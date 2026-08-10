output "route53_zone_id" {
  value       = aws_route53_zone.primary.zone_id
  description = "Route53 Primary Hosted Zone ID"
}

output "route53_name_servers" {
  value       = aws_route53_zone.primary.name_servers
  description = "Route53 Primary Hosted Zone Name Servers"
}

output "s3_backup_bucket_name" {
  value       = aws_s3_bucket.backups.id
  description = "S3 Backup Bucket Name"
}

output "s3_backup_bucket_arn" {
  value       = aws_s3_bucket.backups.arn
  description = "S3 Backup Bucket ARN"
}

output "eks_connector_role_arn" {
  value       = aws_iam_role.eks_connector.arn
  description = "AWS IAM Role ARN for EKS Connector"
}
