# Cloudflare Tunnel & Zero Trust Remote Access Architecture

This guide outlines the architecture, security benefits, and Kubernetes deployment manifest for **[Cloudflare Tunnels (`cloudflared`)](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)** to securely expose homelab applications to the internet without opening router ports.

---

## 🛡 Why Cloudflare Tunnels?

Cloudflare Tunnel creates an outbound-only encrypted gRPC/QUIC connection from your Kubernetes cluster directly to Cloudflare's global edge network.

### Key Security Benefits:

1. **Zero Inbound Open Ports**: You do **not** need to open Port 80/443 or configure Port Forwarding on your UniFi Dream Machine Pro. Your home IP address remains completely hidden from the public internet.
2. **DDoS Protection & Web Application Firewall (WAF)**: Cloudflare automatically mitigates volumetric DDoS attacks, SQL injection, and bot scrapers before traffic ever reaches your homelab.
3. **Cloudflare Access (Zero Trust Authentication)**: You can place a free SSO login gate (Google, GitHub, or Email OTP) in front of private apps (TeslaMate, Actual Budget, Mealie, Grafana, Sidero Omni) so only authorized users can access them.
4. **Automatic SSL/TLS Certificates**: Managed wildcard SSL certificates with zero `cert-manager` configuration needed.

---

## 📐 Architecture Diagram

```
                     +---------------------------------------+
                     |         Public Internet / User        |
                     +---------------------------------------+
                                         | HTTPS (Domain)
                                         v
                     +---------------------------------------+
                     |         Cloudflare Edge Network       |
                     |  (DDoS Protection, WAF, SSL, Access)  |
                     +---------------------------------------+
                                         | Encrypted Outbound Tunnel (gRPC/QUIC)
                                         v  (Bypasses Firewall / No Open Ports)
 +--------------------------------------------------------------------------------+
 |                           Talos Kubernetes Cluster                             |
 |                                                                                |
 |  +--------------------------------------------------------------------------+  |
 |  |                       cloudflared Deployment Pod                         |  |
 |  +--------------------------------------------------------------------------+  |
 |        /                              |                             \          |
 |       v                               v                              v         |
 | +------------+                 +------------+                 +------------+   |
 | | TeslaMate  |                 |   Actual   |                 |   Mealie   |   |
 | | (Port 4000)|                 | (Port 5006)|                 | (Port 9000)|   |
 | +------------+                 +------------+                 +------------+   |
 +--------------------------------------------------------------------------------+
```

---

## 🌐 Subdomain Routing Layout (`bar2sek.com`)

All public web services are routed via Cloudflare Tunnels using CNAME DNS records on **`bar2sek.com`**:

| Subdomain | App / Target Service | Internal K8s Service | Cloudflare Access Protected? |
| :--- | :--- | :--- | :--- |
| `teslamate.bar2sek.com` | TeslaMate Analytics | `teslamate.teslamate:4000` | Yes (Google / Email OTP SSO) |
| `finance.bar2sek.com` | Actual Budget | `actual-budget-service.finance:80` | Yes (Client-Side E2E Encrypted) |
| `recipes.bar2sek.com` | Mealie Recipe Manager | `mealie-service.mealie:80` | Yes (Household Login) |
| `grafana.bar2sek.com` | Cluster Grafana | `grafana.monitoring:3000` | Yes (Admin SSO) |
| `omni.bar2sek.com` | Sidero Omni Console | `omni-server.mgmt:8080` | Yes (Strict Admin SSO) |

---

## ⚠️ Streaming & Video Guidelines (Cloudflare TOS)

- **Web Applications**: Ideal for web apps like **TeslaMate**, **Actual Budget**, **Mealie**, **Grafana**, and **ACK/Kubernetes Dashboards**.
- **High-Bandwidth Video/Gaming (Sunshine / Moonlight / Plex)**: Cloudflare's free tier terms of service prohibit heavy raw video file streaming. For Sunshine/Moonlight gaming or Plex streaming, we recommend **Tailscale** / **WireGuard** directly to the cluster.

---

## 📦 Cloudflare Tunnel Kubernetes Manifest (`cloudflared.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cloudflare-system
---
apiVersion: v1
kind: Secret
metadata:
  name: cloudflared-tunnel-token
  namespace: cloudflare-system
type: Opaque
stringData:
  TUNNEL_TOKEN: "YOUR_CLOUDFLARE_TUNNEL_TOKEN" # Managed via Secret Store / SealedSecrets
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
  namespace: cloudflare-system
spec:
  replicas: 2 # High Availability across nodes
  selector:
    matchLabels:
      app: cloudflared
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:latest
          args:
            - tunnel
            - --no-autoupdate
            - run
          env:
            - name: TUNNEL_TOKEN
              valueFrom:
                secretKeyRef:
                  name: cloudflared-tunnel-token
                  key: TUNNEL_TOKEN
          resources:
            limits:
              cpu: 500m
              memory: 256Mi
            requests:
              cpu: 100m
              memory: 128Mi
```
