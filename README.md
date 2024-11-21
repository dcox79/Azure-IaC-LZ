# Azure Bicep IaC Landing Zones

This repository contains basic Azure Bicep IaC code for a tenant's Sandbox environment. It is not intended for production use, it deploys to a single subscription that is a dedicated sandbox. 

This deployment does not need policies and management groups because they are already deployed using Azure's Cloud Adoption Framework's landing zone accelerator.

**[Optional Steps]**
Prep Subscription: Delete all resources in the current subscription using Azure CLI
`az group list --query "[].name" -o tsv | ForEach-Object { az group delete -n $_  }`

Create reusable landing zone template 
`az ts create --name default-landing-zone --location centralus --resource-group management --template-file .\landing-zones\default-landing-zone.bicep`

**Deploy the platform**

`az deployment sub create --location centralus --parameters .\platform\platform.bicepparam`




## Connectivity

The Connectivity Landing Zone contains the virtual network, bastion host, and firewall.

## Management

The Management Landing Zone contains the Log Analytics workspace and diagnostic settings.
