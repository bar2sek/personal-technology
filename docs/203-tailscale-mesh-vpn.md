# Tailscale Kubernetes Operator & Private Mesh Network

This guide outlines the architecture and deployment workflow for the **[Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator)** to provide secure, encrypted mesh VPN access to private cluster services and admin APIs.

---

## 🔒 Why Tailscale in Kubernetes?

- **Direct End-to-End Encrypted Mesh**: Connects your devices (MacBook, iPhone, iPad) directly to cluster pods over WireGuard without exposing any public endpoints.
- **Subnet Router / Exit Node**: Exposes internal cluster subnets (`10.10.x.x`) to your Tailnet so you can run `talosctl` and `kubectl` securely from anywhere in the world.
- **Tailscale Ingress & Service Operator**: Automatically generates `*.ts.net` private domain endpoints for internal administrative services.

---

## 📐 Dual-Remote Access Strategy (`bar2sek.com` + Tailscale)

```
 +--------------------------------------------------------------------------------+
 |                           Remote Access Topology                               |
 |                                                                                |
 |  1. PUBLIC WEB APPS (Cloudflare Tunnel)                                        |
 |     https://tesla.bar2sek.com      --> Cloudflare Edge --> cloudflared Pod     |
 |     https://finance.bar2sek.com    --> Cloudflare Edge --> cloudflared Pod     |
 |     https://diet.bar2sek.com       --> Cloudflare Edge --> cloudflared Pod     |
 |                                                                                |
 |  2. PRIVATE CLUSTER ADMIN & APIS (Tailscale Mesh VPN)                          |
 |     https://k8s-api.tailnet.ts.net --> Tailscale WireGuard --> Cluster Pods     |
 |     talosctl / kubectl commands   --> Subnet Router Pod --> Internal 10.10.x.x   |
 |                                                                                |
 |  3. IN-HOUSE 4K GAMING (Local Network LAN)                                     |
 |     Moonlight App --> UniFi 2.5G/10G Switch --> KubeVirt Windows 11 VM (RTX 4070) |
 +--------------------------------------------------------------------------------+
```

---

## 📦 Deployment (2026-10-18)

**What is deployed:** the operator (Helm, chart pinned in `just tailscale-apply`) and one `Connector` subnet router that advertises only the ingress VIP `10.10.20.50/32`. Every `*.bar2sek.com` app behind ingress-nginx (ntfy, Grafana, Ceph dashboard, Authentik) is then reachable from any tailnet device. Public DNS already resolves those names to `10.10.20.50`, and the wildcard certificate is valid, so no Tailscale DNS settings are needed.

> [!IMPORTANT]
> **Why only a `/32`.** macOS and iOS clients use advertised subnets by default, even at home. Advertising all of `10.10.20.0/24` would send Moonlight traffic to the gaming VM (`10.10.20.52`) and all node traffic through the router pod. kubectl and talosctl go through Omni, so they do not need the route. VLAN 10 (IPMI) is never advertised.

| File | Purpose |
|---|---|
| `kubernetes/infrastructure/tailscale/namespace.yaml` | `tailscale` namespace with Pod Security `privileged` (the router needs `NET_ADMIN` and a privileged init container; Talos enforces `baseline`) |
| `kubernetes/infrastructure/tailscale/values.yaml` | Tags (`tag:k8s-operator` for the operator, `tag:k8s` for proxies); API server proxy off |
| `kubernetes/infrastructure/tailscale/connector.yaml` | The subnet router (`talos-homelab-router`) |
| `kubernetes/infrastructure/tailscale/operator-oauth.example.yaml` | Shape of the OAuth Secret. The real one is gitignored and never committed |

### 1. Tailnet policy (admin console → Access controls)
Add to the policy file (merge with existing sections):
```json
"tagOwners": {
  "tag:k8s-operator": [],
  "tag:k8s": ["tag:k8s-operator"]
},
"autoApprovers": {
  "routes": {
    "10.10.20.50/32": ["tag:k8s"]
  }
}
```
`tag:k8s-operator` has no human owners: only an OAuth client can apply it. The operator owns `tag:k8s`, so it can tag the proxies it creates, and `autoApprovers` approves the router's route without a manual click.

### 2. OAuth client (admin console → Settings → Trust credentials)
Create an OAuth credential with write scopes **Devices → Core**, **Keys → Auth Keys** and **Services**, tagged `tag:k8s-operator`. The secret is shown only once.

### 3. Secret, then deploy
```bash
read -r "TS_ID?Client ID: "; read -rs "TS_SECRET?Client secret: "; echo
kubectl create namespace tailscale --dry-run=client -o yaml | kubectl apply -f -
kubectl -n tailscale create secret generic operator-oauth \
  --from-literal=client_id="$TS_ID" --from-literal=client_secret="$TS_SECRET"
unset TS_ID TS_SECRET
just tailscale-apply
```
`read -s` keeps the secret out of the screen and shell history. Do **not** pass it to Helm with `--set`: Helm stores `--set` values in its release record, where `helm get values` prints them.

### Verification
```bash
kubectl -n tailscale get pods                    # operator + ts-homelab-subnet-router-* Running
kubectl get connector homelab-subnet-router      # STATUS: ConnectorCreated, SUBNETROUTES: 10.10.20.50/32
tailscale status | grep talos-homelab-router     # visible from the Mac
```
From the iPhone **on mobile data** with Tailscale on, `https://grafana.bar2sek.com` should load.

> [!WARNING]
> **Rotating or revoking the OAuth client** stops the operator from minting keys for new proxies; existing ones keep running until restarted. Replace the `operator-oauth` Secret and restart the operator Deployment.
