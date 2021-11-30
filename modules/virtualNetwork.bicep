targetScope = 'resourceGroup'

@description('Location of the resources')
param resourceLocation string

@description('Azure Virtual Network Name')
@minLength(2)
@maxLength(64)
param virtualNetworkName string

@description('Azure Virtual Network Prefix')
param virtualNetworkAddressPrefix string

@description('Subnet Name')
@minLength(1)
@maxLength(80)
param virtualNetworkSubnetName01 string

@description('Subnet Prefix')
param virtualNetworkSubnetPrefix01 string

@description('Subnet Name')
@minLength(1)
@maxLength(80)
param virtualNetworkSubnetName02 string

@description('Subnet Prefix')
param virtualNetworkSubnetPrefix02 string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: toLower(virtualNetworkName)
  location: resourceLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
  }
  resource subnet1 'subnets' = {
    name: toLower(virtualNetworkSubnetName01)
    properties: {
      addressPrefix: virtualNetworkSubnetPrefix01
    }
  }
  resource subnet2 'subnets' = {
    name: toLower(virtualNetworkSubnetName02)
    properties: {
      addressPrefix: virtualNetworkSubnetPrefix02
    }
  }
}

output virtualNetworkId string = virtualNetwork.id
