###############################################
# Spoke outputs                              #
###############################################

###############################################
# Networking outputs                          #
###############################################

###############################################
# VM outputs                                   #
###############################################

output "deployment_subnet_id" {
  description = "The resource ID of the deployment subnet."
  value       = module.vnet_spoke.subnets["deployment"].resource_id
}

output "deployment_subnet_name" {
  description = "The name of the deployment subnet."
  value       = module.vnet_spoke.subnets["deployment"].name
}

output "log_analytics_workspace_customer_id" {
  description = "The customer ID (workspace ID) of the Azure Log Analytics Workspace."
  value       = module.log_analytics.workspace_id
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Azure Log Analytics Workspace."
  value       = module.log_analytics.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Azure Log Analytics Workspace."
  value       = module.log_analytics.name
}

output "resource_id" {
  description = "The resource ID of the primary resource deployed by this module (spoke VNet)"
  value       = module.vnet_spoke.resource_id
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

output "vm_jumpbox_name" {
  description = "The name of the jump box virtual machine, if created; otherwise empty string."
  value       = var.resources_names["vmJumpBox"]
}
