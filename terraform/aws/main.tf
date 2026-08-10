# 1. AWS Route53 Hosted Zone
resource "aws_route53_zone" "primary" {
  name    = var.domain_name
  comment = "Primary DNS zone for homelab cluster services and Cloudflare Tunnels (${local.r53_zone_name})"
}

# 2. Encrypted Offsite Backup S3 Bucket
resource "aws_s3_bucket" "backups" {
  bucket        = local.s3_backup_bucket_name
  force_destroy = false

  tags = {
    Name        = local.s3_backup_bucket_name
    Environment = var.env
    ManagedBy   = "Terraform"
    Project     = "${var.platform}-${var.product}"
  }
}

# Enable Server-Side Encryption (AES256) on Backup Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "backups_crypto" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access on Backup S3 Bucket
resource "aws_s3_bucket_public_access_block" "backups_privacy" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. AWS EKS Connector IAM Role
resource "aws_iam_role" "eks_connector" {
  name = local.iam_role_eks_connector

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_connector_policy" {
  role       = aws_iam_role.eks_connector.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSConnectorServiceRolePolicy"
}
