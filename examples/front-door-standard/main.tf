terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

# Test resource group for the module
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

# Front Door Standard scenario with TLS termination
module "aca_lza_hosting" {
  source = "../../"

  # Application Gateway (still required even when not used)
  application_gateway_certificate_key_name = "${var.workload_name}-agw-cert" # Not used but required
  deployment_subnet_address_prefix         = "10.20.4.0/24"
  # Observability
  enable_application_insights = true
  enable_dapr_instrumentation = false
  # Core
  location                                        = azurerm_resource_group.this.location
  spoke_application_gateway_subnet_address_prefix = "" # Not needed for Front Door
  spoke_infra_subnet_address_prefix               = "10.20.1.0/24"
  spoke_private_endpoints_subnet_address_prefix   = "10.20.2.0/24"
  # Networking - Front Door doesn't need Application Gateway subnet
  spoke_vnet_address_prefixes      = ["10.20.0.0/16"]
  vm_admin_password                = "P@ssword1234!ChangeMe" # replace via TF_VAR for real runs
  vm_jumpbox_subnet_address_prefix = "10.20.5.0/24"
  # VM/jumpbox configuration (disabled for this example)
  vm_size = "Standard_DS2_v2"
  # Optional features
  deploy_sample_application       = true
  deploy_zone_redundant_resources = var.deploy_zone_redundant_resources
  enable_ddos_protection          = false
  enable_telemetry                = var.enable_telemetry
  environment                     = var.environment
  existing_resource_group_id      = azurerm_resource_group.this.id
  # Front Door Configuration
  expose_container_apps_with      = "frontDoor"
  front_door_certificate_key_name = var.certificate_key_name
  front_door_enable_waf           = false # Standard SKU doesn't support WAF
  front_door_fqdn                 = var.front_door_fqdn
  front_door_sku_name             = "Standard_AzureFrontDoor"
  tags                            = var.tags
  use_existing_resource_group     = true
  vm_jumpbox_os_type              = "none" # disable VM for this example
  # Naming
  workload_name = var.workload_name
}







