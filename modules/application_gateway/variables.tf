###############################################
# Application Gateway module: variables       #
###############################################

variable "certificate_key_name" {
  type        = string
  description = "Required. Key Vault secret/certificate name to use."
}

variable "deployment_subnet_id" {
  type        = string
  description = "Required. The subnet resource ID where the deployment script container will be deployed."
}

variable "key_vault_id" {
  type        = string
  description = "Required. Resource ID of the Key Vault holding/receiving the TLS certificate."

  validation {
    condition     = length(trimspace(coalesce(var.key_vault_id, ""))) > 0
    error_message = "key_vault_id must be a non-empty Key Vault resource ID. Pass the Key Vault ID from the supporting services module output."
  }
}

variable "location" {
  type        = string
  description = "Required. Azure region for resources."
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

variable "storage_account_name" {
  type        = string
  description = "Required. Name of the storage account where the deployment script will be stored."
}

variable "subnet_id" {
  type        = string
  description = "Required. Subnet ID for the Application Gateway."
}

variable "user_assigned_identity_name" {
  type        = string
  description = "Required. Name of the User Assigned Identity used by Application Gateway to read Key Vault secrets."
}

variable "application_gateway_fqdn" {
  type        = string
  default     = ""
  description = "Optional. The FQDN of the Application Gateway (must match TLS cert if provided)."
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

variable "base64_certificate" {
  type        = string
  default     = ""
  description = "Optional. Base64-encoded PFX certificate to store in Key Vault and attach to the listener."
  sensitive   = true
}

variable "certificate_subject_name" {
  type        = string
  default     = "CN=contoso.com"
  description = "Optional. The certificate subject name for self-signed certificates."
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
  default     = {}
  description = "Optional. Tags to apply."
}
