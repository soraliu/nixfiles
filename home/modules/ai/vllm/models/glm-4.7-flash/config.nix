# GLM-4.7-Flash — 对话+工具调用（备选，手动启动）
{
  name = "vllm-glm4-flash";
  model = "GadflyII/GLM-4.7-Flash-NVFP4";
  port = 8000;
  autostart = false;
  gpu-memory-utilization = 0.45;
  max-model-len = 32768;
  max-num-seqs = 256;
  extraArgs = [
    "--enable-auto-tool-choice"
    "--tool-call-parser glm47"
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--max-num-batched-tokens 32768"
  ];
}
