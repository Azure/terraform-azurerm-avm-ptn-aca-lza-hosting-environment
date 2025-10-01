variable "custom_fqdn" {
  type        = string
  default     = "enterprise-aca.contoso.com"
  description = "Custom FQDN for the Application Gateway."
}

variable "custom_resource_group_name" {
  type        = string
  default     = "rg-aca-lza-enterprise-complex"
  description = "Custom name for the main resource group that the module will create."
}

variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Enable DDoS protection. WARNING: This is very expensive and should only be enabled for production or testing purposes."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "This variable controls whether or not telemetry is enabled for the module."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "The environment identifier for the module."

  validation {
    condition     = length(var.environment) <= 8
    error_message = "environment must be at most 8 characters."
  }
}

variable "location" {
  type        = string
  default     = "East US"
  description = "The Azure region where the resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aca-lza-complex"
  description = "The base name for resource groups."
}

variable "tags" {
  type = map(string)
  default = {
    environment = "production"
    workload    = "container-apps"
    complexity  = "high"
    purpose     = "enterprise-testing"
  }
  description = "Map of tags to assign to the resources."
}

variable "workload_name" {
  type        = string
  default     = "enterprise"
  description = "The name of the workload."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}
