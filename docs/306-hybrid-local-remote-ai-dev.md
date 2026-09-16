# Hybrid Local/Remote AI Development Architecture (Apple MLX + Kubernetes)

This guide specifies the architecture, client configuration, and Kubernetes manifests for our **Hybrid Local/Remote AI Development Stack**. It combines zero-latency local code completion on Apple Silicon via **Apple MLX / oMLX** with unbounded remote agentic execution inside our on-premise Talos Kubernetes cluster.

---

## 🏗 Architectural Topology

The system separates concerns into three distinct layers:

1. **Client Layer (macOS / 48GB Unified RAM)**:
   - Runs standard VS Code with the **Continue.dev** extension.
   - Hosts local, zero-latency inference using **Apple MLX / oMLX** (Metal-accelerated C++ framework native to Apple Silicon).
   - Zero Antigravity binaries installed locally; no local build tools required.

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
 |  | VS Code            |                     | Apple MLX / oMLX Local Server    |  |
 |  | (Continue.dev UI)  |--- IPC (:8081) ---->| - Tab Autocomplete (Qwen 14B)    |  |
 |  |                    |--- IPC (:8080) ---->| - Deep Chat & Refactor (Qwen 32B)|  |
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

| Layer | Engine / Interface | Model & Role | Memory Footprint (Weights + KV) |
| :--- | :--- | :--- | :--- |
| **Tab Completion** | Continue.dev in VS Code | **Qwen 2.5 Coder 14B (4-bit MLX)**<br>Context: Strict 4,096 tokens (FIM ghost text) | ~8.8 GB |
| **In-Editor Chat & Scoped Refactor** | Continue.dev Sidebar in VS Code | **Qwen 2.5 Coder 32B (4-bit MLX)**<br>Context: 32,768 tokens (diffs, unit tests) | ~22.0 GB |
| **Autonomous Agent Automation** | Antigravity Remote Dashboard or `agy` CLI | **Antigravity Agent Platform**<br>Multi-file refactors, long-running test suites | Cluster Host Memory (`sm-node-03`) |

---

## 🍏 Why Apple MLX / oMLX Over Ollama on macOS?

1. **Native Metal Architecture**: MLX was designed from scratch by Apple's machine learning research team for Apple Silicon unified memory. It avoids the translation overhead and CPU-GPU synchronization bottlenecks present in llama.cpp wrappers.
2. **Direct Unified Memory Access**: Zero memory copying—Metal shaders operate directly on model weight tensors in RAM, achieving peak memory bandwidth (up to 150–300+ GB/s).
3. **Dynamic Buffer Allocation**: MLX allocates Metal memory on-demand and immediately frees KV cache pages without holding rigid allocations.
4. **OpenAI-Compatible Server API**: oMLX and `mlx-lm.server` expose standard `http://localhost:8000/v1` endpoints that drop directly into VS Code extensions.

---

## 💾 Client Memory Budget (48GB Unified RAM Envelope)

Under simultaneous load with both models resident in Metal memory:

- **Qwen 2.5 Coder 14B (4-bit) + 4k KV Cache**: ~8.8 GB
- **Qwen 2.5 Coder 32B (4-bit) + 32k KV Cache**: ~22.0 GB
- **macOS System Overhead & VS Code UI**: ~9.0 GB
- **Safety Margin / Working Headroom**: ~8.2 GB
- **Total In-Use**: **~39.8 GB / 48.0 GB** (Safely avoids disk swapping).

---

## 🛠 macOS Client Configuration

### 1. Metal VRAM Ceiling Tuning
By default, macOS limits any single process to ~70% of unified memory. Run this command to raise the Metal wired allocation ceiling to 40 GB:

```bash
sudo sysctl iogpu.wired_mem_limit=40960
```
To persist this across reboots, add to `/etc/sysctl.conf`:
```text
iogpu.wired_mem_limit=40960
```

### 2. Automated Installation Script & Justfile Shortcuts
Run [`client-tools/ai-dev/setup-mac-mlx.sh`](../client-tools/ai-dev/setup-mac-mlx.sh) or execute via `Justfile`:

```bash
# Set up Metal ceiling and pre-cache models via Astral uv
./client-tools/ai-dev/setup-mac-mlx.sh

# Launch dual-port MLX servers (:8081 Tab Autocomplete + :8080 Deep Chat)
just serve-ai
```

### 3. VS Code Continue.dev Configuration
Deploy [`client-tools/ai-dev/continue-config.json`](../client-tools/ai-dev/continue-config.json) to `~/.continue/config.json` (also managed declaratively via `nix-mac`):

```json
{
  "tabAutocompleteModel": {
    "title": "Local Qwen 14B Autocomplete (MLX)",
    "provider": "openai",
    "model": "mlx-community/Qwen2.5-Coder-14B-Instruct-4bit",
    "apiBase": "http://localhost:8081/v1",
    "contextLength": 4096
  },
  "models": [
    {
      "title": "Local Qwen 32B Chat (oMLX)",
      "provider": "openai",
      "model": "mlx-community/Qwen2.5-Coder-32B-Instruct-4bit",
      "apiBase": "http://localhost:8080/v1",
      "contextLength": 32768
    }
  ]
}
```

---

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

