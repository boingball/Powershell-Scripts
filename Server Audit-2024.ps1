#Server Audit - Need 100% pass to be clean.
#Date/Time Strings
$time = (Get-Date).ToString("HHmmss")
$Date = Get-Date -Format "ddMMyy"
$DomainDetails = Get-ADDomain #AD Domain Details
$ForestDetails = Get-ADForest #AD Forest Details
$OSLevel = (Get-CimInstance Win32_OperatingSystem).Caption #OS Level used for Check 1
$DomainMode = $DomainDetails.DomainMode #DomainMode
$DomainForest = $ForestDetails.ForestMode #DomainForest
$DNSRoot = $DomainDetails.DNSRoot #server.local
$InfaMaster = $DomainDetails.InfrastructureMaster #Server running AD
$PDCEmulator = $DomainDetails.PDCEmulator #PDC 
$RIDMaster = $DomainDetails.RIDMaster 
$DomainNamingMaster = $ForestDetails.DomainNamingMaster
$SchemaMaster = $ForestDetails.SchemaMaster 
$DomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy #Domain Password Policy
$PasswordPolicyComplex = $DomainPasswordPolicy.ComplexityEnabled #Should be True
$PasswordPolicyLockoutDuration = $DomainPasswordPolicy.LockoutDuration #Should be 15-30+
$PasswordPolicyMinPasswordLength = $DomainPasswordPolicy.MinPasswordLength #Should be 8+
$PasswordPolicyHistoryCount = $DomainPasswordPolicy.PasswordHistoryCount #Sould be <15
#$PasswordPolicyKerberos = $DomainPasswordPolicy.KerberosTicketPolicy
$DelegatedUSers = Get-ADUser -Filter {TrustedForDelegation -eq $true} #Check DelegatedUsers
$Kerberoasting = Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName #Check Kerber Account
$DomainUsersLastLogin = Get-ADUser -Filter * -Properties LastLogonDate, Enabled | Where-Object {$_.LastLogonDate -ne $null -and $_.Enabled -eq $true} | Select-Object Name, LastLogonDate #Last Logins
$PrivilegedAccounts = Get-ADUser -Filter {AdminCount -eq 1} | Select-Object Name, SamAccountName #PriviligedAccounts
$HighValueAccounts = Get-ADUser -Filter {ServicePrincipalName -ne "$null" -and MemberOf -like "*Domain Admins*"} | Select-Object Name, ServicePrincipalName #HighValueAccounts
$SessionsOnServer = qwinsta.exe /server:$InfaMaster #SessionsonDC
$DNSServers = Get-DnsServerResourceRecord -ZoneName $DomainDetails.Forest #DNSServerDetails
$DomainAdmins = Get-ADGroupMember -Identity "Domain Admins" #Domain-Admin
$FailedAudit = $false
$Report = ""

#Server Info
$Report += "Server Audit Check v1.0 - " + $date + " " + $time +"`n"
$Report += "__________________________________________________`n"
$Report += "Server Infra Master - " + $InfaMaster +"`n"
$Report += "Server PDC Master - " + $PDCEmulator +"`n"
$Report += "Server RID Master - " + $RIDMaster +"`n"
$Report += "Server Domain Naming Master - " + $DomainNamingMaster +"`n"
$Report += "Server SchemaMaster - " + $SchemaMaster +"`n"
$Report += "`n"
$Report += "Domain Admin Count : " + $DomainAdmins.count + "`n"

foreach ($DomainUsers in $DomainAdmins){
    $Report += $DomainUsers.name + "`n"
}
$Report += "`n"
#Check what active sessions we have on server
$ActiveSessions = ""
$ActiveSessions = ($SessionsOnServer -like "*active*")
if("" -ne $ActiveSessions) {$Report += "Failed - Active Session - found on server`n"
$Report += "Active Sessions : " + $ActiveSessions
$FailedAudit = $true} else {$Report+= "Active Sessions - No active session on server`n"}
$Report += "`n`n"
$DomainCheckResult = "Failed - Didn't Check correctly"
#1) - OSLevel vs Forest and Domain Level
#Check if the OSLevel is the same as the Forest Level - 2016 is maximum at the moment
#2012 Check
if($OSLevel -like "*2012*") {
    if($DomainMode -like "*2012R2*" -and $DomainForest -like "*2012R2*") { #Passed
        $DomainCheckResult = "Passed - Setup 2012R2"
    } else {
        $DomainCheckResult = "Failed - Supposed to be 2012R2 Setup"
        $DomainCheckResult += $DomainMode + " " + $DomainForest
        $FailedAudit = $true
        #Failed
    }
}
#2016/2019/2022 Check
if($OSLevel -like "*2016*" -or $OSLevel -like "*2019*" -or $OSLevel -like "*2022*"){
    if($DomainMode -like "*2016*" -and $DomainForest -like "*2016*") { #Passed
         $DomainCheckResult = "Passed - Setup 2016 Setup"
        } else {
            $DomainCheckResult = "Failed - Supposed to be 2016+ Setup"
            $DomainCheckResult += $DomainMode + " " + $DomainForest
            $FailedAudit = $true
        }
}
#----------------------------------------------------------------------------------
$Report += "--Domain Check --`n"
$Report += "OS Level : " + $OSLevel +"`n"
$Report += "Domain Level : " + $DomainMode +"`n"
$Report += "Forest Level : " + $DomainForest +"`n"
$Report += "Domain Level Result : " + $DomainCheckResult +"`n"

#2) - $DNSRoot
$Report += "`n"
$Report += "--DNS Check-- `n"
$Report += $DNSRoot
$Report += "`n"

#3) - Password Policy
$Report += "`n"
$Report += "--Password Policy-- `n"
$PasswordCheckResult = ""
#Password Complexity Check
if($PasswordPolicyComplex -ne $true) {$PasswordCheckResult += "Failed - Password Policy has Complexity turned off`n"
$FailedAudit = $true} else {
    $PasswordCheckResult += "Passed - Password Complexity On`n"
}
#Password Lockout Time check
if($PasswordPolicyLockoutDuration.Minutes -lt 30) {$PasswordCheckResult += "Failed - Password Lockout is less than 30 minutes`n"
$FailedAudit = $true} else {
    $PasswordCheckResult += "Passed - Lockout Duration 30Mins or Greater : " + $PasswordPolicyLockoutDuration.Minutes + "`n"
}
#Password Min Password Length
if($PasswordPolicyMinPasswordLength -lt 8) {$PasswordCheckResult += "Failed - Password length is less than 8`n"
$FailedAudit = $true} else {
    $PasswordCheckResult += "Passed - Password Length Greater - Equal than 8 : " + $PasswordPolicyMinPasswordLength  + "`n"
}
#Password History (gt 14)
if($PasswordPolicyHistoryCount -lt 15) {$PasswordCheckResult += "Failed - Password History less than 15 `n"
$FailedAudit = $true} else {
    $PasswordCheckResult += "Passed - Password History Greater - Equal to 15 " +$PasswordPolicyHistoryCount + "`n"
}
$Report += $PasswordCheckResult

#4) Deligated Access and HighValue Accounts
$Report += "`n"
$Report += "--Delegated Access and HighValue Accounts --"
$Report += "`n"
$DelegatedUsersCheck  = ""
if($DelegatedUSers.count -gt 0) {$DelegatedUsersCheck += "Failed - We have delegated users in this domain`n"
$DelegatedUsersCheck += $DelegatedUSers
$DelegatedUsersCheck += "`n"
$FailedAudit = $true} else {
    $DelegatedUsersCheck += "Passed - No delegated users found`n"
}
$HighValueAccountsCheck = ""
if($HighValueAccounts.count -gt 0) {$HighValueAccountsCheck += "Failed - We have HighValue accounts in this domain`n"
$FailedAudit = $true} else {
    $HighValueAccountsCheck += "Passed - No HighValue Accounts found in this domain`n"
}
$Report += $DelegatedUsersCheck
#Priviliged Users - Should just be our normal accounts on here
$Report += "`n"
$Report += "--Privileged Accounts--`n"
foreach($item in $PrivilegedAccounts){
    $Report += $item.name + "`n"
}

#Kerberroasting


#5)User Login Times
$Report += "`n"
$Report += "--Domain Users Last Login--`n"
$Report += "___________________________`n"
foreach ($user in $DomainUsersLastLogin)
{
    $Report += $user.Name + " " + $user.LastLogonDate + "`n"
}


$Report += "`n"
if($FailedAudit = $true) {$Report += "`n FAILED AUDIT `n"}
#Print Report 
$Report

