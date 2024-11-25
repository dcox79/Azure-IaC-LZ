targetScope = 'subscription'

param location string
param productName string
param spokeNumber string

resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: 'rg-${productName}-${spokeNumber}-lz'
  location: location
}

module spokeResourceDeployment 'default-landing-zone/landing-zone.bicep' = {
  name: 'spokeResourceDeployment'
  scope: spokeResourceGroup
  params: {
    spokeNumber: spokeNumber
    location: location
    productName: productName
    deployDefaultSubnet: true
  }
}
