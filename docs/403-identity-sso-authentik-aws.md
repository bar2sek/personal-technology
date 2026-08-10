# Single Sign-On (SSO) & AWS SAML 2.0 Identity Federation

This guide outlines the enterprise architecture, security flow, and Kubernetes deployment manifest for **[Authentik](https://goauthentik.io/)** — our master External Identity Provider (External IdP) federated with **AWS IAM Identity Center** via SAML 2.0.

---

## 🚀 Enterprise Architecture: Authentik + AWS IAM Identity Center

In enterprise cloud environments, organizations use a dedicated External Identity Provider (External IdP) to manage user authentication, enforcing strong MFA/Passkeys before federating access into AWS.

In our architecture, **Authentik** operates as the master External IdP, issuing signed SAML 2.0 assertions to **AWS IAM Identity Center**.

### Federation Flow Diagram:

```
  +--------------------------------------------------------------------------------+
  |                     Hybrid Identity Federation Topology                        |
  |                                                                                |
  |  1. USER AUTHENTICATION (Authentik Master IdP in Homelab)                      |
  |     - User logs into Authentik using Passkeys (TouchID / FaceID), YubiKey, or PIN.|
  |                                                                                |
  |  2. SAML 2.0 FEDERATION (Authentik ---> AWS IAM Identity Center)               |
  |     - Authentik issues a signed SAML 2.0 assertion token to AWS.              |
  |     - AWS Security Token Service (STS) calls AssumeRoleWithSAML.               |
  |                                                                                |
  |  3. AUTHORIZED CLOUD ACCESS (AWS Console / CLI / ACK / Terraform)              |
  |     - User receives temporary, short-lived AWS IAM credentials for AWS Console,  |
  |       AWS CLI (`aws sso login`), Terraform, and AWS ACK Kubernetes CRDs!        |
  +--------------------------------------------------------------------------------+
```

---

## 🏢 Enterprise Corporate vs Homelab Architecture Alignment

| Architectural Component | Enterprise Corporate Pattern | Our Homelab Implementation |
| :--- | :--- | :--- |
| **External Identity Provider (IdP)** | Okta / Entra ID (Azure AD) / Ping | **Authentik** (Self-Hosted in Kubernetes) |
| **Federation Protocol** | SAML 2.0 / OIDC | **SAML 2.0 / OIDC** |
| **AWS Single Sign-On Target** | AWS IAM Identity Center | **AWS IAM Identity Center** |
| **Credential Issuance** | AWS STS (`AssumeRoleWithSAML`) | **AWS STS (`AssumeRoleWithSAML`)** |
| **User Authentication** | Enterprise SSO + Hardware Keys | **Passkeys (TouchID / FaceID) + Authentik** |

---

## 🔐 Standardized IdP Access Group Mapping

All Authentik groups and AWS IAM Identity Center permission sets follow the global naming standard:

```html
<idp-source>-<platform>-<product>-<env>-<resource-id>-<permission-set>
```

### Examples:
- **`authentik-aws-homelab-prod-73t0-admin`**: Maps to AWS Permission Set `pset-aws-homelab-prod-admin` (Full Administrator Access).
- **`authentik-aws-homelab-prod-73t0-read`**: Maps to AWS Permission Set `pset-aws-homelab-prod-read` (ReadOnly Access).
- **`authentik-aws-immich-prod-73t0-admin`**: Immich Photo Manager Administrator Group.

## 📚 AWS Certification Exam Topics Mastered with this Architecture

- **AWS Solutions Architect (Associate & Professional)**: *Federated Single Sign-On using SAML 2.0 / OIDC External Identity Providers*.
- **AWS Security Specialty**: *AWS Security Token Service (STS) `sts:AssumeRoleWithSAML`*, *Cross-Account IAM Roles*, *Attribute-Based Access Control (ABAC)*.
- **Hands-On Skills**: Configures AWS CLI `aws sso login` backed by our custom `bar2sek.com` domain!

## 📦 Authentik Kubernetes Deployment Manifest (`authentik.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: identity
---
# PostgreSQL PVC backed by Rook-Ceph SSD Pool
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: authentik-db-pvc
  namespace: identity
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 10Gi
---
# Authentik Server Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authentik-server
  namespace: identity
spec:
  replicas: 1
  selector:
    matchLabels:
      app: authentik-server
  template:
    metadata:
      labels:
        app: authentik-server
    spec:
      containers:
        - name: authentik-server
          image: ghcr.io/goauthentik/server:latest
          args: ["server"]
          env:
            - name: AUTHENTIK_REDIS__HOST
              value: authentik-redis
            - name: AUTHENTIK_POSTGRESQL__HOST
              value: authentik-db
            - name: AUTHENTIK_POSTGRESQL__NAME
              value: authentik
            - name: AUTHENTIK_POSTGRESQL__USER
              value: authentik
            - name: AUTHENTIK_POSTGRESQL__PASSWORD
              valueFrom:
                secretKeyRef:
                  name: authentik-secrets
                  key: db-password
          ports:
            - containerPort: 9000
              name: http
            - containerPort: 9443
              name: https
```
