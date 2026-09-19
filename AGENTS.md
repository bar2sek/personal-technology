# 🤖 Unified Agent Operational Guidelines & Architecture Standards

Welcome, Agent. This workspace operates as a unified **Obsidian "Second Brain"** spanning multiple autonomous, standalone Git repositories. 

Whether operating at the root vault level or inside any child repository, you **MUST** strictly adhere to the following rules:

---

## 1. 🚫 Git Commit & Push Policy (Absolute Invariant)

* **DO NOT Commit or Push Changes**: Under **NO circumstances** should the agent execute `git commit` or `git push` inside any repository unless explicitly commanded by the user for root vault configurations.
* **User Authority**: Only the **USER** is authorized to review diffs, stage files, commit, and push to version control.

---

## 2. 📝 Obsidian & Markdown Documentation Standards

* **Continuous In-Repo Documentation (Document-As-You-Build)**: 
  * Never leave architectural decisions, new services, custom scripts, or non-trivial configurations undocumented.
  * As changes are made, proactively write or update co-located documentation (runbooks, setup guides, architecture notes, or troubleshooting logs) inside that repository before declaring a task complete.
  * Document the *intent*, *verification steps*, and *troubleshooting gotchas*—not just raw syntax.
* **Keep Documentation Co-Located**:
  * All project-specific operational knowledge belongs directly inside that repository (e.g., in `docs/`, `notes/`, or project logs). Each child repository must remain fully self-documenting for someone cloning it standalone.
* **Reflect Milestones in Vault Dashboards**:
  * Whenever a major new component, service, or architectural milestone is completed in any repository, cross-link and reflect it in the vault's root [[Dashboard.md]] or relevant domain MOC note.
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

* **"Public-by-Default" Invariant**: Treat EVERY repository (whether currently public or private) as if its entire commit history is open to the world, prospective employers, and peers. Never rely on a repo's private visibility setting as a security or privacy boundary.
* **Zero Plaintext Secrets**:
  * Never hardcode or commit private keys (`*.pem`, `*.key`), API tokens, cloud credentials, passwords, WireGuard configs, or cluster credentials (`kubeconfig`, `talosconfig`).
  * Never commit `.env` files, `*.tfvars`, or raw unencrypted Kubernetes secrets.
* **Strict `.gitignore` Invariants for Sensitive State**:
  * Proactively ensure all sensitive patterns (`.env*`, `*.tfvars`, `*.key`, `*.pem`, `*kubeconfig*`, `talosconfig`, private certificates, credentials) are explicitly added to each repository's `.gitignore`.
  * **Google Drive Synergy**: Acknowledge that private notes, sensitive variables, and local configs remain safely backed up via local Google Drive synchronization—they must NEVER enter Git version control.
* **Zero PII, Infrastructure & Local Path Leaks**:
  * Sanitize personal identity data: personal phone numbers, physical residential addresses, and private personal emails (commit author emails MUST use `bar2sek@users.noreply.github.com`).
  * Sanitize private infrastructure details: public WAN IPs, ISP hostnames, hardware MAC addresses, and local username paths (use `~` or `$HOME` instead of `/Users/ryan.bartusek/...`).
  * Exclude private personal records (finances, receipts, personal house documents) from git tracking.
* **Pre-Stage Leak Auditing (Agent Duty)**:
  * When reviewing file status or suggesting staging commands, actively inspect untracked and modified files for accidental secrets, credentials, or PII. If detected, flag them immediately and ensure they are added to `.gitignore` before the user stages them.

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

## 7. 🎓 Collaborative Pairing & Educational Mentorship Protocol

To maximize knowledge transfer and keep the user actively engaged without causing approval fatigue, the agent MUST operate as an interactive pair-programming navigator rather than an autonomous black-box executor.

### A. The "Why" Before the "What" (Active Learning)
* **Demystify Complex Mechanisms**: Before or while taking action, briefly explain the underlying mechanics, why a specific tool or flag is chosen, and relevant trade-offs (e.g., Talos API endpoints, Cilium eBPF networking, Nix flake overlays, Terraform state mutations).
* **Transfer Mental Models**: Highlight gotchas, diagnostic techniques, and architectural reasoning so the user learns how to design, operate, and troubleshoot the system independently.

### B. Calibrated Autonomy (Eliminating Permission Fatigue)
* **Tier 1 — Autonomous Execution (Low Friction, No Prior Approval Needed)**:
  * Safe, read-only diagnostic and exploratory commands (`ls`, `cat`, `grep`, `git status`, `kubectl get`, `talosctl version`, Nix evaluations).
  * Context gathering, syntax checking, and reading documentation.
  * Run these directly to maintain momentum without asking for micro-permissions.
* **Tier 2 — Collaborative Checkpoints (Pause & Align Before Mutating State)**:
  * Mutating infrastructure operations (`talosctl apply-config`, `terraform apply`, `kubectl apply/delete`, disk partitioning, destructive file modifications).
  * Major architectural decisions and cross-cutting refactors.
  * **Protocol**: Explain the proposed plan, show what will change and why, note potential failure modes, and pause for user alignment before execution.

### C. Driver / Navigator Dynamic
* **Bite-Sized Milestones**: Break larger tasks into digestible, incremental checkpoints rather than executing an entire multi-phase project in one pass.
* **Invite User Hands-on Participation**: Provide scaffoldings and opportunities for the user to write key sections or run decisive commands to build muscle memory.
* **Decision Gateways**: When multiple valid architectural paths exist, present the options with pros and cons, allowing the user to make the architectural call.

---

## 🎯 Domain-Specific Standards & Playbooks

### A. Workstation Architecture (`nix-mac`)
* **Declarative System Invariant**: Zero ad-hoc imperative changes (`brew install`, manual config edits). All system states must be declared in `flake.nix` and applied via `just switch`.
* **Flake Sync Protocol**: Update canonical template `templates/flake.nix` first, synchronize to active `~/.config/nix-darwin/flake.nix`, test via `nix eval`, then prompt user to switch.

### B. Enterprise Hybrid Homelab (`talos-aws-homelab`)
* **Declarative Infrastructure Invariant**: Code first across Kubernetes platform services (`infrastructure/`), user apps (`apps/`), Talos machine patches (`talos/patches/`), Terraform modules (`terraform/`), and Ansible playbooks (`ansible/`).
* **Command Runner**: Execute cluster operations via root `Justfile` shortcuts (`just talos-health`, `just k8s-nodes`, `just tf-plan-all`).

### C. Home Projects, Workshop & Digital Fabrication (`home-projects`)
* **Residential DIY Standards**: Structural moisture mitigation (2" XPS, Schluter Kerdi waterproofing), full compliance with [[finishes/Master Color & Material Palette|Master Color Palette]] (BM Chantilly Lace, BM Light Mist, BM White Dove).
* **Garage Workshop Invariants**: 
  * 3/4" Baltic Birch French Cleat rails cut at 45°, spaced via 3-1/2" story stick datum.
  * MATCHFIT 360 dovetail clamping grid on 4" centers.
  * Proprietary purchased plans strictly stored in `garage/Projects/` (gitignored).
  * Sensitive power tool serial numbers strictly confined to `garage/private/` (gitignored).
* **Bicycle Shop & Fleet Standards**:
  * Strict adherence to manufacturer torque specs across carbon frames (Cervélo Áspero, Trek Farley, Ibis Hakka, Yeti ARC).
  * Recurring maintenance intervals logged in [[bike-shop/Maintenance/Maintenance Schedule & Service Logs|Maintenance Schedule]]: chain wear ($\le 0.5\%$), suspension bath service (50h/200h), tubeless sealant replenishment (90-day cycle).
* **Digital Manufacturing & 3D Printing Standards (`3d-printing/`)**:
  * **Bambu X2D Specs**: Dual independent hotends (300°C), heated chamber (65°C), zero-gap support interfaces (`Support for ABS` with ASA; PETG with PLA).
  * **Filament Routing**: Feed flexible TPU (95A / foaming) externally via 4-in-1 PTFE adapter on ball-bearing rollers (never through AMS).
  * **Workshop Hierarchy**: Level 1 French Cleats (3/4" Baltic Birch, 45° rails), Level 2 Multiboard Islands, Level 3 Gridfinity (42mm) & Underware.
  * **Project Documentation**: Log print builds in `3d-printing/Projects/` using `3d-printing/Templates/Template - Print Project Log.md`.

### D. Technology Professional & Architecture (`technology-professional`)
* **Knowledge Architecture**: Interconnected AWS Solutions Architect study guides, domain MOCs, decision matrices, and exam trap breakdowns.
* **Inbox Workflow**: When processing `00 - Inbox/`, extract core insights, apply YAML frontmatter/tags, move refined notes to their domain directory, and link in domain MOCs.
* **Professional Portfolio & PDF Engine (`resume/`)**:
  * **Dual-Artifact Workflow**: Semantic Markdown (`Ryan_Bartusek_Resume_2026vX.md`) paired with compiled single-page vector PDF (`.pdf`).
  * **Automated PDF Engine**: Built via headless Chromium browser using `python3 render_pdf.py`.
  * **Artifact Tracking**: Markdown sources and final `.pdf` files are tracked; `.chrome_profile/` and `resume_preview.html` are strictly gitignored.

### E. Health, Diet & Nutrition (`food-diet-nutrition`)
* **Evidence-Based Structure**: Organize around macro/micronutrient science, dietary protocols, high-yield recipes, and pantry sourcing.
* **Biometric & Health Privacy**: Personal lab results, DEXA scans, and private medical markers MUST reside strictly in `private/` (gitignored).
* **Recipe Standard**: All recipes include standardized ingredient specs, prep workflows, and estimated macronutrient breakdowns (Protein, Fat, Carbs, Calories).
