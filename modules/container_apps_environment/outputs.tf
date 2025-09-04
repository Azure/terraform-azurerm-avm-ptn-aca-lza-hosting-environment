output "managed_environment_id" {
  description = "Resource ID of the Container Apps managed environment."
  value       = module.managed_environment.resource_id
}

output "managed_environment_name" {
  description = "Name of the Container Apps managed environment."
  value       = module.managed_environment.name
}

output "default_domain" {
  description = "Default domain of the Container Apps managed environment."
  value       = module.managed_environment.default_domain
}

output "static_ip_address" {
  description = "The static IP address of the Container Apps Managed Environment."
  value       = module.managed_environment.static_ip_address
}

output "private_dns_zone_id" {
  description = "The resource ID of the Private DNS Zone for the environment default domain."
  value       = module.aca_privatedns.resource_id
}

output "private_dns_zone_name" {
  description = "The name of the Private DNS Zone for the environment default domain."
  value       = module.aca_privatedns.name
}

output "application_insights_name" {
  description = "Name of Application Insights if created, else empty string."
  value       = var.enable_application_insights ? module.application_insights[0].name : ""
}

output "workload_profile_names" {
  description = "The name(s) of the workload profiles provisioned in the Container Apps environment."
  value       = ["general-purpose"]
}
