variable "platform" {
  type        = string
  description = "Abbreviated cloud platform name"
  default     = "aws"
}

variable "product" {
  type        = string
  description = "General product or workload name"
  default     = "backups"
}

variable "env" {
  type        = string
  description = "Deployment environment"
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "Target AWS Region"
  default     = "us-east-1"
}

variable "region_code" {
  type        = string
  description = "Shortened AWS Region Code"
  default     = "use1"
}

variable "iteration" {
  type        = string
  description = "Three character iteration sequence"
  default     = "001"
}

variable "domain_name" {
  type        = string
  description = "Primary domain name"
  default     = "bar2sek.com"
}
