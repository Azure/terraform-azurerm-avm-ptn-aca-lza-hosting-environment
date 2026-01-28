###############################################
# Front Door module: variables               #
###############################################

variable "location" {
  type        = string
  description = "Required. Azure region for resources."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Required. Front Door profile name."
}

variable "resource_group_name" {
  type        = string
  description = "Required. Resource group name to deploy resources into."
}

variable "backend_fqdn" {
  type        = string
  default     = null
  description = "Optional. The backend FQDN that Front Door will route traffic to (Container App FQDN, not the environment). If not provided, no origin or route will be created."
}

variable "backend_port" {
  type        = number
  default     = 443
  description = "Optional. Port for backend communication."

  validation {
    condition     = var.backend_port > 0 && var.backend_port <= 65535
    error_message = "backend_port must be between 1 and 65535."
  }
}

variable "backend_probe_path" {
  type        = string
  default     = "/"
  description = "Optional. Health probe path for backend health checks."
}

variable "backend_protocol" {
  type        = string
  default     = "Https"
  description = "Optional. Protocol for backend communication."

  validation {
    condition     = contains(["Http", "Https"], var.backend_protocol)
    error_message = "backend_protocol must be either Http or Https."
  }
}

variable "caching_enabled" {
  type        = bool
  default     = true
  description = "Optional. Enable caching for the route."
}

variable "container_apps_environment_id" {
  type        = string
  default     = null
  description = "Optional. The resource ID of the Container Apps Environment for private link integration. This is used as the private link target. Required if enable_backend is true."
}

variable "enable_backend" {
  type        = bool
  default     = false
  description = "Optional. Enable backend origin and route creation. Set to true when a Container App backend is available."
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

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Optional. Enable Web Application Firewall. Requires Premium SKU."
}

variable "forwarding_protocol" {
  type        = string
  default     = "MatchRequest"
  description = "Optional. Protocol to use when forwarding traffic to backends."

  validation {
    condition     = contains(["HttpOnly", "HttpsOnly", "MatchRequest"], var.forwarding_protocol)
    error_message = "forwarding_protocol must be one of: HttpOnly, HttpsOnly, MatchRequest."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Optional. Log Analytics workspace ID for diagnostic settings. Required if enable_diagnostics is true."

  validation {
    condition     = !var.enable_diagnostics || (var.enable_diagnostics && var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "")
    error_message = "log_analytics_workspace_id must be provided when enable_diagnostics is true."
  }
}

variable "sku_name" {
  type        = string
  default     = "Standard_AzureFrontDoor"
  description = "Optional. SKU name for the Front Door profile. Options: Standard_AzureFrontDoor, Premium_AzureFrontDoor."

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be either Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional. Tags to apply."
}

variable "waf_policy_name" {
  type        = string
  default     = null
  description = "Optional. Name of the WAF policy. Required if enable_waf is true."
}
