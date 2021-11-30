/*
Synopsis
    Main Bicep template for Virtual Wan deployment

NOTES
    Author     : Roman Rabodzei
*/

//// Deployment scope
targetScope = 'subscription'

param tags object = {
  Environment: 'Demo'
}


///// Parameters and variables
param variables object = json(loadTextContent('azvwan.parameters.json'))
@description('Name and location of the resource group')
var resourceGroupName = variables.resourceGroupName
var resourceLocation = variables.resourceLocations

///// Virtual Wan
var virtualWanName = variables.virtualWanName

///// West Europe
var virtualNetworkNameWestEu = variables.virtualNetworkNameWestEu

var virtualHubNameWestEU = variables.virtualHubNameWestEU
var virtualHubAddressPrefixWestEu = variables.virtualHubAddressPrefixWestEu

///// East US
var virtualNetworkNameEastUS = variables.virtualNetworkNameEastUS
var virtualNetworkAddressPrefixEastUS = variables.virtualNetworkAddressPrefixEastUS
var virtualNetworkSubnetNameEastUS01 = variables.virtualNetworkSubnetNameEastUS01
var virtualNetworkSubnetPrefixEastUS01 = variables.virtualNetworkSubnetPrefixEastUS01
 var virtualNetworkSubnetNameEastUS02 = variables.virtualNetworkSubnetNameEastUS02
 var virtualNetworkSubnetPrefixEastUS02 = variables.virtualNetworkSubnetPrefixEastUS02


var virtualHubNameEastUS = variables.virtualHubNameEastUS
var virtualHubAddressPrefixEastUS = variables.virtualHubAddressPrefixEastUS

///// Resources
resource azureVWanResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (true) {
  name: resourceGroupName
  location: resourceLocation[0]
  tags: tags
}

module azureVirtualWan 'modules/virtualWan.bicep' = if (true) {
  scope: azureVWanResourceGroup
  name: 'virtualWan'
  params: {
    resourceLocation: resourceLocation[1]
    virtualWanName: virtualWanName
  }
}

///// West Europe resources
resource azureVrtualNetworkWestEu 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  scope: azureVWanResourceGroup
  name: virtualNetworkNameWestEu
}

module azureVirtualNetworkHubWestEu 'modules/virtualHub.bicep' = if (true) {
  scope: azureVWanResourceGroup
  name: 'virtualNetworkHubWestEu'
  params: {
    resourceLocation: resourceLocation[0]
    virtualHubName: virtualHubNameWestEU
    virtualHubAddressPrefix: virtualHubAddressPrefixWestEu
    virtualWanId: azureVirtualWan.outputs.virtualWanId
    virtualNetworkName: virtualNetworkNameWestEu
    virtualNetworkId: azureVrtualNetworkWestEu.id
  }
}

///// East US resources
module azureVirtualNetworkEastUs 'modules/virtualNetwork.bicep' = if (true) {
  scope: azureVWanResourceGroup
  name: 'virtualNetworkEastUs'
  params: {
    resourceLocation: resourceLocation[1]
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefixEastUS
    virtualNetworkName: virtualNetworkNameEastUS
    virtualNetworkSubnetName01: virtualNetworkSubnetNameEastUS01
    virtualNetworkSubnetPrefix01: virtualNetworkSubnetPrefixEastUS01
    virtualNetworkSubnetName02: virtualNetworkSubnetNameEastUS02
    virtualNetworkSubnetPrefix02: virtualNetworkSubnetPrefixEastUS02
  }
}

module azureVirtualNetworkHubEastUs 'modules/virtualHub.bicep' = if (true) {
  scope: azureVWanResourceGroup
  name: 'virtualNetworkHubEastUs'
  params: {
    resourceLocation: resourceLocation[1]
    virtualHubName: virtualHubNameEastUS
    virtualHubAddressPrefix: virtualHubAddressPrefixEastUS
    virtualWanId: azureVirtualWan.outputs.virtualWanId
    virtualNetworkName: virtualNetworkNameEastUS
    virtualNetworkId: azureVirtualNetworkEastUs.outputs.virtualNetworkId
  }
}


///// Key Vault, Log Analytics Workspace, Virtual Machine
var keyVaultName = variables.keyVaultName
var keyVaultSecretName = variables.keyVaultSecretName
var keyVaultResourceGroup = variables.keyVaultResourceGroup

var workspaceName = variables.workspaceName
var workspaceResourceGroup = variables.workspaceResourceGroup

var vmResourceGroup = variables.VMResourceGroup
var adminUsername = variables.adminUsername
var vmName = variables.vmName
var vmSize = variables.vmSize
var dataDiskSize = variables.dataDiskSize
var dataDiskType = variables.dataDiskType
var imagePublisher = variables.imagePublisher
var imageOffer = variables.imageOffer
var imageSku = variables.imageSku

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  scope: resourceGroup(keyVaultResourceGroup)
  name: keyVaultName
}

module azureVM 'modules/virtualMachine.bicep' = if (false) {
  scope: resourceGroup(vmResourceGroup)
  name: 'PRDVM'
  params: {
    adminUsername: adminUsername
    adminPassword: keyVault.getSecret(keyVaultSecretName)
    vmName: vmName
    vmSize: vmSize
    dataDiskSize: dataDiskSize
    dataDiskType: dataDiskType
    imageSku: imageSku
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    location: resourceLocation[1]
    vnetResourceGroup: resourceGroupName
    vnetName: virtualNetworkNameEastUS
    subnetName: virtualNetworkSubnetNameEastUS01
    workspaceName: workspaceName
    workspaceResourceGroup: workspaceResourceGroup
  }
  dependsOn: [
    azureVirtualNetworkHubEastUs
    azureVirtualNetworkHubWestEu
  ]
}
