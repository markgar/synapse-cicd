param workspaceName string
param location string
param defaultDataLakeStorageAccountName string
param defaultDataLakeStorageFilesystemName string
param sqlAdministratorLogin string

@secure()
param sqlAdministratorLoginPassword string = ''
param setWorkspaceIdentityRbacOnStorageAccount bool
param createManagedPrivateEndpoint bool
param defaultAdlsGen2AccountResourceId string = ''
param allowAllConnections bool = true

@allowed([
  'default'
  ''
])
param managedVirtualNetwork string
param tagValues object = {}
param storageSubscriptionID string = subscription().subscriptionId
param storageResourceGroupName string = resourceGroup().name
param storageLocation string = resourceGroup().location
param storageRoleUniqueId string = newGuid()
param isNewStorageAccount bool = false
param isNewFileSystemOnly bool = false
param adlaResourceId string = ''
param managedResourceGroupName string = ''
param storageAccessTier string
param storageAccountType string
param storageSupportsHttpsTrafficOnly bool
param storageKind string
param minimumTlsVersion string
param storageIsHnsEnabled bool
param userObjectId string = ''
param setSbdcRbacOnStorageAccount bool = false
param setWorkspaceMsiByPassOnStorageAccount bool = false
param workspaceStorageAccountProperties object = {}

var storageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var defaultDataLakeStorageAccountUrl = 'https://${defaultDataLakeStorageAccountName}.dfs.core.windows.net'

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: defaultDataLakeStorageAccountUrl
      filesystem: defaultDataLakeStorageFilesystemName
      resourceId: defaultAdlsGen2AccountResourceId
      createManagedPrivateEndpoint: createManagedPrivateEndpoint
    }
    managedVirtualNetwork: managedVirtualNetwork
    managedResourceGroupName: managedResourceGroupName
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
  }
  tags: tagValues
  dependsOn: [
    storageAccount
    //'Microsoft.Resources/deployments/${defaultDataLakeStorageFilesystemName}'
  ]
}

resource name_allowAll 'Microsoft.Synapse/workspaces/firewallrules@2021-06-01' = if (allowAllConnections) {
  parent: synapseWorkspace
  name: 'allowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' = if (isNewStorageAccount) {
  name: defaultDataLakeStorageAccountName
  location: storageLocation
  properties: {
    accessTier: storageAccessTier
    supportsHttpsTrafficOnly: storageSupportsHttpsTrafficOnly
    isHnsEnabled: storageIsHnsEnabled
    minimumTlsVersion: minimumTlsVersion
  }
  sku: {
    name: storageAccountType
  }
  kind: storageKind
  tags: {}
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-01-01' = if (isNewStorageAccount) {
  name: '${defaultDataLakeStorageAccountName}/default/${defaultDataLakeStorageFilesystemName}'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccount
  ]
}

// I'M NOT USING THIS
// module deployStorage './nested_defaultDataLakeStorageFilesystemName_resource.bicep' = if (isNewFileSystemOnly) {
//   name: defaultDataLakeStorageFilesystemName
//   scope: resourceGroup(storageSubscriptionID, storageResourceGroupName)
//   params: {
//     defaultDataLakeStorageAccountName: defaultDataLakeStorageAccountName
//     defaultDataLakeStorageFilesystemName: defaultDataLakeStorageFilesystemName
//   }
// }

module deployStorageRoles './nested_StorageRoleDeploymentResource.bicep' = if (setWorkspaceIdentityRbacOnStorageAccount) {
  name: 'StorageRoleDeploymentResource'
  scope: resourceGroup(storageSubscriptionID, storageResourceGroupName)
  params: {
    reference_concat_Microsoft_Synapse_workspaces_parameters_name_2021_06_01_Full_identity_principalId: reference('Microsoft.Synapse/workspaces/${workspaceName}', '2021-06-01', 'Full')
    resourceId_Microsoft_Authorization_roleDefinitions_variables_storageBlobDataContributorRoleID: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleID)
    variables_storageBlobDataContributorRoleID: storageBlobDataContributorRoleID
    defaultDataLakeStorageAccountName: defaultDataLakeStorageAccountName
    name: workspaceName
    storageRoleUniqueId: storageRoleUniqueId
    storageLocation: storageLocation
    setSbdcRbacOnStorageAccount: setSbdcRbacOnStorageAccount
    userObjectId: userObjectId
  }
  dependsOn: [
    synapseWorkspace
  ]
}

// NOT USING THIS
// module UpdateStorageAccountNetworkingAcls './nested_UpdateStorageAccountNetworkingAcls.bicep' = if (setWorkspaceMsiByPassOnStorageAccount) {
//   name: 'UpdateStorageAccountNetworkingAcls'
//   scope: resourceGroup(storageSubscriptionID, storageResourceGroupName)
//   params: {
//     storageLocation: storageLocation
//     defaultDataLakeStorageAccountName: defaultDataLakeStorageAccountName
//     workspaceStorageAccountProperties: workspaceStorageAccountProperties
//   }
//   dependsOn: [
//     synapseWorkspace
//   ]
// }
