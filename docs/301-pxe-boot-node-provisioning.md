# Network PXE Boot & Node Provisioning Instruction Manual

This manual provides step-by-step instructions for configuring **Network PXE Boot** across all 5 Kubernetes cluster nodes (`sm-node-01` through `pc-node-05`) using **Sidero Omni** and **UniFi DHCP**.

---

## Omni Server (`omni-server`) PXE Boot Server

1. Install Sidero Omni directly onto `omni-server`'s local 500GB Samsung 860 EVO SSD using a standard USB installation flash drive.
2. Once booted, `omni-server` runs the PXE TFTP/HTTP boot service (`iPXE`) that provisions the remaining **5 Talos cluster nodes** over the network!

---

## 🌐 UniFi Network PXE Configuration (`UDM-Pro`)

In your UniFi Controller, configure network boot settings on **VLAN 20 (`K8S-CONTROL`)**:

- **Network Boot**: Enabled
- **Server IP Address**: `10.10.20.5` (Sidero Omni Server IP)
- **iPXE Boot Filename**: `undionly.kpxe` (Legacy BIOS) or `ipxe.efi` (UEFI)

---

## 📋 Node-by-Node BIOS & PXE Setup Instructions

### 1. Supermicro Nodes (`sm-node-01`, `sm-node-02`, `sm-node-03`)

These nodes feature dedicated IPMI BMC ports and dual 10G SFP+ / 1GbE ports.

- **Step 1**: Access Supermicro IPMI Web Interface (e.g. `http://10.10.10.11`).
- **Step 2**: Open Remote iKVM HTML5 Console.
- **Step 3**: Reboot node and press `DEL` to enter BIOS Setup.
- **Step 4**: Navigate to **Advanced > Network Stack Configuration** -> Set `IPv4 PXE Support -> Enabled`.
- **Step 5**: Navigate to **Boot Options** -> Set `Boot Option #1 -> UEFI Network (iPXE)`.
- **Step 6**: Save & Exit. The node will boot, contact Sidero Omni, and auto-register with Talos Linux.

---

### 2. Desktop PC Nodes (`pc-node-04` Ryzen 3800X & `pc-node-05` Ryzen 7600)

These consumer gaming PC motherboards do not have IPMI, so they use standard onboard NIC PXE Boot.

- **Step 1**: Attach monitor/keyboard (or use temporary USB KVM) and power on the PC.
- **Step 2**: Press `DEL` or `F2` to enter BIOS Setup.
- **Step 3**: Navigate to **Advanced > Onboard Devices Configuration** -> Set `Realtek/Intel PXE OPROM -> Enabled`.
- **Step 4**: Navigate to **Advanced > Power Management** -> Set `Restore AC Power Loss -> Power On` and `Enable Wake-on-LAN (WoL) -> Enabled`.
- **Step 5**: Navigate to **Boot Menu** -> Set `Boot Option #1 -> Network / PXE Boot`.
- **Step 6**: Save & Exit. The PC will boot over network Ethernet, obtain an IP from UniFi, fetch the Talos kernel from Sidero Omni, and begin installation onto its dedicated boot drive!

---

## 📊 Summary Provisioning Matrix

| Hostname | Node Role | Initial Install Method | Boot Drive Location | Daily Management |
| :--- | :--- | :--- | :--- | :--- |
| `omni-server` | Omni Bare-Metal Engine | USB Flash Drive | 500GB Samsung SSD | Omni Web Console |
| `sm-node-01` | Control Plane + Worker | Network PXE (via Omni) | 16GB SATA SuperDOM | Talos API (`talosctl`) |
| `sm-node-02` | Control Plane + Worker | Network PXE (via Omni) | 16GB SATA SuperDOM | Talos API (`talosctl`) |
| `sm-node-03` | Primary Control Plane | Network PXE (via Omni) | Dual 16GB SuperDOMs | Talos API (`talosctl`) |
| `pc-node-04` | Storage & Compute Worker | Network PXE (via Omni) | 80GB Intel 320 SSD | Talos API (`talosctl`) |
| `pc-node-05` | GPU Worker (RTX 4070) | Network PXE (via Omni) | 2GB NVMe Partition | Talos API (`talosctl`) |
