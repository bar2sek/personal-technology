# Automated AWS Account Provisioning via GitHub Actions ARC Runner & Terraform

This guide details the architecture, security configuration, and GitHub Actions workflow YAML to automatically provision new **AWS Accounts** using **Terraform** executing inside our self-hosted **Actions Runner Controller (ARC)** pods inside our cluster.

---

## ⚡ Why ARC-Powered GitOps Account Provisioning?

By executing Terraform inside our cluster's **Actions Runner Controller (ARC)** pods:

1. **100% Free ($0.00/month)**: Eliminates monthly AWS CodePipeline / CodeBuild charges.
2. **Cluster Security**: Secret credentials (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` or SAML STS tokens) are injected directly into ephemeral runner pods that self-destruct after execution.
3. **Pure GitOps Workflow**: Simply add a new `aws_organizations_account` block to `terraform/aws_organization/main.tf` in Git, create a Pull Request, and merge! ARC automatically provisions the new AWS Account!

---

## 📦 GitHub Actions Workflow (`.github/workflows/provision-aws-account.yml`)

```yaml
name: "Provision AWS Account via Terraform & ARC"

on:
  push:
    branches:
      - main
    paths:
      - "terraform/aws_organization/**"
  pull_request:
    branches:
      - main
    paths:
      - "terraform/aws_organization/**"

jobs:
  terraform:
    name: "Terraform AWS Account Provisioning"
    runs-on: talos-homelab-runner # Executes on self-hosted ARC runner pod inside Talos cluster
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform/aws_organization

      - name: Terraform Plan
        run: terraform plan -no-color
        working-directory: ./terraform/aws_organization

      - name: Terraform Apply (Main Branch Only)
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve
        working-directory: ./terraform/aws_organization
```

---

## 💰 Cost Comparison: AFT vs ARC GitOps

| Provisioning Method | Execution Pipeline | Monthly AWS Cost |
| :--- | :--- | :--- |
| **AWS Account Factory (AFT)** | AWS CodePipeline + CodeBuild + KMS + Control Tower | **~$3.00 to $8.00 / month** |
| **ARC Runner GitOps (Selected)** | **Self-Hosted ARC Pod inside Talos Cluster** | **$0.00 (100% Free)** |

