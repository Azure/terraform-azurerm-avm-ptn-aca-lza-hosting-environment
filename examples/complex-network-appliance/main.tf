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

# Create complex hub network with multiple appliances
resource "azurerm_resource_group" "hub" {
  location = var.location
  name     = "${var.resource_group_name}-hub-complex"
}

resource "azurerm_virtual_network" "hub" {
  location            = azurerm_resource_group.hub.location
  name                = "vnet-hub-complex"
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.100.0.0/16"]
  tags                = var.tags
}

# Azure Firewall subnet
resource "azurerm_subnet" "firewall" {
  address_prefixes     = ["10.100.1.0/24"]
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
}

# Management subnet for firewall
resource "azurerm_subnet" "firewall_mgmt" {
  address_prefixes     = ["10.100.2.0/24"]
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
}

# Public IPs for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.hub.location
  name                = "pip-fw-complex"
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tags                = var.tags
  zones               = ["1", "2", "3"]
}

resource "azurerm_public_ip" "firewall_mgmt" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.hub.location
  name                = "pip-fw-mgmt-complex"
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tags                = var.tags
  zones               = ["1", "2", "3"]
}

# Azure Firewall with complex configuration
resource "azurerm_firewall" "this" {
  location            = azurerm_resource_group.hub.location
  name                = "fw-complex-test"
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = var.tags
  zones               = ["1", "2", "3"]

  ip_configuration {
    name                 = "configuration"
    public_ip_address_id = azurerm_public_ip.firewall.id
    subnet_id            = azurerm_subnet.firewall.id
  }
  management_ip_configuration {
    name                 = "mgmt-configuration"
    public_ip_address_id = azurerm_public_ip.firewall_mgmt.id
    subnet_id            = azurerm_subnet.firewall_mgmt.id
  }
}

# Firewall policy with rules
resource "azurerm_firewall_policy" "this" {
  location            = azurerm_resource_group.hub.location
  name                = "fw-policy-complex"
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tags                = var.tags

  dns {
    proxy_enabled = true
  }
}

# Application rule collection for Container Apps
resource "azurerm_firewall_policy_rule_collection_group" "this" {
  firewall_policy_id = azurerm_firewall_policy.this.id
  name               = "ContainerAppsRules"
  priority           = 500

  application_rule_collection {
    action   = "Allow"
    name     = "ContainerAppsAllow"
    priority = 500

    rule {
      name              = "AllowContainerRegistry"
      destination_fqdns = ["*.azurecr.io", "*.microsoft.com", "*.azure.com"]
      source_addresses  = ["10.50.0.0/16"] # Spoke network

      protocols {
        port = 443
        type = "Https"
      }
    }
    rule {
      name              = "AllowPackageManagers"
      destination_fqdns = ["*.npmjs.org", "*.nuget.org", "*.pypi.org"]
      source_addresses  = ["10.50.0.0/16"]

      protocols {
        port = 443
        type = "Https"
      }
    }
  }
  network_rule_collection {
    action   = "Allow"
    name     = "ContainerAppsNetwork"
    priority = 400

    rule {
      destination_ports     = ["53"]
      name                  = "AllowDNS"
      protocols             = ["TCP", "UDP"]
      destination_addresses = ["168.63.129.16"] # Azure DNS
      source_addresses      = ["10.50.0.0/16"]
    }
  }
}

# UDR for spoke to route through firewall
resource "azurerm_route_table" "spoke" {
  location            = azurerm_resource_group.hub.location
  name                = "rt-spoke-via-fw"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags

  route {
    address_prefix         = "0.0.0.0/0"
    name                   = "DefaultRoute"
    next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
    next_hop_type          = "VirtualAppliance"
  }
  route {
    address_prefix = "0.0.0.0/0"
    name           = "InternetRoute"
    next_hop_type  = "Internet"
  }
}

# Most complex scenario: Network appliance with custom naming and all features
module "aca_lza_hosting" {
  source = "../../"

  # Application Gateway with self-signed certificate (COMPLEX)
  deployment_subnet_address_prefix = "10.50.4.0/24"
  # Full observability with custom configuration (COMPLEX)
  enable_application_insights = true
  enable_dapr_instrumentation = true
  # Core - custom named RG (COMPLEX)
  location                                      = var.location
  spoke_infra_subnet_address_prefix             = "10.50.1.0/24"
  spoke_private_endpoints_subnet_address_prefix = "10.50.2.0/24"
  # Large address space for complex scenarios
  spoke_vnet_address_prefixes = ["10.50.0.0/16"] # Large spoke
  created_resource_group_name = var.custom_resource_group_name
  # All features enabled (COMPLEX)
  deploy_sample_application = true
  # Zone redundancy for production-like setup (COMPLEX)
  deploy_zone_redundant_resources = true
  # DDoS protection for enterprise scenarios (COMPLEX - expensive)
  enable_ddos_protection     = var.enable_ddos_protection
  enable_telemetry           = var.enable_telemetry
  environment                = var.environment
  expose_container_apps_with = "applicationGateway"
  # Complex hub-spoke with network appliance (COMPLEX)
  hub_virtual_network_resource_id                 = azurerm_virtual_network.hub.id
  network_appliance_ip_address                    = azurerm_firewall.this.ip_configuration[0].private_ip_address
  route_spoke_traffic_internally                  = false # Force through hub appliance
  spoke_application_gateway_subnet_address_prefix = "10.50.3.0/24"
  # Premium storage for high performance (COMPLEX)
  storage_account_type             = "Premium_LRS"
  tags                             = var.tags
  use_existing_resource_group      = false
  vm_admin_password                = "NotUsedForSSH123!"
  vm_authentication_type           = "sshPublicKey"
  vm_jumpbox_os_type               = "linux"
  vm_jumpbox_subnet_address_prefix = "10.50.5.0/24"
  vm_linux_ssh_authorized_key      = tls_private_key.ssh_key.public_key_openssh
  # Linux VM with SSH for testing appliance connectivity (COMPLEX)
  vm_size                                     = "Standard_D4s_v3" # Larger VM for testing
  log_analytics_workspace_replication_enabled = false
  # Custom naming (COMPLEX)
  workload_name = var.workload_name

  depends_on = [
    azurerm_firewall.this,
    azurerm_firewall_policy_rule_collection_group.this
  ]
}

# Associate route table with spoke subnets after module deployment
resource "azurerm_subnet_route_table_association" "spoke_infra" {
  route_table_id = azurerm_route_table.spoke.id
  subnet_id      = "${module.aca_lza_hosting.spoke_virtual_network_id}/subnets/snet-spoke-infrastructure"
}








