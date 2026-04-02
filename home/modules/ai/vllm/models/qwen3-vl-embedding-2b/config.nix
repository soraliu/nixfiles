{
  name = "vllm-qwen3-vl-embedding-2b";
  # Embedding Dimension: 2048, Model Layers 28, 显存消耗: ~3 G, Sequence Length 32k
  model =  "alexliap/Qwen3-VL-Embedding-2B-FP8-DYNAMIC";
  port = 8010;
  socat-port = 18010;
  autostart = true;
  gpu-memory-utilization = 0.25;
  max-model-len = 4096;
  max-num-seqs = 64;
  extraArgs = [
    "--runner pooling"
    "--convert embed"
    "--hf-overrides '{\"is_matryoshka\": true}'"
    "--quantization compressed-tensors"
    "--disable-frontend-multiprocessing"
  ];
}
