# 🤖 Unified Agent Operational Guidelines & Architecture Standards

Welcome, Agent. This workspace operates as a unified **Obsidian "Second Brain"** spanning multiple autonomous, standalone Git repositories. 

Whether operating at the root vault level or inside any child repository, you **MUST** strictly adhere to the following rules:

---

## 1. 🚫 Git Commit & Push Policy (Absolute Invariant)

* **Assist with Commit Messages**: When tasks or file modifications are complete, suggest clear, well-structured commit messages following the Conventional Commits standard (provide detailed, short, and atomic options).
* **DO NOT Commit or Push Changes**: Under **NO circumstances** should the agent execute `git commit` or `git push` inside any repository unless explicitly commanded by the user for root vault configurations.
* **User Authority**: Only the **USER** is authorized to review diffs, stage files, commit, and push to version control.

---

## 2. 📝 Obsidian & Markdown Documentation Standards

* **Strict Repository Self-Containment**: All links within a repository MUST resolve exclusively to notes and files inside that same repository. Never generate relative links that traverse out to sibling directories or other repositories (e.g., do NOT write `[[../other-repo/...]]` or `[...](../other-repo/...)`).
* **Obsidian Wikilinks Standard**: Use standard Obsidian Wikilinks `[[Note Name]]` (or `[[Folder/Note Name|Display Text]]`) for all internal note cross-references, glossary terms, runbooks, and project logs.
* **YAML Frontmatter Schema**: Every formal documentation note should begin with a consistent YAML frontmatter block:
  ```yaml
  ---
  title: "Document Title"
  date: YYYY-MM-DD
  tags:
    - category/subcategory
  status: in-progress # Options: inbox, in-progress, evergreen, archive
  aliases: []
  ---
  ```
* **Visuals & Diagrams**: Use native Mermaid syntax (` ```mermaid `) for architecture diagrams, network topologies, wiring schematics, and workflow logic (`graph TD` or `graph LR`).
* **Callouts & Code Blocks**:
  * Always label code blocks with their exact language identifier (e.g., `yaml`, `bash`, `python`, `terraform`, `nix`).
  * Use Obsidian/GitHub callouts strategically (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`).
* **External Cross-References**: If you need to reference an external project, tool, or sibling repository, mention it in plain text or provide the full canonical GitHub URL—never a fragile relative file path.

---

## 3. 🏛️ Multi-Repo Architecture & Boundary Invariants

* **Root Repository Scope (`second-brain`)**: Tracks **only** Obsidian configurations (`.obsidian/`), root metadata (`.gitignore`, `README.md`, `AGENTS.md`), and global vault dashboards (`!/*.md`).
* **Child Repositories are Standalone**: Subdirectories are independent, autonomous Git repositories with their own remotes, branches, and release cycles. Never attempt to stage, commit, or track child repository files from the root Git repo.
* **Keep `.gitignore` Resilient**: Never remove the root `/*` ignore rule or track child repository folders as Git submodules.
* **Vault-Level Hub Notes (Root Level Only)**: Global dashboards, indexes, or Maps of Content (MOCs) created directly at the root of the vault (e.g. `Dashboard.md`, `Index.md`) **are permitted** to cross-link into any child repository (e.g. `[[project-alpha/Architecture|Project Alpha]]`).

---

## 4. 🔐 Security, Privacy & Sanitization Hygiene

* **Zero Plaintext Secrets**: Never hardcode private keys, API tokens, cloud credentials, or passwords into manifests, scripts, or documentation.
* **Zero PII & Local Path Leaks**: Do not hardcode personal email addresses, private file paths (e.g., `/Users/<username>/...`), or internal hostnames in public templates or documentation.
* **Sensitive Inputs**: Reference secrets via Kubernetes Secrets, environment variables, or `.tfvars` files (which must remain strictly ignored by `.gitignore`).
* **Public GitHub Commits**: In public repositories, ensure commit author emails utilize the GitHub private noreply address (`bar2sek@users.noreply.github.com`).

---

## 5. ⚡ System Cleanliness, Tooling & Anti-Bloat

* **macOS Metadata**: Keep `.DS_Store` and AppleDouble files ignored and untracked across all repositories.
* **Binary Hygiene**: Never commit installers, disk images (`*.dmg`, `*.pkg`, `*.iso`), build caches, or temporary runtime state.
* **Python Discipline**: Never install Python packages globally or mutate macOS system Python. Use **`uv`** and **`uvx`** exclusively for isolated, ephemeral environments.
* **Apple MLX Local AI Standard**:
  * Local model inference is powered by Apple's native **MLX** framework (`mlx-lm` / `oMLX`).
  * **Port 8080**: Qwen 2.5 Coder 32B (4-bit) for Deep Chat & Scoped Refactor.
  * **Port 8081**: Qwen 2.5 Coder 14B (4-bit) for Instant Tab Autocomplete (FIM).

---

## 6. ☁️ Cloud Storage & Sync Hygiene

* If the vault directory lives inside a cloud storage provider (e.g., Google Drive for Desktop), it must remain pinned to **"Available offline"**.
* Never introduce tools or scripts that create mass temporary files or unpinned streaming states inside Git object directories.

---

## 🎯 Domain-Specific Standards & Playbooks

### A. Workstation Architecture (`nix-mac`)
* **Declarative System Invariant**: Zero ad-hoc imperative changes (`brew install`, manual config edits). All system states must be declared in `flake.nix` and applied via `just switch`.
* **Flake Sync Protocol**: Update canonical template `templates/flake.nix` first, synchronize to active `~/.config/nix-darwin/flake.nix`, test via `nix eval`, then prompt user to switch.

### B. Enterprise Hybrid Homelab (`talos-aws-homelab`)
* **Declarative Infrastructure Invariant**: Code first across Kubernetes platform services (`infrastructure/`), user apps (`apps/`), Talos machine patches (`talos/patches/`), Terraform modules (`terraform/`), and Ansible playbooks (`ansible/`).
* **Command Runner**: Execute cluster operations via root `Justfile` shortcuts (`just talos-health`, `just k8s-nodes`, `just tf-plan-all`).

### C. Digital Manufacturing & Physical Shop (`3d-printing`)
* **Bambu X2D Specs**: Dual independent hotends (300°C), heated chamber (65°C), zero-gap support interfaces (`Support for ABS` with ASA; PETG with PLA).
* **Filament Routing**: Feed flexible TPU (95A / foaming) externally via 4-in-1 PTFE adapter on ball-bearing rollers (never through AMS).
* **Workshop Hierarchy**: Level 1 French Cleats (3/4" Baltic Birch, 45° rails), Level 2 Multiboard Islands, Level 3 Gridfinity (42mm) & Underware.
* **Project Documentation**: Log print builds in `Projects/` using `Templates/Template - Print Project Log.md`.

### D. Knowledge Base & Curriculum (`aws-learning`)
* **Directory Scoping**: Confine active research and notes to `10_Projects/<project>/` or `20_Knowledge/<domain>/`.
* **Inbox Workflow**: When processing `00_Inbox/`, extract core insights, apply YAML frontmatter/tags, move refined notes to their home directory, and link in domain MOCs.

### E. Professional Portfolio & PDF Engine (`resume`)
* **Dual-Artifact Workflow**: Semantic Markdown (`Ryan_Bartusek_Resume_2026vX.md`) paired with compiled single-page vector PDF (`.pdf`).
* **Automated PDF Engine**: Built via headless Google Chrome using `python3 render_pdf.py`.
* **Artifact Tracking**: Markdown sources and final `.pdf` files are tracked; `.chrome_profile/` and `resume_preview.html` are strictly gitignored.
