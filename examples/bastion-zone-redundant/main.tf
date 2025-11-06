terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
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

# Create hub network with Bastion for testing
resource "azurerm_resource_group" "hub" {
  location = var.location
  name     = "${var.resource_group_name}-hub"
}

resource "azurerm_virtual_network" "hub" {
  location            = azurerm_resource_group.hub.location
  name                = "vnet-hub-bastion"
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Bastion subnet (required name and size)
resource "azurerm_subnet" "bastion" {
  address_prefixes     = ["10.0.1.0/27"]      # /27 is minimum for Bastion
  name                 = "AzureBastionSubnet" # Required name
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
}

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.hub.location
  name                = "pip-bastion-test"
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tags                = var.tags
  zones               = ["1", "2", "3"] # Zone redundant
}

# Bastion Host
resource "azurerm_bastion_host" "this" {
  location               = azurerm_resource_group.hub.location
  name                   = "bastion-test"
  resource_group_name    = azurerm_resource_group.hub.name
  file_copy_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = true
  sku                    = "Standard"
  tags                   = var.tags
  # Advanced Bastion features
  tunneling_enabled = true

  ip_configuration {
    name                 = "configuration"
    public_ip_address_id = azurerm_public_ip.bastion.id
    subnet_id            = azurerm_subnet.bastion.id
  }
}

# Test resource group for the module
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

# Complex scenario: Bastion integration with zone redundancy and all features
module "aca_lza_hosting" {
  source = "../../"

  # Application Gateway with zone redundancy
  deployment_subnet_address_prefix = "10.40.4.0/24"
  # Full observability stack (COMPLEX)
  enable_application_insights = true
  enable_dapr_instrumentation = true
  # Core
  location                                      = azurerm_resource_group.this.location
  spoke_infra_subnet_address_prefix             = "10.40.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.40.2.0/24"
  # Spoke networking - avoid overlap with hub
  spoke_vnet_address_prefixes = ["10.40.0.0/16"]
  bastion_resource_id         = azurerm_bastion_host.this.id
  # Deploy all optional features
  deploy_sample_application = true
  # Zone redundancy for maximum availability (COMPLEX)
  deploy_zone_redundant_resources = true
  # DDoS protection (optional - expensive)
  enable_ddos_protection     = var.enable_ddos_protection
  enable_telemetry           = var.enable_telemetry
  environment                = var.environment
  existing_resource_group_id = azurerm_resource_group.this.id
  expose_container_apps_with = "applicationGateway"
  # Bastion Integration (COMPLEX)
  hub_virtual_network_resource_id                 = azurerm_virtual_network.hub.id
  route_spoke_traffic_internally                  = false
  spoke_application_gateway_subnet_address_prefix = "10.40.3.0/24"
  tags                                            = var.tags
  use_existing_resource_group                     = true
  vm_admin_password                               = "NotUsedForSSH123!" # Required but not used for SSH
  vm_authentication_type                          = "sshPublicKey"
  vm_jumpbox_os_type                              = "linux"
  vm_jumpbox_subnet_address_prefix                = "10.40.5.0/24"
  vm_linux_ssh_authorized_key                     = tls_private_key.ssh_key.public_key_openssh
  # Linux VM with SSH for Bastion testing (COMPLEX)
  vm_size                                     = "Standard_DS2_v2"
  log_analytics_workspace_replication_enabled = false
  # Naming
  workload_name = var.workload_name
}







