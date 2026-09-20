# ==============================================================================
# GitHub Infrastructure - Outputs
# ==============================================================================

output "repository_name" {
  description = "Name of the GitOps deployments repository"
  value       = github_repository.infra_cloud_deployments.name
}

output "repository_full_name" {
  description = "Full name (owner/repo) of the deployments repository"
  value       = github_repository.infra_cloud_deployments.full_name
}

output "repository_html_url" {
  description = "Web URL of the GitHub repository"
  value       = github_repository.infra_cloud_deployments.html_url
}

output "repository_ssh_clone_url" {
  description = "SSH clone URL of the repository"
  value       = github_repository.infra_cloud_deployments.ssh_clone_url
}

output "repository_http_clone_url" {
  description = "HTTPS clone URL of the repository"
  value       = github_repository.infra_cloud_deployments.http_clone_url
}

output "production_environment_name" {
  description = "Name of the production deployment environment"
  value       = github_repository_environment.production.environment
}
