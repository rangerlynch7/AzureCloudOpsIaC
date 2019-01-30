$DeployType = "DnsForward"
$DeploymentName = "$DeployType-$(get-date -f yyyymmdd_HHmm)"
$TemplateFile = "arm-$DeployType.json"
# $Template=get-content $TemplateFile | ConvertFrom-Json -AsHashtable
# $Template.Keys
# $Template.resources

. ./Set-VarsOs.ps1
$resourceGroupName = $HdiResourceGroupName

# validation
Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction Stop | out-null
$VNet = Get-AzureRmVirtualNetwork -WarningAction SilentlyContinue | ? Name -eq $VNetName
if ($null -eq $VNet.Id) {throw "VNetId null"}
if ($vnet.Subnets.Name -notcontains $VNetSubnetName) { throw "[$VNetSubnetName] subnet is not one of the available [$($vnet.Subnets.Name -join ",")]" }

# upload setup script & generate sas token
$StorageAccount=Get-AzureRmStorageAccount | ? StorageAccountName -eq $PrjScriptStorageAccountName
if ($null -eq $StorageAccount) { Throw "$StorageAccount not found" }
Get-AzureStorageContainer -Context $StorageAccount.Context -Name $PrjScriptStorageContainerName -ErrorAction Stop | out-null
$FullName=Get-ChildItem -Path $DnsForwardScriptName -ErrorAction Stop | % FullName
$ICloudBlob=Set-AzureStorageBlobContent -File $FullName -Container $PrjScriptStorageContainerName -Blob $DnsForwardScriptName -Context $StorageAccount.Context -BlobType Block -Force 
$StartTime = Get-Date; $EndTime = $startTime.AddHours(2.0)
$SASToken=New-AzureStorageBlobSASToken -Container $PrjScriptStorageContainerName -Blob $DnsForwardScriptName -Permission rd -ExpiryTime $EndTime -Context $StorageAccount.Context
$DnsForwardScriptUrl=$ICloudBlob.ICloudBlob.Uri.AbsoluteUri+$SASToken
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
	VNetSubnetName	= $VNetSubnetName
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