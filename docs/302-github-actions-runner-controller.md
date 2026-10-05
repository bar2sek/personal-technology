---
title: "Actions Runner Controller (ARC) Self-Hosted CI/CD Platform"
date: 2026-10-04
tags:
  - ci-cd/github-actions
  - kubernetes/arc
  - security/supply-chain
status: in-progress
aliases:
  - "ARC"
---

# Actions Runner Controller (ARC) Self-Hosted CI/CD Platform

This guide outlines the architecture, security benefits, and Kubernetes deployment manifest for **[Actions Runner Controller (ARC)](https://github.com/actions/actions-runner-controller)** — our primary Kubernetes-native GitHub Actions CI/CD platform.

---

## 🚀 Why Exclusive Actions Runner Controller (ARC)?

By deploying GitHub's official **Actions Runner Controller (ARC)** directly inside our Talos Linux cluster, private-repository workflows, container builds, and infrastructure deployments execute natively on our physical hardware (see the security boundary below):

1. **Direct Private Network Deployment (Zero Exposed Router Ports)**:
   - Runner pods execute inside the cluster, allowing GitHub Actions workflows to apply Kubernetes manifests (`kubectl apply`), execute Helm upgrades, and trigger Talos APIs directly on private subnets (`10.10.x.x`) **without opening any incoming router ports or public endpoints on the UDM-Pro**.
2. **High-Performance Hardware Acceleration**:
   - Container builds leverage our **14C/28T Xeon E5-2680v4** and **Ryzen 3800X** CPUs, **10GbE SFP+ inter-switch backbone**, and **NVMe storage pools** for ultra-fast build times.
3. **GPU-Accelerated Workflows**:
   - Workflows can request `nvidia.com/gpu: 1` resources to run CUDA tests, PyTorch builds, or AI model validation directly on our **NVIDIA RTX 4070 GPU**.
4. **Unlimited Compute & Ephemeral Isolation**:
   - ARC automatically spawns a fresh, isolated ephemeral runner pod for each job and tears it down immediately upon completion, guaranteeing clean, reproducible CI/CD execution with zero execution minute limits.

---

## 🔐 Security Boundary: Private Repositories Only

> [!CAUTION]
> **Never register this runner to a public repository.** A `pull_request` workflow runs the workflow files *from the pull request itself*, so a fork can add a brand-new job with `runs-on: talos-homelab-runner`. That job then executes attacker code on a pod **inside the homelab network**. Changing your own workflows to `ubuntu-latest` does not close this: the runner's registration is the exposure. GitHub's default "require approval for first-time contributors" is not a boundary either, because a single merged trivial PR makes the next one auto-run.

| Control | Implementation |
| :--- | :--- |
| Registration scope | `githubConfigUrl` points at the **private** `bar2sek/homelab-ops` repository |
| Namespace isolation | Runner pods in `arc-runners` with Pod Security `restricted` **enforced**; controller RBAC limited to that namespace |
| Public repo CI | Lint/validate jobs in public repos run on ephemeral GitHub-hosted `ubuntu-latest` runners |
| Authentication | GitHub App installed on one repository; ARC mints 1-hour installation tokens (no PAT) |
| Pod privileges | Non-root (`uid 1001`), `allowPrivilegeEscalation: false`, all capabilities dropped, `RuntimeDefault` seccomp |
| Cluster API access | `automountServiceAccountToken: false`; grant a namespace-scoped ServiceAccount per workflow only when needed |

### GitHub App setup

1. **Create the private repository** `homelab-ops` (GitHub → New repository → Private).
2. **Create a GitHub App** (avatar → Settings → Developer settings → GitHub Apps → New GitHub App):

   | Field | Value | Why |
   | :--- | :--- | :--- |
   | Name | **bar2sek-homelab-arc-runner** | Names are global; shows in audit logs |
   | Homepage URL | `https://github.com/bar2sek/homelab-ops` | Required, informational |
   | Callback URL / user OAuth / Device Flow | blank / unchecked | The App acts as itself, never as a user |
   | Webhook → Active | **unchecked** | ARC's listener *polls* GitHub, so there's no inbound endpoint to expose |
   | Repository permissions | **Administration: Read & write**; Metadata: Read-only (automatic); everything else **No access** | Repo-level runner registration requires repo admin; ARC never reads code |
   | Where can this App be installed | **Only on this account** | Nobody else can install it |

3. **Record the identifiers.** These are not secret, but keep them out of git anyway:
   - **App ID**: the numeric ID on the App's General page (not the `Iv23…` Client ID)
   - **Installation ID**: install the App (**Install App** → **Only select repositories** → `homelab-ops`), then take the number at the end of `github.com/settings/installations/<ID>`
4. **Generate a private key** (bottom of the General page). It downloads to `~/Downloads`. That `.pem` **is** the credential: run `chmod 600` on it and **never move it into the vault**, which syncs to Google Drive.
5. **Create the Secret straight from the `.pem`, then delete it:**

   ```bash
   just gha-runners-secret <app-id> <installation-id> ~/Downloads/bar2sek-homelab-arc-runner.<date>.private-key.pem
   rm ~/Downloads/bar2sek-homelab-arc-runner.*.private-key.pem
   ```

   To rotate later: generate a new key on the App page, re-run the recipe, then delete the old key on GitHub.

### Deployment

ARC is two pinned Helm charts (version in the [Justfile](../Justfile)), configured by values files in [`kubernetes/infrastructure/arc/`](../kubernetes/infrastructure/arc/):

| File | Purpose |
| :--- | :--- |
| [`namespaces.yaml`](../kubernetes/infrastructure/arc/namespaces.yaml) | `arc-systems` (controller, listener) and `arc-runners` (job pods, Pod Security `restricted` **enforced**) |
| [`controller-values.yaml`](../kubernetes/infrastructure/arc/controller-values.yaml) | Controller watches only `arc-runners`, so it gets namespaced Roles and no ClusterRole; hardened pod |
| [`runner-scale-set-values.yaml`](../kubernetes/infrastructure/arc/runner-scale-set-values.yaml) | Private repo URL, GitHub App Secret, hardened runner pod template |

```bash
just gha-runners-deploy
just gha-runners-status
```

> [!WARNING] Don't hand-write the `AutoscalingRunnerSet`
> The controller only reconciles scale sets carrying the chart's version labels and annotations. A raw manifest is silently ignored or rejected. Always deploy through the `gha-runner-scale-set` chart.

### Verification

```bash
# Registered to the PRIVATE repo, listener Running
just gha-runners-status
# Runner pods carry no Kubernetes API token (expect: false)
kubectl -n arc-runners get autoscalingrunnerset talos-homelab-runner \
  -o jsonpath='{.spec.template.spec.automountServiceAccountToken}{"\n"}'
```

Then in GitHub:
- **homelab-ops → Settings → Actions → Runners** lists the `talos-homelab-runner` scale set.
- **personal-technology → Settings → Actions → Runners** lists **no** self-hosted runners.
- **Smoke test:** add `.github/workflows/runner-smoke.yml` to `homelab-ops` with `on: workflow_dispatch` and `runs-on: talos-homelab-runner`, running `id && uname -a`. It should report `uid=1001(runner)`, and an ephemeral pod should appear in `arc-runners`, then disappear.

### Troubleshooting & gotchas

- **Jobs stuck in "Queued" forever:** nothing is registered under that `runs-on:` label. Until 2026-10-04 the public repo's workflows targeted `talos-homelab-runner` while ARC was never actually deployed, which left 75 runs queued. Public-repo workflows now use `ubuntu-latest`.
- **Listener pod `CrashLoopBackOff` with `401`/`404`:** wrong App ID (Client ID used instead), wrong installation ID, or the App isn't installed on `homelab-ops`. Check with `kubectl -n arc-systems logs -l app.kubernetes.io/component=runner-scale-set-listener`.
- **Runner pod rejected with `violates PodSecurity "restricted"`:** a values change weakened the template. Fix the template; never relax the namespace label.
- **A job needs `sudo`, Docker, or cluster access:** it is blocked on purpose. Add it explicitly and narrowly: a custom runner image for tools, or a dedicated namespaced ServiceAccount for `kubectl`.
- **"ARC" is ambiguous here:** `just arc-status` and `just arc-logs` are **Azure Arc**. GitHub runner recipes use the `gha-runners-` prefix.

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

## 📦 ARC Kubernetes Deployment

See [Deployment](#deployment) above. The chart values files are authoritative and are not duplicated here, to avoid drift.
