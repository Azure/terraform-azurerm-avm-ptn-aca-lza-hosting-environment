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
  description = "Required. The location of the Azure Container Apps deployment."
  nullable    = false
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

variable "bastion_resource_id" {
  type        = string
  default     = null
  description = "Optional. The resource ID of the bastion host. If set, the spoke virtual network will be peered with the hub virtual network and the bastion host will be allowed to connect to the jump box. Default is null."
}

variable "created_resource_group_name" {
  type        = string
  default     = null
  description = "Optional. Name to use when use_existing_resource_group is true and the module is creating a resource group. Leave null for auto-generation."
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

variable "enable_bastion_access" {
  type        = bool
  default     = false
  description = "Optional. Whether to enable bastion access rule in the VM NSG. Set to true when using a bastion host with a VM jumpbox. Default is false."
  nullable    = false
}

variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Optional. DDoS protection mode. see https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison#skus. Default is \"false\"."
}

variable "enable_egress_lockdown" {
  type        = bool
  default     = false
  description = "Optional. Whether to enable egress lockdown by routing all traffic through a network appliance. When true, network_appliance_ip_address must be provided. Default is false."
  nullable    = false
}

# Hub/Spoke integration
variable "enable_hub_peering" {
  type        = bool
  default     = false
  description = "Optional. Whether to enable peering with a hub virtual network. When true, hub_virtual_network_resource_id must be provided. Default is false."
  nullable    = false
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
  default     = null
  description = "Optional. The resource ID of an existing resource group to use when use_existing_resource_group is set to true. Default is null."

  validation {
    condition     = !var.use_existing_resource_group || (var.use_existing_resource_group && var.existing_resource_group_id != null && trimspace(var.existing_resource_group_id) != "")
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

variable "front_door_enable_waf" {
  type        = bool
  default     = false
  description = "Optional. Enable Web Application Firewall for Front Door. Default is false."
}

variable "front_door_waf_policy_name" {
  type        = string
  default     = null
  description = "Optional. Name of the WAF policy for Front Door. Required if front_door_enable_waf is true. Default is null."
}

variable "generate_ssh_key_for_vm" {
  type        = bool
  default     = false
  description = "Optional. Whether to auto-generate an SSH key for the Linux VM. When false, vm_linux_ssh_authorized_key must be provided if using SSH authentication. Default is false."
  nullable    = false
}

variable "hub_virtual_network_resource_id" {
  type        = string
  default     = null
  description = "Optional. The resource ID of the hub virtual network. Required when enable_hub_peering is true. If set, the spoke virtual network will be peered with the hub virtual network. Default is null."

  validation {
    condition     = !var.enable_hub_peering || var.hub_virtual_network_resource_id != null
    error_message = "hub_virtual_network_resource_id is required when enable_hub_peering is true."
  }
}

variable "log_analytics_workspace_replication_enabled" {
  type        = bool
  default     = true
  description = "Optional. Enable cross-region replication for the Log Analytics workspace. Default is true. Set to false in test/example environments to avoid issues with resource destruction."
  nullable    = false
}

variable "network_appliance_ip_address" {
  type        = string
  default     = null
  description = "Optional. IP address of the network appliance (e.g., Azure Firewall) for routing egress traffic. Required when enable_egress_lockdown is true. Default is null."

  validation {
    condition     = !var.enable_egress_lockdown || var.network_appliance_ip_address != null
    error_message = "network_appliance_ip_address is required when enable_egress_lockdown is true."
  }
}

variable "route_spoke_traffic_internally" {
  type        = bool
  default     = false
  description = "Optional. Define whether to route spoke-internal traffic within the spoke network. If false, traffic will be sent to the hub network. Default is false."
}

variable "spoke_application_gateway_subnet_address_prefix" {
  type        = string
  default     = null
  description = "Optional. CIDR of the Spoke Application Gateway Subnet. Required when expose_container_apps_with is 'applicationGateway'. Default is null."

  validation {
    condition     = var.expose_container_apps_with != "applicationGateway" || var.spoke_application_gateway_subnet_address_prefix != null
    error_message = "spoke_application_gateway_subnet_address_prefix is required when expose_container_apps_with is 'applicationGateway'."
  }
}

variable "storage_account_type" {
  type        = string
  default     = "Premium_LRS"
  description = "Optional. The storage account type to use for the jump box. Defaults to `Premium_LRS` for APRL compliance."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional. Tags related to the Azure Container Apps deployment. Default is null."
}

variable "use_existing_resource_group" {
  type        = bool
  default     = false
  description = "Optional. Whether to use an existing resource group or create a new one. If true, the module will use the resource group specified in existing_resource_group_id. If false, a new resource group will be created with the name specified in create_resource_group_name (or selected one for you if not specified). Default is false."
}

variable "vm_admin_password" {
  type        = string
  default     = null
  description = "Optional. The password to use for the virtual machine. Required when vm_jumpbox_os_type is not 'none'. Default is null."
  sensitive   = true

  validation {
    condition     = var.vm_jumpbox_os_type == "none" || var.vm_admin_password != null
    error_message = "vm_admin_password is required when vm_jumpbox_os_type is not 'none'."
  }
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
  default     = null
  description = "Optional. CIDR to use for the virtual machine subnet. Required when vm_jumpbox_os_type is not 'none'. Default is null."

  validation {
    condition     = var.vm_jumpbox_os_type == "none" || var.vm_jumpbox_subnet_address_prefix != null
    error_message = "vm_jumpbox_subnet_address_prefix is required when vm_jumpbox_os_type is not 'none'."
  }
}

variable "vm_linux_ssh_authorized_key" {
  type        = string
  default     = null
  description = "Optional. The SSH public key to use for the virtual machine. Required when vm_jumpbox_os_type is 'linux', vm_authentication_type is 'sshPublicKey', and generate_ssh_key_for_vm is false."
  sensitive   = true

  validation {
    condition     = var.vm_jumpbox_os_type != "linux" || var.vm_authentication_type != "sshPublicKey" || var.generate_ssh_key_for_vm || var.vm_linux_ssh_authorized_key != null
    error_message = "vm_linux_ssh_authorized_key is required when vm_jumpbox_os_type is 'linux' and vm_authentication_type is 'sshPublicKey' and generate_ssh_key_for_vm is false."
  }
}

# Jumpbox VM controls
variable "vm_size" {
  type        = string
  default     = null
  description = "Optional. The size of the virtual machine to create. Required when vm_jumpbox_os_type is not 'none'. See https://learn.microsoft.com/azure/virtual-machines/sizes for more information. Default is null."

  validation {
    condition     = var.vm_jumpbox_os_type == "none" || var.vm_size != null
    error_message = "vm_size is required when vm_jumpbox_os_type is not 'none'."
  }
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
