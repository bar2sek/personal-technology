variable "aws_region" {
  description = "Target AWS Region"
  type        = string
  default     = "us-east-2"
}

variable "region_code" {
  description = "Shortened AWS Region Code (use2 for us-east-2)"
  type        = string
  default     = "use2"
}

variable "platform" {
  description = "Platform identifier"
  type        = string
  default     = "aws"
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "iteration" {
  description = "Resource iteration sequence"
  type        = string
  default     = "001"
}

variable "github_repo_name" {
  description = "Target GitHub repository for OIDC federation (owner/repo)"
  type        = string
  default     = "bar2sek/infra-cloud-deployments"
}
