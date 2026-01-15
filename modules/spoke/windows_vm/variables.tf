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

variable "bastion_subnet_address_prefix" {
  type        = string
  default     = null
  description = "The CIDR address prefix of the bastion subnet. Required when enable_bastion_access is true."
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

variable "vm_windows_os_version" {
  type    = string
  default = "2016-Datacenter"
}

variable "log_analytics_workspace_id" { type = string }
