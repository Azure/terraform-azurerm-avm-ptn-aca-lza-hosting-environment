output "id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = azapi_resource.workspace.id
}

output "name" {
  description = "Name of the Log Analytics Workspace"
  value       = azapi_resource.workspace.name
}

output "workspace_id" {
  description = "Workspace (customer) ID"
  value       = try(azapi_resource.workspace.output.properties.customerId, null)
}
