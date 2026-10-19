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
# nix-mac lives inside the personal-technology repository (there is no standalone nix-mac repo)
git clone https://github.com/bar2sek/personal-technology.git ~/personal-technology
cd ~/personal-technology/nix-mac

# Run the 1-click bootstrap installer
bash templates/bootstrap.sh
```

**What the bootstrap script automates:**
* Installs **Xcode Command Line Tools**, **Homebrew**, and the official **Determinate Systems Nix** daemon.
* Builds and applies the **`nix-darwin`** system state from `templates/flake.nix`.
* Installs all GUI applications declared in `homebrew.casks`, including **Visual Studio Code, Antigravity, Claude, Ghostty, OrbStack, Tailscale, Moonlight, TigerVNC, Google Drive, Obsidian, and AppCleaner** (see `templates/flake.nix` for the full list).
* Installs modern CLI utilities: `git`, `uv`, `ripgrep`, `fd`, `jq`, `just`, `eza`, `bat`, `zoxide`, `fzf`, and `p10k`.
* Installs cloud infrastructure CLIs: `awscli`, `aws-cdk`, `azure-cli`, `terraform`, `node`, and `typescript`.
* Deploys **JetBrainsMono Nerd Font** system-wide.
* Auto-configures **Visual Studio Code** (Tokyo Night theme, JetBrainsMono Nerd Font, Material Icons, and declarative extensions) and writes the Roo Code multi-model profiles.
* Installs the **Antigravity CLI (`agy`)** (`bootstrap.sh`).
* Configures **Ghostty** and **Zsh** with Powerlevel10k (colors, icons, Git status).
* Arranges the macOS Dock in a tidy 3-tier layout and eliminates telemetry from Edge and Brave.
* Purges GarageBand, iMovie, and sound libraries to reclaim **~5–8 GB** of SSD space.

---

## 🧠 Cloud AI Model Routing

This workstation is **cloud-first**: day-to-day inference is remote, which keeps the 48 GB of unified memory available for builds, containers, and Nix derivations. Local Qwen 2.5 Coder 32B via Apple MLX runs **on demand only** (`just serve-qwen-32b`, ~22 GB while active); see [[Local LLMs with MLX]]. *(The MLX setup is due for a revisit.)*

### Model Tiering
* **`claude-haiku-4-5`** — tab autocomplete, where latency dominates quality.
* **`claude-sonnet-5`** — daily driver for implementation, review, and tests.
* **`claude-opus-5`** — deep reasoning, multi-file refactors, architecture decisions.

Gemini is reached through the Antigravity extension in VS Code (plus Antigravity Desktop and the `agy` CLI); Claude through the Claude Code extension, CLI and desktop app; xAI Grok through the Roo Code switcher. See [[Cloud AI Providers & Models]] for the full routing table and credential handling.

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

* **AI agents:** Antigravity (`Google.google-antigravity`), Claude Code (`anthropic.claude-code`), and Roo Code (`RooVeterinaryInc.roo-cline`).
* **Containers:** Docker (pairs natively with [OrbStack](https://orbstack.dev)).
* **Cloud & DevOps:** AWS Toolkit, Azure Resource Groups, Kubernetes Tools, and HashiCorp Terraform.
* **Languages & Formatting:** ESLint, Prettier, Python, Go, YAML, and Nix IDE.
* **Themes:** Tokyo Night and Material Icon Theme.

> [!NOTE]
> Claude runs through the Claude Code extension under the Claude.ai subscription; Roo Code holds the Grok, local MLX and AWS Bedrock profiles.

---

## 📚 Knowledge Vault & Documentation

The root of this repository contains an Obsidian-compatible documentation vault detailing every design decision:

* [[Pre-Flight Preparation & Unboxing Master Plan]] — The 15-minute 1-click bootstrap pipeline.
* [[System Architecture]] — Containerized applications paradigm and the Metal GPU access boundary.
* [[Dual-Tier AI Workflow]] — Routing work between fast and deep cloud model tiers.
* [[Hardware & Memory Budget]] — Unified memory allocation (48GB) and headroom math.
* [[Hardware Protection & Keyboard Care]] — Step-by-step Barekey decal application & screen buffer setup.
* [[Container Strategy]] — Why OrbStack replaces Docker Desktop for minimal CPU/RAM overhead.
* [[IDE Configuration Guide]] — Step-by-step configuration for VS Code and its Antigravity, Claude Code and Roo Code extensions.
* [[AWS CDK & TypeScript Workstation Guide]] — Declarative AWS CDK v2 & TypeScript toolchain, aliases, and workflows.
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
