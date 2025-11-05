###############################################
# Outputs                                     #
###############################################

output "resource_id" {
  description = "Not applicable for naming module - this is a utility module that does not create resources"
  value       = ""
}

output "resource_type_abbreviations" {
  description = "Resource type abbreviations"
  value       = local.resource_type_abbreviations
}

output "resources_names" {
  description = "Computed resource names"
  value       = local.resource_names
}
