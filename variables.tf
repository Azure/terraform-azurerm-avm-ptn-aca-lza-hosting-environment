###############################################
# Stage 0: Variables mirroring Bicep inputs  #
###############################################

# Ingress (Application Gateway uses self-signed certificate for demo)

variable "deployment_subnet_address_prefix" {
  type        = string
  description = "Required. The CIDR to use for Deployment scripts subnet."
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

# General
variable "location" {
  type        = string
  description = "Optional. The location of the Azure Container Apps deployment."
}

variable "spoke_application_gateway_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the Spoke Application Gateway Subnet."
}

variable "spoke_infra_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the Spoke Infrastructure Subnet."
}

variable "spoke_private_endpoints_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the Spoke Private Endpoints Subnet."
}

variable "spoke_vnet_address_prefixes" {
  type        = list(string)
  description = "Required. CIDR of the Spoke Virtual Network."
}

variable "vm_admin_password" {
  type        = string
  description = "Required. The password to use for the virtual machine."
  sensitive   = true
}

variable "vm_jumpbox_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR to use for the virtual machine subnet."
}

# Jumpbox VM controls
variable "vm_size" {
  type        = string
  description = "Required. The size of the virtual machine to create. See https://learn.microsoft.com/azure/virtual-machines/sizes for more information."
}

variable "bastion_resource_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of the bastion host. If set, the spoke virtual network will be peered with the hub virtual network and the bastion host will be allowed to connect to the jump box. Default is empty."
}

variable "created_resource_group_name" {
  type        = string
  default     = ""
  description = "Optional. Name to use when use_existing_resource_group is true and the module is creating a resource group. Leave blank for auto-generation."
}

variable "deploy_sample_application" {
  type        = bool
  default     = false
  description = "Optional. Deploy sample application to the container apps environment. Default is false."
}

variable "deploy_zone_redundant_resources" {
  type        = bool
  default     = true
  description = "Optional. Default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false. Default is true."
}

variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Optional. DDoS protection mode. see https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison#skus. Default is \"false\"."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
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

variable "existing_resource_group_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of an existing resource group to use when use_existing_resource_group is set to true. Default is empty."

  validation {
    condition     = var.use_existing_resource_group == true && trimspace(var.existing_resource_group_id) != ""
    error_message = "existing_resource_group_id must be provided when use_existing_resource_group is true."
  }
}

variable "expose_container_apps_with" {
  type        = string
  default     = "applicationGateway"
  description = "Optional. Specify the way container apps is going to be exposed. Options are applicationGateway, frontDoor, or none. Default is \"applicationGateway\"."

  validation {
    condition     = contains(["applicationGateway", "frontDoor", "none"], var.expose_container_apps_with)
    error_message = "expose_container_apps_with must be one of: applicationGateway, frontDoor, none."
  }
}

variable "front_door_enable_private_link" {
  type        = bool
  default     = false
  description = "Optional. Enable private link integration between Front Door and Container Apps Environment. Requires Premium SKU. Default is false."
}

variable "front_door_enable_waf" {
  type        = bool
  default     = false
  description = "Optional. Enable Web Application Firewall for Front Door. Requires Premium SKU. Default is false."
}

# Front Door (alternative ingress option)
variable "front_door_sku_name" {
  type        = string
  default     = "Standard_AzureFrontDoor"
  description = "Optional. SKU name for the Front Door profile. Options: Standard_AzureFrontDoor, Premium_AzureFrontDoor. Default is \"Standard_AzureFrontDoor\"."

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.front_door_sku_name)
    error_message = "front_door_sku_name must be either Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "front_door_waf_policy_name" {
  type        = string
  default     = ""
  description = "Optional. Name of the WAF policy for Front Door. Required if front_door_enable_waf is true. Default is empty."
}

# Hub/Spoke integration
variable "hub_virtual_network_resource_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of the hub virtual network. If set, the spoke virtual network will be peered with the hub virtual network. Default is empty."
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

variable "storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "Optional. The storage account type to use for the jump box. Defaults to `Standard_LRS`."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional. Tags related to the Azure Container Apps deployment. Default is empty."
}

variable "use_existing_resource_group" {
  type        = bool
  default     = false
  description = "Optional. Whether to use an existing resource group or create a new one. If true, the module will use the resource group specified in existing_resource_group_id. If false, a new resource group will be created with the name specified in create_resource_group_name (or selected one for you if not specified). Default is false."
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

variable "vm_linux_ssh_authorized_key" {
  type        = string
  default     = ""
  description = "Optional. The SSH public key to use for the virtual machine. If not provided one will be generated. Default is empty."
  sensitive   = true
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
