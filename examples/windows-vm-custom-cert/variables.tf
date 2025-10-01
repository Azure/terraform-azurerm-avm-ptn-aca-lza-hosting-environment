variable "certificate_common_name" {
  type        = string
  default     = "wintest.contoso.com"
  description = "The common name for the custom certificate."
}

variable "certificate_key_name" {
  type        = string
  default     = "wintest-custom-cert"
  description = "The name of the certificate key in Key Vault."
}

variable "certificate_password" {
  type        = string
  default     = "CertP@ssw0rd123!"
  description = "The password for the certificate private key."
  sensitive   = true
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
  default     = "East US"
  description = "The Azure region where the resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aca-lza-windows-test"
  description = "The name of the resource group to create."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to assign to the resources."
}

variable "vm_admin_password" {
  type        = string
  default     = "WindowsP@ssw0rd123!"
  description = "The password for the Windows VM administrator account."
  sensitive   = true

  validation {
    condition     = length(var.vm_admin_password) >= 12
    error_message = "vm_admin_password must be at least 12 characters long."
  }
}

variable "workload_name" {
  type        = string
  default     = "wintest"
  description = "The name of the workload."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}
