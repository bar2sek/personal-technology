# ==============================================================================
# Policy exemptions (M5, docs/417 "Trim")
# ==============================================================================
# Enforce-GR-Storage0 on the platform MG would block (Deny) or rewrite (Modify:
# publicNetworkAccess = Disabled) the two Terraform state accounts, cutting off
# the workstation and GitHub-hosted runners. Rule of thumb: FIX what's free,
# EXEMPT only what isn't. Copy scope and ACL bypass are fixed in bootstrap/azure;
# these four members are not fixable without cost or a rebuild:
#
#   Deny-Storage-NetworkRules / -Restrict-NetworkRules  default action Deny needs a
#                                                       Private Endpoint (~$7.30/mo
#                                                       each) + self-hosted runner
#   Modify-Storage-Account-PublicEndpoint               same reason
#   Deny-Storage-ServicesEncryption                     queue/table keyType=Account is
#                                                       create-time only (rebuild)
#
# Category Waiver, not Mitigated: "Mitigated" claims the control's intent is met
# another way; here a public endpoint is ACCEPTED risk, compensated by Entra-only
# auth (shared keys off) and data-plane roles. Scoped to the two resource groups
# and to these four members only: the other 18 storage rules still apply.
# No expiry on purpose: an expired waiver would silently start blocking state
# updates. Review it whenever Phase 2 networking changes (Private Endpoints).

locals {
  state_exempt_rgs = var.policy_enabled ? {
    bootstrap = "rg-azure-tfstate-bootstrap-prod-cus-001"
    ci        = "rg-azure-tfstate-ci-prod-cus-001"
  } : {}

  state_exempt_members = [
    "Deny-Storage-NetworkRules",
    "Deny-Storage-Restrict-NetworkRules",
    "Modify-Storage-Account-PublicEndpoint",
    "Deny-Storage-ServicesEncryption",
  ]
}

resource "azapi_resource" "state_storage_exemption" {
  for_each = local.state_exempt_rgs

  type      = "Microsoft.Authorization/policyExemptions@2022-07-01-preview"
  name      = "Waiver-TfState-Storage-Network"
  parent_id = "/subscriptions/${local.subscription_placement["management"].subscription_id}/resourceGroups/${each.value}"

  body = {
    properties = {
      policyAssignmentId           = "/providers/Microsoft.Management/managementGroups/${local.mg_ids["platform"]}/providers/Microsoft.Authorization/policyAssignments/Enforce-GR-Storage0"
      policyDefinitionReferenceIds = local.state_exempt_members
      exemptionCategory            = "Waiver"
      displayName                  = "Terraform state (${each.key}): public endpoint by design"
      description                  = "Accepted risk: no Private Endpoint (cost) and GitHub-hosted runners have no fixed IPs. Compensated by Entra-only auth (shared keys off) and data-plane RBAC. See personal-technology docs/417."
    }
  }

  # The assignment must exist first; it's created inside the module.
  depends_on = [module.alz]
}
