output "architecture" {
  description = "Active ALZ architecture: homelab-hierarchy (no policy) or homelab (trimmed policy)"
  value       = local.architecture
}

output "management_group_ids" {
  description = "Management group IDs by <category> node"
  value       = local.mg_ids
}

output "subscription_placement" {
  description = "Subscription display name -> management group (no IDs)"
  value       = { for name, id in local.subscriptions : name => try(local.subscription_placement[split("-", name)[2]].management_group_name, "(not placed)") }
}

output "policy_assignment_count" {
  description = "Policy assignments per management group"
  value       = { for mg in data.alz_architecture.inventory.management_groups : mg.id => length(mg.policy_assignments) }
}

output "policy_enforcement" {
  description = "Effective enforcement mode per management group that has assignments"
  value       = { for id, v in local.policy_assignments_to_modify : id => distinct([for a in values(v.policy_assignments) : a.enforcement_mode]) }
}
