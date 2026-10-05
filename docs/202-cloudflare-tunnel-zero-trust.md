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
| `auth.bar2sek.com` | Authentik IdP | `https://ingress-nginx-controller.ingress-nginx:443` | **Yes** (Cloudflare Zero Trust Access - Admin), except the OIDC back-channel paths below |

> [!IMPORTANT]
> **Authentik back-channel bypass.** Grafana's *server* calls Authentik's `/application/o/token/` and `/application/o/userinfo/` directly. A server can't carry an Access session cookie, so these two paths are separate path-scoped Access applications with a `bypass` decision (`infra-cloud-deployments`, `terraform/cloudflare/locals.tf`, `authentik_backchannel_paths`). Cloudflare evaluates the most specific path first, so every other path on `auth` (login flows, admin UI, API, OIDC discovery) requires Access.
>
> Verified 2026-10-05 with external `curl` probes:
> - `/`, `/if/admin/` and `/api/v3/` return a 302 to the Access login.
> - An unauthenticated `POST /application/o/token/` returns Authentik's `400 invalid_client`.
> - `GET /application/o/userinfo/` without a token returns `401`.
> - A look-alike path (`/application/o/tokenX`) still requires Access.
>
> If another OIDC client is added, its server-side calls must use these same two paths, or it needs its own bypass entry.

---

## ✉️ Cloudflare Email Routing (100% Free Domain Email Forwarding)

Using **Cloudflare Email Routing**, we manage unlimited custom `@bar2sek.com` email aliases (e.g. `aws-prod@bar2sek.com`, `aws-logs@bar2sek.com`, `aws-security@bar2sek.com`) without hosting an email server or paying monthly inbox fees. All emails forward automatically to a personal destination inbox.

---

## 🤖 Infrastructure as Code (Cloudflare Terraform Provider)

All Cloudflare Tunnels, DNS records, and Access SSO policies are declaratively managed using Terraform in the `infra-cloud-deployments` repository (`terraform/cloudflare/main.tf`):

```hcl
# Cloudflare Tunnel Ingress Configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id

  config {
    ingress_rule {
      hostname = "tesla.${var.domain_name}"
      service  = "http://teslamate.teslamate.svc.cluster.local:4000"
    }
    ingress_rule {
      hostname = "finance.${var.domain_name}"
      service  = "http://actual-budget-service.finance.svc.cluster.local:80"
    }
    ingress_rule {
      hostname = "diet.${var.domain_name}"
      service  = "http://mealie-service.mealie.svc.cluster.local:80"
    }
    ingress_rule {
      hostname = "grafana.${var.domain_name}"
      service  = "https://ingress-nginx-controller.ingress-nginx.svc.cluster.local:443"
      origin_request { no_tls_verify = true }
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}
```

> [!NOTE] Email Routing
> Cloudflare Email Routing is managed directly out-of-band via the Cloudflare Dashboard console when needed. Custom domain root aliases (e.g. for AWS root accounts) are not managed via Terraform to avoid cyclic dependencies during Day-0 bootstrap.

---

## ⚠️ Streaming & Video Guidelines (Cloudflare TOS)

- **Web Applications**: Ideal for web apps like **TeslaMate**, **Actual Budget**, **Mealie**, **Grafana**, and **ACK/Kubernetes Dashboards**.
- **High-Bandwidth Video/Gaming (Sunshine / Moonlight / Plex)**: Cloudflare's free tier terms of service prohibit heavy raw video file streaming. For Sunshine/Moonlight gaming or Plex streaming, we recommend **Tailscale** / **WireGuard** directly to the cluster.

---

## 📦 Cloudflare Tunnel Kubernetes Deployment

The Cloudflare Tunnel secret is derived directly from the `infra-cloud-deployments/terraform/cloudflare` root output:

```bash
# 1. Extract sensitive tunnel token from Terraform and apply directly to cluster:
TUNNEL_TOKEN=$(terraform -chdir=../../infra-cloud-deployments/terraform/cloudflare output -raw tunnel_token)

kubectl create namespace cloudflare-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic cloudflared-tunnel-token \
  --namespace=cloudflare-system \
  --from-literal=TUNNEL_TOKEN="${TUNNEL_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. Deploy High-Availability Cloudflared pods:
kubectl apply -f kubernetes/infrastructure/cloudflare/cloudflared.yaml
```

### Manifest Reference (`kubernetes/infrastructure/cloudflare/cloudflared.yaml`)
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
