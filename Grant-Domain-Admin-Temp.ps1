#Create a Temporary Domain Admin to for one off use - WIP - Expires withing 30 minutes
#Run on Domain Controller running Server 2012r2 - needs name as a argument

#Enable TLS1.2 - Without it, Tickets will not be generated in Deskpro
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Install RSAT-AD-PowerShell
Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature -ErrorAction SilentlyContinue
#Import AD Module for use
Import-Module -Name ActiveDirectory
#Get Time
$time = (Get-Date).ToString("ddMMyyyy-HHmmss")
$date = (Get-Date).ToString("HHmmss")
#Get HostName
$AssetTag = hostname
#Takes Username from Command Line
$ParamUserName=$args[0]
if($ParamUserName -eq "Your.Name" -or $ParamUserName -eq "YourName"){
    WRITE-HOST "Please enter Your real name before running command"
    exit 1000}

if ($null -ne $ParamUserName){
    $ParamUserName=$args[0]
    $ParamUserName = $ParamUserName + "" + $date
    WRITE-HOST "Username Has been Passed Over " + $ParamUserName
    WRITE-HOST "Creating a Temp Domain Admin for IT Use"
   # WRITE-HOST "This Account will expire within one hour"
    $RandomPassword = -Join("ABCDEFGabcdefg&@#!1234567890".tochararray() | Get-Random -Count 25 | ForEach-Object {[char]$_})
    #Read more: https://www.sharepointdiary.com/2020/04/powershell-generate-random-password.html#ixzz8GOpgwejf
    $UserName = "admin.$ParamUserName"
    if($UserName.Length -gt 20){
        $Username = $UserName.Substring(0,20)
    }
    $ADPassword = ConvertTo-SecureString -AsPlainText -Force -String $RandomPassword
    #Find the OU which is for IT Admin access
    $ITAdminOU = Get-ADOrganizationalUnit -Filter 'Name -like "*OU-With-IT-Access*"'
    New-ADUser -Name $UserName -Description "Temp Domain Admin for $ParamUserName - $time" -Enabled $true -AccountPassword $ADPassword -Path $ITAdminOU.DistinguishedName -AccountNotDelegated $true
    Add-ADGroupMember -Identity "Domain Admins" -Members $UserName
    Add-ADGroupMember -Identity "Protected Users" -Members $UserName
    if($DeskProEnabled -eq $true){
      }
    WRITE-HOST "Domain Admin : $UserName"
    WRITE-HOST "Password : $RandomPassword"
    Set-ADAccountExpiration -Identity $UserName -TimeSpan 0.0:30:0.0
    WRITE-HOST "Account Will be Disabled in 30 Minutes - Sheduled"
    #Start-Sleep -Duration (New-TimeSpan -Minutes 30)
    #Remove-ADGroupMember -Identity "Domain Admins" -Member $UserName -Confirm:$False
    #Remove-ADUser -Identity $UserName -Confirm:$False

  }else{
      <# Action when all if and elseif conditions are false #>
      WRITE-HOST "No Username Entered - Enter your username"
      exit 1000
  }

