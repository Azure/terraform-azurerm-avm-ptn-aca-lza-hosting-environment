###############################################
# Spoke module inputs                        #
###############################################

###############################################
# Networking inputs (from root)               #
###############################################

###############################################
# Jumpbox VM inputs                           #
###############################################

variable "deployment_subnet_address_prefix" {
  type        = string
  description = "Required. The CIDR to use for Deployment scripts subnet."
}

variable "location" {
  type        = string
  description = "Required. Azure location for the spoke resources."
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "Required. The ID of the resource group to deploy spoke resources into."
}

variable "resource_group_name" {
  type        = string
  description = "Required. The name of the resource group to deploy spoke resources into."
}

variable "resources_names" {
  type        = map(string)
  description = "Required. Computed resource names from naming module (expects key 'logAnalyticsWorkspace')."
}

variable "spoke_infra_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the spoke infrastructure subnet."
}

variable "spoke_private_endpoints_subnet_address_prefix" {
  type        = string
  description = "Required. CIDR of the spoke private endpoints subnet."
}

variable "spoke_vnet_address_prefixes" {
  type        = list(string)
  description = "Required. CIDR of the spoke virtual network."
}

variable "bastion_resource_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of the bastion host."
}

variable "deployment_subnet_name" {
  type        = string
  default     = "snet-deployment"
  description = "Optional. The name of the subnet to create for the deployment scripts. If set, overrides the default name 'snet-deployment'."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Optional. Enable/Disable module telemetry for AVM submodules."
}

variable "hub_virtual_network_resource_id" {
  type        = string
  default     = ""
  description = "Optional. The resource ID of the existing hub virtual network. If provided, a peering from spoke to hub will be created."
}

variable "log_analytics_workspace_replication_enabled" {
  type        = bool
  default     = true
  description = "Optional. Enable cross-region replication for the Log Analytics workspace. Default is true."
  nullable    = false
}

variable "network_appliance_ip_address" {
  type        = string
  default     = ""
  description = "Optional. The IP address of the network appliance (e.g. firewall) that will be used to route traffic to the internet. Required to create the egress lockdown UDR."
}

variable "route_spoke_traffic_internally" {
  type        = bool
  default     = false
  description = "Optional. Define whether to route spoke-internal traffic within the spoke network. If false, traffic will be sent to the hub network. Default is false."
}

variable "spoke_application_gateway_subnet_address_prefix" {
  type        = string
  default     = ""
  description = "Optional. CIDR of the spoke Application Gateway subnet. If empty, no Application Gateway subnet or NSG will be created."
}

variable "spoke_application_gateway_subnet_name" {
  type        = string
  default     = "snet-agw"
  description = "Optional. The name of the subnet to create for the spoke application gateway. If set, overrides the default name 'snet-agw'. Only used when the subnet CIDR is provided."
}

variable "spoke_infra_subnet_name" {
  type        = string
  default     = "snet-infra"
  description = "Optional. The name of the subnet to create for the spoke infrastructure. If set, overrides the default name 'snet-infra'."
}

variable "spoke_private_endpoints_subnet_name" {
  type        = string
  default     = "snet-pep"
  description = "Optional. The name of the subnet to create for the spoke private endpoints. If set, overrides the default name 'snet-pep'."
}

variable "storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "Optional. The storage account type to use for the jump box."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional. Tags to apply to spoke resources."
}

variable "vm_admin_password" {
  type        = string
  default     = null
  description = "Optional. The password to use for the virtual machine. Required when vm_authentication_type == 'password' and vm_jumpbox_os_type != 'none'."
  sensitive   = true
}

variable "vm_authentication_type" {
  type        = string
  default     = "password"
  description = "Optional. Type of authentication to use on the Virtual Machine. SSH key is recommended."
}

variable "vm_jumpbox_os_type" {
  type        = string
  default     = "none"
  description = "Optional. The operating system type of the virtual machine. If 'none', no VM is deployed."
}

variable "vm_jumpbox_subnet_address_prefix" {
  type        = string
  default     = ""
  description = "Optional. CIDR to use for the virtual machine subnet. Required when vm_jumpbox_os_type != 'none'."
}

variable "vm_linux_ssh_authorized_key" {
  type        = string
  default     = null
  description = "Optional. The SSH public key to use for the Linux virtual machine."
  sensitive   = true
}

variable "vm_size" {
  type        = string
  default     = ""
  description = "Optional. The size of the virtual machine to create when vm_jumpbox_os_type != 'none'."
}

variable "vm_subnet_name" {
  type        = string
  default     = "snet-jumpbox"
  description = "Optional. The name of the subnet to create for the jump box."
}

variable "vm_zone" {
  type        = number
  default     = 0
  description = "Optional. The zone to create the jump box in. Defaults to 0."
}
