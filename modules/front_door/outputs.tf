output "custom_domain_fqdn" {
  description = "Custom domain FQDN configured for Front Door"
  value       = var.front_door_fqdn
}

output "endpoint_hostname" {
  description = "Front Door endpoint hostname"
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "endpoint_id" {
  description = "Front Door endpoint resource ID"
  value       = azurerm_cdn_frontdoor_endpoint.this.id
}

output "id" {
  description = "Front Door profile resource ID"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "name" {
  description = "Front Door profile name"
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "origin_group_id" {
  description = "Front Door origin group resource ID"
  value       = azurerm_cdn_frontdoor_origin_group.this.id
}

output "resource_id" {
  description = "Front Door profile resource ID"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "waf_policy_id" {
  description = "WAF policy resource ID (if enabled)"
  value       = var.enable_waf ? azurerm_cdn_frontdoor_firewall_policy.this[0].id : null
}
