---
title: "Local LLMs with Apple MLX"
date: 2026-11-17
tags:
  - ai/local
  - mlx
  - qwen
  - macos
  - m5-pro
status: in-progress
aliases: []
---

# ⚡ Local LLMs with Apple MLX (On-Demand Inference)

This guide documents the workstation's setup for running **local open-weight LLMs** on Apple Silicon using [Apple MLX](https://github.com/ml-explore/mlx) and serving them on-demand via `mlx-lm` and **Astral `uvx`**.

While frontier cloud models (Gemini Flash/Pro, Claude 3.7/Sonnet 5, xAI Grok) power deep orchestration and complex architecture audits, a dedicated local model provides an offline, zero-quota playground for conversational coding, refactoring, and experimentation without touching cloud rate limits.

---

## 🧠 Model Choice: Qwen 3.8 27B (4-bit)

For the **Apple M5 Pro with 48 GB Unified Memory**, the selected local model is:

* **Model:** `mlx-community/Qwen3.8-27B-4bit` (Apache 2.0)
* **Architecture:** 27 Billion parameters (dense hybrid Gated DeltaNet with native vision encoder)
* **Context Window:** 262,144 tokens native (Roo Code profile sets `32768` to keep KV cache bounded)
* **VRAM / Unified Memory Footprint:**
  * Model Weights: **~16.1 GB** (`14.97 GiB` on disk across 3 safetensors shards)
  * KV Cache (at 32k context): **~2–3 GB**
  * **Total Footprint:** **~18–19 GB**

### Why Qwen 3.8 27B?
1. **Modern Reasoning & Agentic Fidelity:** Adds native thinking controls (`reasoning_effort`), 262K native context, and strong tool-calling and coding performance over the older Qwen 2.5 Coder 32B baseline.
2. **Headroom Preservation:** Running at 4-bit consumes ~18–19 GB, leaving **~29–30 GB free** for macOS, OrbStack containers, and Nix derivations.
3. **On-Demand Lifecycle:** Served ephemerally via `just serve-qwen-27b`. When closed, unified memory is immediately returned to macOS with zero permanent background drain. *(For multimodal image/video prompts, run via `uvx --from mlx-vlm mlx_vlm.generate`.)*

---

## ⚡ Zero-Bloat Execution via `uvx`

Adhering to the workstation's strict anti-bloat and Python isolation invariants, `mlx-lm` is **never installed globally**. It is executed on-demand in an isolated, ephemeral virtual environment via Astral `uvx`.

### Starting the Server
From the workstation directory or terminal:

```bash
# Launch the local OpenAI-compatible server on port 8080
just serve-qwen-27b
```

Under the hood, this executes:
```bash
uvx --from mlx-lm mlx_lm.server \
  --model mlx-community/Qwen3.8-27B-4bit \
  --port 8080
```

The server exposes standard OpenAI-compatible endpoints:
* **Base URL:** `http://localhost:8080/v1`
* **Chat Completions:** `http://localhost:8080/v1/chat/completions`

### Quick CLI Prompt Verification
To run a fast prompt test against Metal GPU acceleration without launching the HTTP server:

```bash
just test-prompt
```

Or manually:
```bash
uvx --from mlx-lm mlx_lm.generate \
  --model mlx-community/Qwen3.8-27B-4bit \
  --prompt "Write a Python script that benchmarks GPU memory bandwidth on Apple Silicon."
```

---

## 🤖 Connecting to Roo Code in VS Code

Roo Code (`RooVeterinaryInc.roo-cline`) inside **VS Code** is pre-configured with the **"Local MLX (Qwen 3.8 27B)"** provider profile.

### Configuration Specification
Declared in `templates/flake.nix` (home-manager `home.file`) and linked read-only to `~/.config/roo-code/settings.json`:

```json
{
  "Local MLX (Qwen 3.8 27B)": {
    "id": "local-mlx-qwen-27b",
    "apiProvider": "openai",
    "openAiBaseUrl": "http://localhost:8080/v1",
    "openAiApiKey": "local",
    "openAiModelId": "mlx-community/Qwen3.8-27B-4bit",
    "openAiCustomModelInfo": {
      "contextWindow": 32768,
      "maxTokens": 8192,
      "supportsImages": false,
      "supportsPromptCache": false
    }
  }
}
```

### How to Use
1. Start the server in a terminal: `just serve-qwen-27b`.
2. Open **Roo Code** in the VS Code sidebar.
3. In the model dropdown selector, choose **"Local MLX (Qwen 3.8 27B)"**.
4. Chat, prompt refactors, generate tests, or execute tasks offline.

> [!NOTE] Tab Autocomplete vs. Conversational Coding
> Roo Code acts as an **autonomous agent** and chat engine. Real-time inline ghost-text code completion as you type is handled seamlessly by **Antigravity Tab** (Google's native speculative decoding engine). This preserves local MLX resources purely for conversational reasoning and refactoring.

---

## 🧹 Memory & Disk Cleanliness

* **Weight Cache Location:** Weights downloaded by `mlx-lm` reside in `~/.cache/huggingface/hub/`.
* **Checking Disk Usage:**
  ```bash
  du -sh ~/.cache/huggingface/hub/
  ```
* **Purging Weights:** If SSD space is ever needed, the cache can be pruned without affecting system files:
  ```bash
  rm -rf ~/.cache/huggingface/hub/models--mlx-community--Qwen3.8-27B-4bit
  ```

---

## Related Notes
* [[Dual-Tier AI Workflow]]
* [[Hardware & Memory Budget]]
* [[IDE Configuration Guide]]
* [[Cloud AI Providers & Models]]
* [[Nix-Darwin Guide]]
