param location string

param vnetName string
param firewallSubnetName string
param bastionSubnetName string

resource hubNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: '10.0.10.0/24'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '10.0.11.0/24'
        }
      }
    ]
  }
}
