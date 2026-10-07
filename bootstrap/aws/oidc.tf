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
      },
      {
        # ReadOnlyAccess (v190) grants these data-plane reads. Vectors carry the
        # source text chunks as metadata, and AgentCore memory holds conversation
        # content, so a PR must not be able to read either. Plan only needs the
        # index and bucket configuration (GetIndex / GetVectorBucket).
        Sid    = "DenyVectorAndAgentMemoryReads"
        Effect = "Deny"
        Action = [
          "s3vectors:GetVectors",
          "s3vectors:ListVectors",
          "s3vectors:QueryVectors",
          "bedrock-agentcore:GetMemoryRecord",
          "bedrock-agentcore:ListMemoryRecords",
          "bedrock-agentcore:RetrieveMemoryRecords",
          "bedrock-agentcore:GetEvent",
          "bedrock-agentcore:ListEvents",
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
      },

      # --- Bedrock Knowledge Base service role ---------------------------------
      # Ceiling only: the role's own policy in infra-cloud-deployments narrows
      # these to the exact embedding model, bucket, and index. Names follow
      # s3-aws-bedrock-* (source documents) and s3v-aws-bedrock-* (vector bucket),
      # so a KB can never be pointed at the state or backup buckets.
      {
        Sid      = "KnowledgeBaseListModels"
        Effect   = "Allow"
        Action   = ["bedrock:ListFoundationModels", "bedrock:ListCustomModels"]
        Resource = "*"
      },
      {
        # Embedding calls during ingestion. Region-pinned on-demand models only;
        # cross-Region inference profiles are added when a workload needs them.
        Sid      = "KnowledgeBaseEmbeddingModels"
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      },
      {
        Sid    = "KnowledgeBaseSourceDocuments"
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetObject"]
        Resource = [
          "arn:aws:s3:::s3-${var.platform}-bedrock-*",
          "arn:aws:s3:::s3-${var.platform}-bedrock-*/*",
        ]
        Condition = {
          StringEquals = { "aws:ResourceAccount" = local.account_id }
        }
      },
      {
        Sid    = "KnowledgeBaseVectorIndex"
        Effect = "Allow"
        Action = [
          "s3vectors:GetIndex",
          "s3vectors:PutVectors",
          "s3vectors:GetVectors",
          "s3vectors:QueryVectors",
          "s3vectors:DeleteVectors",
        ]
        Resource = "arn:aws:s3vectors:${var.aws_region}:${local.account_id}:bucket/s3v-${var.platform}-bedrock-*/index/*"
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
      {
        # The backup bucket's guardrails (bucket policy, Object Lock) are owned by
        # bootstrap (backups.tf). A pipeline must not be able to loosen the
        # controls that protect backups from a compromised pipeline. An explicit
        # identity-policy Deny cannot be overridden by any bucket policy grant.
        Sid    = "ProtectBackupBucketGuardrails"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketObjectLockConfiguration",
          "s3:PutBucketVersioning",
          "s3:BypassGovernanceRetention",
          "s3:PutObjectRetention",
          "s3:PutObjectLegalHold",
        ]
        Resource = [local.backup_bucket_arn, "${local.backup_bucket_arn}/*"]
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

      # --- Bedrock: Knowledge Bases, Guardrails, S3 Vectors --------------------
      # Knowledge base and guardrail IDs are service-generated, so these are
      # scoped to this account and Region rather than by name.
      {
        # StartIngestionJob lets a post-apply CI step sync the KB; it is a
        # runtime operation with no Terraform resource.
        Sid    = "ManageBedrockKnowledgeBases"
        Effect = "Allow"
        Action = [
          "bedrock:CreateKnowledgeBase",
          "bedrock:GetKnowledgeBase",
          "bedrock:UpdateKnowledgeBase",
          "bedrock:DeleteKnowledgeBase",
          "bedrock:CreateDataSource",
          "bedrock:GetDataSource",
          "bedrock:UpdateDataSource",
          "bedrock:DeleteDataSource",
          "bedrock:ListDataSources",
          "bedrock:StartIngestionJob",
          "bedrock:GetIngestionJob",
          "bedrock:ListIngestionJobs",
          "bedrock:TagResource",
          "bedrock:UntagResource",
          "bedrock:ListTagsForResource",
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}:${local.account_id}:knowledge-base/*"
      },
      {
        Sid    = "ManageBedrockGuardrails"
        Effect = "Allow"
        Action = [
          "bedrock:CreateGuardrail",
          "bedrock:GetGuardrail",
          "bedrock:UpdateGuardrail",
          "bedrock:DeleteGuardrail",
          "bedrock:CreateGuardrailVersion",
          "bedrock:TagResource",
          "bedrock:UntagResource",
          "bedrock:ListTagsForResource",
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}:${local.account_id}:guardrail/*"
      },
      {
        # No DeleteVectorBucket, matching the no-DeleteBucket rule above. Indexes
        # may be deleted: they hold derived data that re-ingestion rebuilds, and
        # changing an index's dimension forces replacement.
        Sid    = "ManageBedrockVectorStore"
        Effect = "Allow"
        Action = [
          "s3vectors:CreateVectorBucket",
          "s3vectors:GetVectorBucket",
          "s3vectors:ListIndexes",
          "s3vectors:CreateIndex",
          "s3vectors:GetIndex",
          "s3vectors:DeleteIndex",
          "s3vectors:TagResource",
          "s3vectors:UntagResource",
          "s3vectors:ListTagsForResource",
        ]
        Resource = [
          "arn:aws:s3vectors:${var.aws_region}:${local.account_id}:bucket/s3v-${var.platform}-bedrock-*",
          "arn:aws:s3vectors:${var.aws_region}:${local.account_id}:bucket/s3v-${var.platform}-bedrock-*/index/*",
        ]
      },
      {
        # The one exception to "configuration only, never object data": the
        # apply job syncs the synthetic KB corpus (kb-corpus/ in git) into the
        # bucket with `aws s3 sync --delete`. Limited to s3-aws-bedrock-* buckets.
        Sid    = "ManageBedrockSourceDocuments"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
        ]
        Resource = "arn:aws:s3:::s3-${var.platform}-bedrock-*/*"
      },

      {
        # CreateKnowledgeBase hands ("passes") a service role to Bedrock, which
        # then acts with that role's permissions. Unscoped PassRole is a classic
        # escalation path: pass any powerful role to any service the pipeline
        # can drive, and borrow its permissions. Both limits are needed:
        #   Resource  - only role-aws-bedrock-*, which CI can only create with
        #               the workload boundary (GrantPrivilegeOnlyWithinBoundary).
        #   Condition - only to bedrock.amazonaws.com, so the same roles can't be
        #               handed to, say, EC2 or Lambda and used from there.
        Sid      = "PassBedrockServiceRoles"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::${local.account_id}:role/role-${var.platform}-bedrock-*"
        Condition = {
          StringEquals = { "iam:PassedToService" = "bedrock.amazonaws.com" }
        }
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
