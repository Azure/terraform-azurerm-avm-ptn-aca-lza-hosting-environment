variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  description = "Azure region for the example resource group."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the example resource group."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources in the example."
}

variable "workload_name" {
  type        = string
  default     = "aca-lza"
  description = "Workload token for naming."
}

variable "environment" {
  type        = string
  default     = "test"
  description = "Environment token for naming."
}
