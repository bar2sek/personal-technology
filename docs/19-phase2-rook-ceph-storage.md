# Phase 2: Rook-Ceph 3-Tier Distributed Storage Cluster

This guide outlines the deployment architecture and Kubernetes manifests for **[Rook-Ceph](https://rook.io/)** — our cloud-native storage orchestrator providing block (`RBD`), shared file system (`CephFS`), and object storage across 3 distinct hardware performance tiers.

---

## 💾 3-Tier Storage Pool Topology

| Storage Tier | Physical Drive Pool | Total Raw Capacity | Intended Cluster Workloads |
| :--- | :--- | :--- | :--- |
| **Tier 1 (High-IOPS NVMe)** | 2x 2TB NVMe (`sm-node-01/02`) + 2x 1TB NVMe (`pc-node-05`) | **6.0 TB** | `etcd` WAL, PostgreSQL/Redis databases, Ceph RocksDB/WAL metadata, Ollama AI model weights. |
| **Tier 2 (SATA SSD Replicated)** | 8x 2TB Crucial MX500 SATA SSDs (`sm-node-01`, `02`, `03`) | **16.0 TB** | Replicated Block (`RBD`) & File (`CephFS`) PVCs for active apps (TeslaMate, Actual Budget, Mealie, Immich). |
| **Tier 3 (Bulk HDD Erasure-Coded)** | 11x Mechanical HDDs in `pc-node-04` (4x 4TB NAS + 2x 2TB Enterprise + 3TB + 1.5TB + 2x 1TB + 500GB) | **27.0 TB** | Erasure-coded bulk object storage, MinIO S3 target, Velero cluster backups, media archives. |

---

## 🛠 Storage Network Isolation (VLAN 40)

To prevent Ceph storage replication traffic from competing with Kubernetes API or application pod traffic, all Rook-Ceph OSD East-West traffic is routed over **VLAN 40 (`CEPH-STORAGE`)** using **10GbE SFP+ interfaces with MTU 9000 (Jumbo Frames)**.

---

## 📦 Rook-Ceph Cluster Manifest (`kubernetes/rook-ceph/cluster.yaml`)

```yaml
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  cephVersion:
    image: quay.io/ceph/ceph:v18.2.1
  dataDirHostPath: /var/lib/rook
  mon:
    count: 3
    allowMultiplePerNode: false
  network:
    provider: host
    ipFamily: IPv4
  storage:
    useAllNodes: false
    useAllDevices: false
    nodes:
      # Tier 1 & Tier 2 OSDs on Supermicro Node 01
      - name: sm-node-01
        devices:
          - name: "nvme0n1" # Tier 1 NVMe
          - name: "sda"     # Tier 2 SATA SSD
          - name: "sdb"     # Tier 2 SATA SSD
      # Tier 1 & Tier 2 OSDs on Supermicro Node 02
      - name: sm-node-02
        devices:
          - name: "nvme0n1" # Tier 1 NVMe
          - name: "sda"     # Tier 2 SATA SSD
          - name: "sdb"     # Tier 2 SATA SSD
      # Tier 2 OSDs on Supermicro Node 03
      - name: sm-node-03
        devices:
          - name: "sda"     # Tier 2 SATA SSD
          - name: "sdb"     # Tier 2 SATA SSD
          - name: "sdc"     # Tier 2 SATA SSD
          - name: "sdd"     # Tier 2 SATA SSD
      # Tier 3 OSDs on Storage PC Node 04
      - name: pc-node-04
        devices:
          - name: "sdb"     # 4TB Seagate IronWolf
          - name: "sdc"     # 4TB Seagate IronWolf
          - name: "sdd"     # 4TB Seagate IronWolf
          - name: "sde"     # 4TB Seagate IronWolf
          - name: "sdf"     # 2TB Seagate Enterprise
          - name: "sdg"     # 2TB Seagate Enterprise
          - name: "sdh"     # 3TB Seagate BarraCuda
          - name: "sdi"     # 1.5TB WD Green
          - name: "sdj"     # 1TB Seagate Barracuda
          - name: "sdk"     # 1TB Seagate Barracuda
          - name: "sdl"     # 500GB HGST HDD
      # Tier 1 OSDs on GPU Worker Node 05
      - name: pc-node-05
        devices:
          - name: "nvme0n1p2" # 998GB Unpartitioned NVMe 1
          - name: "nvme1n1"   # 1TB NVMe 2
```
