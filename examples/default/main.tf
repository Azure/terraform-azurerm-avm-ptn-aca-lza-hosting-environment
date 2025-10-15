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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

# Generate a random password for VM admin
resource "random_password" "vm_admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}


module "aca_lza_hosting" {
  source = "../../"

  # Required by module
  deployment_subnet_address_prefix = "10.10.4.0/24"
  # Observability toggles (as per variables): ensure required flags provided
  enable_application_insights = false
  enable_dapr_instrumentation = false
  # Core
  location                                        = var.location
  spoke_application_gateway_subnet_address_prefix = "10.10.3.0/24"
  spoke_infra_subnet_address_prefix               = "10.10.1.0/24"
  spoke_private_endpoints_subnet_address_prefix   = "10.10.2.0/24"
  # Minimal required networking to satisfy spoke inputs
  spoke_vnet_address_prefixes      = ["10.10.0.0/16"]
  vm_admin_password                = random_password.vm_admin.result
  vm_jumpbox_subnet_address_prefix = "10.10.5.0/24"
  # VM/jumpbox minimal required inputs, keep VM disabled by default (vm_jumpbox_os_type = "none")
  vm_size = "Standard_DS2_v2"
  # Container Registry
  deploy_sample_application   = true
  enable_telemetry            = var.enable_telemetry
  environment                 = var.environment
  expose_container_apps_with  = "applicationGateway"
  tags                        = var.tags
  vm_authentication_type      = "password"
  vm_jumpbox_os_type          = "none"
  vm_linux_ssh_authorized_key = ""
  # Naming
  workload_name = var.workload_name
}

