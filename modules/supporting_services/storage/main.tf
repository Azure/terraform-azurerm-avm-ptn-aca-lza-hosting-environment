locals {
  dns_zone_name = "privatelink.file.core.windows.net"
}

module "st_dns" {
  source = "Azure/avm-res-network-privatednszone/azurerm"

  domain_name      = local.dns_zone_name
  parent_id        = var.resource_group_id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags

  virtual_network_links = merge({
    spoke = {
      name                 = "st-spoke-link"
      virtual_network_id   = var.spoke_vnet_resource_id
      registration_enabled = false
    }
    }, var.hub_vnet_resource_id == "" ? {} : {
    hub = {
      name                 = "st-hub-link"
      virtual_network_id   = var.hub_vnet_resource_id
      registration_enabled = false
    }
  })
}

module "st" {
  source = "Azure/avm-res-storage-storageaccount/azurerm"

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags

  account_kind                  = "StorageV2"
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  public_network_access_enabled = false
  shared_access_key_enabled     = true

  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  private_endpoints = {
    file = {
      name                          = var.private_endpoint_name
      subnet_resource_id            = var.private_endpoint_subnet_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = [module.st_dns.resource_id]
    }
  }

  diagnostic_settings_storage_account = var.enable_diagnostics ? {
    sa = {
      name                  = "storage-diagnosticSettings"
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
}

# Optional file shares - migrated to AzAPI for AVM v1.0 compliance
resource "azapi_resource" "file_share" {
  for_each  = toset(var.shares)
  type      = "Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01"
  name      = each.value
  parent_id = "${module.st.resource_id}/fileServices/default"

  body = {
    properties = {
      shareQuota = 100
    }
  }

  schema_validation_enabled = true
}

