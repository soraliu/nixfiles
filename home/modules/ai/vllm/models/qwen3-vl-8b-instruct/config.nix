# Qwen3.5-9B — 对话（默认启动）
{
  name = "vllm-qwen3-vl-8b-instruct";
  model = "Qwen/Qwen3-VL-8B-Instruct";
  port = 8000;
  socat-port = 18000;
  autostart = true;
  gpu-memory-utilization = 0.60;
  max-model-len = 32768;
  max-num-seqs = 256;
  extraArgs = [
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--kv-cache-dtype fp8"
    "--max-num-batched-tokens 16384"
  ];
}
