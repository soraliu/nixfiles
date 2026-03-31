# 最终配置 - 添加 extraEnv
{
  name = "vllm-qwen3-vl-8b-instruct";
  model = "Qwen/Qwen3-VL-8B-Instruct-FP8";
  port = 8000;
  socat-port = 18000;
  autostart = true;
  gpu-memory-utilization = 0.56;
  max-model-len = 16384;
  max-num-seqs = 256;

  extraEnv = {};

  extraArgs = [
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--max-num-batched-tokens 16384"

    "--enable-auto-tool-choice"
    "--tool-call-parser hermes"
    # instruct 模型不能设置 reasoning, 只有 thinking 模型才需要
    # "--reasoning-parser qwen3"
  ];
}
