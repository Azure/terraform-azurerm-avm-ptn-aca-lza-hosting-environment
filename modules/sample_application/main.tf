# Azure Container App using AVM module
module "app" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.7.4"

  container_app_environment_resource_id = var.container_app_environment_resource_id
  name                                  = var.name
  resource_group_name                   = var.resource_group_name
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
  enable_telemetry = var.enable_telemetry
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
  # Assign UAI used for ACR pulls
  managed_identities = {
    user_assigned_resource_ids = [var.container_registry_user_assigned_identity_id]
  }
  revision_mode         = "Single"
  tags                  = var.tags
  workload_profile_name = var.workload_profile_name
}
