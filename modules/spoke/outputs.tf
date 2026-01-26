###############################################
# Spoke outputs                              #
###############################################

###############################################
# Networking outputs                          #
###############################################

output "log_analytics_workspace_customer_id" {
  description = "The customer ID (workspace ID) of the Azure Log Analytics Workspace."
  value       = try(azapi_resource.log_analytics_workspace.output.properties.customerId, null)
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Azure Log Analytics Workspace."
  value       = azapi_resource.log_analytics_workspace.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Azure Log Analytics Workspace."
  value       = azapi_resource.log_analytics_workspace.name
}

output "resource_id" {
  description = "The resource ID of the primary resource deployed by this module (spoke VNet)"
  value       = module.vnet_spoke.resource_id
}

output "spoke_application_gateway_nsg_id" {
  description = "The resource ID of the Application Gateway NSG, if created; otherwise empty string. Used for dependency ordering during destroy."
  value       = length(module.nsg_appgw) > 0 ? module.nsg_appgw[0].resource_id : ""
}

output "spoke_application_gateway_subnet_id" {
  description = "The resource ID of the spoke Application Gateway subnet, if created; otherwise empty string."
  value       = try(module.vnet_spoke.subnets["agw"].resource_id, "")
}

output "spoke_application_gateway_subnet_name" {
  description = "The name of the spoke Application Gateway subnet, if created; otherwise empty string."
  value       = try(module.vnet_spoke.subnets["agw"].name, "")
}

output "spoke_infra_subnet_id" {
  description = "The resource ID of the spoke infrastructure subnet."
  value       = module.vnet_spoke.subnets["infra"].resource_id
}

output "spoke_infra_subnet_name" {
  description = "The name of the spoke infrastructure subnet."
  value       = module.vnet_spoke.subnets["infra"].name
}

output "spoke_private_endpoints_subnet_id" {
  description = "The resource ID of the spoke private endpoints subnet."
  value       = module.vnet_spoke.subnets["pep"].resource_id
}

output "spoke_private_endpoints_subnet_name" {
  description = "The name of the spoke private endpoints subnet."
  value       = module.vnet_spoke.subnets["pep"].name
}

output "spoke_vnet_id" {
  description = "The resource ID of the spoke virtual network."
  value       = module.vnet_spoke.resource_id
}

output "spoke_vnet_name" {
  description = "The name of the spoke virtual network."
  value       = module.vnet_spoke.name
}

output "spoke_jumpbox_subnet_id" {
  description = "The resource ID of the jumpbox subnet, if created; otherwise empty string."
  value       = try(module.vnet_spoke.subnets["jumpbox"].resource_id, "")
}
