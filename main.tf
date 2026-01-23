# Naming module wiring

data "azapi_client_config" "naming" {}

locals {
  create_custom_named_rg = !local.existing_resource_group_used && var.created_resource_group_name != null && trimspace(var.created_resource_group_name) != ""
  # Deterministic uniqueness token derived from subscription + inputs
  naming_unique_id = substr(lower(replace(base64encode(sha256(local.naming_unique_seed)), "=", "")), 0, 13)
  naming_unique_seed = join("|", [
    data.azapi_client_config.naming.subscription_id,
    local.safe_location,
    var.environment,
    var.workload_name,
  ])
  # Resource group ID logic
  resource_group_id = local.existing_resource_group_used ? var.existing_resource_group_id : module.spoke_resource_group[0].resource_id
  # Resource group name logic - for existing RG, extract from ID using azapi provider function; for new RG with custom name, use it; otherwise use generated name from naming module
  resource_group_name = local.existing_resource_group_used ? provider::azapi::parse_resource_id(var.existing_resource_group_id).resource_group_name : (local.create_custom_named_rg ? var.created_resource_group_name : module.naming.resources_names.resourceGroup)
  safe_location       = replace(var.location, " ", "")
  # Determine if we're using an existing resource group from the input variable
  existing_resource_group_used = var.existing_resource_group_used
}

module "naming" {
  source = "./modules/naming"

  environment               = var.environment
  location                  = local.safe_location
  unique_id                 = local.naming_unique_id
  workload_name             = var.workload_name
  spoke_resource_group_name = local.create_custom_named_rg ? var.created_resource_group_name : ""
}

module "spoke_resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.0"
  count   = local.existing_resource_group_used ? 0 : 1

  location         = local.safe_location
  name             = local.resource_group_name
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}

# Spoke composition module (Stage 2+: LAW first)
module "spoke" {
  source = "./modules/spoke"

  location                                      = local.safe_location
  resource_group_id                             = local.resource_group_id
  resource_group_name                           = local.resource_group_name
  resources_names                               = module.naming.resources_names
  spoke_infra_subnet_address_prefix             = var.spoke_infra_subnet_address_prefix
  spoke_private_endpoints_subnet_address_prefix = var.spoke_private_endpoints_subnet_address_prefix
  spoke_vnet_address_prefixes                   = var.spoke_vnet_address_prefixes
  # Jumpbox VM
  bastion_subnet_address_prefix              = var.bastion_subnet_address_prefix
  bastion_access_enabled                     = var.bastion_access_enabled
  egress_lockdown_enabled                    = var.egress_lockdown_enabled
  hub_peering_enabled                        = var.hub_peering_enabled
  enable_telemetry                           = var.enable_telemetry
  virtual_machine_ssh_key_generation_enabled = var.virtual_machine_ssh_key_generation_enabled
  # Networking
  hub_virtual_network_resource_id                 = var.hub_virtual_network_resource_id
  log_analytics_workspace_replication_enabled     = var.log_analytics_workspace_replication_enabled
  network_appliance_ip_address                    = var.network_appliance_ip_address
  route_spoke_traffic_internally                  = var.route_spoke_traffic_internally
  spoke_application_gateway_subnet_address_prefix = var.spoke_application_gateway_subnet_address_prefix
  storage_account_type                            = var.storage_account_type
  tags                                            = var.tags
  virtual_machine_admin_password                  = var.virtual_machine_admin_password
  virtual_machine_authentication_type             = var.virtual_machine_authentication_type
  virtual_machine_jumpbox_os_type                 = var.virtual_machine_jumpbox_os_type
  virtual_machine_jumpbox_subnet_address_prefix   = var.virtual_machine_jumpbox_subnet_address_prefix
  virtual_machine_linux_ssh_authorized_key        = var.virtual_machine_linux_ssh_authorized_key
  virtual_machine_size                            = var.virtual_machine_size
  virtual_machine_zone                            = var.zone_redundant_resources_enabled ? 2 : 0
}

# Supporting services (ACR, Key Vault, Storage)
module "supporting_services" {
  source = "./modules/supporting_services"

  enable_telemetry                          = var.enable_telemetry
  location                                  = local.safe_location
  resource_group_id                         = local.resource_group_id
  resource_group_name                       = local.resource_group_name
  resources_names                           = module.naming.resources_names
  spoke_private_endpoint_subnet_resource_id = module.spoke.spoke_private_endpoints_subnet_id
  spoke_vnet_resource_id                    = module.spoke.spoke_vnet_id
  zone_redundant_resources_enabled          = var.zone_redundant_resources_enabled
  hub_peering_enabled                       = var.hub_peering_enabled
  expose_container_apps_with                = var.expose_container_apps_with
  hub_vnet_resource_id                      = var.hub_virtual_network_resource_id
  log_analytics_workspace_id                = module.spoke.log_analytics_workspace_id
  tags                                      = var.tags
}

# Container Apps Managed Environment + Private DNS + optional App Insights
module "container_apps_environment" {
  source = "./modules/container_apps_environment"

  # ACR pull identity
  container_registry_user_assigned_identity_id = module.supporting_services.container_registry_uai_id
  infrastructure_subnet_id                     = module.spoke.spoke_infra_subnet_id
  location                                     = local.safe_location
  log_analytics_workspace_customer_id          = module.spoke.log_analytics_workspace_customer_id
  # Observability
  log_analytics_workspace_id = module.spoke.log_analytics_workspace_id
  name                       = module.naming.resources_names.containerAppsEnvironment
  resource_group_id          = local.resource_group_id
  resource_group_name        = local.resource_group_name
  # Networking
  spoke_virtual_network_id = module.spoke.spoke_vnet_id
  # Optional storage mounts (none by default)
  container_apps_environment_storages = {}
  # Zone redundancy per workload setting
  zone_redundant_resources_enabled = var.zone_redundant_resources_enabled
  application_insights_enabled     = var.application_insights_enabled
  dapr_instrumentation_enabled     = var.dapr_instrumentation_enabled
  hub_peering_enabled              = var.hub_peering_enabled
  enable_telemetry                 = var.enable_telemetry
  hub_virtual_network_id           = var.hub_virtual_network_resource_id
  tags                             = var.tags
}

# Optional sample application (Hello World) deployed into the ACA environment
module "sample_application" {
  source = "./modules/sample_application"
  count  = var.sample_application_enabled ? 1 : 0

  # Target environment and profile
  container_app_environment_resource_id = module.container_apps_environment.managed_environment_id
  # Identity to pull images from ACR (already created in supporting services)
  container_registry_user_assigned_identity_id = module.supporting_services.container_registry_uai_id
  # Where to deploy
  resource_group_name   = local.resource_group_name
  enable_telemetry      = var.enable_telemetry
  tags                  = var.tags
  workload_profile_name = module.container_apps_environment.workload_profile_names[0]
}


# Ingress via Application Gateway (default path)
# Routes to the sample app if deployed, providing a working demo
module "application_gateway" {
  source = "./modules/application_gateway"
  count  = var.expose_container_apps_with == "application_gateway" ? 1 : 0

  location            = local.safe_location
  name                = module.naming.resources_names.applicationGateway
  public_ip_name      = module.naming.resources_names.applicationGatewayPip
  resource_group_name = local.resource_group_name
  subnet_id           = module.spoke.spoke_application_gateway_subnet_id
  # Backend - route to sample app if deployed, otherwise leave empty
  backend_fqdn                     = var.sample_application_enabled ? module.sample_application[0].fqdn : ""
  backend_probe_path               = "/"
  zone_redundant_resources_enabled = var.zone_redundant_resources_enabled
  enable_backend                   = var.sample_application_enabled
  ddos_protection_enabled          = var.ddos_protection_enabled
  enable_diagnostics               = true
  enable_telemetry                 = var.enable_telemetry
  # Diagnostics and HA
  log_analytics_workspace_id = module.spoke.log_analytics_workspace_id
  # NSG dependency for proper destroy ordering
  # This ensures the Application Gateway is fully destroyed before NSG rules are deleted
  subnet_nsg_id = module.spoke.spoke_application_gateway_nsg_id
  tags          = var.tags
}

# Ingress via Front Door (alternative path)
# Uses default *.azurefd.net endpoint with Microsoft-managed certificate
# Routes to sample Container App if deployed
# Note: Front Door always uses Premium SKU with Private Link for internal Container Apps Environment
module "front_door" {
  source = "./modules/front_door"
  count  = var.expose_container_apps_with == "front_door" ? 1 : 0

  location            = local.safe_location
  name                = module.naming.resources_names.frontDoor
  resource_group_name = local.resource_group_name
  # Backend Configuration - Route to sample app if deployed
  backend_fqdn     = var.sample_application_enabled ? module.sample_application[0].fqdn : ""
  backend_port     = 443
  backend_protocol = "Https"
  # Private Link Configuration - Required when backend is enabled
  container_apps_environment_id = module.container_apps_environment.managed_environment_id
  enable_backend                = var.sample_application_enabled
  enable_telemetry              = var.enable_telemetry
  # WAF Configuration - Optional
  enable_waf = var.front_door_waf_enabled
  # Diagnostics
  log_analytics_workspace_id = module.spoke.log_analytics_workspace_id
  # SKU Configuration - Premium SKU is required for Private Link support with internal Container Apps Environment
  # This is intentionally hard-coded as Standard SKU does not support Private Link origins.
  # See: https://learn.microsoft.com/azure/frontdoor/standard-premium/concept-private-link
  sku_name        = "Premium_AzureFrontDoor"
  tags            = var.tags
  waf_policy_name = var.front_door_waf_policy_name != null ? var.front_door_waf_policy_name : "${module.naming.resources_names.frontDoor}-waf"
}

