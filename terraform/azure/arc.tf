# ==============================================================================
# Azure Arc-Enabled Kubernetes & Zero-Cost Observability Infrastructure
# ==============================================================================

# Dedicated Homelab Resource Group (Mandatory rg- prefix)
resource "azurerm_resource_group" "homelab" {
  name     = local.resource_group_name
  location = var.location

  tags = {
    platform    = var.platform
    product     = var.product
    environment = var.env
    managed_by  = "terraform"
  }
}

# Cost-Guarded Log Analytics Workspace
# Mathematical Guarantee: 0.16 GB/day = ~4.8 GB/month, well within Azure 5 GB/month free tier
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.homelab.location
  resource_group_name = azurerm_resource_group.homelab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  # Enforce hard daily ingestion cap to prevent any unexpected cloud spend
  daily_quota_gb = var.daily_quota_gb

  tags = {
    platform    = var.platform
    product     = var.product
    environment = var.env
    tier        = "free"
    managed_by  = "terraform"
  }
}

# TLS Key Pair for Azure Arc Kubernetes Agent
resource "tls_private_key" "arc_agent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "arc_agent" {
  private_key_pem = tls_private_key.arc_agent.private_key_pem

  subject {
    common_name  = local.arc_cluster_name
    organization = "Homelab"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}

# Azure Arc Connected Kubernetes Cluster Resource
resource "azurerm_arc_kubernetes_cluster" "talos" {
  name                         = local.arc_cluster_name
  resource_group_name          = azurerm_resource_group.homelab.name
  location                     = azurerm_resource_group.homelab.location
  agent_public_key_certificate = base64encode(tls_self_signed_cert.arc_agent.cert_pem)

  identity {
    type = "SystemAssigned"
  }

  tags = {
    platform    = var.platform
    product     = var.product
    environment = var.env
    os          = "talos-linux"
    managed_by  = "terraform"
  }
}

# Role Assignment: Grant Azure Arc cluster permission to write metrics to Log Analytics
resource "azurerm_role_assignment" "arc_monitoring_contributor" {
  scope                = azurerm_log_analytics_workspace.monitoring.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_arc_kubernetes_cluster.talos.identity[0].principal_id
}
