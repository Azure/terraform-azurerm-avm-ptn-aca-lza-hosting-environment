# Naming module wiring

data "azapi_client_config" "naming" {}

# Validation to ensure only one resource group approach is used
resource "null_resource" "resource_group_validation" {
  lifecycle {
    precondition {
      condition     = !(var.created_resource_group_name != null && var.existing_resource_group_id != null)
      error_message = "Cannot specify both created_resource_group_name (for new RG) and existing_resource_group_id (for existing RG). Please provide only one, or leave both null for auto-generation."
    }
  }
}

locals {
  create_custom_named_rg = !local.use_existing_resource_group && var.created_resource_group_name != null && trimspace(var.created_resource_group_name) != ""
  # Deterministic uniqueness token derived from subscription + inputs
  naming_unique_id = substr(lower(replace(base64encode(sha256(local.naming_unique_seed)), "=", "")), 0, 13)
  naming_unique_seed = join("|", [
    data.azapi_client_config.naming.subscription_id,
    local.safe_location,
    var.environment,
    var.workload_name,
  ])
  # Resource group ID logic
  resource_group_id = local.use_existing_resource_group ? var.existing_resource_group_id : module.spoke_resource_group[0].resource_id
  # Resource group name logic - for existing RG, extract from ID; for new RG with custom name, use it; otherwise use generated name from naming module
  resource_group_name = local.use_existing_resource_group ? regex("/resourceGroups/([^/]+)", var.existing_resource_group_id)[0] : (local.create_custom_named_rg ? var.created_resource_group_name : module.naming.resources_names.resourceGroup)
  safe_location       = replace(var.location, " ", "")
  # Determine if we're using an existing resource group from the input variable
  use_existing_resource_group = var.use_existing_resource_group
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
  count   = local.use_existing_resource_group ? 0 : 1

  location         = local.safe_location
  name             = local.resource_group_name
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}

# Spoke composition module (Stage 2+: LAW first)
module "spoke" {
  source = "./modules/spoke"

  deployment_subnet_address_prefix              = var.deployment_subnet_address_prefix
  location                                      = local.safe_location
  resource_group_id                             = local.resource_group_id
  resource_group_name                           = local.resource_group_name
  resources_names                               = module.naming.resources_names
  spoke_infra_subnet_address_prefix             = var.spoke_infra_subnet_address_prefix
  spoke_private_endpoints_subnet_address_prefix = var.spoke_private_endpoints_subnet_address_prefix
  spoke_vnet_address_prefixes                   = var.spoke_vnet_address_prefixes
  # Jumpbox VM
  bastion_resource_id     = var.bastion_resource_id
  enable_bastion_access   = var.enable_bastion_access
  enable_egress_lockdown  = var.enable_egress_lockdown
  enable_hub_peering      = var.enable_hub_peering
  enable_telemetry        = var.enable_telemetry
  generate_ssh_key_for_vm = var.generate_ssh_key_for_vm
  # Networking
  hub_virtual_network_resource_id                 = var.hub_virtual_network_resource_id
  log_analytics_workspace_replication_enabled     = var.log_analytics_workspace_replication_enabled
  network_appliance_ip_address                    = var.network_appliance_ip_address
  route_spoke_traffic_internally                  = var.route_spoke_traffic_internally
  spoke_application_gateway_subnet_address_prefix = var.spoke_application_gateway_subnet_address_prefix
  storage_account_type                            = var.storage_account_type
  tags                                            = var.tags
  vm_admin_password                               = var.vm_admin_password
  vm_authentication_type                          = var.vm_authentication_type
  vm_jumpbox_os_type                              = var.vm_jumpbox_os_type
  vm_jumpbox_subnet_address_prefix                = var.vm_jumpbox_subnet_address_prefix
  vm_linux_ssh_authorized_key                     = var.vm_linux_ssh_authorized_key
  vm_size                                         = var.vm_size
  vm_zone                                         = var.deploy_zone_redundant_resources ? 2 : 0

  depends_on = [module.spoke_resource_group]
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
  deploy_zone_redundant_resources           = var.deploy_zone_redundant_resources
  enable_hub_peering                        = var.enable_hub_peering
  expose_container_apps_with                = var.expose_container_apps_with
  hub_vnet_resource_id                      = var.hub_virtual_network_resource_id
  log_analytics_workspace_id                = module.spoke.log_analytics_workspace_id
  tags                                      = var.tags

  depends_on = [module.spoke_resource_group]
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
  deploy_zone_redundant_resources = var.deploy_zone_redundant_resources
  enable_application_insights     = var.enable_application_insights
  enable_dapr_instrumentation     = var.enable_dapr_instrumentation
  enable_hub_peering              = var.enable_hub_peering
  enable_telemetry                = var.enable_telemetry
  hub_virtual_network_id          = var.hub_virtual_network_resource_id
  tags                            = var.tags

  depends_on = [module.spoke_resource_group]
}

# Optional sample application (Hello World) deployed into the ACA environment
module "sample_application" {
  source = "./modules/sample_application"
  count  = var.deploy_sample_application ? 1 : 0

  # Target environment and profile
  container_app_environment_resource_id = module.container_apps_environment.managed_environment_id
  # Identity to pull images from ACR (already created in supporting services)
  container_registry_user_assigned_identity_id = module.supporting_services.container_registry_uai_id
  # Where to deploy
  resource_group_name   = local.resource_group_name
  enable_telemetry      = var.enable_telemetry
  tags                  = var.tags
  workload_profile_name = module.container_apps_environment.workload_profile_names[0]

  depends_on = [module.spoke_resource_group]
}


# Ingress via Application Gateway (default path)
# Routes to the sample app if deployed, providing a working demo
module "application_gateway" {
  source = "./modules/application_gateway"
  count  = var.expose_container_apps_with == "applicationGateway" ? 1 : 0

  location            = local.safe_location
  name                = module.naming.resources_names.applicationGateway
  public_ip_name      = module.naming.resources_names.applicationGatewayPip
  resource_group_name = local.resource_group_name
  subnet_id           = module.spoke.spoke_application_gateway_subnet_id
  # Backend - route to sample app if deployed, otherwise leave empty
  backend_fqdn                    = var.deploy_sample_application ? module.sample_application[0].fqdn : ""
  backend_probe_path              = "/"
  deploy_zone_redundant_resources = var.deploy_zone_redundant_resources
  enable_backend                  = var.deploy_sample_application
  enable_ddos_protection          = var.enable_ddos_protection
  enable_diagnostics              = true
  enable_telemetry                = var.enable_telemetry
  # Diagnostics and HA
  log_analytics_workspace_id = module.spoke.log_analytics_workspace_id
  tags                       = var.tags
}

# Ingress via Front Door (alternative path)
# Uses default *.azurefd.net endpoint with Microsoft-managed certificate
# Routes to sample Container App if deployed
# Note: Front Door always uses Premium SKU with Private Link for internal Container Apps Environment
module "front_door" {
  source = "./modules/front_door"
  count  = var.expose_container_apps_with == "frontDoor" ? 1 : 0

  location            = local.safe_location
  name                = module.naming.resources_names.frontDoor
  resource_group_name = local.resource_group_name
  # Backend Configuration - Route to sample app if deployed
  backend_fqdn     = var.deploy_sample_application ? module.sample_application[0].fqdn : ""
  backend_port     = 443
  backend_protocol = "Https"
  # Private Link Configuration - Required when backend is enabled
  container_apps_environment_id = module.container_apps_environment.managed_environment_id
  enable_backend                = var.deploy_sample_application
  enable_telemetry              = var.enable_telemetry
  # WAF Configuration - Optional
  enable_waf = var.front_door_enable_waf
  # Diagnostics
  log_analytics_workspace_id = module.spoke.log_analytics_workspace_id
  # SKU Configuration - Always Premium for Private Link support
  sku_name        = "Premium_AzureFrontDoor" # Required for Private Link
  tags            = var.tags
  waf_policy_name = var.front_door_waf_policy_name != null ? var.front_door_waf_policy_name : "${module.naming.resources_names.frontDoor}-waf"
}

