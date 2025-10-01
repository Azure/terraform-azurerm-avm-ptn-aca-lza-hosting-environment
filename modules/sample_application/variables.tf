###############################################
# Variables                                   #
###############################################

variable "container_app_environment_resource_id" {
  type        = string
  description = "The resource ID of the existing Container Apps environment in which the Container App will be deployed."
}

variable "container_registry_user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity with ACR Pull permissions."
}

variable "location" {
  type        = string
  description = "Azure region for the Container App."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name where the Container App will be deployed."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable/Disable usage telemetry for the module."
}

variable "name" {
  type        = string
  default     = "ca-simple-hello"
  description = "Name of the sample Container App."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to the Container App."
}

variable "workload_profile_name" {
  type        = string
  default     = "general-purpose"
  description = "The workload profile name in the Container Apps environment to run the app on."
}
