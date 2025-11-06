

locals {
  # Map storages input into the AVM module's storages shape when account_name/share_name/access_key present
  storages_map = {
    for k, v in var.container_apps_environment_storages : k => {
      account_name = v.account_name
      share_name   = v.share_name
      access_key   = coalesce(try(v.access_key, null), "")
      access_mode  = v.access_mode
    } if try(v.kind, "") == "SMB"
  }

  work_profile_name = "general-purpose"

  # Build vnet links - use enable_hub_peering flag to determine keys statically
  # This avoids dynamic key issues when hub_virtual_network_id is computed
  virtual_network_links = merge(
    {
      spoke = {
        name               = "${var.name}-spoke-link"
        virtual_network_id = var.spoke_virtual_network_id
      }
    },
    var.enable_hub_peering ? {
      hub = {
        name               = "${var.name}-hub-link"
        virtual_network_id = var.hub_virtual_network_id
      }
    } : {}
  )
}

# Optional Application Insights (workspace-based)
module "application_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.2.0"
  count   = var.enable_application_insights ? 1 : 0

  location            = var.location
  name                = "${var.name}-ai"
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags
}

# ACA Managed Environment
module "managed_environment" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.3.0"

  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  # Dapr AI instrumentation (optional)
  dapr_application_insights_connection_string = var.enable_application_insights && var.enable_dapr_instrumentation ? module.application_insights[0].connection_string : null
  enable_telemetry                            = var.enable_telemetry
  # Networking and internal load balancer
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = true
  # Link to LAW (customerId + primary key)
  log_analytics_workspace_customer_id        = var.log_analytics_workspace_customer_id
  log_analytics_workspace_primary_shared_key = try(data.azapi_resource_action.law_shared_keys.output.primarySharedKey, null)
  # Managed Identity for ACR pull
  managed_identities = {
    user_assigned_resource_ids = [var.container_registry_user_assigned_identity_id]
  }
  # Storage mounts: only include entries provided with access keys (ensure non-sensitive map for for_each downstream)
  storages = nonsensitive(local.storages_map)
  tags     = var.tags
  # Increased timeout for Container Apps Environment creation (can take 45+ minutes with workload profiles)
  timeouts = {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
  # Workload profile and zone redundancy like Bicep
  workload_profile = [{
    name                  = local.work_profile_name
    workload_profile_type = "D4"
    minimum_count         = 0
    maximum_count         = 3
  }]
  zone_redundancy_enabled = var.deploy_zone_redundant_resources
}

# Private DNS zone: domain is the defaultDomain from ACA env
module "aca_privatedns" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.4.2"

  domain_name = module.managed_environment.default_domain
  parent_id   = var.resource_group_id
  # A record wildcard to static IP
  a_records = {
    wildcard = {
      name    = "*"
      ttl     = 300
      records = [module.managed_environment.static_ip_address]
    }
  }
  enable_telemetry      = var.enable_telemetry
  tags                  = var.tags
  virtual_network_links = local.virtual_network_links
}



data "azapi_resource_action" "law_shared_keys" {
  action                 = "sharedKeys"
  method                 = "POST"
  resource_id            = var.log_analytics_workspace_id
  type                   = "Microsoft.OperationalInsights/workspaces@2022-10-01"
  response_export_values = ["primarySharedKey"]
}
