---
title: "Enterprise Hybrid Homelab (Talos Linux + UniFi + AWS Cloud)"
date: 2026-09-07
tags:
  - talos
  - kubernetes
  - unifi
  - ceph
  - aws
  - terraform
  - homelab
  - hub
status: evergreen
aliases:
  - "Homelab Hub"
  - "Talos Cluster"
---

# 🚀 Enterprise Hybrid Homelab (Talos Linux + UniFi + AWS Cloud)

A production-grade, declarative hybrid Kubernetes infrastructure powered by **Talos Linux**, **Sidero Omni**, **Ubiquiti UniFi**, **Rook-Ceph**, **KubeVirt**, **Authentik**, and **AWS Cloud**.

---

## 📊 Infrastructure Resource Overview

| Resource Layer | Physical Hardware & Capacity Breakdown |
| :--- | :--- |
| **Physical Nodes** | **6 Nodes**: `omni-server` (Dell OptiPlex), `sm-node-01/02` (Supermicro Xeon D), `sm-node-03` (Supermicro 1U Xeon E5), `pc-node-04` (Ryzen 3800X 27TB Storage PC), `pc-node-05` (Ryzen 7600 RTX 4070 GPU PC). |
| **Total Compute** | **36 Physical Cores / 72 vCPU Threads** (`allowSchedulingOnControlPlanes: true` across all 5 cluster nodes). |
| **Total Memory** | **320 GB DDR4 RAM**. |
| **Total Storage** | **47.5 TB Raw Storage**: **5TB High-IOPS NVMe Pool** + **16TB Replicated SATA SSD Pool** + **27.0TB Bulk Mechanical HDD Array** (11 HDDs). |
| **Network Fabric** | **3.5 Gbps Google Fiber WAN**, **20 Gbps LAG SFP+ Switch Backbone**, **Dual 10G SFP+ Server Uplinks**, **2.5G Multi-Gig Node Uplink**, MTU 9000 Jumbo Frames, Dual-Stack IPv4/IPv6, UniFi U7 Pro (Wi-Fi 7) & U6-Lite (Wi-Fi 6). |

---

## 📚 Categorized Documentation Index

### 🏗 Section 1: Hardware Architecture & Deployment Phases
- [101 - Hardware Inventory & Resource Breakdown](docs/101-hardware-inventory.md)
- [102 - Architecture Blueprint & Technology Stack](docs/102-architecture-design.md)
- [103 - Phase 1: Sidero Omni & Talos Bootstrap Guide](docs/103-phase1-omni-talos-bootstrap.md)
- [104 - Phase 2: Rook-Ceph 3-Tier Storage Cluster](docs/104-phase2-rook-ceph-storage.md)
- [105 - Global Resource Naming Conventions](docs/105-naming-conventions.md)

### 🌐 Section 2: UniFi Networking & Infrastructure
- [201 - UniFi Physical Cabling & Logical Topology Diagrams](docs/201-unifi-network-topology.md)
- [202 - Cloudflare Tunnel & Zero Trust Remote Access](docs/202-cloudflare-tunnel-zero-trust.md)
- [203 - Tailscale Kubernetes Operator & Mesh VPN](docs/203-tailscale-mesh-vpn.md)
- [204 - UDM-Pro Network & VLAN Setup Guide (Step-by-Step)](docs/204-udm-pro-network-creation-guide.md)

### ⚙️ Section 3: Talos Linux & Cluster Administration
- [301 - Network PXE Boot & Node Provisioning Instruction Manual](docs/301-pxe-boot-node-provisioning.md)
- [302 - GitHub Actions ARC Self-Hosted CI/CD](docs/302-github-actions-runner-controller.md)
- [303 - KubeVirt Windows 11 Gaming VM (RTX 4070 Passthrough)](docs/303-kubevirt-windows-gpu-vm.md)
- [304 - Automated Windows VM Setup with Ansible & Chocolatey](docs/304-windows-ansible-automation.md)
- [305 - KubeVirt `omarchy-vm` Arch Linux VM](docs/305-kubevirt-arch-linux-vm.md)
- [306 - Hybrid Local/Remote AI Development Architecture (MLX + K8s)](docs/306-hybrid-local-remote-ai-dev.md)


### ☁️ Section 4: AWS Hybrid Integration & Cloud Security
- [401 - AWS Controllers for Kubernetes (ACK) Architecture](docs/401-aws-ack-hybrid-architecture.md)
- [402 - AWS EKS Connector & Unified AWS Console Management](docs/402-aws-eks-connector.md)
- [403 - Authentik Master IdP & AWS SAML 2.0 Identity Federation](docs/403-identity-sso-authentik-aws.md)
- [404 - AWS Multi-Account Landing Zone (Organizations, IAM Identity Center & Terraform)](docs/404-aws-landing-zone-organizations-terraform.md)
- [405 - AWS Account Factory for Terraform (AFT) vs GitHub Actions GitOps](docs/405-aws-account-factory-terraform.md)
- [406 - Floci: In-Cluster Local AWS Cloud Emulator for Terraform & CI/CD](docs/406-floci-local-aws-emulator.md)

### 📦 Section 5: Self-Hosted Application Suite
- [501 - TeslaMate Vehicle Telemetry & Analytics Platform](docs/501-teslamate-telemetry-deployment.md)
- [502 - Actual Budget Self-Hosted Personal Finance Platform](docs/502-personal-finance-apps.md)
- [503 - Mealie Recipe Manager & Meal Planner](docs/503-mealie-recipe-planner.md)
- [504 - Immich Self-Hosted Photo & Video Backup Platform](docs/504-immich-photo-backup.md)
- [505 - Home Assistant Smart Home & IoT Automation Platform](docs/505-home-assistant-smart-home.md)

---

## 📁 Repository Codebase Structure

```
├── Justfile                   # Central command runner for Talos, K8s, Terraform & MLX
├── .github/workflows/         # Actions Runner Controller (ARC) CI/CD pipelines
│   ├── provision-aws-account.yml # Automated AWS account provisioning GitOps
│   ├── terraform-ci.yml       # Multi-directory Terraform lint/validate CI
│   └── k8s-validate.yml       # YAML and Kubernetes manifest validation
├── ansible/                   # Ansible configuration management for VMs
│   ├── ansible.cfg            # WinRM & connection defaults
│   ├── inventory/             # Windows 11 Gaming VM hosts
│   ├── playbooks/             # Automated Chocolatey & Sunshine setup
│   └── files/                 # Unattend.xml sysprep bootstrap answer file
├── client-tools/              # Workstation client configuration & bootstrap scripts
│   └── ai-dev/                # Apple MLX / oMLX & Continue.dev local setup
├── docker/                    # Custom container images
│   └── dev-agent/             # Remote Antigravity dev container & toolchains
├── docs/                      # Comprehensive homelab architecture documentation
├── kubernetes/                # Declarative Kubernetes manifests
│   ├── infrastructure/        # Core platform services
│   │   ├── rook-ceph/         # 3-tier Ceph cluster & StorageClasses
│   │   ├── cloudflare/        # Cloudflare Tunnel HA deployment
│   │   ├── tailscale/         # Tailscale operator & subnet router
│   │   ├── kubevirt/          # Windows 11 (GPU passthrough) & Arch VMs
│   │   ├── arc/               # Actions Runner Controller AutoscalingRunnerSet
│   │   ├── floci/             # In-cluster local AWS cloud emulator
│   │   ├── authentik/         # Authentik master IdP & PostgreSQL/Redis
│   │   ├── aws-hybrid/        # AWS ACK (S3, Route53) & EKS Connector
│   │   └── dev-workspace/     # Antigravity persistent remote dev pod & NVMe PVC
│   └── apps/                  # Containerized self-hosted application suite
│       ├── teslamate/         # Tesla telemetry, MQTT, PostgreSQL, Grafana
│       ├── finance/           # Actual Budget personal finance
│       ├── mealie/            # Mealie recipe manager
│       ├── immich/            # Immich photo backup (pgvector + ML)
│       └── home-assistant/    # Home Assistant smart home automation
├── talos/                     # Talos Linux machine configurations & patches
│   ├── talosconfig.example    # talosctl client configuration template
│   └── patches/               # Node-specific configuration patches
│       ├── controlplane.yaml  # Supermicro HA control plane (allowSchedulingOnControlPlanes)
│       ├── storage-worker.yaml# pc-node-04 11-disk bulk HDD storage worker
│       └── gpu-worker.yaml    # pc-node-05 AM5 Ryzen 7600 + RTX 4070 VFIO passthrough
└── terraform/                 # Infrastructure as Code
    ├── aws/                   # Route53, encrypted S3 backups, EKS Connector role
    ├── aws_organization/      # Multi-account Landing Zone, Control Tower, SSO
    ├── cloudflare/            # Zero Trust Tunnels, DNS, Access SSO, Email Routing
    ├── unifi/                 # UDM-Pro VLANs (10,20,30,40,50,60,90), firewalls, profiles
    └── backend-config.example.tf # Remote state configuration reference
```