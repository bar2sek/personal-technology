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
  value       = try(unifi_client.omni_server[0].fixed_ip, "10.10.10.5 (pending MAC)")
  description = "Static IP reserved for Sidero Omni PXE server"
}

output "sm_node_01_ipmi_ip" {
  value       = unifi_client.sm_node_01_ipmi.fixed_ip
  description = "Static IP reserved for sm-node-01 IPMI BMC"
}

output "sm_node_02_ipmi_ip" {
  value       = unifi_client.sm_node_02_ipmi.fixed_ip
  description = "Static IP reserved for sm-node-02 IPMI BMC"
}

output "sm_node_03_ipmi_ip" {
  value       = unifi_client.sm_node_03_ipmi.fixed_ip
  description = "Static IP reserved for sm-node-03 IPMI BMC"
}
