---
title: "Cloud AI Providers & Models"
date: 2026-09-20
tags:
  - ai/cloud
  - llm
status: evergreen
aliases:
  - "Local LLMs with MLX"
---

# ☁️ Cloud AI Providers & Models

The workstation runs **no local model weights**. All inference is remote, over provider APIs. This note is the reference for which model to reach for, which tool routes to which provider, and how credentials are handled.

> [!IMPORTANT] Why cloud-first
> A 48 GB M5 Pro can host a 32B model at 6-bit, but only by surrendering 25–34 GB of unified memory that native builds, OrbStack containers, and Nix derivations need. Frontier cloud models outperform anything that fits locally, and the memory stays available for actual development work. Retiring local serving reclaimed ~59 GB of SSD alongside that memory.

---

## 🧠 Model Tiering

Pick the cheapest tier that clears the task's quality bar. Escalating is cheap; discovering a subtle wrong answer later is not.

| Tier | Model ID | Context | Use for |
| :--- | :--- | :--- | :--- |
| **Deep reasoning** | `claude-opus-5` | 1M | Multi-file refactors, architecture decisions, debugging with incomplete information |
| **Daily driver** | `claude-sonnet-5` | 1M | Routine implementation, code review, writing tests, documentation |
| **Latency-critical** | `claude-haiku-4-5` | 200K | Tab autocomplete, where response time dominates output quality |

> [!TIP] Use the exact model ID strings
> Do **not** append date suffixes (`claude-opus-5`, never `claude-opus-5-20260401`). Dated variants are a stale convention from older model generations and will fail.

---

## 🔀 Provider Routing by Tool

Each editor reaches a different provider. Knowing which is which avoids configuring the wrong surface.

| Tool | Provider | Notes |
| :--- | :--- | :--- |
| **Antigravity IDE** | Google Gemini | Native agent canvas. Antigravity Tab uses Google's proprietary speculative decoding for autocomplete — it cannot be rerouted to another provider. |
| **Roo Code** | Anthropic Claude, xAI Grok | Model switcher inside the IDE; the path for Claude and Grok. |
| **VS Code + Continue** | Anthropic Claude | Config template at `client-tools/ai-dev/continue-config.json`. |
| **Claude Code** | Anthropic Claude | Terminal-native agent, installed declaratively via `pkgs.claude-code` in the flake. |
| **Claude Desktop** | Anthropic Claude | Official macOS desktop application, installed declaratively via Homebrew cask `claude`. |

---

## 🔐 Credential Hygiene

API keys are the one genuinely sensitive part of this setup.

* **Never commit a key.** The tracked `continue-config.json` carries `REPLACE_WITH_ANTHROPIC_API_KEY` placeholders. Substitute real values only in your local copy at `~/.continue/config.json`, which is outside version control.
* **Prefer the environment.** Export `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` / `XAI_API_KEY` in your shell profile, or let the tool store them in the macOS keychain.
* **Treat this repository as public** regardless of its current visibility — a key in git history is compromised the moment it lands, and rotating it is the only remedy.

---

## ✍️ Tab Autocomplete vs. Chat

These have genuinely different requirements, and the split survived the move to cloud:

| Modality | Target latency | Model choice |
| :--- | :--- | :--- |
| **Tab autocomplete** | `< 200ms` per pause | Smallest capable model — `claude-haiku-4-5` |
| **Chat, refactoring, agents** | `1–30s` acceptable | `claude-sonnet-5`, escalating to `claude-opus-5` |

The old local setup targeted `< 50ms` autocomplete because inference was on-device. Over a network that budget is unreachable, so cloud autocomplete triggers on pause rather than per keystroke. If autocomplete latency becomes intrusive, prefer Antigravity Tab — it is purpose-built for this and is the one place a proprietary engine beats a general-purpose model.

---

## 🗄️ Decommissioning Record (September 2026)

Retained for context on what was removed and what to expect if you find stale references:

* **Removed:** `oMLX.app`, ephemeral `mlx-lm` servers on ports `8080`/`8081`, the `serve-ai` Justfile recipe, and `client-tools/ai-dev/setup-mac-mlx.sh`.
* **Reclaimed:** ~59 GB SSD (Hugging Face weight cache at `~/.cache/huggingface/hub/`), 25–34 GB unified memory.
* **Leftover cache:** if that directory still exists on an older machine image, it is safe to delete:
  ```bash
  du -sh ~/.cache/huggingface/hub/
  rm -rf ~/.cache/huggingface/hub/
  ```

---

## Related Notes
* [[Dual-Tier AI Workflow]]
* [[Hardware & Memory Budget]]
* [[IDE Configuration Guide]]
* [[System Architecture]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
