function IsAdministrator {
    param()
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($currentUser)).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (IsAdministrator)) {
    throw "This script requires administrative rights, please run as administrator."
}

########################## Required CSV Variables. #########################
# Get foldername and scriptname.
$ScriptDir = if ($script:MyInvocation.MyCommand.Path) {
    Split-Path $script:MyInvocation.MyCommand.Path
}
else {
    "$env:windir\temp"
}

$ScriptName = if ($MyInvocation.MyCommand.Name) {
    $MyInvocation.MyCommand.Name
}
else {
    "42_OnBoarding_Defender.ps1"
}

# Get only the filename without extension.
$ScriptName_withoutfileend = $ScriptName.Substring(0, $ScriptName.Length - 4)

# Generating CSV log name.
$log_csv = "_log.csv"
$FilePath_Log = "$ScriptDir\$ScriptName_withoutfileend$($log_csv)"
#Remove-Item -Force $FilePath_Log -ErrorAction SilentlyContinue

# Clear $Error variable.
$Error.Clear()
$ErrorMessage = $null
$Output = $null
# Ok log.
$ok_log = "_OK.log"
$OK = "$ScriptDir\$ScriptName_withoutfileend$($ok_log)"
$ErrorActionPreference = 'Continue'
$InformationPreference = "Continue"
############################################################################

function Write-ColorOutput {
    param (
        [Parameter (Mandatory = $false, position = 0)]
        [String]$String,

        [Parameter(Mandatory = $false, position = 1)]
        [ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
        $ForegroundColor,

        [Parameter(Mandatory = $false, position = 2)]
        [ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
        $BackgroundColor
    )
    $Check_Output = $false
    if (!($psISE)) {
        # Save the current color
        $fc_save = $host.UI.RawUI.ForegroundColor
        $bc_save = $host.UI.RawUI.BackgroundColor

        # Set the new color
        if ($ForegroundColor) {
            Write-Debug "if fc - NOT ISE"
            $host.UI.RawUI.ForegroundColor = $ForegroundColor
        }

        if ($BackgroundColor) {
            Write-Debug "if bc - NOT ISE"
            $host.UI.RawUI.BackgroundColor = $BackgroundColor
        }

        if (!($BackgroundColor) -and !($ForegroundColor)) {
            Write-Debug "if not bc or fc - NOT ISE"
            Write-Information $String
            $Check_Output = $true
        }

        if ($ForegroundColor -and $BackgroundColor) {
            Write-Debug "ForegroundColor:[$ForegroundColor] true and BackgroundColor:[$BackgroundColor] true and Check_Output false - ISE"
            Write-Information $String
            $Check_Output = $true
        }

        elseif ($ForegroundColor -and $Check_Output -eq $false) {
            Write-Debug "ForegroundColor: [$ForegroundColor] true and Check_Output false - NOT ISE"
            Write-Information $String
            $Check_Output = $true
        }

        elseif ($BackgroundColor -and $Check_Output -eq $false) {
            Write-Debug "BackgroundColor: [$BackgroundColor] true and Check_Output false - NOT ISE"
            Write-Information $String
        }

        if ($ForegroundColor) {
            $host.UI.RawUI.ForegroundColor = $fc_save
        }
        if ($BackgroundColor) {
            $host.UI.RawUI.BackgroundColor = $bc_save
        }
    }

    else {
        if (!($BackgroundColor) -and !($ForegroundColor)) {
            Write-Debug "if not bc or fc - ISE"
            Write-Host $String
            $Check_Output = $true
        }

        if ($ForegroundColor -and $BackgroundColor -and $Check_Output -eq $false) {
            Write-Debug "ForegroundColor:[$ForegroundColor] true and BackgroundColor:[$BackgroundColor] true and Check_Output false - ISE"
            Write-Host $String -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
            $Check_Output = $true
        }
        elseif ($ForegroundColor -and $Check_Output -eq $false) {
            Write-Debug "ForegroundColor:[$ForegroundColor] true and Check_Output false - ISE"
            Write-Host $String -ForegroundColor $ForegroundColor
            $Check_Output = $true
        }

        elseif ($BackgroundColor -and $Check_Output -eq $false) {
            Write-Debug "BackgroundColor:[$BackgroundColor] true and Check_Output false - ISE"
            Write-Host $String -BackgroundColor $BackgroundColor
        }
    }
} # End of Function Write-ColorOutput.

function Write-CSVLog {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Trigger CSV logs.

    .DESCRIPTION
    The Write-CSVLog is a way to set a log file to a CSVfile.

    .PARAMETER Extension
    CSV file is the output.

    .EXAMPLE
    PS C:\> $server = "SEEMM1MGM003"
    PS C:\> Write-CSVLog -Target $server -Output "Everything went fine."

    .EXAMPLE
    PS C:\> $server = "SEEMM1MGM003"
    PS C:\> $Output = "Unable to connect to remote system."
    PS C:\> Write-CSVLog -Target $server -Output $Output

    .NOTES
    ########################## Required CSV Variables. #########################
    # Get foldername and scriptname.
    $ScriptDir = if ($script:MyInvocation.MyCommand.Path) {
        Split-Path $script:MyInvocation.MyCommand.Path
    }
    else {
        "$env:windir\temp"
    }

    $ScriptName = if ($MyInvocation.MyCommand.Name) {
        $MyInvocation.MyCommand.Name
    }
    else {
        "Misc.ps1"
    }

    # Get only the filename without extension.
    $ScriptName_withoutfileend = $ScriptName.Substring(0, $ScriptName.Length - 4)

    # Generating CSV log name.
    $log_csv = "_log.csv"
    $FilePath_Log = "$ScriptDir\$ScriptName_withoutfileend$($log_csv)"
    #Remove-Item -Force $FilePath_Log -ErrorAction SilentlyContinue

    # Add addition to the variable.
    $wrapper2 = @()

    # Clear $Error variable.
    $Error.Clear()
    $ErrorMessage = $null
    $Output = $null
    $ErrorMessage2 = $null
    # Ok log.
    $ok_log = "_OK.log"
    $OK = "$ScriptDir\$ScriptName_withoutfileend$($ok_log)"
    $ErrorActionPreference = "Stop"
    ############################################################################

    $Output = "Test"
    $server = "10.95.1.7"
    Write-CSVLog -Target $server -Output $Output

    Requirement:
    In order to make it work automated with the same csv output name as the script. Always use the required CSV variables above.
    Use $Output like above to be able to catch the output in the CSV file.
    Use $Target as the machinename.

    Example output of the CSV file:
    "2022-04-06 15:49:35.20","SEEMM1APP992","Change Keyboard Language","Failed to add Language: [sv-SE] but set [en-US] as default.","Failed","Cannot bind parameter 'LanguageList'. Cannot convert the ""Microsoft.InternationalSettings.Commands.WinUserLanguage"" value of type ""Deserialized.Microsoft.InternationalSettings.Commands.WinUserLanguage"" to type ""Microsoft.InternationalSettings.Commands.WinUserLanguage"".","System.Management.Automation.RemoteException","1896"
    "2022-04-06 15:49:35.24","SEEMM1APP992","Set the culture language","Trying to set culture to Language: [sv-SE].",,,,
    "2022-04-06 15:49:35.37","SEEMM1APP992","Set the culture language","Successfully set culture to Language: [sv-SE].","Success",,,
    "2022-04-06 15:49:35.42","SEEMM1APP992","Exit Code.","Something went wrong. Cannot bind parameter 'LanguageList'. Cannot convert the ""Microsoft.InternationalSettings.Commands.WinUserLanguage"" value of type ""Deserialized.Microsoft.InternationalSettings.Commands.WinUserLanguage"" to type ""Microsoft.InternationalSettings.Commands.WinUserLanguage"".",,,,

    Easiest to read the CSV files with tail function is to use CSVFileView: \\seemm1netapp1.world.fluidtechnology.net\resources\CSVFileView\CSVFileView.exe
    In CSVFileView go to "Options - AtuoRefresh" and "View - Auto Size Columns+Headers"
    #>

    param (
        [Parameter (Mandatory = $false, position = 0)]
        [String] $Target = $env:COMPUTERNAME,

        [Parameter (Mandatory = $false, position = 1)]
        [String] $Type,

        [Parameter (Mandatory = $true, position = 2)]
        [String] $Output,

        [Parameter (Mandatory = $false, position = 3)]
        [switch] $Yellow,

        [Parameter (Mandatory = $false, position = 4)]
        [switch] $Throw

    )
    $Time = Get-Date -format "yyyy/MM/dd HH:mm:ss.ff"

    $Errormessage = $($_.Exception.Message)
    $Standard_Output = "$Time | Target: $Target | Type: $Type | $Output"
    if ($Errormessage) {
        $ErrorType = $($_.Exception.GetType().FullName)
        $ErrorType = $ErrorType.replace("`r", " ")
        $ErrorType = $ErrorType.replace("`n", " ")
        $ErrorType = $ErrorType.Trim()
        $ErrorLine = $_.InvocationInfo.ScriptLineNumber
        $Status = "Failed"
        if (!($Throw)) {
            Write-ColorOutput -String "$Standard_Output | Error Exception Message: $ErrorMessage | Error Exception Type: $ErrorType | Line: $ErrorLine | Status: $Status" -ForegroundColor White -BackgroundColor Red
        }
        else {
            Write-ColorOutput -String "$Standard_Output | Error Exception Message: $ErrorMessage | Error Exception Type: $ErrorType | Line: $ErrorLine | Status: $Status" -ForegroundColor White -BackgroundColor Red
            throw "$Standard_Output | Error Exception Message: $ErrorMessage | Error Exception Type: $ErrorType | Line: $ErrorLine | Status: $Status"
        }
    }

    elseif ($Output.Where( { ($_ -match "Success") })) {
        $Status = "Success"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "Green"
    }

    elseif ($Output.Where( { ($_ -match "Failed") })) {
        $Status = "Failed"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "White" -BackgroundColor "Red"
    }

    elseif ($Output.Where( { ($_ -match "Not Compliant") })) {
        $Status = "Not Compliant"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "White" -BackgroundColor "Red"
    }

    elseif ($Output.Where( { ($_ -match "is compliant") })) {
        $Status = "Compliant"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "Green"
    }

    elseif ($Output.Where( { ($Yellow.IsPresent -eq $true) })) {
        Write-ColorOutput -String $Standard_Output -ForegroundColor "Yellow" -BackgroundColor "Black"
    }

    elseif ($Output.Where( { ($Throw.IsPresent -eq $true) })) {
        $Status = "Forced Throw"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "White" -BackgroundColor "Red"
        throw "$Standard_Output | $Status"
    }

    else {
        Write-ColorOutput -String $Standard_Output
    }

    # Adding the columns that are needed.
    $wrapper = [PSCustomObject]@{
        Time         = $Time
        Target       = $Target
        Type         = $Type
        Output       = $Output
        Status       = $Status
        ErrorMessage = $ErrorMessage
        ErrorType    = $ErrorType
        ErrorLine    = $ErrorLine
    }
    
    # Exporting the output wrapper to a CSV, appended.
    $retry = 0
    while ($retry -lt 5) {
        try {
            $wrapper | Export-Csv -Path $FilePath_Log -NoTypeInformation -Append
            break
        }
        catch {
            Start-Sleep -Milliseconds 500
            $retry++
        }
    }
} # End of Function Write-CSVLog.

#Region ####################################### Defender Feature ###################################################
$Feature = 'Windows-Defender'
try {
    Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Trying to get the Install status on the Windows Feature: [$Feature]."
    $Feature_Install_State = Get-WindowsFeature $Feature | Select-Object -ExpandProperty InstallState
    Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Successfully to get the Install status on the Windows Feature: [$Feature]."
}
catch {
    Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Failed to get the Install status on the Windows Feature: [$Feature]. Error: $_. ExceptionType: $($_.Exception.GetType().FullName)" -Throw
}

if ($Feature_Install_State -eq 'Available') {
    Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Windows Feature: [$Feature] is NOT installed."
    Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Trying to install the Windows Feature: [$Feature]."
    try {
        Install-WindowsFeature -Name $Feature -IncludeAllSubFeature -IncludeManagementTools -ErrorAction Stop
        Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Successfully installed the Windows Feature: [$Feature]." -Yellow
    }
    catch {
        Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Failed to install the Windows Feature: [$Feature]. Error: $_. ExceptionType: $($_.Exception.GetType().FullName)" -Throw
    }
}
else {
    Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "Windows Feature: [$Feature] is already installed."
}
#Endregion #################################### Defender Feature ###################################################

#Region ####################################### CMD Onboarding Part ################################################
# Run the script remotely and capture output
$PathToCMD_OnboardingCMD = "$PSScriptRoot\WindowsDefenderATPOnboardingScript_2019-2025.cmd" #TODO: Change the path to C:\Temp\Install\Scripts
Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output "PathToCMD_OnboardingCMD: $PathToCMD_OnboardingCMD"
# Run command and capture output
$output = cmd.exe /c "$PathToCMD_OnboardingCMD 2>&1"

# Split the output into lines and filter out empty lines
$outputLines = $output -split "`r`n" | Where-Object { $_ -ne "" }

# Display output on local console with line breaks
foreach ($line in $outputLines) {
    Write-CSVLog -Type "42_OnBoarding_Defender.ps1" -Output " | $line"
}
#Endregion #################################### CMD Onboarding Part ################################################