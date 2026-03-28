# 显存消耗: ~11 G
{
  name = "vllm-qwen3-vl-embedding-8b";
  model = "Qwen/Qwen3-VL-Embedding-8B";
  port = 8013;
  socat-port = 18013;
  autostart = false;
  gpu-memory-utilization = 0.7;
  max-model-len = 16384;
  max-num-seqs = 64;
  extraArgs = [
    "--runner pooling"
    "--convert embed"
    "--hf-overrides '{\"is_matryoshka\": true}'"
    "--disable-frontend-multiprocessing"
  ];
}
