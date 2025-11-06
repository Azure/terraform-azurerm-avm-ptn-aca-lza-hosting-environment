###############################################
# Spoke core resources via AVM submodules    #
###############################################

module "log_analytics" {
  source = "./log_analytics" # tflint-ignore: required_module_source_tffr1

  location            = var.location
  name                = var.resources_names["logAnalyticsWorkspace"]
  resource_group_id   = var.resource_group_id
  replication_enabled = var.log_analytics_workspace_replication_enabled
  retention_in_days   = 30
  sku                 = "PerGB2018"
  tags                = var.tags
}

###############################################
# Network Security Groups                     #
###############################################

locals {
  # Align location tag name for AzureCloud service tag (Bicep used francecentral -> centralfrance)
  location_for_service_tag = var.location == "francecentral" ? "centralfrance" : var.location
}

module "nsg_container_apps_env" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  location            = var.location
  name                = var.resources_names["containerAppsEnvironmentNsg"]
  resource_group_name = var.resource_group_name
  diagnostic_settings = {
    logAnalyticsSettings = {
      name                  = "logAnalyticsSettings"
      workspace_resource_id = module.log_analytics.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = {
    Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_UDP = {
      name                       = "Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_UDP"
      description                = "internal AKS secure connection between underlying nodes and control plane.."
      protocol                   = "Udp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "AzureCloud.${local.location_for_service_tag}"
      destination_port_range     = "1194"
      access                     = "Allow"
      priority                   = 100
      direction                  = "Outbound"
    }
    Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_TCP = {
      name                       = "Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_TCP"
      description                = "internal AKS secure connection between underlying nodes and control plane.."
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "AzureCloud.${local.location_for_service_tag}"
      destination_port_range     = "9000"
      access                     = "Allow"
      priority                   = 110
      direction                  = "Outbound"
    }
    Allow_Azure_Monitor = {
      name                       = "Allow_Azure_Monitor"
      description                = "Allows outbound calls to Azure Monitor."
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "AzureCloud.${local.location_for_service_tag}"
      destination_port_range     = "443"
      access                     = "Allow"
      priority                   = 120
      direction                  = "Outbound"
    }
    Allow_Outbound_443 = {
      name                       = "Allow_Outbound_443"
      description                = "Allowing all outbound on port 443 provides a way to allow all FQDN based outbound dependencies that don't have a static IP"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      access                     = "Allow"
      priority                   = 130
      direction                  = "Outbound"
    }
    Allow_NTP_Server = {
      name                       = "Allow_NTP_Server"
      description                = "NTP server"
      protocol                   = "Udp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "123"
      access                     = "Allow"
      priority                   = 140
      direction                  = "Outbound"
    }
    Allow_Container_Apps_control_plane = {
      name                       = "Allow_Container_Apps_control_plane"
      description                = "Container Apps control plane"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_ranges    = ["5671", "5672"]
      access                     = "Allow"
      priority                   = 150
      direction                  = "Outbound"
    }
    deny_hop_outbound = {
      name                       = "deny-hop-outbound"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["3389", "22"]
      access                     = "Deny"
      priority                   = 200
      direction                  = "Outbound"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
  tags = var.tags
}

module "nsg_appgw" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"
  count   = var.spoke_application_gateway_subnet_address_prefix != null && var.spoke_application_gateway_subnet_address_prefix != "" ? 1 : 0

  location            = var.location
  name                = var.resources_names["applicationGatewayNsg"]
  resource_group_name = var.resource_group_name
  diagnostic_settings = {
    logAnalyticsSettings = {
      name                  = "logAnalyticsSettings"
      workspace_resource_id = module.log_analytics.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = {
    HealthProbes = {
      name                       = "HealthProbes"
      description                = "allow HealthProbes from gateway Manager."
      protocol                   = "*"
      source_address_prefix      = "GatewayManager"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "65200-65535"
      access                     = "Allow"
      priority                   = 100
      direction                  = "Inbound"
    }
    Allow_TLS = {
      name                       = "Allow_TLS"
      description                = "allow https incoming connections"
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      access                     = "Allow"
      priority                   = 110
      direction                  = "Inbound"
    }
    Allow_HTTP = {
      name                       = "Allow_HTTP"
      description                = "allow http incoming connections"
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "80"
      access                     = "Allow"
      priority                   = 120
      direction                  = "Inbound"
    }
    Allow_AzureLoadBalancer = {
      name                       = "Allow_AzureLoadBalancer"
      description                = "allow AzureLoadBalancer incoming connections"
      protocol                   = "*"
      source_address_prefix      = "AzureLoadBalancer"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "80"
      access                     = "Allow"
      priority                   = 130
      direction                  = "Inbound"
    }
    allow_all_outbound = {
      name                       = "allow-all-outbound"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      access                     = "Allow"
      priority                   = 210
      direction                  = "Outbound"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
  tags = var.tags
}

module "nsg_pep" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  location            = var.location
  name                = var.resources_names["pepNsg"]
  resource_group_name = var.resource_group_name
  diagnostic_settings = {
    logAnalyticsSettings = {
      name                  = "logAnalyticsSettings"
      workspace_resource_id = module.log_analytics.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = {
    deny_hop_outbound = {
      name                       = "deny-hop-outbound"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["3389", "22"]
      access                     = "Deny"
      priority                   = 200
      direction                  = "Outbound"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
  tags = var.tags
}

module "nsg_deployment" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  location            = var.location
  name                = var.resources_names["acrDeploymentPoolNsg"]
  resource_group_name = var.resource_group_name
  diagnostic_settings = {
    logAnalyticsSettings = {
      name                  = "logAnalyticsSettings"
      workspace_resource_id = module.log_analytics.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = {
    Allow_HTTPS_Inbound = {
      name                       = "Allow_HTTPS_Inbound"
      description                = "Allow inbound HTTPS traffic on port 443 from any source."
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      access                     = "Allow"
      priority                   = 110
      direction                  = "Inbound"
    }
    Allow_HTTPS_Outbound = {
      name                       = "Allow_HTTPS_Outbound"
      description                = "Allow outbound HTTPS traffic on port 443 to any destination."
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      access                     = "Allow"
      priority                   = 120
      direction                  = "Outbound"
    }
    Allow_Azure_Container_Instance_Outbound = {
      name                       = "Allow_Azure_Container_Instance_Outbound"
      description                = "Allow outbound traffic to Azure services for container instances."
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "Internet"
      destination_port_range     = "*"
      access                     = "Allow"
      priority                   = 200
      direction                  = "Outbound"
    }
  }
  tags = var.tags
}

###############################################
# Route Table (egress lockdown)               #
###############################################

locals {
  create_egress_lockdown = var.hub_virtual_network_resource_id != "" && var.network_appliance_ip_address != ""
}

module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.4.1"
  count   = local.create_egress_lockdown ? 1 : 0

  location            = var.location
  name                = var.resources_names["routeTable"]
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  routes = merge({
    defaultEgressLockdown = {
      name                   = "defaultEgressLockdown"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.network_appliance_ip_address
    }
    }, var.route_spoke_traffic_internally ? {
    # Build VnetLocal routes for each spoke address prefix
    for idx, prefix in var.spoke_vnet_address_prefixes :
    "spokeInternalTraffic-${idx}" => {
      name           = "spokeInternalTraffic-${idx}"
      address_prefix = prefix
      next_hop_type  = "VnetLocal"
    }
  } : {})
  tags = var.tags
}

###############################################
# Virtual Network + Subnets + Peering         #
###############################################

module "vnet_spoke" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.15.0"

  location         = var.location
  parent_id        = var.resource_group_id
  address_space    = var.spoke_vnet_address_prefixes
  enable_telemetry = var.enable_telemetry
  name             = var.resources_names["vnetSpoke"]
  peerings = var.hub_virtual_network_resource_id != "" ? {
    spokeToHub = {
      name                                 = "spokeToHub"
      remote_virtual_network_resource_id   = var.hub_virtual_network_resource_id
      allow_forwarded_traffic              = true
      allow_gateway_transit                = false
      allow_virtual_network_access         = true
      use_remote_gateways                  = false
      create_reverse_peering               = true
      reverse_name                         = "hubToSpoke"
      reverse_allow_forwarded_traffic      = true
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_use_remote_gateways          = false
    }
  } : null
  subnets = merge({
    infra = {
      name             = var.spoke_infra_subnet_name
      address_prefixes = [var.spoke_infra_subnet_address_prefix]
      network_security_group = {
        id = module.nsg_container_apps_env.resource_id
      }
      route_table = local.create_egress_lockdown ? {
        id = module.route_table[0].resource_id
      } : null
      delegations = [{
        name = "Microsoft.App/environments"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
    }
    deployment = {
      name             = var.deployment_subnet_name
      address_prefixes = [var.deployment_subnet_address_prefix]
      network_security_group = {
        id = module.nsg_deployment.resource_id
      }
      delegations = [{
        name = "Microsoft.ContainerInstance/containerGroups"
        service_delegation = {
          name = "Microsoft.ContainerInstance/containerGroups"
        }
      }]
    }
    pep = {
      name             = var.spoke_private_endpoints_subnet_name
      address_prefixes = [var.spoke_private_endpoints_subnet_address_prefix]
      network_security_group = {
        id = module.nsg_pep.resource_id
      }
    }
    }, var.spoke_application_gateway_subnet_address_prefix != null && var.spoke_application_gateway_subnet_address_prefix != "" ? {
    agw = {
      name             = var.spoke_application_gateway_subnet_name
      address_prefixes = [var.spoke_application_gateway_subnet_address_prefix]
      network_security_group = {
        id = module.nsg_appgw[0].resource_id
      }
    }
    } : {}, var.vm_jumpbox_os_type != "none" ? {
    jumpbox = {
      name             = var.vm_subnet_name
      address_prefixes = [var.vm_jumpbox_subnet_address_prefix]
      # NSG will be created and associated by the VM submodule
    }
  } : {})
  tags = var.tags
}

###############################################
# Optional Jumpbox VM                         #
###############################################

module "vm_linux" {
  source = "./linux_vm" # tflint-ignore: required_module_source_tffr1
  count  = var.vm_jumpbox_os_type == "linux" ? 1 : 0

  enable_telemetry            = var.enable_telemetry
  location                    = var.location
  log_analytics_workspace_id  = module.log_analytics.id
  name                        = var.resources_names["vmJumpBox"]
  network_interface_name      = var.resources_names["vmJumpBoxNic"]
  network_security_group_name = var.resources_names["vmJumpBoxNsg"]
  resource_group_name         = var.resource_group_name
  subnet_id                   = module.vnet_spoke.subnets["jumpbox"].resource_id
  vm_admin_password           = var.vm_admin_password
  vm_size                     = var.vm_size
  bastion_resource_id         = var.bastion_resource_id
  storage_account_type        = var.storage_account_type
  tags                        = var.tags
  vm_authentication_type      = var.vm_authentication_type
  vm_linux_ssh_authorized_key = var.vm_linux_ssh_authorized_key
  vm_zone                     = var.vm_zone
}

module "vm_windows" {
  source = "./windows_vm" # tflint-ignore: required_module_source_tffr1
  count  = var.vm_jumpbox_os_type == "windows" ? 1 : 0

  enable_telemetry            = var.enable_telemetry
  location                    = var.location
  log_analytics_workspace_id  = module.log_analytics.id
  name                        = var.resources_names["vmJumpBox"]
  network_interface_name      = var.resources_names["vmJumpBoxNic"]
  network_security_group_name = var.resources_names["vmJumpBoxNsg"]
  resource_group_name         = var.resource_group_name
  subnet_id                   = module.vnet_spoke.subnets["jumpbox"].resource_id
  vm_admin_password           = var.vm_admin_password
  vm_size                     = var.vm_size
  bastion_resource_id         = var.bastion_resource_id
  storage_account_type        = var.storage_account_type
  tags                        = var.tags
  vm_windows_os_version       = "2016-Datacenter"
  vm_zone                     = var.vm_zone
}
