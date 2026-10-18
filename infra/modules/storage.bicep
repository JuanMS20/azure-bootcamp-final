// Almacenamiento: Storage Account ADLS Gen2 (namespace jerárquico) con contenedores medallion.
param location string
param prefix string
param envName string
param dataSubnetId string
param tags object

// Nombre global único, solo minúsculas/números, máx. 24 caracteres.
var storageName = take(toLower('st${prefix}${envName}${uniqueString(resourceGroup().id)}'), 24)

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: dataSubnetId
          action: 'Allow'
        }
      ]
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for c in [ 'bronze', 'silver', 'gold' ]: {
  parent: blobService
  name: c
  properties: {
    publicAccess: 'None'
  }
}]

output storageAccountName string = storage.name
output storageAccountId string = storage.id
