data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # GitHub Immutable ID Format for OIDC assertion
  github_repo_immutable = "bar2sek@6226865/infra-cloud-deployments@1378897273"

  # Standardized Resource Naming
  iam_role_github_actions_name = "role-${var.platform}-github-actions-${var.env}-${var.iteration}"
  s3_tfstate_bucket_name       = "s3-${var.platform}-tfstate-${var.env}-${var.region_code}-${local.account_id}"
  dynamodb_lock_table_name     = "ddb-${var.platform}-tflocks-${var.env}-${var.region_code}-${var.iteration}"
}
