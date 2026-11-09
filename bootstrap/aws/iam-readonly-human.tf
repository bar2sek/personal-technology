# ------------------------------------------------------------------------------
# Read-only role for humans and coding agents (docs/414)
# ------------------------------------------------------------------------------
# Day-to-day CLI and Claude Code sessions use `[profile readonly]`, which
# assumes this role from the admin-cli login session. Mutations need an explicit
# `AWS_PROFILE=terraform` / `--profile admin`, so a stray `aws ... delete-*` from
# a default shell fails with AccessDenied instead of deleting something.
#
# Plan works under this role (state read + lock object only, like the PR plan
# role); apply does not.
resource "aws_iam_role" "readonly_human" {
  name                 = local.iam_role_readonly_human_name
  description          = "Read-only default for CLI and coding-agent sessions"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AdminCliLoginSession"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:user/admin-cli" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = local.iam_role_readonly_human_name
  }
}

resource "aws_iam_role_policy_attachment" "readonly_human" {
  role       = aws_iam_role.readonly_human.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "readonly_human" {
  name = "readonly-data-guardrails"
  role = aws_iam_role.readonly_human.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # `use_lockfile = true` takes a lock even for plan.
        Sid      = "TerraformStateLock"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.tfstate_bucket_arn}/*.tflock"
      },
      {
        # Configuration is readable; data is not. Backups stay unreadable.
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
