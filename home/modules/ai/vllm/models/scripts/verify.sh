#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "vLLM 环境验证"
echo "=========================================="

# 1. 检查 GPU
echo -e "\n[1/6] 检查 GPU..."
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "N/A")
if [ "$GPU_NAME" = "N/A" ]; then
    echo "✗ nvidia-smi 不可用"
    exit 1
fi
echo "✓ GPU: $GPU_NAME"

# 2. 检查 CUDA
echo -e "\n[2/6] 检查 CUDA..."
if [ ! -d "/usr/lib/wsl/lib" ]; then
    echo "✗ WSL CUDA 库不存在"
    exit 1
fi
echo "✓ WSL CUDA 库: /usr/lib/wsl/lib"

# 3. 检查 uv 环境
echo -e "\n[3/6] 检查 uv 环境..."
VENV_PATH="$HOME/.cache/vllm-flake-venv"
if [ ! -d "$VENV_PATH" ]; then
    echo "✗ uv 虚拟环境不存在: $VENV_PATH"
    echo "  运行: home-manager switch"
    exit 1
fi
source "$VENV_PATH/bin/activate"
echo "✓ uv 环境已激活: $VENV_PATH"

# 设置必要的库路径（WSL + nix）
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$HOME/.nix-profile/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# 4. 检查 vLLM
echo -e "\n[4/6] 检查 vLLM..."
VLLM_VERSION=$(python -c "import vllm; print(vllm.__version__)" 2>/dev/null || echo "N/A")
if [ "$VLLM_VERSION" = "N/A" ]; then
    echo "✗ vLLM 未安装"
    exit 1
fi
echo "✓ vLLM $VLLM_VERSION"

# 5. 检查 PyTorch CUDA
echo -e "\n[5/6] 检查 PyTorch CUDA..."
TORCH_CUDA=$(python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null || echo "False")
if [ "$TORCH_CUDA" != "True" ]; then
    echo "✗ PyTorch CUDA 不可用"
    exit 1
fi
TORCH_VERSION=$(python -c "import torch; print(torch.__version__)" )
echo "✓ PyTorch $TORCH_VERSION (CUDA available)"

# 6. 检查模型配置
echo -e "\n[6/6] 检查模型配置..."
CONFIG_COUNT=$(find "$PROJECT_ROOT" -name "config.nix" -path "*/models/*" | wc -l)
if [ "$CONFIG_COUNT" -eq 0 ]; then
    echo "✗ 没有找到模型配置"
    exit 1
fi
echo "✓ 找到 $CONFIG_COUNT 个模型配置"

echo -e "\n=========================================="
echo "✓ 所有检查通过"
echo "=========================================="
