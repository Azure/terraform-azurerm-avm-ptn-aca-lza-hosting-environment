###############################################
# Outputs                                     #
###############################################

output "resource_type_abbreviations" {
  description = "Resource type abbreviations"
  value       = local.resource_type_abbreviations
}

output "resources_names" {
  description = "Computed resource names"
  value       = local.resource_names
}
