# UniFi Network Infrastructure Terraform Module
# Manages Networks, VLANs, Switch Port Profiles, and Static DHCP Reservations

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    unifi = {
      source  = "paultag/unifi"
      version = "~> 0.38.0"
    }
  }
}

provider "unifi" {
  username = var.unifi_username
  password = var.unifi_password
  api_url  = var.unifi_api_url
  allow_insecure = true
}

# 1. VLAN 10: MGMT-IPMI (Out-of-Band Management & Omni Server)
resource "unifi_network" "mgmt_ipmi" {
  name         = "MGMT-IPMI"
  purpose      = "corporate"
  vlan_id      = 10
  subnet       = "10.10.10.1/24"
  dhcp_start   = "10.10.10.10"
  dhcp_stop    = "10.10.10.254"
  dhcp_enabled = true
  domain_name  = "mgmt.homelab.local"
}

# 2. VLAN 20: K8S-CONTROL (Talos API, Kubelet, etcd)
resource "unifi_network" "k8s_control" {
  name         = "K8S-CONTROL"
  purpose      = "corporate"
  vlan_id      = 20
  subnet       = "10.10.20.1/24"
  dhcp_start   = "10.10.20.10"
  dhcp_stop    = "10.10.20.254"
  dhcp_enabled = true
  domain_name  = "k8s.homelab.local"

  # IPv6 Prefix Delegation (Google Fiber UDM-Pro)
  ipv6_interface_type = "pd"
  ipv6_pd_start       = "::2"
  ipv6_pd_stop        = "::7d1"
  dhcp_v6_enabled     = true
}

# 3. VLAN 40: CEPH-STORAGE (10G SFP+ Storage Replication MTU 9000)
resource "unifi_network" "ceph_storage" {
  name         = "CEPH-STORAGE"
  purpose      = "corporate"
  vlan_id      = 40
  subnet       = "10.10.40.1/24"
  dhcp_start   = "10.10.40.10"
  dhcp_stop    = "10.10.40.254"
  dhcp_enabled = true
  domain_name  = "ceph.homelab.local"
}

# Static DHCP Reservation: Omni Server
resource "unifi_user" "omni_server" {
  mac        = var.omni_mac_address
  name       = "omni-server"
  fixed_ip   = "10.10.10.5"
  network_id = unifi_network.mgmt_ipmi.id
}
