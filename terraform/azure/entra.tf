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

# Client Secret for Authentik OpenID Connect OAuth Source
resource "azuread_application_password" "authentik_secret" {
  application_id = azuread_application.authentik.id
  display_name   = "Authentik SSO OIDC Secret"
  # Valid for 1 year
  end_date_relative = "8760h"
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
