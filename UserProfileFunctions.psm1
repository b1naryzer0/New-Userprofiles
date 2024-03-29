
<#
.Synopsis
   Rough PS functions to create new user profiles
.DESCRIPTION
   Call the New-UserProfile function directly to create a new profile
.EXAMPLE
   New-UserProfile -Username 'testUser1' -Password 'testUser1'
.NOTES
   Created by: Josh Rickard (@MS_dministrator) and Thom Schumacher (@driberif)
   https://gist.github.com/crshnbrn66/7e81bf20408c05ddb2b4fdf4498477d8#file-user-profile-psm1
   
   Modified by Fritz R. 2024 
   - tested and compatible to PS 5.1
   - changed New-LocalUser to PS native method
   - minor changes to function names to avoid invalid verb check loading error
   - far from being tested 100% so don't use in production
#>


#function to register a native method
function Register-NativeMethod
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$dll,
 
        # Param2 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $methodSignature
    )
 
    $script:nativeMethods += [PSCustomObject]@{ Dll = $dll; Signature = $methodSignature; }
}


function Get-Win32LastError
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param($typeName = 'LastError')
 if (-not ([System.Management.Automation.PSTypeName]$typeName).Type)
    {
    $lasterrorCode = $script:lasterror | ForEach-Object{
        '[DllImport("kernel32.dll", SetLastError = true)]
         public static extern uint GetLastError();'
    }
        Add-Type @"
        using System;
        using System.Text;
        using System.Runtime.InteropServices;
        public static class $typeName {
            $lasterrorCode
        }
"@
    }
}


#function to add native method
function Add-NativeMethods
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param($typeName = 'NativeMethods')
 
    $nativeMethodsCode = $script:nativeMethods | ForEach-Object { "
        [DllImport(`"$($_.Dll)`")]
        public static extern $($_.Signature);
    " }
 
    Add-Type @"
        using System;
        using System.Text;
        using System.Runtime.InteropServices;
        public static class $typeName {
            $nativeMethodsCode
        }
"@
}

#Main function to create the new user profile
function New-UserProfile {
 
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$UserName,
 
        # Param2 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $Password
    )
  
    Write-Verbose "Creating local user $Username";
  
    try
    {        
        $SecurePwd = ConvertTo-SecureString $Password -AsPlainText -Force
        New-LocalUser -Name $UserName -password $SecurePwd
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }
    $methodName = 'UserEnvCP'
    $script:nativeMethods = @();
 
    if (-not ([System.Management.Automation.PSTypeName]$MethodName).Type)
    {
        Register-NativeMethod "userenv.dll" "int CreateProfile([MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,`
         [MarshalAs(UnmanagedType.LPWStr)] string pszUserName,`
         [Out][MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszProfilePath, uint cchProfilePath)";
 
        Add-NativeMethods -typeName $MethodName;
    }
 
    $localUser = New-Object System.Security.Principal.NTAccount("$UserName");
    $userSID = $localUser.Translate([System.Security.Principal.SecurityIdentifier]);
    $sb = new-object System.Text.StringBuilder(260);
    $pathLen = $sb.Capacity;
 
    Write-Verbose "Creating user profile for $Username";
 
    try
    {
        [UserEnvCP]::CreateProfile($userSID.Value, $Username, $sb, $pathLen) | Out-Null;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }
}

function New-ProfileFromSID {
 
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$UserName,
        [string]$domain = 'PHCORP'
    )
    $methodname = 'UserEnvCP2'
    $script:nativeMethods = @();
    
    if (-not ([System.Management.Automation.PSTypeName]$methodname).Type)
    {
        Register-NativeMethod "userenv.dll" "int CreateProfile([MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,`
         [MarshalAs(UnmanagedType.LPWStr)] string pszUserName,`
         [Out][MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszProfilePath, uint cchProfilePath)";
 
        Add-NativeMethods -typeName $methodname;
    }
 
    $sb = new-object System.Text.StringBuilder(260);
    $pathLen = $sb.Capacity;
 
    Write-Verbose "Creating user profile for $Username";
    #$SID= ((get-aduser -id $UserName -ErrorAction Stop).sid.value)
  if($domain)
   {
        $objUser = New-Object System.Security.Principal.NTAccount($domain, $UserName)
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        $SID = $strSID.Value
   }
   else 
   {
       $objUser = New-Object System.Security.Principal.NTAccount($UserName)
       $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
       $SID = $strSID.Value
   }
    Write-Verbose "$UserName SID: $SID"
    try
    {
       $result = [UserEnvCP2]::CreateProfile($SID, $Username, $sb, $pathLen) 
       if($result -eq '-2147024713')
       {
           $status = "$userName already exists"
           write-verbose "$username Creation Result: $result"
        }
        elseif($result -eq '-2147024809')
        {
            $staus = "$username Not Found"
            write-verbose "$username creation result: $result"
        }
       elseif($result -eq 0)
       {
           $status = "$username Profile has been created"
           write-verbose "$username Creation Result: $result"
       }
       else
       {
          $status = "$UserName unknown return result: $result"
       }
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }
    $status
}
Function Remove-Profile {
 
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$UserName,
        [string]$ProfilePath,
        [string]$domain = 'PHCORP'
    )
    $methodname = 'userenvDP'
    $script:nativeMethods = @();
 
    if (-not ([System.Management.Automation.PSTypeName]"$methodname.profile").Type)
    {
      add-type @"
using System.Runtime.InteropServices;

namespace $typename
{
    public static class UserEnv
    {
        [DllImport("userenv.dll", CharSet = CharSet.Unicode, ExactSpelling = false, SetLastError = true)]
        public static extern bool DeleteProfile(string sidString, string profilePath, string computerName);

        [DllImport("kernel32.dll")]
        public static extern uint GetLastError();
    }

    public static class Profile
    {
        public static uint Delete(string sidString)
        { //Profile path and computer name are optional
            if (!UserEnv.DeleteProfile(sidString, null, null))
            {
                return UserEnv.GetLastError();
            }

            return 0;
        }
    }
}
"@
    }

   #$SID= ((get-aduser -id $UserName -ErrorAction Stop).sid.value)
   if($domain)
   {
        $objUser = New-Object System.Security.Principal.NTAccount($domain, $UserName)
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        $SID = $strSID.Value
   }
   else 
   {
       $objUser = New-Object System.Security.Principal.NTAccount($UserName)
       $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
       $SID = $strSID.Value
   }
    Write-Verbose "$UserName SID: $SID"
    try
    {
        #http://stackoverflow.com/questions/31949002/c-sharp-delete-user-profile
       $result = [userenvDP.Profile]::Delete($SID)
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }
    $LastError
}
