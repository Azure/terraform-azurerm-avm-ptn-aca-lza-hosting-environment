variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Enable DDoS protection. WARNING: This is expensive and should only be enabled for testing purposes."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "This variable controls whether or not telemetry is enabled for the module."
}

variable "environment" {
  type        = string
  default     = "test"
  description = "The environment identifier for the module."
}

variable "location" {
  type        = string
  default     = "UK South"
  description = "The Azure region where the resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aca-lza-bastion-test"
  description = "The name of the resource group to create."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to assign to the resources."
}

variable "workload_name" {
  type        = string
  default     = "bastion"
  description = "The name of the workload."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}
