---
title: Setup Checklist
tags:
  - checklist
  - unboxing
  - setup
  - macos
created: 2026-08-24
---

# 📋 New Mac Setup Checklist (M5 Pro 48GB)

Follow this step-by-step checklist when unboxing your new MacBook Pro to ensure a clean, isolated setup from Day 1.

---

## Phase 0: Physical Hardware Protection & Prep
*(Perform on a clean desk before software onboarding)*
- [ ] Clean hands thoroughly with degreasing soap.
- [ ] Wipe down keycaps with **70% Isopropyl Alcohol** on a microfiber cloth.
- [ ] Dab keycaps with painter's tape to remove any microscopic lint.
- [ ] Apply **Barekey** key skins using curved fine-tip tweezers (see [[Hardware Protection & Keyboard Care]]).
- [ ] Burnish corners with microfiber cloth and allow 12–24hr curing time.
- [ ] Place **UPPERCASE GhostBlanket** buffer liner over keyboard before closing lid in transit.

---

## Phase 1: Core Foundation & Nix-Darwin Bootstrap
- [ ] **Disable iCloud File Sync (Keep iMessage/Keychain):** Open System Settings $\rightarrow$ Apple Account $\rightarrow$ iCloud $\rightarrow$ Toggle **OFF** iCloud Drive and Desktop & Documents (see [[Cloud Storage & Google Drive Guide]]).
- [ ] Install Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```
- [ ] Install [Homebrew](https://brew.sh) (Nix-darwin uses Homebrew for GUI casks):
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- [ ] Install Nix via official Determinate Systems installer:
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```

---

## Phase 2: Deploy `flake.nix` & Apply System State
- [ ] Create the nix-darwin configuration folder:
  ```bash
  mkdir -p ~/.config/nix-darwin
  ```
- [ ] Copy the starter template from `templates/flake.nix` into `~/.config/nix-darwin/flake.nix`.
- [ ] Copy `templates/Justfile` to `~/Justfile`.
- [ ] Run initial system build and switch:
  ```bash
  sudo nix run nix-darwin -- switch --flake ~/.config/nix-darwin
  ```
  *(This single command automatically installs all CLI tools: `git`, `uv`, `ripgrep`, `just`, along with your GUI apps: `obsidian`, `orbstack`, `appcleaner`, and configures your macOS Dock/Finder preferences).*
- [ ] Verify container runtime (OrbStack):
  ```bash
  docker run --rm hello-world
  ```

---

## Phase 3: MLX & oMLX Local Qwen Coder Setup
- [ ] Install **oMLX** via official `.dmg` from [github.com/jundot/omlx/releases](https://github.com/jundot/omlx/releases):
  * Drag `oMLX.app` to `/Applications` to get pre-compiled Metal kernels & native menu bar app without needing Full Xcode.
- [ ] Start serving Qwen 2.5 Coder 32B with Paged SSD KV Caching:
  ```bash
  just serve-omlx-32b
  ```
- [ ] Verify API endpoint response:
  ```bash
  curl http://localhost:8080/v1/models
  ```

---

## Phase 4: IDE & Agent Integration
- [ ] Verify **Visual Studio Code** is installed (automatically installed via `nix-darwin` flake):
  ```bash
  which code
  ```
- [ ] Install and configure **Continue.dev** extension with local MLX endpoint (see [[IDE Configuration Guide]]).
- [ ] Verify **Antigravity CLI (`agy`)** and Desktop app are installed (automated via `bootstrap.sh`):
  ```bash
  agy --version
  ```
- [ ] Test local inline code generation inside VS Code (`Cmd + I`).
- [ ] Test agentic workflow inside Antigravity on your workspace (`agy` or `Antigravity.app`).

---

## Related Notes
* [[Index]]
* [[Local LLMs with MLX]]
* [[Container Strategy]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
