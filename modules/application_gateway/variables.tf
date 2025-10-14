###############################################
# Application Gateway module: variables       #
###############################################

variable "location" {
  type        = string
  description = "Required. Azure region for resources."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Required. Application Gateway name."
}

variable "public_ip_name" {
  type        = string
  description = "Required. Name of the Public IP to create for the Application Gateway frontend."
}

variable "resource_group_name" {
  type        = string
  description = "Required. Resource group name to deploy resources into."
}

variable "subnet_id" {
  type        = string
  description = "Required. Subnet ID for the Application Gateway."
}

variable "backend_fqdn" {
  type        = string
  default     = ""
  description = "Optional. Backend FQDN to route traffic to (e.g., your Container App or internal endpoint)."
}

variable "backend_probe_path" {
  type        = string
  default     = "/"
  description = "Optional. Path for backend health probe."
}

variable "deploy_zone_redundant_resources" {
  type        = bool
  default     = true
  description = "Optional. When true, deploy zone-redundant resources (zones 1,2,3 where supported)."
}

variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Optional. Enable DDoS protection on the Public IP."
}

variable "enable_diagnostics" {
  type        = bool
  default     = true
  description = "Enable diagnostics settings"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Optional. Enable module telemetry."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = ""
  description = "Optional. Log Analytics Workspace ID for diagnostics."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional. Tags to apply."
}
