# ==============================================================================
# AWS CDK bootstrap (stack CDKToolkit) — managed by Terraform
#
# `cdk bootstrap` creates a CloudFormation stack holding the CDK asset bucket,
# ECR repository, the five cdk-<qualifier>-* roles and an SSM version
# parameter. Terraform owns that stack's lifecycle here; CDK owns its contents.
# The template is CDK's own, saved verbatim:
#
#   npx cdk bootstrap --show-template > templates/cdk-bootstrap-v<N>.yaml
#
# Upgrading the bootstrap = save the new version's template as a new file,
# point template_body at it, and review the plan in a pull request.
#
# Never run `cdk bootstrap` against this account/region again: it would update
# the stack outside Terraform and the next plan would revert it.
# ==============================================================================

# Adopts the stack created by `cdk bootstrap` on 2026-10-10. Kept after the
# first apply as a record of where the resource came from; it is a no-op once
# the stack is in state.
import {
  to = aws_cloudformation_stack.cdk_toolkit
  id = "CDKToolkit"
}

resource "aws_cloudformation_stack" "cdk_toolkit" {
  name          = "CDKToolkit"
  template_body = file("${path.module}/templates/cdk-bootstrap-v32.yaml")

  # Acknowledgements CloudFormation requires to create/update this template
  # (IAM roles with fixed names). Same set `cdk bootstrap` passes.
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]

  # The values `cdk bootstrap` deployed with (default qualifier, no custom KMS
  # key). They match the deployed stack so adoption changes nothing.
  parameters = {
    Qualifier                      = local.cdk_qualifier
    BootstrapVariant               = "AWS CDK: Default Resources"
    FileAssetsBucketKmsKeyId       = "AWS_MANAGED_KEY"
    PublicAccessBlockConfiguration = "true"
    DenyExternalId                 = "true"
    UseExamplePermissionsBoundary  = "false"

    # Replaces the template's silent default of AdministratorAccess.
    CloudFormationExecutionPolicies = aws_iam_policy.cdk_cfn_exec.arn
  }

  lifecycle {
    # Every CDK deploy in the account depends on this stack.
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# CloudFormation execution policy — what CDK stacks may create
#
# CloudFormation assumes cdk-<qualifier>-cfn-exec-role to create, update and
# delete every resource in a CDK stack. Left empty, the bootstrap template
# attaches AdministratorAccess to that role. This policy allows only the
# resource types bedrock-ai-gateway uses, and only on resources named after its
# stack (CloudFormation names physical resources <stack>-<logicalId>-<suffix>).
#
# Each statement covers create, read, update and delete: a rollback runs with
# this same role, so a missing delete action would leave a failed deploy stuck
# in UPDATE_ROLLBACK_FAILED.
#
# A new resource type (DynamoDB, CloudWatch alarms, ...) fails the deploy with
# AccessDenied and rolls back. Add the actions here, apply, then redeploy.
# ------------------------------------------------------------------------------
locals {
  cdk_gateway_stack = "BedrockAiGateway"
}

resource "aws_iam_policy" "cdk_cfn_exec" {
  name        = local.iam_policy_cdk_cfn_exec_name
  description = "CDK CloudFormation execution policy: resources for the ${local.cdk_gateway_stack} stack only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # The CDK-generated template checks the bootstrap version parameter.
        Sid      = "ReadBootstrapVersion"
        Effect   = "Allow"
        Action   = ["ssm:GetParameters"]
        Resource = "arn:aws:ssm:${var.aws_region}:${local.account_id}:parameter/cdk-bootstrap/${local.cdk_qualifier}/version"
      },
      {
        # Lambda reads the function's code bundle from the asset bucket with
        # the caller's (this role's) permissions.
        Sid      = "ReadAssets"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "arn:aws:s3:::cdk-${local.cdk_qualifier}-assets-${local.account_id}-${var.aws_region}/*"
      },
      {
        # Asset objects are encrypted with the AWS-managed S3 key.
        Sid      = "DecryptAssetsViaS3"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = { "kms:ViaService" = "s3.${var.aws_region}.amazonaws.com" }
        }
      },
      {
        Sid    = "LambdaFunctions"
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:PutFunctionConcurrency",
          "lambda:DeleteFunctionConcurrency",
          "lambda:PutRuntimeManagementConfig",
          "lambda:PutFunctionRecursionConfig",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:Get*",
          "lambda:List*",
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${local.account_id}:function:${local.cdk_gateway_stack}-*"
      },
      {
        # Network lookups the Lambda resource handler makes; read-only.
        Sid      = "LambdaHandlerLookups"
        Effect   = "Allow"
        Action   = ["ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVpcs", "ec2:DescribeNetworkInterfaces"]
        Resource = "*"
      },
      {
        # The function's execution role and its inline policy.
        Sid    = "LambdaExecutionRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
        ]
        Resource = "arn:aws:iam::${local.account_id}:role/${local.cdk_gateway_stack}-*"
      },
      {
        Sid      = "PassRoleToLambdaOnly"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "arn:aws:iam::${local.account_id}:role/${local.cdk_gateway_stack}-*"
        Condition = {
          StringEquals = { "iam:PassedToService" = "lambda.amazonaws.com" }
        }
      },
      {
        Sid    = "LogGroups"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:ListTagsForResource",
          "logs:TagLogGroup",
          "logs:UntagLogGroup",
          "logs:ListTagsLogGroup",
        ]
        # The trailing * also matches the ":*" (log streams) form of the ARN.
        Resource = "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${local.cdk_gateway_stack}-*"
      },
      {
        # DescribeLogGroups does not support resource-level scoping.
        Sid      = "DescribeLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "*"
      },
      {
        # REST APIs, stages, API keys and usage plans. API Gateway's IAM model
        # is HTTP verbs on resource paths; the region-wide path is the
        # narrowest scope that covers API keys and usage plans.
        Sid      = "ApiGateway"
        Effect   = "Allow"
        Action   = ["apigateway:GET", "apigateway:POST", "apigateway:PUT", "apigateway:PATCH", "apigateway:DELETE"]
        Resource = "arn:aws:apigateway:${var.aws_region}::/*"
      },
    ]
  })
}
