# UDM-Pro Network & VLAN Setup Guide (Step-by-Step)

This guide walks you step-by-step through configuring all required subnets, VLANs, DHCP options, and switch port profiles on your **UniFi Dream Machine Pro (UDM-Pro)** to transform your single default network into a fully segmented, enterprise-grade hybrid homelab fabric.

---

## 📋 Complete Network Blueprint

| Network Name | VLAN ID | Subnet / Gateway | DHCP Range | Special Features / Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Default (Home LAN)** | `1` (Untagged) | `192.168.1.1/24` | `192.168.1.10 - .254` | Primary home network, Wi-Fi 7 (U7 Pro), phones, laptops. |
| **MGMT-IPMI** | `10` | `10.10.10.1/24` | `10.10.10.10 - .254` | Supermicro IPMI/BMC ports, `omni-server` static IP (`10.10.10.5`). |
| **K8S-CONTROL** | `20` | `10.10.20.1/24` | `10.10.20.10 - .254` | Talos API (`6443`), Kubelet, etcd, **PXE Network Boot (iPXE)**, IPv6 PD. |
| **CEPH-STORAGE** | `40` | `10.10.40.1/24` | `10.10.40.10 - .254` | 10GbE East-West storage replication for Rook-Ceph, **MTU 9000**. |
| **K8S-METALLB** | `50` | `10.10.50.1/24` | *None (Manual Pool)* | Kubernetes Ingress LoadBalancer VIP pool (`10.10.50.100 - .200`). |

---

## 🛠 Method 1: Web UI Configuration (UniFi Network Application)

Log into your UDM-Pro dashboard (`https://192.168.1.1` or `https://unifi.ui.com`) and navigate to **Settings (Gear Icon) > Networks**.

---

### Step 1: Create `MGMT-IPMI` (VLAN 10)
1. Click **New Virtual Network**.
2. **Network Name**: `MGMT-IPMI`
3. **Router**: `UniFi Dream Machine Pro`
4. **VLAN ID**: `10`
5. **Gateway IP/Subnet**: `10.10.10.1/24`
6. **Advanced Settings (Manual)**:
   - **DHCP Mode**: `DHCP Server`
   - **DHCP Range**: `10.10.10.10` to `10.10.10.254`
   - **Domain Name**: `mgmt.homelab.local`
7. Click **Add Network**.

---

### Step 2: Create `K8S-CONTROL` (VLAN 20) with PXE Boot
1. Click **New Virtual Network**.
2. **Network Name**: `K8S-CONTROL`
3. **VLAN ID**: `20`
4. **Gateway IP/Subnet**: `10.10.20.1/24`
5. **Advanced Settings (Manual)**:
   - **DHCP Range**: `10.10.20.10` to `10.10.20.254`
   - **Domain Name**: `k8s.homelab.local`
   - **IPv6 Interface Type**: `Prefix Delegation` (Select WAN1/Port 11)
   - **DHCPv6**: `Enabled`
6. **Configure PXE Network Boot (DHCP Option 66 & 67)**:
   - Check **Network Boot**.
   - **Server IP (Next-Server / Option 66)**: `10.10.10.5` (or `10.10.20.5` Sidero Omni Server).
   - **Boot Filename (Option 67)**: `ipxe.efi` (for UEFI nodes) or `undionly.kpxe` (for BIOS).
7. Click **Add Network**.

---

### Step 3: Create `CEPH-STORAGE` (VLAN 40)
1. Click **New Virtual Network**.
2. **Network Name**: `CEPH-STORAGE`
3. **VLAN ID**: `40`
4. **Gateway IP/Subnet**: `10.10.40.1/24`
5. **Advanced Settings (Manual)**:
   - **DHCP Range**: `10.10.40.10` to `10.10.40.254`
   - **Domain Name**: `ceph.homelab.local`
   - **Isolate Network**: Checked (prevents accidental broadcast traffic from non-storage devices).
6. Click **Add Network**.

---

### Step 4: Create `K8S-METALLB` (VLAN 50)
1. Click **New Virtual Network**.
2. **Network Name**: `K8S-METALLB`
3. **VLAN ID**: `50`
4. **Gateway IP/Subnet**: `10.10.50.1/24`
5. **Advanced Settings (Manual)**:
   - **DHCP Mode**: `None` (Static VIPs allocated by MetalLB / Cilium).
6. Click **Add Network**.

---

## 🔌 Step 5: Switch Port Profile & VLAN Tagging

Navigate to **UniFi Devices > USW-24-G2 / USW-Aggregation > Ports**:

### 1. USW-24-G2 (1G Management Switch):
- **Port 1 (`omni-server`)**: Set Native VLAN to `MGMT-IPMI` (VLAN 10).
- **Ports 2, 3, 4 (Supermicro IPMI ports)**: Set Native VLAN to `MGMT-IPMI` (VLAN 10).
- **Ports 5, 6 (`pc-node-04`/`05` 1G onboard)**: Set Native VLAN to `K8S-CONTROL` (VLAN 20).

### 2. USW-Aggregation #1 & #2 (10G SFP+ Backbone):
- **Ports 7 & 8 (20G LAG Backbone)**: Profile = `All (Trunk)` with 802.3ad Link Aggregation enabled.
- **Server 10G SFP+ Ports (`sm-node-01`, `02`, `03`, `pc-node-04`)**:
  - **Native VLAN**: `K8S-CONTROL` (VLAN 20)
  - **Tagged VLAN Management**: Allow `CEPH-STORAGE` (VLAN 40) and `K8S-METALLB` (VLAN 50).
- **Jumbo Frames**: In **Settings > Networks > Global Network Settings**, toggle **Jumbo Frames (MTU 9000)** to `ON` across all USW-Aggregation switches.

---

## 🤖 Method 2: Automated Deployment via Terraform

You can deploy all of these networks instantly using our Infrastructure-as-Code module:

```bash
cd terraform/unifi
terraform init
terraform apply
```

This runs [`terraform/unifi/main.tf`](./terraform/unifi/main.tf) which declaratively provisions VLANs 10, 20, 40, IPv6 Prefix Delegation, and static IP reservations in seconds!
