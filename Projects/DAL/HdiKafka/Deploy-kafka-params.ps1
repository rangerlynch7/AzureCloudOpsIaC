$DeployType = "kafka"
$deploymentName = "$DeployType-$(get-date -f yyyymmdd_HHmm)"
$TemplateFile = "arm-$DeployType.json"

# Setup
$ScriptItem=$MyInvocation.MyCommand.Path | get-childitem
$ScriptItem.Directory | set-location
$BaseDir=$ScriptItem.Directory.Parent.FullName
"BaseDir=$BaseDir"
. $BaseDir/Set-Vars.ps1

# Validation
$ResourceGroupName = $HdiResourceGroupName
Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Stop | % ResourceId | out-null
$VNet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $VNetResourceGroupName -ErrorAction Stop
if ($vnet.Subnets.Name -notcontains $HdiVNetSubnetName) { throw "[$HdiVNetSubnetName] subnet is not one of the available [$($vnet.Subnets.Name -join ",")]" }

$TemplateParameterObject = [ordered]@{
	CertSrvPass = $CertSrvPass
	HdiClusterName = $HdiClusterName
	HdiLoginPassword = $HdiLoginPassword
	HdiLoginUserName = $HdiLoginUserName
	HdiScriptUriHead = Get-ChildItem -Filter $HdiScriptHead -Recurse | % FullName | % { Send-StorageUri -StorageAccountName $PrjScriptStorageAccountName -FilePath $_ -ContainerName $PrjScriptStorageContainerName }
	HdiScriptUriWorker = Get-ChildItem -Filter $HdiScriptWorker -Recurse | % FullName | % { Send-StorageUri -StorageAccountName $PrjScriptStorageAccountName -FilePath $_ -ContainerName $PrjScriptStorageContainerName }
	HdiScriptUriZookeeper = Get-ChildItem -Filter $HdiScriptZookeeper -Recurse | % FullName | % { Send-StorageUri -StorageAccountName $PrjScriptStorageAccountName -FilePath $_ -ContainerName $PrjScriptStorageContainerName }
	HdiSshPassword = $HdiSshPassword
	HdiSshUserName = $HdiSshUserName
	HdiStorageAccountName = $HdiStorageAccountName
	HdiTier = $HdiTier
	HdiVNetSubnetName = $HdiVNetSubnetName
	HdiVersion = "{0:n1}" -f [int]$HdiVersion
	HdiVmSizeHeadNode = $HdiVmSizeHeadNode
	HdiVmSizeWorkerNode = $HdiVmSizeWorkerNode
	HdiVmSizeZookeeperNode = $HdiVmSizeZookeeperNode
	HdiCountWorker = [int]$HdiCountWorker
	VNetId = $VNet.Id
}
"TemplateParameterObject"
$TemplateParameterObject | ConvertTo-Json 
$TemplateParameterObject | ConvertTo-Json > TemplateParameterObject.json; code TemplateParameterObject.json

Try {
	Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction Stop | out-null
}
Catch {
	New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction SilentlyContinue -Confirm:$false -Force -verbose | out-null
}

"Deploy ..."
Test-AzureRmResourceGroupDeployment -Verbose -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameterObject -ErrorAction Stop
New-AzureRmResourceGroupDeployment -Name $DeploymentName -Verbose -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameterObject
