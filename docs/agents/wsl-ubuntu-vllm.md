# WSL Ubuntu vLLM 配置指南

## 核心原则

### 环境隔离策略

**❌ 不要使用 buildFHSEnv 包装 vLLM 启动脚本**

原因：
- FHS 环境会隔离 `/usr/lib/wsl/lib` 中的 CUDA 库
- 即使使用 `extraBwrapArgs` 尝试 bind mount，也会因权限问题失败
- WSL2 的 CUDA 库访问需要直接访问宿主机路径

**✅ 正确做法：直接使用 writeShellScriptBin**

```nix
mkModelRunner = cfg:
  pkgs.writeShellScriptBin cfg.name ''
    # 直接设置环境变量，不经过 FHS 包装
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.gcc13.cc.lib}/lib"
    export CUDA_HOME="${cuda.cudatoolkit}"
    # ...
  '';
```

### LD_LIBRARY_PATH 管理

**❌ 避免复杂的库路径**

错误示例（会导致 segfault）：
```bash
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${cuda.cuda_cudart}/lib:${cuda.libcublas}/lib:${cuda.cudnn}/lib:..."
```

**✅ 保持最简路径**

```bash
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.gcc13.cc.lib}/lib"
```

原因：
- WSL2 的 `/usr/lib/wsl/lib` 已包含所有必要的 CUDA 运行时库
- 过多的库路径会导致版本冲突和符号解析问题
- gcc13 的 libstdc++ 是必需的，用于 C++ 标准库支持

### CUDA 环境变量

**必需的环境变量：**

```bash
export CUDA_HOME="${cuda.cudatoolkit}"
export CUDA_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.gcc13.cc.lib}/lib"
```

## 常见问题与解决方案

### 1. FlashInfer JIT 编译失败

**错误现象：**
```
Ninja build failed
Could not compile FlashInfer kernels
```

**原因：**
- FlashInfer 尝试 JIT 编译 CUDA kernels
- Nix 环境中缺少完整的编译工具链

**解决方案：**
不强制指定 attention backend，让 vLLM 自动选择：

```nix
# ❌ 不要添加这些参数
extraArgs = [
  "--attention-backend FLASH_ATTN"  # 会导致其他问题
];

extraEnv = {
  VLLM_ATTENTION_BACKEND = "FLASHINFER";  # 会触发 JIT 编译
};
```

### 2. FLASH_ATTN 与 FP8 KV Cache 不兼容

**错误现象：**
```
ValueError: Selected backend AttentionBackendEnum.FLASH_ATTN is not valid for this configuration.
Reason: ['kv_cache_dtype not supported']
```

**原因：**
- FLASH_ATTN backend 不支持 fp8 kv_cache_dtype
- FP8 量化模型需要特定的 attention backend

**解决方案：**
移除冲突的参数，让 vLLM 自动选择兼容的 backend：

```nix
# ❌ 不要同时使用
extraArgs = [
  "--attention-backend FLASH_ATTN"
  "--kv-cache-dtype fp8"
];

# ✅ 让 vLLM 自动选择
extraArgs = [
  "--enable-prefix-caching"
  "--enable-chunked-prefill"
];
```

### 3. Segmentation Fault (Exit Code 139)

**错误现象：**
```
[1] 12345 segmentation fault (core dumped)
```

**可能原因：**
1. LD_LIBRARY_PATH 过于复杂，导致库冲突
2. 缺少 CUDA_HOME 环境变量
3. FHS 环境隔离导致 CUDA 库访问失败

**解决方案：**
1. 简化 LD_LIBRARY_PATH（见上文）
2. 添加 CUDA_HOME 环境变量
3. 不使用 FHS 环境包装

### 4. 缺少 libstdc++.so.6

**错误现象：**
```
error while loading shared libraries: libstdc++.so.6: cannot open shared object file
```

**解决方案：**
在 LD_LIBRARY_PATH 中添加 gcc13 库路径：

```bash
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.gcc13.cc.lib}/lib"
```

## 推荐配置模板

### 最小可用配置

```nix
{
  name = "vllm-model-name";
  model = "model/path";
  port = 8000;
  gpu-memory-utilization = 0.60;
  max-model-len = 16384;
  max-num-seqs = 256;

  extraEnv = {};  # 不设置 VLLM_ATTENTION_BACKEND

  extraArgs = [
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--max-num-batched-tokens 16384"
  ];
}
```

### flake.nix 实现

```nix
mkModelRunner = cfg:
  let
    venvPath = "$HOME/.cache/vllm-venv-${venvHash}";
    allArgs = defaultArgs ++ (cfg.extraArgs or []);
  in pkgs.writeShellScriptBin cfg.name ''
    set -euo pipefail

    # 检查 venv
    if [ ! -d "${venvPath}" ]; then
      echo "错误: venv 不存在"
      exit 1
    fi

    # 设置环境变量
    export HF_HOME="$HOME/.cache/huggingface"
    export CUDA_VISIBLE_DEVICES=0
    export CUDA_HOME="${cuda.cudatoolkit}"
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.gcc13.cc.lib}/lib"

    # 激活 venv
    source "${venvPath}/bin/activate"

    # 启动 vLLM
    exec python -m vllm.entrypoints.openai.api_server \
      --model ${cfg.model} \
      --port ${toString cfg.port} \
      --max-model-len ${toString cfg.max-model-len} \
      --gpu-memory-utilization ${toString cfg.gpu-memory-utilization} \
      ${pkgs.lib.concatStringsSep " \\\n      " allArgs}
  '';
```

## 验证步骤

### 1. 检查模型启动

```bash
nix run --impure --no-sandbox ./path/to/flake#model-name
```

预期输出：
```
INFO: Started server process
INFO: Waiting for application startup.
INFO: Application startup complete.
```

### 2. 测试 API 访问

```bash
curl http://10.255.255.254:8000/v1/models
```

预期返回：
```json
{
  "object": "list",
  "data": [
    {
      "id": "model-name",
      "object": "model",
      "created": 1234567890
    }
  ]
}
```

## 调试技巧

### 查看详细日志

```bash
# 启动时查看完整输出
nix run --impure --no-sandbox ./path/to/flake#model-name 2>&1 | tee vllm.log
```

### 检查进程状态

```bash
ps aux | grep vllm
```

### 检查 CUDA 可用性

```bash
# 在 venv 中测试
source ~/.cache/vllm-venv-xxx/bin/activate
python -c "import torch; print(torch.cuda.is_available())"
```

### 检查库依赖

```bash
# 检查可执行文件依赖
ldd $(which python) | grep -E "(cuda|nvidia)"
```

### JIT 缓存清理规则

当 `@home/modules/ai/vllm/models/flake.nix` 中的 vLLM 模型启动失败时：

- **自动清理 JIT（Just-In-Time）缓存目录**：
  - `~/.cache/flashinfer`
  - `~/.cache/vllm/torch_compile_cache`

- **清理命令**：`rm -rf ~/.cache/flashinfer ~/.cache/vllm/torch_compile_cache`

- **适用时机**：在模型启动失败后、重试之前立即执行清理

这样可以解决 Triton 的 JIT 编译错误和旧缓存残留问题。

## 参考资料

- [vLLM 官方文档](https://docs.vllm.ai/)
- [WSL2 CUDA 支持](https://docs.nvidia.com/cuda/wsl-user-guide/)
- [Nix buildFHSEnv](https://nixos.org/manual/nixpkgs/stable/#sec-fhs-environments)
