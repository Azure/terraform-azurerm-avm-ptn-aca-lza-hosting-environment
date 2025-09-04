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

output "container_registry_id" {
  description = "The resource ID of the Azure Container Registry."
  value       = module.supporting_services.container_registry_id
}

output "container_registry_name" {
  description = "The name of the Azure Container Registry."
  value       = module.supporting_services.container_registry_name
}

output "container_registry_login_server" {
  description = "The name of the container registry login server."
  value       = module.supporting_services.container_registry_login_server
}

output "container_registry_agent_pool_name" {
  description = "The name of the internal agent pool for the container registry."
  value       = module.supporting_services.container_registry_agent_pool_name
}

output "container_registry_user_assigned_identity_id" {
  description = "The resource ID of the user-assigned managed identity for ACR pulls."
  value       = module.supporting_services.container_registry_uai_id
}

output "key_vault_id" {
  description = "The resource ID of the Azure Key Vault."
  value       = module.supporting_services.key_vault_id
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault."
  value       = module.supporting_services.key_vault_name
}

output "storage_account_name" {
  description = "The account name of the storage account."
  value       = module.supporting_services.storage_account_name
}

output "storage_account_resource_id" {
  description = "The resource ID of the storage account."
  value       = module.supporting_services.storage_account_id
}

output "container_apps_environment_id" {
  description = "The resource ID of the Container Apps Managed Environment."
  value       = module.container_apps_environment.managed_environment_id
}

output "container_apps_environment_default_domain" {
  description = "The default domain of the Container Apps Managed Environment."
  value       = module.container_apps_environment.default_domain
}

output "container_apps_environment_static_ip" {
  description = "The static IP address of the Container Apps Managed Environment."
  value       = module.container_apps_environment.static_ip_address
}

output "container_apps_environment_private_dns_zone_id" {
  description = "The resource ID of the Private DNS Zone for the ACA environment default domain."
  value       = module.container_apps_environment.private_dns_zone_id
}

output "sample_app_id" {
  description = "The resource ID of the sample Container App (when deployed)."
  value       = try(module.sample_application[0].id, null)
}

output "sample_app_name" {
  description = "The name of the sample Container App (when deployed)."
  value       = try(module.sample_application[0].name, null)
}

output "sample_app_fqdn" {
  description = "The FQDN of the sample Container App (when deployed)."
  value       = try(module.sample_application[0].fqdn, null)
}

output "application_gateway_id" {
  description = "The resource ID of the Application Gateway (when deployed)."
  value       = try(module.application_gateway[0].id, null)
}

output "application_gateway_public_ip" {
  description = "The public IP address of the Application Gateway (when deployed)."
  value       = try(module.application_gateway[0].public_ip_address, null)
}

output "application_gateway_fqdn" {
  description = "The FQDN of the Application Gateway (input, when used)."
  value       = try(module.application_gateway[0].fqdn, null)
}
