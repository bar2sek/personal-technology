variable "subscription_id" {
  description = "Azure Subscription ID for resource deployment"
  type        = string
  default     = ""
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

variable "daily_quota_gb" {
  description = "Log Analytics daily ingestion ceiling in GB (0.16 GB = ~4.8 GB/mo to ensure $0 Free Tier)"
  type        = number
  default     = 0.16
}

variable "github_repo_name" {
  description = "GitHub repository (owner/repo) authorized for OIDC Workload Identity Federation"
  type        = string
  default     = "bar2sek/infra-cloud-deployments"
}
