variable "deploy_acr" {
  type        = bool
  default     = true
  description = "Optional. Whether to deploy a new Azure Container Registry. Set to false to skip ACR creation or to use an existing ACR via existing_acr_id. Default is true."
  nullable    = false
}

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

variable "enable_diagnostics" {
  type        = bool
  default     = true
  description = "Enable diagnostics settings for supporting services"
}

variable "existing_acr_id" {
  type        = string
  default     = null
  description = "Optional. The resource ID of an existing Azure Container Registry to use when deploy_acr is false. When provided, a user-assigned identity with AcrPull permissions and a private endpoint will be configured for the existing ACR. Default is null."

  validation {
    condition     = var.existing_acr_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ContainerRegistry/registries/[^/]+$", var.existing_acr_id))
    error_message = "existing_acr_id must be a valid Azure Container Registry resource ID."
  }
}

variable "hub_peering_enabled" {
  type        = bool
  default     = false
  description = "Whether hub peering is enabled. Used to determine if hub VNet link should be created."
  nullable    = false
}

variable "hub_vnet_resource_id" {
  type        = string
  default     = null
  description = "Hub VNet resource ID. Required when hub_peering_enabled is true."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log Analytics Workspace resource ID (optional)"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply"
}

variable "zone_redundant_resources_enabled" {
  type        = bool
  default     = true
  description = "If true, use AZ-enabled SKUs where supported"
}
