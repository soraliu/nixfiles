#!/usr/bin/env bash
# vLLM RTX 5090 性能基准测试脚本

set -e

DATASET="/home/sora/Github/nixfiles-wrapper/ShareGPT_V3_unfiltered_cleaned_split.json"
RESULTS_DIR="$HOME/.cache/vllm-benchmarks"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULTS_DIR"

echo "🚀 vLLM RTX 5090 性能基准测试"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "数据集: $DATASET"
echo "结果目录: $RESULTS_DIR"
echo "时间戳: $TIMESTAMP"
echo ""

# 确保 vLLM 服务正在运行
if ! curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
    echo "❌ vLLM 服务未运行，请先启动服务："
    echo "   nix run .#vllm-serve"
    exit 1
fi

echo "✅ vLLM 服务已就绪"
echo ""

# 测试配置矩阵
declare -a REQUEST_RATES=("1" "2" "4" "8" "16" "32")
declare -a NUM_PROMPTS=("100" "500" "1000")

for NUM_PROMPT in "${NUM_PROMPTS[@]}"; do
    for RATE in "${REQUEST_RATES[@]}"; do
        OUTPUT_FILE="$RESULTS_DIR/benchmark_${TIMESTAMP}_prompts${NUM_PROMPT}_rate${RATE}.json"

        echo "📊 测试配置: ${NUM_PROMPT} prompts @ ${RATE} req/s"
        echo "   输出: $OUTPUT_FILE"

        vllm bench serve \
            --backend openai \
            --base-url http://127.0.0.1:8000 \
            --model GadflyII/GLM-4.7-Flash-NVFP4 \
            --dataset-name sharegpt \
            --dataset-path "$DATASET" \
            --num-prompts "$NUM_PROMPT" \
            --request-rate "$RATE" \
            --seed 42 \
            --save-result \
            --result-dir "$RESULTS_DIR" \
            --result-filename "benchmark_${TIMESTAMP}_prompts${NUM_PROMPT}_rate${RATE}.json"

        echo "✅ 完成"
        echo ""
        sleep 5
    done
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 所有基准测试完成！"
echo ""
echo "📈 生成汇总报告..."

# 生成汇总报告
python3 << 'PYTHON_SCRIPT'
import json
import glob
import os
from pathlib import Path

results_dir = Path.home() / ".cache" / "vllm-benchmarks"
pattern = str(results_dir / "benchmark_*.json")
files = sorted(glob.glob(pattern))

if not files:
    print("❌ 未找到测试结果文件")
    exit(1)

print(f"\n📊 基准测试汇总报告")
print("=" * 100)
print(f"{'配置':<25} {'请求吞吐':<12} {'输出吞吐':<12} {'TTFT中位':<12} {'TPOT中位':<12} {'E2E中位':<12}")
print(f"{'':25} {'(req/s)':<12} {'(tok/s)':<12} {'(ms)':<12} {'(ms)':<12} {'(ms)':<12}")
print("-" * 100)

for file in files:
    try:
        with open(file, 'r') as f:
            data = json.load(f)

        filename = os.path.basename(file)
        parts = filename.replace("benchmark_", "").replace(".json", "").split("_")

        # 从文件名提取配置信息
        config = f"{parts[2]} @ {parts[3]}"

        # 新版本字段名
        req_throughput = data.get("request_throughput", 0)
        output_throughput = data.get("output_throughput", 0)
        median_ttft = data.get("median_ttft_ms", 0)
        median_tpot = data.get("median_tpot_ms", 0)
        median_e2el = data.get("median_e2el_ms", 0)

        print(f"{config:<25} {req_throughput:<12.2f} {output_throughput:<12.2f} {median_ttft:<12.2f} {median_tpot:<12.2f} {median_e2el:<12.2f}")
    except Exception as e:
        print(f"⚠️  解析失败: {file} - {e}")

print("=" * 100)
print(f"\n详细结果保存在: {results_dir}")
print("\n指标说明:")
print("  - 请求吞吐 (Request Throughput): 每秒处理的请求数")
print("  - 输出吞吐 (Output Throughput): 每秒生成的 token 数")
print("  - TTFT (Time To First Token): 首 token 延迟")
print("  - TPOT (Time Per Output Token): 每个输出 token 的平均时间")
print("  - E2E (End-to-End): 端到端延迟")
PYTHON_SCRIPT

echo ""
echo "✨ 测试完成！"
