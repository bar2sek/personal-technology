output "aws_account_id" {
  description = "Target AWS Account ID"
  value       = local.account_id
}

output "aws_region" {
  description = "AWS Deployment Region"
  value       = var.aws_region
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions OIDC runner"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "IAM Role Name for GitHub Actions"
  value       = aws_iam_role.github_actions.name
}

output "tfstate_s3_bucket" {
  description = "S3 Bucket Name for Remote State Backend"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_dynamodb_table" {
  description = "DynamoDB Table Name for State Locking"
  value       = aws_dynamodb_table.tflocks.name
}
