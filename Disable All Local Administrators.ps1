#Disable and remove all extra local Administrators Accounts and Remove the local Administrator permissions from End Users v1.0
#InfoSec - 210324
#Administrator / Any other account you need to add to the list at the bottom
#Needs upgraded to #Get-LocalUser | ? {$_.SID -like "*-500"}

$RemoveAccounts = 1
#Need to get a list of all Local Admins on the computer (Try as breaks on some Powershell Versions)
try {
    $ListofAdmins = Get-LocalGroupMember -Group "Administrators" | Select-Object * | Where-Object PrincipalSource -eq Local
}
catch {
    WRITE-HOST "Powershell Bug getting list of Local Admins - trying alternative method"
    $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators"
    $admins = $group.Invoke('Members') | ForEach-Object {
        $path = ([adsi]$_).path
        [pscustomobject]@{
            Computer = $env:COMPUTERNAME
            Domain = $(Split-Path (Split-Path $path) -Leaf)
            User = $(Split-Path $path -Leaf)
        }
    }
    #Setup an Admin Table and put a SID Field in there
    $admins | Add-Member -MemberType NoteProperty -Name SID -Value "NA"
    #Code to update all users with SIDS
    foreach($User in $admins){
        #Get SID of Current user
        if($User.User -ne "Domain Admins"){
        $SID = Get-LocalUser -Name $User.User | Select-Object -ExpandProperty SID
        $SelectedUser = $admins| Where-Object -Property User -eq $User.User
        $SelectedUser.SID = $SID
        }
        }
    #Create a list of all Administrators
    $ListofAdmins = $admins | Select-Object * | Where-Object User -ne "Domain Admins"
}

#Get list of AD Admin accounts on the computer - Skipping Domain Admin groups
try {
    $ListofNonLocalAdmins = Get-LocalGroupMember -Group "Administrators" | Select-Object * | Where-Object {($_.PrincipalSource -eq "ActiveDirectory") -and ($_.ObjectClass -eq "User")}
}
catch {
    #Need code to emulate this 
    $ListofNonLocalAdmins = $false
}

$ConvertToNames = @()
$ProcessedAccounts = @()
$RandomPassword = -Join("ABCDabcd&@#$%!12345678".tochararray() | Get-Random -Count 22 | ForEach-Object {[char]$_})
$SecurePassword = ConvertTo-SecureString $RandomPassword -AsPlainText -Force

#Read more: https://www.sharepointdiary.com/2020/04/powershell-generate-random-password.html#ixzz8V7HvJ6Bm
#Get Logged in User Currently
try {
$LoggedOnUser = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object UserName).UserName.Split('\')[1] 
} catch {
    $LoggedOnUser = "No Logged in User"
}
WRITE-HOST "Found List of Admins"
WRITE-HOST $ListofAdmins

#List of Accounts to Disable
$ListofAccountsforDisable = [System.Collections.ArrayList]@()
[void]$ListofAccountsforDisable.Add("AdminAccount")
[void]$ListofAccountsforDisable.Add("Administrator")
#Get-LocalUser | ? {$_.SID -like "*-500"}
[void]$ListofAccountsforDisable.Add("OtherAdmin")
[void]$ListofAccountsforDisable.Add("AnotherAdmin")
#Convert the List of Admins to Names to process
$ConvertToNames = Get-LocalUser -SID $ListofAdmins.SID | Select-Object Name -ExpandProperty Name


#Loop through all admin accounts found and if it's on the Disabled list - disable
foreach ($Name in $ConvertToNames){
    if($ListofAccountsforDisable.Contains($Name)){
    $Name | Disable-LocalUser
    WRITE-HOST $Name " Disabled"

    }
}

#Scamble Admin Account Password (Use LAPS to control it)
Set-LocalUser -Name "Administrator" -Password $SecurePassword -Description "LAPS Controlled Account"
WRITE-HOST "Administrator"

#Now we need to remove extra local admins from the machine
#The Administrator default cannot be removed from the system but it should have beeen renamed
$ListofAccountsforDisable.Remove("Administrator")
#Loop through to remove these accounts from the system
if($RemoveAccounts -eq 1){
foreach ($Name in $ListofAccountsforDisable){
    If(Get-LocalUser $Name -ErrorAction SilentlyContinue){
        WRITE-HOST "Removing : " $Name
        $Name | Remove-LocalUser
    }
}
}
#Now to remove the Domain User / Administrators
if($ListofNonLocalAdmins -eq $false){
    WRITE-HOST "List of Non Local Admins Failed - Intune Device?"

}else{
foreach ($NonName in $ListofNonLocalAdmins){
       Remove-LocalGroupMember -Group "Administrators" -Member $NonName
       WRITE-HOST "Removed Local Admin from " $NonName
}
}

WRITE-HOST "All Complete"
