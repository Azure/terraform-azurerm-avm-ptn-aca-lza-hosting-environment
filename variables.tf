###############################################
# Stage 0: Variables mirroring Bicep inputs  #
###############################################

# General
variable "location" {
  type        = string
  description = "Optional. The location of the Azure Container Apps deployment."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional. Tags related to the Azure Container Apps deployment. Default is empty."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Optional. Enable/Disable usage telemetry for module."
}

# Naming/Env
variable "workload_name" {
  type        = string
  default     = "aca-lza"
  description = "Optional. The name of the workload that is being deployed. Up to 10 characters long."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}

variable "environment" {
  type        = string
  default     = "test"
  description = "Optional. The name of the environment (e.g. \"dev\", \"test\", \"prod\", \"uat\", \"dr\", \"qa\"). Up to 8 characters long. Default is \"test\"."

  validation {
    condition     = length(var.environment) <= 8
    error_message = "environment must be at most 8 characters."
  }
}

# Hub/Spoke integration
variable "hub_virtual_network_resource_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of the hub virtual network. If set, the spoke virtual network will be peered with the hub virtual network. Default is empty."
}

variable "bastion_resource_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of the bastion host. If set, the spoke virtual network will be peered with the hub virtual network and the bastion host will be allowed to connect to the jump box. Default is empty."
}

variable "network_appliance_ip_address" {
  type        = string
  default     = ""
  description = "Optional. If set, the spoke virtual network will be peered with the hub virtual network and egress traffic will be routed through the network appliance. Default is empty."
}

variable "route_spoke_traffic_internally" {
  type        = bool
  default     = false
  description = "Optional. Define whether to route spoke-internal traffic within the spoke network. If false, traffic will be sent to the hub network. Default is false."
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "Optional. Name of an existing resource group to use. If provided, the module will use this existing resource group instead of creating a new one. Cannot be used together with existing_resource_group_id. Default is empty."

}

variable "existing_resource_group_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of an existing resource group to use. If provided, the module will use this existing resource group instead of creating a new one. Cannot be used together with resource_group_name. Default is empty."

}

variable "spoke_vnet_address_prefixes" {
  type        = list(string)
  description = "Required. CIDR of the Spoke Virtual Network."
}

variable "spoke_infra_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the Spoke Infrastructure Subnet."
}

variable "spoke_private_endpoints_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the Spoke Private Endpoints Subnet."
}

variable "spoke_application_gateway_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the Spoke Application Gateway Subnet."
}

variable "deployment_subnet_address_prefix" {
  type        = string
  description = "Required. The CIDR to use for Deployment scripts subnet."
}

# Jumpbox VM controls
variable "vm_size" {
  type        = string
  description = "Required. The size of the virtual machine to create. See https://learn.microsoft.com/azure/virtual-machines/sizes for more information."
}

variable "storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "Optional. The storage account type to use for the jump box. Defaults to `Standard_LRS`."
}

variable "vm_admin_password" {
  type        = string
  sensitive   = true
  description = "Required. The password to use for the virtual machine."
}

variable "vm_linux_ssh_authorized_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Optional. The SSH public key to use for the virtual machine. If not provided one will be generated. Default is empty."
}

variable "vm_authentication_type" {
  type        = string
  default     = "password"
  description = "Optional. Type of authentication to use on the Virtual Machine. SSH key is recommended. Default is \"password\"."

  validation {
    condition     = contains(["sshPublicKey", "password"], var.vm_authentication_type)
    error_message = "vm_authentication_type must be 'sshPublicKey' or 'password'."
  }
}

variable "vm_jumpbox_os_type" {
  type        = string
  default     = "none"
  description = "Optional. The operating system type of the virtual machine. Default is \"none\" which results in no VM deployment."

  validation {
    condition     = contains(["linux", "windows", "none"], var.vm_jumpbox_os_type)
    error_message = "vm_jumpbox_os_type must be 'linux', 'windows', or 'none'."
  }
}

variable "vm_jumpbox_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR to use for the virtual machine subnet."
}

# Observability & ACA
variable "enable_application_insights" {
  type        = bool
  description = "Required. Enable or disable the creation of Application Insights."
}

variable "enable_dapr_instrumentation" {
  type        = bool
  description = "Required. Enable or disable Dapr Application Instrumentation Key used for Dapr telemetry. If Application Insights is not enabled, this parameter is ignored."
}

# Ingress (Application Gateway path by default)
variable "application_gateway_fqdn" {
  type        = string
  default     = ""
  description = "Optional. The FQDN of the Application Gateway. Required and must match if the TLS Certificate is provided. Default is empty."
}

variable "base64_certificate" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Optional. The base64 encoded certificate to use for Application Gateway certificate. When not provided a self signed one will be generated, the certificate will be added to the Key Vault and assigned to the Application Gateway listener."
}

variable "application_gateway_certificate_key_name" {
  type        = string
  description = "Required. The name of the certificate key to use for Application Gateway certificate."
}

variable "application_gateway_certificate_subject_name" {
  type        = string
  default     = "CN=contoso.com"
  description = "Optional. The certificate subject name for self-signed certificates. Default is 'CN=contoso.com'."
}

variable "application_gateway_backend_fqdn" {
  type        = string
  default     = ""
  description = "Optional. The FQDN of the backend to use for the Application Gateway. Default is empty."
}

variable "deploy_zone_redundant_resources" {
  type        = bool
  default     = true
  description = "Optional. Default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false. Default is true."
}

variable "expose_container_apps_with" {
  type        = string
  default     = "applicationGateway"
  description = "Optional. Specify the way container apps is going to be exposed. Options are applicationGateway or frontDoor. Default is \"applicationGateway\"."

  validation {
    condition     = contains(["applicationGateway", "frontDoor", "none"], var.expose_container_apps_with)
    error_message = "expose_container_apps_with must be one of: applicationGateway, frontDoor, none."
  }
}

variable "deploy_sample_application" {
  type        = bool
  default     = false
  description = "Optional. Deploy sample application to the container apps environment. Default is false."
}

variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Optional. DDoS protection mode. see https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison#skus. Default is \"false\"."
}

variable "deploy_agent_pool" {
  type        = bool
  default     = true
  description = "Optional. Deploy the agent pool for the container registry. Default value is true."
}
