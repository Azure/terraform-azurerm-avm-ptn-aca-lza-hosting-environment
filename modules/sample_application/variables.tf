###############################################
# Variables                                   #
###############################################

variable "name" {
  description = "Name of the sample Container App."
  type        = string
  default     = "ca-simple-hello"
}

variable "resource_group_name" {
  description = "Resource group name where the Container App will be deployed."
  type        = string
}

variable "location" {
  description = "Azure region for the Container App."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Container App."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Enable/Disable usage telemetry for the module."
  type        = bool
  default     = true
}

variable "container_app_environment_resource_id" {
  description = "The resource ID of the existing Container Apps environment in which the Container App will be deployed."
  type        = string
}

variable "workload_profile_name" {
  description = "The workload profile name in the Container Apps environment to run the app on."
  type        = string
  default     = "general-purpose"
}

variable "container_registry_user_assigned_identity_id" {
  description = "Resource ID of the user-assigned managed identity with ACR Pull permissions."
  type        = string
}
