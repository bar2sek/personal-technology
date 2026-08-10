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
 |     https://teslamate.bar2sek.com  --> Cloudflare Edge --> cloudflared Pod     |
 |     https://finance.bar2sek.com    --> Cloudflare Edge --> cloudflared Pod     |
 |     https://recipes.bar2sek.com    --> Cloudflare Edge --> cloudflared Pod     |
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

## 📦 Tailscale Operator Helm Installation

```bash
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update
helm install tailscale-operator tailscale/tailscale-operator \
  --namespace tailscale \
  --create-namespace \
  --set clientId="YOUR_TAILSCALE_CLIENT_ID" \
  --set clientSecret="YOUR_TAILSCALE_CLIENT_SECRET"
```
