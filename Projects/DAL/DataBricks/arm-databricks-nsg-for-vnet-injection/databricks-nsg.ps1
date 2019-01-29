$deployType="databricks-nsg"
$templateFilePath="$deployType.json"
Get-ChildItem -Path $templateFilePath -ErrorAction Stop | out-null
$deploymentName="$deployType-$(get-date -f yyyymmdd_HHmm)"
# $context=get-azurermcontext
# $parametersFilePath="$deployType.params.json"
# $subscriptionId=$context.Subscription.Id

$resourceGroupName=$VnetResourceGroupName
Try {
	Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
} Catch {
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue -Confirm:$false -Force
}

$Tags=@{ 
	appsn="Network"
	env="LAB"
}

New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $templateFilePath -nsgName $nsgName -verbose

# ./deploy.ps1 -subscriptionId $subscriptionId -resourceGroupName $VnetResourceGroupName -resourceGroupLocation $resourceGroupLocation -deploymentName $deploymentName -templateFilePath ./azuredeploy.json -parametersFilePath ./azuredeploy.parameters.json

