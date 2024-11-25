param location string
param productName string
param spokeNumber string
param deployDefaultSubnet bool

var virtualNetworkName = 'vnet-${productName}'
var connectivityResourceGroupName = 'connectivity'

resource hubNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  name: 'hub'
  scope: resourceGroup(connectivityResourceGroupName)
}

resource hubFirewall 'Microsoft.Network/azureFirewalls@2024-03-01' existing = {
  name: 'firewall'
  scope: resourceGroup(connectivityResourceGroupName)
}

resource spokeNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.${spokeNumber}.0/24'
      ]
    }
    subnets: deployDefaultSubnet ? [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.1.${spokeNumber}.0/24'
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ] : []
  }
}

resource peeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-03-01' = {
  parent: spokeNetwork
  name: 'spoke-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubNetwork.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

module peeringHubtoSpokeDeployment 'hub-to-spoke-peering.bicep' = {
  name: 'peeringHubToSpokeDeployment'
  scope: resourceGroup(connectivityResourceGroupName)
  params: {
    spokeResourceGroupName: resourceGroup().name
    spokeVirtualNetworkName: spokeNetwork.name
    spokeNumber: spokeNumber
  }
}

resource routeTable 'Microsoft.Network/routeTables@2024-03-01' = {
  name: 'spoke${spokeNumber}RouteTable'
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [{
      name: 'defaultRoute'
      properties: {
        addressPrefix: '0.0.0.0/0'
        nextHopIpAddress: hubFirewall.properties.ipConfigurations[0].properties.privateIPAddress
        nextHopType: 'VirtualAppliance'
      }
    }]
  }
}
