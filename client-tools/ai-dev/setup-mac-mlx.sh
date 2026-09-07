#!/usr/bin/env bash
# ==============================================================================
# setup-mac-mlx.sh
# Automated Apple Silicon Setup for MLX / oMLX Zero-Latency Local Code Models
# ==============================================================================

set -euo pipefail

echo "============================================================"
echo "🚀 Setting up Apple MLX / oMLX on Apple Silicon Workstation"
echo "============================================================"

# 1. Architecture & OS Verification
OS_NAME=$(uname -s)
ARCH_NAME=$(uname -m)

if [ "$OS_NAME" != "Darwin" ] || [ "$ARCH_NAME" != "arm64" ]; then
    echo "❌ Error: This script is intended for macOS on Apple Silicon (arm64)."
    exit 1
fi

echo "✅ Verified Apple Silicon architecture ($ARCH_NAME on $OS_NAME)."

# 2. Tune Metal Wired Memory Limit (Ceiling to 40 GB)
echo ""
echo "⚙️  Configuring Metal GPU memory ceiling (40960 MB)..."
CURRENT_LIMIT=$(sysctl -n iogpu.wired_mem_limit 2>/dev/null || echo "0")
if [ "$CURRENT_LIMIT" != "40960" ]; then
    echo "Requesting sudo to set iogpu.wired_mem_limit=40960..."
    sudo sysctl iogpu.wired_mem_limit=40960
    echo "✅ Applied runtime wired memory limit: 40 GB."
else
    echo "✅ Metal wired memory limit already set to 40 GB."
fi

# 3. Setup Python Virtual Environment for MLX
MLX_ENV_DIR="$HOME/.mlx-env"
if [ ! -d "$MLX_ENV_DIR" ]; then
    echo ""
    echo "📦 Creating Python virtual environment at $MLX_ENV_DIR..."
    python3 -m venv "$MLX_ENV_DIR"
fi

echo "📥 Installing / Updating Apple MLX & mlx-lm packages..."
"$MLX_ENV_DIR/bin/pip" install --upgrade pip
"$MLX_ENV_DIR/bin/pip" install --upgrade mlx mlx-lm huggingface_hub

# 4. Download Recommended Quantized Models
echo ""
echo "💾 Pre-caching MLX 4-bit models from mlx-community..."
echo " - Qwen 2.5 Coder 14B (FIM Autocomplete)"
"$MLX_ENV_DIR/bin/python" -c '
from huggingface_hub import snapshot_download
snapshot_download("mlx-community/Qwen2.5-Coder-14B-Instruct-4bit")
'

echo " - Qwen 2.5 Coder 32B (In-Editor Chat & Refactor)"
"$MLX_ENV_DIR/bin/python" -c '
from huggingface_hub import snapshot_download
snapshot_download("mlx-community/Qwen2.5-Coder-32B-Instruct-4bit")
'

echo ""
echo "============================================================"
echo "🎉 Setup Complete!"
echo "============================================================"
echo ""
echo "To start the local OpenAI-compatible MLX API server, run:"
echo ""
echo "  $MLX_ENV_DIR/bin/python -m mlx_lm.server --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit --port 8000"
echo ""
echo "Or start with the 14B model for autocomplete focus:"
echo ""
echo "  $MLX_ENV_DIR/bin/python -m mlx_lm.server --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit --port 8000"
echo ""
