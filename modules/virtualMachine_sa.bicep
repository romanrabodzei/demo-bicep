param variables object = json(loadTextContent('parametersFile'))

@description('Username for the Virtual Machine.')
var adminUsername = variables.adminUsername

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Name of the virtual machine.')
var vmName = variables.vmName

@description('Size of the virtual machine.')
var vmSize = variables.vmSize

@description('Size and type of the virtual machine disk.')
var dataDiskSize = variables.dataDiskSize
var dataDiskType = variables.dataDiskType

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
var imagePublisher = variables.imagePublisher
var imageOffer = variables.imageOffer
var imageSku = variables.imageSku

@description('Location for all resources.')
var location = variables.Region

@description('The virtual network information')
var vnetResourceGroup = variables.vnetResourceGroup
var vnetName = variables.vnetName
var subnetName = variables.subnetName

@description('Log Analytics workspace')
var workspaceResourceGroup = variables.workspaceResourceGroup
var workspaceName = variables.workspaceName

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  scope: resourceGroup(vnetResourceGroup)
  name: vnetName
  resource subnet 'subnets' existing = {
    name: subnetName
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  scope: resourceGroup(workspaceResourceGroup)
  name: workspaceName
}

resource vm 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  properties: {
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        name: '${vmName}_osdisk1'
      }
      dataDisks: [
        {
          name: '${vmName}_datadisk1'
          diskSizeGB: dataDiskSize
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: dataDiskType
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
  resource OMSExtension 'extensions' = {
    name: 'OMSExtension'
    location: location
    properties: {
      publisher: 'Microsoft.EnterpriseCloud.Monitoring'
      type: 'MicrosoftMonitoringAgent'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      settings: {
        workspaceId: reference(logAnalytics.id, '2015-03-20').customerId
      }
      protectedSettings: {
        workspaceKey: listKeys(logAnalytics.id, '2015-03-20').primarySharedKey
      }
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: '${vmName}-nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet::subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

