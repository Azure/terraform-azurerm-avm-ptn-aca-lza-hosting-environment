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

# Windows VM scenario - No Application Gateway deployed
# When Application Gateway is deployed, it automatically generates self-signed certificates
module "aca_lza_hosting" {
  source = "../../"

  # Core networking
  deployment_subnet_address_prefix = "10.30.4.0/24"
  # Observability - mixed configuration
  enable_application_insights = true
  enable_dapr_instrumentation = false # Test mixed observability
  # Core - Let module create RG with custom name (COMPLEX)
  location                                      = var.location
  spoke_infra_subnet_address_prefix             = "10.30.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.30.2.0/24"
  # Spoke networking
  spoke_vnet_address_prefixes = ["10.30.0.0/16"]
  created_resource_group_name = var.resource_group_name
  # No sample app to test minimal deployment
  deploy_sample_application = false
  # No zone redundancy for cost optimization (COMPLEX test case)
  deploy_zone_redundant_resources = false
  # No DDoS protection for cost efficiency
  enable_ddos_protection = false
  enable_telemetry       = var.enable_telemetry
  environment            = var.environment
  # NO Application Gateway - test alternate ingress (COMPLEX)
  expose_container_apps_with = "none"
  # No hub integration - standalone spoke
  hub_virtual_network_resource_id                 = ""
  network_appliance_ip_address                    = ""
  route_spoke_traffic_internally                  = true
  spoke_application_gateway_subnet_address_prefix = "10.30.3.0/24"
  tags                                            = var.tags
  use_existing_resource_group                     = false
  vm_admin_password                               = var.vm_admin_password
  vm_authentication_type                          = "password"
  vm_jumpbox_os_type                              = "windows"
  vm_jumpbox_subnet_address_prefix                = "10.30.5.0/24"
  vm_linux_ssh_authorized_key                     = "" # Not used for Windows
  # Windows VM with password authentication (COMPLEX)
  vm_size = "Standard_DS2_v2"
  # Naming
  workload_name = var.workload_name
}




