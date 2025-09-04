# Sample application (Terraform module)

Deploys a simple public Hello World Azure Container App into an existing Container Apps Environment using the AVM module.

- Uses image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest
- External ingress on port 80, Single revision, min/max replicas 2/10
- Assigns the ACR pull User Assigned Identity

Inputs: see `variables.tf`.
Outputs:
- id, name, fqdn (latest revision)
