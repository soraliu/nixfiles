{
  name = "vllm-qwen3-reranker-0-6b";
  model = "Qwen/Qwen3-Reranker-0.6B";
  port = 8020;
  socat-port = 18020;
  autostart = true;
  gpu-memory-utilization = 0.10;
  max-model-len = 4096;
  max-num-seqs = 64;

  # Qwen3-Reranker 是纯文本模型，不需要额外参数
  extraArgs = [
    "--enable-prefix-caching"
    '' --hf_overrides '{"architectures": ["Qwen3ForSequenceClassification"], "classifier_from_token": ["no", "yes"], "is_original_qwen3_reranker": true}' ''
  ];
}
