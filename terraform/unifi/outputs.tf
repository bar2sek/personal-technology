output "mgmt_network_id" {
  value       = unifi_network.mgmt_ipmi.id
  description = "ID of MGMT-IPMI network"
}

output "k8s_control_network_id" {
  value       = unifi_network.k8s_control.id
  description = "ID of K8S-CONTROL network"
}

output "k8s_apps_network_id" {
  value       = unifi_network.k8s_apps.id
  description = "ID of K8S-APPS network"
}

output "ceph_storage_network_id" {
  value       = unifi_network.ceph_storage.id
  description = "ID of CEPH-STORAGE network"
}

output "k8s_metallb_network_id" {
  value       = unifi_network.k8s_metallb.id
  description = "ID of K8S-METALLB network"
}

output "trusted_lan_network_id" {
  value       = unifi_network.trusted_lan.id
  description = "ID of TRUSTED-LAN network"
}

output "iot_network_id" {
  value       = unifi_network.iot_network.id
  description = "ID of IOT-SMART-HOME network"
}

output "omni_server_ip" {
  value       = "10.10.10.5"
  description = "Target static IP for Sidero Omni PXE server (VLAN 10)"
}

output "sm_node_01_ipmi_ip" {
  value       = "10.10.10.11"
  description = "Static IP reserved for sm-node-01 IPMI BMC (VLAN 10)"
}

output "sm_node_02_ipmi_ip" {
  value       = "10.10.10.12"
  description = "Static IP reserved for sm-node-02 IPMI BMC (VLAN 10)"
}

output "sm_node_03_ipmi_ip" {
  value       = "10.10.10.13"
  description = "Static IP reserved for sm-node-03 IPMI BMC (VLAN 10)"
}

output "local_dns_ceph" {
  value       = "${unifi_dns_record.ceph.name} -> ${unifi_dns_record.ceph.value}"
  description = "Local split-horizon DNS record for Ceph Dashboard"
}

output "local_dns_omni" {
  value       = "${unifi_dns_record.omni.name} -> ${unifi_dns_record.omni.value}"
  description = "Local split-horizon DNS record for Sidero Omni"
}

output "local_dns_grafana" {
  value       = "${unifi_dns_record.grafana.name} -> ${unifi_dns_record.grafana.value}"
  description = "Local split-horizon DNS record for Grafana"
}

output "local_dns_auth" {
  value       = "${unifi_dns_record.auth.name} -> ${unifi_dns_record.auth.value}"
  description = "Local split-horizon DNS record for Authentik"
}

output "local_dns_printer" {
  value       = "${unifi_dns_record.printer.name} -> ${unifi_dns_record.printer.value}"
  description = "Local split-horizon DNS record for Brother DCP-7065DN Printer"
}

output "local_dns_printing" {
  value       = "${unifi_dns_record.printing.name} -> ${unifi_dns_record.printing.value}"
  description = "Local split-horizon DNS record for CUPS AirPrint Bridge"
}


