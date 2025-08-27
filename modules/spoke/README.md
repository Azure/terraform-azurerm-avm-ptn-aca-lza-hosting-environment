# Spoke Module

This module mirrors the Bicep spoke composition. It orchestrates spoke-level resources using Azure Verified Modules (AVM).

Included submodules (current):
- Log Analytics Workspace (AVM): Azure/avm-res-operationalinsights-workspace/azurerm

Inputs:
- resources_names (map(string)): Naming object; expects key `logAnalyticsWorkspace`.
- location (string): Azure region.
- resource_group_name (string): Target resource group name.
- tags (map(string)): Resource tags.
- enable_telemetry (bool): Toggle AVM telemetry.

Outputs:
- log_analytics_workspace_id
- log_analytics_workspace_name

More spoke resources (NSGs, VNet, routes, jumpbox) will be added incrementally as separate AVM modules.
