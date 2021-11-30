targetScope = 'resourceGroup'

@description('Location of the resources')
param resourceLocation string

@description('Azure Virtual WAN Name')
@minLength(1)
@maxLength(80)
param virtualWanName string

resource virtualWan 'Microsoft.Network/virtualWans@2021-03-01' = {
  name: toLower(virtualWanName)
  location: resourceLocation
  properties: {
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    type: 'Standard'
  }
}

output virtualWanId string = virtualWan.id
