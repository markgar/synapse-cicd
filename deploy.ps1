$deploymentName = Get-Date -Format "yyyyMMddHHmmss"

az deployment group create -g synapse-cicd --template-file ./main.bicep --name $deploymentName