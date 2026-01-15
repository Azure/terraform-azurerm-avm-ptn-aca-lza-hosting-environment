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

# Minimal scenario: Test edge cases with minimal configuration
module "aca_lza_hosting" {
  source = "../../"

  # NO observability (COMPLEX edge case)
  enable_application_insights = false
  enable_dapr_instrumentation = false
  # Core - minimal required configuration
  location                                      = azurerm_resource_group.this.location
  spoke_infra_subnet_address_prefix             = "172.16.0.0/27"  # /27 = 32 IPs (REQUIRED minimum for Container Apps)
  spoke_private_endpoints_subnet_address_prefix = "172.16.0.32/28" # /28 = 16 IPs
  # Minimal networking - small address spaces
  spoke_vnet_address_prefixes = ["172.16.0.0/24"] # Small /24
  # NO sample application
  deploy_sample_application = false
  # Minimal availability - single zone
  deploy_zone_redundant_resources = false
  # NO DDoS protection
  enable_ddos_protection     = false
  enable_telemetry           = var.enable_telemetry
  environment                = "dev"
  existing_resource_group_id = azurerm_resource_group.this.id
  expose_container_apps_with = "none" # NO App Gateway
  # No hub integration - isolated spoke
  hub_virtual_network_resource_id             = ""
  log_analytics_workspace_replication_enabled = false
  network_appliance_ip_address                = ""
  route_spoke_traffic_internally              = true
  tags                                        = {}
  use_existing_resource_group                 = true
  vm_jumpbox_os_type                          = "none" # NO VM
  # Naming - short names to test validation
  workload_name = "min"
}




