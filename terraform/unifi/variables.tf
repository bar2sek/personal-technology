variable "platform" {
  type        = string
  description = "Abbreviated platform name"
  default     = "uni"
}

variable "env" {
  type        = string
  description = "Deployment environment"
  default     = "prod"
}

variable "domain_suffix" {
  type        = string
  description = "Domain suffix for internal subnets"
  default     = "homelab.local"
}

variable "unifi_username" {
  type        = string
  description = "UniFi Controller Admin Username"
}

variable "unifi_password" {
  type        = string
  description = "UniFi Controller Admin Password"
  sensitive   = true
}

variable "unifi_api_url" {
  type        = string
  description = "UniFi Controller API URL"
  default     = "https://10.10.10.1"
}

variable "omni_mac_address" {
  type        = string
  description = "MAC address for Omni server static DHCP reservation"
}
