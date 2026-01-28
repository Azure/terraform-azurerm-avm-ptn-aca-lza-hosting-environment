locals {
  # Determine the actual password to use (only relevant for password auth)
  # If generating, use the generated password; otherwise use the provided password
  effective_password = var.virtual_machine_admin_password_generate ? random_password.admin[0].result : var.virtual_machine_admin_password
  ssh_keys_list      = tolist(local.ssh_keys_set)
  # Compute SSH keys list to ensure type consistency
  # Convert to set then back to list to get consistent list(string) type
  ssh_keys_set = !var.virtual_machine_ssh_key_generation_enabled && var.virtual_machine_linux_ssh_authorized_key != null ? toset([var.virtual_machine_linux_ssh_authorized_key]) : toset([])
  # Determine if we're using SSH authentication
  use_ssh_auth = var.virtual_machine_authentication_type == "ssh_public_key"
}

# Generate password if requested (count is based on boolean, known at plan time)
resource "random_password" "admin" {
  count = var.virtual_machine_admin_password_generate ? 1 : 0

  length           = 24
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!@#$%&*()-_=+[]{}|;:,.<>?"
  special          = true
}

# Store password in Key Vault (only when using password auth, not SSH)
# Uses azurerm_key_vault_secret as it handles soft-delete lifecycle properly
resource "azurerm_key_vault_secret" "admin_password" {
  count = !local.use_ssh_auth ? 1 : 0

  key_vault_id = var.key_vault_resource_id
  name         = "${var.name}-admin-password"
  content_type = "text/plain"
  tags         = var.tags
  value        = local.effective_password

  lifecycle {
    ignore_changes = [value]
  }
}

module "vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.0"

  location = var.location
  name     = var.name
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
  resource_group_name = var.resource_group_name
  zone                = var.virtual_machine_zone
  account_credentials = {
    admin_credentials = {
      username = "localAdministrator"
      # Only generate SSH key when using SSH auth and key generation is enabled
      generate_admin_password_or_ssh_key = local.use_ssh_auth && var.virtual_machine_ssh_key_generation_enabled
      ssh_keys                           = local.ssh_keys_list
      # Only pass password when using password authentication
      password = local.use_ssh_auth ? null : local.effective_password
    }
    password_authentication_disabled = local.use_ssh_auth
  }
  admin_ssh_keys = !var.virtual_machine_ssh_key_generation_enabled && var.virtual_machine_linux_ssh_authorized_key != null ? [{
    username   = "localAdministrator"
    public_key = var.virtual_machine_linux_ssh_authorized_key
  }] : []
  diagnostic_settings = {
    vm_diags = {
      name                  = "vm-diags"
      workspace_resource_id = var.log_analytics_workspace_id
      metric_categories     = ["AllMetrics"]
    }
  }
  enable_telemetry = var.enable_telemetry
  # Disable encryption at host as it requires subscription feature registration
  encryption_at_host_enabled = false
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }
  os_type  = "Linux"
  sku_size = var.virtual_machine_size
  # Minimal image reference matching Bicep
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
