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
  features {}
  storage_use_azuread = true
}


module "aca_lza_hosting" {
  source = "../../"

  # Required by module
  deployment_subnet_address_prefix = "10.10.4.0/24"
  # Observability toggles (as per variables): ensure required flags provided
  enable_application_insights = false
  enable_dapr_instrumentation = false
  # Core
  location                                      = var.location
  spoke_infra_subnet_address_prefix             = "10.10.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.10.2.0/24"
  # Minimal required networking to satisfy spoke inputs
  spoke_vnet_address_prefixes = ["10.10.0.0/16"]
  # Container Registry
  deploy_sample_application                       = true
  enable_telemetry                                = var.enable_telemetry
  environment                                     = var.environment
  expose_container_apps_with                      = "applicationGateway"
  spoke_application_gateway_subnet_address_prefix = "10.10.3.0/24"
  tags                                            = var.tags
  vm_jumpbox_os_type                              = "none"
  # Naming
  workload_name = var.workload_name
}

