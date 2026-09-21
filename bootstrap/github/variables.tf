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
  description = "AWS IAM Role ARN for GitHub Actions OIDC assume-role"
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
