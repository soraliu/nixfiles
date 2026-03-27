# Qwen3-Embedding-4B — embedding（默认启动）
{
  name = "vllm-qwen3-embedding";
  model = "Qwen/Qwen3-Embedding-4B";
  port = 8010;
  socat-port = 18010;
  autostart = true;
  # 4B 模型，20% 显存足够
  gpu-memory-utilization = 0.20;
  max-model-len = 8192;
  max-num-seqs = 128;
  extraArgs = [
    "--runner pooling"
    "--disable-log-requests"
  ];
}
