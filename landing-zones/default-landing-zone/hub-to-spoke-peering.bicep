param spokeResourceGroupName string
param spokeVirtualNetworkName string
param spokeNumber string

resource hubNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  name: 'hub'
}

resource spokeNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  name: spokeVirtualNetworkName
  scope: resourceGroup(spokeResourceGroupName)
}

resource peeringHubtoSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-03-01' = {
  parent: hubNetwork
  name: 'hub-to-spoke-${spokeNumber}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeNetwork.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
