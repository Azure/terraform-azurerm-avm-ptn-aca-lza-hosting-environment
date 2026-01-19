locals {
  # Compute SSH keys list to ensure type consistency
  # Convert to set then back to list to get consistent list(string) type
  ssh_keys_set  = !var.generate_ssh_key_for_vm && var.vm_linux_ssh_authorized_key != null ? toset([var.vm_linux_ssh_authorized_key]) : toset([])
  ssh_keys_list = tolist(local.ssh_keys_set)
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

  account_credentials = {
    admin_credentials = {
      username                           = "localAdministrator"
      generate_admin_password_or_ssh_key = var.generate_ssh_key_for_vm
      ssh_keys                           = local.ssh_keys_list
    }
    password_authentication_disabled = true
  }

  admin_ssh_keys = !var.generate_ssh_key_for_vm && var.vm_linux_ssh_authorized_key != null ? [{
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
