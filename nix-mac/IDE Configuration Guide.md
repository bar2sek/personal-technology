---
title: "IDE Configuration Guide (VS Code + Antigravity)"
date: 2026-09-20
tags:
  - ide
  - vscode
  - continue
  - configuration
  - macos
status: evergreen
aliases: []
---

# ⚡ Antigravity IDE + Multi-Model Setup

**Antigravity IDE** is your primary development environment on macOS—combining the familiarity and extension ecosystem of Code OSS with Google's native agentic architecture and **Roo Code** as a multi-model backup switcher.

* **Unified Agent Canvas:** Seamlessly integrates native Antigravity agent workflows (Gemini Flash/Pro) directly alongside the editor canvas, visual diffs, and terminal.
* **Multi-Model Switcher (Roo Code):** Provides an instant toggle between **Claude Sonnet 5** and **Claude Opus 5** (Anthropic API) whenever AGY tokens are exhausted or a second opinion is wanted.
* **Zero Bloat:** Replaces standalone VS Code entirely, and runs no local inference — the unified memory stays available for builds and containers.

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
# Autonomous Multi-Model Agent (Claude via Anthropic API)
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

### Profile 1: Claude Sonnet 5 (Daily Driver)
* **Provider:** `Anthropic`
* **API Key:** Read from the environment (`ANTHROPIC_API_KEY`) — never written into a tracked file
* **Model ID:** `claude-sonnet-5`
* **Prompt Caching:** Enabled (cuts multi-turn costs substantially on repeated prefixes)
* **Use Case:** Routine implementation, code review, unit tests, log diagnosis, and the fallback when Antigravity rate limits trigger.

### Profile 2: Claude Opus 5 (Deep Reasoning & Complex Architecture)
* **Provider:** `Anthropic`
* **API Key:** Read from the environment (`ANTHROPIC_API_KEY`)
* **Model ID:** `claude-opus-5`
* **Use Case:** Top-tier frontier reasoning, architectural reviews, and multi-file refactors.

> [!TIP] Use the exact model ID strings
> Never append date suffixes such as `claude-opus-5-20260401`. Dated variants are a convention from older model generations and are rejected. Previous-generation IDs like `claude-sonnet-4-6` still resolve but are a step down — see [[Cloud AI Providers & Models]] for the current tiering.

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
│ 1. Confirm API keys are exported in your shell:             │
│    ANTHROPIC_API_KEY · GEMINI_API_KEY · XAI_API_KEY         │
│                                                             │
│ 2. Primary Development in ANTIGRAVITY IDE:                  │
│    • Use Native Antigravity Agent for high-level tasks      │
│    • Autonomous builds, tests, and multi-repo planning      │
│                                                             │
│ 3. Token Quota Reached or Deeper Reasoning Needed:          │
│    • Click ROO CODE in the same Antigravity IDE sidebar     │
│    • Toggle to Sonnet 5 (routine) or Opus 5 (hard problems) │
│    • Continue executing without interrupting context        │
└─────────────────────────────────────────────────────────────┘
```

---

## Related Notes
* [[Dual-Tier AI Workflow]]
* [[Cloud AI Providers & Models]]
* [[Nix-Darwin Guide]]
* [[Setup Checklist]]
