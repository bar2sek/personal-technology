# Example Terraform Remote Backend Configurations
# Choose either AWS S3 + DynamoDB (Production Cloud) or Floci (In-Cluster Offline)

# Option A: AWS Production S3 Backend with DynamoDB State Locking
# terraform {
#   backend "s3" {
#     bucket         = "s3-aws-backups-prod-use2-001"
#     key            = "terraform/state/<module-name>/terraform.tfstate"
#     region         = "us-east-2"
#     dynamodb_table = "dynamo-aws-tfstate-lock-prod-use2-001"
#     encrypt        = true
#   }
# }

# Option B: Floci In-Cluster AWS Emulator Backend (Zero Cost / Offline)
# terraform {
#   backend "s3" {
#     bucket                      = "floci-tfstate-bucket"
#     key                         = "terraform/state/<module-name>/terraform.tfstate"
#     region                      = "us-east-2"
#     endpoint                    = "http://floci.aws-emulator.svc.cluster.local:4566"
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     force_path_style            = true
#   }
# }
