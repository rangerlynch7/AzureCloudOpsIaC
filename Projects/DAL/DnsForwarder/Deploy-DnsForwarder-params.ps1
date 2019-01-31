$DeployType = "DnsForward"
$DeploymentName = "$DeployType-$(get-date -f yyyymmdd_HHmm)"
$TemplateFile = "arm-$DeployType.json"
# $Template=get-content $TemplateFile | ConvertFrom-Json -AsHashtable
# $Template.Keys
# $Template.resources

# Setup
$ScriptItem=$MyInvocation.MyCommand.Path | get-childitem
$ScriptItem.Directory | set-location
$BaseDir=$ScriptItem.Directory.Parent.FullName
"BaseDir=$BaseDir"
. $BaseDir/Set-Vars.ps1

# exit

# validation
$resourceGroupName = $HdiResourceGroupName
Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction Stop | out-null
$VNet = Get-AzureRmVirtualNetwork -WarningAction SilentlyContinue | ? Name -eq $VNetName
if ($null -eq $VNet.Id) {throw "VNetId null"}
if ($vnet.Subnets.Name -notcontains $HdiVNetSubnetName) { throw "[$HdiVNetSubnetName] subnet is not one of the available [$($vnet.Subnets.Name -join ",")]" }

# upload setup script & generate sas token
$DnsForwardScriptUrl=Get-ChildItem -Filter $DnsForwardScriptName -Recurse | % FullName | % { Send-StorageUri -StorageAccountName $PrjScriptStorageAccountName -FilePath $_ -ContainerName $PrjScriptStorageContainerName }
# "curl -o $DnsForwardScriptName `'$DnsForwardScriptUrl`'"

"TemplateParameterObject"
$TemplateParameterObject = @{
	DnsForwardAcl	= $DnsForwardAcl
	DnsForwardScriptName = $DnsForwardScriptName
	DnsForwardScriptUrl = $DnsForwardScriptUrl
	DnsForwardTarget	= $DnsForwardTarget
	DnsVmName	= $DnsVmName
	DnsZone = $DnsZone
	VNetName	= $VNetName
	VNetResourceGroupName	= $VNetResourceGroupName
	HdiVNetSubnetName	= $HdiVNetSubnetName
	VmAdminUsername	= $VmAdminUsername
	VmDiagStorageAccName	= $VmDiagStorageAccName
	VmSshPublicKeyData	= $VmSshPublicKeyData
}
$TemplateParameterObject | ConvertTo-Json
# $TemplateParameterObject | ConvertTo-Json > TemplateParameterObject.json; code TemplateParameterObject.json

Try {
	Get-AzureRmResourceGroup -Name $resourceGroupName -Location $Location -ErrorAction Stop | out-null
}
Catch {
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location -ErrorAction SilentlyContinue -Confirm:$false -Force -verbose
}

"Deploy ..."
Test-AzureRmResourceGroupDeployment -Verbose -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameterObject -ErrorAction Stop
New-AzureRmResourceGroupDeployment -Name $DeploymentName -Verbose -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameterObject -ErrorAction Stop

"Stdout & confirm succeeded"
$extout=((Get-AzureRmVM -Name $DnsVmName -ResourceGroupName $resourceGroupName -Status).Extensions | Where-Object {$_.Type -eq "Microsoft.Azure.Extensions.CustomScript"}).statuses.Message
$extout
if ($extout -notmatch "Enable succeeded") {
	throw "Extension failed"
}