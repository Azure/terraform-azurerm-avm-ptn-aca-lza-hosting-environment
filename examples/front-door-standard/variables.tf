variable "certificate_key_name" {
  type        = string
  default     = "app-contoso-com-cert"
  description = "The name of the certificate key in Key Vault for Front Door TLS termination."
}

variable "deploy_zone_redundant_resources" {
  type        = bool
  default     = true
  description = "Enable zone redundant resources where supported."
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

variable "front_door_fqdn" {
  type        = string
  default     = "app.contoso.com"
  description = "The custom domain FQDN for the Front Door endpoint."
}

variable "location" {
  type        = string
  default     = "East US"
  description = "The Azure region where the resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aca-lza-front-door-test"
  description = "The name of the resource group to create."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to assign to the resources."
}

variable "workload_name" {
  type        = string
  default     = "frontdoor"
  description = "The name of the workload."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}
