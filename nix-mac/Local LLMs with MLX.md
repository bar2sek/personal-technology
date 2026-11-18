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
* **Context Window:** 262,144 tokens native (Continue config sets `contextLength: 65536` to give Agent mode comfortable headroom while keeping KV cache bounded)
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

## 🤖 Connecting to Continue in VS Code

Continue (`continue.continue`) inside **VS Code** is pre-configured with the **`Local MLX (Qwen 3.8 27B)`** model entry.

### Configuration Specification
Declared in `templates/home.nix` (`home.file`) and linked read-only to `~/.continue/config.yaml`:

```yaml
- name: Local MLX (Qwen 3.8 27B)
  provider: openai
  model: mlx-community/Qwen3.8-27B-4bit
  apiBase: http://localhost:8080/v1
  apiKey: local
  contextLength: 65536
  defaultCompletionOptions:
    maxTokens: 8192
    temperature: 0.7
    topP: 0.8
  capabilities:
    - tool_use
  roles:
    - chat
    - edit
    - apply
```

### How to Use
1. Start the server in a terminal: `just serve-qwen-27b`.
2. Open **Continue** in the VS Code sidebar.
3. In the model dropdown selector, choose **`Local MLX (Qwen 3.8 27B)`**.
4. Chat, prompt refactors, generate tests, or execute tasks offline.

> [!WARNING] Agent mode prints tool calls instead of running them
> **Symptom:** in Agent mode the model replies with text like `TOOL_NAME: run_terminal_command` / `BEGIN_ARG: command ...` and nothing executes.
> **Cause:** with `provider: openai` and a model name Continue doesn't recognize, Continue assumes no native tool support and falls back to a text-based tool protocol in the system prompt. Qwen doesn't follow that format reliably.
> **Fix:** `capabilities: [tool_use]` (above) makes Continue send standard OpenAI `tools`; `mlx_lm.server` turns them into native `tool_calls` through Qwen's chat template.
> **Verify the server side:**
> ```bash
> curl -s http://localhost:8080/v1/chat/completions -H 'Content-Type: application/json' \
>   -d '{"model":"mlx-community/Qwen3.8-27B-4bit","messages":[{"role":"user","content":"List files in /tmp"}],
>        "tools":[{"type":"function","function":{"name":"ls","parameters":{"type":"object","properties":{"dirPath":{"type":"string"}}}}}]}'
> ```
> A healthy response has `"finish_reason": "tool_calls"`.
> **Context budget:** an Agent-mode request (system prompt + 13 tool schemas + `AGENTS.md` rules) uses ~18–20k of the 64k `contextLength`, leaving ~45k for files and multi-turn tool loops. Chat mode is much lighter.

> [!NOTE] Tab Autocomplete vs. Conversational Coding
> Continue handles conversational chat, edits, and applies. Real-time inline ghost-text code completion as you type is handled seamlessly by **Antigravity Tab** (Google's native speculative decoding engine, with `continue.enableTabAutocomplete = false`). This preserves local MLX resources purely for conversational reasoning and refactoring.

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
