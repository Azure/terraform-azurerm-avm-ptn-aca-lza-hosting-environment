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

# Create a mock hub network for testing hub-spoke integration
resource "azurerm_resource_group" "hub" {
  location = "swedencentral"
  name     = "${module.naming.resource_group.name_unique}-hub"
}

resource "azurerm_virtual_network" "hub" {
  location            = azurerm_resource_group.hub.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
}

# Simulate a network appliance IP (like Azure Firewall)
resource "azurerm_subnet" "firewall" {
  address_prefixes     = ["10.0.1.0/26"]
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
}

resource "azurerm_public_ip" "firewall" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.hub.location
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# Test resource group for the module
resource "azurerm_resource_group" "this" {
  location = "swedencentral"
  name     = module.naming.resource_group.name_unique
}

# Complex scenario: Hub-spoke with Linux VM and full observability
module "aca_lza_hosting" {
  source = "../../"

  # Full observability stack (COMPLEX)
  application_insights_enabled = true
  dapr_instrumentation_enabled = true
  # Core
  location                                      = azurerm_resource_group.this.location
  spoke_infra_subnet_address_prefix             = "10.20.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.20.2.0/24"
  # Spoke networking - avoid overlap with hub
  spoke_vnet_address_prefixes = ["10.20.0.0/16"]
  # Deploy sample app
  sample_application_enabled = true
  # Zone redundancy for high availability (COMPLEX)
  zone_redundant_resources_enabled = true
  # DDoS protection disabled for automated testing
  ddos_protection_enabled                    = false
  egress_lockdown_enabled                    = true
  hub_peering_enabled                        = true
  enable_telemetry                           = var.enable_telemetry
  environment                                = "test"
  existing_resource_group_id                 = azurerm_resource_group.this.id
  expose_container_apps_with                 = "application_gateway"
  virtual_machine_ssh_key_generation_enabled = true
  # Hub-Spoke Integration (COMPLEX)
  hub_virtual_network_resource_id                 = azurerm_virtual_network.hub.id
  log_analytics_workspace_replication_enabled     = false
  network_appliance_ip_address                    = azurerm_public_ip.firewall.ip_address
  route_spoke_traffic_internally                  = false # Force traffic through hub
  spoke_application_gateway_subnet_address_prefix = "10.20.3.0/24"
  tags                                            = {}
  existing_resource_group_used                    = true
  virtual_machine_admin_password_generate         = true # Auto-generate password and store in Key Vault
  virtual_machine_authentication_type             = "ssh_public_key"
  virtual_machine_jumpbox_os_type                 = "linux"
  virtual_machine_jumpbox_subnet_address_prefix   = "10.20.5.0/24"
  # Linux VM with SSH authentication (COMPLEX)
  virtual_machine_size = "Standard_D2ds_v5"
  # Naming
  workload_name = "hubspoke"
}





