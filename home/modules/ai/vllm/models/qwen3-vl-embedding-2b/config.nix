# 显存消耗: 5.5 G
{
  name = "vllm-qwen3-vl-embedding-2b";
  model =  "alexliap/Qwen3-VL-Embedding-2B-FP8-DYNAMIC";
  port = 8010;
  socat-port = 18010;
  autostart = true;
  gpu-memory-utilization = 0.2;
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
