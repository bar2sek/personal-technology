---
title: "Homelab Deployment Journal & Handover Runbook"
date: 2026-09-12
tags:
  - homelab/journal
  - talos/deployment
  - unifi/runbook
status: in-progress
aliases:
  - "Deployment Journal"
  - "Handover Runbook"
---

# 📖 Homelab Deployment Journal & Handover Runbook

This document serves as the canonical, persistent record of all operations, architectural discoveries, and state changes executed across this hybrid homelab repository. 

Any AI agent or human operator can review this document to pick up exactly where work left off without duplicating effort or making assumptions.

---

## 🧭 Executive Summary & Current State (As of 2026-09-12)

* **Workstation & Remote Access**:
  * Native macOS OpenSSH daemon (`sshd`) enabled on MacBook Pro workstation.
  * Remote iPad client access operational via **Termius** SSH.
  * Local CLI discovery tool established: `client-tools/unifi-discover.py`.
* **UniFi Network Fabric**:
  * Gateway: UDM-Pro running UniFi OS at `https://10.0.1.1`.
  * WAN: 3.5 Gbps Google Fiber (WAN2 / SFP+) with IPv6 Prefix Delegation (`/56`) active.
  * Active LAN: `Default` corporate network on `10.0.1.1/24` with domain `bar2sek.com`.
  * Dedicated local administrator created: `terraform-admin` (Local Access Only).
  * 7 UniFi devices adopted and cataloged (UDM-Pro, 2x USW-Aggregation, USW-24-G2, USW-Lite-8-PoE, U7 Pro, U6-Lite).
  * Homelab VLANs (10, 20, 30, 40, 50, 90) designed and declared in Terraform; ready for initial deployment.
* **Physical Hardware & Node Roles**:
  * 3x Supermicro nodes (`main01`, `edge01`, `edge02`) powered on with IPMI interfaces active on `10.0.1.x` and connected to `USW-24-G2`.
  * 1x Storage PC (`stor01` / `pc-node-04`) dual 10G SFP+ NICs cataloged.
  * 1x Mini-ITX GPU PC (`pc-node-05` / RTX 4070) plugged into aggregation switch.
  * 1x Dell OptiPlex Micro (`omni-server`) powered on; awaiting Sidero Omni USB installer boot.

---

## 📋 Physical Hardware & Discovered Interface Matrix

| Node / Device | Role | Management / IPMI | 10G / High-Speed SFP+ | Connected Switch Ports | Status / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`sm-node-01`** (`edge01`) | Control Plane 1 + Worker | IPMI: `3c:ec:ef:44:a4:2c`<br>IP: `10.0.1.190` | `eno7np2`: `3c:ec:ef:44:9b:50`<br>`eno8np3`: `3c:ec:ef:44:9b:51` | IPMI -> `USW-24-G2` Port 11<br>10G -> `USW-Agg #1` Ports 1 & 2 | Online; Supermicro Xeon D; HTML5 KVM ready at `https://10.0.1.190` |
| **`sm-node-02`** (`edge02`) | Control Plane 2 + Worker | IPMI: `3c:ec:ef:6f:da:41`<br>IP: `10.0.1.208` | `10G-1`: `3c:ec:ef:6f:d4:bc`<br>`10G-2`: `3c:ec:ef:6f:d4:bd` | IPMI -> `USW-24-G2` Port 15<br>10G -> `USW-Agg #1` Ports 3 & 4 | Online; Supermicro Xeon D; HTML5 KVM ready at `https://10.0.1.208` |
| **`sm-node-03`** (`main01`) | Primary Control Plane + Heavy Worker | IPMI: `3c:ec:ef:5b:9a:da`<br>IP: `10.0.1.228` | `10G-1`: `a0:36:9f:3b:0c:f8`<br>`10G-2`: `a0:36:9f:3b:0c:fa` | IPMI -> `USW-24-G2` Port 1<br>10G -> Core Aggregation Fabric | Online; Supermicro 813M Xeon E5; HTML5 KVM ready at `https://10.0.1.228` |
| **`pc-node-04`** (`stor01`) | Storage Worker (11 HDDs) | 1GbE Onboard: `2c:f0:5d:57:7e:a4` | `10G-1`: `a0:36:9f:9a:ce:24`<br>`10G-2`: `a0:36:9f:9a:ce:26` | 10G -> USW-Agg #1 & #2 | Powered on; Ryzen 3800X; boots off Intel 320 SSD |
| **`pc-node-05`** (GPU PC) | GPU Worker (RTX 4070) | 1GbE USB: Available | 2.5GbE SFP+ Transceiver | SFP+ -> `Ceph-USW-Agg` Port 3/4 | Powered on; Ryzen 7600; AM5 ITX board |
| **`omni-server`** (Dell Micro) | Sidero Omni Controller | 1GbE Onboard: Dell OptiPlex | N/A | 1GbE -> `USW-24-G2` / `USW-Agg` | Powered on; awaiting Sidero Omni boot media |

---

## 🌐 Adopted UniFi Infrastructure Inventory

| Device Name | Model Identifier | MAC Address | Management IP | Primary Function |
| :--- | :--- | :--- | :--- | :--- |
| **UDM-Pro** | `UDMPRO` | `68:d7:9a:50:ee:2d` | `10.0.1.1` | L3 Gateway, DHCP Server, WAN Routing |
| **USW-Aggregation** | `USL8A` | `f4:92:bf:a3:37:65` | `10.0.1.224` | Core 10G SFP+ Fabric (Ports 7/8 in 20G LAG) |
| **Ceph-USW-Aggregation** | `USL8A` | `f4:e2:c6:5d:d6:f8` | `10.0.1.59` | Dedicated 10G SFP+ Storage Network (Ports 7/8 in 20G LAG) |
| **USW-24-G2** | `USL24` | `24:5a:4c:60:bb:09` | `10.0.1.30` | 1G Access Switch for IPMI, Omni, and management |
| **USW-Lite-8-PoE** | `USL8LP` | `78:45:58:82:8a:39` | `10.0.1.40` | Garage PoE Switch (powers G3-Flex & AP) |
| **U7 Pro** | `U7PRO` | `94:2a:6f:c4:ec:04` | `10.0.1.214` | Primary House Wi-Fi 7 Access Point |
| **U6-Lite** | `UAL6` | `24:5a:4c:13:ae:3c` | `10.0.1.45` | Garage Wi-Fi 6 Access Point |

---

## 🛠️ Step-by-Step Chronological Work Log

### 2026-09-12
1. **Repository & Architecture Audit**:
   - Reviewed all 25 architecture documents, Kubernetes platform manifests, and Terraform configurations.
   - Identified 5-node cluster topology with `allowSchedulingOnControlPlanes: true` across 3 Supermicro servers + 2 desktop workers.
2. **Workstation Remote Connectivity**:
   - Verified native macOS SSH daemon configuration (`sudo systemsetup -setremotelogin on`).
   - Configured iPad SSH client (**Termius**) connecting to Mac workstation.
3. **UniFi Controller Local Credentials**:
   - Resolved Cloud SSO vs. Local Credential boundary on UniFi OS.
   - Created dedicated `terraform-admin` user with Local Access Only and Super Admin / Network permissions on UDM-Pro (`https://10.0.1.1`).
4. **Automated UniFi Discovery**:
   - Created [`client-tools/unifi-discover.py`](file:///client-tools/unifi-discover.py) with zero external Python dependencies.
   - Executed live API discovery against `https://10.0.1.1`.
   - Generated [`client-tools/unifi-inventory.json`](file:///client-tools/unifi-inventory.json) and [`client-tools/terraform.tfvars.discovered`](file:///client-tools/terraform.tfvars.discovered).
   - Extracted live physical switch port tables, 20G LAG backbone status, Google Fiber 3.5G WAN2 configuration, and live node MAC addresses.
5. **Headless PC & IPMI Strategy**:
   - Confirmed 3 Supermicro servers possess live HTML5 KVM consoles over IPMI without physical monitors.
   - Confirmed consumer PCs are headless and will be wiped and flashed via zero-touch Sidero Omni PXE booting.
6. **UniFi Terraform Code Alignment**:
   - Made `omni_mac_address` optional via conditional `count` in [`terraform/unifi/main.tf`](file:///terraform/unifi/main.tf).
   - Added declarative static DHCP reservations for the 3 Supermicro IPMI BMC interfaces (`10.10.10.11`, `10.10.10.12`, `10.10.10.13`) using discovered MAC addresses.
   - Created [`terraform/unifi/terraform.tfvars.example`](file:///terraform/unifi/terraform.tfvars.example).
   - Updated [`terraform/unifi/outputs.tf`](file:///terraform/unifi/outputs.tf) with IPMI static IP outputs.
7. **Terraform Provider Migration & Schema Modernization**:
   - Upgraded UniFi provider in [`terraform/unifi/providers.tf`](file:///terraform/unifi/providers.tf) from deprecated `paultag/unifi` to `ubiquiti-community/unifi` (`~> 0.41.0`).
   - Refactored [`terraform/unifi/main.tf`](file:///terraform/unifi/main.tf) to match modern provider schema:
     - Migrated `vlan_id` to `vlan`.
     - Migrated standalone DHCP flags (`dhcp_enabled`, `dhcp_start`, `dhcp_stop`) to nested `dhcp_server = { enabled = true, start = "...", stop = "..." }` blocks.
     - Migrated `unifi_user` to `unifi_client` with `allow_existing = true` for idempotent device adoption.
     - Migrated `unifi_port_profile` forward mode to `forward = "customize"`.
   - Successfully initialized (`terraform init`) with `ubiquiti-community/unifi v0.41.25` and verified valid syntax via `terraform validate`.

---

## 🎯 Immediate Next Actions

1. **Populate Local Credentials**:
   - Populate local password for `terraform-admin` in `terraform/unifi/terraform.tfvars` (ignored by git).
2. **Execute UniFi Terraform Plan & Review**:
   - Run `just tf-plan unifi` (or `terraform -chdir=terraform/unifi plan`) to preview provisioning of 7 VLANs, 3 IPMI DHCP reservations, 2 port profiles, and 2 firewall isolation rules.
3. **Apply UniFi Homelab Networks**:
   - Apply Terraform configuration to provision VLANs 10, 20, 30, 40, 50, 60, 90.
4. **Sidero Omni Installation (`omni-server`)**:
   - Write Sidero Omni boot media to USB drive for the Dell OptiPlex Micro.
   - Boot Dell OptiPlex into Omni installer and access web console at `10.10.10.5`.
5. **UniFi PXE Configuration**:
   - Enable DHCP boot option (`boot { enabled = true, server = "10.10.10.5", filename = "ipxe.efi" }`) on VLAN 20 pointing to `omni-server`.

