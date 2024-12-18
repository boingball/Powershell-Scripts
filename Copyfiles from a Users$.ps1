#Copyfiles from a Users$
$UsersLocation = "S:\Shares\users$"
$ProfileName = "user.name"
$CopyLocation = "S:\"
$FinalDestination = "S:\ProfileCopy"
$FinalDestinationDesktop = "S:\ProfileCopy\Desktop"
$FinalDestinationDocuments = "S:\ProfileCopy\Documents"
$Desktop = $UsersLocation + "\" + $ProfileName + "\" + "Desktop\*"
$Documents = $UsersLocation + "\" + $ProfileName + "\" + "Documents\*"

#Create Copy Location
New-Item -Path $CopyLocation -Name "ProfileCopy" -ItemType "Directory"

#Copy desktop files from Profile
Copy-Item -Path $Desktop -Destination $FinalDestinationDesktop -Recurse -Force
#Copy document files from Profile 
Copy-Item -Path $Documents -Destination $FinalDestinationDocuments -Recurse -Force
