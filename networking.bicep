param vnetName string
param appgw_subnetName string
param subnet_appGatewayAddressPrefix string 
param nsgAppGateway_id string

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
}


resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  parent: vnet
  name: appgw_subnetName
  properties: {
    addressPrefix: subnet_appGatewayAddressPrefix
    networkSecurityGroup: {
      id: nsgAppGateway_id 
    }
  } 
}


output subnet_id string = subnet.id
