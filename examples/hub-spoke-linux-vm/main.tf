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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

# Generate SSH key for Linux VM
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a mock hub network for testing hub-spoke integration
resource "azurerm_resource_group" "hub" {
  location = var.location
  name     = "${var.resource_group_name}-hub"
}

resource "azurerm_virtual_network" "hub" {
  location            = azurerm_resource_group.hub.location
  name                = "vnet-hub-test"
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
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
  name                = "pip-fw-test"
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tags                = var.tags
}

# Test resource group for the module
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

# Complex scenario: Hub-spoke with Linux VM and full observability
module "aca_lza_hosting" {
  source = "../../"

  # Application Gateway with self-signed certificate
  deployment_subnet_address_prefix = "10.20.4.0/24"
  # Full observability stack (COMPLEX)
  enable_application_insights = true
  enable_dapr_instrumentation = true
  # Core
  location                                        = azurerm_resource_group.this.location
  spoke_application_gateway_subnet_address_prefix = "10.20.3.0/24"
  spoke_infra_subnet_address_prefix               = "10.20.1.0/24"
  spoke_private_endpoints_subnet_address_prefix   = "10.20.2.0/24"
  # Spoke networking - avoid overlap with hub
  spoke_vnet_address_prefixes      = ["10.20.0.0/16"]
  vm_admin_password                = "NotUsedForSSH123!" # Required but not used for SSH
  vm_jumpbox_subnet_address_prefix = "10.20.5.0/24"
  # Linux VM with SSH authentication (COMPLEX)
  vm_size = "Standard_DS2_v2"
  # Deploy sample app
  deploy_sample_application = true
  # Zone redundancy for high availability (COMPLEX)
  deploy_zone_redundant_resources = true
  # DDoS Protection (COMPLEX - expensive but important to test)
  enable_ddos_protection     = var.enable_ddos_protection
  enable_telemetry           = var.enable_telemetry
  environment                = var.environment
  existing_resource_group_id = azurerm_resource_group.this.id
  expose_container_apps_with = "applicationGateway"
  # Hub-Spoke Integration (COMPLEX)
  hub_virtual_network_resource_id = azurerm_virtual_network.hub.id
  network_appliance_ip_address    = azurerm_public_ip.firewall.ip_address
  route_spoke_traffic_internally  = false # Force traffic through hub
  tags                            = var.tags
  use_existing_resource_group     = true
  vm_authentication_type          = "sshPublicKey"
  vm_jumpbox_os_type              = "linux"
  vm_linux_ssh_authorized_key     = tls_private_key.ssh_key.public_key_openssh
  # Naming
  workload_name = var.workload_name
}





