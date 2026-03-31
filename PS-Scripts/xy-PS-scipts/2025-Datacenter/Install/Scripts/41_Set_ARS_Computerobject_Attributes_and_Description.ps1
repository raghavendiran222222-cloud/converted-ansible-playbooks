#requires -Module ActiveRolesManagementShell

param (
    [Parameter (position = 0 , Mandatory = $false)]
    [string] $ComputerName = $env:COMPUTERNAME,

    [Parameter (position = 1 , Mandatory = $false)]
    [string] $XylemServerRoleName = 'Xylem-ServerRole',

    [Parameter (position = 2 , Mandatory = $true)]
    [ValidateSet("Production", "Test")]
    [string] $Classification,

    [Parameter (position = 3 , Mandatory = $true)]
    [AllowEmptyString()]
    [string] $Description,

    [Parameter (position = 4 , Mandatory = $false)]
    [string] $ARS_Server = "seemm1ars-06.world.fluidtechnology.net"
)

$ErrorActionPreference = 'Stop'
$script:Messages = New-Object System.Collections.Generic.List[PSObject]

function Write-Output2 {
    param (
        [Parameter(Mandatory = $true)]
        [String]$Message,
        [String]$ComputerName = $env:COMPUTERNAME
    )

    # Create a PSCustomObject
    $obj = [PSCustomObject]@{
        ComputerName = $ComputerName
        Message      = $Message
    }

    # Add the PSCustomObject to the script-scoped list
    $script:Messages.Add($obj)

    # Output the message directly to the console
    Write-Host "$ComputerName | $Message"

    # Return the PSCustomObject (optional, if you need to use it elsewhere)
    #return $obj
}

#Add hashtable with Classification to XylemServerRole.
$Xylem_ServerRole_Table = @{
    $XylemServerRoleName = @{
        'Test'       = 'Test-Server'
        'Production' = 'Production-Server'
    }
}

try {
    Write-Output2 -ComputerName $ComputerName -Message "Trying to set the XylemServerRoleName: [$XylemServerRoleName] based on Classification: [$Classification]."
    $XylemServerRoleType = $Xylem_ServerRole_Table[$XylemServerRoleName][$Classification]
    Write-Output2 -ComputerName $ComputerName -Message "Successfully set the XylemServerRoleName: [$XylemServerRoleName] to: XylemServerRoleType: [$XylemServerRoleType]."
}
catch {
    Write-Output2 -ComputerName $ComputerName -Message "Unable to set the XylemServerRoleName: [$XylemServerRoleName] based on Classification: [$Classification]. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
}

try {
    Write-Output2 -ComputerName $ComputerName -Message "Trying to set XylemServerRoleName: [$XylemServerRoleName] with [$XylemServerRoleType] and Description with: [$Description]."
    $Set_QADComputer_Splatting = @{
        Identity     = $ComputerName
        ObjectAttributes = @{
            "$($XylemServerRoleName)" = "$($XylemServerRoleType)"
            "Description"            = "$($Description)"
        }
        Service          = $ARS_Server
        Proxy            = $true
    }
    $Set_QADComputer = Set-QADComputer @Set_QADComputer_Splatting

    if ($Set_QADComputer) {
        Write-Output2 -ComputerName $ComputerName -Message "Successfully set the XylemServerRoleName: [$XylemServerRoleName] with [$XylemServerRoleType] and Description with: [$Description]."
    }
    else {
        Write-Output2 -ComputerName $ComputerName -Message "Unable to set XylemServerRoleName: [$XylemServerRoleName] with [$XylemServerRoleType] and Description with: [$Description]."
    }
}
catch {
    Write-Output2 -ComputerName $ComputerName -Message "Unable to set the ServerRole. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
}