variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "This variable controls whether or not telemetry is enabled for the module."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "The environment identifier for the module."

  validation {
    condition     = length(var.environment) <= 8
    error_message = "environment must be at most 8 characters."
  }
}

variable "location" {
  type        = string
  default     = "Sweden Central"
  description = "The Azure region where the resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aca-lza-minimal-test"
  description = "The name of the resource group to create."
}

variable "tags" {
  type = map(string)
  default = {
    environment = "test"
    purpose     = "minimal-config-testing"
  }
  description = "Map of tags to assign to the resources."
}

variable "workload_name" {
  type        = string
  default     = "min"
  description = "The name of the workload (minimum length to test validation)."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}
