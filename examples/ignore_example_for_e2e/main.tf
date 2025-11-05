terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

module "aca_lza_hosting" {
  source = "../../"

  # Required by module
  deployment_subnet_address_prefix = "10.30.4.0/24"
  # Observability toggles
  enable_application_insights                   = false
  enable_dapr_instrumentation                   = false
  location                                      = azurerm_resource_group.this.location
  spoke_infra_subnet_address_prefix             = "10.30.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.30.2.0/24"
  # Required networking
  spoke_vnet_address_prefixes = ["10.30.0.0/16"]
  enable_telemetry            = var.enable_telemetry
  environment                 = var.environment
  # Disable ingress - no Application Gateway or Front Door
  expose_container_apps_with = "none"
  tags                       = var.tags
  vm_jumpbox_os_type         = "none"
  workload_name              = var.workload_name
}
