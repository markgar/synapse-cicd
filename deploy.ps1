$deploymentName = Get-Date -Format "yyyyMMddHHmmss"

az deployment group create -g synapse-cicd-3 --template-file ./main.bicep --parameters main.parameters.json --name $deploymentName
