---
title: "IDE Configuration Guide (VS Code + Antigravity)"
date: 2026-09-20
tags:
  - ide
  - vscode
  - configuration
  - macos
status: evergreen
aliases: []
---


# ⚡ Visual Studio Code + Antigravity Multi-Model Setup

**Visual Studio Code** (`visual-studio-code`) paired with the **Antigravity extension** (`Google.google-antigravity`) and **Claude Code** (`anthropic.claude-code`) is your primary development environment on macOS—combining official VS Code with Google's and Anthropic's native agentic extensions, plus VS Code's built-in Copilot Free (for Git commit messages / optional Tab completions) and native **BYOK** for ad-hoc cloud or local API testing.

- **Unified Agent Canvas:** Seamlessly integrates native Antigravity agent workflows (Gemini) directly inside VS Code alongside visual diffs and the integrated terminal.
- **Claude Code Panel:** Provides instant access to Claude via your Claude.ai subscription (`anthropic.claude-code`) without per-token API charges.
- **Built-In Copilot Free + BYOK:** Handles Git commit message generation natively and lets you plug in Azure AI Foundry, AWS Bedrock, or on-demand local MLX via **Chat: Manage Language Models** without third-party switcher bloat.
- **Single-IDE Footprint:** VS Code is the only editor; every agent runs natively inside it.

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
| AI assistants | `google.google-antigravity`, `anthropic.claude-code` (Claude.ai subscription, no per-token charges) |
| Theme & icons | `enkia.tokyo-night`, `pkief.material-icon-theme` |
| Infrastructure & cloud | `jnoortheen.nix-ide`, `hashicorp.terraform`, `ms-azuretools.vscode-docker` (+ `vscode-containers`), `ms-vscode-remote.remote-containers`, `ms-kubernetes-tools.vscode-kubernetes-tools`, `redhat.vscode-yaml` |
| Azure | `ms-azuretools.vscode-azureresourcegroups`, `vscode-azurefunctions`, `vscode-azureappservice`, `vscode-azurestorage`, `vscode-azurecontainerapps`, `vscode-cosmosdb`, `vscode-bicep` (+ `ms-dotnettools.vscode-dotnet-runtime`), `ms-mssql.mssql` |
| GitHub | `github.vscode-pull-request-github`, `github.vscode-github-actions` |
| Languages & formatting | `dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`, `golang.go`, `ms-python.python` (+ `vscode-pylance`, `debugpy`, `vscode-python-envs`) |

> [!IMPORTANT]
> **Adding an extension:** add it to the list in the flake, sync, and `just switch`. Installing from the VS Code Extensions panel fails because the folder is read-only. Dependencies are not pulled in automatically, so list them too (that's why Pylance and Containers appear above).

> [!NOTE]
> - Deprecated `ms-vscode.azure-account`, legacy ARM Tools, and stale `ms-vscode.azurecli` are intentionally omitted (VS Code's built-in Microsoft auth + `vscode-azureresourcegroups` replace Azure Account, and Bicep replaces ARM Tools).
> - `ms-azuretools.vscode-bicep` uses `.overrideAttrs (_: { buildInputs = [ ]; })` in `templates/home.nix` because `nix-vscode-extensions` attaches unused `pkgs.bicep`, `pkgs.bicep-lsp`, and `pkgs.azure-cli` `buildInputs`; building `pkgs.bicep` from source fails on Apple Silicon (`aarch64-darwin`) when NuGet's `grpc.tools` invokes an `x86_64` `protoc` binary (`Bad CPU type in executable`), whereas the unpacked `.vsix` runs natively via `ms-dotnettools.vscode-dotnet-runtime`.
> - `"dotnetAcquisitionExtension.sharedExistingDotnetPath"` is pinned to `${pkgs.dotnetCorePackages.runtime_10_0-bin}/bin/dotnet` alongside `"dotnetAcquisitionExtension.allowInvalidPaths" = true` in `templates/home.nix` because `ms-dotnettools.vscode-dotnet-runtime` cannot `chmod` its bundled `dotnet-install.sh` inside the read-only `/nix/store`, and `ms-mssql.mssql` requests exact `"10.0.0"` while Nix supplies `10.0.15` (whose `runtimeconfig.json` rolls forward cleanly).

---

## 🤖 Step 3: Optional Cloud & Local Testing via VS Code Built-In BYOK

VS Code's built-in **Copilot Free** handles one-click Git commit messages and optional inline Tab completions out of the box (no extra extensions declared in `home.nix`). When you want to test external cloud endpoints or local weights inside VS Code without adding a third-party switcher extension, use VS Code's native **Bring Your Own Key (BYOK)** model picker (`Cmd + Shift + P` $\rightarrow$ **Chat: Manage Language Models**):

- **Azure AI Foundry:** First-class provider in the BYOK model picker (supports endpoint URL + API key or Entra ID credentials).
- **AWS Bedrock:** Supported via the Bedrock BYOK provider / AWS credential chain.
- **Local MLX (Qwen 3.8 27B Playground):** Start on-demand via `just serve-qwen-27b`, then point a custom OpenAI-compatible BYOK entry to `http://localhost:8080/v1/chat/completions` (see [[Local LLMs with MLX]]).

> [!NOTE] Retirement of Continue (`continue.continue`)
> Continue was retired from `nix-mac` in November 2026 after the upstream `continuedev/continue` project was archived in June 2026. Antigravity and Claude Code cover day-to-day chat/agent panels, while VS Code's built-in BYOK replaces multi-provider API testing with zero extra extension overhead.

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
│    • Antigravity Google sign-in + Claude.ai subscription    │
│    • Optional: Azure Foundry / AWS Bedrock credentials      │
│                                                             │
│ 2. Primary Daily Driver in VISUAL STUDIO CODE:              │
│    • Use Native Antigravity Agent extension for tasks       │
│    • Autonomous builds, tests, and multi-repo planning      │
│    • Built-in Copilot Free for commit messages & Tab        │
│                                                             │
│ 3. Deep Frontier Reasoning & Claude Pair-Programming:       │
│    • Open CLAUDE CODE sidebar extension (or Desktop app)    │
│    • Authenticated via Claude.ai subscription (no API fees) │
│    • Full repo indexing, interactive chat, and diffs        │
│                                                             │
│ 4. Optional Cloud / Local API Testing (VS Code BYOK):       │
│    • Chat: Manage Language Models -> Azure Foundry / Bedrock│
│    • On-demand Local MLX (just serve-qwen-27b) on :8080     │
└─────────────────────────────────────────────────────────────┘
```

---

## Related Notes

- [[Dual-Tier AI Workflow]]
- [[Cloud AI Providers & Models]]
- [[Nix-Darwin Guide]]
- [[Setup Checklist]]
