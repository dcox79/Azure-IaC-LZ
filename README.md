# Azure Bicep IaC Landing Zones

This repository contains basic Azure Bicep IaC code for a tenant's Sandbox environment. It is not intended for production use, and it deploys to a single subscription that is dedicated as a sandbox. Policies and management groups are already deployed using Azure's Cloud Adoption Framework.

**Delete all resources in the current subscription using Azure CLI**

`az group list --query "[].name" -o tsv | ForEach-Object { az group delete -n $_  }`

**Deploy the platform**

`az deployment sub create --location centralus --parameters .\platform\platform.bicepparam`




## Connectivity

The Connectivity Landing Zone contains the virtual network, bastion host, and firewall.

## Management

The Management Landing Zone contains the Log Analytics workspace and diagnostic settings.
