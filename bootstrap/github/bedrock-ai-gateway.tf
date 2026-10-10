# ==============================================================================
# bedrock-ai-gateway — AWS CDK application repository
#
# The repository was created by hand with `gh repo create` and is adopted into
# Terraform by the import block below. Everything else here (environment,
# reviewer gate, secrets, branch protection) is managed only from this file.
#
# Pipeline shape (see .github/workflows in that repository):
#   pull_request  -> job `verify`: typecheck, test, synth, `cdk diff`
#                    assumes the DIFF role (repository secret)
#   push to main  -> job in environment `production`: `cdk deploy`
#                    waits for reviewer approval, assumes the DEPLOY role
#                    (environment secret, invisible to pull request jobs)
# ==============================================================================

# Role ARNs are read straight from the bootstrap/aws state instead of being
# copied into terraform.tfvars: one source of truth, nothing to keep in sync,
# and the values never pass through a file or the shell.
data "terraform_remote_state" "aws" {
  backend = "local"
  config = {
    path = "${path.module}/../aws/terraform.tfstate"
  }
}

data "github_user" "owner" {
  username = var.github_owner
}

# 1. Repository (adopted, not created) ---------------------------------------
import {
  to = github_repository.bedrock_ai_gateway
  id = "bedrock-ai-gateway"
}

resource "github_repository" "bedrock_ai_gateway" {
  name        = "bedrock-ai-gateway"
  description = "Governed AI gateway on AWS: API Gateway + Lambda (TypeScript) doing RAG over a Bedrock Knowledge Base with Guardrails, deployed with AWS CDK"
  visibility  = "public"

  has_issues   = true
  has_projects = false
  has_wiki     = false

  # Same merge policy as infra-cloud-deployments: one squashed commit per PR.
  allow_merge_commit = false
  allow_squash_merge = true
  allow_rebase_merge = false

  delete_branch_on_merge = true
  auto_init              = false

  # A destroy archives the repository instead of deleting it and its history.
  archive_on_destroy = true

  topics = [
    "aws-cdk",
    "typescript",
    "amazon-bedrock",
    "rag",
    "generative-ai",
    "aws-lambda",
    "api-gateway",
  ]
}

resource "github_repository_vulnerability_alerts" "bedrock_ai_gateway" {
  repository = github_repository.bedrock_ai_gateway.name
}

# 2. Production environment ----------------------------------------------------
# The deploy role trusts only OIDC tokens whose subject ends in
# `:environment:production`, and GitHub issues that subject only to jobs
# running in this environment. These rules therefore decide who can deploy.
resource "github_repository_environment" "gateway_production" {
  repository  = github_repository.bedrock_ai_gateway.name
  environment = "production"

  # Every deployment pauses until the owner approves it in the Actions UI.
  # Self-review is allowed (solo maintainer); admins cannot skip the gate.
  prevent_self_review = false
  can_admins_bypass   = false
  reviewers {
    users = [data.github_user.owner.id]
  }

  # Only branches with protection rules — i.e. `main` — may deploy.
  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}

# 3. Secrets ---------------------------------------------------------------------
# Secrets, not variables: both ARNs embed the AWS account ID, and this public
# repository's Actions logs print step inputs verbatim. Secrets are masked.
resource "github_actions_secret" "gateway_diff_role" {
  repository  = github_repository.bedrock_ai_gateway.name
  secret_name = "AWS_DIFF_ROLE_ARN"
  value       = data.terraform_remote_state.aws.outputs.github_gateway_diff_role_arn
}

# Environment scope only: pull request jobs run without an environment, so they
# cannot read the deploy role ARN at all.
resource "github_actions_environment_secret" "gateway_deploy_role" {
  repository  = github_repository.bedrock_ai_gateway.name
  environment = github_repository_environment.gateway_production.environment
  secret_name = "AWS_DEPLOY_ROLE_ARN"
  value       = data.terraform_remote_state.aws.outputs.github_gateway_deploy_role_arn
}

# 4. Branch protection for main ----------------------------------------------
resource "github_branch_protection" "gateway_main" {
  repository_id = github_repository.bedrock_ai_gateway.node_id
  pattern       = "main"

  # No admin bypass: every change, including the owner's, arrives through a PR,
  # so tests and `cdk diff` always run before anything can deploy.
  enforce_admins      = true
  allows_force_pushes = false
  allows_deletions    = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 0
  }

  # `verify` is the job name in the repository's CI workflow; renaming that job
  # requires changing it here too. strict = the PR branch must be up to date
  # with main, so the check ran against what will actually be merged.
  required_status_checks {
    strict   = true
    contexts = ["verify"]
  }
}
