# ==============================================================================
# Offsite Backup Guardrails & Uploader Identity (on-prem Kubernetes -> S3)
#
# The bucket itself (versioning, SSE, lifecycle) lives in infra-cloud-deployments
# (terraform/aws/main.tf) and is applied by CI. Its GUARDRAILS live here, applied
# only by an administrator: the Object Lock configuration and the bucket policy.
# The CI apply role is explicitly denied from changing either (oidc.tf,
# ProtectBackupBucketGuardrails), so a compromised pipeline cannot loosen the
# controls that protect backups from it.
# ==============================================================================

# Object Lock, GOVERNANCE mode, 30-day default retention.
#
# Every new object version is immutable for 30 days: it cannot be deleted or
# overwritten-in-place, even by an administrator, unless that principal holds
# s3:BypassGovernanceRetention and sends the bypass header. The bucket policy
# below denies that permission to everyone, so bypass first requires editing
# the bucket policy: a deliberate, CloudTrail-visible act.
#
# GOVERNANCE (not COMPLIANCE) is deliberate: compliance-mode objects cannot be
# removed by anyone, root included, until retention expires. Had compliance been
# active during the 2026-10 cleanup, plaintext archives containing a live
# credential could not have been purged. Revisit once encrypted-only uploads
# have a long, clean track record.
#
# IRREVERSIBLE: once enabled, Object Lock can never be disabled on this bucket.
# The default retention rule can still be changed or removed.
resource "aws_s3_bucket_object_lock_configuration" "backups" {
  bucket = local.backup_bucket_name

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "backups" {
  bucket = local.backup_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [local.backup_bucket_arn, "${local.backup_bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        # Server-side half of fail-closed encryption: whoever the caller is, only
        # age ciphertext (*.age) can be written. Mirrors the uploader's IAM policy.
        Sid         = "DenyUnencryptedArtifacts"
        Effect      = "Deny"
        Principal   = "*"
        Action      = "s3:PutObject"
        NotResource = "${local.backup_bucket_arn}/*.age"
      },
      {
        # Nobody may bypass governance retention. Break-glass is to edit this
        # policy first, as root or an administrator, which is logged.
        Sid       = "DenyGovernanceBypass"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:BypassGovernanceRetention"
        Resource  = "${local.backup_bucket_arn}/*"
      }
    ]
  })
}

# ==============================================================================
# Uploader identity
#
# Write-only identity for the backup CronJobs in kubernetes/infrastructure/backups.
# It can upload age-encrypted artifacts under two prefixes and nothing else:
# no GetObject, no ListBucket, no DeleteObject. A stolen key can add objects but
# cannot read, enumerate, or destroy existing backups.
#
# Lives in bootstrap (applied locally by an administrator), not in
# infra-cloud-deployments: the CI apply role may only create boundary-scoped
# roles, never IAM users, and that limit is deliberate.
#
# The ACCESS KEY is intentionally NOT a Terraform resource. This module uses
# local state, and aws_iam_access_key would write the secret into it in
# plaintext. Mint and rotate the key with the CLI instead; see
# kubernetes/infrastructure/backups/README.md.
#
# Roadmap: replace this static key with IAM Roles Anywhere.
# ==============================================================================

resource "aws_iam_user" "backup_uploader" {
  name = local.iam_user_backup_uploader_name
  path = "/service/"

  tags = {
    Name    = local.iam_user_backup_uploader_name
    Purpose = "offsite-backup-upload"
  }
}

resource "aws_iam_user_policy" "backup_uploader" {
  name = "policy-${var.platform}-backup-upload-${var.env}-${var.iteration}"
  user = aws_iam_user.backup_uploader.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Only *.age keys: a plaintext artifact is rejected even if the job
        # script regresses. The bucket policy enforces the same rule.
        Sid    = "UploadEncryptedBackupsOnly"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          # CLI v2 switches to multipart above 8 MB; lets it clean up a failed upload.
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          "${local.backup_bucket_arn}/cluster-state/*.age",
          "${local.backup_bucket_arn}/postgres/*.age"
        ]
      }
    ]
  })
}
