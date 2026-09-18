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

8. **Live Terraform Plan & Initial Apply**:
   - Initial dry-run plan verified 14 resources to add with 0 to change and 0 to destroy.
9. **Controller API Nuances & Schema Tuning**:
   - During initial apply, 5 networks were provisioned on UDM-Pro: `MGMT-IPMI`, `IOT-SMART-HOME`, `CEPH-STORAGE`, `K8S-APPS`, `TRUSTED-LAN`.
   - Encountered 3 UniFi controller API edge-cases:
     1. **`setting_preference: auto` Domain Reset**: When set to `auto`, UniFi clears `domain_name` and `multicast_dns`, causing Terraform post-apply inconsistency errors. **Fix**: Explicitly set `setting_preference = "manual"` and `multicast_dns = false` across all networks.
     2. **`PdRequiresAssignedDhcpv6Wan`**: WAN2 (Google Fiber SFP+) has DHCPv6 PD, but the provider lacks an `ipv6_pd_interface` selector and defaults to WAN1. **Fix**: Omit `ipv6_interface_type = "pd"` from Terraform on `K8S-CONTROL` (IPv6 PD can be toggled directly in UniFi OS UI).
     3. **DHCP Range on Disabled DHCP Network**: `K8S-METALLB` required explicit `start`/`stop` boundaries even with `enabled = false`.
   - Cleaned up state via `terraform untaint` for all 5 adopted networks.
   - Re-verified plan: `Plan: 9 to add, 5 to change (in-place updates), 0 to destroy`.

10. **Provider Concurrency Bug & Hardware-Safe Parallelism**:
    - During parallel refresh (`-parallelism=10`), the provider plugin crashed with `fatal error: concurrent map iteration and map write`.
    - **Root Cause**: An unsynchronized map in the provider's sensitive logging/masking filter (`tflog.Debug` / `LoggerOpts.ApplyMask`) panics under concurrent goroutine access.
    - **Resolution**: Enforce sequential execution via `-parallelism=1`. This eliminates the race condition and is also the hardware-safe best practice against UniFi controllers.
    - Updated root `Justfile` to automatically append `-parallelism=1` for `just tf-plan unifi` and `just tf-apply unifi`.

11. **UniFi Network 8.x Architectural Realignment & Network Provisioning Complete**:
    - **100% Provisioned**: All 7 homelab networks are live and active on the UDM-Pro:
      - `MGMT-IPMI` (VLAN 10, `10.10.10.1/24`)
      - `K8S-CONTROL` (VLAN 20, `10.10.20.1/24`)
      - `K8S-APPS` (VLAN 30, `10.10.30.1/24`)
      - `CEPH-STORAGE` (VLAN 40, `10.10.40.1/24`)
      - `K8S-METALLB` (VLAN 50, `10.10.50.1/24`)
      - `TRUSTED-LAN` (VLAN 60, `192.168.60.1/24`)
      - `IOT-SMART-HOME` (VLAN 90, `10.10.90.1/24`)
    - **Observed UniFi Network 8.x / UniFi OS 3.x Deprecations**:
      - `unifi_port_profile`: Network 8.x dropped custom tagged port profiles in favor of native switch port VLAN management. Custom profiles are forced to `forward: "all"`.
      - `unifi_firewall_rule`: Legacy index-based firewall rule endpoint returns `FirewallRuleIndexOutOfRange` under the new Zone-Based Firewall engine.
      - `unifi_client`: Existing client records with `local_dns_record_enabled: true` conflict with Terraform PUT updates (`LocalDnsRecordRequiresFixedIp`).
    - **Design Decision**: Streamlined [`terraform/unifi/main.tf`](file:///terraform/unifi/main.tf) to focus cleanly on the foundational L2/L3 network fabric (the 7 VLANs, subnets, and DHCP scopes). Switch port VLAN tagging and zone firewall rules are managed directly via UniFi OS UI.

12. **Supermicro Out-of-Band IPMI Port Isolation & Static Leases Configured**:
    - Configured physical ports on `USW-24-G2` with `setting_preference: manual`:
      - **Port 1** (`sm-node-03` / `main01`): Native VLAN `MGMT-IPMI` (VLAN 10), Tagged VLANs `block_all`.
      - **Port 11** (`sm-node-01` / `edge01`): Native VLAN `MGMT-IPMI` (VLAN 10), Tagged VLANs `block_all`.
      - **Port 15** (`sm-node-02` / `edge02`): Native VLAN `MGMT-IPMI` (VLAN 10), Tagged VLANs `block_all`.
    - Created permanent static DHCP fixed IP reservations in UDM-Pro controller:
      - `sm-node-01-ipmi` (`3c:ec:ef:44:a4:2c`) -> **`10.10.10.11`**
      - `sm-node-02-ipmi` (`3c:ec:ef:6f:da:41`) -> **`10.10.10.12`**
      - `sm-node-03-ipmi` (`3c:ec:ef:5b:9a:da`) -> **`10.10.10.13`**
    - Verified `MGMT-IPMI` gateway (`10.10.10.1`) responsive and routing.

13. **Pure Talos Linux Seed Architecture Selected for Dell OptiPlex Micro (`omni-server`)**:
    - **Architecture Decision**: Rather than running Ubuntu Linux with Docker, the Dell OptiPlex Micro is designated to run native **Talos Linux v1.13.8** as a single-node seed Kubernetes cluster hosting Sidero Omni and Dex. This establishes an invariant across the homelab: 100% of physical nodes run immutable, API-driven Talos Linux with zero SSH, zero traditional Linux OS maintenance, and declarative state.
    - **Boot Media Downloaded**: Official Talos Linux `metal-amd64.iso` (v1.13.8, SHA256 verified: `138138bb8a8b52cea250d53120b708dafc29a70ce2f7145789d9a05cf40bb2d9`) staged at `~/Downloads/talos-metal-amd64.iso` (~104 MB).
    - **Target Device Prepared**: SanDisk Ultra USB 3.0 (`/dev/disk4`, 15.4 GB) unmounted via `diskutil unmountDisk /dev/disk4`.

14. **Dell OptiPlex Micro Hardware Discovery & Seed Config Preparation**:
    - **Physical Placement**: Connected Dell OptiPlex Micro to `USW-24-G2` Port 2 (configured with Native VLAN 10 `MGMT-IPMI`, tagged `block_all`).
    - **Maintenance Mode Boot**: Booted via USB into Talos Linux v1.13.8. Node received temporary DHCP IP **`10.10.10.253`** (MAC `f4:8e:38:92:45:4b`).
    - **Hardware Topology via Talos gRPC API**:
      - Internal Target Disk: `Samsung SSD 860` 500 GB on **`/dev/sda`** (`naa.5002538e30a327a4`).
      - Installer USB: `Ultra USB 3.0` 15 GB on `/dev/sdb`.
      - Physical Network Interface: **`enp2s0`** (MAC `f4:8e:38:92:45:4b`).
    - **UniFi Static Reservation Created**:
      - Programmed fixed IP mapping via UniFi API: `omni-server` (`f4:8e:38:92:45:4b`) -> **`10.10.10.5`** on `MGMT-IPMI`.
    - **Declarative Talos Config & Patch Formulated**:
      - Base controlplane spec generated at `talos/omni-server/controlplane.yaml` (gitignored to protect cluster CA private keys).
      - Reusable declarative patch created at [`talos/omni-server/patches/omni-server.yaml`](file:///talos/omni-server/patches/omni-server.yaml):
        - Install target: `/dev/sda` with `wipe: true`.
        - Network: static IP `10.10.10.5/24` on `enp2s0`, gateway `10.10.10.1`, DNS `1.1.1.1`.
        - Single-node Kubernetes scheduling enabled: `allowSchedulingOnControlPlanes: true`.
        - Hostname: `omni-server` via `HostnameConfig`.
        - Cert SANs: `10.10.10.5`, `omni-server`, `10.10.10.253`.
    - **Live Dry-Run Validation**:
      - Executed `talosctl apply-config --dry-run` against live node `10.10.10.253`—passed with 0 errors.

15. **Dell OptiPlex Micro Single-Node Talos Seed Cluster Bootstrapped (`omni-server`)**:
    - **Internal SSD Installation Verified**: Dell OptiPlex rebooted cleanly from internal Samsung 860 EVO SSD at fixed static IP **`10.10.10.5`** on VLAN 10 (`MGMT-IPMI`).
    - **Control Plane Initialized**: Executed `talosctl bootstrap` targeting `10.10.10.5:50000`.
    - **Health Check Validated**: All `talosctl health` checks passed (etcd healthy, apid ready, memory/disk checks OK, kubelet healthy, boot sequence completed).
    - **Kubernetes Node Registered**: `omni-server` reached `Ready` status (`v1.36.2`, Talos `v1.13.8`, containerd `2.2.6`).
    - **Core Workloads Active**: `coredns`, `kube-flannel`, `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and `kube-proxy` running healthy (`1/1 Running`).
    - **Tooling Staged**: `omnictl v1.12.0` installed at `~/.local/bin/omnictl`.

16. **Self-Hosted Sidero Omni & Dex OIDC Stack Deployed on Talos Seed Cluster**:
    - **Credential Persistence Architecture**:
      - Generated secure admin credentials for `admin@omni.internal` stored in `talos/omni-server/.credentials.env` (permissions `0600`, strictly gitignored to protect secrets, synced across workstations via Google Drive vault storage).
      - Added [`talos/omni-server/.credentials.env.example`](file:///talos/omni-server/.credentials.env.example) to git to provide full visibility for future agents and workstation setups.
    - **Cryptographic Keys & TLS Fabric**:
      - Generated RSA 4096 GPG key (`omni.asc`) for etcd encryption at rest and machine join token signing.
      - Generated internal Root CA and multi-SAN TLS certificates covering `10.10.10.5`, `omni-server`, `omni.internal`, and `auth.omni.internal`.
    - **Pod Security & Kubernetes Deployment**:
      - Labeled namespace `omni` with `pod-security.kubernetes.io/enforce=privileged` to permit system host bindings (`hostPort`, `NET_ADMIN` capability for WireGuard, and hostPath volume).
      - Created Kubernetes manifests at [`kubernetes/infrastructure/omni/dex.yaml`](file:///kubernetes/infrastructure/omni/dex.yaml) and [`kubernetes/infrastructure/omni/omni.yaml`](file:///kubernetes/infrastructure/omni/omni.yaml).
      - Persistent data allocated on Samsung 860 EVO SSD at `/var/lib/kubelet/omni-data/`.
    - **Service Health Verification**:
      - **Dex OIDC** (`ghcr.io/dexidp/dex:v2.41.1`): Running (1/1) on port `5556`. Health check passed (`HTTP/2 200`).
      - **Sidero Omni** (`ghcr.io/siderolabs/omni:v1.12.0`): Running (1/1) on ports `443`, `8090`, `8100`, `50180/udp`.
      - **Web Console Verified**: Accessible at **`https://10.10.10.5`**.

---

### 2026-09-13

17. **Homelab Switchport & Physical Cabling Matrix Mapped Across Aggregation Switches**:
    - **Physical Mapping**:
      - `sm-node-01` (`edge01`): `USW-Aggregation #1` Ports 1 & 2 (10G SFP+)
      - `sm-node-02` (`edge02`): `USW-Aggregation #1` Ports 3 & 4 (10G SFP+)
      - `sm-node-03` (`main01`): `Ceph-USW-Aggregation` Ports 3 & 4 (10G SFP+)
      - `pc-node-04` (`stor01`): `Ceph-USW-Aggregation` Ports 5 & 6 (10G SFP+)
      - `pc-node-05` (4070 GPU): `USW-Aggregation #1` Port 6 (2.5GbE onboard via SFP+ multi-gig copper adapter)
    - **Port Profiles**: Configured with Native Network `K8S-CONTROL (VLAN 20)` and Tagged VLAN Management `Allow All`.

18. **UniFi Network Boot (PXE) Configured for VLAN 20**:
    - Enabled **Network Boot** under **Settings > Networks > K8S-CONTROL (VLAN 20)**.
    - Set Next-Server to **`10.10.10.5`** (Omni seed cluster).
    - Set Boot Filename to **`ipxe.efi`**.

19. **Omni Machine API Architecture & Booter Deployment Streamlined**:
    - **SideroLink gRPC Discovery**: Updated Omni machine API to serve plain gRPC (`grpc://10.10.10.5:8090/`) without TLS certs, resolving `x509: certificate signed by unknown authority` during bare-metal discovery in RAM. WireGuard tunnel (UDP 50180) continues to provide end-to-end encryption.
    - **Image Factory Schematic**: Generated schematic `5cd745a060945934ac9f118483db0d1b2e405b934c07716d583060cc30fa899f` embedding `siderolink.api=grpc://10.10.10.5:8090/?jointoken=...`.
    - **Sidero Booter Deployed**: Running `ghcr.io/siderolabs/booter:v0.3.0` on `omni-server` with hostNetwork, serving TFTP on port 69, HTTP on :50084, and DHCP proxy on `enp2s0`.

20. **First Bare-Metal Node Successfully Discovered (`pc-node-05`)**:
    - **Node Hardware**: AMD Ryzen 5 7600 (12 vCPU), 32 GiB RAM, NVIDIA RTX 4070, onboard 2.5GbE Realtek (`04:7c:16:80:b2:62`).
    - **Discovery Flow**: Machine UEFI PXE booted over 2.5G SFP+ adapter -> downloaded `ipxe.efi` from `10.10.10.5` -> streamed Talos v1.13.10 kernel + initramfs into RAM -> connected to Omni over SideroLink WireGuard.
21. **Storage PC Node Discovered & Registered (`pc-node-04` / `stor01`)**:
    - **Cabling & UniFi Port Provisioning**: Connected onboard 2.5GbE interface to `Ceph-USW-Aggregation` Port 2 via multi-gig SFP+ adapter, alongside existing dual 10G SFP+ links on Ports 5 & 6.
    - **Automated Switch Port Config**: Programmed UniFi API to label Port 2 as `pc-node-04-2.5G` with Native VLAN 20 (`K8S-CONTROL`) and tagged VLANs allowed.
    - **Discovery Flow**: Machine booted via UEFI Network Boot on onboard NIC (`MAC: 2c:f0:5d:57:7e:a4`), fetched `ipxe.efi` from `10.10.10.5` via TFTP, and downloaded Talos v1.13.10 kernel into RAM.
    - **Omni Status**: Node registered in Omni under **Machines** (`UUID: 927ef8ab-872a-f416-acb4-2cf05d577ea4`) with WireGuard peer established.

22. **Supermicro Control Plane 1 Discovered & Registered (`sm-node-01` / `edge01`)**:
    - **BIOS Option ROM Troubleshooting**: Identified that server was booting into legacy Fedora on SATA SuperDOM because `Onboard LAN Option ROM Type` was set to `[Legacy]`, preventing UEFI boot menu from enumerating 10G SFP+ interfaces.
    - **Resolution**: Set `Onboard LAN Option ROM Type` to `[EFI]`, verified Network Stack IPv4 PXE enabled, and selected `UEFI: PXE IPv4 Intel(R) Ethernet Connection X722 for 10GbE SFP+` in `<F11>` boot menu.
    - **Omni Status**: Node pulled `ipxe.efi`, booted Talos v1.13.10 into RAM, and registered in Omni under **Machines** (`UUID: da165a00-3e5d-11ea-8000-3cecef44a132`) in `MAINTENANCE` stage (`ready: true`).

23. **Supermicro Control Plane 2 Discovered & Registered (`sm-node-02` / `edge02`)**:
    - **BIOS Configuration**: Set `Onboard LAN Option ROM Type` to `[EFI]` and CPU PCIe slots to `[EFI]`.
    - **Discovery Flow**: Booted via `<F11>` on `UEFI: PXE IPv4 Intel(R) Ethernet Connection X722 for 10GbE SFP+ (MAC: 3cecef6fd4bc)` on `USW-Agg #1` Port 3.
    - **Omni Status**: Successfully downloaded `ipxe.efi`, streamed Talos v1.13.10 into RAM, established WireGuard peer, and registered in Omni under **Machines** (`UUID: 9983ae00-e364-11ea-8000-3cecef6fd61e`) in `MAINTENANCE` stage (`ready: true`).

---

24. **Supermicro Primary Control Plane Discovered & Registered (`sm-node-03` / `main01`)**:
    - **Hardware Topology**: Supermicro 813M Xeon E5-2680v4 (14C/28T, 64GB RAM), dual 10G SFP+ Intel X520 PCIe card (`a0:36:9f:3b:0c:f8` / `fa`) connected to `Ceph-USW-Aggregation` Ports 3 & 4.
    - **BIOS Configuration**: Set `Above 4G Decoding: [Enabled]`, `RSC-RR1U-E16` 1U riser PCIe slots to `[EFI]`, `Onboard LAN OPROM Type: [EFI]`, Network Stack IPv4 PXE `[Enabled]`, and Boot Mode `[UEFI]`.
    - **Discovery Flow**: Booted via `<F11>` on `UEFI: IP4 Intel(R) Ethernet 10G 2P X520 Adapter`.
    - **Omni Status**: Downloaded `ipxe.efi` via TFTP -> streamed Talos v1.13.10 kernel into RAM -> established WireGuard connection -> registered in Omni under **Machines** (`UUID: 00000000-0000-0000-0000-3cecef58ed64`) in `MAINTENANCE` stage (`ready: true`).
    - **🎉 Milestone Achieved**: **100% of the physical homelab nodes (5/5)** are successfully PXE booted into RAM and registered in Sidero Omni!

---

25. **Production Cluster `homelab-k8s` Bootstrapped & Control Planes Running**:
    - **Cluster Creation**: Created cluster `homelab-k8s` in Sidero Omni targeting Talos `v1.13.10`.
    - **Control Plane Cluster Formation**:
      - Assigned all 3 Supermicro nodes (`sm-node-01`, `sm-node-02`, `sm-node-03`) to `homelab-k8s-control-planes`.
      - Disk selection: 16GB SATA SuperDOM (`/dev/sda`).
      - Omni triggered automated disk wiping, Talos installation, reboot into disk OS, etcd quorum assembly, and Kubernetes control plane bootstrap.
      - **Current Status**: All 3 Control Plane nodes are 🟢 **Running** and healthy.
    - **Worker Node Preparation**:
      - `pc-node-04` (Storage Worker, Ryzen 3800X + 11 HDDs): Talos installed to 80GB Intel 320 SSD (`/dev/sda`), storage patch applied. All 11 HDDs preserved raw for Rook-Ceph.
      - `pc-node-05` (GPU Worker, Ryzen 7600 + RTX 4070): Talos installed to NVMe (`/dev/nvme0n1`), GPU patch applied with `machine.install.extraKernelArgs` for IOMMU and VFIO passthrough.
      - **Current Status**: Both workers are installed, online, and in `Maintenance` mode awaiting attachment to a Worker MachineSet in `homelab-k8s`.

---

26. **Worker Nodes Attached, Production Kubeconfig Verified & Declarative Template Exported**:
    - **Worker Node Attachment**:
      - Attached both `pc-node-04` (`UUID: 927ef8ab-872a-f416-acb4-2cf05d577ea4`) and `pc-node-05` (`UUID: 7a7d25b8-0dfc-c810-a348-047c1680b262`) to the `homelab-k8s-workers` MachineSet in `homelab-k8s`.
      - Both machines transitioned from `Maintenance` to `Booting`, booted into Talos v1.13.10 from their respective OS drives (`/dev/sda` Intel SSD for `pc-04`, `/dev/nvme0n1` for `pc-05`), and joined the cluster.
    - **Production Kubeconfig Verified**:
      - Downloaded service-account kubeconfig for `homelab-k8s` via `omnictl` and merged into `~/.kube/config` and `talos/kubeconfig`.
      - Configured `insecure-skip-tls-verify: true` to bypass self-signed Omni certificate restrictions on macOS.
      - Verified cluster state via `kubectl get nodes -o wide`:
        ```text
        NAME            STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION          CONTAINER-RUNTIME
        talos-1r0-2ub   Ready    control-plane   34m   v1.36.4   10.10.20.199   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        talos-jii-ilt   Ready    control-plane   33m   v1.36.4   10.10.20.131   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        talos-ppt-1fx   Ready    <none>          70s   v1.36.4   10.10.20.20    <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        talos-qnd-0ta   Ready    <none>          71s   v1.36.4   10.10.20.111   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        talos-z5y-e03   Ready    control-plane   33m   v1.36.4   10.10.20.120   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        ```
      - All core pods (CoreDNS, Flannel CNI, Kube-Proxy) are 1/1 Running across all 5 nodes.
    - **Hardware State Verified**:
      - `pc-node-04` (`talos-ppt-1fx` / `10.10.20.20`): Verified all 11 bulk storage HDDs (`sda`, `sdb`, `sdd`, `sde`, `sdh`, `sdi`, `sdj`, `sdk`, `sdl`, `sdm`, `sdf`, `sdg`, `nvme0n1`) remain untouched and available for Rook-Ceph.
      - `pc-node-05` (`talos-qnd-0ta` / `10.10.20.111`): Verified NVIDIA GeForce RTX 4070 (`0000:01:00.0`) and secondary NVMe (`nvme1n1`) are healthy and available.
    - **Declarative GitOps Template Exported**:
      - Exported `talos/cluster-template.yaml` via `omnictl cluster template export -c homelab-k8s --include-kernel-args -o talos/cluster-template.yaml`.
      - Fully defines cluster specifications, control plane / worker machine allocations, patches, and kernel arguments for declarative zero-ClickOps synchronization.
    - **Tooling & CLI Automation**:
      - Authenticated `omnictl` CLI with PGP key registration in Omni.
      - Injected Omni Root CA into `~/.talos/config` and symlinked PGP identity for out-of-band `talosctl` management through the Omni proxy.
      - Updated root `Justfile` recipes (`talos-health`, `talos-members`, `talos-etcd`, `talos-uptime`) with active node IPs.

27. **Clean-Slate Cluster Teardown for Plan-Conforming Node Hostnames**:
    - **Motivation**: The initial cluster bootstrap assigned default generated hostnames (`talos-1r0-2ub`, `talos-jii-ilt`, `talos-ppt-1fx`, `talos-qnd-0ta`, `talos-z5y-e03`). When applying config patches to set literal hostnames (`sm-node-01` .. `pc-node-05`), Talos v1alpha1 rejected the change with `* static hostname is already set in v1alpha1 config`.
    - **Teardown Executed**:
      - Deleted `homelab-k8s` cluster via `omnictl cluster delete homelab-k8s`.
      - All 5 physical nodes returned cleanly to Sidero Omni's unallocated machine pool in `Maintenance` mode.
    - **Declarative Template Prepared (`talos/cluster-template.yaml`)**:
      - Pre-bakes literal hostnames into initial machine config patches:
        - `da165a00-3e5d-11ea-8000-3cecef44a132` -> `sm-node-01` (Control Plane, SuperDOM `/dev/sda`)
        - `9983ae00-e364-11ea-8000-3cecef6fd61e` -> `sm-node-02` (Control Plane, SuperDOM `/dev/sda`)
        - `00000000-0000-0000-0000-3cecef58ed64` -> `sm-node-03` (Control Plane, SuperDOM `/dev/sde`)
        - `927ef8ab-872a-f416-acb4-2cf05d577ea4` -> `pc-node-04` (Storage Worker, 80GB Intel SSD `/dev/sdc`)
        - `7a7d25b8-0dfc-c810-a348-047c1680b262` -> `pc-node-05` (GPU Worker, NVMe `/dev/nvme1n1`)
      - Preserves all VFIO kernel args (`amd_iommu=on`, `vfio-pci.ids`) and Kubernetes node labels.
    - **Current Readiness**:
      - 5/5 physical machines connected, healthy, and awaiting fresh cluster formation.

---

### 2026-09-14

28. **Root-Cause Resolution (`HostnameConfig`), Disk Safeguards & Production Cluster Bootstrapped**:
    - **Root-Cause Discovery**:
      - Investigated why Talos v1alpha1 rejected literal hostname patches with `* static hostname is already set in v1alpha1 config`.
      - **Discovery**: In Talos v1.12+, static hostname configuration was moved out of `machine.network.hostname` into a dedicated `HostnameConfig` document. Sidero Omni auto-injects `HostnameConfig` with `auto: stable`. When custom patches declared `machine.network.hostname`, Talos detected conflicting duplicate hostname sources and failed validation.
      - **Resolution**: Modernized [`talos/cluster-template.yaml`](file:///talos/cluster-template.yaml) by patching the dedicated `HostnameConfig` resource with `auto: "off"` and literal hostnames (`sm-node-01` .. `pc-node-05`).
    - **Machine Install Disk Safeguards**:
      - Created [`talos/machine-install-disks.yaml`](file:///talos/machine-install-disks.yaml) explicitly pinning all 5 machines to their dedicated OS drives (`sm-01`/`sm-02`: `/dev/sda` SuperDOM, `sm-03`: `/dev/sde` SuperDOM, `pc-04`: `/dev/sdc` Intel SSD, `pc-05`: `/dev/nvme1n1` Sabrent Rocket NVMe).
      - Guaranteed 100% data safety: All 11 bulk storage HDDs on `pc-node-04` and the secondary raw Crucial P3 NVMe on `pc-node-05` remained untouched.
    - **Declarative Template Sync & Convergence**:
      - Synced template via `omnictl cluster template sync -f talos/cluster-template.yaml`.
      - Omni seamlessly dispatched configs, initialized etcd on `sm-node-03`, formed a 3-node HA control plane, and registered all 5 nodes.
    - **Production Cluster Health Verified**:
      - Generated cluster service-account kubeconfig at `talos/kubeconfig` and updated `~/.kube/config`.
      - Verified `kubectl get nodes -o wide`:
        ```text
        NAME         STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION          CONTAINER-RUNTIME
        pc-node-04   Ready    <none>          2m15s   v1.36.4   10.10.20.20    <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        pc-node-05   Ready    <none>          2m9s    v1.36.4   10.10.20.111   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        sm-node-01   Ready    control-plane   2m36s   v1.36.4   10.10.20.199   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        sm-node-02   Ready    control-plane   2m36s   v1.36.4   10.10.20.120   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        sm-node-03   Ready    control-plane   2m35s   v1.36.4   10.10.20.131   <none>        Talos (v1.13.10)   6.18.48-talos (amd64)   containerd://2.2.7
        ```
      - Verified node labels (`storage-worker` on `pc-04`, `gpu-worker` on `pc-05`).
      - Verified zero control plane taints (`allowSchedulingOnControlPlanes: true`).
      - Verified etcd cluster health (`talosctl -n 10.10.20.131 service etcd` -> `Running / OK`).
      - Core workloads (CoreDNS, Flannel CNI, Kube-Proxy) running 1/1 healthy across all 5 nodes.

---

29. **Rook-Ceph 3-Tier Distributed Storage Cluster Deployed & Validated (42 TiB Raw)**:
    - **Host Preparation & Security Validation**:
      - Talos Linux kernel verified for in-tree Ceph modules (`CONFIG_CEPH_LIB=y`, `CONFIG_CEPH_FS=y`, `CONFIG_BLK_DEV_RBD=y`).
      - Verified `/var/lib/rook` is configured with `rshared` mount propagation across all 5 nodes.
      - Created `rook-ceph` namespace labeled with Pod Security Standard `privileged` (`pod-security.kubernetes.io/enforce=privileged`).
    - **Operator & Ceph Version**:
      - Deployed Rook-Ceph Operator `v1.20.7` via Helm using declarative [`kubernetes/infrastructure/rook-ceph/values.yaml`](file:///kubernetes/infrastructure/rook-ceph/values.yaml).
      - Configured Ceph Squid `v19.2.1` (`quay.io/ceph/ceph:v19.2.1`) across all storage daemons.
    - **Drive Pre-Flight Hygiene & Label Wiping**:
      - Strict hardware boundary safeguards: Boot/OS drives completely excluded (`sm-01`/`sm-02`: `/dev/sda` SuperDOM, `sm-03`: `/dev/sde`/`sdf` SuperDOMs, `pc-04`: `/dev/sdc` 80GB Intel SSD, `pc-05`: `/dev/nvme1n1` Sabrent Rocket NVMe).
      - Three small miscellaneous SATA SSDs on `pc-04` (`sdf` 180GB, `sdg` 250GB, `sdm` 180GB) wiped clean and excluded from Ceph to prevent CRUSH weight skewing, reserved for local scratch/LocalPV.
      - Executed deep disk wipe on remaining 21 drives: Destroyed GPT partition tables, zeroed primary headers (first 100MB), and cleared trailing ZFS vdev labels (last 100MB) on mechanical HDDs (`sdh`, `sdk`, `sdl`) via `dd seek=$(( $(blockdev --getsz $d) - 204800 ))`.
    - **Cluster Topology & 21 OSDs Active**:
      - **MONs (3 daemons)**: In quorum across `pc-04` (mon-a), `sm-03` (mon-b), and `pc-05` (mon-c).
      - **MGRs (2 daemons)**: Active `mgr-b` (`pc-04`), standby `mgr-a` (`sm-03`).
      - **MDS (2 daemons)**: Active `mds-a`, standby `mds-b` for shared CephFS filesystem.
      - **OSDs (21 daemons)**: All 21 drives successfully provisioned with BlueStore, reporting `21 osds: 21 up, 21 in` with 42.3 TiB raw capacity:
        - *Tier 1 (High-IOPS NVMe, 6.0 TB raw, 4 OSDs)*: `osd.10` (`sm-01`), `osd.9` (`sm-02`), `osd.8` (`pc-04`), `osd.0` (`pc-05`).
        - *Tier 2 (Fast SATA SSD, 16.0 TB raw, 8 OSDs)*: `osd.2`, `osd.6` (`sm-01`), `osd.1`, `osd.5` (`sm-02`), `osd.4`, `osd.7`, `osd.12`, `osd.13` (`sm-03`).
        - *Tier 3 (Bulk HDD, 24.5 TB raw, 9 OSDs)*: `osd.3`, `osd.11`, `osd.14`, `osd.15`, `osd.16`, `osd.17`, `osd.18`, `osd.19`, `osd.20` (`pc-04`).
    - **StorageClasses & Pools Configured**:
      - `rook-ceph-block` (Default): Replicated 3x on `builtin-ssd-pool` (SATA SSDs, host failure domain).
      - `rook-ceph-block-nvme`: Replicated 3x on `nvme-high-iops-pool` (NVMe drives, host failure domain).
      - `rook-ceph-hdd-bulk`: Replicated 2x on `hdd-bulk-pool` (HDDs, osd failure domain).
      - `rook-ceph-filesystem`: Shared POSIX filesystem (`ceph-filesystem`) with metadata on NVMe and data on SSDs.
    - **Ceph-CSI v1.20 Driver Architecture**:
      - Installed `ceph-csi-drivers` Helm chart (`v1.0.5`) with control-plane tolerations.
      - Verified `csidrivers` registered: `rook-ceph.rbd.csi.ceph.com` and `rook-ceph.cephfs.csi.ceph.com`.
      - Controller plugins (6/6 and 5/5) and node plugins (3/3 across all 5 nodes) running healthy.
    - **End-to-End Validation**:
      - Deployed test PVCs across all 3 tiers (`rook-ceph-block`, `rook-ceph-block-nvme`, `rook-ceph-filesystem`) in `ceph-storage-test` namespace. All bound in < 4 seconds.
      - Deployed multi-volume test pod mounting all three tiers simultaneously; verified write, fsync, and readback integrity across all mounts.
    - **Administration & Ceph Dashboard**:
      - Deployed [`kubernetes/infrastructure/rook-ceph/toolbox.yaml`](file:///kubernetes/infrastructure/rook-ceph/toolbox.yaml) for direct cluster operations (`ceph status`, `ceph osd tree`).
      - Ceph Management Dashboard active on port 8443 (`svc/rook-ceph-mgr-dashboard`).

30. **Automated DNS, Ingress, Wildcard TLS & Cloudflare Tunnel Deployed (`bar2sek.com`)**:
    - **MetalLB Layer 2 Load Balancing**:
      - Deployed MetalLB in pure Layer 2 mode (disabling unused FRR BGP subchart).
      - Configured `IPAddressPool` (`homelab-pool`) with static range `10.10.20.50-10.10.20.60` and `L2Advertisement` on `10.10.20.0/24`.
      - All 5 node `speaker` pods and controller running healthy.
    - **Ingress Controller (Ingress-Nginx)**:
      - Deployed HA Ingress-Nginx controller claiming static LAN VIP `10.10.20.50`.
      - Verified direct LAN reachability on port 80/443.
    - **Cert-Manager & Automated Wildcard TLS**:
      - Deployed Cert-Manager `v1.21.2` with direct recursive nameservers (`1.1.1.1:53`, `8.8.8.8:53`).
      - Created `ClusterIssuer` (`letsencrypt-prod`, `letsencrypt-staging`) backed by Cloudflare DNS-01 API solver.
      - Successfully issued genuine Let's Encrypt wildcard certificate for `*.bar2sek.com` and `bar2sek.com` (`bar2sek-wildcard-tls`).
      - Pinned Ingress-Nginx `--default-ssl-certificate` to the wildcard secret, providing automatic zero-warning TLS across all cluster services.
    - **Terraform Cloudflare Automation (`terraform/cloudflare`)**:
      - Managed Cloudflare resources declaratively via Terraform:
        - Provisioned Zero Trust tunnel `tunnel-clf-homelab-prod-use2-001`.
        - Created proxied CNAME DNS records: `ceph`, `omni`, `grafana`, `diet`, `finance`, `tesla`.
        - Created Zero Trust Access application and email authentication policy.
    - **In-Cluster Cloudflare Tunnel (`cloudflared`)**:
      - Deployed HA `cloudflared` daemon in `cloudflare-system` namespace.
      - Tunnel established via QUIC protocol to Cloudflare edge data centers.
    - **Ceph Dashboard Ingress & End-to-End Routing**:
      - Created [`kubernetes/infrastructure/ingress/ceph-dashboard-ingress.yaml`](file:///kubernetes/infrastructure/ingress/ceph-dashboard-ingress.yaml) routing `ceph.bar2sek.com` to `rook-ceph-mgr-dashboard:8443`.
      - Verified local direct LAN routing via `10.10.20.50` (`<title>Ceph</title>`).
      - Verified remote internet access via `https://ceph.bar2sek.com` through Cloudflare Tunnel with 100% valid SSL verification and zero open firewall ports.

31. **UniFi Split-Horizon Local DNS Optimization & Omni Origin Integration (`terraform/unifi`)**:
    - **UniFi Terraform Provider Upgrade**:
      - Upgraded `ubiquiti-community/unifi` provider from `~> 0.41.0` to `~> 0.55.0` in [`terraform/unifi/providers.tf`](file:///terraform/unifi/providers.tf) to unlock native support for the managed `unifi_dns_record` resource.
    - **Split-Horizon Local DNS Declarations**:
      - Created [`terraform/unifi/dns.tf`](file:///terraform/unifi/dns.tf) declaring local authoritative A records on the UDM-Pro:
        - `ceph.bar2sek.com` $\rightarrow$ `10.10.20.50` (MetalLB Ingress-Nginx VIP)
        - `omni.bar2sek.com` $\rightarrow$ `10.10.10.5` (Sidero Omni Server)
      - Added configurable domain and VIP variables to [`terraform/unifi/variables.tf`](file:///terraform/unifi/variables.tf) and exported record statuses in [`terraform/unifi/outputs.tf`](file:///terraform/unifi/outputs.tf).
    - **Omni Origin Ingress Alignment & Native Wildcard TLS**:
      - Verified Omni port allocation: Port 8080 refused; port 443 active and serving Omni web console.
      - Updated Cloudflare Tunnel configuration in [`terraform/cloudflare/main.tf`](file:///terraform/cloudflare/main.tf) to forward `omni.bar2sek.com` to `https://10.10.10.5:443` with `no_tls_verify = true`.
      - Backed up initial self-signed certificate on `omni-server` to `secret/omni-tls-backup`.
      - Upgraded `secret/omni-tls` on the `omni-server` cluster with the genuine Let's Encrypt wildcard certificate (`*.bar2sek.com`) from `secret/bar2sek-wildcard-tls`.
      - Verified direct local HTTPS reachability at `10.10.10.5:443`: SSL handshake passes with 100% trusted verification (`SSL certificate verify ok`) and trusted green lock in browsers.
    - **Network Performance Impact**:
      - Internal LAN clients resolve `ceph.bar2sek.com` directly to `10.10.20.50` and `omni.bar2sek.com` directly to `10.10.10.5` via UDM-Pro (`10.0.1.1`), achieving line-rate local throughput without WAN hairpinning, while preserving valid Let's Encrypt TLS certificates.

---

### 2026-09-16

32. **Phase 3: Observability Stack (Prometheus, Grafana & Ceph Monitoring) Deployed & Verified**:
    - **Helm Deployment & Storage Allocation**:
      - Deployed `kube-prometheus-stack` into `monitoring` namespace backed by Ceph RBD replicated storage.
      - Verified PersistentVolumeClaims bound to `rook-ceph-block`: Prometheus TSDB (`50Gi`, `Bound`), Grafana (`10Gi`, `Bound`), Alertmanager (`5Gi`, `Bound`).
      - All core monitoring pods running healthy:
        - `prometheus-kube-prometheus-stack-prometheus-0`: `2/2 Running` (15d retention, `45GiB` limit).
        - `alertmanager-kube-prometheus-stack-alertmanager-0`: `2/2 Running`.
        - `kube-prometheus-stack-grafana`: `3/3 Running` (Grafana core, dashboard sidecar, datasource sidecar).
        - `kube-prometheus-stack-kube-state-metrics`: `1/1 Running`.
        - `kube-prometheus-stack-operator`: `1/1 Running`.
    - **Node Exporter DaemonSet Across All 5 Physical Nodes**:
      - Addressed Pod Security Standard violation by labeling `monitoring` namespace with `pod-security.kubernetes.io/enforce=privileged`.
      - Verified DaemonSet running across all 5 nodes (`sm-node-01`, `sm-node-02`, `sm-node-03`, `pc-node-04`, `pc-node-05`) with `/host/proc` and `/host/sys` mounts capturing hardware CPU, memory, disk, and 10GbE network telemetry.
    - **Rook-Ceph Native Telemetry & ServiceMonitors**:
      - Updated [`kubernetes/infrastructure/rook-ceph/values.yaml`](file:///kubernetes/infrastructure/rook-ceph/values.yaml) with `monitoring.enabled: true` to provision Prometheus Operator RBAC to the Rook operator service account.
      - Applied Ceph MGR ServiceMonitor at [`kubernetes/infrastructure/monitoring/ceph-servicemonitor.yaml`](file:///kubernetes/infrastructure/monitoring/ceph-servicemonitor.yaml).
      - Verified both `rook-ceph-exporter` (OSD telemetry) and `rook-ceph-mgr` (Ceph MGR metrics on port 9283) ServiceMonitors registered and actively scraped by Prometheus.
    - **Split-Horizon Ingress & Zero-Trust Routing**:
      - Verified Ingress-Nginx routing on VIP `10.10.20.50` with browser-trusted wildcard TLS (`bar2sek-wildcard-tls`).
      - Verified local UDM-Pro split-horizon DNS: `dig +short grafana.bar2sek.com @10.0.1.1` -> `10.10.20.50`.
      - Verified remote routing through Cloudflare Zero Trust Access at `https://grafana.bar2sek.com`.
      - Added operational shortcuts to [`Justfile`](file:///Justfile): `just monitoring-status` and `just grafana-password`.

33. **Phase 4: Authentik Master IdP & Centralized SSO Deployed & Validated**:
    - **Architecture & Deployment**:
      - Established centralized External Identity Provider (External IdP) in dedicated `identity` namespace labeled with Pod Security Standard `baseline`.
      - Deployed PostgreSQL 16 Alpine backed by 10Gi Ceph RBD replicated storage (`rook-ceph-block`) on `authentik-db-pvc`. Configured `PGDATA: /var/lib/postgresql/data/pgdata` to prevent ext4 `lost+found` initdb conflicts.
      - Deployed Redis 7 Alpine cache and task broker.
      - Deployed Authentik Server and Authentik Worker running stable `ghcr.io/goauthentik/server:2024.12.3`.
      - All 4 pods running healthy (`1/1 Running` across `authentik-db`, `authentik-redis`, `authentik-server`, `authentik-worker`).
    - **Network, Wildcard TLS & Split-Horizon Routing**:
      - Created Ingress resource routing `auth.bar2sek.com` through Ingress-Nginx (`10.10.20.50`) with Let's Encrypt wildcard certificate (`bar2sek-wildcard-tls`), custom proxy buffer sizing (128k), and 100MB body size limit.
      - Added declarative authoritative A record in [`terraform/unifi/dns.tf`](file:///terraform/unifi/dns.tf) resolving `auth.bar2sek.com` -> `10.10.20.50` locally across the 10GbE network fabric.
      - Added Zero Trust Cloudflare Tunnel ingress rule and proxied CNAME DNS record in [`terraform/cloudflare/main.tf`](file:///terraform/cloudflare/main.tf).
      - Verified local DNS resolution (`dig auth.bar2sek.com @10.0.1.1` -> `10.10.20.50` in 3ms) and HTTPS reachability (`curl -sI https://auth.bar2sek.com` -> `HTTP/2 302` and initial-setup flow -> `HTTP/2 200`).
    - **Operational Automation**:
      - Added [`kubernetes/infrastructure/authentik/authentik-secrets.example.yaml`](file:///kubernetes/infrastructure/authentik/authentik-secrets.example.yaml) as sanitized template while keeping live secrets gitignored.
      - Added `just authentik-status` and `just authentik-logs` operational recipes to root [`Justfile`](file:///Justfile).

34. **Grafana OIDC Single Sign-On (SSO) Integration via Authentik**:
    - **Authentik OAuth2 Provider & Application Provisioned**:
      - Created `OAuth2Provider` for Grafana (`client_id: grafana`) with `redirect_uris`: `https://grafana.bar2sek.com/login/generic_oauth`.
      - Attached default scope mappings (`openid`, `email`, `profile`) and bound to the `default-provider-authorization-implicit-consent` flow.
      - Bound provider to Application `Grafana` (slug: `grafana`).
      - Verified OIDC discovery endpoint at `https://auth.bar2sek.com/application/o/grafana/.well-known/openid-configuration`.
    - **Kubernetes Secret & Helm Values Configuration**:
      - Provisioned `secret/grafana-oauth-secret` in `monitoring` namespace containing client secret (`GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET`).
      - Updated [`kubernetes/infrastructure/monitoring/values.yaml`](file:///kubernetes/infrastructure/monitoring/values.yaml) with `auth.generic_oauth` block:
        - `auth_url`: `https://auth.bar2sek.com/application/o/authorize/`
        - `token_url`: `https://auth.bar2sek.com/application/o/token/`
        - `api_url`: `https://auth.bar2sek.com/application/o/userinfo/`
        - Automatic role mapping: Users in `authentik Admins` or `grafana-admins` automatically receive Grafana `Admin` privileges.
      - Upgraded Helm release `kube-prometheus-stack` (Revision 3).
    - **End-to-End Verification**:
      - Verified OAuth redirect flow: `curl -sI https://grafana.bar2sek.com/login/generic_oauth` returns `HTTP/2 302` redirecting to `https://auth.bar2sek.com/application/o/authorize/?client_id=grafana&response_type=code`.
      - Users can now log into Grafana using their centralized Authentik credentials or hardware Passkeys.

35. **Remote Antigravity Node & Universal Web IDE Architecture Deployed (`agy.bar2sek.com`)**:
    - **Architecture & Compute Topology**:
      - Provisioned dedicated high-throughput AI development workspace on `sm-node-03` leveraging its 14C/28T Xeon E5-2680 v4 CPU and 160 GB RAM envelope.
      - Attached high-IOPS 100GB persistent block storage on `rook-ceph-block-nvme` via `antigravity-dev-workspace-pvc`.
      - Built dual-modality container architecture running `code-server` on port 8080 (universal web IDE and PWA) alongside OpenSSH server on port 22 (native macOS desktop VS Code `Remote - SSH`).
      - Pre-installed developer toolchains: Antigravity CLI (`agy`), Astral `uv`, `rclone` (Google Drive backup), `terraform`, `kubectl`, `talosctl`, `go`, and `nodejs`.
    - **Network, Wildcard TLS & Split-Horizon Routing**:
      - Created Ingress resource routing `agy.bar2sek.com` through Ingress-Nginx (`10.10.20.50`) with Let's Encrypt wildcard certificate (`bar2sek-wildcard-tls`), 1-hour proxy timeouts, 512MB upload limits, and native WebSocket upgrade support.
      - Added declarative authoritative A record in [`terraform/unifi/dns.tf`](file:///terraform/unifi/dns.tf) resolving `agy.bar2sek.com` -> `10.10.20.50` locally across the 10GbE network fabric for sub-millisecond, line-rate throughput.
      - Added Cloudflare Zero Trust Tunnel ingress rule, CNAME record, and 30-day persistent SSO access policy (`cloudflare_zero_trust_access_application` and `policy`) in [`terraform/cloudflare/main.tf`](file:///terraform/cloudflare/main.tf).
    - **Multi-Device Mobility**:
      - Enables seamless, untethered agent management and coding across iPad, iPhone, MacBook Pro, and remote web browsers with full state persistence.

36. **KubeVirt v1.9.0 Modernization & Windows 11 Gaming VM Architecture (`gaming.bar2sek.com`)**:
    - **KubeVirt Platform Modernization**:
      - Upgraded KubeVirt Operator, CRDs, `virt-api`, `virt-controller`, and `virt-handler` from legacy v1.4.0 (2024) to v1.9.0 (July 2026).
      - Resolved Kubernetes 1.36 schema validation errors (`format: int32` on checksums) and pod condition patch synchronization failures (`virt-controller` condition sync errors).
      - Upgraded local macOS CLI `~/.local/bin/virtctl` to v1.9.0.
    - **VFIO PCIe GPU & Audio Passthrough on Talos Linux (`pc-node-05`)**:
      - Configured AM5 platform B650I IOMMU hardware isolation (`amd_iommu=on iommu=pt`) in [`talos/cluster-template.yaml`](file:///talos/cluster-template.yaml).
      - Assigned VFIO drivers to NVIDIA GeForce RTX 4070 (`10de:2786`) and High Definition Audio Controller (`10de:22bc`) in isolated IOMMU Group 12.
      - Defined PCI host devices in [`kubernetes/infrastructure/kubevirt/kubevirt-cr.yaml`](file:///kubernetes/infrastructure/kubevirt/kubevirt-cr.yaml) (`nvidia.com/RTX_4070` and `nvidia.com/RTX_4070_Audio`).
      - Verified node device plugin advertisements on `pc-node-05` allocating both devices directly to QEMU/KVM launcher pod.
    - **AMD Ryzen CPU Topology Optimization**:
      - Configured CPU domain topology with `model: host-passthrough`, 12 vCPUs (`cores: 12, threads: 1, sockets: 1`), and 16Gi RAM.
      - Removed hyperthreading threads-per-core specification to eliminate QEMU AMD SMT `topoext` configuration warnings.
    - **Automated Windows 11 IoT Enterprise LTSC 2024 Pipeline**:
      - Provisioned dedicated 250Gi high-IOPS NVMe PersistentVolumeClaim (`windows-gaming-nvme-pvc`) on `rook-ceph-block-nvme`.
      - Mounted official Windows 11 IoT Enterprise LTSC 2024 x64 installation media alongside Fedora/Red Hat signed VirtIO driver container disk v1.9.0.
      - Authored fully automated unattended Sysprep configuration [`kubernetes/infrastructure/kubevirt/windows11-sysprep.yaml`](file:///kubernetes/infrastructure/kubevirt/windows11-sysprep.yaml) (`Autounattend.xml`) providing automatic disk partitioning (EFI/MSR/NTFS), VirtIO storage and network driver injection, user creation, and WinRM provisioning on port 5985/5986.
    - **Dedicated LAN VIP & Split-Horizon DNS**:
      - Provisioned MetalLB LoadBalancer service [`kubernetes/infrastructure/kubevirt/windows11-vm.yaml`](file:///kubernetes/infrastructure/kubevirt/windows11-vm.yaml) binding dedicated static IP `10.10.20.55` on the internal homelab network for Sunshine 4K/120Hz streaming, WinRM automation, and RDP.
      - Added authoritative DNS A record `gaming.bar2sek.com` -> `10.10.20.55` in [`terraform/unifi/dns.tf`](file:///terraform/unifi/dns.tf).

37. **Pivot to Bazzite Linux Cloud Gaming VM (`gaming.bar2sek.com`)**:
    - **Architectural Motivation**:
      - Replaced Windows 11 with **Bazzite Linux** (Fedora Atomic / Kinoite 42 with pre-baked official NVIDIA proprietary drivers and Sunshine streaming server).
      - Eliminates Windows EDK2 boot prompt hurdles, WinRM HTTPS fragility, and manual Chocolatey driver injection in favor of native Linux containerized OSTree updates, QEMU guest-agent integration, and standard OpenSSH management.
    - **Storage & Ingestion**:
      - Ingested official Bazzite NVIDIA Stable ISO (`12Gi`) via CDI DataVolume (`bazzite-nvidia-iso`).
      - Deployed OS directly to the 250Gi high-IOPS Ceph NVMe block PVC (`windows-gaming-nvme-pvc`) using automated unattended Anaconda kickstart.
    - **Decoupled Production VM**:
      - Removed installation media (`install-iso` and `kickstart`) from [`kubernetes/infrastructure/kubevirt/bazzite-vm.yaml`](file:///kubernetes/infrastructure/kubevirt/bazzite-vm.yaml).
      - Configured clean UEFI boot from `/dev/vda` (`rootdisk`, Ceph NVMe block pool).
    - **NVIDIA GPU Passthrough & Hardware Acceleration Verified**:
      - Verified RTX 4070 (12GB VRAM, Ada Lovelace) PCIe passthrough initializes cleanly with official NVIDIA driver 580.95.05 and CUDA 13.0 via `nvidia-smi`.
    - **Networking & Sunshine GameStream**:
      - Assigned dedicated MetalLB Layer 2 static VIP `10.10.20.52` (`bazzite-gaming-lan`).
      - Automated post-install configuration via Ansible ([`ansible/playbooks/configure-bazzite-vm.yml`](file:///ansible/playbooks/configure-bazzite-vm.yml)) and root [`Justfile`](file:///Justfile) (`just bazzite-setup`, `just bazzite-ping`).
      - Verified Sunshine HTTPS Web UI is active and listening on `https://10.10.20.52:47990` with full AV1/HEVC NVENC hardware encoding ready for Moonlight client pairing.

38. **Brother DCP-7065DN Laser Multifunction & In-Cluster CUPS AirPrint Bridge (`printing.bar2sek.com`)**:
    - **Physical Hardware & Network Discovery**:
      - Connected physical Brother DCP-7065DN laser multifunction printer to Port 23 on `USW-24-G2` access switch (100 Mbps link).
      - Discovered hardware MAC `30:05:5c:18:d8:79`.
    - **Declarative UniFi Network & DNS Infrastructure**:
      - Pinned static DHCP reservation `10.0.1.25` on Default corporate LAN in [`terraform/unifi/main.tf`](file:///terraform/unifi/main.tf) via `unifi_client.brother_printer`.
      - Configured authoritative split-horizon DNS records in [`terraform/unifi/dns.tf`](file:///terraform/unifi/dns.tf):
        - `printer.bar2sek.com` -> `10.0.1.25` (physical printer web admin & raw JetDirect port 9100).
        - `printing.bar2sek.com` -> `10.10.20.20` (`pc-node-04` host IP running CUPS).
      - Updated switch port topology documentation in [`docs/201-unifi-network-topology.md`](file:///docs/201-unifi-network-topology.md).
    - **Kubernetes CUPS & Avahi AirPrint Bridge Deployment**:
      - Created dedicated `printing` namespace in [`kubernetes/apps/cups/cups.yaml`](file:///kubernetes/apps/cups/cups.yaml) with privileged pod-security enforcement.
      - Provisioned persistent storage on `rook-ceph-block` (`cups-config-pvc`, 1Gi) to preserve queues across pod restarts.
      - Pinned container workload to worker node `pc-node-04` (`nodeSelector: kubernetes.io/hostname: pc-node-04`) to prevent disk pressure on 16GB SATA SuperDOM control planes.
      - Configured `hostNetwork: true` with Avahi daemon to broadcast link-local Bonjour/mDNS (`_ipp._tcp`, `_universal._sub._ipp._tcp`) across the physical network.
      - Integrated open-source `brlaser` rasterizer driver (`drv:///brlaser.drv/br7065d.ppd`) targeting raw JetDirect socket `socket://10.0.1.25:9100`.
      - Solved CUPS port collision (`Listen *:631` vs `Port 631`) and DNS rebinding host restrictions (`ServerAlias *`) via runtime `PRE_INIT_HOOK`.
    - **Declarative Workstation Configuration & Apple Ecosystem**:
      - Declaratively provisioned default print queue on MacBook Pro via `system.activationScripts.postActivation` in `nix-mac/templates/flake.nix` targeting `ipp://printing.bar2sek.com:631/printers/Brother_DCP-7065DN`.
      - Enabled UniFi gateway Multicast DNS (mDNS) reflector for zero-configuration driverless AirPrint discovery on iOS and iPadOS devices.
      - Documented complete architecture, operational runbook, and diagnostic steps in [`docs/506-cups-airprint-bridge.md`](file:///docs/506-cups-airprint-bridge.md).

---

## 🎯 Immediate Next Actions

1. **Pair Client Devices & Configure Games**:
   - Access Sunshine Web UI at `https://10.10.20.52:47990` to pair Moonlight client on MacBook Pro.
   - Launch Steam Big Picture mode and configure game library.
2. **Deploy Workload Applications (Day-1 SSO Ready)**:
   - Deploy tier 1 self-hosted platform applications: Home Assistant, Immich, Mealie, and TeslaMate.
