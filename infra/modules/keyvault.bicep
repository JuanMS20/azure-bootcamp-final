// Key Vault con autorización por RBAC (sin access policies) para guardar secretos.
param location string
param prefix string
param envName string
param tags object

var kvName = take('kv-${prefix}-${envName}-${uniqueString(resourceGroup().id)}', 24)

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
  }
}

output keyVaultName string = kv.name
output keyVaultUri string = kv.properties.vaultUri
