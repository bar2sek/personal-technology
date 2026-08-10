# Phase 1: Sidero Omni Setup & Talos Bare-Metal Provisioning Plan

This guide outlines the step-by-step procedure to deploy **Sidero Omni** on the Dell OptiPlex Micro (`omni-server`) and provision our 5 bare-metal nodes into a High-Availability Talos Linux cluster.

---

## 🎯 Phase 1 Goals

1. Install Sidero Omni on the Dell OptiPlex Micro (`omni-server`).
2. Configure network PXE boot / iPXE infrastructure on the UniFi network (`MGMT-IPMI` & `K8S-CONTROL` VLANs).
3. Register the 5 bare-metal machines into Sidero Omni.
4. Apply Talos machine configurations declaratively to bootstrap the 3-Node HA Control Plane + 2-Node Worker cluster.

---

## 💻 Hardware Assignment: Omni Server

| Parameter | Value |
| :--- | :--- |
| **Hostname** | `omni-server` |
| **Hardware** | Dell OptiPlex Micro (D08U) |
| **OS Drive** | 500GB Samsung 860 EVO SATA SSD |
| **Network Interface (Primary)** | Onboard 1GbE RJ45 (`MGMT-IPMI` VLAN 10 for Admin UI / API) |
| **Network Interface (Secondary)** | USB 1GbE Adapter (`K8S-CONTROL` VLAN 20 for iPXE / PXE Boot Server) |
| **IP Addresses** | Static IPs (`10.10.10.5` Admin / `10.10.20.5` iPXE Provisioning) |

---

## 🛠 Step 1: Install Sidero Omni OS & Service

Sidero Omni runs on Linux (or as a standalone Talos/Omni boot image).

### Option A: Omni On-Premises (Recommended)
1. Flash the Omni installer / Linux OS onto the 500GB Samsung 860 EVO SSD.
2. Configure `omni-server` to run Omni services:
   - **Omni Management API**: Manages machine configs, cluster states, and Talos upgrades.
   - **Sidero iPXE / PXE Server**: Listens for PXE boot requests from target nodes over the network.
   - **Wireguard / Tunnel Agent**: Secure communication between Omni and bare-metal nodes.

---

## 🔌 Step 2: UniFi Network & PXE Boot Configuration

1. In the **UniFi Network Controller**:
   - Go to **Settings > Networks > K8S-CONTROL (VLAN 20)**.
   - Enable **Network Boot / PXE Boot**.
   - Set **TFTP Server / Boot Server IP**: `10.10.10.5` (Omni Server IP).
   - Set **Boot File Name**: `undionly.kpxe` (for BIOS) or `ipxe.efi` (for UEFI).

---

## 🖥 Step 3: Node Bios & Boot Configuration

For all 5 bare-metal nodes:

### Supermicro Nodes (`sm-node-01`, `sm-node-02`, `sm-node-03`):
1. Log into Supermicro IPMI web interface.
2. Ensure SATA SuperDOM is set as Primary Disk / Boot Drive.
3. Enable **Network Boot (PXE)** on the 10G SFP+ or 1GbE boot interface.
4. Set Boot Order: **1st: Network PXE Boot**, **2nd: SATA SuperDOM**.

### Gaming PC Workers (`pc-node-04`, `pc-node-05`):
1. Enter UEFI/BIOS setup.
2. Enable **PXE / Network Stack (UEFI Network Boot)**.
3. Enable **NVIDIA Resizable BAR** and **Above 4G Decoding** on `pc-node-05` (for RTX 4070 GPU passthrough).
4. Set Boot Order: **1st: Network Boot**, **2nd: NVMe / Local Drive**.

---

## 🚀 Step 4: Machine Discovery & Registration in Omni

1. Boot all 5 machines via PXE network boot.
2. The nodes pull the Omni maintenance iPXE kernel over the network and register automatically with the Omni Web Console.
3. In the Omni Web UI / CLI:
   - Assign `sm-node-01`, `sm-node-02`, and `sm-node-03` to **Control Plane Role**.
   - Assign `pc-node-04` and `pc-node-05` to **Worker Role**.

---

## 📋 Step 5: Talos Machine Configuration Extensions

When Omni applies the Talos Linux configuration, we inject custom Talos system extensions:

```yaml
# Extension for 10G Intel SFP+ cards & NVIDIA GPU driver
machine:
  install:
    extensions:
      - siderolabs/nonfree-kmod-nvidia  # NVIDIA Kernel Modules for RTX 4070
      - siderolabs/nvidia-container-toolkit # GPU Container Runtime
```

---

## ⏱ Step 6: Cluster Bootstrap & Verification

1. Click **Deploy Cluster** in Omni.
2. Omni flashes Talos Linux onto:
   - **SATA SuperDOMs** for `sm-node-01`, `sm-node-02`, and `sm-node-03`.
   - **NVMe OS Drives** for `pc-node-04` and `pc-node-05`.
3. Nodes reboot into Talos Linux, establish etcd quorum, and form the 5-node Kubernetes cluster.
4. Verify cluster status using `talosctl` and `kubectl`:
   ```bash
   talosctl --nodes 10.10.20.10 health
   kubectl get nodes -o wide
   ```
