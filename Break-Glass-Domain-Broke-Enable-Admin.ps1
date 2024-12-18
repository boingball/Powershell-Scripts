#BreakGlass - Domain needs fixed from a remote machine
#Installing RSAT on local machine
WRITE-HOST "Installing RSAT Tools"
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
#Import RSAT Module
import-module ActiveDirectory
WRITE-HOST "Enabling Adminstrator Account"
Enable-ADAccount -Identity 'Administrator'
$RandomPassword = -Join("ABCDabcd&@#$%!12345678".tochararray() | Get-Random -Count 22 | ForEach-Object {[char]$_})
$SecurePassword = ConvertTo-SecureString $RandomPassword -AsPlainText -Force
Set-ADAccountPassword -Identity 'Administrator' -Reset -NewPassword $SecurePassword
WRITE-HOST "Password Set to " $RandomPassword
