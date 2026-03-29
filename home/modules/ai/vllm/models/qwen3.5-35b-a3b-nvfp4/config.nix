# Qwen3.5-35B — 对话（默认启动）
{
  name = "vllm-qwen35-35b-a3b-nvfp4";
  model = "AxionML/Qwen3.5-35B-A3B-NVFP4";
  port = 8000;
  socat-port = 18000;
  autostart = true;
  gpu-memory-utilization = 0.70;
  max-model-len = 32768;
  max-num-seqs = 64;

  # Python 依赖版本配置
  pythonDeps = {
    vllm = "0.17.1";
  };

  extraArgs = [
    "--enable-auto-tool-choice"
    "--tool-call-parser qwen3_coder"
    "--reasoning-parser qwen3"
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--max-num-batched-tokens 32768"
    "--kv-cache-dtype fp8"
  ];
}
