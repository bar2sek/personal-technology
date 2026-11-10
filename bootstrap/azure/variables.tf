variable "subscription_id" {
  description = "Identity platform subscription ID (default azurerm provider). Set in gitignored terraform.tfvars."
  type        = string
  default     = ""
}

variable "management_subscription_id" {
  description = "Management platform subscription ID (remote-state account). Set in gitignored terraform.tfvars."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra ID Tenant ID (GUID)"
  type        = string
  default     = ""
}

variable "platform" {
  description = "Target cloud platform identifier"
  type        = string
  default     = "azure"
}

variable "product" {
  description = "Product or workload namespace"
  type        = string
  default     = "homelab"
}

variable "env" {
  description = "Deployment environment (prod, nonprod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure geographical deployment region"
  type        = string
  default     = "centralus"
}

variable "location_short" {
  description = "Standardized 3-4 character regional abbreviation"
  type        = string
  default     = "cus"
}

variable "iteration" {
  description = "Three-character resource iteration suffix"
  type        = string
  default     = "001"
}

variable "authentik_redirect_uri" {
  description = "Redirect URI for Authentik OIDC OAuth Source"
  type        = string
  default     = "https://auth.bar2sek.com/source/oauth/callback/entra-id/"
}

variable "authentik_secret_versions" {
  description = "Rotation ring for the Authentik Entra client secret: one live secret per label (YYYY-MM). Add a label to rotate in, remove one to revoke. See docs/415."
  type        = set(string)
  default     = ["2026-11"]

  validation {
    condition     = length(var.authentik_secret_versions) >= 1 && length(var.authentik_secret_versions) <= 2
    error_message = "Keep 1 secret (steady state) or 2 (mid-rotation). An empty set would revoke the live SSO secret."
  }

  validation {
    condition     = alltrue([for v in var.authentik_secret_versions : can(regex("^[0-9]{4}-[0-9]{2}$", v))])
    error_message = "Labels must be YYYY-MM so the newest sorts last."
  }
}

variable "authentik_secret_lifetime" {
  description = "Lifetime of NEWLY created Authentik secrets (timeadd duration, hours). 6 months keeps rotation a regular habit."
  type        = string
  default     = "4380h"
}

variable "github_repo_name" {
  description = "GitHub repository (owner/repo) authorized for OIDC Workload Identity Federation"
  type        = string
  default     = "bar2sek/infra-cloud-deployments"
}

# ------------------------------------------------------------------------------
# Cost guardrails (budgets.tf)
# ------------------------------------------------------------------------------

variable "lab_subscription_prefix" {
  description = "Display-name prefix that selects subscriptions for budgets and anomaly alerts (docs/105: subscr-azure-<category>-<product>-<env>-<tenant-4>)"
  type        = string
  default     = "subscr-azure-"
}

variable "alert_emails" {
  description = "Recipients for budget and cost-anomaly alerts. Personal data: set in gitignored terraform.tfvars only."
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "Set at least one address in terraform.tfvars."
  }
}

variable "default_monthly_budget_by_env" {
  description = "Monthly budget (USD) by the <env> node of the subscription name, for subscriptions not in monthly_budgets"
  type        = map(number)
  default = {
    prod    = 5
    nonprod = 5
    lab     = 3
  }
}

variable "monthly_budget_fallback" {
  description = "Monthly budget (USD) when a subscription name has no recognised <env> node"
  type        = number
  default     = 5
}

variable "monthly_budgets" {
  description = "Per-subscription monthly budget overrides (USD), keyed by the <category> node (identity, management, connectivity, ...)"
  type        = map(number)
  default = {
    # Connectivity hosts the on-demand Firewall / VPN Gateway labs.
    connectivity = 15
    # Management hosts state, monitoring, backup and (later) app workloads.
    management = 10
  }
}

variable "budget_start_date" {
  description = "First day of the month the budgets start (RFC3339). Must be the first of a month and not before the current month at creation."
  type        = string
  default     = "2026-11-01T00:00:00Z"
}
