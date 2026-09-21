# 🖥️ Declarative Mac AI Workstation (`nix-mac`)

> Fully declarative, single-command bootstrap for an Apple Silicon Mac workstation. Combines **`nix-darwin`**, **Homebrew**, cloud-first AI tooling, and **Visual Studio Code** into a clean, reproducible, anti-bloat system.

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
* Installs all GUI applications: **Visual Studio Code, Ghostty, Google Drive, Obsidian, OrbStack, and AppCleaner**.
* Installs modern CLI utilities: `git`, `uv`, `ripgrep`, `fd`, `jq`, `just`, `eza`, `bat`, `zoxide`, `fzf`, and `p10k`.
* Installs cloud infrastructure CLIs: `awscli`, `azure-cli`, `terraform`, and `node`.
* Deploys **JetBrainsMono Nerd Font** system-wide.
* Auto-configures **Visual Studio Code** (`Default Dark+` theme, font ligatures, Material Icons, and declarative extensions).
* Deploys **Continue.dev** pre-configured for Anthropic Claude endpoints.
* Configures **Ghostty** and **Zsh** with Powerlevel10k (colors, icons, Git status).
* Arranges the macOS Dock in a tidy 3-tier layout and eliminates telemetry from Edge and Brave.
* Purges GarageBand, iMovie, and sound libraries to reclaim **~5–8 GB** of SSD space.

---

## 🧠 Cloud AI Model Routing

This workstation runs **no local model weights**. All inference is remote, which keeps the full 48 GB of unified memory available for builds, containers, and Nix derivations.

### Model Tiering
* **`claude-haiku-4-5`** — tab autocomplete, where latency dominates quality.
* **`claude-sonnet-5`** — daily driver for implementation, review, and tests.
* **`claude-opus-5`** — deep reasoning, multi-file refactors, architecture decisions.

Gemini is reached through the Antigravity IDE native agent; Claude and xAI Grok through the Roo Code switcher. See [[Cloud AI Providers & Models]] for the full routing table and credential handling.

---

## 🛠️ Everyday Workflows (`just`)

This repository includes a [`Justfile`](templates/Justfile) with handy shortcuts:

| Command | Purpose |
| :--- | :--- |
| `just switch` | Rebuild and apply the active `nix-darwin` configuration. |
| `just update` | Update Nix flake inputs (`flake.lock`) and apply system updates. |
| `just code` | Launch Visual Studio Code on the current directory. |
| `just gc` | Garbage collect old Nix generations to free disk space. |
| `just prune-all` | Deep clean `uv`, `nix`, `brew`, and container caches. |
| `just debloat` | Purge pre-installed GarageBand/iMovie files from `/Library/Application Support`. |

---

## 📦 Declarative VS Code Suite

Visual Studio Code is configured with a curated suite of extensions managed declaratively in `flake.nix`:

* **AI & Completion:** [Continue.dev](https://continue.dev) (wired to Anthropic Claude endpoints).
* **Containers & Remote:** Dev Containers, Docker, and Remote - SSH (pairs natively with [OrbStack](https://orbstack.dev)).
* **Cloud & DevOps:** AWS Toolkit, Microsoft Kubernetes Tools, and HashiCorp Terraform.
* **Tooling & Themes:** Nix IDE, Material Icon Theme, and JetBrainsMono Nerd Font.

---

## 📚 Knowledge Vault & Documentation

The root of this repository contains an Obsidian-compatible documentation vault detailing every design decision:

* [[Pre-Flight Preparation & Unboxing Master Plan]] — The 15-minute 1-click bootstrap pipeline.
* [[System Architecture]] — Containerized applications paradigm and the Metal GPU access boundary.
* [[Dual-Tier AI Workflow]] — Routing work between fast and deep cloud model tiers.
* [[Hardware & Memory Budget]] — Unified memory allocation (48GB) and headroom math.
* [[Hardware Protection & Keyboard Care]] — Step-by-step Barekey decal application & screen buffer setup.
* [[Container Strategy]] — Why OrbStack replaces Docker Desktop for minimal CPU/RAM overhead.
* [[IDE Configuration Guide]] — Step-by-step configuration for VS Code, Continue.dev, and Antigravity.
* [[Cloud AI Providers & Models]] — Model tiering, provider routing per tool, and credential hygiene.
* [[Mac Cleanliness & Anti-Bloat Guide]] — Best practices for keeping macOS pristine (`uv`, Homebrew zap, cache pruning).
* [[Cloud Storage & Google Drive Guide]] — Disabling iCloud syncing and configuring Google Drive for Desktop.
* [[Setup Checklist]] — Printable unboxing and software checklist.

---

## 🤖 Agent Rules

This workspace includes an [`AGENTS.md`](./AGENTS.md) file that strictly enforces the **Declarative Invariant**:
* All changes must be written into `flake.nix` first—never applied via ad-hoc manual commands.
* All updates are tested and applied via `just switch`.
* Installers (`*.dmg`) and macOS metadata (`.DS_Store`) are excluded from Git.
