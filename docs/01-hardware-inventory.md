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
| `omni-server` | Dell OptiPlex Micro (D08U) | 500GB Samsung 860 EVO SSD | 1GbE Onboard + 1GbE USB Adapter | Sidero Omni Management Server |

### 2. Cluster Nodes (Talos Linux 5-Node Cluster)

| Hostname / Node | Machine Type | Specs (CPU / RAM / Storage) | Boot / OS Drive | Intended Talos Role |
| :--- | :--- | :--- | :--- | :--- |
| `sm-node-01` | Supermicro SYS-E300-9D-4CN8TP | Xeon D-2123IT (4C/8T) / 32GB RAM / 1x 2TB Sabrent NVMe + 2x 2TB MX500 SSD | Integrated Dual 10G SFP+ | 16GB SATA SuperDOM | Control Plane 1 + Worker |
| `sm-node-02` | Supermicro SYS-E300-9D-4CN8TP | Xeon D-2123IT (4C/8T) / 32GB RAM / 1x 2TB Sabrent NVMe + 2x 2TB MX500 SSD | Integrated Dual 10G SFP+ | 16GB SATA SuperDOM | Control Plane 2 + Worker |
| `sm-node-03` | Supermicro 813M-3 Chassis | Xeon E5-2680 v4 (14C/28T) / 160GB RAM / 4x 2TB MX500 SSD | Intel Dual 10G SFP+ Card | Dual 16GB SATA SuperDOMs | Primary Control Plane + Heavy Worker |
| `pc-node-04` | AMD Ryzen 7 3800X PC | Ryzen 7 3800X (8C/16T) / 64GB RAM / 27.0TB HDD Array (11 HDDs) + 490GB SATA SSDs | Intel Dual 10G SFP+ + Dual 1GbE NIC + Onboard 1GbE (5 Ports) | 80GB Intel 320 SSD (OS) | Storage & Compute Worker |
| `pc-node-05` | Mini-ITX PC (B650I EDGE) | Ryzen 5 7600 (6C/12T) / 32GB RAM / 2x 1TB NVMe SSD / NVIDIA RTX 4070 | 2.5GbE SFP+ + 1GbE USB Adapter | 2GB NVMe Partition (1.998TB Data) | GPU Worker (AI/ML & Transcoding) |

---

## Key Architecture & Design Considerations

1. **Control Plane Strategy**: 
   - Option A: 3-Node Control Plane (using the 3 Supermicro servers for high availability) + 2 Worker Nodes (Gaming PCs).
   - Option B: Single Control Plane + 4 Workers (less recommended for HA).
2. **Omni Provisioning**:
   - Omni manages bare-metal Talos nodes via PXE / boot media / API.
3. **Storage & Networking**:
   - **Boot Drives**: Dedicated **16GB SATA SuperDOMs** (single SuperDOMs on `sm-node-01`/`02`, mirrored dual SuperDOMs on `sm-node-03`) provide resilient boot drives for Supermicro nodes. `pc-node-04` boots off a dedicated **80GB Intel 320 Enterprise SATA SSD**, and `pc-node-05` uses a tiny **2GB partition** on its first 1TB NVMe drive (leaving **1.998 TB NVMe** completely free for Rook-Ceph & AI model caching).
   - **Tier 1 Storage (High IOPS NVMe Pool)**: **2x 2TB NVMe SSDs** (`sm-node-01`/`02`) + **2x 1TB NVMe SSDs** (`pc-node-05`) = **6TB raw NVMe storage**. Ideal for etcd WAL directories, high-performance database volumes, and fast caching for Ollama AI models.
   - **Tier 2 Storage (SATA SSD Capacity Pool)**: All **8x 2TB Crucial MX500 SSDs** (16TB raw capacity across the 3 Supermicro servers) remain 100% available for distributed storage engines like **Rook-Ceph**, **Longhorn**, or **OpenEBS Mayastor**. Extra SATA SSDs in `pc-node-04` (250GB Crucial + 240GB Kingston) available for scratch cache.
   - **Tier 3 Storage (Bulk HDD Storage Pool)**: **11x Mechanical HDDs** in `pc-node-04` (**4x 4TB Seagate IronWolf NAS** + **2x 2TB Seagate Constellation ES.3 Enterprise** + 1x 3TB Seagate BarraCuda + 1x 1.5TB WD Green + 2x 1TB Seagate Barracuda + 1x 500GB HGST = **27.0TB raw HDD capacity**). Ideal for Rook-Ceph bulk erasure-coded storage pools, MinIO S3 object store, Velero cluster backups, and media archives.
   - **High-Speed Networking (10GbE SFP+)**: 4 out of 5 nodes (`sm-node-01`, `sm-node-02`, `sm-node-03`, `pc-node-04`) have **Dual 10GbE SFP+ NICs** (Intel 82599/X520-DA2 chipset & Xeon D integrated). This enables a dedicated 10G SFP+ network VLAN for Rook-Ceph storage replication traffic.
