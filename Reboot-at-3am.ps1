$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "& {Restart-Computer -Force -wait}"'
$trigger = New-ScheduledTaskTrigger -Once -At 3am
$taskname = 'ScheduledReboot'
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$params = @{
Action  = $action
Trigger = $trigger
TaskName = $taskname
Principal = $principal
}

    if(Get-ScheduledTask -TaskName $params.TaskName -EA SilentlyContinue) { 
        Set-ScheduledTask @params
     }
    else {
        Register-ScheduledTask @params
    }