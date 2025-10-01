output "fqdn" {
  description = "Public FQDN of the latest revision of the Container App."
  value       = try(module.app.latest_revision_fqdn, module.app.fqdn)
}

output "id" {
  description = "Resource ID of the Container App."
  value       = module.app.resource_id
}

output "name" {
  description = "Name of the Container App."
  value       = module.app.name
}
