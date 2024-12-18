#Remove Local Admin rights from logged on user if they are in the Local Administrators Group
#Set to True to do the automated removal
$removeAdmin = $false

#Get Logged in User Currently
$LoggedOnUser = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object UserName).UserName.Split('\')[1] 

#Array to start the list of users in the Administrators Group
$admins = New-Object System.Collections.ArrayList
#Using this method due to a bug in Get-LocalGroupMember that seems to not work with AzureAD accounts
$group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators"
    $admins = $group.Invoke('Members') | ForEach-Object {
        $path = ([adsi]$_).path
        [pscustomobject]@{
            Computer = $env:COMPUTERNAME
            Domain = $(Split-Path (Split-Path $path) -Leaf)
            User = $(Split-Path $path -Leaf)
        }
    }
foreach($admin in $admins){
    #For some reason this exceptions and trys to add a duplicate value - Try catch to stop console errors
   try {
    $admins.Add($admin)
   }
   catch {
    <#Do this if a terminating exception happens#>
   }
}
$admins
#Check if the LoggedOnUser is in the Admin List
if($admins.Contains($LoggedOnUser) -eq $true -and $removeAdmin -eq $true)
{
Remove-LocalGroupMember -Group "Administrators" -Member $LoggedOnUser 
}


