# Qwen3.5-9B — 对话（默认启动）
{
  name = "vllm-qwen3-vl-8b-instruct";
  #model = "Qwen/Qwen3-VL-8B-Instruct";
  model = "Qwen/Qwen3-VL-8B-Instruct-FP8";
  port = 8000;
  socat-port = 18000;
  autostart = true;
  gpu-memory-utilization = 0.60;
  max-model-len = 16384;
  max-num-seqs = 256;

  # 模型特定的环境变量（可选，可覆盖 flake.nix 中的默认值）
  extraEnv = {
    VLLM_ATTENTION_BACKEND = "FLASH_ATTN";
    # VLLM_USE_FLASHINFER_MOE_FP4 = "1";  # 禁用 FlashInfer，避免 Triton JIT 编译错误
  };

  extraArgs = [
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--kv-cache-dtype fp8"
    "--max-num-batched-tokens 16384"

    "--enable-auto-tool-choice"
    "--tool-call-parser hermes"
    "--reasoning-parser qwen3"
  ];
}
