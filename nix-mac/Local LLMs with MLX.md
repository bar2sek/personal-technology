---
title: Local LLMs with MLX
tags:
  - mlx
  - llm
  - qwen
  - setup
  - python
created: 2026-08-24
---

# ⚡ Local LLMs with Apple MLX

## Why Apple MLX?
[Apple MLX](https://github.com/ml-explore/mlx) is an open-source machine learning framework engineered specifically for Apple Silicon and Metal GPU acceleration. 

* **Zero-copy memory sharing:** CPU and GPU share the same memory without PCIe transfer overhead.
* **Native 4-bit / 8-bit quantization:** Minimizes memory footprint while preserving accuracy.
* **Optimized token generation:** Outperforms generic CPU/cross-platform runtimes on M-series chips.

---

## Zero-Bloat Execution with `uv`

To avoid polluting your global macOS environment with Python packages, use **`uv`** (by Astral) to run `mlx-lm` in ephemeral virtual environments.

### 1. Install `uv`
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2. Launch OpenAI-Compatible MLX Server

Run the server on-demand without installing anything permanently into system Python:

#### Primary Workhorse: Qwen 2.5 Coder 32B (High-Quant 6-bit / 8-bit)
```bash
# Launch via oMLX (preferred for Paged SSD KV Caching)
just serve-omlx

# Or run ephemeral server via uvx:
uvx --from mlx-lm mlx_lm.server \
  --model mlx-community/Qwen2.5-Coder-32B-Instruct-6bit \
  --port 8080 \
  --chat-template-name chatml
```

> [!TIP]
> **Quantization Selection for 48GB M5 Pro:**
> * **6-bit (`Qwen2.5-Coder-32B-Instruct-6bit`):** ~25GB VRAM. Provides >99.7% float16 accuracy while leaving a 13GB+ cushion for OrbStack and Antigravity IDE.
> * **8-bit (`Qwen2.5-Coder-32B-Instruct-8bit`):** ~33.5GB VRAM. Near-lossless precision, utilizing the maximum safe Metal memory boundary on 48GB.
> * Smaller models (1.5B and 14B) have been retired to eliminate background memory contention.

---

## 🚀 Primary Inference Engine: oMLX

[oMLX](https://github.com/jundot/omlx) is your **primary, dedicated inference engine** for local coding models on Apple Silicon. Installed declaratively via `nix-mac` as `/Applications/oMLX.app`, it provides high-throughput token generation paired with **Paged SSD KV Caching**.

### Why oMLX is the Standard for Agentic & Multi-Turn Coding
In multi-turn coding sessions (chat, follow-ups, or agent loops), assistants repeatedly re-send large prompt prefixes (system instructions + codebase files + chat history).
* With vanilla `mlx-lm` or `llama.cpp`, the server recomputes the entire context from scratch on every turn, causing **5–15 second latency delays (Time-to-First-Token)**.
* **Paged SSD KV Caching:** oMLX persists historical and branched KV cache blocks to your Mac's internal NVMe SSD in `safetensors` format (`~/.omlx/cache`). When VS Code sends a new turn with a known prefix, oMLX restores the cached state in milliseconds, dropping TTFT to **$< 0.5$ seconds**.

### Key Features of oMLX
1. **Multi-Model Continuous Batching:** Simultaneously handles concurrent requests (e.g. Chat and Tab Autocomplete) without blocking.
2. **Auto Model Discovery:** Automatically discovers models cached in `~/.cache/huggingface/hub/` without manual copying.
3. **Dual API Compatibility:** Exposes standard **OpenAI** (`/v1/chat/completions`) and **Anthropic** (`/v1/messages`) endpoints on `localhost:8080`.
4. **Native macOS Menu Bar App:** Monitor token speeds, VRAM, and active requests with zero Electron bloat.

### Launching oMLX
```bash
# Start multi-model server on port 8080 (via Justfile):
just serve-omlx

# Or start as a managed background daemon:
just omlx-start

# Check health and menu bar status:
just omlx-status
```

---

## 🛠️ Secondary Fallback: `mlx-lm` via `uv`

For quick CLI tests and one-off benchmarks (without launching the full server), use `uvx` for ephemeral execution:

```bash
# 5-second CLI generation benchmark
uvx --from mlx-lm mlx_lm.generate \
  --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit \
  --prompt "Write a Python script that benchmarks GPU memory bandwidth on Apple Silicon."
```

---

---

## ✍️ Tab Autocomplete (FIM) vs. Chat / Agent Models

Tab autocomplete has fundamentally different latency and architectural requirements than chat/agent pair-programming:

| Modality | Target Latency | Best Local Model Size | Recommended Tooling |
| :--- | :--- | :--- | :--- |
| **Tab Autocomplete (FIM)** | `< 50ms` per keystroke | **Qwen 2.5 Coder 1.5B / 7B (Base)** | **VS Code + Continue.dev** |
| **Chat, Refactoring & Agents** | `200ms – 1s` | **Qwen 2.5 Coder 32B (Instruct)** | **Antigravity**, **Cursor**, **Aider** |

### How IDEs Handle Local Tab Completion:
1. **VS Code + [Continue.dev](https://continue.dev)**: The industry standard for local tab-completion and inline code generation. Allows you to set `tabAutocompleteModel` to your local MLX/Ollama endpoint using a lightweight model (`qwen2.5-coder:1.5b-base`).
2. **Antigravity IDE**: Uses **Antigravity Tab** (Google DeepMind's proprietary next-intent speculative decoding engine). It is optimized for cloud sub-50ms latency and does not natively support rerouting autocomplete to a custom local endpoint.
3. **Cursor**: Features built-in custom OpenAI API support for chat, while its proprietary "Cursor Tab" routes through Cursor's multi-token prediction engine.

---

## Model Cache Location & Cleanup

MLX caches downloaded Hugging Face model weights in:
`~/.cache/huggingface/hub/`

To inspect or clean up model storage:
```bash
# Check size of downloaded models
du -sh ~/.cache/huggingface/hub/

# Delete a specific model to free disk space
rm -rf ~/.cache/huggingface/hub/models--mlx-community--Qwen2.5-Coder-32B-Instruct-4bit
```

---

## Related Notes
* [[Hardware & Memory Budget]]
* [[System Architecture]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
