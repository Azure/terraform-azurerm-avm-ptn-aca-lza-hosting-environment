###############################################
# Naming module variables                     #
###############################################

variable "environment" {
  type        = string
  description = "The name of the environment (e.g. \"dev\", \"test\", \"prod\", \"uat\", \"dr\", \"qa\") Up to 8 characters long."

  validation {
    condition     = length(var.environment) <= 8
    error_message = "environment must be at most 8 characters."
  }
}

variable "location" {
  type        = string
  description = "Location for all Resources."
}

variable "unique_id" {
  type        = string
  description = "a unique ID that can be appended (or prepended) in azure resource names that require some kind of uniqueness"
}

variable "workload_name" {
  type        = string
  description = "The name of the workload that is being deployed. Up to 10 characters long."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}

variable "spoke_resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the resource group where the resources will be deployed."
}
