# AWS Multi-Account Landing Zone & Control Tower Terraform Module
# Manages AWS Organizations, Control Tower Landing Zone, Guardrails, and IAM Identity Center

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
  region = "us-east-1"
}

# 1. AWS Organization Setup
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "sso.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "controltower.amazonaws.com"
  ]
  feature_set = "ALL"
}

# 2. Organizational Units (OUs)
resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# 3. AWS Member Account: Production Homelab Cluster
resource "aws_organizations_account" "homelab_prod" {
  name      = "bar2sek-homelab-prod"
  email     = "aws-prod@bar2sek.com"
  parent_id = aws_organizations_organizational_unit.infrastructure.id
}

# 4. AWS Control Tower Landing Zone Deployment
resource "aws_controltower_landing_zone" "homelab_lz" {
  manifest_json = jsonencode({
    governance = {
      overall = {
        enabled = true
      }
    }
    core_accounts = {
      log_archive = {
        email = "aws-logs@bar2sek.com"
      }
      security_audit = {
        email = "aws-security@bar2sek.com"
      }
    }
  })
  version = "3.2"
}

# 5. Control Tower Guardrail (Preventative SCP / Detective Config Rule)
resource "aws_controltower_control" "prevent_s3_public" {
  control_identifier = "arn:aws:controltower:us-east-1::control/AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED"
  target_identifier  = aws_organizations_organizational_unit.infrastructure.arn
}

# 6. AWS IAM Identity Center Administrator Permission Set
data "aws_ssoadmin_instances" "org" {}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdministratorAccess"
  description      = "Full Administrator Access for Authentik SAML Federated Users"
  instance_arn     = tolist(data.aws_ssoadmin_instances.org.arns)[0]
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.org.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}
