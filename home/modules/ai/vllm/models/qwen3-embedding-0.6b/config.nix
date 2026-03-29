# Qwen3-Embedding-4B — embedding（默认启动）
{
  name = "vllm-qwen3-embedding-0-6b";
  model = "Qwen/Qwen3-Embedding-0.6B";
  port = 8014;
  socat-port = 18014;
  autostart = true;
  gpu-memory-utilization = 0.12;
  max-model-len = 8192;
  max-num-seqs = 128;
  extraArgs = [
    "--runner pooling"
  ];
}
