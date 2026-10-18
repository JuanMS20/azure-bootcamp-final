// Proyecto final - Bootcamp Azure
// Despliega: red segmentada (VNet + 3 subredes + NSG), Storage ADLS Gen2 y Key Vault.
targetScope = 'resourceGroup'

@description('Región de despliegue. Por defecto la del Resource Group.')
param location string = resourceGroup().location

@allowed([
  'dev'
  'prod'
])
@description('Nombre del entorno.')
param envName string = 'dev'

@minLength(3)
@maxLength(8)
@description('Prefijo corto para nombrar los recursos.')
param prefix string = 'bootc'

@description('IP pública (CIDR) autorizada para administración. Ej: 190.1.2.3/32')
param adminSourceIp string

@description('Espacio de direcciones de la VNet.')
param vnetAddressPrefix string = '10.0.0.0/16'

var tags = {
  proyecto: 'bootcamp-azure-final'
  entorno: envName
  gestionadoPor: 'bicep'
}

module network 'modules/network.bicep' = {
  name: 'network-${envName}'
  params: {
    location: location
    prefix: prefix
    envName: envName
    vnetAddressPrefix: vnetAddressPrefix
    adminSourceIp: adminSourceIp
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage-${envName}'
  params: {
    location: location
    prefix: prefix
    envName: envName
    dataSubnetId: network.outputs.dataSubnetId
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault-${envName}'
  params: {
    location: location
    prefix: prefix
    envName: envName
    tags: tags
  }
}

output vnetName string = network.outputs.vnetName
output storageAccountName string = storage.outputs.storageAccountName
output keyVaultName string = keyvault.outputs.keyVaultName
