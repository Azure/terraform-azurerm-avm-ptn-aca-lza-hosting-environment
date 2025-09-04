Application Gateway (AVM-based)

This submodule provisions an Azure Application Gateway with:
- A new Standard static Public IP (zones optional)
- A User-Assigned Managed Identity to read Key Vault secrets
- WAF_v2 policy (Prevention, OWASP 3.2 + BotManager)
- HTTPS listener on 443, certificate sourced from Key Vault secret
- Optional backend FQDN with HTTPS settings and a health probe
- Diagnostic settings to Log Analytics (optional)

Inputs
- name, resource_group_name, location, tags, enable_telemetry
- subnet_id
- public_ip_name
- user_assigned_identity_name
- application_gateway_fqdn (optional)
- backend_fqdn (optional)
- backend_probe_path (default "/")
- base64_certificate (optional)
- certificate_key_name
- key_vault_id (required; pass the Key Vault ID output from supporting_services)
- log_analytics_workspace_id (optional)
- deploy_zone_redundant_resources (default true)
- enable_ddos_protection (default false)

Outputs
- id: Application Gateway resource ID
- public_ip_address: frontend public IP address
- fqdn: the provided FQDN (input)

Notes
- If base64_certificate is provided, it is written as a secret to the provided Key Vault, and the UAI is granted Key Vault Secrets User on that secret.
- If base64_certificate is empty, the module expects the secret to already exist (certificate_key_name) in the given Key Vault.
- The module returns the PIP address from the created PIP when available; a data lookup is used as fallback.
- This mirrors the Bicep approach but omits the deployment script-based self-signed generation for now.
