# ==============================================================================
# CI Terraform state (management subscription), Phase 1 M4, docs/418
# ==============================================================================
# The state store for roots that GitHub Actions applies (infra-cloud-deployments).
# It is a SEPARATE account from the admin-only bootstrap one (docs/409, finding 1):
# CI must never be able to read the Authentik secret in bootstrap state.
#
# Same hardening as storage.tf, with one difference: CI gets DATA-PLANE roles on
# this account's container only, and still no management-plane role anywhere in
# the management subscription. Contributor on the account would let a pipeline
# re-enable shared keys and read every blob; a container-scoped blob role can't.
#
#   apply SP : Storage Blob Data Contributor (writes state, takes the lease lock)
#   plan  SP : Storage Blob Data Reader      (PR plans run with -lock=false)
#
# Why the plan identity can't lock: a lock is a blob lease, a write. Granting it
# write access would also let a PR overwrite or corrupt the state. Speculative
# PR plans don't need a lock; the apply job, which does, holds it.
#
# Cost: LRS, KB-sized state, a few cents a month.

resource "azurerm_resource_group" "ci_tfstate" {
  provider = azurerm.management
  name     = local.ci_tfstate_rg_name
  location = var.location
  tags     = merge(local.common_tags, { purpose = "ci-remote-state" })
}

resource "azurerm_storage_account" "ci_tfstate" {
  provider                 = azurerm.management
  name                     = local.ci_tfstate_storage_name
  resource_group_name      = azurerm_resource_group.ci_tfstate.name
  location                 = azurerm_resource_group.ci_tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  # Entra ID only (also required by the Deny-Storage-SharedKey policy, docs/417).
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false

  infrastructure_encryption_enabled = true

  # GitHub-hosted runners have no fixed IPs and a Private Endpoint costs
  # ~$7.30/mo, so the public endpoint stays on, gated by Entra ID + RBAC.
  public_network_access_enabled = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = merge(local.common_tags, { purpose = "ci-remote-state" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "ci_tfstate" {
  provider              = azurerm.management
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.ci_tfstate.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "ci_tfstate" {
  provider           = azurerm.management
  storage_account_id = azurerm_storage_account.ci_tfstate.id

  rule {
    name    = "expire-noncurrent-state-versions"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      version {
        delete_after_days_since_creation = 30
      }
    }
  }
}

resource "azurerm_management_lock" "ci_tfstate" {
  provider   = azurerm.management
  name       = "lock-tfstate-cannotdelete"
  scope      = azurerm_resource_group.ci_tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Protects the CI Terraform state."
}

# Operator: break-glass access (state surgery, unlocking a stuck lease).
resource "azurerm_role_assignment" "ci_tfstate_operator" {
  provider             = azurerm.management
  scope                = azurerm_storage_account.ci_tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  description          = "Workstation operator: break-glass access to CI state"
}

resource "azurerm_role_assignment" "ci_tfstate_apply" {
  provider             = azurerm.management
  scope                = azurerm_storage_container.ci_tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_apply.object_id
  principal_type       = "ServicePrincipal"
  description          = "GitHub Actions apply job: read/write CI state, take the lease lock"
}

resource "azurerm_role_assignment" "ci_tfstate_plan" {
  provider             = azurerm.management
  scope                = azurerm_storage_container.ci_tfstate.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.github_plan.object_id
  principal_type       = "ServicePrincipal"
  description          = "GitHub Actions plan job: read-only CI state (plans run with -lock=false)"
}
