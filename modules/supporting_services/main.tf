locals {
  tags = var.tags
}

# tflint-ignore: required_module_source_tffr1
module "container_registry" {
  source = "./container_registry"
  count  = 1

  location                    = var.location
  name                        = var.resources_names.containerRegistry
  private_endpoint_name       = var.resources_names.containerRegistryPep
  private_endpoint_subnet_id  = var.spoke_private_endpoint_subnet_resource_id
  resource_group_id           = var.resource_group_id
  resource_group_name         = var.resource_group_name
  spoke_vnet_resource_id      = var.spoke_vnet_resource_id
  user_assigned_identity_name = var.resources_names.containerRegistryUserAssignedIdentity
  enable_diagnostics          = var.enable_diagnostics
  enable_telemetry            = var.enable_telemetry
  hub_vnet_resource_id        = var.hub_vnet_resource_id
  log_analytics_workspace_id  = var.log_analytics_workspace_id
  tags                        = local.tags
  zone_redundant_enabled      = var.deploy_zone_redundant_resources
}

# tflint-ignore: required_module_source_tffr1
module "key_vault" {
  source = "./key_vault"
  count  = 1

  location                   = var.location
  name                       = var.resources_names.keyVault
  private_endpoint_name      = var.resources_names.keyVaultPep
  private_endpoint_subnet_id = var.spoke_private_endpoint_subnet_resource_id
  resource_group_id          = var.resource_group_id
  resource_group_name        = var.resource_group_name
  spoke_vnet_resource_id     = var.spoke_vnet_resource_id
  enable_diagnostics         = var.enable_diagnostics
  enable_telemetry           = var.enable_telemetry
  expose_container_apps_with = var.expose_container_apps_with
  hub_vnet_resource_id       = var.hub_vnet_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = local.tags
}

# tflint-ignore: required_module_source_tffr1
module "storage" {
  source = "./storage"
  count  = 1

  enable_telemetry           = var.enable_telemetry
  key_vault_id               = module.key_vault[0].id
  location                   = var.location
  name                       = var.resources_names.storageAccount
  private_endpoint_name      = "storage-pep"
  private_endpoint_subnet_id = var.spoke_private_endpoint_subnet_resource_id
  resource_group_id          = var.resource_group_id
  resource_group_name        = var.resource_group_name
  spoke_vnet_resource_id     = var.spoke_vnet_resource_id
  enable_diagnostics         = var.enable_diagnostics
  hub_vnet_resource_id       = var.hub_vnet_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  shares                     = ["smbfileshare"]
  tags                       = local.tags
}

