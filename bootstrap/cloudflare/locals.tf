locals {
  # Pattern: tunnel-<platform>-homelab-<env>-<region-code>-<iteration>
  tunnel_name = "tunnel-${var.platform}-homelab-${var.env}-${var.region_code}-${var.iteration}"
}
