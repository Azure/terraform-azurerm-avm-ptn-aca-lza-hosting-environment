output "fqdn" {
  description = "Application Gateway FQDN (input)"
  value       = var.application_gateway_fqdn
}

output "id" {
  description = "Application Gateway resource ID"
  value       = module.app_gateway.application_gateway_id
}

output "public_ip_address" {
  description = "Application Gateway frontend public IP address"
  value       = coalesce(try(module.appgw_pip.ip_address, null), try(data.azurerm_public_ip.pip.ip_address, null))
}

output "resource_id" {
  description = "Application Gateway resource ID"
  value       = module.app_gateway.application_gateway_id
}
