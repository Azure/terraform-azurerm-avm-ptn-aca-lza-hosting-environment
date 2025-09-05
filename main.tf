// Naming module wiring

data "azapi_client_config" "naming" {}

# Validation to ensure only one resource group approach is used
# resource "null_resource" "resource_group_validation" {
#   lifecycle {
#     precondition {
#       condition     = var.use_existing_resource_group == true  && trimspace(var.existing_resource_group_id) == ""
#       error_message = "existing_resource_group_id must be provided when use_existing_resource_group is true."
#     }
#   }
# }

locals {
  naming_unique_seed = join("|", [
    data.azapi_client_config.naming.subscription_id,
    var.location,
    var.environment,
    var.workload_name,
  ])

  // Deterministic uniqueness token derived from subscription + inputs
  naming_unique_id = substr(lower(replace(base64encode(sha256(local.naming_unique_seed)), "=", "")), 0, 13)

  // Determine the resource group scenario based on input variables only

  create_custom_named_rg      = !var.use_existing_resource_group && trimspace(var.created_resource_group_name) != ""
  create_auto_named_rg        = !var.use_existing_resource_group && trimspace(var.created_resource_group_name) == ""

  // For existing resource groups, extract the name from the ID
  existing_resource_group_name = var.use_existing_resource_group ? split("/", var.existing_resource_group_id)[4] : ""

  // Input to the naming module (empty for auto-generation)
  naming_module_resource_group_input = var.use_existing_resource_group ? local.existing_resource_group_name : local.create_custom_named_rg ? var.created_resource_group_name : ""

  // Resource group ID logic
  resource_group_id = var.use_existing_resource_group ? var.existing_resource_group_id : (length(module.spoke_resource_group) > 0 ? module.spoke_resource_group[0].resource_id : "")

}

module "naming" {
  source = "./modules/naming"

  workload_name             = var.workload_name
  spoke_resource_group_name = local.naming_module_resource_group_input
  environment               = var.environment
  location                  = var.location
  unique_id                 = local.naming_unique_id
}

# Final resource group name calculation (must be after naming module)
locals {
  final_resource_group_name = (
   var.use_existing_resource_group
    ? local.existing_resource_group_name
    : module.naming.resources_names.resourceGroup
  )
}

module "spoke_resource_group" {
  count   = var.use_existing_resource_group ? 0 : 1
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  name             = local.create_custom_named_rg ? var.created_resource_group_name : module.naming.resources_names.resourceGroup
  location         = var.location
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}




// Spoke composition module (Stage 2+: LAW first)
module "spoke" {
  source = "./modules/spoke"

  resources_names     = module.naming.resources_names
  location            = var.location
  resource_group_id   = local.resource_group_id
  resource_group_name = local.final_resource_group_name
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

// Supporting services (ACR, Key Vault, Storage)
module "supporting_services" {
  source = "./modules/supporting_services"

  resources_names                           = module.naming.resources_names
  location                                  = var.location
  resource_group_id                         = local.resource_group_id
  resource_group_name                       = local.final_resource_group_name
  tags                                      = var.tags
  enable_telemetry                          = var.enable_telemetry
  hub_vnet_resource_id                      = var.hub_virtual_network_resource_id
  spoke_vnet_resource_id                    = module.spoke.spoke_vnet_id
  spoke_private_endpoint_subnet_resource_id = module.spoke.spoke_private_endpoints_subnet_id
  log_analytics_workspace_id                = module.spoke.log_analytics_workspace_id
  deploy_zone_redundant_resources           = var.deploy_zone_redundant_resources
  deploy_agent_pool                         = var.deploy_agent_pool
}

// Container Apps Managed Environment + Private DNS + optional App Insights
module "container_apps_environment" {
  source = "./modules/container_apps_environment"

  name                = module.naming.resources_names.containerAppsEnvironment
  resource_group_name = local.final_resource_group_name
  resource_group_id   = local.resource_group_id
  location            = var.location
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  # Networking
  spoke_virtual_network_id = module.spoke.spoke_vnet_id
  hub_virtual_network_id   = var.hub_virtual_network_resource_id
  infrastructure_subnet_id = module.spoke.spoke_infra_subnet_id

  # Observability
  log_analytics_workspace_id          = module.spoke.log_analytics_workspace_id
  log_analytics_workspace_customer_id = module.spoke.log_analytics_workspace_customer_id
  enable_application_insights         = var.enable_application_insights
  enable_dapr_instrumentation         = var.enable_dapr_instrumentation

  # ACR pull identity
  container_registry_user_assigned_identity_id = module.supporting_services.container_registry_uai_id

  # Zone redundancy per workload setting
  deploy_zone_redundant_resources = var.deploy_zone_redundant_resources

  # Optional storage mounts (none by default)
  container_apps_environment_storages = {}
}

// Optional sample application (Hello World) deployed into the ACA environment
module "sample_application" {
  count  = var.deploy_sample_application ? 1 : 0
  source = "./modules/sample_application"

  enable_telemetry = var.enable_telemetry
  location         = var.location
  tags             = var.tags

  // Where to deploy
  resource_group_name = local.final_resource_group_name

  // Target environment and profile
  container_app_environment_resource_id = module.container_apps_environment.managed_environment_id
  workload_profile_name                 = module.container_apps_environment.workload_profile_names[0]

  // Identity to pull images from ACR (already created in supporting services)
  container_registry_user_assigned_identity_id = module.supporting_services.container_registry_uai_id
}


# Ingress via Application Gateway (default path)
module "application_gateway" {
  count  = var.expose_container_apps_with == "applicationGateway" ? 1 : 0
  source = "./modules/application_gateway"

  name                = module.naming.resources_names.applicationGateway
  resource_group_name = local.final_resource_group_name
  location            = var.location
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  subnet_id                   = module.spoke.spoke_application_gateway_subnet_id
  public_ip_name              = module.naming.resources_names.applicationGatewayPip
  user_assigned_identity_name = module.naming.resources_names.applicationGatewayUserAssignedIdentity

  # TLS and FQDN
  application_gateway_fqdn = var.application_gateway_fqdn
  base64_certificate       = var.base64_certificate
  certificate_key_name     = var.application_gateway_certificate_key_name
  certificate_subject_name = var.application_gateway_certificate_subject_name
  key_vault_id             = module.supporting_services.key_vault_id

  # Certificate deployment requirements
  storage_account_name = module.supporting_services.storage_account_name
  deployment_subnet_id = module.spoke.deployment_subnet_id

  # Backend
  backend_fqdn       = var.application_gateway_backend_fqdn
  backend_probe_path = "/"

  # Diagnostics and HA
  log_analytics_workspace_id      = module.spoke.log_analytics_workspace_id
  enable_diagnostics              = true
  deploy_zone_redundant_resources = var.deploy_zone_redundant_resources
  enable_ddos_protection          = var.enable_ddos_protection
}


