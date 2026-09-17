# ==============================================================================
# Local Split-Horizon DNS Records (UniFi Dream Machine Pro)
# ==============================================================================
# Resolves internal homelab endpoints directly across the local 10GbE network,
# eliminating latency, bandwidth bottlenecks, and WAN roundtrips through the
# Cloudflare Tunnel, while preserving full browser-trusted Let's Encrypt TLS.

resource "unifi_dns_record" "ceph" {
  name        = "ceph.${var.public_domain}"
  record_type = "A"
  value       = var.ingress_vip
  ttl         = "300s"
}

resource "unifi_dns_record" "omni" {
  name        = "omni.${var.public_domain}"
  record_type = "A"
  value       = var.omni_ip
  ttl         = "300s"
}

resource "unifi_dns_record" "grafana" {
  name        = "grafana.${var.public_domain}"
  record_type = "A"
  value       = var.ingress_vip
  ttl         = "300s"
}

resource "unifi_dns_record" "auth" {
  name        = "auth.${var.public_domain}"
  record_type = "A"
  value       = var.ingress_vip
  ttl         = "300s"
}

resource "unifi_dns_record" "agy" {
  name        = "agy.${var.public_domain}"
  record_type = "A"
  value       = var.ingress_vip
  ttl         = "300s"
}

resource "unifi_dns_record" "gaming" {
  name        = "gaming.${var.public_domain}"
  record_type = "A"
  value       = "10.10.20.52"
  ttl         = "300s"
}



