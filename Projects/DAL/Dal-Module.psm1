function Send-StorageUri {
	param (
		[Parameter(Mandatory = $true)][string]$StorageAccountName,
		[Parameter(Mandatory = $true)][string]$FilePath,
		[Parameter(Mandatory = $true)][string]$ContainerName
	)

	# upload setup script & generate sas token
	$TokenLifeTime=2
	$StorageAccount = Get-AzureRmStorageAccount | ? StorageAccountName -eq $StorageAccountName
	if ($null -eq $StorageAccount) { Throw "$StorageAccount not found" }
	Get-AzureStorageContainer -Context $StorageAccount.Context -Name $ContainerName -ErrorAction Stop | out-null
	$FullName = Get-ChildItem -Path $FilePath -ErrorAction Stop | % FullName
	$FileName = Get-ChildItem -Path $FilePath -ErrorAction Stop | % Name
	$ICloudBlob = Set-AzureStorageBlobContent -File $FullName -Container $ContainerName -Blob $FileName -Context $StorageAccount.Context -BlobType Block -Force 
	$TokenStartTime = Get-Date
	$TokenStartTime = $TokenStartTime.ToUniversalTime()
	$TokenEndTime = $TokenStartTime.AddHours($TokenLifeTime)
	$SASToken = New-AzureStorageBlobSASToken -Container $ContainerName -Blob $FileName -Permission rd -ExpiryTime $TokenEndTime -Context $StorageAccount.Context
	return $ICloudBlob.ICloudBlob.Uri.AbsoluteUri + $SASToken
}

