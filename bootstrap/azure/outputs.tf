# ==============================================================================
# Outputs: Entra ID identity, remote state, cost guardrails
# ==============================================================================

output "tenant_id" {
  description = "Microsoft Entra ID Tenant ID"
  value       = local.effective_tenant_id
  sensitive   = true
}

output "tenant_4" {
  description = "Four-character root anchor derived from the Azure Tenant ID"
  value       = local.tenant_4
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

# ------------------------------------------------------------------------------
# GitHub Actions CI/CD & Remote State Storage
# ------------------------------------------------------------------------------

output "github_actions_client_id" {
  description = "Client ID for GitHub Actions OIDC Workload Identity Federation (app-azure-github-actions-prod-001)"
  value       = azuread_application.github_actions.client_id
}

output "github_actions_sp_object_id" {
  description = "Enterprise Service Principal Object ID for GitHub Actions"
  value       = azuread_service_principal.github_actions.object_id
}

output "tfstate_resource_group_name" {
  description = "Resource group holding the admin-only bootstrap state (management subscription)"
  value       = azurerm_resource_group.tfstate.name
}

output "tfstate_storage_account_name" {
  description = "Storage account name holding Terraform remote state"
  value       = azurerm_storage_account.tfstate.name
}

output "tfstate_container_name" {
  description = "Storage container name for Terraform remote state"
  value       = azurerm_storage_container.tfstate.name
}

# ------------------------------------------------------------------------------
# Cost Guardrails
# ------------------------------------------------------------------------------

output "budgets" {
  description = "Monthly budget (USD) per lab subscription"
  value       = { for k, b in azurerm_consumption_budget_subscription.lab : k => b.amount }
}
