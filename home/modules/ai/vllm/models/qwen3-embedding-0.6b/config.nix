# Qwen3-Embedding-4B — embedding（默认启动）
{
  name = "vllm-qwen3-embedding-0-6b";
  model = "Qwen/Qwen3-Embedding-0.6B";
  port = 8010;
  socat-port = 18010;
  autostart = true;
  gpu-memory-utilization = 0.12;
  max-model-len = 8192;
  max-num-seqs = 128;
  delay = 60000;  # 延迟 60 秒启动（毫秒）
  extraArgs = [
    "--runner pooling"
  ];
}
