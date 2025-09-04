variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the resources will be created."
}

variable "tags" {
  type        = map(string)
  description = "Optional. The tags to be assigned to the created resources."
  default     = {}
}

variable "resource_prefix" {
  type        = string
  description = "A unique prefix used for generating resource names."
}

variable "key_vault_id" {
  type        = string
  description = "The resource ID of the existing Key Vault which will contain the certificate."
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account where the deployment script will be stored."
}

variable "deployment_subnet_id" {
  type        = string
  description = "The subnet resource ID of the subnet where the deployment script container will be deployed."
}

variable "app_gateway_principal_id" {
  type        = string
  description = "The application gateway managed identity principal ID that needs access to key vault to read the certificate."
}

variable "certificate_key_name" {
  type        = string
  description = "The certificate key name to be used in the key vault."
}

variable "certificate_subject_name" {
  type        = string
  description = "The certificate subject name for self-signed certificates."
  default     = "CN=contoso.com"
}

variable "base64_certificate" {
  type        = string
  description = "The certificate data to be stored in the key vault. If not provided or empty, a self-signed certificate will be generated."
  default     = ""
  sensitive   = true
}
