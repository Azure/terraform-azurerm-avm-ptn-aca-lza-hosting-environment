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

# Minimal scenario: Test edge cases with minimal configuration
module "aca_lza_hosting" {
  source = "../../"

  # NO Application Gateway (COMPLEX edge case)
  application_gateway_certificate_key_name = "${var.workload_name}-cert" # Required but unused
  deployment_subnet_address_prefix         = "172.16.0.48/28"            # /28 = 16 IPs
  # NO observability (COMPLEX edge case)
  enable_application_insights = false
  enable_dapr_instrumentation = false
  # Core - minimal required configuration
  location                                        = azurerm_resource_group.this.location
  spoke_application_gateway_subnet_address_prefix = "172.16.0.32/28" # /28 = 16 IPs (minimum for App GW)
  spoke_infra_subnet_address_prefix               = "172.16.0.0/28"  # /28 = 16 IPs
  spoke_private_endpoints_subnet_address_prefix   = "172.16.0.16/28" # /28 = 16 IPs
  # Minimal networking - small address spaces
  spoke_vnet_address_prefixes      = ["172.16.0.0/24"] # Small /24
  vm_admin_password                = "NotUsed123!"     # Required but unused
  vm_jumpbox_subnet_address_prefix = "172.16.0.64/28"  # Required but unused
  # NO VM deployment (COMPLEX edge case)
  vm_size                                      = "Standard_DS2_v2" # Required but unused
  application_gateway_certificate_subject_name = "CN=contoso.com"  # Default
  application_gateway_fqdn                     = ""                # Empty
  # NO agent pool to minimize resources
  deploy_agent_pool = false
  # NO sample application
  deploy_sample_application = false
  # Minimal availability - single zone
  deploy_zone_redundant_resources = false
  # NO DDoS protection
  enable_ddos_protection     = false
  enable_telemetry           = var.enable_telemetry
  environment                = var.environment
  existing_resource_group_id = azurerm_resource_group.this.id
  expose_container_apps_with = "none" # NO App Gateway
  # No hub integration - isolated spoke
  hub_virtual_network_resource_id = ""
  network_appliance_ip_address    = ""
  route_spoke_traffic_internally  = true
  tags                            = var.tags
  use_existing_resource_group     = true
  vm_authentication_type          = "password" # Required but unused
  vm_jumpbox_os_type              = "none"     # NO VM
  vm_linux_ssh_authorized_key     = ""         # Not used
  # Naming - short names to test validation
  workload_name = var.workload_name
}




