# ==============================================================================
# GitHub Actions roles for bedrock-ai-gateway (AWS CDK)
#
# These roles hold no AWS permissions of their own beyond assuming the CDK
# bootstrap roles (created by `cdk bootstrap`, stack CDKToolkit). The CDK CLI
# then works through those roles, and CloudFormation creates resources with
# the bootstrap's execution role.
#
#   diff   (pull_request)            -> lookup role only (ReadOnlyAccess).
#                                       `cdk diff --method=template` reads the
#                                       deployed template through it.
#   deploy (environment:production)  -> deploy + file-publishing + lookup roles.
#
# The bootstrap roles trust the whole account, so any principal in it with
# sts:AssumeRole on them can use them. Granting that permission here, per
# role, is what scopes each pipeline stage.
#
# CAUTION: the CloudFormation execution role is AdministratorAccess by default,
# so the deploy role is effectively admin for anything a CDK stack can define.
# The protected production environment and branch protection are the guard
# until the bootstrap execution policy is narrowed.
# ==============================================================================

locals {
  # Default bootstrap qualifier; change only if bootstrapped with --qualifier.
  cdk_qualifier = "hnb659fds"

  cdk_bootstrap_role_arns = {
    for role in ["lookup", "deploy", "file-publishing"] :
    role => "arn:aws:iam::${local.account_id}:role/cdk-${local.cdk_qualifier}-${role}-role-${local.account_id}-${var.aws_region}"
  }

  github_gateway_oidc_trust = {
    for stage, subject in {
      diff   = "repo:${local.github_gateway_repo_immutable}:pull_request"
      deploy = "repo:${local.github_gateway_repo_immutable}:environment:production"
    } :
    stage => jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Federated = aws_iam_openid_connect_provider.github_actions.arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
              "token.actions.githubusercontent.com:sub" = subject
            }
          }
        }
      ]
    })
  }
}

# ------------------------------------------------------------------------------
# DIFF role — `cdk diff` on pull requests
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_gateway_diff" {
  name                 = local.iam_role_github_gateway_diff
  description          = "Read-only cdk diff for pull requests in bar2sek/bedrock-ai-gateway"
  assume_role_policy   = local.github_gateway_oidc_trust["diff"]
  max_session_duration = 3600

  tags = {
    Name = local.iam_role_github_gateway_diff
  }
}

resource "aws_iam_role_policy" "github_gateway_diff" {
  name = "assume-cdk-lookup-role"
  role = aws_iam_role.github_gateway_diff.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # TagSession: the CDK CLI may tag the sessions it opens on bootstrap roles.
        Sid      = "AssumeCdkLookupRole"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole", "sts:TagSession"]
        Resource = local.cdk_bootstrap_role_arns["lookup"]
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# DEPLOY role — `cdk deploy` from the protected production environment
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_gateway_deploy" {
  name                 = local.iam_role_github_gateway_deploy
  description          = "cdk deploy from the production environment of bar2sek/bedrock-ai-gateway"
  assume_role_policy   = local.github_gateway_oidc_trust["deploy"]
  max_session_duration = 3600

  tags = {
    Name = local.iam_role_github_gateway_deploy
  }
}

resource "aws_iam_role_policy" "github_gateway_deploy" {
  name = "assume-cdk-deploy-roles"
  role = aws_iam_role.github_gateway_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # deploy: create/execute CloudFormation change sets.
        # file-publishing: upload the bundled Lambda code to the asset bucket.
        # lookup: read the current template for the pre-deploy diff.
        # No image-publishing: the stack builds no container images.
        Sid      = "AssumeCdkDeploymentRoles"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole", "sts:TagSession"]
        Resource = values(local.cdk_bootstrap_role_arns)
      }
    ]
  })
}
