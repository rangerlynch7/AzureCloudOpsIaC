# $CsvFile="../../AzureCloudOpsIaC/Projects/DAL/Data/dal-params.csv"
# $Column="rgobjectsharp" 
param (
    [Parameter(Mandatory=$true)][string]$CsvFile,
    [Parameter(Mandatory=$true)][string]$Column
)

$Delimiter=","
$HtParams=[ordered]@{}
$Objects=get-content $CsvFile -ErrorAction Stop | ConvertFrom-Csv -Delimiter $Delimiter 
$FirstColumn=$Objects | gm | ? MemberType -eq NoteProperty | select -first 1 | % Name
$Object=$Objects[0]
# $Object
foreach ($Object in $Objects) {
	$Key=$Object.$FirstColumn
	$Value=$Object.$Column
	Set-Variable -Name $Key -Value $Value
	$HtParams[$Key]=$Value
	# "$Key=$Value"
}
"HtParams"
$HtParams | ConvertTo-Json
"---"