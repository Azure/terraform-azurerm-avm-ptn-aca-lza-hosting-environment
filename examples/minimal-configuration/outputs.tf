output "container_apps_environment_id" {
  description = "Container Apps Environment ID"
  value       = module.aca_lza_hosting.container_apps_environment_id
}

output "container_registry_id" {
  description = "Container Registry ID"
  value       = module.aca_lza_hosting.container_registry_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (minimal configuration)"
  value       = module.aca_lza_hosting.log_analytics_workspace_id
}

output "resource_group_name" {
  description = "Resource group name used by the module"
  value       = module.aca_lza_hosting.resource_group_name
}
