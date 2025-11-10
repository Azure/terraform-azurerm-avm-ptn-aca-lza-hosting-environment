variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "enable_telemetry" { type = bool }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "vm_size" { type = string }
variable "vm_zone" {
  type    = number
  default = 0
}
variable "storage_account_type" {
  type    = string
  default = "Standard_LRS"
}

variable "subnet_id" { type = string }

variable "network_interface_name" { type = string }
variable "network_security_group_name" { type = string }

variable "bastion_resource_id" {
  type    = string
  default = null
}

variable "enable_bastion_access" {
  type        = bool
  default     = false
  description = "Whether to enable bastion access rule in the NSG. Set to true when using a bastion host."
}

variable "vm_admin_password" {
  type      = string
  sensitive = true
}
variable "generate_ssh_key_for_vm" {
  type        = bool
  default     = false
  description = "Whether to auto-generate an SSH key"
}
variable "vm_linux_ssh_authorized_key" {
  type      = string
  sensitive = true
  default   = null
}
variable "vm_authentication_type" {
  type    = string
  default = "password"
}

variable "log_analytics_workspace_id" { type = string }
