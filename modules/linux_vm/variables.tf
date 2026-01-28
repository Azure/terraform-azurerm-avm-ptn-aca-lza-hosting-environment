variable "enable_telemetry" {
  type        = bool
  description = "Whether to enable telemetry for the module."
}

variable "location" {
  type        = string
  description = "The Azure region where the VM will be deployed."
  nullable    = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics workspace for VM diagnostics."
}

variable "name" {
  type        = string
  description = "The name of the virtual machine."
}

variable "network_interface_name" {
  type        = string
  description = "The name of the network interface for the VM."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the VM."
}

variable "subnet_id" {
  type        = string
  description = "The resource ID of the subnet for the VM's network interface."
}

variable "virtual_machine_size" {
  type        = string
  description = "The size of the virtual machine."
}

variable "key_vault_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of the Key Vault to store generated credentials. Required when virtual_machine_admin_password_generate is true."
}

variable "storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "The type of storage account for the OS disk."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A map of tags to apply to the resources."
}

variable "virtual_machine_admin_password" {
  type        = string
  default     = null
  description = "The admin password for the VM. Not required when virtual_machine_admin_password_generate is true. Note: This value will be stored in Terraform state - ensure your state backend is encrypted."
  sensitive   = true
}

variable "virtual_machine_admin_password_generate" {
  type        = bool
  default     = false
  description = "When true, auto-generate the admin password and store in Key Vault. Requires key_vault_resource_id."
}

variable "virtual_machine_authentication_type" {
  type        = string
  default     = "ssh_public_key"
  description = "The authentication type for the VM. Allowed values: 'ssh_public_key' or 'password'."
}

variable "virtual_machine_linux_ssh_authorized_key" {
  type        = string
  default     = null
  description = "The SSH public key for the Linux VM administrator."
  sensitive   = true
}

variable "virtual_machine_ssh_key_generation_enabled" {
  type        = bool
  default     = false
  description = "Whether to auto-generate an SSH key for the VM."
}

variable "virtual_machine_zone" {
  type        = number
  default     = 0
  description = "The availability zone for the virtual machine (0 for no zone)."
}
