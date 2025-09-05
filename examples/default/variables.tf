
variable "location" {
  type        = string
  default     = "uksouth"
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aca-lza-example"
  description = "Resource group name"
}

variable "workload_name" {
  type        = string
  default     = "aca-lz"
  description = "Workload short name"
}

variable "environment" {
  type        = string
  default     = "test"
  description = "Environment short name"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable module telemetry"
}

variable "tags" {
  type        = map(string)
  default     = { env = "test", purpose = "example" }
  description = "Tags"
}
