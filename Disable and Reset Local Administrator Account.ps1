
# Define the local administrator account name
$adminUserName = "Administrator"

# Define the new password
$newPassword = -Join("ABCDEFGabcdefghijklmnopqrstuvwxyz&@#!1234567890".tochararray() | Get-Random -Count 40 | ForEach-Object {[char]$_})
# Reset the password for the Administrator account
$securePassword = ConvertTo-SecureString $newPassword -AsPlainText -Force
Set-LocalUser -Name $adminUserName -Password $securePassword

# Disable the Administrator account
Disable-LocalUser -Name $adminUserName

Write-Output "The password for the Administrator account has been reset and the account has been disabled."