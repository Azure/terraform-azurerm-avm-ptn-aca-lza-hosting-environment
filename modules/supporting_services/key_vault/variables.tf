variable "name" {
  description = "Key Vault name"
  type        = string
}
variable "location" {
  description = "Location"
  type        = string
}
variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "resource_group_id" {
  description = "Resource Group ID"
  type        = string
}
variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
variable "enable_telemetry" {
  description = "Enable telemetry (unused placeholder)"
  type        = bool
  default     = true
}
variable "spoke_vnet_resource_id" {
  description = "Spoke VNet ID"
  type        = string
}
variable "hub_peering_enabled" {
  description = "Whether hub peering is enabled"
  type        = bool
  default     = false
}
variable "hub_vnet_resource_id" {
  description = "Hub VNet ID. Required when hub_peering_enabled is true."
  type        = string
  default     = null
}
variable "private_endpoint_subnet_id" {
  description = "Private Endpoint Subnet ID"
  type        = string
}
variable "private_endpoint_name" {
  description = "Private Endpoint name"
  type        = string
}
variable "log_analytics_workspace_id" {
  description = "LAW id (optional)"
  type        = string
  default     = null
}

variable "enable_diagnostics" {
  description = "Enable diagnostics settings"
  type        = bool
  default     = true
}

variable "expose_container_apps_with" {
  type        = string
  default     = "application_gateway"
  description = "Ingress method: 'applicationGateway', 'frontDoor', or 'none'. Determines if Front Door CDN needs Key Vault access."
}
