#Network LLDP Switch Lookup
#Standalone Console Output Application - 16/01/2024 - DB
#Uses Module PSDiscoveryProtocol (https://github.com/lahell/PSDiscoveryProtocol)
#****Uncomment the next line for Standalone-mode
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force

#Lets enable TLS1.2 for this session - This could be missing on systems that have not used Powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Import the required Modules
Import-Module PowerShellGet
Import-Module PackageManagement

# Trust PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

#Install PackageManagement and Update PackageManagent if it's there
Install-Module -Name PowerShellGet -Force -AllowClobber
Update-Module -Name PowerShellGet -RequiredVersion 2.2.5.1
Update-Module -Name PowerShellGet

# Install PackageManagement first so we can use NuGet and PSGallery (Missing on devices with PS3.0)
Install-Module -Name PackageManagement -Force -ErrorAction SilentlyContinue | Out-Null

# Install NuGet package repository so we can use the PSGallery
Install-PackageProvider "NuGet" -Force -ErrorAction SilentlyContinue | Out-Null

Install-Module -Name PSDiscoveryProtocol -Repository PSGallery -Force
$Packet = Invoke-DiscoveryProtocolCapture -Type LLDP -Force -ErrorAction SilentlyContinue
If ($true -eq $Packet) {
$NetworkLookup = Get-DiscoveryProtocolData -Packet $Packet 
WRITE-HOST $NetworkLookup
} else {WRITE-HOST "Network LLDP Packet Capture Failed"}
