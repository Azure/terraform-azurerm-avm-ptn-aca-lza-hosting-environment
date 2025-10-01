output "container_apps_environment_default_domain" {
  description = "The default domain of the Container Apps Environment"
  value       = module.aca_lza_hosting.container_apps_environment_default_domain
}

output "container_apps_environment_id" {
  description = "The resource ID of the Container Apps Environment"
  value       = module.aca_lza_hosting.container_apps_environment_id
}

output "front_door_custom_domain_fqdn" {
  description = "The custom domain FQDN configured for Front Door"
  value       = module.aca_lza_hosting.front_door_custom_domain_fqdn
}

output "front_door_endpoint_hostname" {
  description = "The hostname of the Front Door endpoint"
  value       = module.aca_lza_hosting.front_door_endpoint_hostname
}

# Output Front Door details
output "front_door_id" {
  description = "The resource ID of the Front Door profile"
  value       = module.aca_lza_hosting.front_door_id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = module.aca_lza_hosting.key_vault_name
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.aca_lza_hosting.resource_group_name
}
