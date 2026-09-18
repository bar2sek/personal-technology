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

variable "public_domain" {
  type        = string
  description = "Public domain name for local split-horizon DNS resolution"
  default     = "bar2sek.com"
}

variable "ingress_vip" {
  type        = string
  description = "MetalLB Layer 2 VIP for cluster ingress (ingress-nginx)"
  default     = "10.10.20.50"
}

variable "omni_ip" {
  type        = string
  description = "Static IP address for Sidero Omni bare-metal server"
  default     = "10.10.10.5"
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

variable "printer_ip" {
  type        = string
  description = "Static IP address for Brother DCP-7065DN laser printer"
  default     = "10.0.1.25"
}

variable "printer_mac_address" {
  type        = string
  description = "MAC address for Brother DCP-7065DN laser printer (USW-24-G2 Port 23)"
  default     = "30:05:5c:18:d8:79"
}
