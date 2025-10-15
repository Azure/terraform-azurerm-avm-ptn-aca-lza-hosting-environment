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
}

# Disable replication before destroy to avoid deletion errors
# Azure requires replication to be disabled before a workspace can be deleted.
# This null_resource uses a destroy-time provisioner to make an Azure REST API call
# that disables replication, then waits 30 seconds for the change to propagate.
# The || true ensures the destroy continues even if the API call fails (e.g., if already disabled).
# Note: Requires Azure CLI (az) to be installed and authenticated.
resource "null_resource" "disable_replication_on_destroy" {
  count = var.replication_enabled ? 1 : 0

  triggers = {
    workspace_id = azapi_resource.workspace.id
    location     = var.location
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Disabling Log Analytics workspace replication before deletion..."
      if command -v az &> /dev/null; then
        az rest --method PUT \
          --url "${self.triggers.workspace_id}?api-version=2025-02-01" \
          --body '{"properties": {"replication": {"enabled": false}}, "location": "${self.triggers.location}"}' \
          && echo "Waiting 30 seconds for replication to disable..." \
          && sleep 30 \
          || echo "Warning: Failed to disable replication via Azure CLI, continuing with destroy..."
      else
        echo "Warning: Azure CLI (az) not found. Skipping replication disable step."
        echo "If workspace deletion fails, manually disable replication using Azure Portal or REST API."
      fi
    EOT
  }
}

output "id" {
  value       = azapi_resource.workspace.id
  description = "Resource ID of the Log Analytics Workspace"
}

output "name" {
  value       = azapi_resource.workspace.name
  description = "Name of the Log Analytics Workspace"
}

output "workspace_id" {
  value       = try(azapi_resource.workspace.output.properties.customerId, null)
  description = "Workspace (customer) ID"
}
