locals {
  dns_zone_name = "privatelink.azurecr.io"
  # Use enable_hub_peering flag for static conditional logic
  vnet_links_map = merge(
    {
      spoke = {
        name                 = "acr-spoke-link"
        virtual_network_id   = var.spoke_vnet_resource_id
        registration_enabled = false
      }
    },
    var.enable_hub_peering ? {
      hub = {
        name                 = "acr-hub-link"
        virtual_network_id   = var.hub_vnet_resource_id
        registration_enabled = false
      }
    } : {}
  )
}

module "uai" {
  source = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  # version = "~> 0.4"  # optional pin

  name                = var.user_assigned_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags
}

module "acrdnszone" {
  source = "Azure/avm-res-network-privatednszone/azurerm"
  # version = "~> 0.4"

  domain_name      = local.dns_zone_name
  parent_id        = var.resource_group_id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags

  virtual_network_links = local.vnet_links_map
}

module "acr" {
  source = "Azure/avm-res-containerregistry-registry/azurerm"
  # version = "~> 0.6"

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags

  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"
  zone_redundancy_enabled       = var.zone_redundant_enabled
  enable_trust_policy           = true
  quarantine_policy_enabled     = true
  retention_policy_in_days      = 7
  export_policy_enabled         = false

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [module.uai.resource_id]
  }

  role_assignments = {
    acrPull = {
      role_definition_id_or_name = "AcrPull"
      principal_id               = module.uai.principal_id
      principal_type             = "ServicePrincipal"
    }
  }

  private_endpoints = {
    pep = {
      name                          = var.private_endpoint_name
      subnet_resource_id            = var.private_endpoint_subnet_id
      private_dns_zone_resource_ids = [module.acrdnszone.resource_id]
    }
  }

  diagnostic_settings = var.enable_diagnostics ? {
    acr = {
      name                  = "acr-log-analytics"
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
}
