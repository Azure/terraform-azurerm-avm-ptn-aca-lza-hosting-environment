module "nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  name                = var.network_security_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags

  security_rules = length(var.bastion_resource_id) > 0 ? {
    allow_bastion_inbound = {
      name                       = "allow-bastion-inbound"
      description                = "Allow inbound traffic from Bastion to the JumpBox"
      protocol                   = "*"
      source_address_prefix      = "Bastion"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
      access                     = "Allow"
      priority                   = 100
      direction                  = "Inbound"
    }
  } : {}
}

# Associate NSG to subnet using AzAPI - migrated for AVM v1.0 compliance
resource "azapi_update_resource" "nsg_association" {
  type        = "Microsoft.Network/virtualNetworks/subnets@2024-01-01"
  resource_id = var.subnet_id

  body = {
    properties = {
      networkSecurityGroup = {
        id = module.nsg.resource_id
      }
    }
  }
}

module "vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "~> 0.19"

  enable_telemetry    = var.enable_telemetry
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  name                = var.name
  sku_size            = var.vm_size
  zone                = var.vm_zone

  account_credentials = var.vm_authentication_type == "sshPublicKey" ? {
    admin_credentials = {
      username                           = "localAdministrator"
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = true
    } : {
    admin_credentials = {
      username                           = "localAdministrator"
      password                           = var.vm_admin_password
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = false
  }

  admin_ssh_keys = var.vm_authentication_type == "sshPublicKey" ? [{
    username   = "localAdministrator"
    public_key = var.vm_linux_ssh_authorized_key
  }] : []

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

  # Minimal image reference matching Bicep
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
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
