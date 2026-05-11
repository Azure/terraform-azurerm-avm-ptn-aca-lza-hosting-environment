# terraform-azurerm-avm-ptn-aca-lza-hosting-environment

This pattern module creates a full Azure Container Apps (ACA) landing zone hosting environment with hub-spoke networking, supporting secure container application deployment scenarios. The module provisions the complete infrastructure including virtual networks, subnets, Azure Container Apps Environment, supporting services (Key Vault, Log Analytics, Application Insights), and optional components like Application Gateway, Azure Front Door, Azure Bastion, and jumpbox VMs for secure access.

## DDoS protection options

Use `ddos_protection_mode` to choose how DDoS protection is handled:

- `none`: no DDoS feature is configured by this module.
- `ip_rules`: enables per-IP protection on the Application Gateway public IP.
- `protection_plan`: associates the spoke virtual network to an existing DDoS Protection Plan using `existing_ddos_protection_plan_id`.

Example (existing plan):

```hcl
ddos_protection_mode             = "protection_plan"
existing_ddos_protection_plan_id = "/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.Network/ddosProtectionPlans/<name>"
```
