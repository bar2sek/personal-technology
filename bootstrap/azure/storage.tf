# ==============================================================================
# Admin-only Remote State for the Azure BOOTSTRAP root (management subscription)
# ==============================================================================
# Applies the findings in docs/409 "Known Risk: Bootstrap State":
#   1. Dedicated account, never shared with CI state. This root's state holds the
#      Authentik client secret; PR plan jobs must not be able to read it.
#   2. CI must hold no management-plane rights over it. Since Phase 1 (docs/418)
#      the GitHub Actions identities only hold roles on the workload management
#      groups, plus a blob role on the CI state container (ci_state.tf).
#      Contributor on this account could re-enable shared keys, list them, and
#      read every blob. So it lives in the MANAGEMENT subscription, where CI has
#      no management-plane role at all.
#   3. Versioning on, with noncurrent versions purged after 30 days so old copies
#      of rotated secrets don't accumulate. No immutability (it would block that purge).
#
# Chicken-and-egg: this root creates the account its own state moves into.
# Step 1 applies with local state; step 2 adds `backend "azurerm"` and runs
# `just tf-init azure -migrate-state`. Runbook: docs/412-azure-lab-cost-guardrails.md.
#
# The CI pipeline's own state account is separate: ci_state.tf (docs/418).

resource "azurerm_resource_group" "tfstate" {
  provider = azurerm.management
  name     = local.tfstate_rg_name
  location = var.location
  tags     = merge(local.common_tags, { purpose = "bootstrap-remote-state" })
}

resource "azurerm_storage_account" "tfstate" {
  provider                 = azurerm.management
  name                     = local.tfstate_storage_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # ~$0.02/GB-month; state files are KB-sized
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  # Entra ID only: no account keys or SAS tokens exist to leak.
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false

  # Double encryption at rest (service + infrastructure layer). Free, but can
  # only be set at creation time.
  infrastructure_encryption_enabled = true

  # Public endpoint stays on: a Private Endpoint costs ~$7.30/mo and the
  # workstation reaches Azure over the internet. Access is gated by Entra ID +
  # a data-plane role held only by the operator.
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

  tags = merge(local.common_tags, { purpose = "bootstrap-remote-state" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  # With storage_account_id the container is created through ARM in the
  # provider's subscription, so it needs the management alias like the account.
  provider              = azurerm.management
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# Purge superseded state versions after 30 days (docs/409 finding 3).
resource "azurerm_storage_management_policy" "tfstate" {
  provider           = azurerm.management
  storage_account_id = azurerm_storage_account.tfstate.id

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

# CanNotDelete lock: free, and it stops a stray `az group delete` (or a teardown
# script like the one used on 2026-11-09) from wiping the state. Remove the lock
# deliberately if the account ever needs to go.
resource "azurerm_management_lock" "tfstate" {
  provider   = azurerm.management
  name       = "lock-tfstate-cannotdelete"
  scope      = azurerm_resource_group.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Protects the admin-only bootstrap Terraform state."
}

# Data-plane access for the human operator only. With shared keys disabled, even
# a subscription Owner gets 403 on blobs without a Storage Blob Data role.
resource "azurerm_role_assignment" "tfstate_operator" {
  provider             = azurerm.management
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  description          = "Workstation operator running the bootstrap root locally"
}
