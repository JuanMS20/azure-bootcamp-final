// Red: VNet con 3 subredes segmentadas, cada una con su NSG.
param location string
param prefix string
param envName string
param adminSourceIp string
param tags object
param vnetAddressPrefix string = '10.0.0.0/16'
param appSubnetPrefix string = '10.0.0.0/24'
param dataSubnetPrefix string = '10.0.1.0/24'
param mgmtSubnetPrefix string = '10.0.2.0/24'

// NSG de la subred de aplicación: solo web (80/443) desde Internet.
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${prefix}-app-${envName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-Internet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-HTTP-Internet'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// NSG de la subred de datos: solo SQL (1433) desde la subred de aplicación.
resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${prefix}-data-${envName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SQL-From-App'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: appSubnetPrefix
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// NSG de la subred de administración: RDP/SSH solo desde tu IP.
resource nsgMgmt 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${prefix}-mgmt-${envName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-Admin'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: adminSourceIp
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-SSH-Admin'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminSourceIp
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-${prefix}-${envName}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-app'
        properties: {
          addressPrefix: appSubnetPrefix
          networkSecurityGroup: {
            id: nsgApp.id
          }
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: dataSubnetPrefix
          networkSecurityGroup: {
            id: nsgData.id
          }
          // Permite que el Storage Account acepte tráfico solo desde esta subred.
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'snet-mgmt'
        properties: {
          addressPrefix: mgmtSubnetPrefix
          networkSecurityGroup: {
            id: nsgMgmt.id
          }
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output dataSubnetId string = vnet.properties.subnets[1].id
