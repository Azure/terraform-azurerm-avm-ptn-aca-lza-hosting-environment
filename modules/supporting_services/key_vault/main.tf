locals {
  dns_zone_name = "privatelink.vaultcore.azure.net"

  # Azure CLI's first-party app ID (used when a user logs in interactively)
  azure_cli_client_id = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"

  principal_type = (
    trimspace(data.azurerm_client_config.current.client_id) == "" ||
    lower(trimspace(data.azurerm_client_config.current.client_id)) == local.azure_cli_client_id
    ? "User"
    : "ServicePrincipal"
  )
}

data "azurerm_client_config" "current" {}

module "kv_dns" {
  source = "Azure/avm-res-network-privatednszone/azurerm"

  domain_name      = local.dns_zone_name
  parent_id        = var.resource_group_id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags

  virtual_network_links = merge({
    spoke = {
      name                 = "kv-spoke-link"
      virtual_network_id   = var.spoke_vnet_resource_id
      registration_enabled = false
    }
    }, var.hub_vnet_resource_id == "" ? {} : {
    hub = {
      name                 = "kv-hub-link"
      virtual_network_id   = var.hub_vnet_resource_id
      registration_enabled = false
    }
  })
}

module "kv" {
  source = "Azure/avm-res-keyvault-vault/azurerm"

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags

  sku_name                        = "standard"
  network_acls                    = { bypass = "AzureServices", default_action = "Deny" }
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  public_network_access_enabled   = false
  enabled_for_template_deployment = true
  legacy_access_policies_enabled  = false

  private_endpoints = {
    pep = {
      name                          = var.private_endpoint_name
      subnet_resource_id            = var.private_endpoint_subnet_id
      private_dns_zone_resource_ids = [module.kv_dns.resource_id]
    }
  }
  # Grant the current client (Terraform principal) necessary permissions
  # Automatically detect if it's a User or ServicePrincipal
  role_assignments = {
    terraform_certificate_officer = {
      role_definition_id_or_name = "Key Vault Certificates Officer"
      principal_id               = data.azurerm_client_config.current.object_id
      principal_type             = local.principal_type
    }
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
