# Manual Testing Plan for ACA LZA Hosting Environment Module

## Overview

This document outlines the comprehensive manual testing plan required before creating a PR for the Azure Container Apps Landing Zone Accelerator (ACA LZA) Hosting Environment module. The testing validates all major deployment scenarios, features, and edge cases.

## Pre-Testing Requirements

### Prerequisites

1. **Azure Subscription**: Access to an Azure subscription with appropriate permissions
2. **Terraform**: Version >= 1.9, < 2.0
3. **Azure CLI**: Latest version installed and authenticated
4. **Test Environment**: Dedicated resource group(s) for testing
5. **AVM Tools**: Ensure `./avm` script is executable and working
6. **Environment Variables**: Set sensitive values (passwords, keys) via environment variables

### Pre-Test Validation

Before starting manual testing, run local validation:

```bash
# Set environment variable to disable TUI
export PORCH_NO_TUI=1

# Format all code
terraform fmt -recursive

# Run AVM pre-commit checks
./avm pre-commit

# Commit any changes
git add .
git commit -m "chore: avm pre-commit"

# Run AVM PR checks
./avm pr-check
```

**⚠️ CRITICAL**: All validation steps must pass before proceeding with manual testing.

---

## Testing Scenarios

The module has **8 primary examples** covering different deployment patterns. We'll test them in order of complexity, from simplest to most complex.

### Priority Levels

- 🔴 **P0 - Critical**: MUST test before PR (required for basic functionality)
- 🟡 **P1 - High**: SHOULD test before PR (important features)
- 🟢 **P2 - Medium**: CAN test after PR (nice-to-have validation)

---

## Test Plan Matrix

| Example | Priority | Complexity | Est. Time | Azure Cost |
|---------|----------|------------|-----------|------------|
| 1. Minimal Configuration | 🔴 P0 | Low | 15-20 min | $ |
| 2. Default | 🔴 P0 | Low | 20-25 min | $$ |
| 3. Front Door Standard | 🟡 P1 | Medium | 25-30 min | $$$ |
| 4. Smoke Spoke | 🟡 P1 | Medium | 20-25 min | $$ |
| 5. Windows VM Custom Cert | 🟡 P1 | Medium | 30-35 min | $$$ |
| 6. Hub-Spoke Linux VM | 🟡 P1 | High | 35-40 min | $$$$ |
| 7. Bastion Zone Redundant | 🟢 P2 | High | 40-50 min | $$$$$ |
| 8. Complex Network Appliance | 🟢 P2 | Very High | 45-60 min | $$$$$ |

**Total Estimated Testing Time**: 4-6 hours (excluding cleanup)

---

## Detailed Test Procedures

### Test 1: Minimal Configuration 🔴 P0

**Objective**: Validate the absolute minimum viable configuration with all optional features disabled.

**Features Being Tested**:
- ✅ Minimal network address spaces
- ✅ No VM deployment
- ✅ No Application Gateway (`expose_container_apps_with = "none"`)
- ✅ No observability (Application Insights disabled)
- ✅ Single-zone deployment
- ✅ Isolated spoke (no hub integration)
- ✅ No sample application

**Test Steps**:

```bash
cd examples/minimal-configuration

# Initialize Terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Wait for completion (~15-20 minutes)
```

**Validation Checklist**:

- [x] Terraform applies without errors
- [x] Resource group created successfully
- [x] Container Apps Environment deployed
- [x] Container Registry deployed
- [x] Log Analytics Workspace created (basic)
- [x] Key Vault deployed
- [x] Storage Account created
- [x] Spoke VNet with minimal subnets deployed
- [x] No Application Gateway deployed
- [x] No VM deployed
- [x] No Application Insights deployed
- [x] No sample application deployed

**Expected Outputs**:

```bash
# Verify outputs
terraform output

# Should show:
# - container_apps_environment_id
# - container_registry_id
# - log_analytics_workspace_id
# - resource_group_name
```

**Azure Portal Validation**:

1. Navigate to the resource group
2. Verify resource count matches expected (no App Gateway, no VM, no App Insights)
3. Check Container Apps Environment status (should be "Running")
4. Verify VNet has minimal subnets (no AGW subnet in use)

**Cleanup**:

```bash
terraform destroy -auto-approve
```

---

### Test 2: Default 🔴 P0

**Objective**: Validate standard deployment with Application Gateway but no VM.

**Features Being Tested**:
- ✅ Application Gateway deployment
- ✅ Sample application deployment
- ✅ No observability (Application Insights disabled)
- ✅ Standard networking
- ✅ No VM deployment
- ✅ Using module created resource group

**Test Steps**:

```bash
cd ../default

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Wait for completion (~20-25 minutes)
```

**Validation Checklist**:

- [ ] All resources from minimal test PLUS:
- [ ] Application Gateway deployed
- [ ] Application Gateway has public IP
- [ ] Sample Container App deployed
- [ ] Container App accessible via Application Gateway
- [ ] Backend health probe is healthy

**Expected Outputs**:

```bash
terraform output

# Should include:
# - application_gateway_id
# - application_gateway_public_ip
# - sample_app_fqdn
# - sample_app_id
```

**Functional Testing**:

```bash
# Get Application Gateway public IP
APP_GW_IP=$(terraform output -raw application_gateway_public_ip)

# Test HTTP access to sample app (may take a few minutes for backend to be healthy)
curl -H "Host: example.com" http://$APP_GW_IP/

# Should return HTML response from sample app
```

**Azure Portal Validation**:

1. Navigate to Application Gateway
2. Check Backend Health (should show healthy)
3. Verify Backend Pools configured correctly
4. Check HTTP Settings
5. Navigate to Container App
6. Verify app is running
7. Check ingress configuration

**Cleanup**:

```bash
terraform destroy -auto-approve
```

---

### Test 3: Front Door Standard 🟡 P1

**Objective**: Validate Front Door as alternative ingress with global load balancing.

**Features Being Tested**:
- ✅ Azure Front Door Standard SKU
- ✅ Custom domain configuration
- ✅ TLS certificate from Key Vault
- ✅ No Application Gateway (Front Door replaces it)
- ✅ Sample application deployment
- ✅ Simplified networking

**Test Steps**:

```bash
cd ../front-door-standard

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Wait for completion (~25-30 minutes)
```

**Validation Checklist**:

- [ ] Front Door profile deployed
- [ ] Front Door endpoint created with *.azurefd.net hostname
- [ ] Front Door origin group configured
- [ ] Origin pointing to Container App
- [ ] Route configured for HTTP(S) traffic
- [ ] No Application Gateway deployed
- [ ] Sample Container App deployed and running
- [ ] TLS certificate in Key Vault (if custom domain used)

**Expected Outputs**:

```bash
terraform output

# Should include:
# - front_door_id
# - front_door_endpoint_hostname
# - sample_app_id
# - sample_app_fqdn
```

**Functional Testing**:

```bash
# Get Front Door endpoint hostname
FD_HOSTNAME=$(terraform output -raw front_door_endpoint_hostname)

# Test access via Front Door (may take several minutes to provision)
curl https://$FD_HOSTNAME/

# Should return response from sample app
```

**Azure Portal Validation**:

1. Navigate to Front Door profile
2. Check endpoint status (should be "Enabled")
3. Verify origin group health
4. Check origin health status
5. Review route configuration
6. Test endpoint in browser
7. Verify TLS certificate if custom domain configured

**Cleanup**:

```bash
terraform destroy -auto-approve
```

---


### Test 4: Windows VM Custom Cert 🟡 P1

**Objective**: Validate Windows VM deployment with custom certificate management.

**Features Being Tested**:
- ✅ Windows VM with password authentication
- ✅ Custom TLS certificate generation
- ✅ Certificate stored in Key Vault
- ✅ Module-managed resource group creation
- ✅ No Application Gateway
- ✅ Single-zone deployment

**Test Steps**:

```bash
cd ../windows-vm-custom-cert

# Set VM password as environment variable
export TF_VAR_vm_admin_password="YourSecurePassword123!"

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Wait for completion (~30-35 minutes)
```

**Validation Checklist**:

- [ ] Resource group created by module
- [ ] Windows VM deployed successfully
- [ ] VM has correct size and configuration
- [ ] VM network interface attached to correct subnet
- [ ] Custom certificate generated
- [ ] Certificate stored in Key Vault
- [ ] Container Apps Environment deployed
- [ ] No Application Gateway deployed

**Expected Outputs**:

```bash
terraform output

# Should include VM-related outputs and certificate details
```

**Azure Portal Validation**:

1. Navigate to the Windows VM
2. Verify VM is running
3. Check VM configuration (size, OS, disks)
4. Navigate to Key Vault
5. Verify custom certificate stored
6. Check certificate properties
7. Verify VM can connect to Container Apps subnet (network connectivity)

**Security Validation**:

- [ ] VM admin password properly secured
- [ ] Certificate has appropriate expiration
- [ ] Key Vault access policies configured correctly
- [ ] VM has no public IP (if not intended)

**Cleanup**:

```bash
terraform destroy -auto-approve
unset TF_VAR_vm_admin_password
```

---

### Test 5: Hub-Spoke Linux VM 🟡 P1

**Objective**: Validate enterprise hub-spoke topology with Linux jumpbox and comprehensive observability.

**Features Being Tested**:
- ✅ Hub-spoke network integration
- ✅ Virtual network peering
- ✅ Linux VM with SSH key authentication
- ✅ Network traffic routing through network appliance
- ✅ Application Insights enabled
- ✅ Dapr instrumentation enabled
- ✅ Zone-redundant deployment
- ✅ Application Gateway

**Prerequisites**:

Create a hub virtual network for testing (or use existing):

```bash
# Create hub VNet in separate resource group for testing
az group create --name rg-hub-test --location eastus

az network vnet create \
  --resource-group rg-hub-test \
  --name vnet-hub-test \
  --address-prefix 10.0.0.0/16

# Get hub VNet resource ID
HUB_VNET_ID=$(az network vnet show \
  --resource-group rg-hub-test \
  --name vnet-hub-test \
  --query id -o tsv)
```

**Test Steps**:

```bash
cd ../hub-spoke-linux-vm

# Generate SSH key if not exists
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aca_lza_test -N ""

# Set environment variables
export TF_VAR_vm_linux_ssh_authorized_key="$(cat ~/.ssh/aca_lza_test.pub)"
export TF_VAR_hub_virtual_network_resource_id="$HUB_VNET_ID"
export TF_VAR_vm_admin_password="NotUsed123!" # Required but not used with SSH

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Wait for completion (~35-40 minutes)
```

**Validation Checklist**:

- [ ] Hub-spoke peering established
- [ ] Both peering links in "Connected" state
- [ ] Linux VM deployed successfully
- [ ] SSH key authentication configured
- [ ] Application Insights deployed
- [ ] Dapr instrumentation enabled
- [ ] Zone-redundant resources deployed across AZs
- [ ] Route table configured for network appliance
- [ ] User-defined routes applied
- [ ] Application Gateway deployed
- [ ] Sample app deployed

**Expected Outputs**:

```bash
terraform output

# Should include all outputs plus observability details
```

**Network Validation**:

```bash
# Check VNet peering status
az network vnet peering list \
  --resource-group <spoke-rg> \
  --vnet-name <spoke-vnet> \
  --output table

# Should show peering to hub with "Connected" status
```

**Functional Testing**:

```bash
# Get VM details
VM_NAME=$(terraform output -raw vm_name)
RG_NAME=$(terraform output -raw resource_group_name)

# Attempt SSH connection (requires appropriate network setup)
# May need bastion or VPN for actual connectivity
ssh -i ~/.ssh/aca_lza_test azureuser@<VM_PRIVATE_IP>
```

**Azure Portal Validation**:

1. Navigate to spoke VNet
2. Check peerings (should show hub peering as "Connected")
3. Navigate to Linux VM
4. Verify VM is running
5. Check SSH public key configured
6. Navigate to Application Insights
7. Verify Application Insights is collecting data
8. Check Dapr components in Container Apps Environment
9. Verify zone redundancy on applicable resources
10. Check route tables and UDRs

**Cleanup**:

```bash
terraform destroy -auto-approve

# Clean up hub VNet
az group delete --name rg-hub-test --yes --no-wait

# Clean up SSH keys
rm ~/.ssh/aca_lza_test*
```

---

### Test 6: Bastion Zone Redundant 🟢 P2

**Objective**: Validate the most secure connectivity pattern with Azure Bastion and full zone redundancy.

**Features Being Tested**:
- ✅ Azure Bastion deployment
- ✅ Bastion advanced features (tunneling, file copy, shareable links)
- ✅ Zone redundancy across all resources
- ✅ Secure VM access without public IPs
- ✅ Complete observability stack
- ✅ All optional features enabled
- ✅ Hub-spoke integration

**Prerequisites**:

```bash
# Create hub VNet with Bastion subnet
az group create --name rg-hub-bastion-test --location eastus

az network vnet create \
  --resource-group rg-hub-bastion-test \
  --name vnet-hub-bastion \
  --address-prefix 10.100.0.0/16

# Bastion requires a subnet named "AzureBastionSubnet" with minimum /26
az network vnet subnet create \
  --resource-group rg-hub-bastion-test \
  --vnet-name vnet-hub-bastion \
  --name AzureBastionSubnet \
  --address-prefix 10.100.255.0/26

# Create Bastion host
az network bastion create \
  --resource-group rg-hub-bastion-test \
  --name bastion-hub-test \
  --vnet-name vnet-hub-bastion \
  --location eastus \
  --sku Standard \
  --enable-tunneling true

# Get Bastion and hub VNet resource IDs
BASTION_ID=$(az network bastion show \
  --resource-group rg-hub-bastion-test \
  --name bastion-hub-test \
  --query id -o tsv)

HUB_VNET_ID=$(az network vnet show \
  --resource-group rg-hub-bastion-test \
  --name vnet-hub-bastion \
  --query id -o tsv)
```

**Test Steps**:

```bash
cd ../bastion-zone-redundant

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aca_lza_bastion_test -N ""

# Set environment variables
export TF_VAR_vm_linux_ssh_authorized_key="$(cat ~/.ssh/aca_lza_bastion_test.pub)"
export TF_VAR_bastion_resource_id="$BASTION_ID"
export TF_VAR_hub_virtual_network_resource_id="$HUB_VNET_ID"
export TF_VAR_vm_admin_password="NotUsed123!"

# Initialize
terraform init

# Plan (review zone redundancy settings)
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Wait for completion (~40-50 minutes - zone redundant resources take longer)
```

**Validation Checklist**:

- [ ] All resources from hub-spoke test PLUS:
- [ ] Bastion connectivity configured
- [ ] All zone-redundant resources deployed across 3 AZs:
  - [ ] Application Gateway (if using)
  - [ ] Container Apps Environment
  - [ ] Other zone-capable resources
- [ ] VM has no public IP
- [ ] VNet peering to hub established
- [ ] All observability features enabled
- [ ] All security features enabled

**Expected Outputs**:

```bash
terraform output

# Verify all outputs including zone redundancy details
```

**Zone Redundancy Validation**:

```bash
# Check Application Gateway zones (if deployed)
az network application-gateway show \
  --resource-group <rg-name> \
  --name <appgw-name> \
  --query zones -o table

# Should show: ["1", "2", "3"]

# Check Container Apps Environment
az containerapp env show \
  --resource-group <rg-name> \
  --name <env-name> \
  --query properties.zoneRedundant -o tsv

# Should show: true
```

**Bastion Connectivity Testing**:

```bash
# Get VM details
VM_NAME=$(terraform output -raw vm_name)
RG_NAME=$(terraform output -raw resource_group_name)
VM_ID=$(az vm show --resource-group $RG_NAME --name $VM_NAME --query id -o tsv)

# Test Bastion tunnel (requires Azure CLI with Bastion extension)
az network bastion tunnel \
  --resource-group rg-hub-bastion-test \
  --name bastion-hub-test \
  --target-resource-id $VM_ID \
  --resource-port 22 \
  --port 2222

# In another terminal, connect via SSH through tunnel
ssh -i ~/.ssh/aca_lza_bastion_test azureuser@localhost -p 2222
```

**Azure Portal Validation**:

1. Navigate to all major resources
2. Verify zone configuration shows zones 1, 2, 3
3. Check Application Gateway backend health
4. Verify Bastion can connect to VM via portal
5. Test Bastion features:
   - SSH via Bastion portal
   - File upload/download (if enabled)
   - Shareable link creation (if enabled)
6. Review Application Insights data
7. Check all monitoring dashboards

**Cleanup**:

```bash
terraform destroy -auto-approve

# Clean up hub infrastructure
az group delete --name rg-hub-bastion-test --yes --no-wait

# Clean up SSH keys
rm ~/.ssh/aca_lza_bastion_test*
```

---

### Test 7: Complex Network Appliance 🟢 P2

**Objective**: Validate enterprise-grade deployment with Azure Firewall and comprehensive traffic control.

**Features Being Tested**:
- ✅ Azure Firewall as network virtual appliance
- ✅ Zone-redundant firewall
- ✅ Custom firewall policies and rules
- ✅ User-defined routes for traffic control
- ✅ Premium storage and performance
- ✅ Enterprise naming conventions
- ✅ Complete feature set enabled

**Prerequisites**:

```bash
# Create hub VNet with Azure Firewall
az group create --name rg-hub-firewall-test --location eastus

az network vnet create \
  --resource-group rg-hub-firewall-test \
  --name vnet-hub-firewall \
  --address-prefix 10.200.0.0/16

# Create Azure Firewall subnet (must be named "AzureFirewallSubnet")
az network vnet subnet create \
  --resource-group rg-hub-firewall-test \
  --vnet-name vnet-hub-firewall \
  --name AzureFirewallSubnet \
  --address-prefix 10.200.255.0/26

# Create Azure Firewall (takes 5-10 minutes)
az network firewall create \
  --resource-group rg-hub-firewall-test \
  --name fw-hub-test \
  --location eastus \
  --tier Standard

# Create public IP for firewall
az network public-ip create \
  --resource-group rg-hub-firewall-test \
  --name pip-fw-hub \
  --location eastus \
  --sku Standard \
  --allocation-method Static

# Configure firewall IP configuration
az network firewall ip-config create \
  --resource-group rg-hub-firewall-test \
  --firewall-name fw-hub-test \
  --name fw-config \
  --public-ip-address pip-fw-hub \
  --vnet-name vnet-hub-firewall

# Get firewall private IP
FW_PRIVATE_IP=$(az network firewall show \
  --resource-group rg-hub-firewall-test \
  --name fw-hub-test \
  --query ipConfigurations[0].privateIPAddress -o tsv)

# Get hub VNet resource ID
HUB_VNET_ID=$(az network vnet show \
  --resource-group rg-hub-firewall-test \
  --name vnet-hub-firewall \
  --query id -o tsv)
```

**Test Steps**:

```bash
cd ../complex-network-appliance

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aca_lza_complex_test -N ""

# Set environment variables
export TF_VAR_vm_linux_ssh_authorized_key="$(cat ~/.ssh/aca_lza_complex_test.pub)"
export TF_VAR_hub_virtual_network_resource_id="$HUB_VNET_ID"
export TF_VAR_network_appliance_ip_address="$FW_PRIVATE_IP"
export TF_VAR_vm_admin_password="NotUsed123!"

# Initialize
terraform init

# Plan (review complex routing configuration)
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Wait for completion (~45-60 minutes - most complex scenario)
```

**Validation Checklist**:

- [ ] Hub-spoke peering with firewall routing
- [ ] Route tables created with firewall as next hop
- [ ] All egress traffic routed through firewall
- [ ] Firewall rules allowing required traffic
- [ ] Zone-redundant deployment
- [ ] Premium storage configured
- [ ] All features enabled
- [ ] Enterprise naming conventions applied
- [ ] Complete monitoring stack
- [ ] Network appliance routing validated

**Expected Outputs**:

```bash
terraform output

# Verify all outputs including routing details
```

**Routing Validation**:

```bash
# Check route tables
az network route-table list \
  --resource-group <spoke-rg> \
  --output table

# Check specific routes
az network route-table route list \
  --resource-group <spoke-rg> \
  --route-table-name <route-table-name> \
  --output table

# Verify next hop is firewall IP
```

**Firewall Validation**:

```bash
# Check firewall rules
az network firewall show \
  --resource-group rg-hub-firewall-test \
  --name fw-hub-test

# Review firewall logs (may need to enable diagnostic settings)
az monitor activity-log list \
  --resource-id <firewall-resource-id> \
  --output table
```

**Network Flow Testing**:

```bash
# From within the environment (if VM deployed), test connectivity
# This validates that traffic flows through the firewall

# Test outbound connectivity
curl -v https://www.microsoft.com

# Check if traffic appears in firewall logs
```

**Azure Portal Validation**:

1. Navigate to Azure Firewall
2. Review firewall rules and policies
3. Check firewall metrics and logs
4. Navigate to route tables
5. Verify routes pointing to firewall
6. Check effective routes on VM NIC
7. Validate Application Gateway backend health
8. Review complete architecture diagram in portal
9. Verify all zone redundancy settings
10. Check all monitoring and observability features

**Performance Validation**:

- [ ] Check Application Gateway performance metrics
- [ ] Review Container Apps scaling behavior
- [ ] Validate firewall throughput
- [ ] Monitor latency through firewall

**Cleanup**:

```bash
terraform destroy -auto-approve

# Clean up hub firewall infrastructure (can take 10+ minutes)
az group delete --name rg-hub-firewall-test --yes --no-wait

# Clean up SSH keys
rm ~/.ssh/aca_lza_complex_test*
```

---

## Cross-Cutting Validation

After completing the scenario tests, perform these general validations:

### 1. Documentation Accuracy

- [ ] README.md examples match actual code
- [ ] Variable descriptions are accurate
- [ ] Output descriptions match actual outputs
- [ ] Example READMEs match example code

### 2. Code Quality

```bash
# Run from repository root
cd /home/sam/repos/terraform-azurerm-avm-ptn-aca-lza-hosting-environment

# Format check
terraform fmt -recursive -check

# Validate all examples
for example in examples/*/; do
  echo "Validating $example"
  cd "$example"
  terraform init -backend=false
  terraform validate
  cd ../..
done
```

### 3. Security Validation

- [ ] No hardcoded secrets in code
- [ ] Sensitive outputs properly marked
- [ ] Key Vault properly secured
- [ ] Network security groups configured correctly
- [ ] Private endpoints used where appropriate
- [ ] Managed identities used instead of keys where possible

### 4. AVM Compliance

```bash
# Final AVM validation
export PORCH_NO_TUI=1
./avm pre-commit
./avm pr-check
```

### 5. Cost Optimization Check

Review each deployed scenario for cost optimization opportunities:

- [ ] Appropriate SKUs selected
- [ ] Zone redundancy only where needed
- [ ] Resources properly sized
- [ ] Unnecessary resources not deployed

---

## Testing Matrix Summary

Use this checklist to track your testing progress:

### P0 - Critical (Must Complete Before PR)

- [ ] **Test 1**: Minimal Configuration - PASSED / FAILED
- [ ] **Test 2**: Default - PASSED / FAILED

### P1 - High Priority (Should Complete Before PR)

- [ ] **Test 3**: Front Door Standard - PASSED / FAILED
- [ ] **Test 4**: Smoke Spoke - PASSED / FAILED
- [ ] **Test 5**: Windows VM Custom Cert - PASSED / FAILED
- [ ] **Test 6**: Hub-Spoke Linux VM - PASSED / FAILED

### P2 - Medium Priority (Can Complete After PR)

- [ ] **Test 7**: Bastion Zone Redundant - PASSED / FAILED
- [ ] **Test 8**: Complex Network Appliance - PASSED / FAILED

### Cross-Cutting Validations

- [ ] Documentation accuracy validated
- [ ] Code quality checks passed
- [ ] Security validation completed
- [ ] AVM compliance verified
- [ ] Cost optimization reviewed

---

## Issue Tracking

Use this section to track any issues found during testing:

### Issues Found

| Test | Issue Description | Severity | Status | Resolution |
|------|------------------|----------|--------|------------|
| | | | | |

**Severity Levels**:
- 🔴 Critical: Blocks deployment
- 🟡 High: Major functionality broken
- 🟢 Medium: Minor issue or improvement
- 🔵 Low: Cosmetic or documentation

---

## Cost Management

### Estimated Total Testing Cost

Based on ~4-6 hours of testing with all scenarios:

- Minimal Configuration: ~$5
- Default: ~$10
- Front Door: ~$15
- Smoke Spoke: ~$8
- Windows VM: ~$12
- Hub-Spoke Linux: ~$20
- Bastion Zone Redundant: ~$35
- Complex Network Appliance: ~$40

**Total Estimated Cost**: $145-$175 (assuming prompt cleanup)

### Cost Saving Tips

1. **Test in sequence**: Deploy → validate → destroy immediately
2. **Use cheaper regions**: East US, West US 2 typically cheaper
3. **Avoid keeping resources overnight**: Set reminders to destroy
4. **Test P0 first**: If P0 tests fail, fix before expensive P2 tests
5. **Parallel testing**: If budget allows, run independent tests in parallel

---

## Post-Testing Tasks

After completing testing:

### 1. Final Code Review

```bash
# Ensure all changes committed
git status

# Review all changes
git diff main

# Final format
terraform fmt -recursive
```

### 2. Final AVM Validation

```bash
export PORCH_NO_TUI=1
./avm pre-commit
git add .
git commit -m "chore: final pre-commit updates"
./avm pr-check
```

### 3. Documentation Updates

- [ ] Update CHANGELOG.md (if exists)
- [ ] Update examples README if needed
- [ ] Ensure all terraform-docs are current
- [ ] Add any testing notes to documentation

### 4. Create PR

```bash
# Push changes
git push origin sam-cogan/initial-module-creation

# Create PR via GitHub UI with:
# - Descriptive title
# - Link to testing results
# - Note any known issues
# - Request appropriate reviewers
```

---

## Troubleshooting Common Issues

### Issue: Terraform Apply Fails with Subnet Size Error

**Solution**: Ensure subnet CIDR blocks are large enough:
- Container Apps Infrastructure subnet: minimum /27
- Application Gateway subnet: minimum /28
- Private Endpoints subnet: /28 recommended

### Issue: Application Gateway Backend Unhealthy

**Solution**:
1. Check Container App is running
2. Verify health probe configuration
3. Wait 5-10 minutes for backends to become healthy
4. Check NSG rules aren't blocking traffic

### Issue: VNet Peering Fails

**Solution**:
1. Ensure hub VNet exists and is accessible
2. Check RBAC permissions for peering
3. Verify address spaces don't overlap
4. Ensure no conflicting route tables

### Issue: Bastion Connection Fails

**Solution**:
1. Verify Bastion is fully provisioned (takes ~10 minutes)
2. Check VM is in "Running" state
3. Ensure VNet peering is "Connected"
4. Verify VM has network connectivity to Bastion subnet

### Issue: Azure Firewall Blocking Traffic

**Solution**:
1. Add appropriate application rules
2. Add network rules for required ports
3. Check firewall logs for denied traffic
4. Verify route table next hop is correct

### Issue: High Deployment Time

**Solution**:
- Zone redundant resources take longer (~2x)
- Application Gateway takes 10-15 minutes
- Azure Firewall takes 10-15 minutes
- Bastion takes 10-15 minutes
- Be patient and monitor Azure portal for progress

---

## Success Criteria

Testing is considered complete and successful when:

1. ✅ All P0 tests pass without errors
2. ✅ At least 75% of P1 tests pass
3. ✅ No critical security issues found
4. ✅ All AVM validation checks pass
5. ✅ Documentation matches implementation
6. ✅ All resources properly cleaned up
7. ✅ No unexpected Azure costs remain

---

## Next Steps After Testing

1. Create detailed PR with testing results
2. Tag appropriate reviewers
3. Address any PR feedback
4. Monitor PR CI/CD pipeline
5. Respond to review comments
6. Merge once approved

**Good luck with your testing! 🚀**
