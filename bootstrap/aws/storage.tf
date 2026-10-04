# ==============================================================================
# AWS Remote State Storage Backend (S3 Bucket)
# ==============================================================================

# 1. S3 Bucket for Terraform State
resource "aws_s3_bucket" "tfstate" {
  bucket        = local.s3_tfstate_bucket_name
  force_destroy = false

  tags = {
    Name    = local.s3_tfstate_bucket_name
    Purpose = "remote-state"
  }
}

# Enforce Object Versioning on State Bucket
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce Server-Side Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block All Public Access to State Bucket
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
