# WSL2 CUDA Toolkit 安装指南 — 解决 vLLM FlashInfer JIT 编译问题

## 背景

vLLM 0.17.1 使用 FlashInfer 作为 attention backend，FlashInfer 在处理特定请求（如多模态/图片推理）时需要 JIT 编译 CUDA kernel。JIT 编译依赖系统中的 `nvcc`（CUDA 编译器）和 `which` 命令。

WSL2 的 CUDA 架构：Windows 宿主机的 GPU 驱动通过 `libcuda.so` stub 映射到 WSL2 内部，因此 **不需要也不能** 在 WSL2 内安装 Linux GPU 驱动。但 Windows 驱动只提供 CUDA runtime，编译器（nvcc）、头文件和库需要在 WSL2 内单独安装 CUDA Toolkit。

### 版本要求

| 组件                | 最低版本 | 推荐版本 | 说明                       |
| ------------------- | -------- | -------- | -------------------------- |
| CUDA Toolkit (nvcc) | 12.6     | 12.8+    | FlashInfer JIT 要求 ≥ 12.6 |
| Windows GPU 驱动    | 550+     | 最新     | WSL2 CUDA 支持             |
| vLLM                | 0.17.x   | —        | 当前使用版本               |

---

## 第一阶段：前置检查

在 WSL2 终端中执行以下命令，记录当前状态：

```bash
# 1. 确认 GPU 可见（应显示 GPU 型号和驱动版本）
nvidia-smi

# 2. 检查是否已有 nvcc（预期：command not found）
which nvcc 2>/dev/null && nvcc --version || echo "nvcc 未安装"

# 3. 检查 which 命令本身是否可用（Nix 环境可能缺失）
which which 2>/dev/null || echo "which 命令不可用"

# 4. 检查是否已有旧版 CUDA Toolkit
ls /usr/local/cuda* 2>/dev/null || echo "未找到已安装的 CUDA Toolkit"

# 5. 确认 WSL 内核版本（需要 5.10.43.3+）
uname -r

# 6. 确认发行版
cat /etc/os-release | grep -E "^(NAME|VERSION)="
```

**记录 `nvidia-smi` 输出中的 CUDA Version 字段**（如 `CUDA Version: 12.8`），这是驱动支持的最大 CUDA 版本，安装的 Toolkit 版本不能超过这个值。

---

## 第二阶段：安装 CUDA Toolkit

> ⚠️ **绝对不要** 安装 `cuda`、`cuda-12-x` 或 `cuda-drivers` meta-package，它们会覆盖 WSL2 的驱动 stub，导致 GPU 不可用。只安装 `cuda-toolkit-12-x`。

### 方案 A：Network Repo 安装（推荐，体积小）

```bash
# 添加 NVIDIA WSL-Ubuntu 仓库
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update

# 安装 CUDA Toolkit 12.8（仅 toolkit，不含驱动）
# 如果 nvidia-smi 显示的 CUDA Version >= 12.8，使用 12.8
# 如果显示 >= 12.9，可以用 cuda-toolkit-12-9
sudo apt-get -y install cuda-toolkit-12-8
```

### 方案 B：Local Installer 安装（离线/网络不稳定时）

从 [CUDA Toolkit Downloads](https://developer.nvidia.com/cuda-12-8-0-download-archive) 选择：

- OS: Linux → Architecture: x86_64 → Distribution: WSL-Ubuntu → Version: 2.0 → Installer Type: deb (local)

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600

wget https://developer.download.nvidia.com/compute/cuda/12.8.1/local_installers/cuda-repo-wsl-ubuntu-12-8-local_12.8.1-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-12-8-local_12.8.1-1_amd64.deb
sudo cp /var/cuda-repo-wsl-ubuntu-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update

# 只装 toolkit！
sudo apt-get -y install cuda-toolkit-12-8
```

---

## 第三阶段：配置环境变量

### 3a. 系统级配置（所有用户生效）

```bash
# 创建 profile 脚本
sudo tee /etc/profile.d/cuda.sh > /dev/null << 'EOF'
export CUDA_HOME=/usr/local/cuda
export PATH="${CUDA_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"
EOF

sudo chmod +x /etc/profile.d/cuda.sh
```

### 3b. Nix 环境集成

如果 vLLM 在 Nix devShell 中运行，需要在 shell 配置中注入系统 CUDA 路径：

```nix
# 在 flake.nix 的 devShell 或 home-manager 配置中
shellHook = ''
  export CUDA_HOME=/usr/local/cuda
  export PATH="/usr/local/cuda/bin:/usr/bin:$PATH"
  export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
'';
```

> 关键点：`/usr/bin` 必须在 PATH 中，因为 `which` 命令通常位于此路径。FlashInfer 的 JIT 查找顺序是：`CUDA_HOME` → `which nvcc` → `CUDA_PATH`。

### 3c. PM2 启动配置

如果通过 PM2 管理 vLLM 进程，在 ecosystem 配置中添加环境变量：

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "vllm-qwen35-35b-a3b-nvfp4",
      script: "vllm",
      args: "serve AxionML/Qwen3.5-35B-A3B-NVFP4 ...",
      env: {
        CUDA_HOME: "/usr/local/cuda",
        PATH: "/usr/local/cuda/bin:/usr/bin:" + process.env.PATH,
        LD_LIBRARY_PATH:
          "/usr/local/cuda/lib64:" + (process.env.LD_LIBRARY_PATH || ""),
      },
    },
  ],
};
```

或者在启动脚本中 source 环境：

```bash
#!/bin/bash
source /etc/profile.d/cuda.sh
exec vllm serve ...
```

---

## 第四阶段：验证安装

重新打开一个 WSL2 终端（或 `source /etc/profile.d/cuda.sh`），逐项验证：

```bash
# ✅ 检查 1: nvcc 可用且版本 >= 12.6
nvcc --version
# 预期输出包含: Cuda compilation tools, release 12.8

# ✅ 检查 2: CUDA_HOME 正确设置
echo $CUDA_HOME
# 预期: /usr/local/cuda

# ✅ 检查 3: nvcc 在 PATH 中
which nvcc
# 预期: /usr/local/cuda/bin/nvcc

# ✅ 检查 4: which 命令本身可用
which which
# 预期: /usr/bin/which 或类似路径

# ✅ 检查 5: CUDA_HOME/bin/nvcc 存在
${CUDA_HOME}/bin/nvcc --version
# 预期: 同检查 1

# ✅ 检查 6: GPU 仍然可见（确认驱动未被覆盖）
nvidia-smi
# 预期: 正常显示 GPU 信息，驱动版本不变

# ✅ 检查 7: PyTorch CUDA 可用（在 vLLM 的 Python 环境中）
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'PyTorch CUDA: {torch.version.cuda}')"
# 预期: CUDA available: True
```

---

## 第五阶段：重新配置 vLLM 启动参数

安装 Toolkit 后，建议重新启用 CUDA Graph 以获得更好的性能：

```bash
vllm serve AxionML/Qwen3.5-35B-A3B-NVFP4 \
  --dtype bfloat16 \
  --quantization modelopt_fp4 \
  --kv-cache-dtype fp8 \
  --trust-remote-code \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --max-model-len 24576 \
  --reasoning-parser qwen3
  # 注意：移除了 --enforce-eager，让 vLLM 使用 CUDA Graph
```

> enforce-eager 模式比 CUDA Graph 模式慢约 8 倍。安装好 nvcc 后 CUDA Graph 应该能正常工作。如果仍有问题，再加回 `--enforce-eager` 作为 fallback。

---

## 第六阶段：功能验证

### 6a. 纯文本请求

```bash
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "AxionML/Qwen3.5-35B-A3B-NVFP4",
    "messages": [{"role": "user", "content": "你好，请简单介绍一下自己"}],
    "max_tokens": 100
  }' | python -m json.tool
```

### 6b. 图片/多模态请求（之前崩溃的场景）

```bash
# 用一张测试图片验证视觉推理
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "AxionML/Qwen3.5-35B-A3B-NVFP4",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "image_url", "image_url": {"url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/300px-PNG_transparency_demonstration_1.png"}},
        {"type": "text", "text": "描述这张图片"}
      ]
    }],
    "max_tokens": 200
  }' | python -m json.tool
```

### 6c. 检查 FlashInfer JIT 缓存

首次图片请求会触发 JIT 编译（可能需要几秒到几十秒）。编译完成后，kernel 会被缓存：

```bash
# 检查 FlashInfer JIT 缓存目录
ls -la ~/.cache/flashinfer/ 2>/dev/null || echo "缓存目录尚未创建"

# 检查 vLLM torch compile 缓存
ls -la ~/.cache/vllm/torch_compile_cache/ 2>/dev/null || echo "缓存目录尚未创建"
```

---

## 故障排除

### 问题：安装后 nvidia-smi 报错

说明驱动被覆盖了。解决方法：

```bash
# 卸载错误安装的驱动组件
sudo apt-get --purge remove "nvidia-driver-*" "libnvidia-*"

# 重启 WSL
wsl --shutdown  # 在 Windows PowerShell 中执行
```

Windows 驱动会在 WSL 重启后自动重新映射。

### 问题：FlashInfer JIT 编译超时或失败

```bash
# 清除 JIT 缓存后重试
rm -rf ~/.cache/flashinfer/
rm -rf ~/.cache/vllm/torch_compile_cache/

# 如果仍然失败，尝试切换 attention backend
vllm serve ... --attention-backend FLASH_ATTN
```

### 问题：Nix 环境中 PATH 被覆盖

确认 Nix shell 的 PATH 保留了系统路径：

```bash
# 在 Nix devShell 内检查
echo $PATH | tr ':' '\n' | grep -E "(cuda|/usr/bin)"
# 应该能看到 /usr/local/cuda/bin 和 /usr/bin
```

### 问题：LD_LIBRARY_PATH 导致 CUBLAS 版本冲突

vLLM 自带的 CUDA 库可能与系统 Toolkit 冲突：

```bash
# 如果出现 CUBLAS_STATUS_INVALID_VALUE 错误
# 移除 LD_LIBRARY_PATH 中的系统 CUDA 路径
unset LD_LIBRARY_PATH
# 只保留 CUDA_HOME 和 PATH 即可，vLLM 会使用自带的库
```

---

## 总结清单

| 步骤               | 命令/操作                            | 验证方式                          |
| ------------------ | ------------------------------------ | --------------------------------- |
| 前置检查           | `nvidia-smi`                         | 确认 GPU 可见，记录 CUDA Version  |
| 安装 Toolkit       | `sudo apt install cuda-toolkit-12-8` | `nvcc --version`                  |
| 配置 PATH          | 设置 CUDA_HOME + PATH                | `which nvcc` 返回正确路径         |
| 配置 Nix           | shellHook 注入路径                   | devShell 内 `nvcc --version` 正常 |
| 移除 enforce-eager | 删除 `--enforce-eager` 参数          | 启动日志显示 CUDA Graph 模式      |
| 验证纯文本         | curl 发送文本请求                    | 返回 200 OK                       |
| 验证多模态         | curl 发送图片请求                    | 返回 200 OK（不再崩溃）           |
