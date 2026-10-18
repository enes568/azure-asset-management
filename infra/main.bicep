// Azure Asset Manager: Backend als Code
// Legt Function App (PowerShell) mit Managed Identity an und gibt ihr die Rolle "Reader"
// auf die Ressourcengruppe, in die deployt wird (Least Privilege).

@description('Kurzer Name für alle Ressourcen, nur Kleinbuchstaben und Ziffern, max. 12 Zeichen.')
@maxLength(12)
param baseName string = 'assetdemo'

@description('Region der Ressourcen. Standard ist die Region der Ressourcengruppe.')
param location string = resourceGroup().location

@description('Adresse des Dashboards, das die API aufrufen darf (CORS).')
param dashboardOrigin string

var suffix = uniqueString(resourceGroup().id)
var storageName = take('st${baseName}${suffix}', 24)
var functionName = 'func-${baseName}-${take(suffix, 6)}'
var planName = 'asp-${baseName}'
var workspaceName = 'log-${baseName}'
var insightsName = 'appi-${baseName}'

// Eingebaute Rolle "Reader"
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: insightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

// Verbrauchstarif (Windows): keine Kosten im Leerlauf
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

var storageConnection = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storage.listKeys().keys[0].value}'

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      powerShellVersion: '7.4'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: [
          dashboardOrigin
        ]
      }
      appSettings: [
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'powershell' }
        { name: 'AzureWebJobsStorage', value: storageConnection }
        { name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING', value: storageConnection }
        { name: 'WEBSITE_CONTENTSHARE', value: toLower(functionName) }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: insights.properties.ConnectionString }
        // Werden von run.ps1 gelesen
        { name: 'SUBSCRIPTION_ID', value: subscription().subscriptionId }
        { name: 'RESOURCE_GROUP', value: resourceGroup().name }
      ]
    }
  }
}

// Anmeldung per Benutzername und Passwort abschalten (Deployment läuft per OIDC)
resource scmPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: functionApp
  name: 'scm'
  properties: {
    allow: false
  }
}

resource ftpPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: functionApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

// RBAC: Die Identität der Function darf die Ressourcengruppe nur lesen
resource readerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, functionApp.id, readerRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppName string = functionApp.name
output functionHostName string = functionApp.properties.defaultHostName
output principalId string = functionApp.identity.principalId
