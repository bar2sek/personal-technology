# 🤖 Agent Operational Guidelines & Repository Rules

Welcome, Agent. This repository defines the declarative infrastructure, Kubernetes manifests, Talos Linux machine configs, Terraform modules, and Ansible playbooks for an enterprise hybrid homelab (**Talos Linux + UniFi + AWS Cloud**).

When assisting in this repository or interacting with cluster resources, you **MUST** strictly adhere to the following rules:

---

## 1. 🚫 Git Commit & Push Policy (Absolute Rule)

* **Assist with Commit Messages**: When tasks or file modifications are complete, suggest clear, well-structured commit messages following the repository's Conventional Commits standard (provide detailed, short, and atomic options).
* **DO NOT Commit or Push Changes**: Under **NO circumstances** should the agent execute `git commit` or `git push`. 
* **User Authority**: Only the **USER** is authorized to review diffs, stage files, commit, and push to version control.

---

## 2. 🏛️ Declarative Infrastructure Invariant

* **Code First**: Never make imperative manual changes to cluster resources, networks, or cloud infrastructure without corresponding declarative code committed in this repository.
* **Manifest Organization**:
  - `kubernetes/infrastructure/`: Platform services (Rook-Ceph, Cloudflare Tunnel, Tailscale, KubeVirt, ARC, Floci, Authentik, AWS ACK).
  - `kubernetes/apps/`: User-facing application suites (TeslaMate, Actual Budget, Mealie, Immich, Home Assistant).
  - `talos/patches/`: Hardware-specific Talos Linux machine configuration patches.
  - `terraform/`: Infrastructure as Code for UniFi, Cloudflare Zero Trust, AWS Organization, and AWS Foundation resources.
  - `ansible/`: Configuration management for Windows 11 Gaming VM.
* **Reproducibility Guarantee**: The entire environment must be reconstructible from the code in this repo and backups stored in Rook-Ceph / AWS S3.

---

## 3. 📝 Conventional Commits Standard

When proposing commit messages to the user, follow the repository's established format:
* Format: `<type>(<scope>): <description>` (all lowercase, imperative mood).
* Primary types:
  - `feat`: New manifests, machine patches, playbooks, or infrastructure code.
  - `docs`: Documentation updates, architecture guides, diagrams.
  - `ci`: GitHub Actions ARC workflows.
  - `fix`: Bug fixes, configuration corrections.
  - `refactor`: Structural improvements without changing external behavior.
* Scope examples: `k8s`, `talos`, `terraform`, `unifi`, `cloudflare`, `aws`, `ansible`, `ai`.

---

## 4. 🔐 Secrets & Privacy Hygiene

* **Zero Plaintext Credentials**: Never hardcode private keys, API tokens, passwords, or cloud credentials into manifests or Terraform files.
* **Sensitive Inputs**: Reference secrets via Kubernetes Secrets, environment variables, or `.tfvars` files (which are strictly excluded by `.gitignore`).
* **No Leaked PII**: Keep personal email addresses and private identifiers parametrized via Terraform variables or environment configs.

---

## 5. ⚡ Workstation Parity (`nix-mac` Integration)

* **Command Runner**: Use the root `Justfile` for cluster management shortcuts (`just talos-health`, `just k8s-nodes`, `just tf-plan-all`, `just ssh-dev`).
* **Local AI Standards**: Adhere to the dual-port Apple MLX serving standard established on the macOS workstation:
  - **Port 8080**: Qwen 2.5 Coder 32B (4-bit) for Deep Chat & Scoped Refactor.
  - **Port 8081**: Qwen 2.5 Coder 14B / 1.5B (4-bit) for Instant Tab Autocomplete (FIM).
* **Package Parity**: CLI tools (`talosctl`, `kubectl`, `helm`, `ansible`, `sops`, `age`, `k9s`) are managed declaratively on the Mac via `nix-mac` (`templates/flake.nix`).
