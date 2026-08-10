output "mgmt_network_id" {
  value       = unifi_network.mgmt_ipmi.id
  description = "ID of MGMT-IPMI network"
}

output "k8s_control_network_id" {
  value       = unifi_network.k8s_control.id
  description = "ID of K8S-CONTROL network"
}

output "ceph_storage_network_id" {
  value       = unifi_network.ceph_storage.id
  description = "ID of CEPH-STORAGE network"
}

output "omni_server_ip" {
  value       = unifi_user.omni_server.fixed_ip
  description = "Static IP reserved for Sidero Omni PXE server"
}
