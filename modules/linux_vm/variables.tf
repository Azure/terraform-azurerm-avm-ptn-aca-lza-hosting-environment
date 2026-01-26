variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "enable_telemetry" { type = bool }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "virtual_machine_size" { type = string }
variable "virtual_machine_zone" {
  type    = number
  default = 0
}
variable "storage_account_type" {
  type    = string
  default = "Standard_LRS"
}

variable "subnet_id" { type = string }

variable "network_interface_name" { type = string }

variable "virtual_machine_admin_password" {
  type        = string
  sensitive   = true
  default     = null
  description = "The admin password for the VM. Not required when virtual_machine_admin_password_generate is true. Note: This value will be stored in Terraform state - ensure your state backend is encrypted."
}

variable "virtual_machine_admin_password_generate" {
  type        = bool
  default     = false
  description = "When true, auto-generate the admin password and store in Key Vault. Requires key_vault_resource_id."
}

variable "key_vault_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of the Key Vault to store generated credentials. Required when virtual_machine_admin_password_generate is true."
}

variable "virtual_machine_ssh_key_generation_enabled" {
  type        = bool
  default     = false
  description = "Whether to auto-generate an SSH key"
}
variable "virtual_machine_linux_ssh_authorized_key" {
  type      = string
  sensitive = true
  default   = null
}
variable "virtual_machine_authentication_type" {
  type    = string
  default = "ssh_public_key"
}

variable "log_analytics_workspace_id" { type = string }
