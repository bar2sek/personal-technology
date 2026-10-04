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

| Subdomain | App / Target Service | Internal Target | Cloudflare Access Protected? |
| :--- | :--- | :--- | :--- |
| `tesla.bar2sek.com` | TeslaMate Analytics | `http://teslamate.teslamate:4000` | **Yes** (Cloudflare Zero Trust Access - Admin) |
| `grafana.bar2sek.com` | Cluster Grafana | `https://ingress-nginx-controller.ingress-nginx:443` | **Yes** (Cloudflare Zero Trust Access - Admin) |
| `omni.bar2sek.com` | Sidero Omni Console | `https://10.10.10.5:443` | **Yes** (Cloudflare Zero Trust Access - Admin) |
| `ceph.bar2sek.com` | Ceph Dashboard | `https://ingress-nginx-controller.ingress-nginx:443` | **Yes** (Cloudflare Zero Trust Access - Admin) |
| `finance.bar2sek.com` | Actual Budget | `http://actual-budget-service.finance:80` | **Yes** (Cloudflare Zero Trust Access - Extended Session) |
| `diet.bar2sek.com` | Mealie Recipe Manager | `http://mealie-service.mealie:80` | **Yes** (Cloudflare Zero Trust Access - Extended Session) |
| `auth.bar2sek.com` | Authentik IdP | `https://ingress-nginx-controller.ingress-nginx:443` | **No** (Direct Tunnel / IdP Self-Protected Endpoint) |

---

## ✉️ Cloudflare Email Routing (100% Free Domain Email Forwarding)

Using **Cloudflare Email Routing**, we manage unlimited custom `@bar2sek.com` email aliases (e.g. `aws-prod@bar2sek.com`, `aws-logs@bar2sek.com`, `aws-security@bar2sek.com`) without hosting an email server or paying monthly inbox fees. All emails forward automatically to a personal destination inbox.

---

## 🤖 Infrastructure as Code (Cloudflare Terraform Provider)

All Cloudflare Tunnels, DNS records, and Access SSO policies are declaratively managed using Terraform in the `infra-cloud-deployments` repository (`terraform/cloudflare/main.tf`):

```hcl
# Cloudflare Email Routing Enabled for bar2sek.com
resource "cloudflare_email_routing_settings" "email_routing" {
  zone_id = var.cloudflare_zone_id
  enabled = true
}

# Forwarding Rule for AWS Production Homelab Account
resource "cloudflare_email_routing_rule" "aws_prod_email" {
  zone_id = var.cloudflare_zone_id
  name    = "AWS Production Homelab Email Forward"
  enabled = true

  matcher {
    type  = "literal"
    field = "to"
    value = "aws-prod@bar2sek.com"
  }

  action {
    type  = "forward"
    value = [var.destination_email]
  }
}
```

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
