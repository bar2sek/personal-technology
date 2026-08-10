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
  name      = local.ou_infrastructure
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = local.ou_security
  parent_id = aws_organizations_organization.org.roots[0].id
}

# 3. AWS Accounts
resource "aws_organizations_account" "homelab_prod" {
  name      = local.acct_homelab_prod
  email     = local.email_prod
  parent_id = aws_organizations_organizational_unit.infrastructure.id
}

resource "aws_organizations_account" "log_archive" {
  name      = local.acct_log_archive
  email     = local.email_logs
  parent_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_account" "security_audit" {
  name      = local.acct_security_audit
  email     = local.email_security
  parent_id = aws_organizations_organizational_unit.security.id
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
        email = local.email_logs
      }
      security_audit = {
        email = local.email_security
      }
    }
  })

  version = "3.2"
}

# 5. Control Tower Guardrail
resource "aws_controltower_control" "prevent_s3_public" {
  control_identifier = "arn:aws:controltower:us-east-2::control/AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED"
  target_identifier  = aws_organizations_organizational_unit.infrastructure.arn
}

# 6. AWS IAM Identity Center Permission Set
data "aws_ssoadmin_instances" "org" {}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = local.pset_admin
  description      = "Full Administrator Access for Authentik SAML Federated Users"
  instance_arn     = tolist(data.aws_ssoadmin_instances.org.arns)[0]
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.org.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}
