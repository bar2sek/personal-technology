data "azurerm_client_config" "current" {}

locals {
  # Resolve effective Tenant ID and dynamically extract first 4 hex characters
  effective_tenant_id = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  tenant_4            = length(local.effective_tenant_id) >= 4 ? substr(local.effective_tenant_id, 0, 4) : "0000"

  # Standardized Azure Resource Names (per docs/105-naming-conventions.md)
  # <abbreviation>-azure-<product>-<env>-<region-code>-<iteration>
  resource_group_name  = "rg-${var.platform}-${var.product}-${var.env}-${var.location_short}-${var.iteration}"
  log_analytics_name   = "law-${var.platform}-monitoring-${var.env}-${var.location_short}-${var.iteration}"
  arc_cluster_name     = "arc-${var.platform}-talos-${var.env}-${var.location_short}-${var.iteration}"
  data_collection_rule = "dcr-${var.platform}-containerinsights-${var.env}-${var.location_short}-${var.iteration}"

  # Standardized Entra ID Application & Service Principal Names
  app_authentik_name = "app-${var.platform}-authentik-${var.env}-${var.iteration}"
  sp_authentik_name  = "sp-${var.platform}-authentik-${var.env}-${var.iteration}"

  # Standardized IDP Access Groups
  # <idp-source>-<platform>-<product>-<env>-<tenant-4>-<permission-set>
  group_admin_name  = "entraid-${var.platform}-${var.product}-${var.env}-${local.tenant_4}-admin"
  group_reader_name = "entraid-${var.platform}-${var.product}-${var.env}-${local.tenant_4}-reader"
  group_member_name = "entraid-authentik-${var.product}-${var.env}-${local.tenant_4}-member"

  # Standardized Hierarchy Labels (Reference)
  management_group_name = "mg-${var.platform}-infrastructure-${var.env}-${local.tenant_4}"
  subscription_name     = "subcr-${var.platform}-${var.product}-${var.env}-${local.tenant_4}"
}
