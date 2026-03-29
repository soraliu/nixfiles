# 在 Nix + WSL2 上构建可复现的 vLLM NVFP4 推理环境

## 目标：在 RTX 5090 上运行 AxionML/Qwen3.5-35B-A3B-NVFP4

**通过 Nix flake 在 WSL2 上运行 Qwen3.5-35B-A3B-NVFP4 的 NVFP4 推理是可行的，但需要同时应对三个独立且不够成熟的生态系统。** nixpkgs 中的 vLLM 包远落后于 PyPI（v0.13.0 vs v0.18.0），SM120 消费级 Blackwell GPU 上的 NVFP4 MoE 支持在最新 vLLM 中仍有未修复的 bug，WSL2 的 GPU 半虚拟化增加了一个与 Nix 隔离模型本质上冲突的驱动桥接层。最实用的路径是混合 flake 方案：Nix 提供可复现的、固定版本的 CUDA 12.8 FHS 环境，而 `uv`/`pip` 在其中从 PyPI wheel 安装 vLLM。当前要实现完全纯 Nix 构建 vLLM v0.18.x 是不现实的，需要大量的打包工作。

---

## 一、nixpkgs 中的 vLLM 包严重落后且频繁构建失败

nixpkgs 官方的 vLLM 包位于 `python3Packages.vllm`，但长期受版本滞后和构建失败困扰，根本原因是 vLLM 与特定 PyTorch 版本的紧耦合。在 **nixos-25.05 stable** 上，vLLM 锁定在 **v0.8.3** —— 但当前无法构建，因为 nixpkgs 已将 PyTorch 升级到 2.7.0，而 vLLM 0.8.3 严格要求 PyTorch 2.6.0（issue #436825）。在 **nixpkgs-unstable** 上，vLLM 为 **v0.13.0**，搭配 PyTorch 2.9.0 和 CUDA 12.8。PyPI 上最新版本为 **v0.18.0**（2026年3月20日发布）。

这个版本差距对 RTX 5090 的 NVFP4 影响极大。SM120 NVFP4 MoE 内核支持的修复直到 **v0.16.0** 才完成（PR #33417），而 Qwen3.5 模型架构支持需要 **transformers ≥4.56.0**。nixpkgs-unstable 的 v0.13.0 不可用 —— 它早于关键的 SM120 修复和 Qwen3.5 架构注册。

Nix 生态中有三种打包方案，按实用性排序：

### 方案一：buildFHSEnv + pip/uv（推荐）

这是社区对 CUDA 密集型 Python 工作负载的共识方案。它创建一个传统文件系统层级的沙箱，pip wheel 可以正常工作，同时 Nix 固定 CUDA 工具链、系统库和 Python 版本。NixOS Wiki 的 CUDA 页面推荐此方案，也是大多数 NixOS 上的 ML 从业者所使用的。`meditans/packaging-vllm` 尝试用 poetry2nix 打包，遇到了 `CUDA_HOME` 检测、stdenv 版本错误和数十个依赖覆写等无法逾越的问题 —— 证实了个人用户纯 Nix 打包 vLLM 100+ 传递依赖是不切实际的。

### 方案二：nixpkgs 原生 `vllm` 包

如果能接受其版本并将 nixpkgs 固定在 vLLM 与 PyTorch 版本对齐的 commit 上，此方案可行。该包使用 `buildPythonPackage` 配合 cmake，包含 Nix 特定的 `setup.py` 补丁，从 `cudaPackages` 获取 CUDA。对于本用例，需要等到 nixpkgs 追上 vLLM ≥0.16.0 或自行维护 overlay。

### 方案三：基于容器的部署

通过 NixOS 的 `hardware.nvidia-container-toolkit` 实现，是生产环境最成熟的选项。NVIDIA NGC 容器（`nvcr.io/nvidia/vllm:26.01-py3`）打包了 CUDA 13.1.1 + vLLM 0.13.0 作为经过测试的组合，官方 `vllm/vllm-openai` 镜像跟踪最新稳定版本并搭配 CUDA 12.8。

---

## 二、WSL2 的 GPU 半虚拟化需要显式驱动桥接

WSL2 不使用 PCIe 直通。Microsoft 的 `dxgkrnl` 内核模块提供 **GPU 半虚拟化** —— Windows 宿主机的 NVIDIA 驱动处理实际的 GPU 通信，存根库被挂载到 WSL2 虚拟机的 **`/usr/lib/wsl/lib/`** 目录下。该目录包含 `libcuda.so.1`、`libnvidia-ml.so.1`、`libdxcore.so` 以及其他与 Windows 宿主机驱动版本紧密耦合的驱动级库。

与 Nix 的核心冲突很直接：**Nix 构建的二进制文件使用指向 `/nix/store/...` 和 `/run/opengl-driver/lib/` 的 RPATH 条目，这两个路径都不包含 WSL2 驱动存根。** 通用的解决方法是将 `/usr/lib/wsl/lib` 添加到 `LD_LIBRARY_PATH`：

```bash
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH
```

这在交互式 shell（`nix develop`、`nix-shell`）中有效，但**在 `nix build` 沙箱内无效**，因为沙箱无法访问 `/usr/lib/wsl/lib`。这意味着在 WSL2 上无法 `nix build` 需要运行时 GPU 访问的 CUDA 应用 —— 只有开发 shell 和直接执行可行。

### NixOS-WSL vs. Ubuntu WSL2 上的普通 Nix

**NixOS-WSL** 提供专用选项 `wsl.useWindowsDriver = true`（在 2405.1.0 版本中添加），它自动创建一个 derivation，将 `/usr/lib/wsl/lib/` 中的所有 GPU 库符号链接到 Nix store 路径，并注册到 `hardware.graphics.extraPackages`。比手动管理 `LD_LIBRARY_PATH` 更干净，但某些工作负载仍需路径 hack（issue #454 仍未关闭）。

**Ubuntu WSL2 上的普通 Nix** 设置更简单 —— Ubuntu 的 `ldconfig` 自动处理 `/usr/lib/wsl/lib/`，非 Nix 工具开箱即用，Nix shell 只需一条 `LD_LIBRARY_PATH` 导出。

对于专注于 ML 推理的 Nix 用户，**推荐 NixOS-WSL**，因为它提供声明式 CUDA 配置和 `useWindowsDriver` 集成：

```nix
{
  wsl = {
    enable = true;
    defaultUser = "ml";
    useWindowsDriver = true;
  };
  hardware.graphics.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };
}
```

### WSL2 特有的 vLLM 注意事项

- vLLM 检测到 WSL2 后会禁用 `pin_memory`（轻微性能影响）
- Blackwell 上的 CUDA 图捕获需要 **WSL2 内核 ≥2.7.0**（2025年12月发布）
- FP8 张量核心**尚未通过 `dxgkrnl` 在 Blackwell GPU 上暴露** —— 但 NVFP4（FP4）使用不同的硬件路径，目前看来可以工作

---

## 三、RTX 5090 上的 NVFP4 可用但 SM120 MoE 支持仍在成熟中

### NVFP4 格式简介

NVFP4 是 NVIDIA 的 4 位浮点格式，使用 **E2M1 码本配合两级层级缩放** —— 每 16 个元素一个 FP8（E4M3）微块缩放因子，加上每张量一个 FP32 全局缩放因子。原生硬件支持仅存在于 Blackwell 架构：**SM100**（数据中心 B200/B100）和 **SM120**（消费级 RTX 5090、RTX 6000 Pro Blackwell）。在旧 GPU 上，vLLM 回退到 **W4A16 仅权重量化**（通过 Marlin 内核）—— 可用但没有 W4A4 激活量化带来的 Blackwell 全部吞吐优势。

### vLLM 的 NVFP4 支持演进

- **v0.8.x**（PR #12784，2025年2月）：初始支持密集模型
- FlashInfer MoE 支持（PR #21639）
- **v0.16.0**（PR #24968 和 #33417）：**SM120 MoE CUTLASS 内核**修复

然而，SM120 仍有显著的未修复 bug：

| Issue    | 问题描述                                                                  |
| -------- | ------------------------------------------------------------------------- |
| #31085   | `get_mxfp4_backend()` 不识别 SM120，回退到 Marlin 而非原生 NVFP4 内核     |
| #33416   | `is_device_capability_family(100)` 不匹配 SM120（报告为 capability 12.0） |
| #35566   | SM120 上大型 NVFP4 模型的 MoE 层出现 CUDA 非法内存访问                    |
| 社区报告 | Blackwell 硬件上 Qwen3.5 MoE NVFP4 模型出现精度退化（乱码输出）           |

这些 bug 的根本原因是一个代码模式：设备能力检查使用 `is_device_capability_family(100)` 匹配数据中心 Blackwell（SM10.x）但**不匹配**消费级 Blackwell（SM12.0）。修复需要在多处添加 `or current_platform.is_device_capability_family(120)`。**v0.18.0** 可能修复了更多问题，但用户应做好运行 nightly 构建或手动 cherry-pick 补丁的准备。

### 模型信息

**AxionML/Qwen3.5-35B-A3B-NVFP4** 使用 NVIDIA ModelOpt 量化格式（非 llm-compressor 的 compressed-tensors）。权重存储为 safetensors 加 ModelOpt 风格的量化配置。

基础模型 Qwen3.5-35B-A3B 是 **混合专家模型（MoE）**：256 个总专家，每个 token 激活 8 个路由专家 + 1 个共享专家，总参数约 35B 但每次前向传播仅约 3B 活跃参数。NVFP4 精度下权重存储约 **10–12 GB**，完全适合 RTX 5090 的 32 GB VRAM，还有充裕的 KV 缓存空间。

加载命令：

```bash
vllm serve AxionML/Qwen3.5-35B-A3B-NVFP4 \
  --quantization modelopt_fp4 \
  --kv-cache-dtype fp8_e4m3 \
  --tensor-parallel-size 1 \
  --max-model-len 32768 \
  --reasoning-parser qwen3
```

### 兼容性矩阵

| 组件             | 最低版本    | 推荐版本                             | 备注                                          |
| ---------------- | ----------- | ------------------------------------ | --------------------------------------------- |
| **vLLM**         | v0.16.0     | v0.18.0 / nightly                    | SM120 NVFP4 MoE 修复在 v0.16.0+               |
| **CUDA Toolkit** | 12.8        | 12.8（nixpkgs 默认）                 | SM120 需要 12.8+；13.0 有 nixpkgs 构建问题    |
| **PyTorch**      | 2.9.0+cu128 | 2.10.0+cu128                         | SM120 支持从 2.9.0 开始                       |
| **transformers** | 4.56.0      | 4.57.x                               | Qwen3.5 MoE 架构支持                          |
| **Windows 驱动** | 572.xx+     | 最新 Game Ready                      | 需支持 CUDA 12.8；在 WSL2 中检查 `nvidia-smi` |
| **WSL2 内核**    | 2.7.0       | 最新                                 | Blackwell CUDA 图支持                         |
| **FlashInfer**   | —           | 设置 `VLLM_USE_FLASHINFER_MOE_FP4=1` | 启用优化的 FP4 MoE 内核                       |

---

## 四、实用 flake.nix：WSL2 上的 vLLM NVFP4 推理环境

基于上述约束 —— nixpkgs vLLM 版本过旧、NVFP4 需要最新 vLLM、WSL2 需要驱动桥接 —— 推荐的 flake 采用 **buildFHSEnv 方案，CUDA 12.8 来自 nixpkgs，vLLM 通过 `uv` 安装**。这在系统环境层面提供 Nix 级别的可复现性，同时允许使用 PyPI 上最新的 vLLM：

```nix
{
  description = "vLLM NVFP4 inference on WSL2 with RTX 5090";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  nixConfig = {
    extra-substituters = [ "https://cache.nixos-cuda.org" ];
    extra-trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    cuda = pkgs.cudaPackages_12_8;

    fhsEnv = pkgs.buildFHSEnv {
      name = "vllm-nvfp4";
      targetPkgs = pkgs: [
        pkgs.python312
        pkgs.python312Packages.pip
        pkgs.uv
        pkgs.git
        pkgs.stdenv.cc
        pkgs.zlib
        pkgs.ncurses5

        # CUDA 12.8 工具链组件
        cuda.cudatoolkit
        cuda.cuda_cudart
        cuda.cuda_nvcc
        cuda.cudnn
        cuda.libcublas
        cuda.libcusparse
        cuda.libcurand
        cuda.nccl
        cuda.cuda_nvrtc
      ];

      profile = ''
        # WSL2：桥接宿主机 NVIDIA 驱动存根
        export LD_LIBRARY_PATH=/usr/lib/wsl/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

        export CUDA_HOME=${cuda.cudatoolkit}
        export CUDA_PATH=${cuda.cudatoolkit}
        export PATH=${cuda.cuda_nvcc}/bin:$PATH

        # FlashInfer FP4 MoE 内核（Blackwell 优化）
        export VLLM_USE_FLASHINFER_MOE_FP4=1

        # 如果 venv 存在则激活
        if [ -d .venv ]; then
          source .venv/bin/activate
        fi
      '';

      runScript = "bash";
    };
  in {
    devShells.${system} = {
      default = fhsEnv.env;
    };

    # 便捷入口
    apps.${system}.default = {
      type = "app";
      program = "${fhsEnv}/bin/vllm-nvfp4";
    };
  };
}
```

### 首次使用流程

```bash
# 进入 Nix 开发环境
nix develop  # 或: nix run .#default

# 创建 Python 虚拟环境并安装 vLLM
python -m venv .venv && source .venv/bin/activate
uv pip install vllm==0.18.0 transformers>=4.57.0

# 验证 CUDA 检测
python -c "import torch; print(torch.cuda.get_device_name(0))"
# 预期输出: NVIDIA GeForce RTX 5090

# 启动模型服务
vllm serve AxionML/Qwen3.5-35B-A3B-NVFP4 \
  --quantization modelopt_fp4 \
  --kv-cache-dtype fp8_e4m3 \
  --max-model-len 32768
```

### 纯 Nix 方案参考（nixpkgs vLLM 追上 v0.16.0+ 后可用）

```nix
environment.systemPackages = [
  (pkgs.python3.withPackages (ps: [ ps.vllm ]))
];
nixpkgs.config = {
  allowUnfree = true;
  cudaSupport = true;
  cudaCapabilities = [ "12.0" ];  # SM120 = RTX 5090
};
```

此方案目前因版本滞后不适用于 SM120 NVFP4。

---

## 五、关键注意事项与排坑指南

### `libcuda.so.1` 问题是最大的 Nix+WSL2 摩擦点

在 NixOS（包括 NixOS-WSL）上，Nix 构建的二进制文件期望在 `/run/opengl-driver/lib/` 找到 `libcuda.so.1`。在 WSL2 上，它位于 `/usr/lib/wsl/lib/`。NixOS-WSL 的 `wsl.useWindowsDriver = true` 通过将 WSL 驱动库符号链接到图形驱动路径来桥接，但这只覆盖 NixOS 管理的二进制文件。对于 buildFHSEnv 内 pip 安装的 vLLM，profile 中的 `LD_LIBRARY_PATH=/usr/lib/wsl/lib` 导出处理此问题。**绝对不要在 WSL2 内安装 NVIDIA Linux GPU 驱动** —— 这会覆盖宿主机驱动存根，完全破坏 GPU 访问。

### CUDA 二进制缓存至关重要

从源码构建 CUDA 包需要数小时。`cache.nixos-cuda.org`（2025年11月从 `cuda-maintainers.cachix.org` 迁移）提供预构建的 CUDA 工具链包。将 nixpkgs 固定到经 `hercules-ci.com/github/SomeoneSerge/nixpkgs-cuda-ci` 测试的 commit 以获得最大缓存命中率。没有此缓存，仅 CUDA 工具链编译就需要 **2–4 小时**。

### 避免全局 `cudaSupport = true`

在 `nixpkgs.config` 中设置此项会强制每个检查该标志的包进行 CUDA 构建 —— 包括浏览器和媒体播放器等无关包，导致大量不必要的重编译（issue #457218 有文档记录）。优先使用逐包覆写或 buildFHSEnv 方案。

### `torch-bin` vs 源码构建 `torch`

nixpkgs 的 `pytorch-bin` 包在 wheel 内捆绑了 CUDA 库（libcudart、libcublas 等）。如果同时在 `LD_LIBRARY_PATH` 上存在 nixpkgs `cudaPackages`，可能产生冲突。在 buildFHSEnv 方案中，pip 的 `torch` wheel 也捆绑 CUDA —— 这实际上是有利的，因为它确保 torch 和 CUDA 版本匹配。Nix 提供的 CUDA 工具链主要用于 vLLM 内核编译，而非 torch 运行时。

### vLLM 的 transformers 版本约束

vLLM 0.12–0.14 要求 `transformers >=4.56.0, <5`。Qwen3.5 架构需要 transformers 4.56+（满足），但 `<5` 上限与需要 transformers 5.x 的更新模型架构冲突。vLLM **v0.16.0** 添加了 transformers v5 兼容补丁（PR #33977、#33683），使用 v0.16.0+ 可避免此冲突。

---

## 六、总结与建议

本部署的可行架构是 **两层可复现策略**：Nix 通过 buildFHSEnv flake 固定 CUDA 工具链（12.8）、系统库和 Python 版本；环境内的固定 `requirements.txt` 或 `uv.lock` 固定 vLLM、PyTorch 和 transformers 到精确版本。这种混合方案牺牲了纯 Nix 的密封性以换取实际可用性 —— 这是 Nix ML 社区已广泛接受的权衡（NixOS Wiki CUDA 页面推荐 buildFHSEnv，nixified-ai、llama.cpp 的 flake 等主要社区项目也采用类似的务实方案）。

对于 RTX 5090，**SM120 NVFP4 MoE 支持仍是最薄弱环节。** 多个未关闭 issue 记录了能力族检测 bug，导致静默回退到 Marlin W4A16 内核而非原生 W4A4 NVFP4。用户应通过检查 vLLM 启动日志中的 `Using NVFP4` vs `Falling back to Marlin` 消息来验证实际的内核选择，并准备好运行 nightly 构建或 cherry-pick 修复。

如果 NVFP4 不稳定，**AWQ 4-bit 量化是经过验证的后备方案** —— 在 SM120 上运行可靠，由于 `dxgkrnl` 中 FP8 张量核心暴露的差距，当前 WSL2 基准测试中甚至优于 NVFP4。另外，`Sehyo/Qwen3.5-35B-A3B-NVFP4` 检查点（llm-compressor 的 compressed-tensors 格式，保留 MTP 权重用于推测解码）值得与 AxionML ModelOpt 检查点一起测试，因为它在 vLLM 中使用不同的代码路径，SM120 问题可能更少。
