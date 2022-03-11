targetScope = 'resourceGroup'

param tags object = {}
param location string = resourceGroup().location

resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-default'
  location: location
  properties: {}
  tags: tags
}
