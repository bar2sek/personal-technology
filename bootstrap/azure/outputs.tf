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
  description = "CURRENT client secret for the Authentik OpenID Connect Source (newest ring label)"
  value       = azuread_application_password.authentik[local.authentik_secret_current].value
  sensitive   = true
}

output "entra_app_client_secret_versions" {
  description = "Live Authentik client secrets: label => expiry (no secret values)"
  value       = { for k, p in azuread_application_password.authentik : k => p.end_date }
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

output "github_plan_client_id" {
  description = "AZURE_CLIENT_ID for the GitHub Actions PLAN job (pull_request, main): app-azure-github-actions-plan-prod-001"
  value       = azuread_application.github_plan.client_id
}

output "github_apply_client_id" {
  description = "AZURE_CLIENT_ID for the GitHub Actions APPLY job (environment: production): app-azure-github-actions-apply-prod-001"
  value       = azuread_application.github_apply.client_id
}

output "ci_tfstate" {
  description = "Backend coordinates for CI Terraform roots (infra-cloud-deployments). Subscription: management."
  value = {
    resource_group_name  = azurerm_resource_group.ci_tfstate.name
    storage_account_name = azurerm_storage_account.ci_tfstate.name
    container_name       = azurerm_storage_container.ci_tfstate.name
  }
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
