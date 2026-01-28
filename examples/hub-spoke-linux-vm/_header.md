# Hub-Spoke with Linux VM

This example demonstrates the most complex hub-spoke networking scenario with a Linux virtual machine and full observability stack.

## Deployment Notes

⚠️ **Important**: This example creates the hub VNet and network appliance in the same Terraform configuration as the spoke resources. Due to Terraform limitations with `count` and computed values, you must deploy in two phases:

**Phase 1 - Create Hub Resources:**
```bash
terraform apply -target=azurerm_virtual_network.hub -target=azurerm_public_ip.firewall
```

**Phase 2 - Deploy Everything Else:**
```bash
terraform apply
```

**Note**: The module uses `enable_hub_peering = true` to solve Private DNS zone `for_each` issues, but route table and SSH key generation still require two-phase deployment when network appliance IP is computed.

For production deployments, we recommend separating hub and spoke infrastructure into different Terraform workspaces. See [DEPLOYMENT_GUIDANCE.md](../../DEPLOYMENT_GUIDANCE.md) for more details and alternative approaches.
