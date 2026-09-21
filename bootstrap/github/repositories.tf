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

# 3. OIDC Workload Identity Federation Configuration
#
# These carry NO static credentials. Under OIDC the runner authenticates with a
# transient JWT; a client ID or role ARN grants nothing without a federated
# credential whose subject claim matches this repository and environment.
#
# Scoping: GitHub resolves lookups with precedence
#   environment > repository > organization
#
# Each value is therefore declared at BOTH scopes:
#   * Repository scope — what the PR `plan` job reads. That job deliberately
#     declares no `environment:` (adding one would subject every pull request
#     to the production approval gate and defeat the speculative plan), so
#     environment-scoped values are invisible to it.
#   * Environment scope — lets `production` override the shared baseline, and
#     gives future `staging`/`dev` environments a place to differ.
#
# Empty inputs are filtered out, so an unset variable provisions nothing.

locals {
  # Non-secret identifiers. Readable by collaborators and unmasked in logs —
  # acceptable, because possession of them confers no access.
  actions_variables = {
    for name, value in {
      AZURE_CLIENT_ID       = var.azure_client_id
      AZURE_TENANT_ID       = var.azure_tenant_id
      AZURE_SUBSCRIPTION_ID = var.azure_subscription_id
      AWS_ROLE_TO_ASSUME    = var.aws_role_arn
      AWS_REGION            = var.aws_region
    } : name => value if value != ""
  }

  # Values that must never surface in a workflow log. The state bucket name
  # embeds the AWS account ID and is interpolated into a `run:` command, which
  # Actions echoes verbatim — as a secret it is masked to `***` instead.
  actions_secrets = {
    AWS_TF_STATE_BUCKET = var.aws_tf_state_bucket
  }

  # Terraform forbids sensitive values as `for_each` arguments, since instance
  # keys are recorded in plaintext in state addresses. The secret *names* are
  # not sensitive, so iterate over those and look the value up by key.
  # `nonsensitive` wraps only the emptiness test — it reveals whether a value
  # was supplied, never the value itself.
  actions_secret_names = toset([
    for name, value in local.actions_secrets : name
    if !nonsensitive(value == "")
  ])
}

resource "github_actions_variable" "shared" {
  for_each = local.actions_variables

  repository    = github_repository.infra_cloud_deployments.name
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_variable" "production" {
  for_each = local.actions_variables

  repository    = github_repository.infra_cloud_deployments.name
  environment   = github_repository_environment.production.environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_secret" "shared" {
  for_each = local.actions_secret_names

  repository  = github_repository.infra_cloud_deployments.name
  secret_name = each.value
  value       = local.actions_secrets[each.value]
}

resource "github_actions_environment_secret" "production" {
  for_each = local.actions_secret_names

  repository  = github_repository.infra_cloud_deployments.name
  environment = github_repository_environment.production.environment
  secret_name = each.value
  value       = local.actions_secrets[each.value]
}

# 4. State Address Migration
#
# The five variables above were previously declared as individually named,
# `count`-guarded resources. Switching to `for_each` changes their state
# addresses, which Terraform would otherwise read as destroy-then-create.
# These `moved` blocks re-map the addresses in place so the plan shows
# additions only. A block whose source is absent from state is a no-op, so
# these stay safe even if an input was never populated.

moved {
  from = github_actions_environment_variable.azure_client_id[0]
  to   = github_actions_environment_variable.production["AZURE_CLIENT_ID"]
}

moved {
  from = github_actions_environment_variable.azure_tenant_id[0]
  to   = github_actions_environment_variable.production["AZURE_TENANT_ID"]
}

moved {
  from = github_actions_environment_variable.azure_subscription_id[0]
  to   = github_actions_environment_variable.production["AZURE_SUBSCRIPTION_ID"]
}

moved {
  from = github_actions_environment_variable.aws_role_to_assume[0]
  to   = github_actions_environment_variable.production["AWS_ROLE_TO_ASSUME"]
}

moved {
  from = github_actions_environment_variable.aws_region[0]
  to   = github_actions_environment_variable.production["AWS_REGION"]
}

# 5. Branch Protection Rules for 'main'
resource "github_branch_protection" "main" {
  repository_id = github_repository.infra_cloud_deployments.name
  pattern       = "main"

  enforce_admins = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 0
  }
}
