$MyInvocation.MyCommand.Source | split-path | set-Location
Get-ChildItem -File -Recurse -Include *.ps1 | % { Rename-Item -Path $_.PSPath -NewName $_.Name.replace(".ps1",".ps1.txt")}
