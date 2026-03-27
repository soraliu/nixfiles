# Qwen3.5-9B — 对话（默认启动）
{
  name = "vllm-qwen35-chat";
  model = "AxionML/Qwen3.5-9B-NVFP4";
  port = 8001;
  socat-port = 18001;
  autostart = true;
  # RTX 5090 32GB，embedding + chat 双模型运行，适度留显存
  gpu-memory-utilization = 0.50;
  max-model-len = 32768;
  max-num-seqs = 256;
  extraArgs = [
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
  ];
}
