# Random secret for Cloudflare Tunnel encryption
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

# 1. Cloudflare Tunnel Creation
resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab_tunnel" {
  account_id = var.cloudflare_account_id
  name       = local.tunnel_name
  secret     = random_id.tunnel_secret.b64_std
}

# 2. Cloudflare Tunnel Ingress Configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id

  config {
    ingress_rule {
      hostname = "teslamate.${var.domain_name}"
      service  = "http://teslamate.teslamate.svc.cluster.local:4000"
    }
    ingress_rule {
      hostname = "finance.${var.domain_name}"
      service  = "http://actual-budget-service.finance.svc.cluster.local:80"
    }
    ingress_rule {
      hostname = "recipes.${var.domain_name}"
      service  = "http://mealie-service.mealie.svc.cluster.local:80"
    }
    ingress_rule {
      hostname = "grafana.${var.domain_name}"
      service  = "http://teslamate-grafana.teslamate.svc.cluster.local:3000"
    }
    ingress_rule {
      hostname = "omni.${var.domain_name}"
      service  = "http://10.10.10.5:8080"
    }
    # Catch-all rule
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# 3. CNAME DNS Records Pointing Subdomains to Tunnel
resource "cloudflare_record" "teslamate_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "teslamate"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "finance_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "finance"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "recipes_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "recipes"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "grafana_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "grafana"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "omni_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "omni"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# 4. Cloudflare Zero Trust Access Applications (SSO Protection)
resource "cloudflare_zero_trust_access_application" "admin_apps" {
  zone_id          = var.cloudflare_zone_id
  name             = "Homelab Admin Applications"
  domain           = "grafana.${var.domain_name}"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "admin_apps_policy" {
  application_id = cloudflare_zero_trust_access_application.admin_apps.id
  zone_id        = var.cloudflare_zone_id
  name           = "Allow Authorized Homelab Admin"
  precedence     = "1"
  decision       = "allow"

  include {
    email = [var.destination_email]
  }
}

# 5. Cloudflare Email Routing Configuration
resource "cloudflare_email_routing_settings" "email_routing" {
  zone_id = var.cloudflare_zone_id
  enabled = true
}

# Forwarding Rules for AWS Sub-Accounts
resource "cloudflare_email_routing_rule" "aws_prod_email" {
  zone_id = var.cloudflare_zone_id
  name    = "AWS Production Homelab Email Forward"
  enabled = true

  matcher {
    type  = "literal"
    field = "to"
    value = "aws-prod@${var.domain_name}"
  }

  action {
    type  = "forward"
    value = [var.destination_email]
  }
}

resource "cloudflare_email_routing_rule" "aws_logs_email" {
  zone_id = var.cloudflare_zone_id
  name    = "AWS Log Archive Account Email Forward"
  enabled = true

  matcher {
    type  = "literal"
    field = "to"
    value = "aws-logs@${var.domain_name}"
  }

  action {
    type  = "forward"
    value = [var.destination_email]
  }
}

resource "cloudflare_email_routing_rule" "aws_security_email" {
  zone_id = var.cloudflare_zone_id
  name    = "AWS Security Audit Account Email Forward"
  enabled = true

  matcher {
    type  = "literal"
    field = "to"
    value = "aws-security@${var.domain_name}"
  }

  action {
    type  = "forward"
    value = [var.destination_email]
  }
}
