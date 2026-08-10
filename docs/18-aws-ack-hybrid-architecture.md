# AWS Controllers for Kubernetes (ACK) Hybrid Architecture

This guide details how we leverage **[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/)** to manage AWS Cloud infrastructure (S3, Route53, IAM, ECR) directly from Kubernetes manifests inside our on-premise Talos Linux cluster.

---

## 🚀 What is AWS ACK?

AWS Controllers for Kubernetes (ACK) is an official AWS open-source system that lets you define and provision native AWS cloud resources using custom Kubernetes CRDs (`kubectl apply`).

---

## 🎯 Top 5 Best Use Cases for ACK in Our Cluster

### 1. Offsite Cluster & Database Backups (AWS S3 Controller)
- **Problem**: Storing all cluster backups on local disk leaves us vulnerable to physical disasters (fire, flood, disk array loss).
- **ACK Solution**: Declare AWS S3 buckets in Kubernetes YAML. ACK automatically provisions encrypted, versioned S3 buckets (`s3://bar2sek-homelab-backups`) in AWS.
- **Integration**: **Velero** (cluster snapshots) and **Rook-Ceph** (object replication) stream encrypted backups offsite to AWS S3 automatically.

### 2. Automated Public DNS Management (`bar2sek.com` via Route53 Controller)
- **Problem**: Manually adding DNS records in AWS Route53 whenever a new homelab app is deployed is tedious.
- **ACK Solution**: ACK's Route53 controller creates `RecordSet` CRDs directly when ingress rules are applied, keeping `teslamate.bar2sek.com`, `finance.bar2sek.com`, and `recipes.bar2sek.com` automatically in sync.

### 3. Managed Offsite Cloud Databases (AWS RDS Controller)
- **ACK Solution**: Provision managed AWS RDS PostgreSQL or MySQL instances on-demand in AWS directly from Kubernetes manifests for applications that require offsite cloud database persistence.

### 4. Enterprise IAM Security Federation (AWS IAM Controller)
- **ACK Solution**: Declaratively manage AWS IAM Roles and Policies from Kubernetes YAML files. Integrates directly with our **Authentik + AWS IAM Identity Center SAML 2.0** federation!

### 5. Private Cloud Container Registries (AWS ECR Controller)
- **ACK Solution**: Automatically provision AWS Elastic Container Registry (ECR) repositories for custom application images built by our **GitHub Actions ARC Runners**.

---

## 📦 ACK Kubernetes Manifest Examples

### Example 1: AWS S3 Bucket Manifest (`s3-backup-bucket.yaml`)

```yaml
apiVersion: s3.services.k8s.aws/v1alpha1
kind: Bucket
metadata:
  name: bar2sek-homelab-backups
  namespace: kube-system
spec:
  name: bar2sek-homelab-backups-us-east-1
  sseConfiguration:
    rules:
      - applyServerSideEncryptionByDefault:
          sseAlgorithm: AES256
```

### Example 2: AWS Route53 RecordSet Manifest (`route53-dns-record.yaml`)

```yaml
apiVersion: route53.services.k8s.aws/v1alpha1
kind: RecordSet
metadata:
  name: teslamate-dns-record
  namespace: teslamate
spec:
  hostedZoneID: "Z0123456789ABCDEF" # bar2sek.com Route53 Zone ID
  name: teslamate.bar2sek.com
  type: CNAME
  ttl: 300
  resourceRecords:
    - value: "tunnel.bar2sek.com"
```
