# Example Terraform Remote Backend Configurations
# Choose either AWS S3 + native S3 lockfile or AzureRM Blob Storage with OIDC

# Option A: AWS Production S3 Backend with Native S3 Lockfile (Terraform 1.10+)
# terraform {
#   backend "s3" {
#     bucket       = "s3-aws-backups-prod-use2-001"
#     key          = "terraform/state/<module-name>/terraform.tfstate"
#     region       = "us-east-2"
#     encrypt      = true
#     use_lockfile = true
#   }
# }

# Option B: AzureRM Production Backend with OIDC Workload Identity
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-azure-tfstate-prod-cus-001"
#     storage_account_name = "stazutfstateprodcus001"
#     container_name       = "tfstate"
#     key                  = "terraform/state/<module-name>/terraform.tfstate"
#     use_azuread_auth     = true
#     use_oidc             = true
#   }
# }
