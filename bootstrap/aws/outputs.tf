output "aws_account_id" {
  description = "Target AWS Account ID"
  value       = local.account_id
}

output "aws_region" {
  description = "AWS Deployment Region"
  value       = var.aws_region
}

output "github_actions_role_arn" {
  description = "APPLY role ARN (production environment) -> bootstrap/github var aws_role_arn"
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

output "github_plan_role_arn" {
  description = "Read-only PLAN role ARN (pull requests) -> bootstrap/github var aws_plan_role_arn"
  value       = aws_iam_role.github_plan.arn
}

output "backup_uploader_user_name" {
  description = "Write-only backup uploader IAM user (mint its access key with the CLI, never in Terraform)"
  value       = aws_iam_user.backup_uploader.name
}

output "backup_uploader_user_arn" {
  description = "Backup uploader ARN -> referenced by the backup bucket policy"
  value       = aws_iam_user.backup_uploader.arn
}

output "workload_boundary_policy_arn" {
  description = "Permissions boundary every CI-created workload role must carry"
  value       = aws_iam_policy.workload_boundary.arn
}

output "github_gateway_diff_role_arn" {
  description = "bedrock-ai-gateway PR diff role ARN -> GitHub secret AWS_DIFF_ROLE_ARN"
  value       = aws_iam_role.github_gateway_diff.arn
}

output "github_gateway_deploy_role_arn" {
  description = "bedrock-ai-gateway deploy role ARN -> GitHub environment secret AWS_DEPLOY_ROLE_ARN"
  value       = aws_iam_role.github_gateway_deploy.arn
}
