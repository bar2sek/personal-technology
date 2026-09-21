locals {
  # Dynamically extract root ID suffix (e.g., "r-73t0" -> "73t0") from live AWS Organization if var.root_id is empty
  raw_root_id     = aws_organizations_organization.org.roots[0].id
  derived_root_id = var.root_id != "" ? var.root_id : replace(local.raw_root_id, "r-", "")

  # OU Patterns: ou-<platform>-<category>-<env>-<root-id>
  ou_infrastructure = "ou-${var.platform}-infrastructure-${var.env}-${local.derived_root_id}"
  ou_security       = "ou-${var.platform}-security-${var.env}-${local.derived_root_id}"

  # Account Patterns: acct-<platform>-<category>-<env>-<root-id>
  acct_homelab_prod   = "acct-${var.platform}-${var.product}-${var.env}-${local.derived_root_id}"
  acct_log_archive    = "acct-${var.platform}-security-logarchive-infra-${var.env}-${local.derived_root_id}"
  acct_security_audit = "acct-${var.platform}-security-tooling-infra-${var.env}-${local.derived_root_id}"

  # Permission Set Pattern: pset-<platform>-<product>-<env>-<permission>
  pset_admin = "pset-${var.platform}-${var.product}-${var.env}-admin"

  # Email pattern construction
  email_prod     = "aws-prod@${var.destination_email_domain}"
  email_logs     = "aws-logs@${var.destination_email_domain}"
  email_security = "aws-security@${var.destination_email_domain}"
}
