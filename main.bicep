@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('A custom domain name for the API Management service developer portal (e.g., portal.consoto.com). ')
param apiManagementPortalCustomHostname string

@description('A custom domain name for the API Management service gateway/proxy endpoint (e.g., api.consoto.com).')
param apiManagementProxyCustomHostname string

@description('A custom domain name for the API Management service management portal (e.g., management.consoto.com).')
param apiManagementManagementCustomHostname string

@description('Password for corresponding to the certificate for the API Management custom developer portal domain name.')
@secure()
param apiManagementPortalCertificatePassword string

@description('Used by Application Gateway, the Base64 encoded PFX certificate corresponding to the API Management custom developer portal domain name.')
@secure()
param apiManagementPortalCustomHostnameBase64EncodedCertificate string

@description('Password for corresponding to the certificate for the API Management custom proxy domain name.')
@secure()
param apiManagementProxyCertificatePassword string

@description('Used by Application Gateway, the Base64 encoded PFX certificate corresponding to the API Management custom proxy domain name.')
@secure()
param apiManagementProxyCustomHostnameBase64EncodedCertificate string

@description('Password for corresponding to the certificate for the API Management custom management domain name.')
@secure()
param apiManagementManagementCertificatePassword string

@description('Used by Application Gateway, the Base64 encoded PFX certificate corresponding to the API Management custom management domain name.')
@secure()
param apiManagementManagementCustomHostnameBase64EncodedCertificate string


// ---- Application Gateway parameters ----
param tags object = {}
param zones array = []
param logAnalyticsWorkspace_id string 

@description('Used by Application Gateway, the Base64 encoded CER/CRT certificate corresponding to the root certificate for Application Gateway.')
@secure()
param appGatewayTrustedRootCertificate string

@description('Flag to indicate if certificates used by Application Gateway were signed by a public Certificate Authority.')
param useWellKnownCertificateAuthority bool = true

param sku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: 2
}

// ---- Subnet parameters ----

@description('Address prefix for the gateway subnet.')
param subnetApplicationGatewayAddressPrefix string = '10.0.6.0/24'


// ---- Variables ----
var baseName = uniqueString(resourceGroup().id)
var applicationGatewayName = 'agw-${baseName}'
var appGatewayPublicIpAddressName = 'pip-${baseName}-agw'
var vnetName = 'vnet-${baseName}'
var subnetAppGatewayName = 'snet-${baseName}-agw'
var nsgAppGatewayName = 'nsg-${baseName}-agw'

var applicationGatewayTrustedRootCertificates = [
  {
    name: 'trustedrootcert'
    properties: {
      data: appGatewayTrustedRootCertificate
    }
  }
]

var applicationGatewayTrustedRootCertificateReferences = [
  {
    id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'trustedrootcert')
  }
]

// ----  Create Subnet in existing vNET with NSG ----
module subnet 'networking.bicep' = {
  name: '${subnetAppGatewayName}-${vnetName}'
  params: {
    appgw_subnetName: subnetAppGatewayName
    nsgAppGateway_id: nsgAppGateway.id
    subnet_appGatewayAddressPrefix: subnetApplicationGatewayAddressPrefix
    vnetName: vnetName
  }
}


// ---- Create Network Security Groups (NSGs) ----
resource nsgAppGateway 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgAppGatewayName
  location: location
  properties: {
    securityRules: [
      {
        name: 'agw-in'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          description: 'App Gateway inbound'
          priority: 100
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
        }
      }
      {
        name: 'https-in'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
          description: 'Allow HTTPS Inbound'
        }
      }
    ]
  }
}


// ---- Public IP Address ----
resource applicationGatewayPublicIpAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: appGatewayPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}


// ---- Azure Application Gateway ----
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-06-01' = {
  name: applicationGatewayName
  location: location
  
  identity: {
    type: 'SystemAssigned' 
  }

  properties: {
    sku: sku
    autoscaleConfiguration:
    enableHttp2:
    gatewayIPConfigurations:
  }
  tags: tags
  zones: zones 
}


resource applicationGatewayDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: applicationGateway
  name: 'diagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace_id
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
