###############################################
# Spoke outputs                              #
###############################################

###############################################
# Networking outputs                          #
###############################################

###############################################
# VM outputs                                   #
###############################################

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

output "spoke_application_gateway_nsg_id" {
  description = "The resource ID of the Application Gateway NSG, if created; otherwise empty string. Used for dependency ordering during destroy."
  value       = length(module.nsg_appgw) > 0 ? module.nsg_appgw[0].resource_id : ""
}

# This output includes the full NSG resource to ensure proper destroy ordering
# When this output is used, Terraform creates a dependency on the entire NSG module
# including all security rules, ensuring App Gateway is destroyed before NSG rules
output "spoke_application_gateway_nsg_resource" {
  description = "The Application Gateway NSG resource object. Used internally for dependency ordering during destroy - ensures App Gateway is destroyed before NSG rules."
  value       = length(module.nsg_appgw) > 0 ? module.nsg_appgw[0].resource : null
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

output "vm_jumpbox_id" {
  description = "The resource ID of the Linux jump box virtual machine (when deployed)."
  value       = var.vm_jumpbox_os_type == "linux" ? module.vm_linux[0].vm_id : (var.vm_jumpbox_os_type == "windows" ? null : null) # Windows VM doesn't have output yet
}

output "vm_jumpbox_name" {
  description = "The name of the jump box virtual machine, if created; otherwise empty string."
  value       = var.resources_names["vmJumpBox"]
}

output "vm_jumpbox_private_ip" {
  description = "The private IP address of the jump box virtual machine (when deployed)."
  value       = var.vm_jumpbox_os_type == "linux" ? module.vm_linux[0].vm_private_ip : (var.vm_jumpbox_os_type == "windows" ? null : null) # Windows VM doesn't have output yet
}
