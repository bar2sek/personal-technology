#!/usr/bin/env bash
# ==============================================================================
# setup-mac-mlx.sh
# Zero-Bloat Apple Silicon Setup for MLX / oMLX Local Code Models (via Astral uv)
# ==============================================================================

set -euo pipefail

echo "============================================================"
echo "🚀 Setting up Apple MLX / oMLX (Zero-Bloat via uv/uvx)"
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

# 3. Ensure Astral uv is installed
if ! command -v uv &> /dev/null; then
    echo ""
    echo "📦 Installing Astral uv (Zero-Bloat package runner)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "✅ Astral uv is ready ($(uv --version))."

# 4. Pre-download / Cache MLX Community Models
echo ""
echo "💾 Pre-caching MLX 4-bit models from Hugging Face..."
echo " - Qwen 2.5 Coder 14B (FIM Autocomplete)"
uvx --from huggingface_hub hf download mlx-community/Qwen2.5-Coder-14B-Instruct-4bit

echo " - Qwen 2.5 Coder 32B (In-Editor Chat & Refactor)"
uvx --from huggingface_hub hf download mlx-community/Qwen2.5-Coder-32B-Instruct-4bit

echo ""
echo "============================================================"
echo "🎉 Setup Complete!"
echo "============================================================"
echo ""
echo "To launch dual-port serving, use Justfile from nix-mac or homelab:"
echo ""
echo "  just serve-all   # in nix-mac"
echo "  just serve-ai    # in talos-aws-homelab"
echo ""
echo "Or start individual servers via uvx on-demand:"
echo "  Chat (:8080):"
echo "    uvx --from mlx-lm mlx_lm.server --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit --port 8080 --chat-template-name chatml"
echo ""
echo "  Tab Autocomplete (:8081):"
echo "    uvx --from mlx-lm mlx_lm.server --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit --port 8081 --chat-template-name chatml"
echo ""
