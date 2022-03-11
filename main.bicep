param tags object = {}
param location string = resourceGroup().location
param nsg_n string = 'nsg-default'

resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsg_n
  location: location
  properties: {}
  tags: tags
}
