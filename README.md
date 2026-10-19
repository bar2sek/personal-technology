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
| **Physical Nodes** | **6 Nodes**: `omni-server` (Dell OptiPlex), `sm-node-01/02` (Supermicro Xeon D), `sm-node-03` (Supermicro 1U Xeon E5), `pc-node-04` (Ryzen 3800X storage PC: SSD + HDD host), `pc-node-05` (Ryzen 7600 RTX 4070 GPU PC, also an HDD host). |
| **Total Compute** | **36 Physical Cores / 72 vCPU Threads** (`allowSchedulingOnControlPlanes: true` across all 5 cluster nodes). |
| **Total Memory** | **320 GB DDR4 RAM**. |
| **Total Storage** | **~37 TB (33.7 TiB) Raw Rook-Ceph Storage (18 OSDs, as of 2026-10-18)**: **6.0TB High-IOPS NVMe Tier** (4 OSDs: sm-01, sm-02, pc-04, pc-05) + **16.0TB Replicated SATA SSD Tier** (8 OSDs across 4 hosts: sm-01 ×2, sm-02 ×2, sm-03 ×1, pc-04 ×3) + **15.0TB Bulk HDD Tier** (6 OSDs: 4 on `pc-04`, 2 on `pc-05`). *(The storage reshuffle is mid-flight: two IronWolf 4TB and a 250GB MX500 are staged in `sm-03` for Wave 4. See [110 - /var migration](docs/110-ephemeral-var-migration.md).)* |
| **Network Fabric** | **3.5 Gbps Google Fiber WAN**, **20 Gbps LAG SFP+ Switch Backbone**, **Dual 10G SFP+ Server Uplinks**, **2.5G Multi-Gig Node Uplink**, MTU 9000 Jumbo Frames, Dual-Stack IPv4/IPv6, UniFi U7 Pro (Wi-Fi 7) & U6-Lite (Wi-Fi 6). |

---

## 📚 Categorized Documentation Index

### 📋 Live Operations & State Handover
- [001 - Homelab Deployment Journal & Handover Runbook](docs/001-deployment-journal.md)

### 🏗 Section 1: Hardware Architecture & Deployment Phases
- [101 - Hardware Inventory & Resource Breakdown](docs/101-hardware-inventory.md)
- [102 - Architecture Blueprint & Technology Stack](docs/102-architecture-design.md)
- [103 - Phase 1: Sidero Omni & Talos Bootstrap Guide](docs/103-phase1-omni-talos-bootstrap.md)
- [104 - Phase 2: Rook-Ceph 3-Tier Storage Cluster](docs/104-phase2-rook-ceph-storage.md)
- [105 - Global Resource Naming Conventions](docs/105-naming-conventions.md)
- [106 - Phase 3: Observability Stack (Prometheus, Grafana & Ceph Monitoring)](docs/106-observability-prometheus-grafana.md)
- [107 - Ingress Traffic Architecture: MetalLB, Ingress-Nginx & Cert-Manager](docs/107-ingress-traffic-metallb-cert-manager.md)
- [108 - Sidero Omni, Dex & Booter Platform Architecture](docs/108-omni-dex-platform-architecture.md)
- [109 - Phase 4: UPS Power Resiliency & Network UPS Tools (NUT) Monitoring](docs/109-ups-power-monitoring-nut.md)
- [110 - Moving Talos /var off the SuperDOMs & Storage Reshuffle](docs/110-ephemeral-var-migration.md)
- [111 - Storage Reshuffle Hardware Checklist](docs/111-storage-reshuffle-hardware-checklist.md)

### 🌐 Section 2: UniFi Networking & Infrastructure
- [201 - UniFi Physical Cabling & Logical Topology Diagrams](docs/201-unifi-network-topology.md)
- [202 - Cloudflare Tunnel & Zero Trust Remote Access](docs/202-cloudflare-tunnel-zero-trust.md)
- [203 - Tailscale Kubernetes Operator & Mesh VPN](docs/203-tailscale-mesh-vpn.md)
- [204 - UDM-Pro Network & VLAN Setup Guide (Step-by-Step)](docs/204-udm-pro-network-creation-guide.md)

### ⚙️ Section 3: Talos Linux & Cluster Administration
- [301 - Network PXE Boot & Node Provisioning Instruction Manual](docs/301-pxe-boot-node-provisioning.md)
- [302 - GitHub Actions ARC Self-Hosted CI/CD](docs/302-github-actions-runner-controller.md)
- [303 - KubeVirt Bazzite Gaming VM (RTX 4070 Passthrough)](docs/303-kubevirt-bazzite-gpu-vm.md)
- [305 - KubeVirt `omarchy-vm` Arch Linux VM](docs/305-kubevirt-arch-linux-vm.md)
- [306 - Hybrid Cloud & Remote AI Development Architecture](docs/306-hybrid-local-remote-ai-dev.md)
- [307 - Garage Synology NAS: Tier-3 Local DR & Time Machine](docs/307-garage-synology-dr-time-machine.md)

### ☁️ Section 4: Hybrid Multi-Cloud (AWS + Azure Arc & Entra ID)
- [401 - AWS Controllers for Kubernetes (ACK) Architecture](docs/401-aws-ack-hybrid-architecture.md)
- [402 - AWS EKS Connector & Unified AWS Console Management](docs/402-aws-eks-connector.md)
- [403 - Authentik Master IdP & AWS SAML 2.0 Identity Federation](docs/403-identity-sso-authentik-aws.md)
- [404 - AWS Multi-Account Landing Zone (Organizations, IAM Identity Center & Terraform)](docs/404-aws-landing-zone-organizations-terraform.md)
- [405 - AWS Account Factory for Terraform (AFT) vs GitHub Actions GitOps](docs/405-aws-account-factory-terraform.md)
- [407 - Microsoft Entra ID & Authentik Enterprise Identity Federation](docs/407-azure-entra-id-authentik-federation.md)
- [408 - Azure Arc-Enabled Kubernetes & Zero-Cost Cloud Monitoring](docs/408-azure-arc-hybrid-kubernetes.md)
- [409 - GitHub Actions & Multi-Cloud OIDC GitOps Deployment Engine](docs/409-github-cloud-oidc-gitops.md)
- [410 - Azure Cloud & AI Transformation Roadmap: Homelab Hybrid Architecture](docs/410-azure-cloud-and-ai-transformation-roadmap.md)

### 📦 Section 5: Self-Hosted Application Suite
- [501 - TeslaMate Vehicle Telemetry & Analytics Platform](docs/501-teslamate-telemetry-deployment.md)
- [502 - Actual Budget Self-Hosted Personal Finance Platform](docs/502-personal-finance-apps.md)
- [503 - Mealie Recipe Manager & Meal Planner](docs/503-mealie-recipe-planner.md)
- [504 - Immich Self-Hosted Photo & Video Backup Platform (Decommissioned)](docs/504-immich-photo-backup.md)
- [505 - Home Assistant Smart Home & IoT Automation Platform](docs/505-home-assistant-smart-home.md)
- [506 - In-Cluster CUPS Network Print Server & AirPrint Bridge](docs/506-cups-airprint-bridge.md)

### 💻 Section 6: Mac AI Workstation Architecture & USB Bootstrap
- [Workstation Map of Content](nix-mac/Index.md) — Master Workstation Index & Navigation
- [Declarative macOS Architecture](nix-mac/README.md) — `nix-darwin`, system-as-code & clean runtime principles
- [Offline Bootstrap Guide](nix-mac/START_HERE.html) — Standalone visual USB setup instructions
- [Canonical Flake Configuration](nix-mac/templates/flake.nix) — Master `nix-darwin` system definition applied via `just switch`

---

## 📁 Repository Codebase Structure

```
├── Justfile                   # Central command runner for Talos, K8s & Terraform
├── .github/workflows/         # Actions Runner Controller (ARC) CI/CD pipelines
│   ├── provision-aws-account.yml # Automated AWS account provisioning GitOps
│   ├── terraform-ci.yml       # Multi-directory Terraform lint/validate CI
│   └── k8s-validate.yml       # YAML and Kubernetes manifest validation
├── terraform/                 # On-premises homelab infrastructure (applied locally from workstation)
│   └── unifi/                 # UDM-Pro VLANs (10,20,30,40,50,60,90), firewalls, split-horizon DNS
├── bootstrap/                 # Day-0 cloud & CI/CD bootstrap roots (before deployment repo takes over)
│   ├── aws/                   # AWS OIDC role & remote state storage
│   ├── aws_organization/      # Multi-account landing zone & account provisioning
│   ├── azure/                 # Azure Entra ID, OIDC workload identity & storage
│   └── github/                # GitHub deployment repository, environments & multi-cloud OIDC variables
├── nix-mac/                   # Workstation configuration & USB bootstrap suite
│   ├── START_HERE.html        # Offline visual bootstrap guide for new Mac setup
│   ├── START_HERE.txt         # Offline CLI bootstrap instructions
│   ├── templates/             # Canonical flake.nix, Justfile & bootstrap scripts
│   └── *.md                   # Workstation architecture, cloud AI routing & care guides
├── ansible/                   # Ansible configuration management for VMs
│   ├── ansible.cfg            # WinRM & SSH connection defaults
│   ├── inventory/             # Bazzite Gaming VM hosts
│   └── playbooks/             # Automated post-install configuration (NVIDIA, Sunshine)
├── client-tools/              # Workstation client configuration & bootstrap scripts
│   ├── ai-dev/                # Deprecated SSH snippet for the decommissioned remote dev pod
│   ├── unifi-discover.py      # Read-only UniFi API inventory discovery
│   └── generate_unifi_diagram.py # Renders docs/architecture-unifi.svg/png
├── docs/                      # Comprehensive homelab architecture documentation
├── kubernetes/                # Declarative Kubernetes manifests
│   ├── infrastructure/        # Core platform services
│   │   ├── rook-ceph/         # 3-tier Ceph cluster, StorageClasses & Rook alert rules
│   │   ├── backups/           # Encrypted S3 + Synology NAS backup CronJobs (cluster state, Postgres)
│   │   ├── monitoring/        # kube-prometheus-stack values, alert tuning & Homelab Overview dashboard
│   │   ├── ntfy/              # Self-hosted ntfy (Alertmanager → phone push over Tailscale)
│   │   ├── nut/               # NUT UPS server, exporter & alert rules
│   │   ├── metallb/           # MetalLB L2 address pool
│   │   ├── ingress/           # ingress-nginx values & Ceph dashboard ingress
│   │   ├── cert-manager/      # ClusterIssuer & wildcard certificate
│   │   ├── cloudflare/        # Cloudflare Tunnel HA deployment
│   │   ├── tailscale/         # Tailscale operator (Helm values) & Connector for the ingress VIP
│   │   ├── kubevirt/          # Bazzite Gaming VM (GPU passthrough, local NVMe disk) & Arch VM
│   │   ├── omni/              # Sidero Omni, Dex & Booter manifests
│   │   ├── arc/               # Actions Runner Controller AutoscalingRunnerSet
│   │   ├── authentik/         # Authentik master IdP & PostgreSQL
│   │   └── aws-hybrid/        # AWS ACK (S3, Route53) & EKS Connector
│   └── apps/                  # Containerized self-hosted application suite
│       ├── teslamate/         # Tesla telemetry, MQTT, PostgreSQL, Grafana
│       ├── finance/           # Actual Budget personal finance & its S3/NAS backup jobs
│       ├── mealie/            # Mealie recipe manager
│       ├── cups/              # CUPS print server & AirPrint bridge
│       └── home-assistant/    # Home Assistant smart home automation
└── talos/                     # Talos Linux machine configurations & patches
    ├── cluster-template.yaml  # Omni cluster template (source of truth: patches, volumes, taints)
    ├── machine-install-disks.yaml # Omni MachineInstallDiskConfig: per-machine install disk selectors
    ├── talosconfig.example    # talosctl client configuration template
    ├── omni-server/           # Omni host Talos config (secrets gitignored; .example + patch tracked)
    └── patches/               # Standalone node patches (not referenced: the Omni template inlines its own)
        ├── controlplane.yaml  # Supermicro HA control plane (allowSchedulingOnControlPlanes, VIP)
        ├── storage-worker.yaml# pc-node-04 storage worker
        └── gpu-worker.yaml    # pc-node-05 AM5 Ryzen 7600 + RTX 4070 VFIO passthrough
```