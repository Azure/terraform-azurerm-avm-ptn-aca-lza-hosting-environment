# Container Apps Environment (Terraform module)

This module provisions an Azure Container Apps Managed Environment, optionally deploys Application Insights, and configures a Private DNS zone for the environment's default domain with wildcard A record and VNet links.

It mirrors the behaviors used in the Bicep `deploy.aca-environment.bicep` implementation while following AVM Terraform best practices.

## Resources
- AVM app managed environment (`Azure/avm-res-app-managedenvironment/azurerm`)
- AVM Application Insights (`Azure/avm-res-insights-component/azurerm`) [optional]
- AVM Private DNS zone (`Azure/avm-res-network-privatednszone/azurerm`)

## Inputs
See `variables.tf` for all inputs. Key ones:
- name, resource_group_name, location, tags, enable_telemetry
- infrastructure_subnet_id (delegated to Microsoft.App/environments)
- log_analytics_workspace_id
- spoke_virtual_network_id, hub_virtual_network_id (optional)
 - container_apps_environment_storages
- enable_application_insights and enable_dapr_instrumentation
- deploy_zone_redundant_resources
- container_registry_user_assigned_identity_id

## Outputs
- managed_environment_id, managed_environment_name
- application_insights_name
- default_domain, static_ip_address
- private_dns_zone_id, private_dns_zone_name
- workload_profile_names (set to ["general-purpose"])

Notes:
- `container_apps_environment_storages` is marked sensitive to hide access keys in plans.
- When both Application Insights and Dapr instrumentation are enabled, the module wires the AI connection string into the Managed Environment for Dapr telemetry.
