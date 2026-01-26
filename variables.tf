###############################################
# Stage 0: Variables mirroring Bicep inputs  #
###############################################

# Observability & ACA
variable "application_insights_enabled" {
  type        = bool
  description = "Required. Enable or disable the creation of Application Insights."
}

variable "dapr_instrumentation_enabled" {
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

variable "bastion_subnet_address_prefix" {
  type        = string
  default     = null
  description = "Optional. The CIDR address prefix of the bastion subnet. Required when bastion_access_enabled is true. Example: 10.0.1.0/27"
}

variable "created_resource_group_name" {
  type        = string
  default     = null
  description = "Optional. Name to use when existing_resource_group_used is true and the module is creating a resource group. Leave null for auto-generation."

  validation {
    condition     = !(var.created_resource_group_name != null && var.existing_resource_group_id != null)
    error_message = "Cannot specify both created_resource_group_name (for new RG) and existing_resource_group_id (for existing RG). Please provide only one, or leave both null for auto-generation."
  }
}

variable "sample_application_enabled" {
  type        = bool
  default     = false
  nullable    = false
  description = "Optional. Deploy sample application to the container apps environment. Default is false."
}

variable "zone_redundant_resources_enabled" {
  type        = bool
  default     = true
  nullable    = false
  description = "Optional. Default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false. Default is true."
}

variable "bastion_access_enabled" {
  type        = bool
  default     = false
  description = "Optional. Whether to enable bastion access rule in the VM NSG. Set to true when using a bastion host with a VM jumpbox. Default is false."
  nullable    = false
}

variable "ddos_protection_enabled" {
  type        = bool
  default     = false
  nullable    = false
  description = <<-EOT
    Optional. Enable DDoS IP Protection on the Application Gateway public IP address.

    When enabled, this configures per-IP DDoS protection mode on the Application Gateway's
    public IP only. This is NOT a DDoS Network Protection Plan.

    Note: Per-IP DDoS protection incurs additional costs (~$199/month per protected IP).
    For enterprise deployments using Azure Landing Zones, consider using a centralized
    DDoS Network Protection Plan instead.

    See https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison
    for SKU comparison and pricing information.

    Default is false.
  EOT
}

variable "egress_lockdown_enabled" {
  type        = bool
  default     = false
  description = "Optional. Whether to enable egress lockdown by routing all traffic through a network appliance. When true, network_appliance_ip_address must be provided. Default is false."
  nullable    = false
}

# Hub/Spoke integration
variable "hub_peering_enabled" {
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
  nullable    = false
  description = "Optional. The name of the environment (e.g. \"dev\", \"test\", \"prod\", \"uat\", \"dr\", \"qa\"). Up to 8 characters long. Default is \"test\"."

  validation {
    condition     = length(var.environment) <= 8
    error_message = "environment must be at most 8 characters."
  }
}

variable "existing_resource_group_id" {
  type        = string
  default     = null
  description = "Optional. The resource ID of an existing resource group to use when existing_resource_group_used is set to true. Default is null."

  validation {
    condition     = !var.existing_resource_group_used || (var.existing_resource_group_used && var.existing_resource_group_id != null && trimspace(var.existing_resource_group_id) != "")
    error_message = "existing_resource_group_id must be provided when existing_resource_group_used is true."
  }
}

variable "expose_container_apps_with" {
  type        = string
  default     = "application_gateway"
  nullable    = false
  description = "Optional. Specify the way container apps is going to be exposed. Options are applicationGateway, frontDoor, or none. Default is \"applicationGateway\"."

  validation {
    condition     = contains(["application_gateway", "front_door", "none"], var.expose_container_apps_with)
    error_message = "expose_container_apps_with must be one of: applicationGateway, frontDoor, none."
  }
}

variable "front_door_waf_enabled" {
  type        = bool
  default     = false
  nullable    = false
  description = "Optional. Enable Web Application Firewall for Front Door. Default is false."
}

variable "front_door_waf_policy_name" {
  type        = string
  default     = null
  description = "Optional. Name of the WAF policy for Front Door. Required if front_door_waf_enabled is true. Default is null."
}

variable "virtual_machine_ssh_key_generation_enabled" {
  type        = bool
  default     = false
  description = "Optional. Whether to auto-generate an SSH key for the Linux VM. When false, virtual_machine_linux_ssh_authorized_key must be provided if using SSH authentication. Default is false."
  nullable    = false
}

variable "hub_virtual_network_resource_id" {
  type        = string
  default     = null
  description = "Optional. The resource ID of the hub virtual network. Required when hub_peering_enabled is true. If set, the spoke virtual network will be peered with the hub virtual network. Default is null."

  validation {
    condition     = !var.hub_peering_enabled || var.hub_virtual_network_resource_id != null
    error_message = "hub_virtual_network_resource_id is required when hub_peering_enabled is true."
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
  description = "Optional. IP address of the network appliance (e.g., Azure Firewall) for routing egress traffic. Required when egress_lockdown_enabled is true. Default is null."

  validation {
    condition     = !var.egress_lockdown_enabled || var.network_appliance_ip_address != null
    error_message = "network_appliance_ip_address is required when egress_lockdown_enabled is true."
  }
}

variable "route_spoke_traffic_internally" {
  type        = bool
  default     = false
  nullable    = false
  description = "Optional. Define whether to route spoke-internal traffic within the spoke network. If false, traffic will be sent to the hub network. Default is false."
}

variable "spoke_application_gateway_subnet_address_prefix" {
  type        = string
  default     = null
  description = "Optional. CIDR of the Spoke Application Gateway Subnet. Required when expose_container_apps_with is 'applicationGateway'. Default is null."

  validation {
    condition     = var.expose_container_apps_with != "application_gateway" || var.spoke_application_gateway_subnet_address_prefix != null
    error_message = "spoke_application_gateway_subnet_address_prefix is required when expose_container_apps_with is 'applicationGateway'."
  }
}

variable "storage_account_type" {
  type        = string
  default     = "Premium_LRS"
  nullable    = false
  description = "Optional. The storage account type to use for the jump box. Defaults to `Premium_LRS` for APRL compliance."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional. Tags related to the Azure Container Apps deployment. Default is null."
}

variable "existing_resource_group_used" {
  type        = bool
  default     = false
  nullable    = false
  description = "Optional. Whether to use an existing resource group or create a new one. If true, the module will use the resource group specified in existing_resource_group_id. If false, a new resource group will be created with the name specified in create_resource_group_name (or selected one for you if not specified). Default is false."
}

variable "virtual_machine_admin_password" {
  type        = string
  default     = null
  sensitive   = true
  description = <<-EOT
    Optional. The password to use for the virtual machine admin account.
    Required when virtual_machine_jumpbox_os_type is not 'none' and virtual_machine_admin_password_generate is false.

    NOTE: This value is marked as sensitive and will not be displayed in logs or plan output.
    However, it will be stored in Terraform state. Ensure your state backend is properly secured
    (e.g., Azure Storage with encryption, Terraform Cloud, etc.).

    For production deployments, consider using virtual_machine_admin_password_generate = true
    to auto-generate the password and store it securely in Azure Key Vault instead.
  EOT

  validation {
    condition     = var.virtual_machine_jumpbox_os_type == "none" || var.virtual_machine_admin_password_generate || var.virtual_machine_admin_password != null
    error_message = "virtual_machine_admin_password must be provided when virtual_machine_jumpbox_os_type is not 'none' and virtual_machine_admin_password_generate is false."
  }
}

variable "virtual_machine_admin_password_generate" {
  type        = bool
  default     = false
  nullable    = false
  description = "Optional. When true, auto-generate the admin password and store in Key Vault. The Key Vault is always created by the supporting_services module. Default is false."
}

variable "virtual_machine_authentication_type" {
  type        = string
  default     = "ssh_public_key"
  nullable    = false
  description = "Optional. Type of authentication to use on the Virtual Machine. SSH key is recommended for security. Default is \"sshPublicKey\"."

  validation {
    condition     = contains(["ssh_public_key", "password"], var.virtual_machine_authentication_type)
    error_message = "virtual_machine_authentication_type must be 'sshPublicKey' or 'password'."
  }
}

variable "virtual_machine_jumpbox_os_type" {
  type        = string
  default     = "none"
  nullable    = false
  description = "Optional. The operating system type of the virtual machine. Default is \"none\" which results in no VM deployment."

  validation {
    condition     = contains(["linux", "windows", "none"], var.virtual_machine_jumpbox_os_type)
    error_message = "virtual_machine_jumpbox_os_type must be 'linux', 'windows', or 'none'."
  }
}

variable "virtual_machine_jumpbox_subnet_address_prefix" {
  type        = string
  default     = null
  description = "Optional. CIDR to use for the virtual machine subnet. Required when virtual_machine_jumpbox_os_type is not 'none'. Default is null."

  validation {
    condition     = var.virtual_machine_jumpbox_os_type == "none" || var.virtual_machine_jumpbox_subnet_address_prefix != null
    error_message = "virtual_machine_jumpbox_subnet_address_prefix is required when virtual_machine_jumpbox_os_type is not 'none'."
  }
}

variable "virtual_machine_linux_ssh_authorized_key" {
  type        = string
  default     = null
  description = "Optional. The SSH public key to use for the virtual machine. Required when virtual_machine_jumpbox_os_type is 'linux', virtual_machine_authentication_type is 'sshPublicKey', and virtual_machine_ssh_key_generation_enabled is false."
  sensitive   = true

  validation {
    condition     = var.virtual_machine_jumpbox_os_type != "linux" || var.virtual_machine_authentication_type != "ssh_public_key" || var.virtual_machine_ssh_key_generation_enabled || var.virtual_machine_linux_ssh_authorized_key != null
    error_message = "virtual_machine_linux_ssh_authorized_key is required when virtual_machine_jumpbox_os_type is 'linux' and virtual_machine_authentication_type is 'sshPublicKey' and virtual_machine_ssh_key_generation_enabled is false."
  }
}

# Jumpbox VM controls
variable "virtual_machine_size" {
  type        = string
  default     = null
  description = "Optional. The size of the virtual machine to create. Required when virtual_machine_jumpbox_os_type is not 'none'. See https://learn.microsoft.com/azure/virtual-machines/sizes for more information. Default is null."

  validation {
    condition     = var.virtual_machine_jumpbox_os_type == "none" || var.virtual_machine_size != null
    error_message = "virtual_machine_size is required when virtual_machine_jumpbox_os_type is not 'none'."
  }
}

# Naming/Env
variable "workload_name" {
  type        = string
  default     = "aca-lza"
  nullable    = false
  description = "Optional. The name of the workload that is being deployed. Up to 10 characters long."

  validation {
    condition     = length(var.workload_name) >= 2 && length(var.workload_name) <= 10
    error_message = "workload_name must be 2 to 10 characters."
  }
}
