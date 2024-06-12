#..LogMeIn Uninstall and Cleanup
#..Darren Banfi - 19/05/2022
#..Version 1.0


#TaskKill Logmein EXE files
taskkill /IM LogMeIn.exe /F
taskkill /IM LMIGuardianSvc.exe /F
taskkill /IM LMIGuardian.exe /F
taskkill /IM LogMeInSystray.exe /F
taskkill /IM ramaint.exe /F

#Run Uninstall Command
Set-Location "C:\Program Files (x86)\LogMEIn\x86"  
.\LogMeIn.exe uninstall

#Cleanup Anything Left
Set-Location "C:\Program Files (x86)"
Get-ChildItem "C:\Program Files (x86)\LogMEIn" -Include *.* -Recurse | ForEach-Object  { $_.Delete()}
(Get-ChildItem "C:\Program Files (x86)\LogMeIn\x64").Delete()
(Get-ChildItem "C:\Program Files (x86)\LogMeIn\x86").Delete()
Remove-Item "C:\Program Files (x86)\LogMeIn" -force -recurse -Confirm:$false
Remove-Item -Path HKCU:\Software\LogMeIn -Recurse
Remove-Item -Path HKLM:\Software\LogMeIn -Recurse
Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\LMIInfo -Recurse
Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\LMIMaint -Recurse
Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\LMImirr -Recurse
Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\LMIRfsClientNP -Recurse
Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\LMIRfsDriver -Recurse
Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\LMIGuardianSvc -Recurse
Remove-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "LogMeIn GUI"

#Complete