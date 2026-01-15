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

# Create hub network with Bastion for testing
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
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # Zone redundant
}

# Bastion Host
resource "azurerm_bastion_host" "this" {
  location               = azurerm_resource_group.hub.location
  name                   = module.naming.bastion_host.name_unique
  resource_group_name    = azurerm_resource_group.hub.name
  file_copy_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = true
  sku                    = "Standard"
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
  location = "swedencentral"
  name     = module.naming.resource_group.name_unique
}

# Complex scenario: Bastion integration with zone redundancy and all features
module "aca_lza_hosting" {
  source = "../../"

  # Full observability stack (COMPLEX)
  enable_application_insights = true
  enable_dapr_instrumentation = true
  # Core
  location                                      = azurerm_resource_group.this.location
  spoke_infra_subnet_address_prefix             = "10.40.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.40.2.0/24"
  # Spoke networking - avoid overlap with hub
  spoke_vnet_address_prefixes   = ["10.40.0.0/16"]
  bastion_resource_id           = azurerm_bastion_host.this.id
  bastion_subnet_address_prefix = azurerm_subnet.bastion.address_prefixes[0]
  # Deploy all optional features
  deploy_sample_application = true
  # Zone redundancy for maximum availability (COMPLEX)
  deploy_zone_redundant_resources = true
  enable_bastion_access           = true
  # DDoS protection disabled for automated testing
  enable_ddos_protection     = false
  enable_telemetry           = var.enable_telemetry
  environment                = "test"
  existing_resource_group_id = azurerm_resource_group.this.id
  expose_container_apps_with = "applicationGateway"
  generate_ssh_key_for_vm    = true
  # Bastion Integration (COMPLEX)
  hub_virtual_network_resource_id                 = azurerm_virtual_network.hub.id
  log_analytics_workspace_replication_enabled     = false
  route_spoke_traffic_internally                  = false
  spoke_application_gateway_subnet_address_prefix = "10.40.3.0/24"
  tags                                            = {}
  use_existing_resource_group                     = true
  vm_admin_password                               = "NotUsedForSSH123!" # Required but not used for SSH
  vm_authentication_type                          = "sshPublicKey"
  vm_jumpbox_os_type                              = "linux"
  vm_jumpbox_subnet_address_prefix                = "10.40.5.0/24"
  # Linux VM with SSH for Bastion testing (COMPLEX)
  vm_size = "Standard_D2ds_v5"
  # Naming
  workload_name = "bastion"
}







