{
  name = "vllm-qwen3-vl-embedding-8b";
  # Embedding Dimension: 4096, Model Layers 36, 显存消耗: ~11 G, Sequence Length 32k
  model = "RamManavalan/Qwen3-VL-Embedding-8B-FP8";
  port = 8010;
  socat-port = 18010;
  autostart = false;
  gpu-memory-utilization = 0.5;
  max-model-len = 16384;
  max-num-seqs = 64;
  extraArgs = [
    "--runner pooling"
    "--convert embed"
    "--hf-overrides '{\"is_matryoshka\": true}'"
    "--disable-frontend-multiprocessing"
  ];
}
