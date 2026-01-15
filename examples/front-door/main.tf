terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  storage_use_azuread = true
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# Test resource group for the module
resource "azurerm_resource_group" "this" {
  location = "swedencentral"
  name     = module.naming.resource_group.name_unique
}

# Front Door Premium with Private Link scenario
# Note: Front Door automatically uses Premium SKU with Private Link for internal Container Apps Environment
module "aca_lza_hosting" {
  source = "../../"

  # Observability
  enable_application_insights = true
  enable_dapr_instrumentation = false
  # Core
  location                                      = azurerm_resource_group.this.location
  spoke_infra_subnet_address_prefix             = "10.20.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.20.2.0/24"
  # Networking - Front Door doesn't need Application Gateway subnet
  spoke_vnet_address_prefixes = ["10.20.0.0/16"]
  # Optional features
  deploy_sample_application       = true
  deploy_zone_redundant_resources = true
  enable_ddos_protection          = false
  enable_telemetry                = var.enable_telemetry
  environment                     = "test"
  existing_resource_group_id      = azurerm_resource_group.this.id
  # Front Door Configuration
  # Front Door automatically uses Premium SKU with Private Link enabled
  expose_container_apps_with                  = "frontDoor"
  front_door_enable_waf                       = false # WAF is optional, defaults to disabled
  log_analytics_workspace_replication_enabled = false
  tags                                        = {}
  use_existing_resource_group                 = true
  vm_jumpbox_os_type                          = "none" # disable VM for this example
  # Naming
  workload_name = "fd"
}







