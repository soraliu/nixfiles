# GLM-4.7-Flash — 对话+工具调用（备选，手动启动）
{
  name = "vllm-glm4-flash";
  model = "GadflyII/GLM-4.7-Flash-NVFP4";
  port = 8000;
  socat-port = 18000;
  autostart = true;
  gpu-memory-utilization = 0.8;
  # 最大上下文长度
  max-model-len = 32768;
  # 最大并发
  max-num-seqs = 12;
  extraArgs = [
    "--enable-auto-tool-choice"
    "--tool-call-parser glm47"
    "--reasoning-parser glm45"
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--max-num-batched-tokens 32768"
    "--kv-cache-dtype fp8"
  ];
}
