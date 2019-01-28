$CsvFile="arm-kafka-params.csv"
$Column="arm-kafka-params-rg.json" 
$Delimiter=","

$HtParams=[ordered]@{}
$Objects=get-content $CsvFile -ErrorAction Stop | ConvertFrom-Csv -Delimiter $Delimiter 
$Object=$Objects[0]
foreach ($Object in $Objects) {
	$Key=$Object.Parameter 
	$Value=$Object.$Column
	#"$Key=$Value"
	Set-Variable -Name $Key -Value $Value
	$HtParams[$Key]=$Value
}
# $HtParams | ConvertTo-Json
$HtParams["Location"]