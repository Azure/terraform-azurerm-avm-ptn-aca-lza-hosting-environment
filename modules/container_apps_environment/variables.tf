variable "name" {
  description = "Name of the Container Apps Managed Environment."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the managed environment and DNS zone."
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID for the managed environment and DNS zone."
  type        = string
}

variable "location" {
  description = "Azure region for resources."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Enable or disable AVM telemetry."
  type        = bool
  default     = true
}

variable "hub_virtual_network_id" {
  description = "Optional hub VNet resource ID to link to the private DNS zone. Empty to skip."
  type        = string
  default     = ""
}

variable "spoke_virtual_network_id" {
  description = "Spoke VNet resource ID to link to the private DNS zone."
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for ACA environment integration (delegated to Microsoft.App/environments)."
  type        = string
}

variable "enable_application_insights" {
  description = "Whether to deploy Application Insights and link to LAW."
  type        = bool
  default     = true
}

variable "enable_dapr_instrumentation" {
  description = "Enable Dapr instrumentation using Application Insights (requires enable_application_insights)."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of an existing Log Analytics Workspace."
  type        = string
}

variable "log_analytics_workspace_customer_id" {
  description = "Customer ID (workspace ID) of the Log Analytics Workspace."
  type        = string
}

variable "container_apps_environment_storages" {
  description = "Additional storage mounts for the ACA environment. Keys are logical names."
  type = map(object({
    access_mode  = string
    kind         = string
    share_name   = string
    account_name = string
    access_key   = string
  }))
  default   = {}
  sensitive = true
}

variable "deploy_zone_redundant_resources" {
  description = "If true, deploy zone-redundant resources (ACA env)."
  type        = bool
  default     = true
}

variable "container_registry_user_assigned_identity_id" {
  description = "Resource ID of the user-assigned identity used by ACA to pull from ACR."
  type        = string
}
