# Floci: In-Cluster Local AWS Cloud Emulator for Terraform & CI/CD Testing

This guide details how to deploy **[Floci](https://github.com/floci-io/floci)** inside our Talos Kubernetes cluster as a high-performance, 100% open-source (MIT) **LocalStack alternative** for zero-cost, offline AWS Terraform testing, SDK emulation, and GitHub Actions ARC CI/CD validation.

---

## 🚀 What is Floci?

Floci is a lightweight, ultra-fast AWS cloud emulator designed as a drop-in, no-strings-attached alternative to LocalStack:

- **Lightning Performance**: Sub-30ms startup time and ~15 MiB idle memory footprint (powered by Quarkus & GraalVM native binary).
- **100% Free & Open-Source (MIT)**: Zero licensing restrictions, no paid pro tiers, no authentication tokens, and zero telemetry.
- **Drop-in Wire Protocol**: Listens on standard port `4566`, supporting native AWS CLI, AWS SDKs, **Terraform AWS Provider**, and AWS CDK.
- **Supported Core Services**: Emulates S3, DynamoDB, SQS, SNS, IAM, Route53, KMS, Lambda, SSM, and CloudWatch.

---

## 📐 Architecture in Our Talos Cluster

```
 +-----------------------------------------------------------------------------------+
 |                             Talos Kubernetes Cluster                              |
 |                                                                                   |
 |  +-----------------------------------------------------------------------------+  |
 |  |                       GitHub Actions ARC Ephemeral Runner                   |  |
 |  |  - Runs `terraform test` / `terraform apply`                                |  |
 |  |  - Configured with custom AWS endpoints pointing to Floci Service           |  |
 |  +-----------------------------------------------------------------------------+  |
 |                                         |
 |                          Internal HTTP  | (Port 4566)
 |                                         v
 |  +-----------------------------------------------------------------------------+  |
 |  |                       Floci Local AWS Emulator Pod                          |  |
 |  |  - Namespace: `aws-emulator`                                                |  |
 |  |  - Service: `floci.aws-emulator.svc.cluster.local:4566`                     |  |
 |  |  - PVC: Persistent storage on Rook-Ceph SSD Pool (persists S3 & tables)     |  |
 |  +-----------------------------------------------------------------------------+  |
 +-----------------------------------------------------------------------------------+
```

---

## 📦 Floci Kubernetes Manifest (`kubernetes/floci/floci.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: aws-emulator
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: floci-data-pvc
  namespace: aws-emulator
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: floci
  namespace: aws-emulator
  labels:
    app: floci
spec:
  replicas: 1
  selector:
    matchLabels:
      app: floci
  template:
    metadata:
      labels:
        app: floci
    spec:
      containers:
        - name: floci
          image: ghcr.io/floci-io/floci:latest
          ports:
            - name: aws-api
              containerPort: 4566
          env:
            - name: FLOCI_DATA_DIR
              value: "/data"
            - name: SERVICES
              value: "s3,dynamodb,sqs,sns,iam,route53,kms,ssm,cloudwatch"
            - name: AWS_DEFAULT_REGION
              value: "us-east-2"
          volumeMounts:
            - name: floci-storage
              mountPath: /data
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 500m
              memory: 512Mi
      volumes:
        - name: floci-storage
          persistentVolumeClaim:
            claimName: floci-data-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: floci
  namespace: aws-emulator
spec:
  selector:
    app: floci
  ports:
    - name: aws-api
      port: 4566
      targetPort: 4566
```

---

## 🛠 Testing Terraform Against Local Floci

To target Floci instead of live AWS, configure endpoint overrides in your Terraform provider:

```hcl
# Example: terraform/local_test/providers.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3         = "http://floci.aws-emulator.svc.cluster.local:4566"
    dynamodb   = "http://floci.aws-emulator.svc.cluster.local:4566"
    sqs        = "http://floci.aws-emulator.svc.cluster.local:4566"
    sns        = "http://floci.aws-emulator.svc.cluster.local:4566"
    iam        = "http://floci.aws-emulator.svc.cluster.local:4566"
    route53    = "http://floci.aws-emulator.svc.cluster.local:4566"
    kms        = "http://floci.aws-emulator.svc.cluster.local:4566"
    ssm        = "http://floci.aws-emulator.svc.cluster.local:4566"
    cloudwatch = "http://floci.aws-emulator.svc.cluster.local:4566"
  }
}
```

---

## ⚡ Benefits for Your Learning & Homelab

1. **Zero AWS Cost ($0.00)**: Rapidly prototype Terraform modules (S3 buckets, IAM roles, SQS queues, DynamoDB tables) thousands of times locally without risking AWS API fees.
2. **Instant Feedback**: Terraform plans and applies execute in milliseconds over in-cluster networking.
3. **CI/CD Integration**: Our self-hosted **GitHub Actions ARC runner pods** can run automated Terraform unit tests against Floci on every Pull Request before merging to `main`!
