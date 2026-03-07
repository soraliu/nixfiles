# vLLM RTX 5090 性能测试使用指南

## 快速开始

### 1. 启动 vLLM 服务

```bash
cd home/modules/ai/vllm
nix run .#vllm-serve
```

等待服务启动完成，看到类似输出：

```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### 2. 运行性能测试

在**另一个终端**中：

```bash
cd ~/Github/nixfiles/home/modules/ai/vllm

# 快速测试（推荐，约 5-10 分钟）
./quick_benchmark.sh

# 或完整测试（约 30-60 分钟）
./benchmark_test.sh
```

## 测试脚本说明

### quick_benchmark.sh - 快速测试

**配置：**

- 请求数：1000 prompts
- 请求速率：8 req/s
- 数据集：ShareGPT_V3

**输出：**

- 实时测试进度
- 完成后自动显示性能指标汇总
- 结果保存在 `~/.cache/vllm-benchmarks/`

**预期耗时：** 5-10 分钟

### benchmark_test.sh - 完整测试

**配置矩阵：**

- 请求数：100, 500, 1000
- 请求速率：1, 2, 4, 8, 16, 32 req/s
- 总计：18 个测试场景

**输出：**

- 每个场景的详细结果
- 最终汇总对比表格
- 所有结果保存为 JSON 文件

**预期耗时：** 30-60 分钟

## 性能指标解读

### 吞吐量 (Throughput)

- **单位：** tokens/s
- **含义：** 每秒处理的 token 数量
- **目标：** > 8000 tokens/s
- **越高越好**

### 请求吞吐量 (Request Throughput)

- **单位：** req/s
- **含义：** 每秒完成的请求数
- **目标：** 接近设定的 request-rate
- **越高越好**

### 延迟 (Latency)

- **P50：** 50% 的请求延迟低于此值（中位数）
- **P95：** 95% 的请求延迟低于此值
- **P99：** 99% 的请求延迟低于此值
- **目标：** P50 < 60ms, P99 < 250ms
- **越低越好**

### 成功率

- **计算：** 成功请求数 / 总请求数
- **目标：** > 99.9%
- **越高越好**

## 结果分析示例

```
📈 性能指标汇总
============================================================
吞吐量 (tokens/s):        10245.67
请求吞吐量 (req/s):        7.89
平均延迟 (ms):            45.23
P50 延迟 (ms):            42.10
P95 延迟 (ms):            98.45
P99 延迟 (ms):            187.32
总请求数:                 1000
成功请求数:               1000
============================================================
```

**解读：**

- ✅ 吞吐量 10245 tokens/s 超过目标 8000
- ✅ P50 延迟 42ms 低于目标 60ms
- ✅ P99 延迟 187ms 低于目标 250ms
- ✅ 成功率 100% (1000/1000)
- **结论：** 性能优秀，配置合理

## 常见问题

### Q1: 服务启动失败

**检查步骤：**

```bash
# 1. 检查 CUDA
python -c "import torch; print(torch.cuda.is_available())"

# 2. 检查 vLLM
python -c "import vllm; print(vllm.__version__)"

# 3. 查看 GPU
nvidia-smi

# 4. 检查端口占用
lsof -i :8000
```

### Q2: 测试脚本报错 "vLLM 服务未运行"

**解决方法：**

1. 确保 vLLM 服务在另一个终端运行
2. 检查服务健康状态：
   ```bash
   curl http://127.0.0.1:8000/health
   ```

### Q3: OOM (显存不足)

**临时解决：**
编辑 `flake.nix`，降低以下参数：

```nix
--gpu-memory-utilization 0.90  # 从 0.95 降低
--max-num-seqs 192             # 从 256 降低
--max-num-batched-tokens 24576 # 从 32768 降低
```

然后重启服务：

```bash
# Ctrl+C 停止当前服务
nix run .#vllm-serve
```

### Q4: 延迟过高

**调优建议：**

1. 降低请求速率（测试时）
2. 调整调度参数：
   ```nix
   --num-scheduler-steps 5  # 从 10 降低
   ```
3. 检查系统负载：
   ```bash
   htop
   nvidia-smi dmon
   ```

### Q5: 吞吐量低于预期

**排查方向：**

1. 检查 GPU 利用率：

   ```bash
   nvidia-smi dmon -s u
   ```

   应该接近 100%

2. 检查显存使用：

   ```bash
   nvidia-smi
   ```

   应该接近 30GB

3. 检查 CPU 瓶颈：
   ```bash
   htop
   ```

## 高级用法

### 自定义测试参数

编辑 `quick_benchmark.sh`，修改：

```bash
--num-prompts 1000      # 请求数量
--request-rate 8        # 请求速率 (req/s)
```

### 查看详细日志

```bash
# vLLM 服务日志（在服务终端）
# 已包含详细的推理信息

# 测试结果 JSON
cat ~/.cache/vllm-benchmarks/quick_benchmark_*.json | jq .
```

### 对比不同配置

```bash
# 1. 运行基线测试
./quick_benchmark.sh

# 2. 修改 flake.nix 参数
# 3. 重启服务
# 4. 再次运行测试
./quick_benchmark.sh

# 5. 对比结果
ls -lt ~/.cache/vllm-benchmarks/
```

## 性能调优建议

### 场景 1: 追求极致吞吐量

```nix
--max-num-seqs 256
--max-num-batched-tokens 32768
--gpu-memory-utilization 0.95
--num-scheduler-steps 10
```

### 场景 2: 追求低延迟

```nix
--max-num-seqs 128
--max-num-batched-tokens 16384
--gpu-memory-utilization 0.90
--num-scheduler-steps 5
```

### 场景 3: 平衡模式（当前配置）

```nix
--max-num-seqs 256
--max-num-batched-tokens 32768
--gpu-memory-utilization 0.95
--num-scheduler-steps 10
```

## 文件位置

```
~/Github/nixfiles/home/modules/ai/vllm/
├── flake.nix                          # vLLM 配置文件
├── quick_benchmark.sh                 # 快速测试脚本
├── benchmark_test.sh                  # 完整测试脚本
├── BENCHMARK.md                       # 优化说明文档
├── OPTIMIZATION_COMPARISON.md         # 优化对比文档
└── USAGE_GUIDE.md                     # 本文档

~/.cache/vllm-benchmarks/              # 测试结果目录
├── quick_benchmark_*.json             # 快速测试结果
└── benchmark_*.json                   # 完整测试结果

~/Github/nixfiles/
└── ShareGPT_V3_unfiltered_cleaned_split.json  # 测试数据集
```

## 下一步

1. ✅ 运行快速测试验证配置
2. 📊 分析性能指标
3. 🔧 根据结果微调参数
4. 🚀 部署到生产环境

## 技术支持

遇到问题？检查：

1. `BENCHMARK.md` - 优化参数详解
2. `OPTIMIZATION_COMPARISON.md` - 优化前后对比
3. vLLM 官方文档：https://docs.vllm.ai/
