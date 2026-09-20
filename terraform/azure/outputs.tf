# ==============================================================================
# Outputs for Microsoft Entra ID & Azure Arc Integration
# ==============================================================================

output "tenant_id" {
  description = "Microsoft Entra ID Tenant ID"
  value       = local.effective_tenant_id
}

output "tenant_4" {
  description = "Four-character root anchor derived from the Azure Tenant ID"
  value       = local.tenant_4
}

output "resource_group_name" {
  description = "Standardized Azure Resource Group name"
  value       = azurerm_resource_group.homelab.name
}

output "log_analytics_workspace_name" {
  description = "Standardized Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.monitoring.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace Resource ID"
  value       = azurerm_log_analytics_workspace.monitoring.id
}

output "arc_cluster_name" {
  description = "Standardized Azure Arc Connected Cluster name"
  value       = azurerm_arc_kubernetes_cluster.talos.name
}

output "arc_cluster_id" {
  description = "Azure Arc Connected Cluster Resource ID"
  value       = azurerm_arc_kubernetes_cluster.talos.id
}

output "entra_app_client_id" {
  description = "Client ID for Authentik OpenID Connect Source (app-azure-authentik-prod-001)"
  value       = azuread_application.authentik.client_id
}

output "entra_app_client_secret" {
  description = "Client Secret for Authentik OpenID Connect Source"
  value       = azuread_application_password.authentik_secret.value
  sensitive   = true
}

output "entra_group_admin_id" {
  description = "Object ID of the homelab admin security group"
  value       = azuread_group.admin.object_id
}

output "entra_group_reader_id" {
  description = "Object ID of the homelab reader security group"
  value       = azuread_group.reader.object_id
}

output "entra_group_member_id" {
  description = "Object ID of the homelab standard member security group"
  value       = azuread_group.member.object_id
}
