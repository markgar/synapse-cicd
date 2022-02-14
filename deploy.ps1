$deploymentName = Get-Date -Format "yyyyMMddHHmmss"

az deployment group create -g synapse-cicd-3 --template-file ./main.bicep --parameters main.parameters.json --name $deploymentName
az synapse role assignment create --workspace-name mynewworkspace-mg --role "Synapse Administrator" --assignee mgarner@microsoft.com