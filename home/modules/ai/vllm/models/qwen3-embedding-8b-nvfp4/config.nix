# Qwen3-Embedding-4B — embedding（默认启动）
{
  name = "vllm-qwen3-embedding-8b-nvfp4";
  model = "alexliap/Qwen3-Embedding-8B-NVFP4";
  port = 8011;
  socat-port = 18011;
  autostart = true;
  gpu-memory-utilization = 0.20;
  max-model-len = 8192;
  max-num-seqs = 128;
  extraArgs = [
    "--task embed"
    "--quantization compressed-tensors"
  ];
}
