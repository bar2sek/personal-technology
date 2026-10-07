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
# Frontier Reasoning (Claude.ai Subscription — Zero per-token charges)
agy-ide --install-extension anthropic.claude-code

# Autonomous Multi-Model Switcher (Grok, Local MLX, AWS Bedrock)
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

## 🤖 Step 3: Configuring Roo Code as the Alternative Model Switcher

> [!NOTE] Why Claude is NOT in Roo Code
> Rather than incurring per-token Anthropic API billing in Roo Code, **Claude is accessed via the official Claude Code VS Code extension** (`anthropic.claude-code`), which authenticates against your existing **Claude.ai paid subscription** (Pro/Team/Enterprise).
>
> Roo Code is reserved exclusively as a multi-model switchboard for **xAI Grok**, your **local MLX model**, and **AWS Bedrock**.

Roo Code profiles are managed **declaratively** via `~/.config/roo-code/settings.json` and automatically imported into Antigravity IDE on startup via `"roo-cline.autoImportSettingsPath"`.

### Profile 1: Grok (xAI Real-Time & Velocity)
* **Provider:** `xAI`
* **API Key:** Read from the environment (`XAI_API_KEY`)
* **Model ID:** `grok-2`
* **Use Case:** High-speed code generation, live web-grounded queries, and an alternative reasoning perspective.

### Profile 2: Local MLX (Qwen 2.5 Coder 32B Playground)
* **Provider:** `OpenAI-Compatible`
* **Base URL:** `http://localhost:8080/v1`
* **API Key:** `local`
* **Model ID:** `mlx-community/Qwen2.5-Coder-32B-Instruct-4bit`
* **Lifecycle:** Start on-demand via `just serve-qwen-32b` (see [[Local LLMs with MLX]])
* **Use Case:** Offline coding, zero-cost experimentation, open-weights testing without internet or quotas.

### Profile 3: AWS Bedrock (Enterprise Cloud Inference)
* **Provider:** `Bedrock`
* **Authentication:** AWS Profile (`default` or homelab profile) or AWS environment variables
* **Region:** `us-east-2`
* **Model ID:** Configured foundation model or private deployed model ARN (with plans to host OpenAI models on AWS Bedrock)
* **Use Case:** Enterprise VPC isolation, corporate accounts, private cloud quota, and eventually routing to OpenAI models hosted directly inside AWS Bedrock.

> [!TIP] Native Antigravity Tab Autocomplete
> In-editor inline code completion as you type is handled seamlessly by **Antigravity Tab** (Google's native speculative decoding). Roo Code operates as an autonomous agent canvas, so local MLX is preserved purely for conversational reasoning, tests, and refactors.

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
│ 1. Confirm credentials are ready in your environment:       │
│    • Claude.ai Subscription logged into Claude extension    │
│    • XAI_API_KEY · AWS Credentials / Profile                │
│                                                             │
│ 2. Primary Daily Driver in ANTIGRAVITY IDE:                 │
│    • Use Native Antigravity Agent for high-level tasks      │
│    • Autonomous builds, tests, and multi-repo planning      │
│    • Native Antigravity Tab for inline ghost-text           │
│                                                             │
│ 3. Deep Frontier Reasoning & Claude Pair-Programming:       │
│    • Open CLAUDE CODE sidebar extension                     │
│    • Authenticated via Claude.ai subscription (no API fees) │
│    • Full repo indexing, interactive chat, and diffs        │
│                                                             │
│ 4. Alternative Models, Offline Coding & AWS in ROO CODE:    │
│    • Toggle Grok (xAI) for rapid second opinions            │
│    • Toggle Local MLX (Qwen 32B) for offline / zero quota   │
│    • Toggle AWS Bedrock for enterprise & hosted OpenAI models│
└─────────────────────────────────────────────────────────────┘
```

---

## Related Notes
* [[Dual-Tier AI Workflow]]
* [[Cloud AI Providers & Models]]
* [[Nix-Darwin Guide]]
* [[Setup Checklist]]
