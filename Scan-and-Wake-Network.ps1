##Scan network and then wake up the network
##Based on script made by © powershell.one (Dr. Tobias Weltner) Apr 29, 2020 - https://powershell.one/code/11.html - 
##Used parts of code by user6811411 Jan 23, 2017 - https://stackoverflow.com/questions/41785413/use-powershell-to-get-device-names-and-their-ipaddress-on-a-home-network
#Added Function to allow this to be used with NCentral with Scripting 
#- When run it will ping all computers in the last subnet, use the ARP table to build a list of Computer Name / MAC Addresses from the Ping response
#- It then passes this to NSLookup to build a computer list table
#- Finally it then passes all these MAC addresses from the computers to the Invoke-WakeOnLan

#Lets check what network I'm on and set that as the Subnet
$IPAddressMe = (Get-NetIPAddress -AddressFamily IPv4 -PrefixLength 24).IPAddress
$Subnet = $IPAddressMe.Substring(0, $IPAddressMe.LastIndexOf(".") + 1)

function Invoke-WakeOnLan
{
  param
  (
    # one or more MACAddresses
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    # mac address must be a following this regex pattern:
    [ValidatePattern('^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$')]
    [string[]]
    $MacAddress 
  )
 
  begin
  {
    # instantiate a UDP client:
    $UDPclient = [System.Net.Sockets.UdpClient]::new()
  }
  process
  {
    foreach($_ in $MacAddress)
    {
      try {
        $currentMacAddress = $_
        
        # get byte array from mac address:
        $mac = $currentMacAddress -split '[:-]' |
          # convert the hex number into byte:
          ForEach-Object {
            [System.Convert]::ToByte($_, 16)
          }
 
        #region compose the "magic packet"
        
        # create a byte array with 102 bytes initialized to 255 each:
        $packet = [byte[]](,0xFF * 102)
        
        # leave the first 6 bytes untouched, and
        # repeat the target mac address bytes in bytes 7 through 102:
        6..101 | Foreach-Object { 
          # $_ is indexing in the byte array,
          # $_ % 6 produces repeating indices between 0 and 5
          # (modulo operator)
          $packet[$_] = $mac[($_ % 6)]
        }
        
        #endregion
        
        # connect to port 400 on broadcast address:
        $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
        
        # send the magic packet to the broadcast address:
        $null = $UDPclient.Send($packet, $packet.Length)
        Write-Host "sent magic packet to $currentMacAddress..."
      }
      catch 
      {
        Write-Host "Unable to send ${mac}: $_"
      }
    }
  }
  end
  {
    # release the UDF client and free its memory:
    $UDPclient.Close()
    $UDPclient.Dispose()
  }
}

## Ping last IP Range (1-254)
1..254|ForEach-Object{
    Start-Process -WindowStyle Hidden ping.exe -Argumentlist "-n 1 -l 0 -f -i 2 -w 1 -4 $SubNet$_"
}
$Computers =(arp.exe -a | Select-String "$SubNet.*dynam") -replace ' +',','|
  ConvertFrom-Csv -Header Computername,IPv4,MAC,x,Vendor|
                   Select-Object Computername,IPv4,MAC
                   WRITE-HOST $Computer.MAC
ForEach ($Computer in $Computers){
  nslookup $Computer.IPv4|Select-String -Pattern "^Name:\s+([^\.]+).*$"|
    ForEach-Object{
      $Computer.Computername = $_.Matches.Groups[1].Value
    }
}
ForEach ($Computer in $Computers){
    WRITE-HOST "Waking Pingable Host " + $Computer.MAC
    #Wake on Lan
    Invoke-WakeOnLan -MacAddress $Computer.MAC
}

#Check for Stale and Unreachable Computers and Send Magic Pack to them
$StaleComputers = Get-NetNeighbor | Select-Object LinkLayerAddress,State | Where-Object {$_.State -eq "Stale" -or $_.State -eq "Unreachable" -and $_.LinkLayerAddress -ne "00-00-00-00-00-00" }

ForEach ($StaleComputer in $StaleComputers){
    WRITE-HOST "Waking Stale Host " + $StaleComputer.LinkLayerAddress
    #Wake on Lan
    Invoke-WakeOnLan -MacAddress $StaleComputer.LinkLayerAddress

}
#Scan and Wake Extra Computers as requested
if ($null -ne $args[0]){
  $args[0]=$ParamMAC
  Invoke-WakeOnLan -MacAddress $ParamMAC
}
