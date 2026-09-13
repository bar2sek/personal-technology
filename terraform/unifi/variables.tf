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
  default     = "https://10.0.1.1"
}

variable "omni_mac_address" {
  type        = string
  description = "MAC address for Omni server static DHCP reservation (optional if not yet known)"
  default     = ""
}

variable "sm_node_01_ipmi_mac" {
  type        = string
  description = "sm-node-01 (edge01) Supermicro IPMI BMC MAC"
  default     = "3c:ec:ef:44:a4:2c"
}

variable "sm_node_02_ipmi_mac" {
  type        = string
  description = "sm-node-02 (edge02) Supermicro IPMI BMC MAC"
  default     = "3c:ec:ef:6f:da:41"
}

variable "sm_node_03_ipmi_mac" {
  type        = string
  description = "sm-node-03 (main01) Supermicro IPMI BMC MAC"
  default     = "3c:ec:ef:5b:9a:da"
}
