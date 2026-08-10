# AWS Hybrid Cloud Infrastructure Terraform Module
# Manages Route53 DNS Zone, Offsite Backup S3 Bucket, IAM Roles, and EKS Connector

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. AWS Route53 Hosted Zone for bar2sek.com
resource "aws_route53_zone" "primary" {
  name    = var.domain_name
  comment = "Primary DNS zone for homelab cluster services and Cloudflare Tunnels"
}

# 2. Encrypted Offsite Backup S3 Bucket (Velero & Rook-Ceph Target)
resource "aws_s3_bucket" "backups" {
  bucket        = "bar2sek-homelab-backups-${var.aws_region}"
  force_destroy = false

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "Talos-AWS-Homelab"
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

# 3. AWS EKS Connector Service Role (Single Pane of Glass Observability)
resource "aws_iam_role" "eks_connector" {
  name = "TalosHomelab-EKSConnectorRole"

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
