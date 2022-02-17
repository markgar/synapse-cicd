$deploymentName = Get-Date -Format "yyyyMMddHHmmss"
$rgName = "synapse-demo"
$sqlAdminPassword = ${{ secrets.SYNAPSE_SQL_ADMIN_PASSWORD }}

az group create -n $rgName --location eastus
az deployment group create -g $rgNameo --template-file ./main.bicep --parameters "synapseSqlAdminPassword=$sqlAdminPassword" --name $deploymentName
