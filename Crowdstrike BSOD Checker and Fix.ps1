#Crowdstrike BSOD Checker
#Check if computer is in safe mode
$SafeModeCheck = Get-WmiObject win32_computersystem | Select-Object BootupState
if ($SafeModeCheck.BootupState -eq "Fail-safe with network boot")
{

$CrowdStrikeFile = Test-Path "c:\windows\system32\drivers\CrowdStrike\C-00000291-00000000-00000032.sys"
$CrowdStrikeOtherFiles = Test-Path "C:\windows\system32\drivers\CrowdStrike\C-00000291*.sys"
Write-Host "Safe Mode is Enabled and the following files are found"
write-host $CrowdStrikeFile
Write-host $CrowdStrikeOtherFiles

if ($CrowdStrikeFile -eq $true -or $CrowdStrikeOtherFiles -eq $true){
    Remove-Item "c:\windows\system32\drivers\CrowdStrike\C-00000291-00000000-00000032.sys"
Remove-Item "C:\windows\system32\drivers\CrowdStrike\C-00000291*.sys"
start-sleep -Seconds 30
Restart-Computer -Force
}
} else { Write-Host "Machine is not in Safe-Mode so Assumed working"}


