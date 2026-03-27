# Qwen3.5-9B — 对话（默认启动）
{
  name = "vllm-qwen35-chat";
  model = "AxionML/Qwen3.5-9B-NVFP4";
  port = 8001;
  socat-port = 18001;
  autostart = true;
  gpu-memory-utilization = 0.60;
  max-model-len = 32768;
  max-num-seqs = 256;
  extraArgs = [
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--disable-log-requests"
  ];
}
