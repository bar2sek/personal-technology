# Actions Runner Controller (ARC) Self-Hosted CI/CD Platform

This guide outlines the architecture, security benefits, and Kubernetes deployment manifest for **[Actions Runner Controller (ARC)](https://github.com/actions/actions-runner-controller)** — our primary Kubernetes-native GitHub Actions CI/CD platform.

---

## 🚀 Why Exclusive Actions Runner Controller (ARC)?

By deploying GitHub's official **Actions Runner Controller (ARC)** directly inside our Talos Linux cluster, all repository workflows, container builds, and infrastructure deployments execute natively on our physical hardware:

1. **Direct Private Network Deployment (Zero Exposed Router Ports)**:
   - Runner pods execute inside the cluster, allowing GitHub Actions workflows to apply Kubernetes manifests (`kubectl apply`), execute Helm upgrades, and trigger Talos APIs directly on private subnets (`10.10.x.x`) **without opening any incoming router ports or public endpoints on the UDM-Pro**.
2. **High-Performance Hardware Acceleration**:
   - Container builds leverage our **14C/28T Xeon E5-2680v4** and **Ryzen 3800X** CPUs, **10GbE SFP+ inter-switch backbone**, and **NVMe storage pools** for ultra-fast build times.
3. **GPU-Accelerated Workflows**:
   - Workflows can request `nvidia.com/gpu: 1` resources to run CUDA tests, PyTorch builds, or AI model validation directly on our **NVIDIA RTX 4070 GPU**.
4. **Unlimited Compute & Ephemeral Isolation**:
   - ARC automatically spawns a fresh, isolated ephemeral runner pod for each job and tears it down immediately upon completion, guaranteeing clean, reproducible CI/CD execution with zero execution minute limits.

---

## 🛠 Kubernetes Architecture: Actions Runner Controller (ARC)

GitHub provides an official open-source Kubernetes operator called **[Actions Runner Controller (ARC)](https://github.com/actions/actions-runner-controller)**.

```
 +--------------------------------------------------------------------------------+
 |                           Talos Kubernetes Cluster                             |
 |                                                                                |
 |  +--------------------------------------------------------------------------+  |
 |  |                    Actions Runner Controller (ARC)                       |  |
 |  |  - Listens to GitHub Repository / Organization Webhooks                  |  |
 |  |  - Auto-scales ephemeral Runner Pods on-demand                             |  |
 |  +--------------------------------------------------------------------------+  |
 |                                      |                                         |
 |             +------------------------+------------------------+                |
 |             v                                                 v                |
 |  +--------------------+                             +--------------------+     |
 |  | Ephemeral Runner   |                             | Ephemeral Runner   |     |
 |  | Pod #1 (Builds)    |                             | Pod #2 (Deployments|     |
 |  +--------------------+                             +--------------------+     |
 +--------------------------------------------------------------------------------+
```

---

## 📦 ARC Kubernetes Deployment Manifest (`arc-runner-set.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: actions-runner-system
---
# GitHub Actions Ephemeral Auto-Scaling Runner Set
apiVersion: actions.github.com/v1alpha1
kind: AutoscalingRunnerSet
metadata:
  name: talos-homelab-runner
  namespace: actions-runner-system
spec:
  githubConfigUrl: "https://github.com/bar2sek/talos-aws-homelab"
  minReplicas: 0
  maxReplicas: 5
  template:
    spec:
      containers:
        - name: runner
          image: ghcr.io/actions/actions-runner:latest
          command: ["/home/runner/run.sh"]
```
