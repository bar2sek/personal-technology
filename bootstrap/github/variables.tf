# ==============================================================================
# GitHub Infrastructure - Input Variables
# ==============================================================================

variable "github_owner" {
  type        = string
  description = "GitHub user or organization account owner"
  default     = "bar2sek"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token (classic with repo scope or fine-grained). Optional if GITHUB_TOKEN env var is set."
  default     = ""
  sensitive   = true
}

variable "repository_name" {
  type        = string
  description = "Name of the dedicated multi-cloud deployment repository"
  default     = "infra-cloud-deployments"
}

variable "repository_visibility" {
  type        = string
  description = "Visibility of the repository (public or private)"
  default     = "private"
}

variable "allow_force_push_main" {
  type        = bool
  description = <<-EOT
    Temporarily permit force-pushes to `main`. Defaults to false; branch
    protection otherwise rejects them with GH006 even for repository admins
    (`enforce_admins` governs reviews and status checks, not force-pushes).

    Set true ONLY for a deliberate history rewrite (e.g. purging a leaked
    secret with git-filter-repo), then set it back to false and re-apply.
  EOT
  default     = false
}

# ------------------------------------------------------------------------------
# Azure OIDC Federation Parameters (Injected into GitHub Environment)
# ------------------------------------------------------------------------------

variable "azure_client_id" {
  type        = string
  description = "Entra ID Application (client) ID for GitHub Actions OIDC"
  default     = ""
}

variable "azure_tenant_id" {
  type        = string
  description = "Microsoft Entra ID Tenant ID"
  default     = ""
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
  default     = ""
}

# ------------------------------------------------------------------------------
# AWS OIDC Federation Parameters (Injected into GitHub Environment)
# ------------------------------------------------------------------------------

variable "aws_role_arn" {
  type        = string
  description = "APPLY role ARN (bootstrap/aws output github_actions_role_arn). Set on the production environment."
  default     = ""
}

variable "aws_plan_role_arn" {
  type        = string
  description = "Read-only PLAN role ARN (bootstrap/aws output github_plan_role_arn). Set at repository scope for pull request plans."
  default     = ""
}

variable "aws_region" {
  type        = string
  description = "Target AWS Region for deployment runner"
  default     = "us-east-2"
}

variable "aws_tf_state_bucket" {
  type        = string
  description = "S3 bucket holding remote Terraform state. Injected as a masked GitHub Actions SECRET (not a variable) because the bucket name embeds the AWS account ID and `run:` commands are echoed into workflow logs."
  default     = ""
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Cloudflare Parameters (Injected into GitHub Actions for GitOps)
# ------------------------------------------------------------------------------

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare Account ID"
  default     = ""
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare DNS Zone ID"
  default     = ""
}

variable "cloudflare_destination_email" {
  type        = string
  description = "Cloudflare destination email for SSO & routing"
  default     = ""
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API Token with Zero Trust, DNS, and Zone permissions"
  default     = ""
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Microsoft Entra ID (Azure AD) Parameters for Cloudflare Access IdP
# ------------------------------------------------------------------------------

variable "entra_client_id" {
  type        = string
  description = "Microsoft Entra ID Application (Client) ID"
  default     = ""
}

variable "entra_tenant_id" {
  type        = string
  description = "Microsoft Entra ID Directory (Tenant) ID"
  default     = ""
}

variable "entra_client_secret" {
  type        = string
  description = "Microsoft Entra ID Application Client Secret"
  default     = ""
  sensitive   = true
}
