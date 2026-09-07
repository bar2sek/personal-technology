# 1. VLAN 10: MGMT-IPMI (Out-of-Band Management & Omni Server)
resource "unifi_network" "mgmt_ipmi" {
  name         = "MGMT-IPMI"
  purpose      = "corporate"
  vlan_id      = 10
  subnet       = "10.10.10.1/24"
  dhcp_start   = "10.10.10.10"
  dhcp_stop    = "10.10.10.254"
  dhcp_enabled = true
  domain_name  = "mgmt.${var.domain_suffix}"
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
  domain_name  = "k8s.${var.domain_suffix}"

  # IPv6 Prefix Delegation (Google Fiber UDM-Pro)
  ipv6_interface_type = "pd"
  ipv6_pd_start       = "::2"
  ipv6_pd_stop        = "::7d1"
  dhcp_v6_enabled     = true
}

# 3. VLAN 30: K8S-APPS (Application Pods & Workload Network)
resource "unifi_network" "k8s_apps" {
  name         = "K8S-APPS"
  purpose      = "corporate"
  vlan_id      = 30
  subnet       = "10.10.30.1/24"
  dhcp_start   = "10.10.30.10"
  dhcp_stop    = "10.10.30.254"
  dhcp_enabled = true
  domain_name  = "apps.${var.domain_suffix}"
}

# 4. VLAN 40: CEPH-STORAGE (10G SFP+ Storage Replication MTU 9000)
resource "unifi_network" "ceph_storage" {
  name         = "CEPH-STORAGE"
  purpose      = "corporate"
  vlan_id      = 40
  subnet       = "10.10.40.1/24"
  dhcp_start   = "10.10.40.10"
  dhcp_stop    = "10.10.40.254"
  dhcp_enabled = true
  domain_name  = "ceph.${var.domain_suffix}"
}

# 5. VLAN 50: K8S-METALLB (LoadBalancer VIP Pool)
resource "unifi_network" "k8s_metallb" {
  name         = "K8S-METALLB"
  purpose      = "corporate"
  vlan_id      = 50
  subnet       = "10.10.50.1/24"
  dhcp_enabled = false # VIPs allocated by MetalLB / Ingress
  domain_name  = "lb.${var.domain_suffix}"
}

# 6. VLAN 60: TRUSTED-LAN (Workstations, Laptops, Trusted Household Devices)
resource "unifi_network" "trusted_lan" {
  name         = "TRUSTED-LAN"
  purpose      = "corporate"
  vlan_id      = 60
  subnet       = "192.168.60.1/24"
  dhcp_start   = "192.168.60.10"
  dhcp_stop    = "192.168.60.254"
  dhcp_enabled = true
  domain_name  = "lan.${var.domain_suffix}"
}

# 7. VLAN 90: IOT-SMART-HOME (Isolated Smart Home Devices, Wi-Fi IoT)
resource "unifi_network" "iot_network" {
  name         = "IOT-SMART-HOME"
  purpose      = "corporate"
  vlan_id      = 90
  subnet       = "10.10.90.1/24"
  dhcp_start   = "10.10.90.10"
  dhcp_stop    = "10.10.90.254"
  dhcp_enabled = true
  domain_name  = "iot.${var.domain_suffix}"
}

# Static DHCP Reservation: Omni Server
resource "unifi_user" "omni_server" {
  mac        = var.omni_mac_address
  name       = "omni-server"
  fixed_ip   = "10.10.10.5"
  network_id = unifi_network.mgmt_ipmi.id
}

# Switch Port Profile: 10G SFP+ Storage & Node Trunk (MTU 9000 Tagged)
resource "unifi_port_profile" "k8s_node_trunk" {
  name                    = "K8S-Node-Trunk"
  native_networkconf_id   = unifi_network.k8s_control.id
  tagged_networkconf_ids  = [
    unifi_network.k8s_apps.id,
    unifi_network.ceph_storage.id,
    unifi_network.k8s_metallb.id
  ]
}

# Switch Port Profile: Dedicated Ceph Storage 10G
resource "unifi_port_profile" "ceph_storage_access" {
  name                  = "Ceph-Storage-Access"
  native_networkconf_id = unifi_network.ceph_storage.id
}

# Firewall Rule: Block IoT Devices from Accessing Kubernetes Control Subnet
resource "unifi_firewall_rule" "drop_iot_to_k8s_control" {
  name           = "drop-iot-to-k8s-control"
  action         = "drop"
  ruleset        = "LAN_IN"
  rule_index     = 2001
  protocol       = "all"
  src_network_id = unifi_network.iot_network.id
  dst_network_id = unifi_network.k8s_control.id
}

# Firewall Rule: Block IoT Devices from Accessing Out-of-Band IPMI Management
resource "unifi_firewall_rule" "drop_iot_to_mgmt" {
  name           = "drop-iot-to-mgmt"
  action         = "drop"
  ruleset        = "LAN_IN"
  rule_index     = 2002
  protocol       = "all"
  src_network_id = unifi_network.iot_network.id
  dst_network_id = unifi_network.mgmt_ipmi.id
}
