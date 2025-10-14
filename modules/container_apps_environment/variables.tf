variable "container_registry_user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned identity used by ACA to pull from ACR."
}

variable "infrastructure_subnet_id" {
  type        = string
  description = "Subnet ID for ACA environment integration (delegated to Microsoft.App/environments)."
}

variable "location" {
  type        = string
  description = "Azure region for resources."
}

variable "log_analytics_workspace_customer_id" {
  type        = string
  description = "Customer ID (workspace ID) of the Log Analytics Workspace."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of an existing Log Analytics Workspace."
}

variable "name" {
  type        = string
  description = "Name of the Container Apps Managed Environment."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID for the managed environment and DNS zone."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for the managed environment and DNS zone."
}

variable "spoke_virtual_network_id" {
  type        = string
  description = "Spoke VNet resource ID to link to the private DNS zone."
}

variable "auto_approve_private_endpoint_connections" {
  type        = bool
  default     = false
  description = "Whether to automatically approve pending private endpoint connections to the Container Apps Environment (e.g., from Front Door). Set to true when using Front Door with Private Link."
}

variable "container_apps_environment_storages" {
  type = map(object({
    access_mode  = string
    kind         = string
    share_name   = string
    account_name = string
    access_key   = string
  }))
  default     = {}
  description = "Additional storage mounts for the ACA environment. Keys are logical names."
  sensitive   = true
}

variable "deploy_zone_redundant_resources" {
  type        = bool
  default     = true
  description = "If true, deploy zone-redundant resources (ACA env)."
}

variable "enable_application_insights" {
  type        = bool
  default     = true
  description = "Whether to deploy Application Insights and link to LAW."
}

variable "enable_dapr_instrumentation" {
  type        = bool
  default     = false
  description = "Enable Dapr instrumentation using Application Insights (requires enable_application_insights)."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable or disable AVM telemetry."
}

variable "hub_virtual_network_id" {
  type        = string
  default     = ""
  description = "Optional hub VNet resource ID to link to the private DNS zone. Empty to skip."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources."
}
