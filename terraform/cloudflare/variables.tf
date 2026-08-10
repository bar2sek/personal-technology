variable "platform" {
  type        = string
  description = "Abbreviated platform identifier"
  default     = "clf"
}

variable "env" {
  type        = string
  description = "Deployment environment"
  default     = "prod"
}

variable "region_code" {
  type        = string
  description = "Shortened Region Code"
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

variable "destination_email" {
  type        = string
  description = "Destination inbox email address for forwarding"
  default     = "me@bar2sek.com"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API Token"
  sensitive   = true
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare Account ID"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare DNS Zone ID"
}
