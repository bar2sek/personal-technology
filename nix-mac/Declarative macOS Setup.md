---
title: Declarative macOS Setup
tags:
  - declarative
  - macos
  - brewfile
  - chezmoi
  - justfile
  - nix
created: 2026-08-24
---

# 📜 Declarative macOS Setup ("System as Code")

The goal of a declarative system is simple: **if your Mac were wiped tomorrow, a single command should rebuild your entire environment, settings, and workflows from Git without manual clicking.**

Here is how to extend the `Brewfile` philosophy across your entire Mac.

---

## 🏛️ The 6 Pillars of a Declarative Mac

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Apps & System Binaries  →  `Brewfile` (Homebrew + `mas`) │
│ 2. Dotfiles & Configs      →  `chezmoi` (Git-tracked dotfiles)
│ 3. macOS System Settings   →  `macos.sh` (`defaults write`) │
│ 4. Workflows & Commands    →  `Justfile` (`just serve-32b`) │
│ 5. Tool Versions & Python  →  `mise.toml` + `uv.lock`       │
│ 6. Databases & Dev Env     →  `docker-compose.yml` + DevCon │
└─────────────────────────────────────────────────────────────┘
```

---

## Pillar 1: Apps & Packages (`Brewfile` + `mas`)
Extend `Brewfile` to also declare Mac App Store applications via `mas`:

```ruby
# Tap third-party repos
tap "homebrew/bundle"

# CLI Binaries
brew "git"
brew "uv"
brew "ripgrep"
brew "fd"
brew "just"
brew "mas"       # Mac App Store CLI

# GUI Applications (Casks)
cask "obsidian"
cask "orbstack"
cask "appcleaner"
cask "cursor"
cask "ghostty"

# Mac App Store Apps (Declarative by App ID)
mas "Keynote", id: 409183694
mas "Magnet", id: 441529406
```

---

## Pillar 2: Dotfiles as Code (`chezmoi`)
Instead of manually managing `~/.zshrc`, `~/.gitconfig`, or editor settings, use **[`chezmoi`](https://www.chezmoi.io/)**:
* Keeps your dotfiles in a secure Git repository.
* Automatically creates symlinks/templates across machines.
* **One-command sync:** `chezmoi apply`

```bash
brew install chezmoi
chezmoi init --apply <your-github-dotfiles-repo>
```

---

## Pillar 3: macOS System Settings (`macos.sh`)
You can declare macOS UI preferences, Dock behavior, Finder settings, and trackpad speeds in a declarative shell script:

```bash
#!/usr/bin/env bash
# macos.sh - Declarative macOS preferences

# Finder: Show hidden files and file extensions
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Dock: Autohide instantly without delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15

# Trackpad: Enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Keyboard: Fast key repeat rate (essential for coding)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Apply changes
killall Finder Dock
```

---

## Pillar 4: Declarative Command Runner (`Justfile`)
Instead of remembering complex `uvx` or `docker` flags, use **[`just`](https://github.com/casey/just)** (a modern, clean alternative to Makefiles):

### Example `Justfile`:
```makefile
# Start local 32B Qwen server
serve-32b:
    uvx --from mlx-lm mlx_lm.server --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit --port 8080

# Start lightweight 14B Qwen server
serve-14b:
    uvx --from mlx-lm mlx_lm.server --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit --port 8080

# Clean all system caches (uv, brew, docker)
prune:
    uv cache clean
    brew cleanup --prune=all
    docker system prune -a --volumes -f

# Re-sync declarative packages
sync:
    brew bundle --global
    brew bundle cleanup --global --force
```

Usage: Just run `just serve-32b` or `just sync`.

---

## Pillar 5: Declarative Runtimes (`mise.toml`)
Use **[`mise`](https://mise.jdx.dev/)** to declare exact language versions per project:

```toml
# ~/.config/mise/config.toml
[tools]
node = "lts"
python = "3.12"
rust = "stable"
```

---

## Pillar 6: Declarative Services & Dev Environments
* **Databases / Microservices:** A `docker-compose.yml` file allows you to start/stop your entire stack cleanly:
  ```bash
  docker compose up -d    # Starts Postgres, Redis
  docker compose down -v  # Destroys everything with zero host trace
  ```
* **IDEs:** Use `.devcontainer/devcontainer.json` so your VS Code / Cursor extensions, environment variables, and linters are defined per-repository.

---

## ⚡ The Ultimate Frontier: `nix-darwin` (Optional)
If you want to take declarativeness to the extreme:
* **[nix-darwin](https://github.com/LnL7/nix-darwin) + [home-manager](https://github.com/nix-community/home-manager)** manages your entire macOS operating system, Homebrew casks, system defaults, fonts, dotfiles, and shell configs in a single `flake.nix` file.
* **Trade-off:** Steeper learning curve compared to the pragmatic `Brewfile` + `chezmoi` + `Justfile` stack.

---

## Related Notes
* [[Mac Cleanliness & Anti-Bloat Guide]]
* [[Setup Checklist]]
* [[Local LLMs with MLX]]
