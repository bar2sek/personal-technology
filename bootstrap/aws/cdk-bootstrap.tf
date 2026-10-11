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
  }

  lifecycle {
    # Every CDK deploy in the account depends on this stack.
    prevent_destroy = true
  }
}
