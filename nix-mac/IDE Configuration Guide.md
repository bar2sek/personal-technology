---
title: IDE Configuration Guide (VS Code + Antigravity)
tags:
  - ide
  - vscode
  - continue
  - configuration
  - setup
  - macos
created: 2026-08-24
---

# ⚡ Antigravity IDE + Multi-Model Setup

**Antigravity IDE** is your primary development environment on macOS—combining the familiarity and extension ecosystem of Code OSS with Google's native agentic architecture and **Roo Code** as a multi-model backup switcher.

* **Unified Agent Canvas:** Seamlessly integrates native Antigravity agent workflows (Gemini Flash/Pro) directly alongside the editor canvas, visual diffs, and terminal.
* **Multi-Model Backup Switcher (Roo Code):** Provides an instant toggle between **Local Qwen 2.5 Coder 32B** (`http://localhost:8080/v1`), **Claude Sonnet 4.6**, and **Claude Opus 5** (Anthropic API) whenever AGY tokens are exhausted.
* **Zero Bloat:** Replaces standalone VS Code entirely; tab-autocomplete background models are removed to free up 100% of local GPU memory.

---

## 🛠️ Step 1: Install Antigravity IDE via `nix-darwin`

Antigravity IDE is declared directly in your `templates/flake.nix` under `homebrew.casks`:
```nix
homebrew.casks = [
  "antigravity-ide"
  "antigravity"
  "obsidian"
  "orbstack"
  "appcleaner"
  "ghostty"
];
```

---

## ⚙️ Step 2: Essential Extensions

Install the recommended extensions to match the workstation's typography, aesthetics, and autonomous backup capabilities:

```bash
# Autonomous Multi-Model Agent (Local MLX + Claude API Backup)
agy-ide --install-extension RooVeterinaryInc.roo-cline

# Aesthetics & Typography
agy-ide --install-extension PKief.material-icon-theme
agy-ide --install-extension enkia.tokyo-night

# Language & Tooling Support
agy-ide --install-extension bbenoist.Nix
agy-ide --install-extension hashicorp.terraform
agy-ide --install-extension amazonwebservices.aws-toolkit-vscode
agy-ide --install-extension ms-vscode.azure-account
agy-ide --install-extension ms-azuretools.vscode-azureresourcegroups
agy-ide --install-extension ms-azuretools.vscode-docker
agy-ide --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
```

---

## 🤖 Step 3: Configuring Roo Code as the Backup Switcher

Roo Code profiles are managed **declaratively** via `~/.config/roo-code/settings.json` and automatically imported into Antigravity IDE on startup via `"roo-cline.autoImportSettingsPath"`.

### Profile 1: Local M5 Pro MLX ($0 / Unlimited)
* **Provider:** `OpenAI Compatible`
* **Base URL:** `http://localhost:8080/v1`
* **Model ID:** `mlx-community--Qwen2.5-Coder-32B-Instruct-6bit`
* **Use Case:** Free autonomous file edits, unit test generation, log diagnosis, and offline work.

### Profile 2: Claude Sonnet 4.6 (Frontier Backup)
* **Provider:** `Anthropic`
* **API Key:** Stored securely in your environment (`sk-ant-...`)
* **Model ID:** `claude-sonnet-4-6`
* **Prompt Caching:** Enabled (slashes multi-turn API costs by ~90%)
* **Use Case:** High-reasoning fallback when Antigravity rate limits are triggered.

### Profile 3: Claude Opus 5 (Deep Reasoning & Complex Architecture)
* **Provider:** `Anthropic`
* **API Key:** Stored securely in your environment (`sk-ant-...`)
* **Model ID:** `claude-opus-5`
* **Use Case:** Top-tier frontier reasoning, architectural reviews, and benchmark evaluations.

---

## 🎨 Step 4: Ergonomic Editor Settings

Configure your user settings (`~/Library/Application Support/Antigravity/User/settings.json`) to align with Ghostty and your hardware preferences:

```json
{
  "workbench.colorTheme": "Tokyo Night",
  "workbench.iconTheme": "material-icon-theme",
  "editor.fontFamily": "'JetBrainsMono Nerd Font', Menlo, Monaco, 'Courier New', monospace",
  "editor.fontSize": 14,
  "editor.lineHeight": 22,
  "editor.fontLigatures": true,
  "editor.cursorBlinking": "smooth",
  "editor.cursorSmoothCaretAnimation": "on",
  "editor.smoothScrolling": true,
  "editor.minimap.enabled": true,
  "editor.renderWhitespace": "selection",
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.formatOnSave": true,
  "files.autoSave": "onFocusChange",
  "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
  "terminal.integrated.fontSize": 13,
  "telemetry.telemetryLevel": "off"
}
```

---

## 🤝 The Unified Workflow in Practice

```
┌─────────────────────────────────────────────────────────────┐
│                    DAILY CODING ROUTINE                     │
│                                                             │
│ 1. Launch local MLX server:                                 │
│    `just serve-omlx` (Port 8080: Qwen 2.5 Coder 32B)        │
│                                                             │
│ 2. Primary Development in ANTIGRAVITY IDE:                  │
│    • Use Native Antigravity Agent for high-level tasks      │
│    • Autonomous builds, tests, and multi-repo planning      │
│                                                             │
│ 3. Token Quota Reached or Scoped Offline Work:              │
│    • Click ROO CODE in the same Antigravity IDE sidebar     │
│    • Toggle to Local Qwen 32B ($0), Sonnet 4.6, or Opus 5   │
│    • Continue executing without interrupting context        │
└─────────────────────────────────────────────────────────────┘
```

---

## Related Notes
* [[Dual-Tier AI Workflow]]
* [[Local LLMs with MLX]]
* [[Nix-Darwin Guide]]
* [[Setup Checklist]]
