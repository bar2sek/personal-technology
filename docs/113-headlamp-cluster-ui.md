---
title: "Headlamp: Read-Only Kubernetes Web UI"
date: 2026-11-03
tags:
  - homelab/operations
  - kubernetes/headlamp
  - security/rbac
status: in-progress
aliases:
  - "Headlamp"
  - "Cluster UI"
---

# 🔦 Headlamp: Read-Only Kubernetes Web UI

> [!NOTE]
> **Status (2026-11-03): deployed and verified.** Pod running, Tailscale ingress serving `https://headlamp.tail6e33.ts.net` (HTTP 200), `just headlamp-rbac-check` 7/7.
>
> **Status (2026-11-05): LAN name live.** `https://headlamp.bar2sek.com` serves HTTP 200 with the wildcard certificate, WebSocket upgrade returns 101, no public DNS answer, tailnet URL unaffected, `just headlamp-rbac-check` 7/7. Token login in a browser not yet exercised on this name.

## 🌐 Which URL to use

| Where you are | URL | Why |
| :--- | :--- | :--- |
| At home | `https://headlamp.bar2sek.com` | UniFi local DNS points at ingress-nginx, which serves the wildcard certificate. |
| Away, on the tailnet | `https://headlamp.tail6e33.ts.net` | The `bar2sek.com` name has no public DNS record, so it doesn't resolve off the LAN. |

Both reach the same pod and use the same token login.

> [!NOTE]
> Adding the LAN name widens who can reach the **login screen**: any device that can route to the ingress VIP, not only tailnet members. That is acceptable because the page grants nothing without a token, and even a valid token is read-only with no access to Secrets. There is deliberately no public DNS record or Cloudflare tunnel route.

## 🎯 Why Headlamp, and why not Portainer

Grafana ([[106-observability-prometheus-grafana|docs/106]]) shows **trends**: CPU over a week, Ceph capacity, alert history. Headlamp shows **current state**: which pods are crash-looping, what an event says, what a container logged a minute ago, how a Deployment is wired to its Service and PVC.

| Option | Verdict |
| :--- | :--- |
| **Headlamp** | Chosen. Official Kubernetes SIG UI project; uses Kubernetes RBAC directly. |
| Portainer | Built around Docker. Its Kubernetes mode is a second-class citizen and adds its own user database next to Authentik. |
| Kubernetes Dashboard | Retired upstream; Headlamp is its recommended successor. |
| k9s | Great terminal companion, not a replacement (worth adding via nix-darwin). |

## 🏛️ How it works

```mermaid
graph LR
    MAC["Browser on the tailnet"] -->|"HTTPS (Tailscale cert)"| TSP["Tailscale proxy pod<br/>headlamp.tail6e33.ts.net"]
    LAN["Browser on the LAN"] -->|"HTTPS (wildcard cert)"| NGINX["ingress-nginx<br/>headlamp.bar2sek.com"]
    TSP --> SVC["Service headlamp:80"]
    NGINX --> SVC
    SVC --> POD["Headlamp pod<br/>SA: headlamp (no RBAC)"]
    POD -->|"Bearer: pasted token"| API["kube-apiserver"]
    API -->|"RBAC check on<br/>SA headlamp-viewer"| RB["view + headlamp-cluster-read"]
```

**Key idea:** Headlamp has no permissions of its own. It forwards the token you paste at login, and the API server checks RBAC on *that* identity. The UI can only ever show what the token can read.

### Two ServiceAccounts, on purpose

| ServiceAccount | Used for | Permissions |
| :--- | :--- | :--- |
| `headlamp` | The pod itself (`-in-cluster` reads the API address and CA from its mounted files) | **None.** No bindings. |
| `headlamp-viewer` | Your login token | Built-in `view` ClusterRole + `headlamp-cluster-read` |

> [!WARNING]
> **The upstream Helm chart's default binds the pod's own ServiceAccount to `cluster-admin`** (`clusterRoleBinding.create: true`). Anyone who could reach the UI would effectively be cluster-admin, and the login screen would be decoration. That is why this repo uses a plain manifest (same style as ntfy) instead of the chart.

### Why the extra ClusterRole

The built-in `view` role only covers **namespaced** resources, and it deliberately excludes Secrets. Nodes, PersistentVolumes, StorageClasses, CRDs and node metrics are **cluster-scoped**, so without `headlamp-cluster-read` those pages show "forbidden". The extra role adds read-only access to exactly those.

## 🚀 Deploy

Prerequisites: the Tailscale operator ([[203-tailscale-mesh-vpn|docs/203]]) with HTTPS certificates enabled in the tailnet (already true for ntfy).

```bash
just tf-apply unifi          # adds headlamp.bar2sek.com local DNS
just headlamp-apply
just headlamp-token          # 30-day token by default
just headlamp-token 168h     # or pick a shorter one
```

Open `https://headlamp.bar2sek.com` (or the tailnet URL when away), choose **token** login, paste the output of `just headlamp-token`.

> [!TIP]
> The token is printed once and stored nowhere. It lives in the browser session (`-session-ttl=86400`, one day). When it expires, run `just headlamp-token` again. Nothing to rotate, nothing to commit.

## ✅ Verification

```bash
kubectl -n headlamp get pods,svc,ingress
# Ingress ADDRESS should show headlamp.tail6e33.ts.net (headlamp)
# and 10.10.20.50 (headlamp-lan)

just headlamp-rbac-check
# ok   headlamp-viewer  list    nodes                allowed=true
# ok   headlamp-viewer  get     pods/log             allowed=true
# ok   headlamp-viewer  list    persistentvolumes    allowed=true
# ok   headlamp-viewer  list    secrets              allowed=false
# ok   headlamp-viewer  delete  pods                 allowed=false
# ok   headlamp         list    pods                 allowed=false
# ok   headlamp         list    secrets              allowed=false
```

> [!WARNING]
> **Don't trust `kubectl auth can-i --as=...` here.** The workstation kubeconfig goes through Omni's Kubernetes proxy, which authenticates you and then makes the request as your Omni identity, so `--as` answers reflect *your* admin rights ("yes" to everything, including `delete pods`). `just headlamp-rbac-check` creates `SubjectAccessReview` objects instead: the API server's authorizer evaluates RBAC for the named ServiceAccount directly, and nothing is stored.

To confirm the LAN name stays private, ask a public resolver over HTTPS. The response should have no `Answer` section:

```bash
curl -s -H "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=headlamp.bar2sek.com&type=A"
```

> [!WARNING]
> **Don't use `dig @1.1.1.1` for this.** The UDM intercepts outbound port 53, so it returns the local answer and looks like a public record exists. See [[205-split-horizon-dns-ipv6-leak|docs/205]].

In the UI: Cluster → Nodes lists all five nodes; a pod's Logs tab streams; Secrets shows "forbidden" (expected).

## 🩺 Troubleshooting

| Symptom | Cause / fix |
| :--- | :--- |
| Nodes or Storage page says forbidden | `headlamp-cluster-read` binding missing: re-run `just headlamp-apply`. |
| Pod CrashLoops with a read-only filesystem error | Something needs a writable path besides `/tmp`. Check `kubectl -n headlamp logs deploy/headlamp` and add an `emptyDir` for that path. |
| Node CPU/memory graphs empty | No metrics-server in the cluster. The RBAC already allows `metrics.k8s.io`; deploying metrics-server would light them up. |
| Login says "unauthorized" | Token expired. `just headlamp-token`. |
| `headlamp.bar2sek.com` doesn't resolve | Expected off the LAN (use the tailnet URL). At home: `just tf-apply unifi` hasn't run, or the client isn't using UniFi for DNS. Check with `dig +short headlamp.bar2sek.com`. |
| URL times out right after deploy | The Tailscale proxy pod (`tailscale` namespace, `ts-headlamp-*`) is still joining the tailnet and getting its certificate. Took about a minute on first deploy. |

## 🔮 Later

- **Authentik SSO:** add OIDC flags to the kube-apiserver through a Talos patch, add an Authentik provider, and bind RBAC to Authentik groups. That gives per-person identity instead of a shared viewer token. It's a rolling control-plane change, so it's deferred.
- **Write access:** if restarting a Deployment from the UI becomes useful, add a separate `headlamp-operator` ServiceAccount with a narrow role (e.g. `patch` on deployments) rather than widening the viewer.
