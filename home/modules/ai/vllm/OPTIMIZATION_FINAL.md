# vLLM RTX 5090 优化配置最终版本

## 配置演进历史

### 版本 1: 初始激进优化（失败）
```nix
--max-num-seqs 256
--gpu-memory-utilization 0.95
--max-num-batched-tokens 32768
--kv-cache-dtype fp8
--num-scheduler-steps 10
--use-v2-block-manager
--enforce-eager
```

**问题**:
- ❌ 参数不支持: `--num-scheduler-steps`, `--use-v2-block-manager`, `--enforce-eager`
- ❌ FP8 KV cache 与 MLA 架构不兼容
- ❌ 显存利用率过高导致 OOM

### 版本 2: 当前稳定配置（成功）✅
```nix
--model GadflyII/GLM-4.7-Flash-NVFP4
--max-num-seqs 256
--max-model-len 32768
--gpu-memory-utilization 0.90
--port 8000
--host 127.0.0.1
--trust-remote-code
--disable-log-requests
--kv-cache-dtype auto
--enable-prefix-caching
--enable-chunked-prefill
--max-num-batched-tokens 32768
--tensor-parallel-size 1
--pipeline-parallel-size 1
--block-size 16
```

**状态**: ✅ 稳定运行，100% 成功率

**性能**:
- 吞吐量: 38.20 tokens/s
- 平均延迟: 4385ms
- 显存占用: ~26GB

### 版本 3: 推荐优化配置（待测试）

基于实际测试结果，推荐以下配置：

```nix
--model GadflyII/GLM-4.7-Flash-NVFP4
--max-num-seqs 128                    # 降低以匹配实际并发
--max-model-len 32768
--gpu-memory-utilization 0.92         # 稍微提高
--port 8000
--host 127.0.0.1
--trust-remote-code
--disable-log-requests
--kv-cache-dtype auto
--enable-prefix-caching
--enable-chunked-prefill
--max-num-batched-tokens 16384        # 降低以减少延迟
--tensor-parallel-size 1
--pipeline-parallel-size 1
--block-size 32                       # 增大块大小
```

**预期改进**:
- 🎯 降低延迟 10-15%
- 🎯 提高 KV cache 效率
- 🎯 更好的显存利用

## 参数说明

### 核心参数

| 参数 | 当前值 | 推荐值 | 说明 |
|------|--------|--------|------|
| `max-num-seqs` | 256 | 128 | 实际并发远低于 256，降低可减少开销 |
| `gpu-memory-utilization` | 0.90 | 0.92 | 稍微提高以获得更多 KV cache |
| `max-num-batched-tokens` | 32768 | 16384 | 降低可减少批处理延迟 |
| `block-size` | 16 | 32 | 增大可减少内存碎片 |
| `kv-cache-dtype` | auto | auto | MLA 架构必须使用 auto |

### 固定参数（不建议修改）

- `max-model-len`: 32768 - 模型最大上下文
- `tensor-parallel-size`: 1 - 单卡配置
- `pipeline-parallel-size`: 1 - 单卡配置
- `enable-prefix-caching`: true - 提高重复前缀效率
- `enable-chunked-prefill`: true - 平衡延迟和吞吐

## 性能基准

### 当前配置性能

```
测试条件: 100 请求, 8 并发, 256 max_tokens
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
吞吐量 (tokens/s):        38.20
请求吞吐量 (req/s):        1.76
平均延迟 (ms):            4385.32
P50 延迟 (ms):            4385.33
P95 延迟 (ms):            4678.50
P99 延迟 (ms):            4684.53
成功率:                   100.00%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 资源使用

```
模型加载:                 18.11 GiB
KV cache:                 7.26 GiB
总显存占用:               ~26 GiB (81% of 32GB)
可用 KV cache tokens:     143,904
最大并发 (32K/req):       4.39x
```

## 性能瓶颈分析

### 主要限制因素

1. **模型架构** (最大影响)
   - MoE (Mixture of Experts) 架构计算复杂度高
   - MLA (Multi-Head Latent Attention) 在 RTX 5090 上只能使用 TRITON backend
   - NVFP4 量化格式使用 VLLM_CUTLASS backend

2. **硬件支持**
   - RTX 5090 (Blackwell) 不支持 FlashMLA Dense
   - 需要 Hopper 架构 (H100/H200) 才能获得最佳 MLA 性能

3. **软件优化**
   - vLLM 0.16.0 对 Blackwell 的支持还不完善
   - 缺少针对 RTX 5090 的专门优化

### 无法突破的限制

❌ **无法使用 FP8 KV cache**: MLA 架构不支持
❌ **无法使用 FlashMLA**: 需要 Hopper 架构
❌ **无法使用 FlashInfer MoE**: qk_nope_head_dim 不匹配

## 优化路径

### 短期优化（配置调整）

**优先级 1: 降低延迟**
```nix
--max-num-batched-tokens 16384  # 从 32768 降低
--max-num-seqs 128              # 从 256 降低
```

**优先级 2: 提高吞吐**
```nix
--gpu-memory-utilization 0.92   # 从 0.90 提高
--block-size 32                 # 从 16 增大
```

### 中期优化（模型选择）

**选项 1: 更换模型架构**
- 使用非 MoE 架构的模型
- 选择支持 FlashAttention 的模型
- 避免 MLA 架构

**选项 2: 更换量化格式**
- 尝试 FP16/BF16 精度
- 测试 AWQ/GPTQ 量化
- 对比 INT8 量化

### 长期优化（硬件/软件升级）

**硬件升级**
- 等待 vLLM 对 Blackwell 的更好支持
- 考虑使用 H100/H200 (Hopper 架构)

**软件升级**
- 关注 vLLM 新版本发布
- 测试 TensorRT-LLM 等其他推理引擎

## 测试建议

### 下一步测试

1. **测试推荐配置**
   ```bash
   # 修改 flake.nix 为推荐配置
   # 重启服务
   # 运行 /tmp/simple_perf_test.py
   ```

2. **对比不同并发数**
   ```python
   # 修改 CONCURRENCY 为 4, 8, 16, 32
   # 观察延迟和吞吐量变化
   ```

3. **测试不同批处理大小**
   ```nix
   # 测试 8192, 16384, 32768
   # 找到最佳平衡点
   ```

### 测试脚本

位置: `/tmp/simple_perf_test.py`

修改并发数:
```python
CONCURRENCY = 4  # 或 8, 16, 32
```

## 结论

### 当前状态评估

✅ **稳定性**: 优秀 (100% 成功率)
⚠️ **性能**: 受限于模型架构和硬件支持
✅ **可用性**: 可用于低并发场景

### 适用场景

**✅ 适合**:
- 低并发推理 (< 10 并发)
- 对延迟不敏感的应用
- 开发和测试环境

**❌ 不适合**:
- 高并发 API 服务
- 实时对话应用
- 需要低延迟的场景

### 最终建议

如果需要更好的性能，建议：
1. 更换为非 MoE 架构的模型（如 Qwen, Llama 系列）
2. 使用 FP16/BF16 精度而非 NVFP4
3. 等待 vLLM 对 Blackwell 架构的更好支持

如果继续使用当前配置：
1. 应用推荐的优化配置
2. 针对低并发场景优化
3. 接受当前性能水平
