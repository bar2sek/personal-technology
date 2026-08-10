# 🚀 Enterprise Hybrid Homelab (Talos Linux + UniFi + AWS Cloud)

A production-grade, declarative hybrid Kubernetes infrastructure powered by **Talos Linux**, **Sidero Omni**, **Ubiquiti UniFi**, **Rook-Ceph**, **KubeVirt**, **Authentik**, and **AWS Cloud**.

---

## 📊 Infrastructure Resource Overview

| Resource Layer | Physical Hardware & Capacity Breakdown |
| :--- | :--- |
| **Physical Nodes** | **6 Nodes**: `omni-server` (Dell OptiPlex), `sm-node-01/02` (Supermicro Xeon D), `sm-node-03` (Supermicro 1U Xeon E5), `pc-node-04` (Ryzen 3800X 27TB Storage PC), `pc-node-05` (Ryzen 7600 RTX 4070 GPU PC). |
| **Total Compute** | **36 Physical Cores / 72 vCPU Threads** (`allowSchedulingOnControlPlanes: true` across all 5 cluster nodes). |
| **Total Memory** | **320 GB DDR4 RAM**. |
| **Total Storage** | **48.5 TB Raw Storage**: **6TB High-IOPS NVMe Pool** + **16TB Replicated SATA SSD Pool** + **27.0TB Bulk Mechanical HDD Array** (11 HDDs). |
| **Network Fabric** | **3.5 Gbps Google Fiber WAN**, **20 Gbps LAG SFP+ Switch Backbone**, **Dual 10G SFP+ Server Uplinks**, **2.5G Multi-Gig Node Uplink**, MTU 9000 Jumbo Frames, Dual-Stack IPv4/IPv6, UniFi U7 Pro (Wi-Fi 7) & U6-Lite (Wi-Fi 6). |

---

## 📚 Documentation Index

- [01 - Hardware Inventory](docs/01-hardware-inventory.md)
- [02 - Architecture & Technology Stack](docs/02-architecture-design.md)
- [03 - UniFi Network Topology & Mermaid Diagrams](docs/03-unifi-network-topology.md)
- [04 - Phase 1: Sidero Omni & Talos Bootstrap Guide](docs/04-phase1-omni-talos-bootstrap.md)
- [05 - KubeVirt Windows Gaming VM (RTX 4070 GPU Passthrough)](docs/05-kubevirt-windows-gpu-vm.md)
- [06 - TeslaMate Vehicle Telemetry & Analytics Platform](docs/06-teslamate-telemetry-deployment.md)
- [07 - Self-Hosted Personal Finance & Budgeting Apps](docs/07-personal-finance-apps.md)
- [08 - Mealie Recipe Manager & Meal Planner](docs/08-mealie-recipe-planner.md)
- [09 - GitHub Actions CI/CD & Actions Runner Controller (ARC)](docs/09-github-actions-runner-controller.md)
- [10 - Cloudflare Tunnel & Zero Trust Remote Access Architecture](docs/10-cloudflare-tunnel-zero-trust.md)
- [11 - Tailscale Kubernetes Operator & Private Mesh Network](docs/11-tailscale-mesh-vpn.md)
- [12 - Immich Self-Hosted Photo & Video Backup Platform](docs/12-immich-photo-backup.md)
- [13 - Home Assistant Smart Home & IoT Automation Platform](docs/13-home-assistant-smart-home.md)
- [14 - Single Sign-On (SSO) & AWS SAML 2.0 Identity Federation](docs/14-identity-sso-authentik-aws.md)
- [15 - Automated Windows Gaming VM Provisioning with Ansible & Chocolatey](docs/15-windows-ansible-automation.md)
- [16 - KubeVirt Arch / Omarchy Linux Virtual Machine](docs/16-kubevirt-arch-linux-vm.md)
- [17 - Network PXE Boot & Node Provisioning Instruction Manual](docs/17-pxe-boot-node-provisioning.md)
- [18 - AWS Controllers for Kubernetes (ACK) Hybrid Architecture](docs/18-aws-ack-hybrid-architecture.md)
- [19 - Phase 2: Rook-Ceph 3-Tier Distributed Storage Cluster](docs/19-phase2-rook-ceph-storage.md)