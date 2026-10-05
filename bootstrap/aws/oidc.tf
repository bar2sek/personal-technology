# ==============================================================================
# AWS IAM OpenID Connect (OIDC) Identity Provider & GitHub Actions Roles
# Zero-Trust Workload Identity Federation (No static AWS Access Keys in GitHub)
#
# Two roles, one per pipeline stage, so a pull request never holds write access:
#
#   plan  (pull_request)            ReadOnlyAccess minus data-plane reads,
#                                   plus the Terraform state lock file.
#   apply (environment:production)  Scoped to the resources Terraform manages.
#                                   Any IAM role it creates must carry the
#                                   workload permissions boundary, so it cannot
#                                   escalate itself to administrator.
#
# Trust uses the IMMUTABLE subject format only (owner@id/repo@id). Verified
# against CloudTrail AssumeRoleWithWebIdentity events on 2026-10-04: GitHub
# emits this format for this repository. A mutable `repo:owner/name` subject
# would let a re-created repository of the same name inherit trust.
# See docs/409-github-azure-oidc-gitops.md.
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

locals {
  tfstate_bucket_arn = aws_s3_bucket.tfstate.arn

  # ARNs built from names (not resource references) so the full apply policy is
  # rendered in `terraform plan` for review. IAM does not require referenced
  # ARNs to exist yet.
  github_plan_role_arn         = "arn:aws:iam::${local.account_id}:role/${local.iam_role_github_plan_name}"
  github_apply_role_arn        = "arn:aws:iam::${local.account_id}:role/${local.iam_role_github_actions_name}"
  github_apply_policy_arn      = "arn:aws:iam::${local.account_id}:policy/${local.iam_policy_github_apply_name}"
  workload_boundary_policy_arn = "arn:aws:iam::${local.account_id}:policy/${local.iam_policy_workload_boundary_name}"

  # Trust policy shared by both roles; only the subject claim differs.
  github_oidc_trust = {
    for stage, subject in {
      plan  = "repo:${local.github_repo_immutable}:pull_request"
      apply = "repo:${local.github_repo_immutable}:environment:production"
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
# 2. PLAN role — speculative `terraform plan` on pull requests
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_plan" {
  name               = local.iam_role_github_plan_name
  description        = "Read-only speculative plan for pull requests in ${var.github_repo_name}"
  assume_role_policy = local.github_oidc_trust["plan"]

  tags = {
    Name = local.iam_role_github_plan_name
  }
}

# ReadOnlyAccess lets plan refresh any resource type added later without IAM
# changes. Its risk is data exfiltration, not mutation — handled by the deny below.
resource "aws_iam_role_policy_attachment" "github_plan_readonly" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "github_plan" {
  name = "terraform-plan-state-access"
  role = aws_iam_role.github_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # `use_lockfile = true` takes a lock even for plan: allow the lock
        # object only, never the state object itself.
        Sid      = "TerraformStateLock"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.tfstate_bucket_arn}/*.tflock"
      },
      {
        # Configuration is readable; DATA is not. Object reads are limited to
        # the state bucket, so a PR can never download backups.
        Sid         = "DenyObjectReadsOutsideState"
        Effect      = "Deny"
        Action      = ["s3:GetObject", "s3:GetObjectVersion"]
        NotResource = "${local.tfstate_bucket_arn}/*"
      },
      {
        Sid    = "DenySecretAndDataReads"
        Effect = "Deny"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "kms:Decrypt",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 3. Workload permissions boundary — ceiling for every role the apply role creates
# ------------------------------------------------------------------------------
# Extend this (here, in bootstrap, applied by a human) when a new workload role
# needs more. That keeps privilege growth a reviewed, out-of-band decision.
resource "aws_iam_policy" "workload_boundary" {
  name        = local.iam_policy_workload_boundary_name
  description = "Permissions boundary: maximum permissions for CI-managed workload roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EksConnectorAgent"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 4. APPLY role — `terraform apply` from the protected production environment
# ------------------------------------------------------------------------------
# Name and ARN are unchanged from the former admin role, so the production
# environment's AWS_ROLE_TO_ASSUME variable needs no update.
resource "aws_iam_role" "github_actions" {
  name               = local.iam_role_github_actions_name
  description        = "Scoped apply role for production deployments in ${var.github_repo_name}"
  assume_role_policy = local.github_oidc_trust["apply"]

  tags = {
    Name = local.iam_role_github_actions_name
  }
}

resource "aws_iam_policy" "github_apply" {
  # Boundary must exist before any role can be created against it.
  depends_on = [aws_iam_policy.workload_boundary]

  name        = local.iam_policy_github_apply_name
  description = "Least-privilege Terraform apply for infra-cloud-deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- Terraform remote state -------------------------------------------
      {
        Sid      = "TerraformStateList"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = local.tfstate_bucket_arn
      },
      {
        Sid      = "TerraformStateObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.tfstate_bucket_arn}/*"
      },

      # --- Workload S3 buckets: configuration only, never object data ----------
      # No s3:DeleteBucket: removing a bucket is a deliberate human action.
      {
        Sid    = "ManageWorkloadBucketConfiguration"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:ListBucket",
          "s3:GetBucket*",
          "s3:PutBucket*",
          "s3:GetAccelerateConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
        ]
        Resource = "arn:aws:s3:::s3-${var.platform}-*"
      },
      {
        # The state bucket also matches s3-aws-*; its configuration belongs to
        # bootstrap, not CI.
        Sid    = "ProtectStateBucketConfiguration"
        Effect = "Deny"
        Action = [
          "s3:PutBucket*",
          "s3:PutEncryptionConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:DeleteBucket*",
        ]
        Resource = local.tfstate_bucket_arn
      },

      # --- Workload IAM roles: only ever with the permissions boundary ---------
      {
        Sid    = "GrantPrivilegeOnlyWithinBoundary"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:PutRolePermissionsBoundary",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
        ]
        Resource = "arn:aws:iam::${local.account_id}:role/role-${var.platform}-*"
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary" = local.workload_boundary_policy_arn
          }
        }
      },
      {
        Sid    = "ManageWorkloadRoles"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:DeleteRole",
        ]
        Resource = "arn:aws:iam::${local.account_id}:role/role-${var.platform}-*"
      },
      {
        # Policies can only take effect on boundary-capped roles (see above).
        Sid    = "ManageWorkloadPolicies"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:ListEntitiesForPolicy",
          "iam:TagPolicy",
          "iam:UntagPolicy",
        ]
        Resource = "arn:aws:iam::${local.account_id}:policy/policy-${var.platform}-*"
      },

      # --- Guardrails: CI can never modify its own identity or its ceiling ----
      {
        Sid      = "NeverRemoveBoundaries"
        Effect   = "Deny"
        Action   = "iam:DeleteRolePermissionsBoundary"
        Resource = "*"
      },
      {
        Sid       = "ProtectCiIdentityAndBoundary"
        Effect    = "Deny"
        NotAction = ["iam:Get*", "iam:List*"]
        Resource = [
          local.github_apply_role_arn,
          local.github_plan_role_arn,
          local.github_apply_policy_arn,
          local.workload_boundary_policy_arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_apply" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_apply.arn
}
