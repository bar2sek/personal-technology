# 1. VLAN 10: MGMT-IPMI (Out-of-Band Management & Omni Server)
resource "unifi_network" "mgmt_ipmi" {
  name               = "MGMT-IPMI"
  vlan               = 10
  subnet             = "10.10.10.1/24"
  domain_name        = "mgmt.${var.domain_suffix}"
  setting_preference = "manual"
  multicast_dns      = false

  dhcp_server = {
    enabled = true
    start   = "10.10.10.10"
    stop    = "10.10.10.254"
  }
}

# 2. VLAN 20: K8S-CONTROL (Talos API, Kubelet, etcd)
resource "unifi_network" "k8s_control" {
  name               = "K8S-CONTROL"
  vlan               = 20
  subnet             = "10.10.20.1/24"
  domain_name        = "k8s.${var.domain_suffix}"
  setting_preference = "manual"
  multicast_dns      = false

  dhcp_server = {
    enabled = true
    start   = "10.10.20.10"
    stop    = "10.10.20.254"
  }
}

# 3. VLAN 30: K8S-APPS (Application Pods & Workload Network)
resource "unifi_network" "k8s_apps" {
  name               = "K8S-APPS"
  vlan               = 30
  subnet             = "10.10.30.1/24"
  domain_name        = "apps.${var.domain_suffix}"
  setting_preference = "manual"
  multicast_dns      = false

  dhcp_server = {
    enabled = true
    start   = "10.10.30.10"
    stop    = "10.10.30.254"
  }
}

# 4. VLAN 40: CEPH-STORAGE (10G SFP+ Storage Replication MTU 9000)
resource "unifi_network" "ceph_storage" {
  name               = "CEPH-STORAGE"
  vlan               = 40
  subnet             = "10.10.40.1/24"
  domain_name        = "ceph.${var.domain_suffix}"
  setting_preference = "manual"
  multicast_dns      = false

  dhcp_server = {
    enabled = true
    start   = "10.10.40.10"
    stop    = "10.10.40.254"
  }
}

# 5. VLAN 50: K8S-METALLB (LoadBalancer VIP Pool)
resource "unifi_network" "k8s_metallb" {
  name               = "K8S-METALLB"
  vlan               = 50
  subnet             = "10.10.50.1/24"
  domain_name        = "lb.${var.domain_suffix}"
  setting_preference = "manual"
  multicast_dns      = false

  dhcp_server = {
    enabled = false # VIPs allocated by MetalLB / Ingress
    start   = "10.10.50.10"
    stop    = "10.10.50.254"
  }
}

# 6. VLAN 60: TRUSTED-LAN (Workstations, Laptops, Trusted Household Devices)
resource "unifi_network" "trusted_lan" {
  name               = "TRUSTED-LAN"
  vlan               = 60
  subnet             = "192.168.60.1/24"
  domain_name        = "lan.${var.domain_suffix}"
  setting_preference = "manual"
  multicast_dns      = false

  dhcp_server = {
    enabled = true
    start   = "192.168.60.10"
    stop    = "192.168.60.254"
  }
}

# 7. VLAN 90: IOT-SMART-HOME (Isolated Smart Home Devices, Wi-Fi IoT)
resource "unifi_network" "iot_network" {
  name               = "IOT-SMART-HOME"
  vlan               = 90
  subnet             = "10.10.90.1/24"
  domain_name        = "iot.${var.domain_suffix}"
  setting_preference = "manual"
  multicast_dns      = false

  dhcp_server = {
    enabled = true
    start   = "10.10.90.10"
    stop    = "10.10.90.254"
  }
}

