locals {
  # AWS Resource Pattern: <abbrev>-aws-<product>-<env>-<region-code>-<iteration>
  s3_backup_bucket_name = "s3-${var.platform}-${var.product}-${var.env}-${var.region_code}-${var.iteration}"
  r53_zone_name          = "r53-${var.platform}-primary-${var.env}-${var.region_code}-${var.iteration}"
  iam_role_eks_connector = "role-${var.platform}-eks-connector-${var.env}-admin"
}
