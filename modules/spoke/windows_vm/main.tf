# Query the Bastion host to get its subnet ID when bastion access is enabled
data "azurerm_bastion_host" "this" {
  count = var.enable_bastion_access && var.bastion_resource_id != null ? 1 : 0

  name                = element(split("/", var.bastion_resource_id), length(split("/", var.bastion_resource_id)) - 1)
  resource_group_name = element(split("/", var.bastion_resource_id), index(split("/", var.bastion_resource_id), "resourceGroups") + 1)
}

# Query the Bastion subnet to get its address prefix
data "azurerm_subnet" "bastion" {
  count = var.enable_bastion_access && var.bastion_resource_id != null ? 1 : 0

  name                 = "AzureBastionSubnet"
  virtual_network_name = element(split("/", data.azurerm_bastion_host.this[0].ip_configuration[0].subnet_id), length(split("/", data.azurerm_bastion_host.this[0].ip_configuration[0].subnet_id)) - 3)
  resource_group_name  = element(split("/", data.azurerm_bastion_host.this[0].ip_configuration[0].subnet_id), index(split("/", data.azurerm_bastion_host.this[0].ip_configuration[0].subnet_id), "resourceGroups") + 1)
}

locals {
  # Get the Bastion subnet address prefix for NSG rules
  bastion_subnet_prefix = var.enable_bastion_access && var.bastion_resource_id != null ? data.azurerm_subnet.bastion[0].address_prefixes[0] : null
}

module "nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  name                = var.network_security_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags

  security_rules = var.enable_bastion_access && local.bastion_subnet_prefix != null ? {
    allow_bastion_inbound = {
      name                       = "allow-bastion-inbound"
      description                = "Allow inbound traffic from Bastion subnet to the JumpBox"
      protocol                   = "*"
      source_address_prefix      = local.bastion_subnet_prefix
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
      access                     = "Allow"
      priority                   = 100
      direction                  = "Inbound"
    }
  } : {}
}

# Associate NSG to subnet using azurerm resource for proper lifecycle management
# This ensures the association is properly removed before NSG deletion during terraform destroy
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = var.subnet_id
  network_security_group_id = module.nsg.resource_id
}

module "vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "~> 0.19"

  enable_telemetry    = var.enable_telemetry
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  name                = var.name
  sku_size            = var.vm_size
  zone                = var.vm_zone

  account_credentials = {
    admin_credentials = {
      username                           = "localAdministrator"
      password                           = var.vm_admin_password
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = false
  }

  network_interfaces = {
    nic1 = {
      name = var.network_interface_name
      ip_configurations = {
        ipconfig1 = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = var.subnet_id
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.vm_windows_os_version
    version   = "latest"
  }

  diagnostic_settings = {
    vm_diags = {
      name                  = "vm-diags"
      workspace_resource_id = var.log_analytics_workspace_id
      metric_categories     = ["AllMetrics"]
    }
  }
}
