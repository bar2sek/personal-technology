# 🖥️ Declarative Mac AI Workstation (`nix-mac`)

> Fully declarative, single-command bootstrap for an Apple Silicon Mac workstation. Combines **`nix-darwin`**, **Homebrew**, **Apple MLX / oMLX** local coding models, and **Visual Studio Code** into a clean, reproducible, anti-bloat system.

---

## ⚡ Quick Start: Day 1 Bootstrap

If setting up a brand-new Mac from scratch:

### 1. Physical Preparation (Before Booting)
1. Clean keycaps with a lint-free microfiber cloth lightly misted with 70% Isopropyl Alcohol.
2. Dab keycaps with painter's tape to lift micro-dust.
3. Apply **Barekey** key skins with curved tweezers (prevents keycap shine and oil wear).
4. Place an ultra-thin buffer cloth (e.g. UPPERCASE GhostBlanket) before closing the lid in transit.

### 2. macOS Out-of-Box Setup Assistant
1. Turn on your new Mac and follow the Apple Setup Assistant prompts.
2. **Enable FileVault** full-disk encryption.
3. Sign into Apple ID (for Keychain, iMessage, and Find My).
4. ⚠️ **CRITICAL:** When Apple prompts *"Store files from Desktop and Documents in iCloud Drive?"* $\rightarrow$ **UNCHECK THE BOX** (keeps your code and local filesystem 100% on your local SSD).

### 3. One-Click Bootstrap
Open the default **Terminal** (`Cmd + Space` $\rightarrow$ type `Terminal`), clone this repository, and run:

```bash
# Clone the repository
git clone https://github.com/bar2sek/nix-mac.git ~/nix-mac
cd ~/nix-mac

# Run the 1-click bootstrap installer
bash templates/bootstrap.sh
```

**What the bootstrap script automates:**
* Installs **Xcode Command Line Tools**, **Homebrew**, and the official **Determinate Systems Nix** daemon.
* Builds and applies the **`nix-darwin`** system state from `templates/flake.nix`.
* Installs all GUI applications: **Visual Studio Code, Ghostty, Google Drive, Obsidian, OrbStack, AppCleaner, and oMLX**.
* Installs modern CLI utilities: `git`, `uv`, `ripgrep`, `fd`, `jq`, `just`, `eza`, `bat`, `zoxide`, `fzf`, and `p10k`.
* Installs cloud infrastructure CLIs: `awscli`, `azure-cli`, `terraform`, and `node`.
* Deploys **JetBrainsMono Nerd Font** system-wide.
* Auto-configures **Visual Studio Code** (`Default Dark+` theme, font ligatures, Material Icons, and declarative extensions).
* Deploys **Continue.dev** pre-configured for local Qwen model endpoints.
* Configures **Ghostty** and **Zsh** with Powerlevel10k (colors, icons, Git status).
* Arranges the macOS Dock in a tidy 3-tier layout and eliminates telemetry from Edge and Brave.
* Purges GarageBand, iMovie, and sound libraries to reclaim **~5–8 GB** of SSD space.

---

## 🧠 Local LLM Serving (Apple MLX + oMLX)

This workstation runs local models natively on Apple Silicon's Unified Memory Architecture with zero host Python bloat (managed ephemerally via `uvx` or standalone `oMLX.app`).

### Model Split & Port Allocation
* **Port 8081 — Tab Autocomplete (FIM):** `Qwen 2.5 Coder 14B (4-bit)` for sub-50ms ghost-text completions.
* **Port 8080 — Chat & Scoped Refactor:** `Qwen 2.5 Coder 32B (4-bit)` utilizing **oMLX Paged SSD KV Caching** for instant multi-turn agent latency ($< 0.5\text{s}$ TTFT).

### Launching Local Models
```bash
# Run both Autocomplete (:8081) and Chat (:8080) simultaneously:
just serve-all

# Or launch Qwen 32B exclusively via oMLX:
just serve-omlx-32b
```

---

## 🛠️ Everyday Workflows (`just`)

This repository includes a [`Justfile`](templates/Justfile) with handy shortcuts:

| Command | Purpose |
| :--- | :--- |
| `just switch` | Rebuild and apply the active `nix-darwin` configuration. |
| `just update` | Update Nix flake inputs (`flake.lock`) and apply system updates. |
| `just code` | Launch Visual Studio Code on the current directory. |
| `just serve-all` | Start both Tab Autocomplete (:8081) and Deep Chat (:8080) servers. |
| `just serve-omlx-32b`| Launch Qwen 32B with Paged SSD KV Caching on port 8080. |
| `just gc` | Garbage collect old Nix generations to free disk space. |
| `just prune-all` | Deep clean `uv`, `nix`, `brew`, and container caches. |
| `just debloat` | Purge pre-installed GarageBand/iMovie files from `/Library/Application Support`. |

---

## 📦 Declarative VS Code Suite

Visual Studio Code is configured with a curated suite of extensions managed declaratively in `flake.nix`:

* **AI & Completion:** [Continue.dev](https://continue.dev) (wired to local oMLX / MLX endpoints).
* **Containers & Remote:** Dev Containers, Docker, and Remote - SSH (pairs natively with [OrbStack](https://orbstack.dev)).
* **Cloud & DevOps:** AWS Toolkit, Microsoft Kubernetes Tools, and HashiCorp Terraform.
* **Tooling & Themes:** Nix IDE, Material Icon Theme, and JetBrainsMono Nerd Font.

---

## 📚 Knowledge Vault & Documentation

The root of this repository contains an Obsidian-compatible documentation vault detailing every design decision:

* [[Pre-Flight Preparation & Unboxing Master Plan]] — The 15-minute 1-click bootstrap pipeline.
* [[System Architecture]] — Hybrid bare-metal LLM + containerized applications paradigm.
* [[Dual-Tier AI Workflow]] — Pairing local Qwen (micro-typist) with agentic platforms (macro-architect).
* [[Hardware & Memory Budget]] — Unified memory allocation (48GB), model quantization, and headroom math.
* [[Hardware Protection & Keyboard Care]] — Step-by-step Barekey decal application & screen buffer setup.
* [[Container Strategy]] — Why OrbStack replaces Docker Desktop for minimal CPU/RAM overhead.
* [[IDE Configuration Guide]] — Step-by-step configuration for VS Code, Continue.dev, and local endpoints.
* [[Local LLMs with MLX]] — Running Qwen 2.5 Coder via Apple MLX and oMLX with zero system bloat.
* [[Mac Cleanliness & Anti-Bloat Guide]] — Best practices for keeping macOS pristine (`uv`, Homebrew zap, cache pruning).
* [[Cloud Storage & Google Drive Guide]] — Disabling iCloud syncing and configuring Google Drive for Desktop.
* [[Setup Checklist]] — Printable unboxing and software checklist.

---

## 🤖 Agent Rules

This workspace includes an [`AGENTS.md`](./AGENTS.md) file that strictly enforces the **Declarative Invariant**:
* All changes must be written into `flake.nix` first—never applied via ad-hoc manual commands.
* All updates are tested and applied via `just switch`.
* Installers (`*.dmg`) and macOS metadata (`.DS_Store`) are excluded from Git.
