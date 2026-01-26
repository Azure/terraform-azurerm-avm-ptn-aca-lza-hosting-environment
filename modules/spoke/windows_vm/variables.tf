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
  description = "The admin password for the VM."
}

variable "vm_windows_os_version" {
  type    = string
  default = "2016-Datacenter"
}

variable "log_analytics_workspace_id" { type = string }
