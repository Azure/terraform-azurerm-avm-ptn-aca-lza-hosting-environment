# Examples

This directory contains practical examples demonstrating different deployment scenarios for the Azure Container Apps Landing Zone Accelerator (ACA LZA) module. Each example showcases specific features and configuration patterns to help you implement the solution that best fits your requirements.

## Available Examples

### [Hub-Spoke with Linux VM](./hub-spoke-linux-vm/)
Demonstrates enterprise hub-spoke network topology with a Linux jumpbox VM and comprehensive observability features.

**Features**:
- Hub-spoke network integration with virtual network peering
- Linux VM with SSH key authentication
- Network traffic routing through simulated network appliance
- Full Application Insights and Dapr instrumentation
- Zone-redundant deployment for high availability

**Use Case**: Enterprise environments requiring secure network isolation, centralized connectivity, and Linux-based administration.

### [Bastion Integration with Zone Redundancy](./bastion-zone-redundant/)
Implements the most secure connectivity pattern using Azure Bastion with full zone redundancy across all supported resources.

**Features**:
- Azure Bastion with advanced features (tunneling, file copy, shareable links)
- Zone-redundant deployment across availability zones
- Secure VM access without public IPs
- Complete observability and monitoring stack
- All optional features enabled

**Use Case**: High-security environments, production workloads requiring maximum availability, or scenarios with strict connectivity requirements.

### [Minimal Configuration](./minimal-configuration/)
Demonstrates the smallest viable deployment with minimal features enabled, ideal for cost-sensitive or development scenarios.

**Features**:
- No virtual machine deployment
- Minimal observability features
- Container Apps without Application Gateway
- Small network address spaces
- All optional features disabled

**Use Case**: Development environments, cost optimization, or scenarios requiring only core Container Apps functionality.

### [Front Door](./front-door/)
Demonstrates how to deploy with Azure Front Door as the ingress solution instead of Application Gateway for global load balancing and content delivery.

**Features**:
- Azure Front Door Premium SKU with Private Link support
- Default *.azurefd.net endpoint with Microsoft-managed certificates
- Simplified networking (no Application Gateway subnet required)
- Container Apps Environment with sample application
- Optional Web Application Firewall support

**Use Case**: Global applications requiring edge caching, content delivery, or when Application Gateway's regional scope is limiting.

### [Complex Network Appliance](./complex-network-appliance/)
Showcases enterprise-grade deployment with Azure Firewall as a network virtual appliance, implementing comprehensive traffic filtering and routing.

**Features**:
- Azure Firewall with custom policies and rules
- Zone-redundant firewall deployment
- User-defined routes for traffic control
- Premium storage and performance options
- Enterprise naming conventions
- Complete feature set enabled

**Use Case**: Large enterprises requiring centralized security policies, traffic inspection, compliance requirements, or maximum feature utilization.

## Getting Started

1. Choose the example that best matches your requirements
2. Navigate to the example directory
3. Review the README.md for specific configuration details
4. Customize variables as needed for your environment
5. Deploy using standard Terraform commands:

```bash
terraform init
terraform plan
terraform apply
```

## Example Comparison

| Feature | Hub-Spoke Linux | Bastion Zone Redundant | Minimal | Front Door | Complex Network Appliance |
|---------|----------------|------------------------|---------|------------|---------------------------|
| **VM Type** | Linux SSH | Linux SSH | None | None | Linux SSH |
| **Hub Integration** | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Zone Redundancy** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **Ingress Method** | App Gateway | App Gateway | None | Front Door | App Gateway |
| **Observability** | Full | Full | Minimal | Full | Full |
| **Relative Cost** | Medium-High | High | Lowest | Medium | Highest |
| **Complexity** | High | High | Minimal | Medium | Maximum |

## Support

For questions about these examples or the ACA LZA module, please refer to the main module documentation or open an issue in the repository.
