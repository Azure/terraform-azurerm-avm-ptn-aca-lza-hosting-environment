output "application_insights_id" {
  description = "Application Insights resource ID"
  value       = module.aca_lza_hosting.application_insights_id
}

output "hub_virtual_network_id" {
  description = "Hub virtual network ID"
  value       = azurerm_virtual_network.hub.id
}

output "linux_vm_id" {
  description = "Linux VM resource ID"
  value       = module.aca_lza_hosting.linux_vm_id
}

output "spoke_virtual_network_id" {
  description = "Spoke virtual network ID"
  value       = module.aca_lza_hosting.spoke_virtual_network_id
}
