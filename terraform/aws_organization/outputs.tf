output "organization_arn" {
  value       = aws_organizations_organization.org.arn
  description = "ARN of the AWS Organization"
}

output "organization_root_id" {
  value       = aws_organizations_organization.org.roots[0].id
  description = "Root ID of the AWS Organization"
}

output "homelab_prod_account_id" {
  value       = aws_organizations_account.homelab_prod.id
  description = "AWS Account ID for homelab production workload"
}

output "log_archive_account_id" {
  value       = aws_organizations_account.log_archive.id
  description = "AWS Account ID for Log Archive account"
}

output "security_audit_account_id" {
  value       = aws_organizations_account.security_audit.id
  description = "AWS Account ID for Security Audit account"
}

output "infrastructure_ou_id" {
  value       = aws_organizations_organizational_unit.infrastructure.id
  description = "ID of Infrastructure Organizational Unit"
}

output "security_ou_id" {
  value       = aws_organizations_organizational_unit.security.id
  description = "ID of Security Organizational Unit"
}
