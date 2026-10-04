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
    start   = "10.10.20.100" # 10.10.20.10-99 reserved for static node IPs and MetalLB VIPs (10.10.20.50-60)
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

# 8. Client Reservations: Brother DCP-7065DN Laser Printer (USW-24-G2 Port 23)
resource "unifi_client" "brother_printer" {
  mac            = var.printer_mac_address
  name           = "Brother DCP-7065DN"
  fixed_ip       = var.printer_ip
  allow_existing = true
  note           = "Brother Laser Printer on USW-24-G2 Port 23"
}

# 9. Client Reservations: Kubernetes Bare-Metal Cluster Nodes (VLAN 20: K8S-CONTROL)
resource "unifi_client" "sm_node_01" {
  mac            = var.sm_node_01_k8s_mac
  name           = "sm-node-01"
  fixed_ip       = var.sm_node_01_k8s_ip
  network_id     = unifi_network.k8s_control.id
  allow_existing = true
  note           = "Supermicro SYS-E300-9D Control Plane 1 (10G SFP+ eno7np2)"
}

resource "unifi_client" "sm_node_02" {
  mac            = var.sm_node_02_k8s_mac
  name           = "sm-node-02"
  fixed_ip       = var.sm_node_02_k8s_ip
  network_id     = unifi_network.k8s_control.id
  allow_existing = true
  note           = "Supermicro SYS-E300-9D Control Plane 2 (10G SFP+ eno7np2)"
}

resource "unifi_client" "sm_node_03" {
  mac            = var.sm_node_03_k8s_mac
  name           = "sm-node-03"
  fixed_ip       = var.sm_node_03_k8s_ip
  network_id     = unifi_network.k8s_control.id
  allow_existing = true
  note           = "Supermicro SYS-E300-9D Control Plane 3 (10G SFP+ ens6f0)"
}

resource "unifi_client" "pc_node_04" {
  mac            = var.pc_node_04_k8s_mac
  name           = "pc-node-04"
  fixed_ip       = var.pc_node_04_k8s_ip
  network_id     = unifi_network.k8s_control.id
  allow_existing = true
  note           = "AMD Ryzen 3800X Ceph Storage Worker (10G SFP+ enp43s0f0)"
}


resource "unifi_client" "pc_node_05" {
  mac            = var.pc_node_05_k8s_mac
  name           = "pc-node-05"
  fixed_ip       = var.pc_node_05_k8s_ip
  network_id     = unifi_network.k8s_control.id
  allow_existing = true
  note           = "AMD Ryzen 5900X GPU Worker (2.5G Intel enp12s0)"
}

# 10. Client Reservations: Supermicro Out-of-Band Management (VLAN 10: MGMT-IPMI)
resource "unifi_client" "sm_node_01_ipmi" {
  mac            = var.sm_node_01_ipmi_mac
  name           = "sm-node-01-ipmi"
  fixed_ip       = "10.10.10.11"
  network_id     = unifi_network.mgmt_ipmi.id
  allow_existing = true
  note           = "Supermicro SYS-E300-9D Control Plane 1 Dedicated IPMI BMC"
}

resource "unifi_client" "sm_node_02_ipmi" {
  mac            = var.sm_node_02_ipmi_mac
  name           = "sm-node-02-ipmi"
  fixed_ip       = "10.10.10.12"
  network_id     = unifi_network.mgmt_ipmi.id
  allow_existing = true
  note           = "Supermicro SYS-E300-9D Control Plane 2 Dedicated IPMI BMC"
}

resource "unifi_client" "sm_node_03_ipmi" {
  mac            = var.sm_node_03_ipmi_mac
  name           = "sm-node-03-ipmi"
  fixed_ip       = "10.10.10.13"
  network_id     = unifi_network.mgmt_ipmi.id
  allow_existing = true
  note           = "Supermicro SYS-E300-9D Control Plane 3 Dedicated IPMI BMC"
}

