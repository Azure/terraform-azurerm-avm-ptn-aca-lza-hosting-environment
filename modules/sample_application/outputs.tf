output "fqdn" {
  description = "Public FQDN of the Container App (base hostname without revision suffix)."
  value       = module.app.fqdn_url
}

output "id" {
  description = "Resource ID of the Container App."
  value       = module.app.resource_id
}

output "name" {
  description = "Name of the Container App."
  value       = module.app.name
}

output "resource_id" {
  description = "Resource ID of the Container App."
  value       = module.app.resource_id
}
