#New Starter Scripted Edition v1.2
#Darren Banfi
#19/09/24 - v1.3 - Fix Usablilty
#02/07/24 - v1.2 - Fix them bugs
#28/02/24 - v1.1 - Updated Output with AD Username
#02/02/24 - v1.0 - Initial Release

#First Lets import the ActiveDirectory Module
Import-Module ActiveDirectory

#Need to get the Command Line for Scripted Support
#arg[0] NewStarter Firstname
#arg[1] NewStart Surname
#arg[2] (Optional) Copy user.name
#arg[3] Description (Set to N for Copy)

#New-Passwd Function
function New-Passwd {
    <#
    
    .SYNOPSIS
    A simple script that generates a random, but human-pronounceable password.
    
    .DESCRIPTION
    Version: 2.0
    This script creates a random password based on human-pronounceable syllables.
    You can adjust the number of syllables, and when working with it interactively,
    includes the ability to generate multiple passwords. The generated password
    will include a symbol character in a random location, and a 2-4 digit number suffix.
    
    When integrating this function into a script, you'll likely want to use the -HideOutput
    switch to prevent the password from being outputted to the console.
    
    .EXAMPLE
    New-Passwd
    
    Default generates one password that is four (4) syllables long, 15-17 character length total.
    
    Example output:
    PS > Jabgot@darsay8472
    
    .EXAMPLE
    New-Passwd -Length 20 -Count 5
    
    Generates 5 passwords that are each 20-syllables long.
    
    Example output:
    PS > Neoreonuasantotlenlodjusveitavfihpotretvifruajigvuolua;tiuket6348
    PS > Coasuukocfekbestajbacnutbabheptaksegcui.sesnadsotjuncaesojpou7255
    PS > Paeruamohsadheimukbanneakui;pujgodmejsuinegjaobitfoffejgafheu2701
    PS > Hapdaobagtiecokbihlubkiurubroelephep-munlijdumgemcuspagmuvkub4728
    PS > Dejtegbia{gonbimpilpiltavvardiiribdujsevvujfovripdornopjiodoj3586
    
    .EXAMPLE
    New-Passwd -HideOutput
    
    Generates one default password that is four (4) syllables long, 15-17 character length total,
    and does not show the output. It is useful to include this switch when calling from within
    a script where you will be using the $script:Passwd variable elsewhere.
    Default is to write output.
    
    Example output:
    PS > 
    
    #>
        [cmdletbinding()]
        param(
            [Parameter(Position=0)]
            #Default length in syllables.
            [Int]$Length = 4,
            [Parameter(Position=1)]
            #Default number of passwords to create.
            [Int]$Count = 1,
            [Parameter(Position=2)]
            #Hides the output. useful when used within a script.
            [Switch]$HideOutput
        )
        Begin {
            #consonants except hard to speak ones
            [Char[]]$lowercaseConsonants = "bcdfghjklmnprstv"
            [Char[]]$uppercaseConsonants = "BCDFGHJKLMNPRSTV"
            #vowels
            [Char[]]$lowercaseVowels = "aeiou"
            #both
            $lowercaseConsantsVowels = $lowercaseConsonants+$lowercaseVowels
            #numbers
            [Char[]]$numbers = "0123456789"
            #special characters
            [Char[]]$specialCharacters = "!$#@+?=-*"
    
            $countNum = 0
        }
        Process {
            while ($countNum -le $Count-1) {
                $script:Passwd = ''
                #random location for special char between first syllable and length
                $specialCharSpot = Get-Random -Minimum 1 -Maximum $Length
                for ($i=0; $i -lt $Length; $i++) {
                    if ($i -eq $specialCharSpot) {
                        #add a special char
                        $script:Passwd += ($specialCharacters | Get-Random -Count 1)
                    }
                    #Start with uppercase
                    if ($i -eq 0) {
                        $script:Passwd += ($uppercaseConsonants | Get-Random -Count 1)
                    } else {
                        $script:Passwd += ($lowercaseConsonants | Get-Random -Count 1)
                    }
                    $script:Passwd += ($lowercaseVowels | Get-Random -Count 1)
                    $script:Passwd += ($lowercaseConsantsVowels | Get-Random -Count 1)
                }
                #add a number at the end
                $randNumNum = Get-Random -Minimum 2 -Maximum 5
                $script:Passwd += (($numbers | Get-Random -Count $randNumNum)-join '')
                if ($HideOutput) {
                    # The $Passwd is not shown as output.
                } else {
                    Write-Output "$script:Passwd"
                }
                $countNum++
            }
        }
    }

#Process the Starter
#If FirstName and Surname filled in Process
if ($null -ne $args[0] -and $null -ne $args[1]){
    $FirstName=$args[0]
    $SurName=$args[1]
    WRITE-HOST "Creating New Starter : " $FirstName $Surname
    #If we have only 3 Args - we are a copy user
    if ($null -ne $args[2] -and $null -eq $args[3]){
        $CopyUser = $args[2]
        $NewUserAttribs = Get-ADUser -Identity $CopyUser -Properties Description
        $Password = New-Passwd -Length 2 -Count 1
        $NewUser = New-ADUser -Name "$FirstName $Surname" -GivenName $FirstName -Surname $SurName -SAMAccountName "$FirstName.$Surname" -DisplayName "$FirstName $SurName" -Description $NewUserAttribs.Description -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -ChangePasswordAtLogon $true -Enabled $true
        #Copy Group time
        Get-ADUser -Identity $CopyUser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members "$Firstname.$Surname"
    } else {
        $Password = New-Passwd -Length 2 -Count 1
        if($null -ne $args[3] -and $args[3] -eq "New"){
            $NewUser = New-ADUser -Name "$FirstName $Surname" -GivenName $FirstName -Surname $SurName -SAMAccountName "$FirstName.$Surname" -DisplayName "$FirstName $SurName" -Description $args[3] -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -ChangePasswordAtLogon $true -Enabled $true
        }
    }

$Groups = Get-ADUser -Identity "$Firstname.$Surname" -Properties memberof | Select-Object -ExpandProperty memberof
WRITE-HOST "AD Login Name :"  + $Firstname + "." + $Surname
WRITE-HOST "Password :" $Password
WRITE-HOST "Groups:" $Groups
    
  }else {
      <# Action when all if and elseif conditions are false #>
      WRITE-HOST "Incorrect Paramaters Entered"
  }