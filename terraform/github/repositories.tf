# ==============================================================================
# GitHub Deployments Repository, Environments & OIDC Variables
# ==============================================================================

# 1. Dedicated Multi-Cloud GitOps Deployment Repository
resource "github_repository" "infra_cloud_deployments" {
  name        = var.repository_name
  description = "Declarative multi-cloud infrastructure deployments and CI/CD GitOps pipelines"
  visibility  = var.repository_visibility

  has_issues   = true
  has_projects = false
  has_wiki     = false

  allow_merge_commit = false
  allow_squash_merge = true
  allow_rebase_merge = false

  delete_branch_on_merge = true
  auto_init              = false

  topics = [
    "infrastructure-as-code",
    "terraform",
    "gitops",
    "azure",
    "aws",
    "github-actions"
  ]
}

# Enable Dependabot / Vulnerability Alerts
resource "github_repository_vulnerability_alerts" "infra_cloud_deployments" {
  repository = github_repository.infra_cloud_deployments.name
}

# 2. Production Deployment Environment
resource "github_repository_environment" "production" {
  repository  = github_repository.infra_cloud_deployments.name
  environment = "production"

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}

# 3. Environment Variables for Azure OIDC Workload Identity Federation
# These variables eliminate static secrets; the GitHub Actions runner authenticates
# using transient JWTs exchanged with Microsoft Entra ID.

resource "github_actions_environment_variable" "azure_client_id" {
  count         = var.azure_client_id != "" ? 1 : 0
  repository    = github_repository.infra_cloud_deployments.name
  environment   = github_repository_environment.production.environment
  variable_name = "AZURE_CLIENT_ID"
  value         = var.azure_client_id
}

resource "github_actions_environment_variable" "azure_tenant_id" {
  count         = var.azure_tenant_id != "" ? 1 : 0
  repository    = github_repository.infra_cloud_deployments.name
  environment   = github_repository_environment.production.environment
  variable_name = "AZURE_TENANT_ID"
  value         = var.azure_tenant_id
}

resource "github_actions_environment_variable" "azure_subscription_id" {
  count         = var.azure_subscription_id != "" ? 1 : 0
  repository    = github_repository.infra_cloud_deployments.name
  environment   = github_repository_environment.production.environment
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = var.azure_subscription_id
}

# 4. Branch Protection Rules for 'main'
resource "github_branch_protection" "main" {
  repository_id = github_repository.infra_cloud_deployments.name
  pattern       = "main"

  enforce_admins = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 0
  }
}
