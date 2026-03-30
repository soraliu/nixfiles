# Qwen3.5-35B — 多模态

# 部署配置中的三大“天坑”
# 1. 内核缺失坑：sm_120 不受官方镜像支持
# 现象: 当你直接 pull 官方的 vllm/vllm-openai:latest 镜像并加载 NVFP4 模型时，会立刻遭遇报错崩溃：ValueError: NvFp4 MoE backend 'FLASHINFER_CUTLASS' does not support the deployment configuration since kernel does not support current device.
# 本质: 官方预编译的 Python Wheels 和 Docker 镜像目前通常只编译到 Hopper (sm_90) 或数据中心版的 Blackwell (sm_100)。RTX 5090 作为消费级 Blackwell (sm_120)，其对应的底层 FlashInfer 和 CUTLASS 矩阵乘法内核并未被打包进去（参考 GitHub Issue #33333）。
# 解法: 绝对不能用官方镜像。 你必须从源码手动编译 vLLM，并在编译时强制注入环境变量 TORCH_CUDA_ARCH_LIST="12.0 12.1"。或者，在 Reddit 上目前最推崇的做法是使用社区维护的 5090 专用镜像（例如 BoltzmannEntropy/vLLM-5090 或 eugr/spark-vllm-docker）。

# 2. Qwen3.5 NVFP4 的精度崩溃与 MLA 报错
# 现象: 模型加载成功了，但输出的内容全是乱码，或者在推理常识逻辑（如 GSM8K 测试）时，准确率从 FP8 的 90% 暴跌到 11% 以下。
# 本质: 这是一个已知 Bug (Issue #36094, #38439)。Qwen3.5 系列采用了 MLA (Multi-Head Latent Attention) 机制。目前的 vLLM 在处理 NVFP4 格式与 MLA 的结合时，FlashInfer 内核在 float32 缩放和 bfloat16 矩阵运算的对齐上存在精度丢失和内存溢出问题。
# 解法: 目前 NVFP4 跑 Qwen3.5 还处于“能跑但变笨”的阶段。社区的临时妥协方案是：如果你需要满血的逻辑能力，暂时退回到 AWQ 4-bit 量化版本，AWQ 目前在 5090 上的单并发吞吐甚至比残血的 NVFP4 更稳定，且没有精度丢失。如果非要跑 NVFP4，需要在启动参数中加入 --kv-cache-dtype fp8 来缓解显存处理错误。

# 3. WSL 的动态图陷阱 (CUDA Graphs 瘫痪)
# 现象: 推理速度奇慢，不得已开启 --enforce-eager。
# 本质: 正如我们之前讨论的，开启 eager 会抹杀 5090 的性能。很多人发现 5090 在 WSL 下无法使用 CUDA Graphs，这是因为 WSL 内部的网络服务（如 Tailscale）或 nvidia-cdi-refresh 在启动时与 Blackwell 的显卡驱动发生了竞态条件，导致 CUDA 初始化失败 (Issue #37242)。
# 解法: 必须将 Windows 宿主机的 WSL2 升级到最新的 2.7.0+ 版本（可能需要加入 Windows Insider 计划获取），该版本修复了 WDDM 对 Blackwell 架构 CUDA Graphs 的支持问题。

{
  name = "vllm-qwen35-35b-a3b-nvfp4";
  model = "AxionML/Qwen3.5-35B-A3B-NVFP4";
  port = 8000;
  socat-port = 18000;
  autostart = true;
  gpu-memory-utilization = 0.8;
  max-model-len = 16384;
  max-num-seqs = 64;

  # Python 依赖版本配置
  pythonDeps = {
    vllm = "0.17.1";
  };

  extraArgs = [
    "--quantization modelopt_fp4"
    "--kv-cache-dtype fp8_e4m3"
    "--enable-auto-tool-choice"
    "--tool-call-parser qwen3_coder"
    "--reasoning-parser qwen3"
    "--enable-prefix-caching"
    "--enable-chunked-prefill"
    "--max-num-batched-tokens 16384"
    "--enforce-eager"
  ];
}
