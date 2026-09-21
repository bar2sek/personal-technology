# ==============================================================================
# AWS IAM OpenID Connect (OIDC) Identity Provider & GitHub Actions Role
# Zero-Trust Workload Identity Federation (No static AWS Access Keys in GitHub)
# ==============================================================================

# 1. GitHub Actions OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c5824a877991a03f47c093a52c0f99479b0629a"
  ]

  tags = {
    Name = "github-actions-oidc-provider"
  }
}

# 2. IAM Role for GitHub Actions Deployment Runner
resource "aws_iam_role" "github_actions" {
  name        = local.iam_role_github_actions_name
  description = "Execution role for GitHub Actions CI/CD in ${var.github_repo_name}"

  assume_role_policy = jsonencode({
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
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${local.github_repo_immutable}:environment:production",
              "repo:${local.github_repo_immutable}:pull_request",
              "repo:${local.github_repo_immutable}:ref:refs/heads/main",
              "repo:${var.github_repo_name}:*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = local.iam_role_github_actions_name
  }
}

# 3. Attach Administrator Policy to GitHub Actions Deployment Role
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
