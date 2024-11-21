# Azure Bicep IaC Landing Zones

This repository contains basic Azure Bicep IaC code for a tenant's Sandbox environment. It is not intended for production use, it deploys to a single subscription that is a dedicated sandbox. 

This deployment does not need policies and management groups because they are already deployed using Azure's Cloud Adoption Framework's landing zone accelerator.

**[Optional Steps]**
Prep Subscription: Delete all resources in the current subscription using Azure CLI
`az group list --query "[].name" -o tsv | ForEach-Object { az group delete -n $_  }`

Create reusable landing zone template 
`az ts create --name default-landing-zone --version "1.0"--location centralus --resource-group management --template-file .\landing-zones\default-landing-zone.bicep`

**Deploy the platform**

`az deployment sub create --location centralus --parameters .\platform\platform.bicepparam`

**Deploy the first landing zone**

`az stack sub create --location centralus --deny-settings-mode None --action-on-unmanage detach--name landingZoneProduct1 --template-spec /subscriptions/<SubscriptionID>/resourceGroups/management/providers/Microsoft.Resources/templateSpecs/default-landing-zone/versions/1.0 --parameters .\landing-zones\default-landing-zone\101-product1.parameters.json`


## Connectivity

The Connectivity Landing Zone contains the virtual network, bastion host, and firewall.

## Management

The Management Landing Zone contains the Log Analytics workspace and diagnostic settings.
