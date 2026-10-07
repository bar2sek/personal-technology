---
title: "Local LLMs with Apple MLX"
date: 2026-10-06
tags:
  - ai/local
  - mlx
  - qwen
  - macos
  - m5-pro
status: evergreen
aliases: []
---

# ⚡ Local LLMs with Apple MLX (On-Demand Inference)

This guide documents the workstation's setup for running **local open-weight LLMs** on Apple Silicon using [Apple MLX](https://github.com/ml-explore/mlx) and serving them on-demand via `mlx-lm` and **Astral `uvx`**.

While frontier cloud models (Gemini Flash/Pro, Claude 3.7/Sonnet 5, xAI Grok) power deep orchestration and complex architecture audits, a dedicated local model provides an offline, zero-quota playground for conversational coding, refactoring, and experimentation without touching cloud rate limits.

---

## 🧠 Model Choice: Qwen 2.5 Coder 32B Instruct (4-bit)

For the **Apple M5 Pro with 48 GB Unified Memory**, the selected local model is:

* **Model:** `mlx-community/Qwen2.5-Coder-32B-Instruct-4bit`
* **Architecture:** 32.5 Billion parameters (dense)
* **Context Window:** 32,768 tokens (up to 128k with RoPE scaling)
* **VRAM / Unified Memory Footprint:**
  * Model Weights: **~19.5 GB**
  * KV Cache (at 32k context): **~2.5 GB**
  * **Total Footprint:** **~22 GB**
* **Inference Speed:** ~45–60 tokens/sec on M5 Pro GPU cores.

### Why Qwen 2.5 Coder 32B?
1. **Best-in-Class Coding Performance:** Competes with much larger 70B models and older GPT-4 checkpoints on coding benchmarks (HumanEval, MultiPL-E, MBPP).
2. **Headroom Preservation:** Running at 4-bit consumes ~22 GB, leaving **~26 GB free** for macOS, OrbStack containers, and Nix derivations.
3. **On-Demand Lifecycle:** Served ephemerally via `just serve-qwen-32b`. When closed, unified memory is immediately returned to macOS with zero permanent background drain.

---

## ⚡ Zero-Bloat Execution via `uvx`

Adhering to the workstation's strict anti-bloat and Python isolation invariants, `mlx-lm` is **never installed globally**. It is executed on-demand in an isolated, ephemeral virtual environment via Astral `uvx`.

### Starting the Server
From the workstation directory or terminal:

```bash
# Launch the local OpenAI-compatible server on port 8080
just serve-qwen-32b
```

Under the hood, this executes:
```bash
uvx --from mlx-lm mlx_lm.server \
  --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  --port 8080 \
  --chat-template-name chatml
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
  --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  --prompt "Write a Python script that benchmarks GPU memory bandwidth on Apple Silicon."
```

---

## 🤖 Connecting to Roo Code in Antigravity IDE

Roo Code (`RooVeterinaryInc.roo-cline`) inside **Antigravity IDE** is pre-configured with the **"Local MLX (Qwen 2.5 Coder 32B)"** provider profile.

### Configuration Specification
Declared declaratively in `templates/flake.nix` and written to `~/.config/roo-code/settings.json`:

```json
{
  "Local MLX (Qwen 2.5 Coder 32B)": {
    "id": "local-mlx-qwen-32b",
    "apiProvider": "openai",
    "openAiBaseUrl": "http://localhost:8080/v1",
    "openAiApiKey": "local",
    "openAiModelId": "mlx-community/Qwen2.5-Coder-32B-Instruct-4bit",
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
1. Start the server in a terminal: `just serve-qwen-32b`.
2. Open **Roo Code** in the Antigravity IDE sidebar.
3. In the model dropdown selector, choose **"Local MLX (Qwen 2.5 Coder 32B)"**.
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
  rm -rf ~/.cache/huggingface/hub/models--mlx-community--Qwen2.5-Coder-32B-Instruct-4bit
  ```

---

## Related Notes
* [[Dual-Tier AI Workflow]]
* [[Hardware & Memory Budget]]
* [[IDE Configuration Guide]]
* [[Cloud AI Providers & Models]]
* [[Nix-Darwin Guide]]
