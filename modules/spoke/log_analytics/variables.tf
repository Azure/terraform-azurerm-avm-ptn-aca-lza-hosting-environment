###############################################
# Log Analytics submodule (AzAPI) inputs     #
###############################################

variable "name" {
  type        = string
  description = "Required. Log Analytics Workspace name."
}

variable "location" {
  type        = string
  description = "Required. Azure location."
}

variable "resource_group_id" {
  type        = string
  description = "Required. Resource group ID."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional. Tags to apply."
}

variable "retention_in_days" {
  type        = number
  default     = 30
  description = "Optional. Retention in days (30-730)."
  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "sku" {
  type        = string
  default     = "PerGB2018"
  description = "Optional. Pricing SKU."
}

variable "replication_enabled" {
  type        = bool
  default     = true
  description = "Optional. Enable cross-region replication as in Bicep."
}

variable "replication_location" {
  type        = string
  default     = null
  description = "Optional. Secondary region for replication. If null, calculated from location map to mirror Bicep."
}
