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

The workstation is **cloud-first**: day-to-day inference is remote, over provider APIs. Local MLX (now Qwen 3.8 27B) was removed in September 2026 and reinstated as an on-demand local endpoint (`just serve-qwen-27b`, reachable via VS Code native BYOK); see [[Local LLMs with MLX]]. This note is the reference for which model to reach for, which tool routes to which provider, and how credentials are handled.

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
| **Antigravity (VS Code extension, Desktop, `agy` CLI)** | Google Gemini | Native agent canvas in VS Code, standalone orchestrator app, and terminal CLI. |
| **Claude Code Extension** | Anthropic Claude | Official IDE extension (`anthropic.claude-code`) authenticated directly via **Claude.ai subscription** (zero per-token charges). |
| **VS Code Built-In (Copilot Free + BYOK)** | GitHub Copilot Free (commit messages/Tab); BYOK for Azure AI Foundry, AWS Bedrock, Local MLX | Zero extra extensions; built-in commit message generation plus on-demand API/local model testing via `Chat: Manage Language Models`. |
| **Claude Code (CLI)** | Anthropic Claude | Terminal-native agent, installed declaratively via `pkgs.claude-code` in the flake. |
| **Claude Desktop** | Anthropic Claude | Official macOS desktop application, installed declaratively via Homebrew cask `claude`. |

---

## 🔐 Credential Hygiene

API keys are the one genuinely sensitive part of this setup.

* **Never commit a key.** No API keys belong in `templates/home.nix` or tracked config files; enter BYOK keys via VS Code's built-in secret storage, store tokens in the macOS keychain, or export them in untracked `~/.zshrc.local`.
* **Prefer the environment.** Export `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` in your untracked shell profile (`~/.zshrc.local`), or let the tool store credentials in the macOS keychain.
* **Treat this repository as public** regardless of its current visibility — a key in git history is compromised the moment it lands, and rotating it is the only remedy.

---

## ✍️ Tab Autocomplete vs. Chat

These have genuinely different requirements, and the split survived the move to cloud:

| Modality | Target latency | Model choice |
| :--- | :--- | :--- |
| **Tab autocomplete** | `< 200ms` per pause | Smallest capable model — `claude-haiku-4-5` (or VS Code Copilot Free) |
| **Chat, refactoring, agents** | `1–30s` acceptable | `claude-sonnet-5`, escalating to `claude-opus-5` |

The old local setup targeted `< 50ms` autocomplete because inference was on-device. Over a network that budget is unreachable, so cloud autocomplete triggers on pause rather than per keystroke.

---

## 🗄️ Decommissioning Record (September – November 2026)

Retained for context on what was removed and what to expect if you find stale references. *Local MLX has since returned in a lighter, on-demand form (`just serve-qwen-27b`); `oMLX.app`, the second server, `serve-ai`, and Continue stay retired.*

* **Retired (Nov 2026):** **Continue (`continue.continue`)** and `~/.continue/config.yaml` were removed from `nix-mac` after the upstream `continuedev/continue` project was archived in June 2026; ad-hoc Azure AI Foundry, AWS Bedrock, and local MLX testing moved to VS Code's built-in BYOK.
* **Removed (Sep 2026):** `oMLX.app`, ephemeral `mlx-lm` servers on ports `8080`/`8081`, the `serve-ai` Justfile recipe, and `client-tools/ai-dev/setup-mac-mlx.sh`.
* **Reclaimed:** ~59 GB SSD (Hugging Face weight cache at `~/.cache/huggingface/hub/`), 25–34 GB unified memory.
* **Leftover cache:** if that directory still exists on an older machine image, it is safe to delete:
  ```bash
  du -sh ~/.cache/huggingface/hub/
  rm -rf ~/.cache/huggingface/hub/
  ```

---

## Related Notes
* [[Local LLMs with MLX]]
* [[Dual-Tier AI Workflow]]
* [[Hardware & Memory Budget]]
* [[IDE Configuration Guide]]
* [[System Architecture]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
