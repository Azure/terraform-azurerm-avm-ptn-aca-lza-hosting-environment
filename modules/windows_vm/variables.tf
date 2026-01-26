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

variable "vm_windows_os_version" {
  type    = string
  default = "2016-Datacenter"
}

variable "log_analytics_workspace_id" { type = string }
