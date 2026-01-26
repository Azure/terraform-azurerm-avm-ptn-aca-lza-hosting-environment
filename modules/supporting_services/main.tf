###############################################
# Supporting Services - Inlined Resources     #
# (ACR, Key Vault, Storage Account)           #
###############################################

locals {
  tags = var.tags

  # DNS Zone names
  acr_dns_zone_name = "privatelink.azurecr.io"
  kv_dns_zone_name  = "privatelink.vaultcore.azure.net"
  st_dns_zone_name  = "privatelink.file.core.windows.net"

  # Azure CLI's first-party app ID (used when a user logs in interactively)
  azure_cli_client_id = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"

  # Determine principal type for Key Vault RBAC
  principal_type = (
    trimspace(data.azurerm_client_config.current.client_id) == "" ||
    lower(trimspace(data.azurerm_client_config.current.client_id)) == local.azure_cli_client_id
    ? "User"
    : "ServicePrincipal"
  )

  # VNet links for ACR DNS zone
  acr_vnet_links_map = merge(
    {
      spoke = {
        name                 = "acr-spoke-link"
        virtual_network_id   = var.spoke_vnet_resource_id
        registration_enabled = false
      }
    },
    var.hub_peering_enabled ? {
      hub = {
        name                 = "acr-hub-link"
        virtual_network_id   = var.hub_vnet_resource_id
        registration_enabled = false
      }
    } : {}
  )

  # VNet links for Key Vault DNS zone
  kv_vnet_links_map = merge(
    {
      spoke = {
        name                 = "kv-spoke-link"
        virtual_network_id   = var.spoke_vnet_resource_id
        registration_enabled = false
      }
    },
    var.hub_peering_enabled ? {
      hub = {
        name                 = "kv-hub-link"
        virtual_network_id   = var.hub_vnet_resource_id
        registration_enabled = false
      }
    } : {}
  )

  # VNet links for Storage DNS zone
  st_vnet_links_map = merge(
    {
      spoke = {
        name                 = "st-spoke-link"
        virtual_network_id   = var.spoke_vnet_resource_id
        registration_enabled = false
      }
    },
    var.hub_peering_enabled ? {
      hub = {
        name                 = "st-hub-link"
        virtual_network_id   = var.hub_vnet_resource_id
        registration_enabled = false
      }
    } : {}
  )
}

# Get current Azure context for Key Vault RBAC
data "azurerm_client_config" "current" {}

###############################################
# Container Registry (ACR)                    #
###############################################

module "acr_uai" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.4"

  name                = var.resources_names.containerRegistryUserAssignedIdentity
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
}

module "acr_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.4.4"

  domain_name           = local.acr_dns_zone_name
  parent_id             = var.resource_group_id
  enable_telemetry      = var.enable_telemetry
  tags                  = local.tags
  virtual_network_links = local.acr_vnet_links_map
}

module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.5.1"

  name                = var.resources_names.containerRegistry
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"
  zone_redundancy_enabled       = var.zone_redundant_resources_enabled
  enable_trust_policy           = true
  quarantine_policy_enabled     = true
  retention_policy_in_days      = 7
  export_policy_enabled         = false

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [module.acr_uai.resource_id]
  }

  role_assignments = {
    acr_pull = {
      role_definition_id_or_name = "AcrPull"
      principal_id               = module.acr_uai.principal_id
      principal_type             = "ServicePrincipal"
    }
  }

  private_endpoints = {
    pep = {
      name                          = var.resources_names.containerRegistryPep
      subnet_resource_id            = var.spoke_private_endpoint_subnet_resource_id
      private_dns_zone_resource_ids = [module.acr_dns_zone.resource_id]
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

###############################################
# Key Vault                                   #
###############################################

module "kv_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.4.4"

  domain_name           = local.kv_dns_zone_name
  parent_id             = var.resource_group_id
  enable_telemetry      = var.enable_telemetry
  tags                  = local.tags
  virtual_network_links = local.kv_vnet_links_map
}

module "kv" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  name                = var.resources_names.keyVault
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  sku_name                        = "standard"
  network_acls                    = { bypass = "AzureServices", default_action = "Deny" }
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  public_network_access_enabled   = false
  enabled_for_template_deployment = true
  legacy_access_policies_enabled  = false

  private_endpoints = {
    pep = {
      name                          = var.resources_names.keyVaultPep
      subnet_resource_id            = var.spoke_private_endpoint_subnet_resource_id
      private_dns_zone_resource_ids = [module.kv_dns_zone.resource_id]
    }
  }

  # Grant the current client (Terraform principal) necessary permissions
  role_assignments = {
    terraform_secrets_officer = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
      principal_type             = local.principal_type
    }
  }

  diagnostic_settings = var.enable_diagnostics ? {
    kv = {
      name                  = "keyvault-diagnosticSettings"
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
}

###############################################
# Storage Account                             #
###############################################

module "st_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.4.4"

  domain_name           = local.st_dns_zone_name
  parent_id             = var.resource_group_id
  enable_telemetry      = var.enable_telemetry
  tags                  = local.tags
  virtual_network_links = local.st_vnet_links_map
}

module "st" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.1"

  name                = var.resources_names.storageAccount
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

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
      name                          = "storage-pep"
      subnet_resource_id            = var.spoke_private_endpoint_subnet_resource_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = [module.st_dns_zone.resource_id]
    }
  }

  diagnostic_settings_storage_account = var.enable_diagnostics ? {
    sa = {
      name                  = "storage-diagnosticSettings"
      workspace_resource_id = var.log_analytics_workspace_id
      metric_categories     = ["Transaction"]
    }
  } : {}
}

# File shares - using AzAPI for AVM v1.0 compliance
resource "azapi_resource" "file_share" {
  for_each  = toset(["smbfileshare"])
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
