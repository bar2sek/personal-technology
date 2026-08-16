# Architecture & Technology Stack Overview

This document outlines the architectural blueprint, storage engine, networking topology, and AWS hybrid cloud integration strategy for the Talos Linux homelab cluster.

---

## 🏗 Core Technology Stack

| Layer | Component | Description & Rationale |
| :--- | :--- | :--- |
| **Operating System** | [Talos Linux](https://www.talos.dev/) | Immutable, minimal, security-focused Linux distribution built specifically for Kubernetes. Managed declaratively. |
| **Bare-Metal Mgmt** | [Sidero Omni](https://www.siderolabs.com/platform/sidero-omni/) | Dedicated on-premise Mini PC running Omni for zero-touch provisioning, PXE boot, machine configs, and Talos upgrades. |
| **Container Storage** | [Rook-Ceph](https://rook.io/) | Cloud-native storage orchestrator providing block (`RBD`), shared file system (`CephFS`), and object storage across the 8x 2TB SATA SSDs + NVMe tiers. |
| **Network Stack** | Ubiquiti UniFi | Managed L2/L3 networking, VLAN separation, DNS, and BGP/L2 integration for Kubernetes LoadBalancers (MetalLB or Cilium BGP). |
| **GPU Workloads** | [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html) | Native NVIDIA container runtime integration on Talos for RTX 4070 (Ollama AI models, CUDA, PyTorch, NVENC media encoding). |
| **Network Automation** | [UniFi Terraform Provider](https://registry.terraform.io/providers/paultag/unifi/latest/docs) | Declaratively manage UniFi networks, VLANs, switch port profiles, static DHCP leases, and firewall rules in Terraform code. |
| **AWS Integration** | [AWS Controllers for K8s (ACK)](https://aws-controllers-k8s.github.io/community/) | Provision and manage native AWS resources (S3, Route53, RDS, IAM) directly using `kubectl` / GitOps manifests on-prem. |
| **AWS Observability** | [AWS EKS Connector](https://docs.aws.amazon.com/eks/latest/userguide/eks-connector.html) | Registers the on-prem Talos cluster into the AWS Management Console for unified observability, health monitoring, and governance. |

---

## 💾 Storage Architecture (Rook-Ceph)

```
                       +-----------------------------------+
                       |         Kubernetes Cluster        |
                       +-----------------------------------+
                                         |
                       +-----------------------------------+
                       |         Rook Storage Operator     |
                       +-----------------------------------+
                        /                 |                 \
     +-----------------------+ +-----------------------+ +-----------------------+
     | OSDs (Node 01)        | | OSDs (Node 02)        | | OSDs (Node 03)        |
     | - 2x 2TB MX500 SSDs   | | - 2x 2TB MX500 SSDs   | | - 4x 2TB MX500 SSDs   |
     | - 1x 2TB NVMe (WAL/DB)| | - 1x 2TB NVMe (WAL/DB)| | (SATA Capacity Pool)|
     +-----------------------+ +-----------------------+ +-----------------------+
```

### Storage Device Assignment (3-Tier Rook-Ceph Architecture):

1. **Tier 1 (NVMe High-IOPS Pool - 5TB)**:
   - **Devices**: 2x 2TB NVMe (`sm-node-01`/`02`) + 1x 1TB NVMe (`pc-node-05`).
   - **Role**: `etcd` WAL, high-speed database PVCs (PostgreSQL/Redis), Ceph RocksDB/WAL metadata acceleration, and Ollama AI model caching.
2. **Tier 2 (SATA SSD Replicated Pool - 16TB)**:
   - **Devices**: 8x 2TB Crucial MX500 SATA SSDs (`sm-node-01`, `02`, `03`).
   - **Role**: Replicated Ceph Block (`RBD`) & File (`CephFS`) storage for active application state and PVCs across 10G SFP+.
3. **Tier 3 (Bulk HDD Storage Pool - 27.0TB)**:
   - **Devices**: 11x Mechanical HDDs in `pc-node-04` (**4x 4TB Seagate IronWolf NAS** + **2x 2TB Seagate Constellation ES.3 Enterprise** + 1x 3TB Seagate BarraCuda + 1x 1.5TB WD Green + 2x 1TB Seagate Barracuda + 1x 500GB HGST).
   - **Role**: Bulk erasure-coded storage, MinIO S3 object store, Velero cluster backups, and media library archives. (Boots off dedicated 250GB Crucial MX500 SSD).

---

## ☁️ AWS Hybrid Integration

```
  +-------------------------------------+         +-------------------------------------+
  |          On-Premise Homelab         |         |              AWS Cloud              |
  |                                     |         |                                     |
  |  +-------------------------------+  |  ACK    |  +-------------------------------+  |
  |  |  AWS Controllers for K8s      |--|-------->|  |  AWS Services (S3, Route53,   |  |
  |  |  (ACK CRDs in Cluster)        |  |  gRPC/  |  |  RDS, IAM, CloudWatch)        |  |
  |  +-------------------------------+  |  HTTPS  |  +-------------------------------+  |
  |                                     |         |                                     |
  |  +-------------------------------+  | EKS     |  +-------------------------------+  |
  |  |  AWS EKS Connector Agent      |--|-------->|  |  AWS EKS Console              |  |
  |  |  (Cluster Observability)      |  |         |  |  (Unified Dashboard & Metrics)|  |
  |  +-------------------------------+  |         |  +-------------------------------+  |
  +-------------------------------------+         +-------------------------------------+
```

1. **AWS Controllers for K8s (ACK)**:
   - Declaratively create S3 buckets (e.g. for cluster backups, Velero, or Rook-Ceph external backups).
   - Manage Route53 DNS records automatically via ExternalDNS & ACK.
2. **AWS EKS Connector**:
   - Gives single-pane-of-glass visibility inside the AWS EKS Console for our physical Talos Linux cluster.
   - Simplifies IAM authentication and centralized security monitoring.

---

## 📌 Next Topics to Document
1. UniFi Network Topology (VLANs, Subnets, Gateway model, 10GbE Switch links).
2. Gaming PC Specs & GPU Passthrough (NVIDIA / AMD container runtime setup).
3. Sidero Omni installation & network boot setup.
