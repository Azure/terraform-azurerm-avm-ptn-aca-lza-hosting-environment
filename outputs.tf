output "resources_names" {
  description = "Computed resource names from naming module"
  value       = module.naming.resources_names
}

output "resource_type_abbreviations" {
  description = "Resource type abbreviations used in naming"
  value       = module.naming.resource_type_abbreviations
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Azure Log Analytics Workspace"
  value       = module.spoke.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Azure Log Analytics Workspace"
  value       = module.spoke.log_analytics_workspace_name
}
