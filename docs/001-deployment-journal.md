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

## 🎯 Immediate Next Actions

1. **Attach Workers to `homelab-k8s`**:
   - In Sidero Omni Web UI (`https://10.10.10.5`) under **Clusters** ➔ **`homelab-k8s`**, create a Worker MachineSet (or assign available machines `pc-node-04` and `pc-node-05` to workers).
   - Alternatively, use `omnictl` CLI once authenticated to link the machines.
2. **Download Production Kubeconfig & Verify Nodes**:
   - Download kubeconfig via Omni Web UI (or `omnictl cluster kubeconfig homelab-k8s`).
   - Run `kubectl get nodes -o wide` to verify all 5 nodes report `Ready`.
3. **Export Declarative Cluster Template (Zero-ClickOps)**:
   - Export cluster template via `omnictl cluster template export homelab-k8s > talos/cluster-template.yaml` for declarative GitOps tracking.

