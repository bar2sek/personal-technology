# Hybrid Cloud & Remote AI Development Architecture

This guide specifies the architecture, client configuration, and Kubernetes manifests for our **Hybrid Cloud/Remote AI Development Stack**. It combines frontier cloud model inference on the macOS client with unbounded remote agentic execution inside our on-premise Talos Kubernetes cluster.

> [!NOTE] Superseded local inference (September 2026)
> This document previously described local Apple MLX / oMLX serving on ports `8080`/`8081`. That was decommissioned — the workstation now standardizes on cloud providers, freeing 25–34 GB of unified memory and ~59 GB of SSD. See [[nix-mac/Cloud AI Providers & Models|Cloud AI Providers & Models]] for the current model tiering.

---

## 🏗 Architectural Topology

The system separates concerns into three distinct layers:

1. **Client Layer (macOS / 48GB Unified RAM)**:
   - Runs standard VS Code with the **Continue.dev** extension, or Antigravity IDE with Roo Code.
   - Inference is **entirely remote** — Anthropic, Google, and xAI APIs over HTTPS. No model weights on disk.
   - Zero Antigravity binaries installed locally; no local build tools required.
   - The full 48 GB of unified memory stays available for containers, Nix builds, and the editor.

2. **Cluster / Server Layer (`sm-node-03` / Kubernetes Pod)**:
   - Hosts persistent project repositories, compilers, build toolchains, linters, and the Antigravity CLI / background daemon (`agy`).
   - Scheduled on `sm-node-03` to utilize its **14C/28T Xeon E5-2680 v4 CPU** and **160 GB RAM** for long-running builds, test suites, and multi-file refactors.
   - Preserves state across pod restarts via a high-IOPS **Rook-Ceph NVMe PersistentVolumeClaim**.

3. **Control Plane (Browser PWA / Relay)**:
   - `antigravity.google.com` acts strictly as an authenticated relay/broker to supervise agent tasks executing on the remote container host.
   - Zero container execution occurs in Google's cloud—all compute and source code remain 100% on-premise.

```
 +-----------------------------------------------------------------------------------+
 |                    Client Layer (macOS / 48GB Unified RAM)                        |
 |                                                                                   |
 |  +--------------------+                     +----------------------------------+  |
 |  | VS Code            |                     | Cloud Provider APIs (HTTPS)      |  |
 |  | (Continue.dev UI)  |--- HTTPS ---------->| - Autocomplete (Haiku 4.5)       |  |
 |  | Antigravity + Roo  |--- HTTPS ---------->| - Chat & Refactor (Sonnet 5)     |  |
 |  |                    |--- HTTPS ---------->| - Deep Reasoning (Opus 5)        |  |
 |  +--------------------+                     +----------------------------------+  |
 +-----------------------------------------------------------------------------------+
           |                                                    
           | Encrypted WireGuard / Tailscale (No Open Ports)    
           v                                                    
 +-----------------------------------------------------------------------------------+
 |            Talos Kubernetes Cluster: sm-node-03 (160GB RAM / 28 vCPUs)            |
 |                                                                                   |
 |  +-----------------------------------------------------------------------------+  |
 |  |                Antigravity Remote Dev Pod (dev-workspace)                   |  |
 |  |                                                                             |  |
 |  |  - OpenSSH Server (VS Code Remote - SSH Attachment)                         |  |
 |  |  - Antigravity Daemon & CLI (agy)                                           |  |
 |  |  - Build Toolchains (Go, Node.js, Python, Rust, Docker, Terraform)         |  |
 |  +-----------------------------------------------------------------------------+  |
 |                                         |                                         |
 |                 +-----------------------+-----------------------+                 |
 |                 v                                               v                 |
 |  +-----------------------------+               +-------------------------------+  |
 |  | Rook-Ceph NVMe PVC (100GB)  |               | antigravity.google.com PWA    |  |
 |  | - ~/.config/antigravity     |               | (Encrypted WebSocket Relay)   |  |
 |  | - Git Repos & Build Caches  |               |                               |  |
 |  +-----------------------------+               +-------------------------------+  |
 +-----------------------------------------------------------------------------------+
```

---

## ⚡ Workload & Model Split

| Layer | Engine / Interface | Model & Role | Where it runs |
| :--- | :--- | :--- | :--- |
| **Tab Completion** | Continue.dev in VS Code | **Claude Haiku 4.5**<br>Latency-critical inline completion | Anthropic API |
| **In-Editor Chat & Scoped Refactor** | Continue.dev sidebar / Roo Code | **Claude Sonnet 5**<br>Diffs, unit tests, routine implementation | Anthropic API |
| **Deep Reasoning & Architecture** | Roo Code in Antigravity IDE | **Claude Opus 5**<br>Multi-file refactors, architectural tie-breakers | Anthropic API |
| **Autonomous Agent Automation** | Antigravity Remote Dashboard or `agy` CLI | **Antigravity Agent Platform**<br>Long-running test suites, multi-file refactors | Cluster host (`sm-node-03`) |

---

## ☁️ Why Cloud Over Local Inference

1. **Capability**: Frontier cloud models substantially outperform anything that fits in 48 GB of unified memory. The largest locally viable model was a 4-bit 32B quantization — a meaningful step down in reasoning quality.
2. **Memory economics**: Two resident models consumed ~31 GB, leaving barely 8 GB of headroom. That memory now serves OrbStack containers, Nix derivations, and native builds — the workloads that genuinely cannot be moved off this machine.
3. **No Metal ceiling tuning**: The old setup required raising `iogpu.wired_mem_limit` above the macOS default, a global system change with real stability implications under memory pressure. No longer needed.
4. **Zero maintenance surface**: No weight downloads, no quantization selection, no server process to supervise, no port conflicts.

The tradeoff is honest: cloud inference costs money per token and requires connectivity. Autocomplete latency is also higher — see the latency discussion in [[nix-mac/Cloud AI Providers & Models|Cloud AI Providers & Models]].

---

## 💾 Client Memory Budget (48GB Unified RAM Envelope)

With no model weights resident:

- **macOS System Overhead & VS Code UI**: ~9.0 GB
- **OrbStack / container workloads**: variable, previously constrained
- **Available for builds, Nix, and containers**: **~39 GB**

The former budget committed ~31 GB to model weights and KV cache, leaving ~8 GB of working headroom. That inversion is the main practical benefit of the migration.

---

## 🛠 macOS Client Configuration

### 1. API Credentials
Export provider keys in your shell profile — never commit them:

```bash
export ANTHROPIC_API_KEY="..."   # Claude via Continue / Roo Code / Claude Code
export GEMINI_API_KEY="..."      # Antigravity native agent
export XAI_API_KEY="..."         # Grok via Roo Code
```

> [!CAUTION]
> Treat every repository here as public. A committed key is compromised the moment it lands, and rotation is the only remedy — see the Security section of `AGENTS.md`.

### 2. VS Code Continue.dev Configuration
Deploy [`client-tools/ai-dev/continue-config.json`](../client-tools/ai-dev/continue-config.json) to `~/.continue/config.json`, replacing the `REPLACE_WITH_ANTHROPIC_API_KEY` placeholders with a real key (the deployed copy is outside version control):

```json
{
  "models": [
    {
      "title": "Claude Opus 5 (Deep Reasoning)",
      "provider": "anthropic",
      "model": "claude-opus-5",
      "contextLength": 1000000,
      "apiKey": "REPLACE_WITH_ANTHROPIC_API_KEY"
    },
    {
      "title": "Claude Sonnet 5 (Daily Driver)",
      "provider": "anthropic",
      "model": "claude-sonnet-5",
      "contextLength": 1000000,
      "apiKey": "REPLACE_WITH_ANTHROPIC_API_KEY"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Claude Haiku 4.5 (Autocomplete)",
    "provider": "anthropic",
    "model": "claude-haiku-4-5",
    "contextLength": 200000,
    "apiKey": "REPLACE_WITH_ANTHROPIC_API_KEY"
  }
}
```

> [!TIP]
> Use the exact model ID strings — never append date suffixes such as `claude-opus-5-20260401`. Dated variants are a convention from older model generations and will be rejected.

---

## 🚀 Deployment & Networking Architecture (`agy.bar2sek.com`)

The remote Antigravity node is accessible across all devices through two optimized paths:

```
[Remote Devices / Internet]                   [Local Devices on Home LAN / Wi-Fi]
 (Mac on the road, iPad, phone)                     (MacBook Pro, Local Desktops)
               │                                                  │
               │ HTTPS (agy.bar2sek.com)                          │ HTTPS (agy.bar2sek.com)
               ▼                                                  ▼
     [Cloudflare Edge Network]                          [UDM-Pro Local DNS]
   - Cloudflare Access (SSO Policy)                    - Split-Horizon DNS A record:
   - SSL / DDoS / WAF                                    agy.bar2sek.com -> 10.10.20.50
               │                                                  │
               │ Encrypted Outbound Tunnel (cloudflared)          │ Direct 10GbE Line-Rate
               ▼                                                  ▼
   [cloudflared Pod in Cluster]                                   │
               │                                                  │
               └───────────────► [Ingress-Nginx VIP: 10.10.20.50] ◄┘
                                       │
                                       │ Let's Encrypt Wildcard TLS (*.bar2sek.com)
                                       │ WebSocket Proxy Headers & 1hr Timeouts
                                       ▼
                               [Dev Workspace Service]
                                       │ (ports 8080 & 22)
                                       ▼
                         [antigravity-dev Pod on sm-node-03]
                               ┌───────────────────────────┐
                               │ - code-server Web IDE (:8080)
                               │ - OpenSSH Server (:22)    │
                               │ - Antigravity CLI (agy)   │
                               │ - rclone (Google Drive)   │
                               │ - 160GB RAM / 28 vCPUs    │
                               │ - 100GB Rook-Ceph NVMe PVC│
                               └───────────────────────────┘
```

### 1. Apply Declarative Infrastructure

```bash
# 1. Update Cloudflare Tunnel & Zero Trust Access (30-day SSO session)
just tf-apply cloudflare

# 2. Update UniFi Split-Horizon DNS (agy.bar2sek.com -> 10.10.20.50)
just tf-apply unifi

# 3. Apply the Dev Workspace Manifest
kubectl apply -f kubernetes/infrastructure/dev-workspace/dev-workspace.yaml
```

### 2. Multi-Device Access Modalities

#### A. Web Browser & PWA (iPad, iPhone, Mac, Windows, Linux)
* **Direct Access**: Navigate to `https://agy.bar2sek.com`.
* **On Local Network**: Split DNS routes directly to `10.10.20.50` over 10GbE with instant passwordless loading.
* **On Public Internet**: Cloudflare Zero Trust Access prompts once for Google SSO or Email OTP (valid for 30 days).
* **PWA Installation**: In Safari or Chrome, select **Add to Home Screen** (iOS/iPadOS) or **Install as App** (macOS). This provides a native window, offline caching, and full desktop keyboard shortcuts.
* **Agent CLI**: Open the integrated terminal (`Ctrl+` `) and run `agy` to plan, refactor, and execute agent tasks.

#### B. Native Desktop VS Code on macOS (`Remote - SSH`)
* Add the snippet from [`client-tools/ai-dev/ssh-config-snippet`](../client-tools/ai-dev/ssh-config-snippet) to `~/.ssh/config`.
* In VS Code, press `⌘+Shift+P` -> **Remote-SSH: Connect to Host** -> select `antigravity-dev`.
* Connects instantly with your native Ed25519 SSH key (`~/.ssh/id_ed25519`) without web SSO prompts.

#### C. Google Drive Synchronization & Backup (`rclone`)
* Untracked files, `.env` files, and persistent workspace configurations live on the 100GB Rook-Ceph NVMe volume.
* `rclone` is pre-installed inside the container to sync gitignored state directly to Google Drive (`rclone sync /workspace gdrive:second-brain/remote-workspace`).

