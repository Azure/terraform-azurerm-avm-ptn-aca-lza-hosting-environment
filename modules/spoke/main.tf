###############################################
# Spoke core resources                       #
###############################################

###############################################
# Log Analytics Workspace (AzAPI)            #
###############################################

locals {
  effective_replication_location = lookup(local.location_pairs, lower(var.location), null)
  law_base_properties = {
    sku = {
      name = "PerGB2018"
    }
    retentionInDays = 30
    features = {
      searchVersion = "2"
    }
  }
  law_replication_block = var.log_analytics_workspace_replication_enabled && local.effective_replication_location != null ? {
    replication = {
      enabled  = true
      location = local.effective_replication_location
    }
  } : {}
  law_workspace_properties = merge(local.law_base_properties, local.law_replication_block)
  # Location pairs for Log Analytics replication (ported from Bicep)
  location_pairs = {
    canadacentral      = "centralus"
    canadaeast         = "canadacentral"
    centralus          = "eastus"
    eastus             = "centralus"
    eastus2            = "centralus"
    northcentralus     = "centralus"
    southcentralus     = "westus"
    westcentralus      = "westus"
    westus             = "westus2"
    westus2            = "westus"
    westus3            = "westus2"
    brazilsouth        = "brazilsoutheast"
    brazilsoutheast    = "brazilsouth"
    francecentral      = "westeurope"
    francesouth        = "francecentral"
    germanynorth       = "northeurope"
    germanywestcentral = "germanynorth"
    italynorth         = "francecentral"
    northeurope        = "westeurope"
    norwayeast         = "northeurope"
    norwaywest         = "northeurope"
    polandcentral      = "northeurope"
    southuk            = "westeurope"
    uksouth            = "westeurope"
    spaincentral       = "francecentral"
    swedencentral      = "northeurope"
    swedensouth        = "swedencentral"
    switzerlandnorth   = "westeurope"
    switzerlandwest    = "westeurope"
    westeurope         = "northeurope"
    westuk             = "southuk"
    ukwest             = "uksouth"
    qatarcentral       = "uaecentral"
    uaecentral         = "uaenorth"
    uaenorth           = "qatarcentral"
    centralindia       = "southindia"
    southindia         = "centralindia"
    eastasia           = "southeastasia"
    japaneast          = "japanwest"
    japanwest          = "japaneast"
    koreacentral       = "koreasouth"
    koreasouth         = "koreacentral"
    southeastasia      = "eastasia"
    australiacentral   = "australiaeast"
    australiacentral2  = "australiacentral"
    australiaeast      = "australiasoutheast"
    australiasoutheast = "australiaeast"
    southafricanorth   = "southafricawest"
    southafricawest    = "southafricanorth"
  }
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = var.location
  name      = var.resources_names["logAnalyticsWorkspace"]
  parent_id = var.resource_group_id
  type      = "Microsoft.OperationalInsights/workspaces@2025-02-01"
  body = {
    properties = local.law_workspace_properties
  }
  response_export_values = ["id", "name", "properties.customerId"]
  tags                   = var.tags

  lifecycle {
    ignore_changes = [body.properties.features.searchVersion]
  }
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
    log_analytics_settings = {
      name                  = "log-analytics-settings"
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = {
    allow_internal_aks_connection_between_nodes_and_control_plane_udp = {
      name                       = "allow-internal-aks-connection-between-nodes-and-control-plane-udp"
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
    allow_internal_aks_connection_between_nodes_and_control_plane_tcp = {
      name                       = "allow-internal-aks-connection-between-nodes-and-control-plane-tcp"
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
    allow_azure_monitor = {
      name                       = "allow-azure-monitor"
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
    allow_outbound_443 = {
      name                       = "allow-outbound-443"
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
    allow_ntp_server = {
      name                       = "allow-ntp-server"
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
    allow_container_apps_control_plane = {
      name                       = "allow-container-apps-control-plane"
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
      destination_port_ranges    = ["22", "3389"]
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
  count   = var.spoke_application_gateway_subnet_address_prefix != null ? 1 : 0

  location            = var.location
  name                = var.resources_names["applicationGatewayNsg"]
  resource_group_name = var.resource_group_name
  diagnostic_settings = {
    log_analytics_settings = {
      name                  = "log-analytics-settings"
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = {
    health_probes = {
      name                       = "health-probes"
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
    allow_tls = {
      name                       = "allow-tls"
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
    allow_http = {
      name                       = "allow-http"
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
    allow_azure_load_balancer = {
      name                       = "allow-azure-load-balancer"
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
    log_analytics_settings = {
      name                  = "log-analytics-settings"
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = {
    deny_hop_outbound = {
      name                       = "deny-hop-outbound"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      access                     = "Deny"
      priority                   = 200
      direction                  = "Outbound"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
  tags = var.tags
}

module "nsg_jumpbox" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"
  count   = var.virtual_machine_jumpbox_os_type != "none" ? 1 : 0

  location            = var.location
  name                = var.resources_names["vmJumpBoxNsg"]
  resource_group_name = var.resource_group_name
  diagnostic_settings = {
    log_analytics_settings = {
      name                  = "log-analytics-settings"
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
    }
  }
  enable_telemetry = var.enable_telemetry
  security_rules = var.bastion_access_enabled && var.bastion_subnet_address_prefix != null ? {
    allow_bastion_inbound = {
      name                       = "allow-bastion-inbound"
      description                = "Allow inbound traffic from Bastion subnet to the JumpBox"
      protocol                   = "*"
      source_address_prefix      = var.bastion_subnet_address_prefix
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
      access                     = "Allow"
      priority                   = 100
      direction                  = "Inbound"
    }
  } : {}
  tags = var.tags
}

###############################################
# Route Table (egress lockdown)               #
###############################################
locals {
  # Use static boolean flag to determine route table creation
  create_route_table = var.egress_lockdown_enabled
  # Build routes only when needed - keys are fully static based on input variables
  route_table_routes = local.create_route_table ? merge(
    {
      default_egress_lockdown = {
        name                   = "default-egress-lockdown"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = var.network_appliance_ip_address
      }
    },
    var.route_spoke_traffic_internally ? {
      for idx, prefix in var.spoke_vnet_address_prefixes :
      "spoke_internal_traffic_${idx}" => {
        name           = "spoke-internal-traffic-${idx}"
        address_prefix = prefix
        next_hop_type  = "VnetLocal"
      }
    } : {}
  ) : {}
}

module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.4.1"
  count   = local.create_route_table ? 1 : 0

  location            = var.location
  name                = var.resources_names["routeTable"]
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  routes              = local.route_table_routes
  tags                = var.tags
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
  peerings = var.hub_peering_enabled ? {
    spoke_to_hub = {
      name                                 = "spoke-to-hub"
      remote_virtual_network_resource_id   = var.hub_virtual_network_resource_id
      allow_forwarded_traffic              = true
      allow_gateway_transit                = false
      allow_virtual_network_access         = true
      use_remote_gateways                  = false
      create_reverse_peering               = true
      reverse_name                         = "hub-to-spoke"
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
      route_table = local.create_route_table ? {
        id = module.route_table[0].resource_id
      } : null
      delegations = [{
        name = "Microsoft.App/environments"
        service_delegation = {
          name = "Microsoft.App/environments"
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
    }, var.spoke_application_gateway_subnet_address_prefix != null ? {
    agw = {
      name             = var.spoke_application_gateway_subnet_name
      address_prefixes = [var.spoke_application_gateway_subnet_address_prefix]
      network_security_group = {
        id = module.nsg_appgw[0].resource_id
      }
    }
    } : {}, var.virtual_machine_jumpbox_os_type != "none" ? {
    jumpbox = {
      name             = var.vm_subnet_name
      address_prefixes = [var.virtual_machine_jumpbox_subnet_address_prefix]
      network_security_group = {
        id = module.nsg_jumpbox[0].resource_id
      }
    }
  } : {})
  tags = var.tags
}

###############################################
# Optional Jumpbox VM                         #
###############################################

