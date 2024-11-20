param location string
param virtualNetworkName string
param subnetName string

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-03-01' = {
  name: 'bastion-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
}
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  name: virtualNetworkName
  
  resource subnet 'subnets@2024-03-01' existing = {
    name: subnetName
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2024-03-01' = {
  name: 'bastion-host'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfiguration'
        properties: {
          subnet: {
            id: virtualNetwork::subnet.id
          
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
