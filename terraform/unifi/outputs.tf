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
