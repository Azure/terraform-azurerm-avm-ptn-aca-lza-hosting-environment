###############################################
# Front Door module: main implementation     #
###############################################
# This module creates a Front Door with the default *.azurefd.net endpoint
# which uses Microsoft-managed certificates automatically

# WAF Policy (if enabled and Premium SKU)
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  count = var.enable_waf ? 1 : 0

  mode                = "Detection"
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  enabled             = true
  tags                = var.tags

  managed_rule {
    action  = "Block"
    type    = "DefaultRuleSet"
    version = "1.0"
  }
  managed_rule {
    action  = "Block"
    type    = "BotProtection"
    version = "preview-0.1"
  }
}

# Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = 120
  tags                     = var.tags
}

# Front Door Endpoint (uses default *.azurefd.net with Microsoft-managed certificate)
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  name                     = "${var.name}-endpoint"
  enabled                  = true
  tags                     = var.tags
}

# Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.this.id
  name                                                      = "${var.name}-origin-group"
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 5
  session_affinity_enabled                                  = false

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 2
  }
  health_probe {
    interval_in_seconds = 30
    protocol            = var.backend_protocol
    path                = var.backend_probe_path
    request_type        = "HEAD"
  }
}

# Origin (Backend) - Routes to Container Apps Environment
# Always uses Private Link for secure connectivity to internal Container Apps Environment
resource "azurerm_cdn_frontdoor_origin" "this" {
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  certificate_name_check_enabled = false # Disabled for private link origins
  host_name                      = var.backend_fqdn
  name                           = "${var.name}-origin"
  enabled                        = true
  http_port                      = 80
  https_port                     = var.backend_port
  origin_host_header             = var.backend_fqdn
  priority                       = 1
  weight                         = 1000

  # Private Link configuration for Container Apps Environment
  # Required for internal Container Apps Environment connectivity
  private_link {
    location               = var.location
    private_link_target_id = var.container_apps_environment_id
    request_message        = "Front Door Private Link Request for Container Apps"
    target_type            = "managedEnvironments"
  }

  lifecycle {
    precondition {
      condition     = var.sku_name == "Premium_AzureFrontDoor"
      error_message = "Private link integration requires Premium_AzureFrontDoor SKU. Current SKU: ${var.sku_name}"
    }
    precondition {
      condition     = var.container_apps_environment_id != ""
      error_message = "container_apps_environment_id must be provided for Private Link connectivity."
    }
  }
}

# Use null_resource with local-exec to approve the private endpoint connection
# This runs after the origin is created and approves any pending connections
resource "null_resource" "approve_private_endpoint" {
  # Trigger whenever the origin changes
  triggers = {
    origin_id = azurerm_cdn_frontdoor_origin.this.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Get all private endpoint connections for the Container Apps Environment
      connections=$(az rest --method get --url "${var.container_apps_environment_id}?api-version=2024-08-02-preview" --query "properties.privateEndpointConnections[?properties.privateLinkServiceConnectionState.status=='Pending'].name" -o tsv)
      
      # Approve each pending connection
      for conn in $connections; do
        echo "Approving private endpoint connection: $conn"
        az rest --method put \
          --url "${var.container_apps_environment_id}/privateEndpointConnections/$conn?api-version=2024-08-02-preview" \
          --body '{"properties":{"privateLinkServiceConnectionState":{"status":"Approved","description":"Auto-approved by Terraform for Front Door Private Link"}}}'
      done
    EOT
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.this
  ]
}

# Route - Uses the default Front Door endpoint (no custom domain needed)
resource "azurerm_cdn_frontdoor_route" "this" {
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]
  name                          = "${var.name}-route"
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]
  enabled                       = true
  forwarding_protocol           = var.forwarding_protocol
  https_redirect_enabled        = true

  dynamic "cache" {
    for_each = var.caching_enabled ? [1] : []

    content {
      compression_enabled = true
      content_types_to_compress = [
        "application/eot",
        "application/font",
        "application/font-sfnt",
        "application/javascript",
        "application/json",
        "application/opentype",
        "application/otf",
        "application/pkcs7-mime",
        "application/truetype",
        "application/ttf",
        "application/vnd.ms-fontobject",
        "application/xhtml+xml",
        "application/xml",
        "application/xml+rss",
        "application/x-font-opentype",
        "application/x-font-truetype",
        "application/x-font-ttf",
        "application/x-httpd-cgi",
        "application/x-javascript",
        "application/x-mpegurl",
        "application/x-opentype",
        "application/x-otf",
        "application/x-perl",
        "application/x-ttf",
        "font/eot",
        "font/ttf",
        "font/otf",
        "font/opentype",
        "image/svg+xml",
        "text/css",
        "text/csv",
        "text/html",
        "text/javascript",
        "text/js",
        "text/plain",
        "text/richtext",
        "text/tab-separated-values",
        "text/xml",
        "text/x-script",
        "text/x-component",
        "text/x-java-source"
      ]
      query_string_caching_behavior = "IgnoreQueryString"
      query_strings                 = []
    }
  }
}

# Security Policy (WAF Association) - Only for Premium SKU
# Note: WAF policy is associated with the default endpoint, not a custom domain
resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count = var.enable_waf ? 1 : 0

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  name                     = "${var.name}-security-policy"

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[0].id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
      }
    }
  }
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "front_door" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "front-door-diagnostics"
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FrontDoorAccessLog"
  }
  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }
  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

# Module telemetry
resource "azurerm_resource_group_template_deployment" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  deployment_mode     = "Incremental"
  name                = "46d3xbcp.ptn.frontdoor.${random_id.telemetry[0].hex}"
  resource_group_name = var.resource_group_name
  template_content = jsonencode({
    "$schema"        = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    "contentVersion" = "1.0.0.0"
    "resources"      = []
  })
}

resource "random_id" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  byte_length = 4
}
