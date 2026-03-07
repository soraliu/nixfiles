# SGLang - Blackwell 优化推理引擎

## 概述

SGLang 是专为 Blackwell 架构（RTX 5090）优化的高性能推理引擎，针对 GLM-4.7-Flash MoE 模型提供了显著的性能提升。

## 性能预期

基于社区基准测试（H200 集群），SGLang 相比 vLLM 的性能提升：

- **吞吐量**: 1.78x 提升（batch size 1）
- **TTFT**: 65% 改进
- **预期性能**: 67-80 tokens/s（相比 vLLM 的 38.2 tokens/s）

## 关键优化

1. **Blackwell CUTLASS 内核**: KernelPtrArrayTmaWarpSpecialized1SmNvf4Sm100
2. **MoE 优化**: Shared Experts Fusion
3. **GLM-4 特定**: QK-Norm-RoPE Fusion
4. **自适应网格**: 动态调整计算网格大小

## 快速开始

### 1. 初始化环境

```bash
# 手动创建环境（如果未使用 home-manager）
uv venv ~/.cache/nix-sglang-env
source ~/.cache/nix-sglang-env/bin/activate
uv pip install sglang
```

### 2. 启动服务

```bash
cd /home/sora/Github/nixfiles/home/modules/ai/sglang
nix run .#sglang-serve
```

### 3. 验证服务

```bash
# 健康检查
curl http://127.0.0.1:8001/health

# 测试请求
curl http://127.0.0.1:8001/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "GadflyII/GLM-4.7-Flash-NVFP4",
    "prompt": "你好，世界！",
    "max_tokens": 50
  }'
```

### 4. 开发环境

```bash
cd /home/sora/Github/nixfiles/home/modules/ai/sglang
nix develop

# 检查 SGLang 版本
python -c "import sglang; print(sglang.__version__)"

# 检查 CUDA
python -c "import torch; print(torch.cuda.is_available())"
```

## 配置参数

### 核心参数

| 参数 | 值 | 说明 |
|------|-----|------|
| `--model-path` | GadflyII/GLM-4.7-Flash-NVFP4 | 模型路径 |
| `--host` | 127.0.0.1 | 监听地址 |
| `--port` | 8001 | 监听端口（避免与 vLLM 冲突） |
| `--tp` | 1 | 张量并行度 |
| `--mem-fraction-static` | 0.90 | 显存利用率 |
| `--max-running-requests` | 256 | 最大并发请求 |
| `--trust-remote-code` | - | 信任远程代码 |
| `--log-level` | warning | 日志级别 |

### 与 vLLM 参数对应

| 功能 | vLLM | SGLang |
|------|------|--------|
| 模型路径 | `--model` | `--model-path` |
| 最大并发 | `--max-num-seqs 256` | `--max-running-requests 256` |
| 显存利用 | `--gpu-memory-utilization 0.90` | `--mem-fraction-static 0.90` |
| 端口 | `--port 8000` | `--port 8001` |
| 张量并行 | `--tensor-parallel-size 1` | `--tp 1` |
| 管道并行 | `--pipeline-parallel-size 1` | `--pp-size 1` |
| 前缀缓存 | `--enable-prefix-caching` | 默认启用 |
| 分块预填充 | `--enable-chunked-prefill` | 默认启用 |

## 基准测试

### 运行测试

```bash
# 1. 启动 SGLang 服务
cd /home/sora/Github/nixfiles/home/modules/ai/sglang
nix run .#sglang-serve &
SGLANG_PID=$!

# 2. 等待服务就绪
sleep 30

# 3. 运行基准测试
python /tmp/sglang_perf_test.py

# 4. 停止服务
kill $SGLANG_PID
```

### 测试脚本

测试脚本位于 `/tmp/sglang_perf_test.py`，基于 vLLM 测试脚本修改端口为 8001。

## 故障排查

### 问题 1: 安装失败

```bash
# 清除缓存重新安装
rm -rf ~/.cache/nix-sglang-env
uv venv ~/.cache/nix-sglang-env
source ~/.cache/nix-sglang-env/bin/activate
uv pip install sglang --no-cache-dir
```

### 问题 2: 模型加载失败

```bash
# 检查 HuggingFace 镜像
echo $HF_ENDPOINT  # 应该是 https://hf-mirror.com

# 检查模型缓存
ls -lh ~/.cache/huggingface/hub/models--GadflyII--GLM-4.7-Flash-NVFP4
```

### 问题 3: 端口冲突

```bash
# 检查端口占用
lsof -i :8001

# 停止 vLLM 服务
pkill -f vllm
```

### 问题 4: 显存不足

```bash
# 降低显存利用率
--mem-fraction-static 0.85

# 减少并发请求
--max-running-requests 128
```

### 问题 5: CUDA 错误

```bash
# 检查 CUDA 驱动
nvidia-smi

# 检查 LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH  # 应该包含 /usr/lib/wsl/lib
```

## PM2 服务管理

如果配置了 `default.nix`，可以使用 PM2 管理服务：

```bash
# 启动服务
pm2 start sglang-glm4-flash

# 查看状态
pm2 status

# 查看日志
pm2 logs sglang-glm4-flash

# 停止服务
pm2 stop sglang-glm4-flash

# 重启服务
pm2 restart sglang-glm4-flash
```

## 性能对比

详细的性能对比报告请参考：
`/home/sora/Github/nixfiles/home/modules/ai/VLLM_VS_SGLANG_BENCHMARK.md`

## 参考资料

- [SGLang 官方文档](https://github.com/sgl-project/sglang)
- [Optimizing GLM4-MoE for Production](https://lmsys.org/blog/2026-01-21-novita-glm4/)
- [vLLM vs SGLang 性能对比](https://github.com/vllm-project/vllm/discussions)

## 技术细节

### Blackwell 优化

SGLang 针对 Blackwell 架构（SM_120）提供了专门的 CUTLASS 内核：

```
KernelPtrArrayTmaWarpSpecialized1SmNvf4Sm100
```

这个内核针对 NVFP4 量化格式和 MoE 架构进行了优化，相比通用内核性能提升显著。

### MoE 优化

GLM-4.7-Flash 是 30B-A3B MoE 模型（64个专家，每次激活3B），SGLang 提供了：

1. **Shared Experts Fusion**: 合并共享专家的计算
2. **Expert Parallelism**: 专家级并行计算
3. **Dynamic Routing**: 动态路由优化

### MLA 支持

GLM-4 使用 Multi-Head Latent Attention (MLA) 架构，SGLang 提供了：

1. **QK-Norm Fusion**: 融合 QK 归一化和 RoPE
2. **Latent Cache**: 优化的 KV 缓存策略
3. **Attention Kernel**: 专门的注意力内核

## 环境变量

```bash
# CUDA 设备
export CUDA_VISIBLE_DEVICES=0

# HuggingFace 配置
export HF_HOME="$HOME/.cache/huggingface"
export HF_ENDPOINT="https://hf-mirror.com"

# CUDA 缓存
export CUDA_CACHE_PATH="$HOME/.cache/cuda"

# 库路径（WSL2）
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$LD_LIBRARY_PATH"

# 编译器
export CC="gcc"
export CXX="g++"
```

## 许可证

SGLang 使用 Apache 2.0 许可证。
