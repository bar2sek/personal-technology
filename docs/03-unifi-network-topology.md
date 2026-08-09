# UniFi Network Topology & VLAN Architecture

This document details the physical network topology, switch interconnects, WAN configuration, and VLAN layout for the Talos Linux homelab cluster.

---

## 🌐 Physical Network Infrastructure

### Core Hardware

- **Gateway / Router**: Ubiquiti UniFi Dream Machine Pro (UDM-Pro)
- **WAN Interface**: 3.5 Gbps Google Fiber connected to **UDM-Pro Port 11 (SFP+)** via TP-Link `TL-SM5310-T` SFP+ to 10GBASE-T Transceiver (negotiated at 10G).
- **Core Switches**: 2x **UniFi Switch Aggregation (USW-Aggregation)**
  - Inter-Switch Backbone: **20 Gbps LAG (2-Port 10G SFP+ Link Aggregation)** between Aggregation Switch 1 and Aggregation Switch 2.
  - Uplink: UDM-Pro Port 10 (SFP+ 10G) connected to USW-Aggregation fabric.
- **Access Switch**: 1x **UniFi Switch 24 (USW-24-G2)** (24x 1GbE RJ45 + 2x 1G SFP)
  - Dedicated access switch for Out-of-Band IPMI/BMC ports, Omni Mini PC 1GbE NIC, and 1GbE management interfaces.
  - Uplink: SFP 1G link to USW-Aggregation fabric.
- **Node 05 Multi-Gig Uplink**: `pc-node-05` 2.5GbE Onboard RJ45 connected to **USW-Aggregation** SFP+ port via TP-Link Multi-Gig SFP+ 10GBASE-T Transceiver (auto-negotiated at **2.5 Gbps**).

---

## 📐 Network Architecture Diagram

```
                     +---------------------------------------+
                     |         3.5 Gbps Google Fiber         |
                     +---------------------------------------+
                                         | (10GBASE-T RJ45)
                                         v
                     +---------------------------------------+
                     |          UDM-Pro (Port 11 SFP+)       |
                     |  Port 10 (10G SFP+)                   |
                     +---------------------------------------+
                                         | 10G SFP+ DAC/Fiber
                                         v
                     +---------------------------------------+
                     |         USW-Aggregation #1            |
                     +---------------------------------------+
                        || 20 Gbps LAG          \ 1G SFP Uplink
                     +---------------------+  +----------------------+
                     | USW-Aggregation #2  |  | USW-24-G2 (1GbE)     |
                     +---------------------+  +----------------------+
                        /   |      \     \        |            \
             +------------+ +----+ +---+ +-----+ +--------+ +------------+
             |sm-node-01/2| |sm03| |pc4| |pc05 | | IPMIs  | | omni-server|
             |(Dual 10G)  | |(10G| |(10| |(2.5G| | (1G)   | | (1G)       |
             +------------+ +----+ +---+ +-----+ +--------+ +------------+
```

---

## 🏷 VLAN & Subnet Architecture (Proposed)

To ensure maximum security, QOS, and high storage performance for Rook-Ceph, we propose the following VLAN layout in UniFi:

| VLAN ID | Name | Subnet Range | Purpose & Traffic Description |
| :--- | :--- | :--- | :--- |
| **VLAN 10** | `MGMT-IPMI` | `10.10.10.0/24` | Out-of-Band Management (Supermicro IPMI / BMC ports, UDM-Pro admin, Omni Mini PC). |
| **VLAN 20** | `K8S-CONTROL` | `10.10.20.0/24` | Talos API (`6443`), Kubelet, etcd (`2379/2380`), and Omni provisioning traffic. |
| **VLAN 30** | `K8S-PODS-SVC` | `10.10.30.0/24` | Kubernetes Pod CNI network (Cilium / Calico) & Service nodeports. |
| **VLAN 40** | `CEPH-STORAGE` | `10.10.40.0/24` | Dedicated **10G SFP+** East-West storage replication network for Rook-Ceph OSDs. |
| **VLAN 50** | `K8S-METALLB` | `10.10.50.0/24` | Ingress LoadBalancer VIP pool allocated by MetalLB / Cilium BGP to route traffic from UniFi. |

---

## ⚙️ UniFi Configuration Notes

1. **Jumbo Frames (MTU 9000)**: Enable Jumbo Frames on the `CEPH-STORAGE` VLAN and USW-Aggregation switch ports connected to the nodes to maximize 10GbE Ceph throughput and lower CPU overhead.
2. **BGP Routing (Optional)**: If using Cilium for CNI, UniFi Dream Machine Pro / USW-Aggregation supports BGP routing to dynamically advertise Kubernetes LoadBalancer IPs directly into the network.

---

## 🤖 Infrastructure as Code (Terraform UniFi Provider)

All UniFi networks, VLANs, static DHCP reservations, and firewall rules can be declaratively managed using Terraform via the [UniFi Terraform Provider](https://registry.terraform.io/providers/paultag/unifi/latest/docs).

### Example `unifi_network` Terraform Resource:

```hcl
resource "unifi_network" "ceph_storage" {
  name          = "CEPH-STORAGE"
  purpose       = "corporate"
  vlan_id       = 40
  subnet        = "10.10.40.1/24"
  dhcp_start    = "10.10.40.10"
  dhcp_stop     = "10.10.40.254"
  dhcp_enabled  = true
  domain_name   = "ceph.homelab.local"
}

resource "unifi_user" "sm_node_01" {
  mac  = "00:25:90:xx:xx:xx"
  name = "sm-node-01-10g"
  fixed_ip = "10.10.40.11"
  network_id = unifi_network.ceph_storage.id
}
```
