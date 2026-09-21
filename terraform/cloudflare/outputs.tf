output "tunnel_id" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id
  description = "Cloudflare Tunnel ID"
}

output "tunnel_token" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.tunnel_token
  description = "Cloudflare Tunnel Token for Kubernetes Deployment Secret"
  sensitive   = true
}
