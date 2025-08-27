// Naming module wiring

data "azapi_client_config" "naming" {}

locals {
  naming_unique_seed = join("|", [
    data.azapi_client_config.naming.subscription_id,
    var.location,
    var.environment,
    var.workload_name,
  ])

  // Deterministic uniqueness token derived from subscription + inputs
  naming_unique_id = substr(lower(replace(base64encode(sha256(local.naming_unique_seed)), "=", "")), 0, 13)
}

module "naming" {
  source = "./modules/naming"

  workload_name             = var.workload_name
  spoke_resource_group_name = var.spoke_resource_group_name
  environment               = var.environment
  location                  = var.location
  unique_id                 = local.naming_unique_id
}

module "spoke_resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  name             = module.naming.resources_names.resourceGroup
  location         = var.location
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}

// Spoke composition module (Stage 2+: LAW first)
module "spoke" {
  source = "./modules/spoke"

  resources_names     = module.naming.resources_names
  location            = var.location
  resource_group_id   = module.spoke_resource_group.resource_id
  resource_group_name = module.naming.resources_names.resourceGroup
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  # Networking
  hub_virtual_network_resource_id                 = var.hub_virtual_network_resource_id
  spoke_vnet_address_prefixes                     = var.spoke_vnet_address_prefixes
  spoke_infra_subnet_address_prefix               = var.spoke_infra_subnet_address_prefix
  spoke_private_endpoints_subnet_address_prefix   = var.spoke_private_endpoints_subnet_address_prefix
  spoke_application_gateway_subnet_address_prefix = var.spoke_application_gateway_subnet_address_prefix
  deployment_subnet_address_prefix                = var.deployment_subnet_address_prefix
  route_spoke_traffic_internally                  = var.route_spoke_traffic_internally
  network_appliance_ip_address                    = var.network_appliance_ip_address

  # Jumpbox VM
  bastion_resource_id              = var.bastion_resource_id
  vm_size                          = var.vm_size
  storage_account_type             = var.storage_account_type
  vm_admin_password                = var.vm_admin_password
  vm_linux_ssh_authorized_key      = var.vm_linux_ssh_authorized_key
  vm_authentication_type           = var.vm_authentication_type
  vm_jumpbox_os_type               = var.vm_jumpbox_os_type
  vm_jumpbox_subnet_address_prefix = var.vm_jumpbox_subnet_address_prefix
  vm_zone                          = var.deploy_zone_redundant_resources ? 2 : 0
}
