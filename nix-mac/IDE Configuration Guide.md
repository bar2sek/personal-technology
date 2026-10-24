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


# ⚡ Visual Studio Code + Antigravity Multi-Model Setup

**Visual Studio Code** (`visual-studio-code`) paired with the **Antigravity extension** (`Google.google-antigravity`) is your primary development environment on macOS—combining official VS Code with Google's native agentic architecture, **Claude Code**, and **Roo Code** as a multi-model backup switcher.

- **Unified Agent Canvas:** Seamlessly integrates native Antigravity agent workflows (Gemini Flash/Pro) directly inside VS Code alongside visual diffs and the integrated terminal.
- **Multi-Model Switcher (Claude Code + Roo Code):** Provides instant access to Claude via your subscription (`anthropic.claude-code`) plus xAI Grok, Local MLX, and AWS Bedrock via Roo Code.
- **Single-IDE Footprint:** VS Code is the only editor; every agent runs as an extension inside it.

---

## 🛠️ Step 1: Install Visual Studio Code & Antigravity via `nix-darwin`

Visual Studio Code and the Antigravity Desktop 2.0 orchestrator are declared directly in your `templates/darwin.nix` under `homebrew.casks`:

```nix
homebrew.casks = [
  "antigravity"
  "visual-studio-code"
  "obsidian"
  "orbstack"
  "appcleaner"
  "ghostty"
];
```

---

## ⚙️ Step 2: Essential Extensions

Extensions are owned by home-manager (`programs.vscode` in `templates/home.nix`) and come from the `nix-vscode-extensions` marketplace mirror. The extensions folder is read-only, so only the listed extensions exist. See [[Home Manager Guide]].

| Group | Extensions |
|---|---|
| AI assistants | `google.google-antigravity`, `anthropic.claude-code` (Claude.ai subscription, no per-token charges), `rooveterinaryinc.roo-cline` (Grok, local MLX, AWS Bedrock) |
| Theme & icons | `enkia.tokyo-night`, `pkief.material-icon-theme` |
| Infrastructure & cloud | `jnoortheen.nix-ide`, `hashicorp.terraform`, `ms-azuretools.vscode-docker` (+ `vscode-containers`), `ms-kubernetes-tools.vscode-kubernetes-tools`, `redhat.vscode-yaml` |
| Languages & formatting | `dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`, `golang.go`, `ms-python.python` (+ `vscode-pylance`, `debugpy`, `vscode-python-envs`) |

> [!IMPORTANT]
> **Adding an extension:** add it to the list in the flake, sync, and `just switch`. Installing from the VS Code Extensions panel fails because the folder is read-only. Dependencies are not pulled in automatically, so list them too (that's why Pylance and Containers appear above).

---

## 🤖 Step 3: Configuring Roo Code as the Alternative Model Switcher

> [!NOTE] Why Claude is NOT in Roo Code
> Rather than incurring per-token Anthropic API billing in Roo Code, **Claude is accessed via the official Claude Code VS Code extension** (`anthropic.claude-code`), which authenticates against your existing **Claude.ai paid subscription** (Pro/Team/Enterprise).
>
> Roo Code is reserved exclusively as a multi-model switchboard for **xAI Grok**, your **local MLX model**, and **AWS Bedrock**.

Roo Code profiles are managed **declaratively** via `~/.config/roo-code/settings.json` (written by home-manager, read-only) and automatically imported into VS Code on startup via `"roo-cline.autoImportSettingsPath"`.

### Profile 1: Grok (xAI Real-Time & Velocity)

- **Provider:** `xAI`
- **API Key:** Read from the environment (`XAI_API_KEY`)
- **Model ID:** `grok-2`
- **Use Case:** High-speed code generation, live web-grounded queries, and an alternative reasoning perspective.

### Profile 2: Local MLX (Qwen 2.5 Coder 32B Playground)

- **Provider:** `OpenAI-Compatible`
- **Base URL:** `http://localhost:8080/v1`
- **API Key:** `local`
- **Model ID:** `mlx-community/Qwen2.5-Coder-32B-Instruct-4bit`
- **Lifecycle:** Start on-demand via `just serve-qwen-32b` (see [[Local LLMs with MLX]])
- **Use Case:** Offline coding, zero-cost experimentation, open-weights testing without internet or quotas.

### Profile 3: AWS Bedrock (Enterprise Cloud Inference)

- **Provider:** `Bedrock`
- **Authentication:** AWS Profile (`default` or homelab profile) or AWS environment variables
- **Region:** `us-east-2`
- **Model ID:** Configured foundation model or private deployed model ARN (with plans to host OpenAI models on AWS Bedrock)
- **Use Case:** Enterprise VPC isolation, corporate accounts, private cloud quota, and eventually routing to OpenAI models hosted directly inside AWS Bedrock.

> [!TIP] Native Antigravity Tab Autocomplete
> In-editor inline code completion as you type is handled seamlessly by **Antigravity Tab** (Google's native speculative decoding). Roo Code operates as an autonomous agent canvas, so local MLX is preserved purely for conversational reasoning, tests, and refactors.

---

## 🎨 Step 4: Ergonomic Editor Settings

User settings (`~/Library/Application Support/Code/User/settings.json`) are owned by home-manager (`programs.vscode.profiles.default.userSettings`), so changes go in the flake. Changing a setting in the VS Code UI will fail to save. The key settings:

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
│ 2. Primary Daily Driver in VISUAL STUDIO CODE:              │
│    • Use Native Antigravity Agent extension for tasks       │
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

- [[Dual-Tier AI Workflow]]
- [[Cloud AI Providers & Models]]
- [[Nix-Darwin Guide]]
- [[Setup Checklist]]
