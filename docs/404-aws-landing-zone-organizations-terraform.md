# AWS Multi-Account Landing Zone (Organizations, IAM Identity Center & Terraform)

This guide details the enterprise multi-account AWS architecture, cost breakdown, and Terraform code to manage **AWS Organizations**, **AWS IAM Identity Center (SSO)**, and **AWS Control Tower**.

---

## ❓ Is AWS Control Tower, Organizations & Identity Center Free?

- **AWS Organizations**: **100% FREE ($0.00)**. Creating an AWS Organization and multiple accounts (`Management`, `Security`, `Workloads`) incurs zero fees.
- **AWS IAM Identity Center (AWS SSO)**: **100% FREE ($0.00)**. Managing users, SAML 2.0 IdP federation (Authentik), and permission sets is completely free.
- **AWS Control Tower (ENABLED)**: **Service is 100% FREE ($0.00)**. Provisions automated Landing Zones, centralized Log Vaults, and Guardrails across all accounts.
  - *Monthly Cost*: AWS Config compliance rules & CloudTrail logging evaluations cost **~$2.00 to $5.00 per month**.
  - *Total Monthly AWS Bill*: **~$3.00 to $8.00 per month** (including Route53, S3 backups, and Control Tower Guardrails).

---

## 🛡 What are AWS Landing Zones & Guardrails?

### 1. What is an AWS Landing Zone?
An AWS Landing Zone is a multi-account AWS environment built according to AWS Well-Architected best practices. It automatically provisions:
- **AWS Organizations Hierarchy**: Centralized management account with dedicated OUs (`Security`, `Infrastructure`, `Workloads`).
- **Log Archive Account**: Centralized, immutable S3 vault where all AWS CloudTrail audit logs from all accounts are consolidated and locked against tampering.
- **Security / Audit Account**: Dedicated account for security auditing, GuardDuty alerts, and IAM access reviews.

### 2. What are Control Tower Guardrails (Controls)?
Guardrails are automated governance rules that enforce security and operational policies across every account:

- **Preventative Guardrails (Service Control Policies - SCPs)**: Hard blocks that physically **prevent** unauthorized actions before they happen.
  - *Examples*:
    - Block anyone from deleting offsite S3 backup buckets.
    - Restrict AWS resource creation exclusively to `us-east-1` (blocking accidental deployments in other regions).
    - Block root user logins on member accounts.
    - Disallow disabling CloudTrail or AWS Config logging.
- **Detective Guardrails (AWS Config Rules)**: Continuous compliance monitors that flag policy violations in your dashboard.
  - *Examples*:
    - Flag any S3 bucket that has public access enabled.
    - Flag unencrypted EBS storage volumes or un-rotated IAM access keys.

---

## 📐 Multi-Account AWS Organization Architecture

```
                               +----------------------------------+
                               |     AWS Management Account       |
                               |  (AWS Organizations Master)      |
                               +----------------------------------+
                                                |
                 +------------------------------+------------------------------+
                 |                                                             |
                 v                                                             v
  +------------------------------+                              +------------------------------+
  |    Organizational Unit (OU)  |                              |    Organizational Unit (OU)  |
  |         [Security]           |                              |        [Infrastructure]      |
  +------------------------------+                              +------------------------------+
                 |                                                             |
                 v                                                             v
  +------------------------------+                              +------------------------------+
  |    AWS Audit / Log Account   |                              |   AWS Production Homelab     |
  |  (CloudTrail & S3 Vault)     |                              |   (ACK, EKS Connector, S3)   |
  +------------------------------+                              +------------------------------+
```

---

## 📦 Terraform Module (`terraform/aws_organization/main.tf`)

```hcl
# Dynamic Naming Construction Following Global Conventions Specification (Without Agency Node)
locals {
  # OU Patterns: ou-<platform>-<category>-<env>-<root-id>
  ou_infrastructure = "ou-${var.platform}-infrastructure-${var.env}-${var.root_id}"
  ou_security       = "ou-${var.platform}-security-${var.env}-${var.root_id}"

  # Account Patterns: acct-<platform>-<category>-<env>-<root-id>
  acct_homelab_prod   = "acct-${var.platform}-${var.product}-${var.env}-${var.root_id}"
  acct_log_archive    = "acct-${var.platform}-security-logarchive-infra-${var.env}-${var.root_id}"
  acct_security_audit = "acct-${var.platform}-security-tooling-infra-${var.env}-${var.root_id}"

  # Permission Set Pattern: pset-<platform>-<product>-<env>-<permission>
  pset_admin = "pset-${var.platform}-${var.product}-${var.env}-admin"
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
  name      = local.ou_infrastructure
  parent_id = aws_organizations_organization.org.roots[0].id
}

# 3. AWS Member Account
resource "aws_organizations_account" "homelab_prod" {
  name      = local.acct_homelab_prod
  email     = "aws-prod@${var.destination_email_domain}"
  parent_id = aws_organizations_organizational_unit.infrastructure.id
}
```

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

# 5. Control Tower Guardrail: Prevent S3 Public Access Across All OUs
resource "aws_controltower_control" "prevent_s3_public" {
  control_identifier = "arn:aws:controltower:us-east-1::control/AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED"
  target_identifier  = aws_organizations_organizational_unit.infrastructure.arn
}

# 6. AWS IAM Identity Center Administrator Permission Set
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
```
