---
title: "Azure Cloud & AI Transformation Roadmap: Homelab Hybrid Architecture"
date: 2026-10-15
tags:
  - azure
  - cloud/hybrid
  - azure-arc
  - ai-engineering
  - terraform
  - az-305
  - ai-102
status: in-progress
aliases:
  - "Azure Homelab Roadmap"
  - "Azure Cloud Transformation"
  - "Azure AI Architecture Plan"
---

# 🔷 Azure Cloud & AI Transformation Roadmap: Homelab Hybrid Architecture

> [!IMPORTANT] Strategic Transformation Objective
> This document establishes the master architectural blueprint and execution roadmap for migrating our hybrid cloud integrations from AWS to **Microsoft Azure**. The goal is twofold: operational alignment with enterprise Azure hybrid design, and hands-on preparation for the **AZ-104 (Administrator)**, **AZ-305 (Solutions Architect Expert)**, and **AI-102 (Azure AI Engineer Associate)** certifications.

---

## 🏛️ Executive Architecture & Paradigm Shift

Our homelab previously maintained hybrid integrations with AWS (AWS EKS Connector, S3 Object Lock backups, and an Amazon Bedrock RAG gateway). While functional, transitioning these workloads to **Microsoft Azure** elevates our platform architecture into a tightly governed enterprise hybrid model.

```mermaid
graph TD
    subgraph OnPrem ["Physical Homelab (Talos Linux Cluster)"]
        Workloads["Homelab Services & Stateful Apps"]
        ArcAgent["Azure Arc Agents<br/>(clusterconnect & ama-logs)"]
        BackupCron["Cluster State & DB Backup Jobs"]
        ClientApps["Downstream AI Clients"]
    end

    subgraph Azure_Cloud ["Microsoft Azure Cloud (Cloud Adoption Framework)"]
        subgraph Governance ["Identity, Security & Management"]
            Entra["Microsoft Entra ID<br/>(OIDC Workload Identity)"]
            PIM["PIM & Role-Based Access Control"]
            Policy["Azure Policy for Kubernetes"]
            LAW["Log Analytics Workspace<br/>(Capped at 0.16 GB/day)"]
        end

        subgraph Hybrid_Plane ["Hybrid & Storage Plane"]
            Arc["Azure Arc-Enabled Kubernetes"]
            Storage["Azure Blob Storage<br/>(Immutable WORM + Tiering)"]
        end

        subgraph AI_Plane ["Azure AI Foundry & Gateway"]
            APIM["Azure API Management<br/>(Consumption / GenAI Policies)"]
            AOAI["Azure OpenAI Service<br/>(gpt-4o-mini inference)"]
            AISearch["Azure AI Search<br/>(Hybrid BM25 + Vector)"]
            ContentSafety["Azure AI Content Safety<br/>(Prompt Shields & Grounding)"]
        end
    end

    ArcAgent -->|Outbound TLS 443 Tunnel| Arc
    ArcAgent -->|Telemetry Stream| LAW
    Policy -->|Audit & Enforce| ArcAgent
    BackupCron -->|Encrypted Blob Ingestion| Storage
    ClientApps -->|Single Governed Endpoint| APIM
    APIM --> ContentSafety
    APIM --> AOAI
    AOAI <--> AISearch
    Entra -.->|Zero-Trust OIDC Auth| Azure_Cloud
```

---

## 🔄 Service Translation: AWS Estate to Azure Target

| Architectural Capability | Current AWS Footprint | Target Azure Target | Certification Alignment |
| :--- | :--- | :--- | :--- |
| **Generative AI Gateway** | `bedrock-ai-gateway` (CDK + Lambda) | **Azure AI Foundry / APIM + Azure Functions** | **AI-102 & AZ-305** |
| **Vector Search & RAG** | Bedrock Knowledge Base (S3 Vectors + Titan) | **Azure AI Search** (Vector + Semantic Ranker) | **AI-102** |
| **AI Safety & Guardrails** | Bedrock Guardrails (PII / Grounding) | **Azure AI Content Safety** (Prompt Shields) | **AI-102** |
| **Hybrid Kubernetes Control** | AWS EKS Connector (SSM tunnel) | **Azure Arc-Enabled Kubernetes** | **AZ-104 & AZ-305** |
| **Offsite Disaster Recovery** | S3 Bucket (Object Lock WORM + Lifecycle) | **Azure Blob Storage** (Time-based Immutability) | **AZ-305** |
| **Identity & Access Management** | IAM Identity Center + Authentik SAML | **Microsoft Entra ID** + Authentik Federation | **AZ-104 & AZ-305** |
| **Multi-Tier Governance** | AWS Organizations & SCPs | **Management Groups & Azure Policy** | **AZ-104 & AZ-305** |
| **CI/CD Authentication** | GitHub Actions AWS OIDC | **GitHub Actions Azure Federated Credentials** | **AZ-305** |

---

## 🚫 Architectural Decision: Elimination of Local Emulators (Floci & Azurite)

In early architectural revisions, local cloud emulators (**Floci** for AWS S3/SQS and **Azurite** for Azure Storage) were evaluated to enable offline testing. 

**Decision: Deprecate and remove all local cloud emulators.**

### Rationale:
1. **Control Plane vs. Data Plane Gap**: Emulators mock individual storage APIs, but cannot emulate Azure Resource Manager (ARM), Azure Arc agents, Azure OpenAI inference profiles, or Entra ID OAuth flows. Testing against an emulator provides zero validation for actual ARM templates, Bicep, or Terraform `azurerm` provider logic.
2. **Resource Efficiency**: Running mock services on cluster NVMe storage and RAM detracts from production homelab workloads (Ceph, KubeVirt, Home Assistant).
3. **Speculative Plan Pattern**: Infrastructure validation is far more accurately performed via GitHub Actions PR speculative plans (`terraform plan`) against isolated Azure sandbox resource groups using short-lived OIDC workload identity tokens.
4. **Static Tooling**: Linting and semantic syntax verification are handled instantaneously on workstations via `terraform fmt`, `terraform validate`, and `tflint`.

---

## 🛠️ Workload Specifications & Engineering Details

### 1. Azure AI Gateway (`azure-ai-gateway`)
Replaces the AWS Bedrock CDK stack with an enterprise Azure AI stack:
* **LLM Engine**: Azure OpenAI Service running `gpt-4o-mini`.
* **RAG & Search**: Azure AI Search leveraging hybrid retrieval (dense vector embeddings via `text-embedding-3-small` combined with BM25 full-text keyword indexing and semantic re-ranking).
* **Guardrails & Evaluation**: Azure AI Content Safety integrating:
  * Prompt Shields against jailbreak and indirect prompt injection.
  * Protected Material detection.
  * Groundedness detection comparing model output against retrieved search chunks.
* **Edge Governance**: Azure API Management (Consumption Tier) providing API key validation, subscription usage limits, and token rate limiting.

### 2. Azure Arc-Enabled Talos Cluster
Codified in [[408-azure-arc-hybrid-kubernetes|docs/408-azure-arc-hybrid-kubernetes.md]]:
* **Zero Firewall Pinholes**: Outbound-only WebSocket reverse tunnel (`clusterconnect-agent`) over TCP port 443 to the Azure cloud.
* **Strict Telemetry Budgeting**:
  * Log Analytics Workspace (`law-azure-monitoring-prod-cus-001`) capped with `daily_quota_gb = 0.16` (~5 GB/month).
  * Data Collection Rules (DCR) filter out verbose container stdout/stderr, collecting strictly essential cluster metrics, pod inventories, and events.
* **Azure Policy Enforcement**: Enforces Azure baseline pod security standards directly on bare-metal Talos nodes.

### 3. Encrypted Immutable Offsite Backups
* **Storage Account**: `stazurebackupsprodcus001` (Central US, GRS or LRS).
* **Immutability Policy**: Time-based retention policies (WORM compliant) ensuring cluster state manifests and PostgreSQL database dumps cannot be deleted or overwritten by any identity (ransomware guardrail).
* **Lifecycle Automation**: Automated tier transition (Hot $\to$ Cool after 7 days $\to$ Archive after 30 days) and automated purge after 35 days.

### 4. Identity & CI/CD Workload Federation
* **Entra ID + Authentik**: Seamless enterprise SSO between local Authentik IdP and Microsoft Entra ID per [[407-azure-entra-id-authentik-federation|docs/407-azure-entra-id-authentik-federation.md]].
* **GitHub Actions Workload Identity**: Zero static credentials in GitHub Secrets. Ephemeral OIDC tokens minted per-job via `token.actions.githubusercontent.com` matching the `production` environment subject claim.

---

## 📅 Phased Execution Roadmap

```mermaid
gantt
    title Azure Cloud & AI Transformation Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 1: Foundation
    Terraform Azure Provider & OIDC Setup       :p1_1, 2026-10-15, 5d
    Storage Account & Immutability Policies      :p1_2, after p1_1, 5d
    Backup CronJobs Cutover to Azure Blob       :p1_3, after p1_2, 4d
    section Phase 2: Hybrid Arc
    Azure Arc Helm Manifests Deployment         :p2_1, after p1_3, 4d
    Log Analytics & DCR Ingestion Quota Cap     :p2_2, after p2_1, 3d
    Azure Policy Validation on Talos Nodes      :p2_3, after p2_2, 3d
    section Phase 3: AI Gateway
    Azure OpenAI & AI Search Provisioning       :p3_1, after p2_3, 7d
    TypeScript Gateway Port (Azure SDKs)        :p3_2, after p3_1, 7d
    Content Safety Guardrails Integration       :p3_3, after p3_2, 5d
    section Phase 4: AWS Decommission
    Drain & Destroy AWS Resources via Terraform :p4_1, after p3_3, 4d
    Clean Up Stale AWS Roles & Bootstrap        :p4_2, after p4_1, 3d
```

### Phase 1: Storage & Cloud Foundation
1. Extend `infra-cloud-deployments/terraform/azure/`:
   - Declare resource groups (`rg-azure-workloads`, `rg-azure-monitoring`).
   - Provision `stazurebackupsprodcus001` with time-based immutable container `backups`.
2. Update Kubernetes backup CronJobs in `personal-technology/kubernetes/infrastructure/backups/` to target Azure Blob Storage using `azcopy` or Azure CLI with workload tokens.

### Phase 2: Azure Arc Hybrid Onboarding
1. Deploy Azure Arc Connected Cluster agents into the `azure-arc` namespace on Talos.
2. Verify node health, cluster workloads, and event streaming in the Azure Portal.
3. Validate that Log Analytics daily quota limits are active and alerting on threshold breaches.

### Phase 3: Azure AI Gateway
1. Deploy Azure OpenAI Service (`gpt-4o-mini`) and Azure AI Search index in `infra-cloud-deployments`.
2. Port `bedrock-ai-gateway` application code from `@aws-sdk/client-bedrock-runtime` to `@azure/openai` and `@azure/search-documents`.
3. Integrate Azure AI Content Safety evaluation hooks and verify prompt defense and groundedness.

### Phase 4: AWS Decommission & Sunset
1. Verify 100% operational autonomy on Azure.
2. Run `terraform destroy` against `infra-cloud-deployments/terraform/aws/`.
3. Archive or delete legacy AWS documentation and decommission `bedrock-ai-gateway`.
