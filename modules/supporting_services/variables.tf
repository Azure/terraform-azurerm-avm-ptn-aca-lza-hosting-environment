variable "resources_names" {
  description = "Resource names map (from naming module)"
  type = object({
    resourceGroup                         = string
    containerRegistry                     = string
    containerRegistryPep                  = string
    containerRegistryUserAssignedIdentity = string
    keyVault                              = string
    keyVaultPep                           = string
    storageAccount                        = string
  })
}

variable "resource_group_name" {
  description = "Resource Group name where supporting services will be created"
  type        = string
}

variable "resource_group_id" {
  description = "Resource Group ID where supporting services will be created"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Enable deployment telemetry"
  type        = bool
}

variable "hub_vnet_resource_id" {
  description = "Hub VNet resource ID (optional)"
  type        = string
  default     = ""
}

variable "spoke_vnet_resource_id" {
  description = "Spoke VNet resource ID"
  type        = string
}

variable "spoke_private_endpoint_subnet_resource_id" {
  description = "Spoke Private Endpoint subnet ID"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID (optional)"
  type        = string
  default     = ""
}

variable "enable_diagnostics" {
  description = "Enable diagnostics settings for supporting services"
  type        = bool
  default     = true
}

variable "deploy_zone_redundant_resources" {
  description = "If true, use AZ-enabled SKUs where supported"
  type        = bool
  default     = true
}

variable "deploy_agent_pool" {
  description = "Deploy ACR agent pool"
  type        = bool
  default     = true
}
