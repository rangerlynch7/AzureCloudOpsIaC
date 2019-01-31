$BaseDir = Split-Path $MyInvocation.MyCommand.Path
$CsvFile="$BaseDir/dal-params.csv"
Get-ChildItem $CsvFile -ErrorAction Stop | Out-Null
$Ctx=Get-AzureRmContext 
if ($Ctx.Account.Id -match "objectsharp") {
	$Column="rgobjectsharp" 
} else {
	$Column="INF NPE" 
}
. $BaseDir/script-posh/Import-Csv2Vars.ps1 -CsvFile $CsvFile -Column $Column
<#
code $BaseDir/script-posh/Import-Csv2Vars.ps1
#>
Import-Module "$BaseDir/Dal-Module.psm1" -ErrorAction Stop
