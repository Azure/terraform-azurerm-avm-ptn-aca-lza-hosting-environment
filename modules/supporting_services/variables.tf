variable "enable_telemetry" {
  type        = bool
  description = "Enable deployment telemetry"
}

variable "location" {
  type        = string
  description = "Azure location"
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "Resource Group ID where supporting services will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group name where supporting services will be created"
}

variable "resources_names" {
  type = object({
    resourceGroup                         = string
    containerRegistry                     = string
    containerRegistryPep                  = string
    containerRegistryUserAssignedIdentity = string
    keyVault                              = string
    keyVaultPep                           = string
    storageAccount                        = string
  })
  description = "Resource names map (from naming module)"
}

variable "spoke_private_endpoint_subnet_resource_id" {
  type        = string
  description = "Spoke Private Endpoint subnet ID"
}

variable "spoke_vnet_resource_id" {
  type        = string
  description = "Spoke VNet resource ID"
}

variable "deploy_zone_redundant_resources" {
  type        = bool
  default     = true
  description = "If true, use AZ-enabled SKUs where supported"
}

variable "enable_diagnostics" {
  type        = bool
  default     = true
  description = "Enable diagnostics settings for supporting services"
}

variable "expose_container_apps_with" {
  type        = string
  default     = "applicationGateway"
  description = "Ingress method: 'applicationGateway', 'frontDoor', or 'none'"
}

variable "hub_vnet_resource_id" {
  type        = string
  default     = ""
  description = "Hub VNet resource ID (optional)"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = ""
  description = "Log Analytics Workspace resource ID (optional)"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply"
}
