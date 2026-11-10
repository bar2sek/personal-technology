# ------------------------------------------------------------------------------
# Milestone switches (docs/416). Each one is applied separately by the operator.
# ------------------------------------------------------------------------------

variable "policy_enabled" {
  description = <<-EOT
    false = hierarchy only (M2): every management group gets the empty archetype.
    true  = trimmed ALZ policy (M3): the homelab archetypes in lib/.
    Setting it back to false is the rollback: it removes every policy assignment
    and definition in one apply and leaves the management groups in place.
  EOT
  type        = bool
  default     = false
}

variable "policy_enforcement_default" {
  description = "Enforcement mode for every policy assignment. DoNotEnforce still evaluates compliance (audit data), but Deny doesn't block and DINE/Modify don't remediate."
  type        = string
  default     = "DoNotEnforce"

  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.policy_enforcement_default)
    error_message = "Use Default (enforce) or DoNotEnforce."
  }
}

variable "policy_enforcement_by_mg" {
  description = "Per management group override of policy_enforcement_default, keyed by the <category> node (root, platform, identity, landingzones, corp, sandbox, ...). Used to flip to enforce one MG at a time (M5)."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.policy_enforcement_by_mg) : contains(["Default", "DoNotEnforce"], v)])
    error_message = "Values must be Default or DoNotEnforce."
  }
}

variable "ci_rbac_enabled" {
  description = "Create the CI role assignments at MG scope (M4). Turn on only after bootstrap/azure has created the plan app, because its service principal is looked up by name."
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Naming (docs/105)
# ------------------------------------------------------------------------------

variable "platform" {
  description = "Platform node"
  type        = string
  default     = "azure"
}

variable "env" {
  description = "Environment node. Management groups are foundation containers, so always prod (docs/105)."
  type        = string
  default     = "prod"
}

variable "iteration" {
  description = "Iteration suffix of the GitHub Actions apps in bootstrap/azure"
  type        = string
  default     = "001"
}

variable "location" {
  description = "Region for the policy assignments' managed identities (DINE/Modify need one)"
  type        = string
  default     = "centralus"
}

variable "subscription_prefix" {
  description = "Display-name prefix that selects lab subscriptions: subscr-azure-<category>-<product>-<env>-<tenant-4>"
  type        = string
  default     = "subscr-azure-"
}

# ------------------------------------------------------------------------------
# Cost guardrails (custom assignments in lib/, docs/417)
# ------------------------------------------------------------------------------

variable "allowed_locations" {
  description = "Regions where resources and resource groups may be created. 'global' resources are always allowed by the built-in policy."
  type        = list(string)
  default     = ["centralus", "eastus2"]
}

variable "allowed_vm_skus" {
  description = "VM / VMSS sizes allowed anywhere in the lab (AKS node pools are VMSS, so they're covered too)"
  type        = list(string)
  default = [
    "Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms",
    "Standard_B2ats_v2", "Standard_B2als_v2", "Standard_B2s_v2", "Standard_B2ls_v2",
  ]
}

variable "denied_resource_types" {
  description = "Resource types that are expensive by design and never needed in the lab"
  type        = list(string)
  default = [
    "Microsoft.Network/ddosProtectionPlans", # ~$2,944/mo
    "Microsoft.Network/expressRouteCircuits",
    "Microsoft.Network/expressRoutePorts",
    "Microsoft.Network/expressRouteGateways",
    "Microsoft.AVS/privateClouds",
    "Microsoft.Sql/managedInstances",
  ]
}
