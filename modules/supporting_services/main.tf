locals {
  tags = var.tags
}

module "container_registry" {
  source = "./container_registry"
  count  = 1

  name                        = var.resources_names.containerRegistry
  location                    = var.location
  resource_group_name         = var.resource_group_name
  resource_group_id           = var.resource_group_id
  tags                        = local.tags
  enable_telemetry            = var.enable_telemetry
  spoke_vnet_resource_id      = var.spoke_vnet_resource_id
  hub_vnet_resource_id        = var.hub_vnet_resource_id
  private_endpoint_subnet_id  = var.spoke_private_endpoint_subnet_resource_id
  private_endpoint_name       = var.resources_names.containerRegistryPep
  user_assigned_identity_name = var.resources_names.containerRegistryUserAssignedIdentity
  log_analytics_workspace_id  = var.log_analytics_workspace_id
  enable_diagnostics          = var.enable_diagnostics
  zone_redundant_enabled      = var.deploy_zone_redundant_resources
  deploy_agent_pool           = var.deploy_agent_pool
}

module "key_vault" {
  source = "./key_vault"
  count  = 1

  name                       = var.resources_names.keyVault
  location                   = var.location
  resource_group_name        = var.resource_group_name
  resource_group_id          = var.resource_group_id
  tags                       = local.tags
  enable_telemetry           = var.enable_telemetry
  spoke_vnet_resource_id     = var.spoke_vnet_resource_id
  hub_vnet_resource_id       = var.hub_vnet_resource_id
  private_endpoint_subnet_id = var.spoke_private_endpoint_subnet_resource_id
  private_endpoint_name      = var.resources_names.keyVaultPep
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enable_diagnostics         = var.enable_diagnostics
}

module "storage" {
  source = "./storage"
  count  = 1

  name                       = var.resources_names.storageAccount
  location                   = var.location
  resource_group_name        = var.resource_group_name
  resource_group_id          = var.resource_group_id
  tags                       = local.tags
  enable_telemetry           = var.enable_telemetry
  spoke_vnet_resource_id     = var.spoke_vnet_resource_id
  hub_vnet_resource_id       = var.hub_vnet_resource_id
  private_endpoint_subnet_id = var.spoke_private_endpoint_subnet_resource_id
  private_endpoint_name      = "storage-pep"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  key_vault_id               = module.key_vault[0].id
  shares                     = ["smbfileshare"]
  enable_diagnostics         = var.enable_diagnostics
}

