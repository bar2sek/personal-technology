terraform {
  # avm-ptn-alz 0.22 requires Terraform >= 1.12.
  required_version = ">= 1.12.0, < 2.0.0"

  required_providers {
    # Reads the ALZ library (archetypes, policies) and computes the final
    # assignments locally. It makes no changes in Azure itself.
    alz = {
      source  = "Azure/alz"
      version = "~> 0.22"
    }
    # Every Azure resource in this root (management groups, policy, role
    # assignments) is created through ARM by azapi, inside the AVM module.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    # Only used to look up the CI service principals by display name (docs/418).
    # Held on 2.x to match bootstrap/azure.
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
  }

  # Admin-only remote state: the same bootstrap account as bootstrap/azure, but
  # its own state key. Coordinates (incl. the management subscription ID) come
  # from the gitignored backend.hcl, which `just tf-init azure-governance` passes.
  backend "azurerm" {}
}

# ALZ library: Microsoft's pinned release, plus this root's lib/ folder, which
# defines the homelab architecture and the archetype overrides that strip every
# cost-bearing assignment (docs/417). Later references override earlier ones.
provider "alz" {
  library_references = [
    {
      path = "platform/alz"
      ref  = "2026.11.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]

  # The provider warns that it can't compute role assignments for members of the
  # built-in MCSB v2 initiative that take a user-assigned identity (vM_UAI_DINE,
  # mDC_DfSQL_AddUserAssignedIdentity_VM). Checked 2026-11-09: MCSB v2 pins every
  # *_DINE member to AuditIfNotExists, so they never deploy and need no role.
  # Re-check after a library upgrade (docs/417).
  suppress_warning_policy_role_assignments = true
}

# No subscription_id needed: management groups, policy and role assignments at
# MG scope are tenant-level ARM calls. Auth comes from the Azure CLI login.
provider "azapi" {}

provider "azuread" {}
