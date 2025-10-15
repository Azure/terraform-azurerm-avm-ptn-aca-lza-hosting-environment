output "container_apps_environment_id" {
  description = "Container Apps Environment ID"
  value       = module.aca_lza_hosting.container_apps_environment_id
}

output "resource_group_name" {
  description = "Created resource group name"
  value       = module.aca_lza_hosting.resource_group_name
}

output "vm_jumpbox_name" {
  description = "Windows VM jumpbox name"
  value       = module.aca_lza_hosting.resources_names.vmJumpBox
}
