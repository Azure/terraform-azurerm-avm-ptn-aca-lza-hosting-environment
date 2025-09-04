###############################################
# Application Gateway module: variables       #
###############################################

variable "name" {
  description = "Required. Application Gateway name."
  type        = string
}

variable "resource_group_name" {
  description = "Required. Resource group name to deploy resources into."
  type        = string
}

variable "location" {
  description = "Required. Azure region for resources."
  type        = string
}

variable "tags" {
  description = "Optional. Tags to apply."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Optional. Enable module telemetry."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Required. Subnet ID for the Application Gateway."
  type        = string
}

variable "public_ip_name" {
  description = "Required. Name of the Public IP to create for the Application Gateway frontend."
  type        = string
}

variable "user_assigned_identity_name" {
  description = "Required. Name of the User Assigned Identity used by Application Gateway to read Key Vault secrets."
  type        = string
}

variable "application_gateway_fqdn" {
  description = "Optional. The FQDN of the Application Gateway (must match TLS cert if provided)."
  type        = string
  default     = ""
}

variable "backend_fqdn" {
  description = "Optional. Backend FQDN to route traffic to (e.g., your Container App or internal endpoint)."
  type        = string
  default     = ""
}

variable "backend_probe_path" {
  description = "Optional. Path for backend health probe."
  type        = string
  default     = "/"
}

variable "base64_certificate" {
  description = "Optional. Base64-encoded PFX certificate to store in Key Vault and attach to the listener."
  type        = string
  default     = ""
  sensitive   = true
}

variable "certificate_key_name" {
  description = "Required. Key Vault secret/certificate name to use."
  type        = string
}

variable "key_vault_id" {
  description = "Required. Resource ID of the Key Vault holding/receiving the TLS certificate."
  type        = string
  validation {
    condition     = length(trimspace(coalesce(var.key_vault_id, ""))) > 0
    error_message = "key_vault_id must be a non-empty Key Vault resource ID. Pass the Key Vault ID from the supporting services module output."
  }
}

variable "log_analytics_workspace_id" {
  description = "Optional. Log Analytics Workspace ID for diagnostics."
  type        = string
  default     = ""
}

variable "enable_diagnostics" {
  description = "Enable diagnostics settings"
  type        = bool
  default     = true
}

variable "deploy_zone_redundant_resources" {
  description = "Optional. When true, deploy zone-redundant resources (zones 1,2,3 where supported)."
  type        = bool
  default     = true
}

variable "enable_ddos_protection" {
  description = "Optional. Enable DDoS protection on the Public IP."
  type        = bool
  default     = false
}

variable "storage_account_name" {
  description = "Required. Name of the storage account where the deployment script will be stored."
  type        = string
}

variable "deployment_subnet_id" {
  description = "Required. The subnet resource ID where the deployment script container will be deployed."
  type        = string
}

variable "certificate_subject_name" {
  description = "Optional. The certificate subject name for self-signed certificates."
  type        = string
  default     = "CN=contoso.com"
}
