
locals {
  zones = var.deploy_zone_redundant_resources ? ["1", "2", "3"] : []
}

# Public IP for Application Gateway
module "appgw_pip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "~> 0.2"

  location             = var.location
  name                 = var.public_ip_name
  resource_group_name  = var.resource_group_name
  allocation_method    = "Static"
  ddos_protection_mode = var.enable_ddos_protection ? "Enabled" : "Disabled"
  diagnostic_settings = var.enable_diagnostics ? {
    diag = {
      name                  = "${var.public_ip_name}-diag"
      workspace_resource_id = var.log_analytics_workspace_id
      metric_categories     = ["AllMetrics"]
    }
  } : null
  enable_telemetry = var.enable_telemetry
  sku              = "Standard"
  tags             = var.tags
  zones            = local.zones
}

# Generate a simple self-signed certificate for demo purposes
# This avoids the complexity of Key Vault integration for a hosting environment module
resource "tls_private_key" "appgw" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "appgw" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  private_key_pem       = tls_private_key.appgw.private_key_pem
  validity_period_hours = 8760 # 1 year

  subject {
    common_name  = "aca-demo.local"
    organization = "Azure Container Apps Demo"
  }
}

# Convert to PKCS12 format for Application Gateway
resource "pkcs12_from_pem" "appgw" {
  password        = "AzureDemo123!" # Simple password for demo cert
  cert_pem        = tls_self_signed_cert.appgw.cert_pem
  private_key_pem = tls_private_key.appgw.private_key_pem
}

# WAF policy - use native resource as AVM equivalent isn't published in TF registry yet
resource "azurerm_web_application_firewall_policy" "waf" {
  location            = var.location
  name                = "${var.name}Policy001"
  resource_group_name = var.resource_group_name
  tags                = var.tags

  managed_rules {
    managed_rule_set {
      version = "3.2"
      type    = "OWASP"
    }
    managed_rule_set {
      version = "0.1"
      type    = "Microsoft_BotManagerRuleSet"
    }
  }
  policy_settings {
    enabled                 = true
    file_upload_limit_in_mb = 10
    mode                    = "Prevention"
  }
}

# Application Gateway using AVM module
module "app_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "~> 0.2"

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
  # HTTPS only listener on 443
  frontend_ports = {
    https = {
      name = "port_443"
      port = 443
    }
  }
  gateway_ip_configuration = {
    subnet_id = var.subnet_id
  }
  http_listeners = {
    https = {
      name                           = "https-listener"
      frontend_port_name             = "port_443"
      frontend_ip_configuration_name = "appGwPublicFrontendIp"
      ssl_certificate_name           = "appgw-demo-cert"
      protocol                       = "Https"
    }
  }
  location = var.location
  name     = var.name
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
  resource_group_name                = var.resource_group_name
  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.waf.id
  create_public_ip                   = false
  diagnostic_settings = var.enable_diagnostics ? {
    agw = {
      name                  = "${var.name}-diag"
      workspace_resource_id = var.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
  enable_telemetry                      = var.enable_telemetry
  frontend_ip_configuration_public_name = "appGwPublicFrontendIp"
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
  public_ip_resource_id = module.appgw_pip.resource_id
  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 3
  }
  ssl_certificates = {
    "appgw-demo-cert" = {
      name     = "appgw-demo-cert"
      data     = pkcs12_from_pem.appgw.result
      password = "AzureDemo123!"
    }
  }
  ssl_policy = {
    policy_type          = "Custom"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
    ]
  }
  tags  = var.tags
  zones = local.zones
}

# Read the public IP to expose its current address
data "azurerm_public_ip" "pip" {
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name

  depends_on = [module.appgw_pip]
}
