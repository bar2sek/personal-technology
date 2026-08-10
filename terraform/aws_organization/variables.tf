variable "platform" {
  type        = string
  description = "Abbreviated cloud platform name"
  default     = "aws"
}

variable "product" {
  type        = string
  description = "General product or workload name"
  default     = "homelab"
}

variable "env" {
  type        = string
  description = "Deployment environment (prod or nonprod)"
  default     = "prod"
}

variable "root_id" {
  type        = string
  description = "AWS Organizations root ID identifier (leave blank to dynamically extract from AWS Organization)"
  default     = ""
}

variable "destination_email_domain" {
  type        = string
  description = "Domain name used for sub-account email addresses"
  default     = "bar2sek.com"
}
