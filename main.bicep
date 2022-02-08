var unq = '${uniqueString(subscription().id, resourceGroup().id)}'
var storageAccountName = 'stg${unq}'
var storageContainerName = 'lakeroot'
var synapseWorkspaceName = 'syn-${unq}'

resource myStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
  }
}

resource myStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageAccountName}/default/${storageContainerName}'
  properties: {
    publicAccess: 'Container'
  }
  dependsOn: [
    myStorage
  ]
}

resource mySynapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: resourceGroup().location
  properties: {
    defaultDataLakeStorage: {
      filesystem: storageContainerName
      accountUrl: 'https://${storageAccountName}.dfs.core.windows.net'
    }
    sqlAdministratorLogin: 'mgarner'
    sqlAdministratorLoginPassword: 'alkjsdhflakjdh!A'
    managedVirtualNetwork: 'default'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource synapseFirewall_AllowAllAzureIps 'Microsoft.Synapse/workspaces/firewallrules@2019-06-01-preview' = {
  parent: mySynapse
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource workspaceName_allowAll 'Microsoft.Synapse/workspaces/firewallrules@2019-06-01-preview' = {
  parent: mySynapse
  name: 'allowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource workspaceName_managedIdentityStuff 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2019-06-01-preview' = {
  parent: mySynapse
  name: 'default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState: 'Enabled'
    }
  }
}

resource Microsoft_Authorization_roleAssignments_dlsName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: mySynapse
  name: guid(uniqueString(myStorage.name))
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: reference(mySynapse.id, '2019-06-01-preview', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}
