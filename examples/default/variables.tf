variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable module telemetry"
}

variable "environment" {
  type        = string
  default     = "test"
  description = "Environment short name"
}

variable "location" {
  type        = string
  default     = "EastUS"
  description = "Azure region"
}

variable "tags" {
  type        = map(string)
  default     = { env = "test", purpose = "example" }
  description = "Tags"
}

variable "workload_name" {
  type        = string
  default     = "aca-lz"
  description = "Workload short name"
}
