#Page file scanner
#Scan all computers in active directory for a page file setting
#wmic.exe pagefile list /format:list
#WMIC /node:target-computer-name pagefile list /format:list
#"Pagefile - Alias not found"
#Set page file on ones not found
#wmic.exe pagefileset create name="C:\\pagefile.sys"

#Enable TLS1.2 - Without it, Tickets will not be generated in Deskpro
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#Get all computers from Active Directory
$PageFileResult = wmic.exe pagefile list /format:list
if([string]$PageFileResult -inotmatch "AllocatedBaseSize"){
    $TicketSubject = "Page File Missing " + $HostName 
$TicketMessage = "Page File Missing : " + $PageFileResult
Add-DeskProTicket -APIKey $DeskProAPIKey -Message $TicketMessage -SubDomain $DeskProDomain -Subject $TicketSubject -DepartmentID 1 -PersonEmail $DeskProEmail
WRITE-HOST "Ticket Sent"
}