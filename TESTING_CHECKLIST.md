# Manual Testing Checklist

**Module**: Azure Container Apps LZA Hosting Environment
**Branch**: `sam-cogan/initial-module-creation`
**Tester**: _________________
**Date Started**: _________________
**Date Completed**: _________________

---

## Pre-Testing Setup

### Prerequisites Validation
- [ ] Azure subscription access verified
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform >= 1.9 installed (`terraform version`)
- [ ] Fish shell configured
- [ ] `./avm` script is executable (`chmod +x ./avm`)

### Pre-Test Code Validation
```bash
# Navigate to repository root
cd /home/sam/repos/terraform-azurerm-avm-ptn-aca-lza-hosting-environment

# Set environment variable
export PORCH_NO_TUI=1

# Format code
terraform fmt -recursive

# Run AVM pre-commit
./avm pre-commit

# Commit any changes
git add .
git commit -m "chore: avm pre-commit"

# Run AVM PR check
./avm pr-check
```

- [ ] All formatting completed
- [ ] AVM pre-commit passed
- [ ] AVM PR check passed
- [ ] All changes committed

---

## Test 1: Minimal Configuration 🔴 P0 CRITICAL

**Priority**: MUST COMPLETE
**Estimated Time**: 15-20 minutes
**Estimated Cost**: ~$5

### Setup
```bash
cd examples/minimal-configuration
terraform init
```
- [ ] Terraform initialized successfully

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Verify resource group
az group show --name (terraform output -raw resource_group_name)

# Check Container Apps Environment
az containerapp env show \
  --resource-group (terraform output -raw resource_group_name) \
  --name (terraform output -json | jq -r '.container_apps_environment_id.value' | awk -F'/' '{print $NF}')

# Check Container Registry
az acr show --resource-id (terraform output -raw container_registry_id)

# Verify Log Analytics Workspace
az monitor log-analytics workspace show \
  --resource-id (terraform output -raw log_analytics_workspace_id)
```

### Validation Checklist
- [ ] Resource group created
- [ ] Container Apps Environment deployed and "Running"
- [ ] Container Registry deployed
- [ ] Log Analytics Workspace created
- [ ] Key Vault deployed
- [ ] Storage Account created
- [ ] Spoke VNet deployed
- [ ] No Application Gateway (confirmed absent)
- [ ] No VM deployed (confirmed absent)
- [ ] No Application Insights (confirmed absent)
- [ ] No sample application (confirmed absent)

### Portal Validation
- [ ] Opened Azure Portal and verified resource group
- [ ] Counted resources matches expected
- [ ] Container Apps Environment status is "Running"
- [ ] VNet subnets match configuration

### Cleanup
```bash
terraform destroy -auto-approve
```
- [ ] Destroy completed successfully
- [ ] All resources removed (verified in portal)

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Test 2: Default 🔴 P0 CRITICAL

**Priority**: MUST COMPLETE
**Estimated Time**: 20-25 minutes
**Estimated Cost**: ~$10

### Setup
```bash
cd ../default
terraform init
```
- [ ] Terraform initialized successfully

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Get Application Gateway public IP
set APP_GW_IP (terraform output -raw application_gateway_public_ip)
echo "App Gateway IP: $APP_GW_IP"

# Check Application Gateway
az network application-gateway show \
  --resource-group (terraform output -raw resource_group_name) \
  --name (terraform output -json | jq -r '.application_gateway_id.value' | awk -F'/' '{print $NF}')

# Check backend health (wait 5-10 minutes if not healthy initially)
az network application-gateway show-backend-health \
  --resource-group (terraform output -raw resource_group_name) \
  --name (terraform output -json | jq -r '.application_gateway_id.value' | awk -F'/' '{print $NF}')

# Test sample app connectivity (after backends are healthy)
curl -H "Host: example.com" http://$APP_GW_IP/
```

### Validation Checklist
- [ ] All resources from Test 1 present
- [ ] Application Gateway deployed
- [ ] Application Gateway has public IP
- [ ] Sample Container App deployed
- [ ] Backend health is "Healthy" (may take 5-10 mins)
- [ ] HTTP request returns HTML response

### Portal Validation
- [ ] Application Gateway shows in portal
- [ ] Backend Health shows as healthy
- [ ] Backend Pools configured correctly
- [ ] HTTP Settings configured
- [ ] Container App is running
- [ ] Container App ingress configured

### Cleanup
```bash
terraform destroy -auto-approve
```
- [ ] Destroy completed successfully
- [ ] All resources removed (verified in portal)

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Test 3: Front Door Standard 🟡 P1 HIGH PRIORITY

**Priority**: SHOULD COMPLETE
**Estimated Time**: 25-30 minutes
**Estimated Cost**: ~$15

### Setup
```bash
cd ../front-door-standard
terraform init
```
- [ ] Terraform initialized successfully

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Get Front Door endpoint
set FD_HOSTNAME (terraform output -raw front_door_endpoint_hostname)
echo "Front Door: $FD_HOSTNAME"

# Check Front Door profile
az afd profile show --resource-id (terraform output -raw front_door_id)

# Test access (may take several minutes to provision)
sleep 300  # Wait 5 minutes for Front Door provisioning
curl https://$FD_HOSTNAME/
```

### Validation Checklist
- [ ] Front Door profile deployed
- [ ] Front Door endpoint created (*.azurefd.net)
- [ ] Front Door origin group configured
- [ ] Origin pointing to Container App
- [ ] Route configured
- [ ] No Application Gateway deployed (confirmed)
- [ ] Sample Container App deployed and running
- [ ] TLS certificate in Key Vault (if custom domain)
- [ ] HTTP/HTTPS request succeeds

### Portal Validation
- [ ] Front Door profile visible in portal
- [ ] Endpoint status is "Enabled"
- [ ] Origin group health is good
- [ ] Origin health status is healthy
- [ ] Route configuration correct
- [ ] Tested endpoint in browser successfully

### Cleanup
```bash
terraform destroy -auto-approve
```
- [ ] Destroy completed successfully
- [ ] All resources removed (verified in portal)

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Test 4: Smoke Spoke 🟡 P1 HIGH PRIORITY

**Priority**: SHOULD COMPLETE
**Estimated Time**: 20-25 minutes
**Estimated Cost**: ~$8

### Setup
```bash
cd ../smoke-spoke
terraform init
```
- [ ] Terraform initialized successfully

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Verify all core outputs present
terraform output -json
```

### Validation Checklist
- [ ] Spoke VNet deployed
- [ ] All required subnets created
- [ ] Container Apps Environment deployed
- [ ] Basic connectivity validated
- [ ] All outputs present

### Portal Validation
- [ ] Resource group contains expected resources
- [ ] VNet and subnets visible
- [ ] Container Apps Environment running

### Cleanup
```bash
terraform destroy -auto-approve
```
- [ ] Destroy completed successfully
- [ ] All resources removed

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Test 5: Windows VM Custom Cert 🟡 P1 HIGH PRIORITY

**Priority**: SHOULD COMPLETE
**Estimated Time**: 30-35 minutes
**Estimated Cost**: ~$12

### Setup
```bash
cd ../windows-vm-custom-cert

# Set VM password
set -x TF_VAR_vm_admin_password "YourSecurePassword123!"

terraform init
```
- [ ] Environment variable set
- [ ] Terraform initialized successfully

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Verify VM
az vm show \
  --resource-group (terraform output -raw resource_group_name) \
  --name (terraform output -json | jq -r '.vm_id.value' | awk -F'/' '{print $NF}') 2>/dev/null || echo "VM name needs verification"

# Check Key Vault certificates
az keyvault certificate list \
  --vault-name (terraform output -raw key_vault_name)
```

### Validation Checklist
- [ ] Resource group created by module
- [ ] Windows VM deployed successfully
- [ ] VM is running
- [ ] VM has correct size and configuration
- [ ] VM network interface attached correctly
- [ ] Custom certificate generated
- [ ] Certificate stored in Key Vault
- [ ] Container Apps Environment deployed
- [ ] No Application Gateway deployed

### Portal Validation
- [ ] Windows VM visible and running
- [ ] VM configuration correct (size, OS, disks)
- [ ] Key Vault contains certificate
- [ ] Certificate properties look correct
- [ ] Network connectivity appears correct

### Cleanup
```bash
terraform destroy -auto-approve
set -e TF_VAR_vm_admin_password
```
- [ ] Destroy completed successfully
- [ ] Environment variable cleared
- [ ] All resources removed

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Test 6: Hub-Spoke Linux VM 🟡 P1 HIGH PRIORITY

**Priority**: SHOULD COMPLETE
**Estimated Time**: 35-40 minutes
**Estimated Cost**: ~$20

### Setup - Create Hub VNet
```bash
# Create test hub VNet
az group create --name rg-hub-test --location eastus

az network vnet create \
  --resource-group rg-hub-test \
  --name vnet-hub-test \
  --address-prefix 10.0.0.0/16

# Get hub VNet resource ID
set HUB_VNET_ID (az network vnet show \
  --resource-group rg-hub-test \
  --name vnet-hub-test \
  --query id -o tsv)

echo "Hub VNet ID: $HUB_VNET_ID"
```
- [ ] Hub resource group created
- [ ] Hub VNet created
- [ ] Hub VNet ID captured

### Setup - Module
```bash
cd ../hub-spoke-linux-vm

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aca_lza_test -N ""

# Set environment variables
set -x TF_VAR_vm_linux_ssh_authorized_key (cat ~/.ssh/aca_lza_test.pub)
set -x TF_VAR_hub_virtual_network_resource_id $HUB_VNET_ID
set -x TF_VAR_vm_admin_password "NotUsed123!"

terraform init
```
- [ ] SSH key generated
- [ ] Environment variables set
- [ ] Terraform initialized

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Check VNet peering status
az network vnet peering list \
  --resource-group (terraform output -raw resource_group_name) \
  --vnet-name (terraform output -json | jq -r '.spoke_vnet_id.value' | awk -F'/' '{print $NF}') \
  --output table

# Verify peering is "Connected"
az network vnet peering show \
  --resource-group (terraform output -raw resource_group_name) \
  --vnet-name (terraform output -json | jq -r '.spoke_vnet_id.value' | awk -F'/' '{print $NF}') \
  --name (az network vnet peering list --resource-group (terraform output -raw resource_group_name) --vnet-name (terraform output -json | jq -r '.spoke_vnet_id.value' | awk -F'/' '{print $NF}') --query [0].name -o tsv)
```

### Validation Checklist
- [ ] Hub-spoke peering established
- [ ] Both peering links show "Connected" state
- [ ] Linux VM deployed successfully
- [ ] SSH key authentication configured
- [ ] Application Insights deployed
- [ ] Dapr instrumentation enabled
- [ ] Zone-redundant resources deployed
- [ ] Route table configured
- [ ] User-defined routes applied
- [ ] Application Gateway deployed
- [ ] Sample app deployed

### Portal Validation
- [ ] Spoke VNet shows peering to hub as "Connected"
- [ ] Hub VNet shows peering to spoke as "Connected"
- [ ] Linux VM is running
- [ ] SSH public key visible in VM config
- [ ] Application Insights collecting data
- [ ] Dapr components visible in Container Apps Environment
- [ ] Zone redundancy verified on applicable resources
- [ ] Route tables and UDRs present

### Cleanup
```bash
terraform destroy -auto-approve

# Clean up hub VNet
az group delete --name rg-hub-test --yes --no-wait

# Clean up SSH keys
rm ~/.ssh/aca_lza_test ~/.ssh/aca_lza_test.pub

# Clear environment variables
set -e TF_VAR_vm_linux_ssh_authorized_key
set -e TF_VAR_hub_virtual_network_resource_id
set -e TF_VAR_vm_admin_password
```
- [ ] Destroy completed successfully
- [ ] Hub VNet deleted
- [ ] SSH keys removed
- [ ] Environment variables cleared

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Test 7: Bastion Zone Redundant 🟢 P2 MEDIUM PRIORITY

**Priority**: CAN COMPLETE AFTER PR
**Estimated Time**: 40-50 minutes
**Estimated Cost**: ~$35

### Setup - Create Hub with Bastion
```bash
# Create hub VNet with Bastion
az group create --name rg-hub-bastion-test --location eastus

az network vnet create \
  --resource-group rg-hub-bastion-test \
  --name vnet-hub-bastion \
  --address-prefix 10.100.0.0/16

# Create Bastion subnet
az network vnet subnet create \
  --resource-group rg-hub-bastion-test \
  --vnet-name vnet-hub-bastion \
  --name AzureBastionSubnet \
  --address-prefix 10.100.255.0/26

# Create Bastion host (takes ~10 minutes)
az network bastion create \
  --resource-group rg-hub-bastion-test \
  --name bastion-hub-test \
  --vnet-name vnet-hub-bastion \
  --location eastus \
  --sku Standard \
  --enable-tunneling true

# Get resource IDs
set BASTION_ID (az network bastion show \
  --resource-group rg-hub-bastion-test \
  --name bastion-hub-test \
  --query id -o tsv)

set HUB_VNET_ID (az network vnet show \
  --resource-group rg-hub-bastion-test \
  --name vnet-hub-bastion \
  --query id -o tsv)

echo "Bastion ID: $BASTION_ID"
echo "Hub VNet ID: $HUB_VNET_ID"
```
- [ ] Hub resource group created
- [ ] Hub VNet created
- [ ] Bastion subnet created
- [ ] Bastion host created (~10 min wait)
- [ ] Resource IDs captured

### Setup - Module
```bash
cd ../bastion-zone-redundant

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aca_lza_bastion_test -N ""

# Set environment variables
set -x TF_VAR_vm_linux_ssh_authorized_key (cat ~/.ssh/aca_lza_bastion_test.pub)
set -x TF_VAR_bastion_resource_id $BASTION_ID
set -x TF_VAR_hub_virtual_network_resource_id $HUB_VNET_ID
set -x TF_VAR_vm_admin_password "NotUsed123!"

terraform init
```
- [ ] SSH key generated
- [ ] Environment variables set
- [ ] Terraform initialized

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Check Application Gateway zones (if deployed)
az network application-gateway show \
  --resource-group (terraform output -raw resource_group_name) \
  --name (terraform output -json | jq -r '.application_gateway_id.value' | awk -F'/' '{print $NF}') \
  --query zones -o table

# Should show zones: ["1", "2", "3"]

# Check Container Apps Environment zone redundancy
az containerapp env show \
  --resource-group (terraform output -raw resource_group_name) \
  --name (terraform output -json | jq -r '.container_apps_environment_id.value' | awk -F'/' '{print $NF}') \
  --query properties.zoneRedundant -o tsv

# Should show: true
```

### Validation Checklist
- [ ] All resources from hub-spoke test present
- [ ] Bastion connectivity configured
- [ ] Application Gateway deployed across zones 1, 2, 3
- [ ] Container Apps Environment zone redundant
- [ ] Other zone-capable resources across 3 AZs
- [ ] VM has no public IP
- [ ] VNet peering to hub established
- [ ] All observability features enabled
- [ ] All security features enabled

### Portal Validation
- [ ] All major resources show zone configuration (1, 2, 3)
- [ ] Application Gateway backend health good
- [ ] Can connect to VM via Bastion in portal
- [ ] Bastion features work (SSH, file copy if enabled)
- [ ] Application Insights showing data
- [ ] All monitoring dashboards functional

### Cleanup
```bash
terraform destroy -auto-approve

# Clean up hub infrastructure
az group delete --name rg-hub-bastion-test --yes --no-wait

# Clean up SSH keys
rm ~/.ssh/aca_lza_bastion_test ~/.ssh/aca_lza_bastion_test.pub

# Clear environment variables
set -e TF_VAR_vm_linux_ssh_authorized_key
set -e TF_VAR_bastion_resource_id
set -e TF_VAR_hub_virtual_network_resource_id
set -e TF_VAR_vm_admin_password
```
- [ ] Destroy completed successfully
- [ ] Hub infrastructure deleted
- [ ] SSH keys removed
- [ ] Environment variables cleared

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Test 8: Complex Network Appliance 🟢 P2 MEDIUM PRIORITY

**Priority**: CAN COMPLETE AFTER PR
**Estimated Time**: 45-60 minutes
**Estimated Cost**: ~$40

### Setup - Create Hub with Firewall
```bash
# Create hub VNet with Azure Firewall
az group create --name rg-hub-firewall-test --location eastus

az network vnet create \
  --resource-group rg-hub-firewall-test \
  --name vnet-hub-firewall \
  --address-prefix 10.200.0.0/16

# Create Azure Firewall subnet
az network vnet subnet create \
  --resource-group rg-hub-firewall-test \
  --vnet-name vnet-hub-firewall \
  --name AzureFirewallSubnet \
  --address-prefix 10.200.255.0/26

# Create public IP for firewall
az network public-ip create \
  --resource-group rg-hub-firewall-test \
  --name pip-fw-hub \
  --location eastus \
  --sku Standard \
  --allocation-method Static

# Create Azure Firewall (takes 5-10 minutes)
az network firewall create \
  --resource-group rg-hub-firewall-test \
  --name fw-hub-test \
  --location eastus \
  --tier Standard

# Configure firewall IP
az network firewall ip-config create \
  --resource-group rg-hub-firewall-test \
  --firewall-name fw-hub-test \
  --name fw-config \
  --public-ip-address pip-fw-hub \
  --vnet-name vnet-hub-firewall

# Get firewall private IP
set FW_PRIVATE_IP (az network firewall show \
  --resource-group rg-hub-firewall-test \
  --name fw-hub-test \
  --query ipConfigurations[0].privateIPAddress -o tsv)

# Get hub VNet resource ID
set HUB_VNET_ID (az network vnet show \
  --resource-group rg-hub-firewall-test \
  --name vnet-hub-firewall \
  --query id -o tsv)

echo "Firewall Private IP: $FW_PRIVATE_IP"
echo "Hub VNet ID: $HUB_VNET_ID"
```
- [ ] Hub resource group created
- [ ] Hub VNet created
- [ ] Firewall subnet created
- [ ] Public IP created
- [ ] Azure Firewall created (~5-10 min wait)
- [ ] Firewall IP configured
- [ ] Firewall private IP captured
- [ ] Hub VNet ID captured

### Setup - Module
```bash
cd ../complex-network-appliance

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aca_lza_complex_test -N ""

# Set environment variables
set -x TF_VAR_vm_linux_ssh_authorized_key (cat ~/.ssh/aca_lza_complex_test.pub)
set -x TF_VAR_hub_virtual_network_resource_id $HUB_VNET_ID
set -x TF_VAR_network_appliance_ip_address $FW_PRIVATE_IP
set -x TF_VAR_vm_admin_password "NotUsed123!"

terraform init
```
- [ ] SSH key generated
- [ ] Environment variables set
- [ ] Terraform initialized

### Deploy
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- [ ] Plan completed without errors
- [ ] Apply completed successfully
- [ ] Deployment time: _______ minutes

### Validation Commands
```bash
# Check outputs
terraform output

# Check route tables
az network route-table list \
  --resource-group (terraform output -raw resource_group_name) \
  --output table

# Check routes point to firewall
az network route-table route list \
  --resource-group (terraform output -raw resource_group_name) \
  --route-table-name (az network route-table list --resource-group (terraform output -raw resource_group_name) --query [0].name -o tsv) \
  --output table

# Verify next hop is firewall IP
```

### Validation Checklist
- [ ] Hub-spoke peering with firewall routing
- [ ] Route tables created with firewall as next hop
- [ ] All egress traffic routed through firewall
- [ ] Firewall rules allowing required traffic
- [ ] Zone-redundant deployment
- [ ] Premium storage configured (if applicable)
- [ ] All features enabled
- [ ] Enterprise naming conventions applied
- [ ] Complete monitoring stack
- [ ] Network appliance routing validated

### Portal Validation
- [ ] Azure Firewall visible and running
- [ ] Firewall rules and policies visible
- [ ] Firewall metrics showing data
- [ ] Route tables visible
- [ ] Routes pointing to firewall private IP
- [ ] Effective routes on VM NIC correct
- [ ] Application Gateway backend health good
- [ ] Complete architecture visible in portal
- [ ] Zone redundancy settings verified
- [ ] All monitoring features working

### Cleanup
```bash
terraform destroy -auto-approve

# Clean up hub firewall infrastructure
az group delete --name rg-hub-firewall-test --yes --no-wait

# Clean up SSH keys
rm ~/.ssh/aca_lza_complex_test ~/.ssh/aca_lza_complex_test.pub

# Clear environment variables
set -e TF_VAR_vm_linux_ssh_authorized_key
set -e TF_VAR_hub_virtual_network_resource_id
set -e TF_VAR_network_appliance_ip_address
set -e TF_VAR_vm_admin_password
```
- [ ] Destroy completed successfully
- [ ] Hub firewall infrastructure deleted
- [ ] SSH keys removed
- [ ] Environment variables cleared

### Test Result
- [ ] ✅ PASSED
- [ ] ❌ FAILED - Issues: _________________________________

---

## Post-Testing Validation

### Cross-Cutting Checks

#### Documentation Accuracy
- [ ] README.md examples match actual code
- [ ] Variable descriptions accurate
- [ ] Output descriptions match actual outputs
- [ ] Example READMEs match example code

#### Code Quality
```bash
cd /home/sam/repos/terraform-azurerm-avm-ptn-aca-lza-hosting-environment

# Format check
terraform fmt -recursive -check

# Validate all examples
for dir in examples/*/
    cd $dir
    echo "Validating $dir"
    terraform init -backend=false
    terraform validate
    cd ../..
end
```
- [ ] Format check passed
- [ ] All examples validated successfully

#### Security Review
- [ ] No hardcoded secrets in code
- [ ] Sensitive outputs properly marked
- [ ] Key Vault properly secured
- [ ] Network security groups correct
- [ ] Private endpoints used appropriately
- [ ] Managed identities used where possible

#### Final AVM Compliance
```bash
cd /home/sam/repos/terraform-azurerm-avm-ptn-aca-lza-hosting-environment

export PORCH_NO_TUI=1
./avm pre-commit

git add .
git commit -m "chore: final pre-commit updates"

./avm pr-check
```
- [ ] Final AVM pre-commit passed
- [ ] Final AVM PR check passed

---

## Testing Summary

### Test Results Overview

| Test | Status | Time | Cost | Notes |
|------|--------|------|------|-------|
| 1. Minimal Configuration | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |
| 2. Default | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |
| 3. Front Door Standard | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |
| 4. Smoke Spoke | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |
| 5. Windows VM Custom Cert | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |
| 6. Hub-Spoke Linux VM | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |
| 7. Bastion Zone Redundant | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |
| 8. Complex Network Appliance | ⬜ Pass / ⬜ Fail | _____ min | $_____ | _________________ |

### Overall Statistics
- **Total Tests**: 8
- **Passed**: _______
- **Failed**: _______
- **Total Time**: _______ hours
- **Total Cost**: $_______

### Issues Found

| # | Test | Severity | Issue Description | Resolution |
|---|------|----------|------------------|------------|
| 1 | | 🔴 Critical / 🟡 High / 🟢 Medium / 🔵 Low | | |
| 2 | | 🔴 Critical / 🟡 High / 🟢 Medium / 🔵 Low | | |
| 3 | | 🔴 Critical / 🟡 High / 🟢 Medium / 🔵 Low | | |

### Ready for PR?

#### Minimum Criteria for PR
- [ ] Both P0 tests passed (Minimal + Default)
- [ ] At least 75% of P1 tests passed (3 of 4)
- [ ] No critical security issues found
- [ ] All AVM validation checks passed
- [ ] Documentation matches implementation
- [ ] All test resources cleaned up

#### Final Decision
- [ ] ✅ **READY FOR PR** - All criteria met
- [ ] ⏳ **NOT READY** - Issues to resolve: _________________________________

---

## Create Pull Request

### Final Steps
```bash
cd /home/sam/repos/terraform-azurerm-avm-ptn-aca-lza-hosting-environment

# Verify clean status
git status

# Push changes
git push origin sam-cogan/initial-module-creation
```

- [ ] All changes committed
- [ ] Branch pushed to GitHub
- [ ] PR created with descriptive title
- [ ] PR includes link to testing results
- [ ] Known issues documented in PR
- [ ] Appropriate reviewers requested

### PR Checklist Items
- [ ] Title follows conventional commits format
- [ ] Description includes testing summary
- [ ] All tests documented
- [ ] Breaking changes noted (if any)
- [ ] Documentation updated
- [ ] Examples tested and working

---

## Sign-Off

**Tester Signature**: _________________________________
**Date**: _________________________________
**Overall Result**: ⬜ PASS  ⬜ FAIL  ⬜ PASS WITH ISSUES

**Notes**:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
