param location string

var vnetName = 'hub'
var firewallSubnetName = 'AzureFirewallSubnet' // mandatory name
var bastionSubnetName = 'AzureBastionSubnet' // mandatory name

module virtualNetworkDeployment 'resources/virtual-network.bicep' = {
  name: 'virtualNetworkDeployment'
  params: {
    location: location
    vnetName: vnetName
    firewallSubnetName: firewallSubnetName
    bastionSubnetName: bastionSubnetName
  }
}

module bastionDeployment 'resources/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    location: location
    virtualNetworkName: vnetName
    subnetName: bastionSubnetName
  }
  dependsOn: [
    virtualNetworkDeployment
  ]
}

module firewallDeployment 'resources/firewall.bicep' = {
  name: 'firewallDeployment'
  params: {
    location: location
    virtualNetworkName: vnetName
    subnetName: firewallSubnetName
  }
  dependsOn: [
    virtualNetworkDeployment
  ]
}
