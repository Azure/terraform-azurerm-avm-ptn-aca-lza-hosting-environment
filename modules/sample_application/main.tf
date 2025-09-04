terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
  }
}

# Azure Container App using AVM module
module "app" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "~> 0.7"

  enable_telemetry    = var.enable_telemetry
  name                = var.name
  resource_group_name = var.resource_group_name

  container_app_environment_resource_id = var.container_app_environment_resource_id
  workload_profile_name                 = var.workload_profile_name

  # Assign UAI used for ACR pulls
  managed_identities = {
    user_assigned_resource_ids = [var.container_registry_user_assigned_identity_id]
  }

  # Simple hello world image, externally exposed as in Bicep sample
  template = {
    containers = [
      {
        name   = "simple-hello"
        image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
        cpu    = 0.25
        memory = "0.5Gi"
      }
    ]
    min_replicas = 2
    max_replicas = 10
  }

  revision_mode = "Single"

  ingress = {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 80
    transport                  = "auto"
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  tags = var.tags
}
