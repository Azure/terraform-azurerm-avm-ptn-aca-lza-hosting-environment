output "application_gateway_fqdn" {
  description = "Application Gateway FQDN"
  value       = var.custom_fqdn
}

output "container_apps_environment_fqdn" {
  description = "Container Apps Environment default domain"
  value       = module.aca_lza_hosting.container_apps_environment_default_domain
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP address"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Azure Firewall public IP address"
  value       = azurerm_public_ip.firewall.ip_address
}

output "hub_virtual_network_id" {
  description = "Hub virtual network ID"
  value       = azurerm_virtual_network.hub.id
}

output "route_table_id" {
  description = "Route table ID for spoke network"
  value       = azurerm_route_table.spoke.id
}

output "spoke_virtual_network_id" {
  description = "Spoke virtual network ID"
  value       = module.aca_lza_hosting.spoke_virtual_network_id
}

output "ssh_private_key" {
  description = "SSH private key for Linux VM"
  sensitive   = true
  value       = tls_private_key.ssh_key.private_key_pem
}
