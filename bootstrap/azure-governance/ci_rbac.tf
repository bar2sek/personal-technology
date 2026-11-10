# ==============================================================================
# CI RBAC at management group scope (M4, docs/418)
# ==============================================================================
# The identities live in bootstrap/azure (Entra apps + GitHub OIDC trust). This
# root only decides WHERE they get rights, because the scopes are the management
# groups it owns.
#
#   plan  identity (pull_request, main):  Reader       on landingzones + sandbox
#   apply identity (environment:production): Contributor on landingzones + sandbox
#
# Neither gets any role on the platform MGs. In particular nothing covers the
# management subscription, where the admin-only bootstrap state lives (docs/412).
# Contributor can't write role assignments, so CI also can't grant itself more.
# ==============================================================================

data "azuread_service_principal" "github_plan" {
  count        = var.ci_rbac_enabled ? 1 : 0
  display_name = "app-${var.platform}-github-actions-plan-${var.env}-${var.iteration}"
}

data "azuread_service_principal" "github_apply" {
  count        = var.ci_rbac_enabled ? 1 : 0
  display_name = "app-${var.platform}-github-actions-apply-${var.env}-${var.iteration}"
}

locals {
  ci_workload_mgs = ["landingzones", "sandbox"]

  ci_role_assignments = var.ci_rbac_enabled ? merge(
    {
      for c in local.ci_workload_mgs : "github-plan-reader-${c}" => {
        management_group_name      = local.mg_ids[c]
        role_definition_id_or_name = "Reader"
        principal_id               = data.azuread_service_principal.github_plan[0].object_id
        principal_type             = "ServicePrincipal"
        description                = "GitHub Actions plan identity (PR plans), infra-cloud-deployments"
      }
    },
    {
      for c in local.ci_workload_mgs : "github-apply-contributor-${c}" => {
        management_group_name      = local.mg_ids[c]
        role_definition_id_or_name = "Contributor"
        principal_id               = data.azuread_service_principal.github_apply[0].object_id
        principal_type             = "ServicePrincipal"
        description                = "GitHub Actions apply identity (environment: production), infra-cloud-deployments"
      }
    },
  ) : {}
}
