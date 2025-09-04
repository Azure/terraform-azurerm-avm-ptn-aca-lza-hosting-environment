Supporting services module: provisions ACR, Key Vault, and Storage with private endpoints, private DNS, and diagnostics. Mirrors Bicep deploy.supporting-services.bicep.

Submodules
- container_registry: ACR (Premium, PNA disabled), UAI, private endpoint (registry), private DNS zone link(s), AcrPull role, optional agent pool via AzAPI, diagnostics.
- key_vault: KV (RBAC, public disabled), private endpoint (vault), private DNS zone link(s), diagnostics.
- storage: StorageV2 ZRS, private endpoint (file), private DNS zone link(s), optional file shares, diagnostics.

Notes
- Uses AzureRM resources; AzAPI only for ACR agent pool (preview). Toggle via variable.
- For security, storage account keys are not exported to Key Vault to avoid secrets in state.

Docs consulted
- AzureRM: container_registry, key_vault, storage_account, private_endpoint, private_dns_zone, monitor_diagnostic_setting, role_assignment.
