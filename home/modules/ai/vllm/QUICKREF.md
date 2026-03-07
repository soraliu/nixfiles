# 🚀 vLLM RTX 5090 快速参考

## 一键启动

```bash
# 终端 1: 启动服务
cd ~/Github/nixfiles && nix run .#vllm-serve

# 终端 2: 运行测试
cd ~/Github/nixfiles/home/modules/ai/vllm && ./quick_benchmark.sh
```

## 核心优化

| 参数 | 值 | 说明 |
|------|-----|------|
| `max-num-seqs` | 256 | 并发序列 ↑100% |
| `gpu-memory-utilization` | 0.95 | 显存利用 ↑11.8% |
| `max-num-batched-tokens` | 32768 | 批处理 ↑100% |
| `num-scheduler-steps` | 10 | 多步调度 |
| `use-v2-block-manager` | ✓ | 新版管理器 |

## 性能目标

```
吞吐量:  > 8000 tokens/s  (目标: 10000+)
P50延迟: < 60ms           (目标: 50ms)
P99延迟: < 250ms          (目标: 200ms)
成功率:  > 99.9%
```

## 文档导航

- 📖 **USAGE_GUIDE.md** - 完整使用指南（从这里开始）
- 📊 **BENCHMARK.md** - 优化参数详解
- 📈 **OPTIMIZATION_COMPARISON.md** - 优化前后对比
- 📝 **SUMMARY.md** - 完整总结

## 故障速查

```bash
# OOM → 降低显存利用率
--gpu-memory-utilization 0.90

# 延迟高 → 减少调度步数
--num-scheduler-steps 5

# 检查状态
nvidia-smi
curl http://127.0.0.1:8000/health
```

## 测试命令

```bash
# 快速测试 (5-10分钟)
./quick_benchmark.sh

# 完整测试 (30-60分钟)
./benchmark_test.sh

# 查看结果
ls -lh ~/.cache/vllm-benchmarks/
```

---
**硬件:** RTX 5090 32GB | **模型:** GLM-4.7-Flash-NVFP4 | **数据集:** ShareGPT_V3
