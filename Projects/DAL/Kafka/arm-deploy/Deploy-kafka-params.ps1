$DeployType = "kafka"
$deploymentName = "$DeployType-$(get-date -f yyyymmdd_HHmm)"
$TemplateFile = "arm-$DeployType.json"

. ./Import-Csv2Vars.ps1
$resourceGroupName = $resourceGroupNameKafka
$vnet = Get-AzureRmVirtualNetwork -WarningAction SilentlyContinue | ? Name -eq $vnetName
$VNetId = $vnet.Id

$TemplateParameterObject = @{
	ClusterName              = $ClusterName
	ClusterVersion           = "{0:d3}" -f $ClusterVersion
	ClusterWorkerNodeCount   = [int]$ClusterWorkerNodeCount
	ClusterKind              = $ClusterKind
	ClusterLoginPassword     = $ClusterLoginPassword
	ClusterLoginUserName     = $ClusterLoginUserName
	ScriptNodeHead           = $ScriptNodeHead
	ScriptNodeWorker         = $ScriptNodeWorker
	ScriptNodeZookeeper      = $ScriptNodeZookeeper
	ScriptStorageAccountName = $ScriptStorageAccountName	
	SrvPass                  = $SrvPass
	SshPassword              = $SshPassword
	SshUserName              = $SshUserName
	StorageAccountName       = $StorageAccountName
	VNetId                   = $VNetId
	VNetSubnetName           = $VNetSubnetName
	VmSizeHeadNode           = $VmSizeHeadNode
	VmSizeWorkerNode         = $VmSizeWorkerNode
	VmSizeZookeeperNode      = $VmSizeZookeeperNode
}

Try {
	Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
}
Catch {
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue -Confirm:$false -Force
}

Test-AzureRmResourceGroupDeployment -Verbose -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameterObject
New-AzureRmResourceGroupDeployment -Name $DeploymentName -Verbose -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameterObject
