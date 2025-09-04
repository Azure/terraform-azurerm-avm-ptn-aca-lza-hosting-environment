variable "name" {
  description = "ACR name"
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
  description = "Enable telemetry"
  type        = bool
  default     = true
}

variable "spoke_vnet_resource_id" {
  description = "Spoke VNet ID"
  type        = string
}

variable "hub_vnet_resource_id" {
  description = "Hub VNet ID"
  type        = string
  default     = ""
}

variable "private_endpoint_subnet_id" {
  description = "Private Endpoint Subnet ID"
  type        = string
}

variable "private_endpoint_name" {
  description = "Private Endpoint name"
  type        = string
}

variable "user_assigned_identity_name" {
  description = "UAI name"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "LAW id (optional)"
  type        = string
  default     = ""
}

variable "enable_diagnostics" {
  description = "Enable diagnostics settings"
  type        = bool
  default     = true
}

variable "zone_redundant_enabled" {
  description = "Enable zone redundancy"
  type        = bool
  default     = true
}

variable "deploy_agent_pool" {
  description = "Deploy ACR agent pool"
  type        = bool
  default     = true
}
