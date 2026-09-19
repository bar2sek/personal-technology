---
title: Mac Cleanliness & Anti-Bloat Guide
tags:
  - macos
  - maintenance
  - anti-bloat
  - homebrew
  - uv
created: 2026-08-24
---

# 🧹 Mac Cleanliness & Anti-Bloat Guide

To keep your new M5 Pro fast, organized, and free of background clutter over time, follow these core isolation rules:

---

## 🏛️ The "Who Installs What?" Hierarchy

| Category | Recommended Tool | Examples | Why This Keeps Your Mac Clean |
| :--- | :--- | :--- | :--- |
| **GUI Applications** | `brew install --cask` | Obsidian, Cursor, OrbStack, AppCleaner | Centrally tracked; updated & uninstalled via one command |
| **System CLI Utilities** | `brew install` | `git`, `ripgrep`, `fd`, `jq`, `htop` | Cleanly contained in `/opt/homebrew/`, no `/usr/local` mess |
| **Python & Local AI** | `uv` / `uvx` / `uv tool` | `mlx-lm`, `ruff`, `ipython`, ML packages | Completely isolated; never touches macOS system Python |
| **Databases & Services** | Containers (OrbStack / Apple Container) | PostgreSQL, Redis, RabbitMQ | Zero host daemons; wipeable with `docker rm` |
| **Node.js / Web Dev** *(optional host)* | `fnm` (Fast Node Manager) or DevContainers | Node LTS, Bun, pnpm | Fast single-binary manager; zero global npm permission mess |
| **Rust / Go** *(optional host)* | `rustup` / `brew install go` | `rustc`, `cargo`, `go` | Standard clean toolchains in `~/.cargo` or `/opt/homebrew` |

---

## 1. Python Hygiene: Use `uv` Exclusively
Never use `pip install` globally or modify system Python.

* **Install standalone CLI tools with `uv tool`:**
  ```bash
  uv tool install ruff
  uv tool install ipython
  ```
* **Run one-off scripts/servers ephemerally:**
  ```bash
  uvx --from mlx-lm mlx_lm.server ...
  ```
* **Project Virtual Environments:**
  ```bash
  cd my-project
  uv init
  uv add fastapi uvicorn
  ```
  *(All project dependencies stay in `.venv/` and can be completely wiped with `rm -rf .venv`).*

---

## 2. Declarative Homebrew Management (`Brewfile`)

Keep track of every CLI tool, font, and GUI app installed via Homebrew.

### Create and Maintain `~/.Brewfile`:
```ruby
# CLI Tools
brew "git"
brew "uv"
brew "ripgrep"
brew "fd"
brew "htop"

# Lightweight Runtimes
cask "orbstack"
cask "obsidian"
cask "appcleaner"
```

### Useful Homebrew Maintenance Commands:
```bash
# Install everything from Brewfile
brew bundle --global

# Remove any installed package NOT listed in your Brewfile
brew bundle cleanup --global --force

# Clear downloaded archives and old versions
brew cleanup --prune=all
```

---

## 3. Complete App Uninstallation & Direct `.dmg` Downloads

### What about apps installed via `.dmg` (e.g., Antigravity)?
Not every application is on Homebrew or in containers. A `.dmg` (Disk Image) is actually very clean on macOS because it contains a standalone application bundle (`.app`):
1. **Installation:** You mount the `.dmg` and drag `Antigravity.app` into `/Applications`. 100% of the binary lives strictly within `/Applications/Antigravity.app`.
2. **Where Data Lives:** Caches and configs live in standard user directories (e.g., `~/.gemini/antigravity` and `~/Library/Application Support/`).
3. **Clean Removal:** Never just drag an app to the Trash. Use **[AppCleaner](https://freemacsoft.net/appcleaner/)**—open AppCleaner and drag `Antigravity.app` onto it. It automatically indexes and purges the app binary, `~/.gemini/` directories, launch agents, and cache files all in one click.

---

## 4. Periodic Cache Housekeeping

| Component | Cache Location | Cleanup Command |
| :--- | :--- | :--- |
| **Hugging Face / MLX Models** | `~/.cache/huggingface/` | `rm -rf ~/.cache/huggingface/hub/<model-folder>` |
| **`uv` Package Cache** | `~/.cache/uv/` | `uv cache clean` |
| **OrbStack / Docker Images** | OrbStack data store | `docker system prune -a --volumes` |
| **Homebrew Downloads** | `~/Library/Caches/Homebrew/` | `brew cleanup -s` |

---

## 5. Debloating Pre-Installed Apple Apps

When you unbox a new Mac, Apple pre-installs two categories of software:

### Category A: Heavy Consumer Apps & Audio Libraries (Removable)
* **What they are:** GarageBand, iMovie, Keynote, Numbers, Pages, and the Apple Sound Library (~5–8 GB).
* **How to purge:** Our `templates/flake.nix` and `Justfile` (`just debloat`) automatically delete these binaries and their instrument loops from `/Library/Application Support/`.

### Category B: Core System Apps (Protected by Apple SIP / SSV)
* **What they are:** Mail, Stocks, News, Chess, Podcasts, Photos, Safari, Maps (located in `/System/Applications/`).
* **The Reality:** macOS protects these on a cryptographically signed, read-only system volume (Signed System Volume). Deleting them is not allowed by Apple without breaking system integrity/updates.
* **The Clean Nix-Darwin Solution:**
  1. **Dock Decluttering:** Our `flake.nix` declares `system.defaults.dock.persistent-apps`, which **removes every Apple app icon from your Dock**, pinning only your coding tools (Ghostty, Visual Studio Code, Obsidian, OrbStack, Antigravity).
  2. **Zero Background Overhead:** These system apps consume 0% CPU and 0MB RAM as long as you do not open them.

---

## 6. Language Packs & Hidden macOS "Fluff"

### 🌐 The Truth About Language Packs (`.lproj` files)
Historically, apps like *Monolingual* stripped foreign language `.lproj` folders from apps. 
* **On Modern macOS:** Apple Gatekeeper enforces cryptographic code signing on `.app` bundles. Stripping `.lproj` folders inside app binaries can invalidate application signatures and trigger *"App is damaged"* errors.
* **Storage Reality:** Language files inside modern apps take up negligible space ($< 150\text{MB}$).
* **System Language Files:** Stored in `/System/` on Apple's read-only Signed System Volume, where they cannot be modified.

---

### 🐘 The Real Hidden Storage Consumers & How to Fix Them

| Hidden Consumer | Size on 48GB Mac | Why It Exists | How to Purge / Optimize |
| :--- | :--- | :--- | :--- |
| **`sleepimage` (RAM dump)** | **48 GB** | macOS dumps all 48GB of RAM to SSD during sleep. | Run `sudo pmset -a hibernatemode 0 && sudo rm /var/vm/sleepimage` to reclaim 48GB immediately. |
| **APFS Local Snapshots** | **10–30 GB** | Hidden local backup snapshots taken by macOS. | Purged in `flake.nix` with `tmutil thinlocalsnapshots / 9999999999 4`. |
| **Diagnostic Reports** | **1–3 GB** | Crash logs in `~/Library/Logs/DiagnosticReports`. | Automatically wiped on `nix-darwin` switch. |
| **Xcode Simulator Fluff** | **5–15 GB** | Unused iOS/watchOS simulator runtimes. | Run `xcrun simctl delete unavailable`. |
| **Siri Speech Downloads** | **1–2 GB** | High-res offline voice models in `~/Library/Speech`. | Kept off by default unless speech synthesis is requested. |

---

## Related Notes
* [[Setup Checklist]]
* [[Nix-Darwin Guide]]
* [[Container Strategy]]
* [[Local LLMs with MLX]]
