# AWS EKS Connector & Unified AWS Console Management

This guide details the capabilities, IAM authentication, and Kubernetes deployment manifest for **[AWS EKS Connector](https://docs.aws.amazon.com/eks/latest/userguide/eks-connector.html)** — connecting our physical Talos Linux cluster directly into the AWS Management Console.

---

## 🚀 Key Benefits: What Does EKS Connector Add?

Beyond basic observability, AWS EKS Connector transforms our physical homelab into a first-class hybrid region in AWS:

1. **AWS Web Console Cluster Browsing**:
   - Log into the official **AWS Management Console**, navigate to **Amazon EKS > Clusters**, and view your physical Talos nodes (`sm-node-01` through `pc-node-05`), namespaces, deployments, pods, and real-time Kubernetes events from anywhere in the world!
2. **AWS IAM Console Authentication (IAM Access Entries)**:
   - Grant AWS IAM users and federated **Authentik SAML 2.0** users direct read/admin permissions to inspect on-premise cluster workloads via the AWS Console UI without sharing raw `kubeconfig` files.
3. **AWS CloudWatch Container Insights & Alarms**:
   - Stream container logs, CPU/Memory metrics, and node health telemetry directly into AWS CloudWatch. Set up automated AWS SNS email/SMS alerts if a node fails or storage disk fills up.
4. **AWS Security Hub & GuardDuty Container Security**:
   - Enables AWS GuardDuty to monitor on-premise pod activity for suspicious network connections, privilege escalation, or container security vulnerabilities.
5. **Unified Cloud-Native Governance**:
   - Manage multi-cluster environments (on-premise Talos + cloud AWS EKS clusters) under a single AWS Organizations governance umbrella.

---

## 💵 AWS Cost Breakdown & Monthly Price Estimate

Connecting an on-premise Kubernetes cluster to AWS via EKS Connector incurs **$0.00 in cluster registration fees**. Below is the complete monthly cost breakdown for our hybrid AWS integration:

| AWS Component | Pricing Details | Monthly Cost |
| :--- | :--- | :--- |
| **AWS EKS Connector** | **100% Free**. AWS charges $0 to register external Kubernetes clusters. | **$0.00** |
| **AWS SSM Agent (Systems Manager)** | **100% Free** for on-premise instance management. | **$0.00** |
| **AWS ACK Controllers** | **100% Free**. ACK pods run inside local cluster hardware. | **$0.00** |
| **AWS Route53 Hosted Zone** | Fixed rate for `bar2sek.com` public DNS zone. | **$0.50 / month** |
| **AWS S3 Offsite Backups** | AWS Free Tier includes 5 GB free. 50GB of Velero backups costs ~$0.01/GB. | **~$0.50 / month** |
| **AWS CloudWatch Metrics/Logs** | AWS Free Tier includes 5 GB ingestion & 5 GB storage per month. | **$0.00** (Free Tier) |
| **TOTAL ESTIMATED AWS BILL** | | **~$1.00 / month** |

---

## 📦 AWS EKS Connector Kubernetes Manifest (`eks-connector.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: eks-connector
---
# EKS Connector Service Account & ClusterRoleBinding
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-connector
  namespace: eks-connector
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: eks-connector-binding
subjects:
  - kind: ServiceAccount
    name: eks-connector
    namespace: eks-connector
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
# AWS Systems Manager (SSM) EKS Connector Agent
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eks-connector
  namespace: eks-connector
spec:
  replicas: 2
  selector:
    matchLabels:
      app: eks-connector
  template:
    metadata:
      labels:
        app: eks-connector
    spec:
      serviceAccountName: eks-connector
      containers:
        - name: connector
          image: public.ecr.aws/amazon-ssm-agent/amazon-ssm-agent:latest
          env:
            - name: AWS_REGION
              value: "us-east-1"
            - name: ACTIVATION_CODE
              valueFrom:
                secretKeyRef:
                  name: eks-connector-activation
                  key: code
            - name: ACTIVATION_ID
              valueFrom:
                secretKeyRef:
                  name: eks-connector-activation
                  key: id
```
