targetScope = 'resourceGroup'

@description('Location of the resources')
param resourceLocation string

@description('Azure Virtual Network Name')
@minLength(1)
@maxLength(64)
param virtualNetworkName string

@description('Azure Virtual Network Id')
param virtualNetworkId string

@description('Azure Virtual WAN Name')
param virtualWanId string

@description('Azure Virtual WAN Hub Name')
@minLength(1)
@maxLength(80)
param virtualHubName string

@description('Azure Virtual WAN Hub Address Prifix')
param virtualHubAddressPrefix string

var defaultRouteTableId = '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualHubs/${virtualHubName}/hubRouteTables/defaultRouteTable'
var propagatedRouteTableId = '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualHubs/${virtualHubName}/hubRouteTables/noneRouteTable'

resource virtualHub 'Microsoft.Network/virtualHubs@2021-03-01' = {
  location: resourceLocation
  name: toLower(virtualHubName)
  properties: {
    sku: 'Standard'
    addressPrefix: virtualHubAddressPrefix
    virtualWan: {
      id: virtualWanId
    }
  }
}


resource virtualHub_to_virtualNetwork_0_connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-02-01' = {
  name: toLower('${virtualHubName}/${virtualNetworkName}-connection')
  properties: {
    remoteVirtualNetwork: {
      id: virtualNetworkId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: defaultRouteTableId
      }
      propagatedRouteTables: {
        ids: [
          {
            id: propagatedRouteTableId
          }
        ]
        labels: [
          'none'
        ]
      }
      vnetRoutes: {
        staticRoutes: []
      }
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  dependsOn: [
    virtualHub
  ]
}

output virtualHubId string = virtualHub.id
