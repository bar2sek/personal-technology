terraform {
  required_version = ">= 1.5.0"

  required_providers {
    unifi = {
      source  = "paultag/unifi"
      version = "~> 0.38.0"
    }
  }
}

provider "unifi" {
  username       = var.unifi_username
  password       = var.unifi_password
  api_url        = var.unifi_api_url
  allow_insecure = true
}
