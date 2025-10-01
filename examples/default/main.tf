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

# Test RG for the module's resources
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

module "aca_lza_hosting" {
  source = "../../"

  # Required by module
  application_gateway_certificate_key_name = "${var.workload_name}-cert"
  deployment_subnet_address_prefix         = "10.10.4.0/24"
  # Observability toggles (as per variables): ensure required flags provided
  enable_application_insights = false
  enable_dapr_instrumentation = false
  # Core
  location                                        = azurerm_resource_group.this.location
  spoke_application_gateway_subnet_address_prefix = "10.10.3.0/24"
  spoke_infra_subnet_address_prefix               = "10.10.1.0/24"
  spoke_private_endpoints_subnet_address_prefix   = "10.10.2.0/24"
  # Minimal required networking to satisfy spoke inputs
  spoke_vnet_address_prefixes      = ["10.10.0.0/16"]
  vm_admin_password                = "P@ssword1234!ChangeMe" # replace via TF_VAR for real runs
  vm_jumpbox_subnet_address_prefix = "10.10.5.0/24"
  # VM/jumpbox minimal required inputs, keep VM disabled by default (vm_jumpbox_os_type = "none")
  vm_size = "Standard_DS2_v2"
  # Container Registry
  deploy_agent_pool           = false
  deploy_sample_application   = true
  enable_telemetry            = var.enable_telemetry
  environment                 = var.environment
  existing_resource_group_id  = azurerm_resource_group.this.id
  expose_container_apps_with  = "applicationGateway"
  tags                        = var.tags
  use_existing_resource_group = true
  vm_authentication_type      = "password"
  vm_jumpbox_os_type          = "none"
  vm_linux_ssh_authorized_key = ""
  # Naming
  workload_name = var.workload_name
}

