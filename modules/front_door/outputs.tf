output "endpoint_hostname" {
  description = "Front Door endpoint hostname (*.azurefd.net with Microsoft-managed certificate)"
  value       = jsondecode(azapi_resource.endpoint.output).properties.hostName
}

output "endpoint_id" {
  description = "Front Door endpoint resource ID"
  value       = azapi_resource.endpoint.id
}

output "id" {
  description = "Front Door profile resource ID"
  value       = azapi_resource.profile.id
}

output "name" {
  description = "Front Door profile name"
  value       = azapi_resource.profile.name
}

output "origin_group_id" {
  description = "Front Door origin group resource ID"
  value       = azapi_resource.origin_group.id
}

output "origin_id" {
  description = "Front Door origin resource ID"
  value       = azapi_resource.origin.id
}

output "resource_id" {
  description = "Front Door profile resource ID"
  value       = azapi_resource.profile.id
}

output "waf_policy_id" {
  description = "WAF policy resource ID (if enabled)"
  value       = var.enable_waf ? azapi_resource.waf_policy[0].id : null
}
