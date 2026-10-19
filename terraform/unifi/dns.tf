# ==============================================================================
# Local Split-Horizon DNS Records (UniFi Dream Machine Pro)
# ==============================================================================
# Resolves internal homelab endpoints directly across the local 10GbE network,
# eliminating latency, bandwidth bottlenecks, and WAN roundtrips through the
# Cloudflare Tunnel, while preserving full browser-trusted Let's Encrypt TLS.
#
# IPv6 leak rule: the UDM only answers the record types it holds and forwards
# every other query upstream. A name that ALSO exists in the public Cloudflare
# zone must therefore be a CNAME to a local-only *.home.arpa target (A only):
# A queries get CNAME + private IP, AAAA queries get CNAME + no answer, so
# clients never receive Cloudflare's IPv6 addresses. Names with no public
# record (gaming, printer, printing, k8s) can stay plain A records.
# Runbook: docs/205-split-horizon-dns-ipv6-leak.md

# --- Local-only targets (RFC 8375 home.arpa: never resolvable publicly) ---

resource "unifi_dns_record" "ingress_target" {
  name        = "ingress.home.arpa"
  record_type = "A"
  value       = var.ingress_vip
  ttl         = "300s"
}

resource "unifi_dns_record" "omni_target" {
  name        = "omni.home.arpa"
  record_type = "A"
  value       = var.omni_ip
  ttl         = "300s"
}

# --- Names that also exist publicly in Cloudflare: CNAME to a local target ---

resource "unifi_dns_record" "ceph" {
  name        = "ceph.${var.public_domain}"
  record_type = "CNAME"
  value       = unifi_dns_record.ingress_target.name
  ttl         = "300s"
}

resource "unifi_dns_record" "omni" {
  name        = "omni.${var.public_domain}"
  record_type = "CNAME"
  value       = unifi_dns_record.omni_target.name
  ttl         = "300s"
}

resource "unifi_dns_record" "grafana" {
  name        = "grafana.${var.public_domain}"
  record_type = "CNAME"
  value       = unifi_dns_record.ingress_target.name
  ttl         = "300s"
}

resource "unifi_dns_record" "auth" {
  name        = "auth.${var.public_domain}"
  record_type = "CNAME"
  value       = unifi_dns_record.ingress_target.name
  ttl         = "300s"
}

# --- Local-only names (no public record, so no IPv6 leak) ---

resource "unifi_dns_record" "gaming" {
  name        = "gaming.${var.public_domain}"
  record_type = "A"
  value       = "10.10.20.52"
  ttl         = "300s"
}

resource "unifi_dns_record" "printer" {
  name        = "printer.${var.public_domain}"
  record_type = "A"
  value       = var.printer_ip
  ttl         = "300s"
}

resource "unifi_dns_record" "printing" {
  name        = "printing.${var.public_domain}"
  record_type = "A"
  value       = "10.10.20.20"
  ttl         = "300s"
}

resource "unifi_dns_record" "k8s" {
  name        = "k8s.${var.public_domain}"
  record_type = "A"
  value       = "10.10.20.10"
  ttl         = "300s"
}
