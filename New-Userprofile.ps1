##########################################
# New-Userprofile.ps1
# creates 10 local users and userprofiles
# and deletes them again
# Fritz R. 02/2024
##########################################
Import-Module .\UserProfileFunctions.psm1 -Verbose
Get-Command -Module user-profile.psm1

for ($i = 1; $i -le 10; $i++) {

    New-UserProfile -UserName "testy$i" -Password "#123hallo"
    # Remove-Profile -UserName "testy$i"
    # Get-CimInstance win32_userprofile | where localpath -match "testy$i" | Remove-CimInstance
}

""
"#######################################"
"# user accounts and profiles"
"# have been created"
"# press a key to delete them again"
"#######################################"
""
pause
break;  # comment this out to have users and profiles deleted

#######################################
# Remove everything
#######################################
for ($i = 1; $i -le 10; $i++) {
    "- deleting user testy$i and removing userprofile c:\users\testy$i"
    Remove-LocalUser "testy$i"
    Get-CimInstance win32_userprofile | where localpath -match "testy$i" | Remove-CimInstance
}

#######################################
Remove-Module UserProfileFunctions
