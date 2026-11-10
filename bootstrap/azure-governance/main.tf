# ==============================================================================
# Azure Mini Enterprise, Phase 1: management groups + Azure Policy (docs/416)
# ==============================================================================
# Applied locally by the operator (admin-only), never by CI: creating management
# groups, policy and MG-scope role assignments needs Owner-level rights at the
# lab root, which a pipeline must not hold (docs/412).
#
#   just tf-plan  azure-governance
#   just tf-apply azure-governance
# ==============================================================================

data "azapi_client_config" "current" {}

# All subscriptions the operator can see. Selected by display name below, so no
# subscription IDs appear in code or tfvars.
data "azapi_resource_list" "subscriptions" {
  type                   = "Microsoft.Resources/subscriptions@2022-12-01"
  parent_id              = "/"
  response_export_values = ["value"]
}

locals {
  tenant_id    = data.azapi_client_config.current.tenant_id
  tenant_4     = substr(local.tenant_id, 0, 4)
  architecture = var.policy_enabled ? "homelab" : "homelab-hierarchy"

  # mg-<platform>-<category>-<env>-<tenant-4> (docs/105). The IDs are literal in
  # lib/*.alz_architecture_definition.yaml; this map must produce the same IDs.
  mg_categories = ["homelab", "platform", "identity", "management", "connectivity", "security", "landingzones", "corp", "online", "sandbox", "decommissioned"]
  mg_ids        = { for c in local.mg_categories : c => "mg-${var.platform}-${c}-${var.env}-${local.tenant_4}" }

  # subscr-azure-<category>-<product>-<env>-<tenant-4>: the <category> node picks
  # the management group. A category without a matching MG stays where it is.
  subscriptions = {
    for s in data.azapi_resource_list.subscriptions.output.value :
    s.displayName => s.subscriptionId
    if startswith(s.displayName, var.subscription_prefix) && s.state == "Enabled"
  }
  subscription_placement = {
    for name, id in local.subscriptions : split("-", name)[2] => {
      subscription_id       = id
      management_group_name = local.mg_ids[split("-", name)[2]]
    } if contains(keys(local.mg_ids), split("-", name)[2]) && !contains(["homelab", "platform", "landingzones"], split("-", name)[2])
  }
}

# Same architecture the module reads, used here only to list every assignment
# name per management group so enforcement mode and parameters can be set on
# all of them without hand-maintaining a list.
data "alz_architecture" "inventory" {
  name                     = local.architecture
  root_management_group_id = local.tenant_id
  location                 = var.location
}

locals {
  # Reverse map: MG ID -> <category>, to look up policy_enforcement_by_mg.
  mg_category_by_id = { for c, id in local.mg_ids : id => c }

  # Parameters forced on specific assignments wherever they appear.
  # Keys: assignment name. Values: parameter name -> jsonencode({ value = ... }).
  assignment_parameters = {
    # Hidden cost traps: these ALZ "guardrail" initiatives each contain a DINE
    # member that switches on a PAID per-resource Defender plan (docs/417).
    "Enforce-GR-Storage0"    = { storageThreatProtection = jsonencode({ value = "Disabled" }) }
    "Enforce-GR-CosmosDb0"   = { cosmosDbAtp = jsonencode({ value = "Disabled" }) }
    "Enforce-GR-MySQL0"      = { mySqlAdvThreatProtection = jsonencode({ value = "Disabled" }) }
    "Enforce-GR-PostgreSQL0" = { postgreSqlAdvThreatProtection = jsonencode({ value = "Disabled" }) }
    "Enforce-GR-SQL0"        = { sqlManagedDefender = jsonencode({ value = "Disabled" }) }
    "Enforce-GR-Synapse0"    = { synapseDefender = jsonencode({ value = "Disabled" }) }
    # Would attach every VNet to a DDoS Network Protection plan.
    "Enforce-GR-Network0" = { vnetModifyDdos = jsonencode({ value = "Disabled" }) }

    # Custom cost guardrails (lib/): values come from variables.
    "Allowed-Locations"    = { listOfAllowedLocations = jsonencode({ value = var.allowed_locations }) }
    "Allowed-RG-Locations" = { listOfAllowedLocations = jsonencode({ value = var.allowed_locations }) }
    "Allowed-VM-SKUs"      = { listOfAllowedSKUs = jsonencode({ value = var.allowed_vm_skus }) }
    "Deny-Costly-ResTypes" = { listOfResourceTypesNotAllowed = jsonencode({ value = var.denied_resource_types }) }
  }

  policy_assignments_to_modify = {
    for mg in data.alz_architecture.inventory.management_groups : mg.id => {
      policy_assignments = {
        for name in keys(mg.policy_assignments) : name => {
          enforcement_mode = lookup(var.policy_enforcement_by_mg, lookup(local.mg_category_by_id, mg.id, ""), var.policy_enforcement_default)
          parameters       = lookup(local.assignment_parameters, name, null)
        }
      }
    } if length(mg.policy_assignments) > 0
  }
}

# Fail the plan, not the apply, if lib/ and the naming locals disagree (e.g. a
# different tenant, whose first 4 characters differ from the literal IDs).
resource "terraform_data" "naming_guard" {
  input = local.architecture

  lifecycle {
    precondition {
      condition     = toset([for mg in data.alz_architecture.inventory.management_groups : mg.id]) == toset(values(local.mg_ids))
      error_message = "Management group IDs in lib/*.alz_architecture_definition.yaml don't match mg-${var.platform}-<category>-${var.env}-${local.tenant_4}."
    }
  }
}

module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.22.0"

  architecture_name  = local.architecture
  parent_resource_id = local.tenant_id # child of the Tenant Root Group
  location           = var.location

  # AVM modules send usage telemetry to Microsoft by default (a tracking
  # deployment). Off: nothing about this tenant leaves without a reason.
  enable_telemetry = false

  subscription_placement = local.subscription_placement
  # On destroy, move subscriptions back to the tenant's default MG instead of
  # leaving them in a group that is about to be deleted.
  subscription_placement_destroy_behavior = "default"

  policy_assignments_to_modify      = local.policy_assignments_to_modify
  management_group_role_assignments = local.ci_role_assignments
}
