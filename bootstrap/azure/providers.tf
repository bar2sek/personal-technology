terraform {
  # AVM modules (used from Phase 1 on) require Terraform >= 1.9.
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
    # Deliberately held on 2.x: azuread 3.0 removes `end_date_relative`, which the
    # live Authentik client secret uses. Upgrading carelessly would force a new
    # secret and break Entra ID SSO. Upgrade as its own, planned change.
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
  }

  # Admin-only remote state (Phase 0 step 2, docs/412). Partial configuration:
  # the coordinates, including the management subscription ID, come from the
  # gitignored backend.hcl, which `just tf-init azure` passes automatically.
  # Locking uses a blob lease on the state file.
  backend "azurerm" {}
}

# Default provider: the identity platform subscription (var.subscription_id).
# Holds the GitHub Actions Contributor assignment from entra.tf.
provider "azurerm" {
  features {
    resource_group {
      # Refuse to delete a resource group that still contains resources Terraform
      # doesn't know about (the old setting `false` silently deleted them).
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}

# Management platform subscription: shared platform services, starting with the
# Terraform remote-state account (CAF puts state and monitoring in "management").
provider "azurerm" {
  alias = "management"
  features {}
  subscription_id     = var.management_subscription_id
  storage_use_azuread = true
}

provider "azuread" {
  tenant_id = var.tenant_id
}
