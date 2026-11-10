data "azurerm_client_config" "current" {}

locals {
  # Resolve effective Tenant ID and dynamically extract first 4 hex characters
  effective_tenant_id = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  tenant_4            = length(local.effective_tenant_id) >= 4 ? substr(local.effective_tenant_id, 0, 4) : "0000"

  # Standardized Entra ID Application & Service Principal Names
  app_authentik_name = "app-${var.platform}-authentik-${var.env}-${var.iteration}"
  sp_authentik_name  = "sp-${var.platform}-authentik-${var.env}-${var.iteration}"
  # GitHub Actions: one identity per job (docs/418). bootstrap/azure-governance
  # looks these up by display name, so keep the two in sync.
  app_github_plan_name  = "app-${var.platform}-github-actions-plan-${var.env}-${var.iteration}"
  app_github_apply_name = "app-${var.platform}-github-actions-apply-${var.env}-${var.iteration}"

  # CI state (docs/418): separate from the admin-only bootstrap account.
  ci_tfstate_rg_name      = "rg-${var.platform}-tfstate-ci-${var.env}-${var.location_short}-${var.iteration}"
  ci_tfstate_storage_name = "stazutfci${var.env}${var.location_short}${var.iteration}"

  # Admin-only bootstrap remote state (per docs/105-naming-conventions.md).
  # Storage account names: 3-24 lowercase alphanumerics, globally unique.
  tfstate_rg_name      = "rg-${var.platform}-tfstate-bootstrap-${var.env}-${var.location_short}-${var.iteration}"
  tfstate_storage_name = "stazubootstrap${var.env}${var.location_short}${var.iteration}"

  # Standardized IDP Access Groups
  # <idp-source>-<platform>-<product>-<env>-<tenant-4>-<permission-set>
  group_admin_name  = "entraid-${var.platform}-${var.product}-${var.env}-${local.tenant_4}-admin"
  group_reader_name = "entraid-${var.platform}-${var.product}-${var.env}-${local.tenant_4}-reader"
  group_member_name = "entraid-authentik-${var.product}-${var.env}-${local.tenant_4}-member"

  # GitHub Immutable ID Format (GitHub Actions OIDC assertion)
  github_repo_immutable = "bar2sek@6226865/infra-cloud-deployments@1378897273"

  # Newest rotation-ring label: YYYY-MM sorts chronologically.
  authentik_secret_current = reverse(sort(tolist(var.authentik_secret_versions)))[0]

  common_tags = {
    platform    = var.platform
    environment = var.env
    managed_by  = "terraform"
    repository  = "personal-technology/bootstrap/azure"
  }
}
