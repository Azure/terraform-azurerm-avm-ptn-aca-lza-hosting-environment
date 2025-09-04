terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.115.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0"
    }
  }
}

locals {
  zones = var.deploy_zone_redundant_resources ? ["1", "2", "3"] : []
}

# UAI for App Gateway to read Key Vault secret
module "appgw_uai" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "~> 0.2"

  name                = var.user_assigned_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags
}

# Public IP for Application Gateway
module "appgw_pip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "~> 0.2"

  name                 = var.public_ip_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  enable_telemetry     = var.enable_telemetry
  tags                 = var.tags
  allocation_method    = "Static"
  sku                  = "Standard"
  ddos_protection_mode = var.enable_ddos_protection ? "Enabled" : "Disabled"
  zones                = local.zones

  diagnostic_settings = var.enable_diagnostics ? {
    diag = {
      name                  = "${var.public_ip_name}-diag"
      workspace_resource_id = var.log_analytics_workspace_id
      metric_categories     = ["AllMetrics"]
    }
  } : null
}

# Certificate module for handling TLS certificates with VNet integration
module "certificate" {
  source = "../certificate"

  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  resource_prefix     = substr(replace(var.name, "-", ""), 0, 8)

  key_vault_id              = var.key_vault_id
  storage_account_name      = var.storage_account_name
  deployment_subnet_id      = var.deployment_subnet_id
  app_gateway_principal_id  = module.appgw_uai.principal_id
  certificate_key_name      = var.certificate_key_name
  certificate_subject_name  = var.certificate_subject_name
  base64_certificate        = var.base64_certificate
}

# WAF policy - use native resource as AVM equivalent isn't published in TF registry yet
resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "${var.name}Policy001"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled                 = true
    mode                    = "Prevention"
    file_upload_limit_in_mb = 10
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "0.1"
    }
  }
}

# Application Gateway using AVM module
module "app_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "~> 0.2"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags

  gateway_ip_configuration = {
    subnet_id = var.subnet_id
  }

  # HTTPS only listener on 443
  frontend_ports = {
    https = {
      name = "port_443"
      port = 443
    }
  }

  http_listeners = {
    https = {
      name                 = "https-listener"
      host_name            = length(trimspace(var.application_gateway_fqdn)) > 0 ? var.application_gateway_fqdn : null
      frontend_port_name   = "port_443"
  frontend_ip_configuration_name = "appGwPublicFrontendIp"
      ssl_certificate_name = var.certificate_key_name
    }
  }

  ssl_certificates = {
    (var.certificate_key_name) = {
      name                = var.certificate_key_name
      key_vault_secret_id = module.certificate.secret_uri
    }
  }

  backend_address_pools = {
    backend = {
      name  = "acaServiceBackend"
      fqdns = length(trimspace(var.backend_fqdn)) > 0 ? [var.backend_fqdn] : null
    }
  }

  backend_http_settings = {
    https = {
      name                                = "https"
      port                                = 443
      protocol                            = "Https"
      request_timeout                     = 20
      pick_host_name_from_backend_address = true
      probe_name                          = length(trimspace(var.backend_fqdn)) > 0 ? "webProbe" : null
    }
  }

  probe_configurations = length(trimspace(var.backend_fqdn)) > 0 ? {
    https = {
      name                                      = "webProbe"
      protocol                                  = "Https"
      host                                      = var.backend_fqdn
      path                                      = var.backend_probe_path
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = false
      match = {
        status_code = ["200-499"]
      }
    }
  } : null

  request_routing_rules = {
    rule1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "https-listener"
      backend_address_pool_name  = "acaServiceBackend"
      backend_http_settings_name = "https"
      priority                   = 100
    }
  }

  create_public_ip                      = false
  public_ip_resource_id                 = module.appgw_pip.resource_id
  frontend_ip_configuration_public_name = "appGwPublicFrontendIp"

  managed_identities = {
    user_assigned_resource_ids = [module.appgw_uai.resource_id]
  }

  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.waf.id

  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 3
  }

  ssl_policy = {
    policy_type          = "Custom"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
    ]
  }

  diagnostic_settings = var.enable_diagnostics ? {
    agw = {
      name                  = "${var.name}-diag"
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}

  zones = local.zones
}

# Read the public IP to expose its current address
data "azurerm_public_ip" "pip" {
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name
  depends_on          = [module.appgw_pip]
}
