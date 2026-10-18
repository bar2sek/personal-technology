---
title: "Sidero Omni, Dex & Booter Platform Architecture"
date: 2026-10-04
status: evergreen
tags:
  - talos/omni
  - pxe/booting
  - dex/oidc
  - kubernetes/infrastructure
  - disaster-recovery
---

# 🛸 Sidero Omni, Dex & Booter Platform Architecture

This document defines the architecture, service interactions, security model, and disaster recovery procedures for **Sidero Omni**, our bare-metal Kubernetes management platform.

---

## 🏛️ Platform Architecture Overview

Sidero Omni operates as the Day-0/Day-1 provisioning engine for our Talos bare-metal cluster. It is currently deployed as a self-hosted instance on the standalone OptiPlex seed host (`10.10.10.5` / `10.10.20.5`).

```mermaid
graph TD
    subgraph MANAGEMENT_LAYER["Seed Node (OptiPlex 10.10.10.5)"]
        OMNI_SRV["Omni Server (omni.yaml)<br/>Embedded etcd + WireGuard Relay"]
        DEX["Dex IdP (dex.yaml)<br/>Port 5556 (OIDC Broker)"]
        BOOTER["SideroBooter (booter.yaml)<br/>TFTP / HTTP iPXE Server"]
    end

    subgraph STORAGE_STATE["Omni Host State (OptiPlex SSD)"]
        DATA_VOL["hostPath: /var/lib/kubelet/omni-data<br/>/_out/etcd & /_out/sqlite.db"]
        ASC_KEY["Secret: omni-asc (/omni.asc)<br/>Omni Account PGP/Private Key"]
        TLS_KEYS["Secret: omni-tls & omni-ca<br/>Internal mTLS Certificates"]
    end

    subgraph BARE_METAL_NODES["Physical Cluster Nodes"]
        N1["sm-node-01"]
        N2["sm-node-02"]
        N3["sm-node-03"]
        N4["pc-node-04"]
        N5["pc-node-05"]
    end

    BOOTER -->|DHCP PXE / iPXE Stream| BARE_METAL_NODES
    OMNI_SRV -->|SideroLink WireGuard (Port 50180)| BARE_METAL_NODES
    DEX -->|OIDC Token Validation| OMNI_SRV
    OMNI_SRV --> DATA_VOL
    OMNI_SRV --> ASC_KEY
    OMNI_SRV --> TLS_KEYS
```

---

## 📦 Component Specifications

### 1. Sidero Omni Server (`omni.yaml`)
* **Image**: `ghcr.io/siderolabs/omni:v1.12.0`
* **Account ID**: `00000000-0000-0000-0000-000000000001`
* **Network Endpoints**:
  * Web & API: `https://omni.bar2sek.com` (Port 443)
  * Machine API: `grpc://10.10.10.5:8090`
  * Kubernetes Proxy: `https://10.10.10.5:8100`
  * SideroLink WireGuard: `10.10.10.5:50180` (UDP)
* **Authentication**: Delegated via Dex OIDC at `https://omni.bar2sek.com:5556`.

### 2. Dex Identity Provider (`dex.yaml`)
* **Image**: `ghcr.io/dexidp/dex:v2.41.1`
* **Port**: 5556 (HTTPS)
* **Configuration**: Static client for Omni with TLS termination.

### 3. SideroBooter PXE Engine (`booter.yaml`)
* **Image**: `ghcr.io/siderolabs/booter:v0.3.0`
* **Host Networking**: `hostNetwork: true` with `NET_ADMIN` and `NET_BIND_SERVICE`.
* **Talos Target Release**: `v1.13.10`.
* **Custom Schematic**: `5cd745a060945934ac9f118483db0d1b2e405b934c07716d583060cc30fa899f` (includes Intel 10GbE network drivers and non-free firmware).

---

## ⚠️ Single Point of Failure (SPOF) & State Isolation

> [!WARNING] Critical Single-Node Dependency
> Omni's embedded etcd database, SQLite state, and master decryption key live entirely on a single OptiPlex host drive (`/var/lib/kubelet/omni-data`). If this drive experiences catastrophic hardware failure without backups, the ability to manage machine configurations, issue Talos certificates, and rotate cluster keys via Omni is permanently lost.

### State Inventory Required for 100% Recovery:
1. **Master Encryption Key**: `omni.asc` (stored in Kubernetes Secret `omni-asc`).
2. **Embedded Database**: `/var/lib/kubelet/omni-data/_out/sqlite.db` and `/var/lib/kubelet/omni-data/_out/etcd/`.
3. **CA and TLS Certificates**: Secrets `omni-ca`, `omni-tls`, and `omni-oidc`.

---

## 🛡️ Disaster Recovery & Backup Runbook

### Step 1: Automated Snapshot Script
Run the following backup command from the OptiPlex host or administrative workstation:

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/omni-backup-${BACKUP_DATE}"
mkdir -p "${BACKUP_DIR}"

echo "===> Exporting Omni Kubernetes Secrets..."
kubectl -n omni get secret omni-asc omni-ca omni-tls omni-oidc -o yaml > "${BACKUP_DIR}/omni-secrets.yaml"

echo "===> Archiving Omni HostPath Data..."
sudo tar -czf "${BACKUP_DIR}/omni-data.tar.gz" -C /var/lib/kubelet omni-data

echo "===> Packaging Master Disaster Recovery Archive..."
tar -czf "omni-dr-${BACKUP_DATE}.tar.gz" -C /tmp "omni-backup-${BACKUP_DATE}"
rm -rf "${BACKUP_DIR}"

echo "Omni DR archive created: omni-dr-${BACKUP_DATE}.tar.gz"
```

### Step 2: Offsite Storage
The archive contains Omni's secrets, so encrypt it before it leaves the host. Use the same `age` recipient as the cluster backups (in `kubernetes/infrastructure/backups/configmap-backup-encryption.yaml`), then upload as an administrator:

```bash
AGE_RECIPIENT=$(awk -F'"' '/AGE_RECIPIENT:/ {print $2}' kubernetes/infrastructure/backups/configmap-backup-encryption.yaml)
age -r "${AGE_RECIPIENT}" -o "omni-dr-${BACKUP_DATE}.tar.gz.age" "omni-dr-${BACKUP_DATE}.tar.gz"
aws s3 cp "omni-dr-${BACKUP_DATE}.tar.gz.age" "s3://s3-aws-backups-prod-use2-001/omni/" --checksum-algorithm CRC32
rm -f "omni-dr-${BACKUP_DATE}.tar.gz"
```

> [!IMPORTANT]
> The backup bucket rejects any object that isn't `*.age`, requires an upload checksum (Object Lock), and removes objects after about 36 days through lifecycle. Keep the most recent Omni archive in secondary offline storage too, because it changes rarely and must outlive that window. Restore with `age -d -i <identity> …`, as described in the Backups README.

### Step 3: Complete Bare-Metal Restoration
If the OptiPlex host is replaced:
1. Re-install Talos Linux on the replacement machine (`10.10.10.5`).
2. Re-create `/var/lib/kubelet/omni-data` and extract `omni-data.tar.gz`.
3. Apply `omni-secrets.yaml` to the namespace `omni`.
4. Apply `kubernetes/infrastructure/omni/` manifests (`dex.yaml`, `booter.yaml`, `omni.yaml`).
5. Omni will immediately resume management of existing cluster nodes without re-PXE booting or rebuilding cluster state.

---

## 💻 Workstation CLI Access (`omnictl` / `talosctl`)

Both CLIs talk to Omni's API at `https://omni.bar2sek.com/`. Omni serves the `*.bar2sek.com` Let's Encrypt wildcard certificate, which has **no IP SANs**, so a client configured with `https://10.10.10.5/` fails with `x509: cannot validate certificate for 10.10.10.5`.

**Refreshing access (about two minutes):**
1. Omni web UI → **Home** → **Download omniconfig** (and **Download talosconfig**).
2. `omnictl config merge ~/Downloads/omniconfig.yaml` (and `talosctl config merge ~/Downloads/talosconfig.yaml`).
3. Run any command (for example `omnictl get clusters`). The first call opens the browser to sign in and saves a PGP key under `~/.talos/keys/`.

> [!WARNING]
> **Split-horizon DNS only covers IPv4.** The UDM-Pro answers `A` queries for `*.bar2sek.com` locally (`10.10.10.5`), but forwards `AAAA` queries upstream, which return **Cloudflare** IPv6 addresses. macOS prefers IPv6, so CLI traffic goes to Cloudflare and Access answers `403`. omnictl reports this as `server closed the stream without sending trailers`. Browsers work because they can log in through Access.
>
> Workstation workaround (both lines are needed, because macOS consults DNS for IPv6 even when `/etc/hosts` has an IPv4 entry):
> ```bash
> echo "10.10.10.5 omni.bar2sek.com" | sudo tee -a /etc/hosts
> echo "::ffff:10.10.10.5 omni.bar2sek.com" | sudo tee -a /etc/hosts
> sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
> curl -sk -o /dev/null -w '%{remote_ip}\n' https://omni.bar2sek.com/   # must not be 2606:4700:…
> ```
> Open item: fix the router so local names also get local (or empty) `AAAA` answers. The same leak sends LAN traffic for `grafana.bar2sek.com` through Cloudflare.

