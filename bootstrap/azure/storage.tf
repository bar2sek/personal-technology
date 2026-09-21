# ==============================================================================
# Azure Remote State Storage Backend (Terraform State & Locks)
# ==============================================================================

# Dedicated Resource Group for Terraform State
resource "azurerm_resource_group" "tfstate" {
  name     = local.tfstate_rg_name
  location = var.location

  tags = {
    Environment = var.env
    ManagedBy   = "terraform"
    Purpose     = "remote-state"
  }
}

# Secure Storage Account for Terraform State
resource "azurerm_storage_account" "tfstate" {
  name                     = local.tfstate_storage_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Zero-Trust Security: Enforce Azure AD (Entra ID) authentication only
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Environment = var.env
    ManagedBy   = "terraform"
    Purpose     = "remote-state"
  }
}

# Blob Container for State Files
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Grant GitHub Actions Service Principal read/write access to state blobs via Entra ID
resource "azurerm_role_assignment" "github_actions_tfstate" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
