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

While frontier cloud models (Gemini, Claude) power deep orchestration and complex architecture audits, a dedicated local model provides an offline, zero-quota playground for conversational coding, refactoring, and experimentation without touching cloud rate limits.

---

## 🧠 Model Choice: Qwen 3.8 27B (4-bit)

For the **Apple M5 Pro with 48 GB Unified Memory**, the selected local model is:

* **Model:** `mlx-community/Qwen3.8-27B-4bit` (Apache 2.0)
* **Architecture:** 27 Billion parameters (dense hybrid Gated DeltaNet with native vision encoder)
* **Context Window:** 262,144 tokens native (configure `maxInputTokens` around `65536` in your client to give Agent mode comfortable headroom while keeping KV cache bounded)
* **VRAM / Unified Memory Footprint:**
  * Model Weights: **~16.1 GB** (`14.97 GiB` on disk across 3 safetensors shards)
  * KV Cache (at 64k context): **~4–6 GB**
  * **Total Footprint:** **~20–22 GB**

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
  --port 8080 \
  --temp 0.7 \
  --top-p 0.8 \
  --top-k 20 \
  --max-tokens 8192 \
  --chat-template-args '{"enable_thinking":false}'
```

> [!NOTE] Why thinking mode is disabled for IDE clients
> Qwen 3.8 defaults to `reasoning_effort = xhigh`, and `mlx_lm.server` streams thinking tokens under `delta.reasoning` (which OpenAI-compatible IDE clients commonly ignore, reading only `delta.content` and `delta.reasoning_content`). Passing `{"enable_thinking":false}` with Qwen's instruct sampling (`temp 0.7`, `top_p 0.8`, `top_k 20`) streams answers straight into `delta.content` without empty-response errors or greedy-decoding loops.

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

## 🤖 Connecting to VS Code via Native BYOK

VS Code's built-in **Bring Your Own Key (BYOK)** model picker can connect directly to your local `mlx_lm.server` instance with zero extra extensions required.

### Configuration Specification
Open the Command Palette (`Cmd + Shift + P`) $\rightarrow$ **Chat: Manage Language Models** (or configure `chatLanguageModels.json`) and add a custom OpenAI-compatible endpoint:

```json
[
  {
    "name": "Local MLX (Qwen 3.8 27B)",
    "vendor": "customendpoint",
    "apiKey": "local",
    "apiType": "chat-completions",
    "models": [
      {
        "id": "mlx-community/Qwen3.8-27B-4bit",
        "name": "Local MLX (Qwen 3.8 27B)",
        "url": "http://localhost:8080/v1/chat/completions",
        "toolCalling": true,
        "vision": false,
        "maxInputTokens": 65536,
        "maxOutputTokens": 8192
      }
    ]
  }
]
```

### How to Use
1. Start the server in a terminal: `just serve-qwen-27b`.
2. Open the VS Code Chat panel and select **`Local MLX (Qwen 3.8 27B)`** from the model picker.
3. Chat, prompt refactors, generate tests, or execute tasks offline.

> [!WARNING] Agent mode prints tool calls instead of running them
> **Symptom:** in Agent mode the model replies with text like `TOOL_NAME: run_terminal_command` / `BEGIN_ARG: command ...` and nothing executes.
> **Cause:** if an OpenAI-compatible client assumes no native tool support, it falls back to a text-based tool protocol in the system prompt, which Qwen does not follow reliably.
> **Fix:** ensure `"toolCalling": true` is enabled in your VS Code BYOK entry so standard OpenAI `tools` are sent; `mlx_lm.server` turns them into native `tool_calls` through Qwen's chat template.
> **Verify the server side:**
> ```bash
> curl -s http://localhost:8080/v1/chat/completions -H 'Content-Type: application/json' \
>   -d '{"model":"mlx-community/Qwen3.8-27B-4bit","messages":[{"role":"user","content":"List files in /tmp"}],
>        "tools":[{"type":"function","function":{"name":"ls","parameters":{"type":"object","properties":{"dirPath":{"type":"string"}}}}}]}'
> ```
> A healthy response has `"finish_reason": "tool_calls"`.
> **Context budget:** an Agent-mode request (system prompt + tool schemas + workspace rules) uses ~18–20k of the 64k `maxInputTokens` budget, leaving ~45k for files and multi-turn tool loops. Chat mode is much lighter.

> [!NOTE] Local BYOK, Zero Quotas & Inline Completions
> Local BYOK requests stay 100% on `localhost`—they work offline and consume zero Copilot Free credits. Inline ghost-text completions and Git commit message generation stay on VS Code's built-in Copilot Free, preserving local MLX resources purely for conversational reasoning and refactoring.

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
