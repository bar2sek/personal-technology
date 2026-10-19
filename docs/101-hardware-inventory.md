---
title: "Homelab Hardware Inventory & Cluster Roles"
date: 2026-09-12
tags:
  - homelab/hardware
  - inventory
  - talos
status: evergreen
aliases:
  - "Hardware Inventory"
---

# Homelab Hardware Inventory & Cluster Roles

This document tracks the physical hardware available in the homelab and their intended roles in the Talos Linux cluster ecosystem.

## Overview

- **Cluster Management**: [Sidero Omni](https://www.siderolabs.com/platform/sidero-omni/) running on a dedicated Mini PC.
- **Kubernetes Cluster**: 5-Node Talos Linux Cluster combining enterprise server hardware and consumer desktop hardware.

---

## Hardware Breakdown

### 1. Management Infrastructure (Sidero Omni)

| Hostname / Node | Hardware Type | Specs (CPU / RAM / Storage) | Network / MAC | Role |
| :--- | :--- | :--- | :--- | :--- |
| `omni-server` | Dell OptiPlex Micro (D08U) | 500GB Samsung 860 EVO SSD | 1GbE Onboard RJ45 | Sidero Omni Management Server |

### 2. Cluster Nodes (Talos Linux 5-Node Cluster)

| Hostname / Node | Machine Type | Specs (CPU / RAM / Storage) | Network Interfaces & Discovered MACs | Boot / OS Drive | Intended Talos Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sm-node-01`<br>(`edge01`) | Supermicro SYS-E300-9D-4CN8TP | Xeon D-2123IT (4C/8T) / 32GB RAM / 1x 2TB Sabrent NVMe + 2x 2TB MX500 SSD (chassis full: no spare power header or usable SATA port) | **IPMI**: `3c:ec:ef:xx:xx:xx` (USW-24-G2 P11)<br>**10G SFP+ #1**: `3c:ec:ef:xx:xx:xx` (USW-Agg P2)<br>**10G SFP+ #2**: `3c:ec:ef:xx:xx:xx` (USW-Agg P1) | 16GB SATA SuperDOM | Control Plane 1 + Worker |
| `sm-node-02`<br>(`edge02`) | Supermicro SYS-E300-9D-4CN8TP | Xeon D-2123IT (4C/8T) / 32GB RAM / 1x 2TB Sabrent NVMe + 2x 2TB MX500 SSD (chassis full; spare SATA port suspect after the 2026-10-17 osd.5 fault) | **IPMI**: `3c:ec:ef:xx:xx:xx` (USW-24-G2 P15)<br>**10G SFP+ #1**: `3c:ec:ef:xx:xx:xx` (USW-Agg P4)<br>**10G SFP+ #2**: `3c:ec:ef:xx:xx:xx` (USW-Agg P3) | 16GB SATA SuperDOM | Control Plane 2 + Worker |
| `sm-node-03`<br>(`main01`) | Supermicro 813M-3 Chassis | Xeon E5-2680 v4 (14C/28T) / 160GB RAM / 1x 2TB MX500 SSD (Ceph) in 3.5" hot-swap bays (2.5" adapters). Staged for Wave 4 (inserted, not yet in Ceph): 2x 4TB IronWolf + 250GB MX500 (future `/var`). Three other MX500s moved to `pc-node-04` on 2026-10-18 | **IPMI**: `3c:ec:ef:xx:xx:xx` (USW-24-G2 P1)<br>**10G SFP+ #1**: `a0:36:9f:xx:xx:xx`<br>**10G SFP+ #2**: `a0:36:9f:xx:xx:xx` | Dual 16GB SATA SuperDOMs | Primary Control Plane + Heavy Worker |
| `pc-node-04`<br>(`stor01`) | AMD Ryzen 7 3800X PC | Ryzen 7 3800X (8C/16T) / 64GB RAM / 1TB Crucial P3 Plus NVMe + 3× 2TB MX500 SSD (from sm-node-03, 2026-10-18) + 7TB HDD (3TB, 2TB, 2× 1TB) + 2× 180GB Intel 335 spares (unused). The 4× IronWolf moved to sm-node-03/pc-node-05 and the failing WD Green 1.5TB was retired | **1GbE Onboard**: `2c:f0:5d:xx:xx:xx`<br>**Dual 10G SFP+**: `a0:36:9f:xx:xx:xx` / `.xx` | 80GB Intel 320 SSD (OS) | Storage & Compute Worker |
| `pc-node-05` | Mini-ITX PC (B650I EDGE) | Ryzen 5 7600 (6C/12T) / 32GB RAM / 2x 1TB NVMe + 2x 4TB IronWolf HDD (re-cased 2026-10-18) / NVIDIA RTX 4070 | **2.5GbE SFP+ Uplink**: Ceph-USW-Agg Port 3/4 | 240GB Kingston SQ500S3 SATA SSD (boot); 1TB Sabrent Rocket = gaming VM disk; Crucial P3 1TB Ceph OSD; 2× IronWolf 4TB Ceph HDD | GPU Worker (AI/ML & Transcoding) |

### 3. Networking & Wireless Infrastructure (UniFi Stack)

| Device | Model / Type | Uplink / Connections | Role & Location |
| :--- | :--- | :--- | :--- |
| **Router / Gateway** | UniFi Dream Machine Pro (UDM-Pro) | 3.5 Gbps Google Fiber WAN via SFP+ | Core L3 Gateway, DHCP, Firewall & UniFi Controller |
| **Aggregation Switch 1** | UniFi USW-Aggregation | 10G SFP+ Links (20G LAG to Agg 2) | Core 10G SFP+ Switch Backbone |
| **Aggregation Switch 2** | UniFi USW-Aggregation | 10G SFP+ Links (20G LAG to Agg 1) | Core 10G SFP+ Storage & Node Backbone |
| **Access Switch (Core)** | UniFi USW-24-G2 | 1GbE RJ45 Ports | Core 1GbE Node & Management Network Switch |
| **Access Switch (Garage)** | UniFi USW-Lite-8-PoE | 1GbE RJ45 + 802.3at PoE | Garage Network Switch & AP Power |
| **Home Wireless AP** | UniFi U7 Pro WAP | Connected to UDM-Pro / USW Switch | Primary Home Wi-Fi 7 Access Point |
| **Garage Wireless AP** | UniFi U6-Lite WAP | PoE Powered via USW-Lite-8-PoE | Garage Wi-Fi 6 Access Point |

### 4. Dedicated Storage & Disaster Recovery Appliances (Out-of-Cluster)

| Device | Hardware Type | Specs (Storage & RAID) | Network / Uplink | Physical Location | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `synology-nas`<br>*(Active)* | Synology DS713+ (2-Bay) | 2x 2TB HDDs (SHR / RAID 1, 2.0TB Usable) | 1GbE RJ45 to USW-Lite-8-PoE Port 2 (`10.0.1.223`) | Garage Workshop | Tier 3 local backup target (independent NAS CronJobs for cluster state, Postgres and Actual Budget), Apple Time Machine Server (`nix-mac`), Out-of-Band DR |

### 5. Power & Resiliency Infrastructure (Dual UPS Battery Backup)

| Device | Class / Form Factor | Connected Equipment & Roles | Monitoring Architecture |
| :--- | :--- | :--- | :--- |
| **Primary Rack UPS (`ups-rack`)** | Pure Sine Wave Line-Interactive (1500VA / 900W) | Core Gateway (UDM-Pro), Core Aggregation Switches, USW-24-G2, Supermicro Control Plane Nodes (`sm-node-01`, `sm-node-02`, `sm-node-03`), Omni Controller | Network UPS Tools (NUT) via USB / Network (`upsd` Port 3493) |
| **Auxiliary Storage UPS (`ups-storage`)** | Pure Sine Wave Line-Interactive (1500VA / 900W) | Storage Worker `pc-node-04` (4 HDDs + 3 SSDs), GPU Worker `pc-node-05` (RTX 4070), Rack Fans & Auxiliary Equipment | Network UPS Tools (NUT) via USB / Network (`upsd` Port 3493) |

*Full telemetry, Kubernetes Prometheus exporter, and alerting rules detailed in [[109-ups-power-monitoring-nut|109: UPS Power Resiliency & NUT Monitoring]].*

---

## Key Architecture & Design Considerations

1. **Control Plane & Worker Scheduling Strategy**: 
   - **3-Node HA Control Plane + Workers**: The 3 Supermicro servers (`sm-node-01`, `sm-node-02`, `sm-node-03`) form the 3-node High-Availability Control Plane (running `etcd` and Kubernetes control plane services).
   - **`allowSchedulingOnControlPlanes: true`**: In Talos Linux, we enable workload scheduling on control plane nodes. This allows **all 5 nodes to act as worker nodes** (the sm nodes currently carry a soft `PreferNoSchedule` taint until their `/var` moves off the SuperDOMs; see [[110-ephemeral-var-migration|/var migration]]) and run container workloads/pods, utilizing 100% of your 320 GB RAM and 72 vCPU threads!
2. **Omni Provisioning**:
   - Omni manages bare-metal Talos nodes via PXE / boot media / API.
3. **Storage & Networking**:
   - **Boot Drives**: Dedicated **16GB SATA SuperDOMs** (single SuperDOMs on `sm-node-01`/`02`, mirrored dual SuperDOMs on `sm-node-03`) provide resilient boot drives for Supermicro nodes. `pc-node-04` boots off a dedicated **80GB Intel 320 Enterprise SATA SSD**, and `pc-node-05` boots off a **240GB Kingston SQ500S3 SATA SSD** (since 2026-10-18; selected by WWID in `talos/machine-install-disks.yaml`). Its **1TB Sabrent Rocket NVMe** is the gaming VM's local disk and its **1TB Crucial P3 NVMe** is a raw Rook-Ceph OSD. The two NVMe names (`nvme0n1`/`nvme1n1`) swap between boots, so everything selects them by serial.
   - **Tier 1 Storage (High IOPS NVMe Pool)**: **2x 2TB NVMe SSDs** (`sm-node-01`/`02`) + **1x 1TB NVMe SSD** (`pc-node-04`) + **1x 1TB NVMe SSD** (`pc-node-05`) = **6.0TB raw NVMe storage**. Ideal for high-performance database volumes and low-latency PVCs. Waves 6–7 of the reshuffle will carve 250 GiB off each sm-node Sabrent for Talos `/var` (etcd included).
   - **Tier 2 Storage (SATA SSD Pool, default StorageClass)**: **8x 2TB Crucial MX500 SSDs** = **16TB raw**, spread over **four hosts** since 2026-10-18: `sm-node-01` ×2, `sm-node-02` ×2, `sm-node-03` ×1, `pc-node-04` ×3. With size-3 replication on four hosts, Ceph can rebuild the third copy when one host is down.
   - **Tier 3 Storage (Bulk HDD Pool, scratch/overflow)**: **6 HDDs = 15TB raw** across two hosts today: `pc-node-04` (3TB BarraCuda, 2TB Constellation ES.3, 2× 1TB Barracuda) and `pc-node-05` (2× 4TB IronWolf). Wave 4 adds 2× 4TB IronWolf in `sm-node-03`, and Wave 5 rebuilds the pool as erasure-coded 2+1 across those three hosts. See [[110-ephemeral-var-migration|/var migration & storage reshuffle]].
   - **Out-of-Band Isolated Backup Storage (Garage Appliance — Active)**: The 2-Bay Synology DS713+ NAS (2x 2TB HDDs in SHR / RAID 1 = 2.0TB usable) operates independently from the main rack in the garage on `USW-Lite-8-PoE` (Port 2 at `10.0.1.223`), providing a physically segregated failure domain for macOS Time Machine (`nix-mac`), the local copy of every encrypted cluster backup, and offline cluster recovery. Detailed in [[307-garage-synology-dr-time-machine|Garage Synology NAS Onboarding]].
   - **High-Speed Networking (10GbE SFP+)**: 4 out of 5 nodes (`sm-node-01`, `sm-node-02`, `sm-node-03`, `pc-node-04`) have **Dual 10GbE SFP+ NICs** (Intel 82599/X520-DA2 chipset & Xeon D integrated). This enables a dedicated 10G SFP+ network VLAN for Rook-Ceph storage replication traffic.
