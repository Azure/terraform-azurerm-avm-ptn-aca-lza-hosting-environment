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

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
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
