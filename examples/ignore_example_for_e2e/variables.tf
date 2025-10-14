variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "environment" {
  type        = string
  default     = "test"
  description = "The environment identifier for the module."
}

variable "location" {
  type        = string
  default     = "East US"
  description = "The Azure region where the resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aca-lza-ignore-test"
  description = "The name of the resource group to create."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to assign to the resources."
}

variable "workload_name" {
  type        = string
  default     = "ignoretest"
  description = "The name of the workload."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}
