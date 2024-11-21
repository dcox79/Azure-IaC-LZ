param location string
param virtualNetworkName string
param subnetName string

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-03-01' = {
  name: 'firewall-ip'
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

resource firewall 'Microsoft.Network/azureFirewalls@2024-03-01' = {
  name: 'firewall'
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
    networkRuleCollections: [{
      name: 'rulesLZ101'
      properties: {
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-outbound-to-internet'
            protocols: ['Any']
            sourceAddresses: ['10.1.101.0/24']
            destinationAddresses: ['*']
            destinationPorts: ['*']
          }
        ]
      }
    }]
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: 'central-log-analytics'
  scope: resourceGroup('management')
}

resource firewallDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'allLogs_to_LogAnalyticsWorkspace'
  scope: firewall
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    logAnalyticsDestinationType: 'Dedicated'
    workspaceId: logAnalyticsWorkspace.id
  }
}
