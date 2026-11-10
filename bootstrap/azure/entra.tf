# ==============================================================================
# Microsoft Entra ID - App Registration, Service Principal & Groups
# ==============================================================================

# Entra ID App Registration for Authentik IdP Broker
resource "azuread_application" "authentik" {
  display_name     = local.app_authentik_name
  sign_in_audience = "AzureADMyOrg"

  web {
    redirect_uris = [
      var.authentik_redirect_uri
    ]
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read (Delegated)
      type = "Scope"
    }
  }

  group_membership_claims = ["SecurityGroup"]
}

# Enterprise Application (Service Principal) for Authentik
resource "azuread_service_principal" "authentik" {
  client_id                    = azuread_application.authentik.client_id
  app_role_assignment_required = false
}

# ------------------------------------------------------------------------------
# Client secrets for the Authentik OpenID Connect OAuth Source (rotation ring)
# ------------------------------------------------------------------------------
# One secret per label in var.authentik_secret_versions. Zero-downtime rotation
# (runbook: docs/415-entra-client-secret-rotation.md):
#   1. ADD a new label and apply        -> old + new secret are both valid
#   2. Put the new secret in Authentik, test sign-in
#   3. REMOVE the old label and apply   -> old secret revoked in Entra ID
# The newest label (sorted) is the one exposed by output.entra_app_client_secret.
resource "azuread_application_password" "authentik" {
  for_each = var.authentik_secret_versions

  application_id = azuread_application.authentik.id
  display_name   = "Authentik SSO OIDC Secret ${each.key}"

  # Explicit expiry, computed once at creation. azuread 2.53 accepted
  # end_date_relative but Entra applied its 2-year default anyway (2026-11
  # secret), so the end date is now sent as an absolute timestamp.
  end_date = timeadd(timestamp(), var.authentik_secret_lifetime)

  lifecycle {
    # Every argument of azuread_application_password (v2) forces replacement.
    # Without this, changing the lifetime or naming scheme would destroy and
    # recreate EVERY live secret at once: an instant SSO outage. end_date is
    # here too because timestamp() changes on every plan. New settings apply
    # to newly added labels only, which is exactly what rotation wants.
    ignore_changes = [display_name, end_date, end_date_relative]
  }
}

# ------------------------------------------------------------------------------
# Standardized IDP Access Groups
# ------------------------------------------------------------------------------

resource "azuread_group" "admin" {
  display_name     = local.group_admin_name
  security_enabled = true
  description      = "Full administrative access to hybrid homelab services and Azure Arc"
}

resource "azuread_group" "reader" {
  display_name     = local.group_reader_name
  security_enabled = true
  description      = "Auditor and read-only access to hybrid homelab workloads"
}

resource "azuread_group" "member" {
  display_name     = local.group_member_name
  security_enabled = true
  description      = "Standard authorized SSO user for self-hosted apps (Immich, Mealie, etc.)"
}

# ------------------------------------------------------------------------------
# Entra ID App Registration & OIDC Federation for GitHub Actions CI/CD
# ------------------------------------------------------------------------------

resource "azuread_application" "github_actions" {
  display_name     = local.app_github_actions_name
  sign_in_audience = "AzureADMyOrg"
  description      = "Workload identity for GitHub Actions CI/CD in ${var.github_repo_name}"
}

resource "azuread_service_principal" "github_actions" {
  client_id                    = azuread_application.github_actions.client_id
  app_role_assignment_required = false
  description                  = "Enterprise service principal for GitHub Actions deployment runner"
}

# OIDC Trust for GitHub Environment 'production' (Immutable ID format)
resource "azuread_application_federated_identity_credential" "github_env_prod" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-env-production"
  description    = "OIDC trust for GitHub Actions production environment deployment"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo_immutable}:environment:production"
}

# OIDC Trust for Pull Requests (PR Validation & Planning - Immutable ID format)
resource "azuread_application_federated_identity_credential" "github_pr" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-pull-request"
  description    = "OIDC trust for GitHub Actions pull request validation and planning"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo_immutable}:pull_request"
}

# OIDC Trust for Branch 'main' (Direct workflow dispatch / push - Immutable ID format)
resource "azuread_application_federated_identity_credential" "github_branch_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-branch-main"
  description    = "OIDC trust for GitHub Actions main branch runs"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo_immutable}:ref:refs/heads/main"
}

# Assign Contributor role on the target Azure Subscription
resource "azurerm_role_assignment" "github_actions_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

