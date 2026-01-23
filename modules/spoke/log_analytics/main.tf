###############################################
# Log Analytics Workspace via AzAPI (parity) #
###############################################

# Build the ARM payload for the workspace with replication (2025-02-01 API)
locals {
  base_properties = {
    sku = {
      name = var.sku
    }
    retentionInDays = var.retention_in_days
    features = {
      searchVersion = "2"
    }
  }

  replication_block = var.replication_enabled && local.effective_replication_location != null ? {
    replication = {
      enabled  = true
      location = local.effective_replication_location
    }
  } : {}

  workspace_properties = merge(local.base_properties, local.replication_block)
}

resource "azapi_resource" "workspace" {
  type      = "Microsoft.OperationalInsights/workspaces@2025-02-01"
  name      = var.name
  location  = var.location
  parent_id = var.resource_group_id
  tags      = var.tags

  body = {
    properties = local.workspace_properties
  }

  response_export_values = ["id", "name", "properties.customerId"]
  lifecycle {
    ignore_changes = [body.properties.features.searchVersion]

  }
}
