output "application_gateway_public_ip" {
  description = "Application Gateway public IP address"
  value       = module.aca_lza_hosting.application_gateway_public_ip
}

output "bastion_fqdn" {
  description = "Bastion Host FQDN"
  value       = azurerm_bastion_host.this.dns_name
}

output "bastion_host_id" {
  description = "Bastion Host resource ID"
  value       = azurerm_bastion_host.this.id
}

output "hub_virtual_network_id" {
  description = "Hub virtual network ID"
  value       = azurerm_virtual_network.hub.id
}

output "linux_vm_private_ip" {
  description = "Linux VM private IP address for Bastion connection"
  value       = module.aca_lza_hosting.linux_vm_private_ip
}

output "spoke_virtual_network_id" {
  description = "Spoke virtual network ID"
  value       = module.aca_lza_hosting.spoke_virtual_network_id
}

output "ssh_private_key" {
  description = "SSH private key for Linux VM (use with Bastion tunneling)"
  sensitive   = true
  value       = tls_private_key.ssh_key.private_key_pem
}
