# Set-ExecutionPolicy -Scope Process Unrestricted
$Global:PowerShell_Text = "PowerShell Check"
$Remediation = $true
$EnablePatchRemediate = $false

# Check for PSversion
if ($PSVersionTable.PSVersion.Major -le 2) {
    throw "$Global:PowerShell_Text version is 2 or lower, you need minimum version 3. Breaking script."
}

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
    "Compliance_Check_Invoke.ps1"
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

$ErrorActionPreference = "Stop"
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
} # End of function Write-ColorOutput.

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
    Use $Target as the machine name.

    Example output of the CSV file:
    "2022-04-06 15:49:35.20","SEEMM1APP992","Change Keyboard Language","Failed to add Language: [sv-SE] but set [en-US] as default.","Failed","Cannot bind parameter 'LanguageList'. Cannot convert the ""Microsoft.InternationalSettings.Commands.WinUserLanguage"" value of type ""Deserialized.Microsoft.InternationalSettings.Commands.WinUserLanguage"" to type ""Microsoft.InternationalSettings.Commands.WinUserLanguage"".","System.Management.Automation.RemoteException","1896"
    "2022-04-06 15:49:35.24","SEEMM1APP992","Set the culture language","Trying to set culture to Language: [sv-SE].",,,,
    "2022-04-06 15:49:35.37","SEEMM1APP992","Set the culture language","Successfully set culture to Language: [sv-SE].","Success",,,
    "2022-04-06 15:49:35.42","SEEMM1APP992","Exit Code.","Something went wrong. Cannot bind parameter 'LanguageList'. Cannot convert the ""Microsoft.InternationalSettings.Commands.WinUserLanguage"" value of type ""Deserialized.Microsoft.InternationalSettings.Commands.WinUserLanguage"" to type ""Microsoft.InternationalSettings.Commands.WinUserLanguage"".",,,,

    Easiest to read the CSV files with tail function is to use CSVFileView: \\seemm1netapp1.world.fluidtechnology.net\resources\CSVFileView\CSVFileView.exe
    In CSVFileView go to "Options - AutoRefresh" and "View - Auto Size Columns+Headers"
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
    $Time = Get-Date -Format "yyyy/MM/dd HH:mm:ss.ff"

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

    elseif ($Output | Where-Object ( { ($_ -match "Success") })) {
        $Status = "Success"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "Green"
    }

    elseif ($Output | Where-Object ( { ($_ -match "Failed") })) {
        $Status = "Failed"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "White" -BackgroundColor "Red"
    }

    elseif ($Output | Where-Object ( { ($_ -match "Not Compliant") })) {
        $Status = "Not Compliant"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "White" -BackgroundColor "Red"
    }

    elseif ($Output | Where-Object ( { ($_ -match "is compliant") })) {
        $Status = "Compliant"
        Write-ColorOutput -String "$Standard_Output | $Status" -ForegroundColor "Green"
    }

    elseif ($Output | Where-Object ( { ($Yellow.IsPresent -eq $true) })) {
        Write-ColorOutput -String $Standard_Output -ForegroundColor "Yellow" -BackgroundColor "Black"
    }

    elseif ($Output | Where-Object ( { ($Throw.IsPresent -eq $true) })) {
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
    $wrapper | Export-Csv -Path $FilePath_Log -NoTypeInformation -Append
} # End of Function Write-CSVLog.

Write-CSVLog -Type "Start" -Output "Right after Write-CSVLog function is loaded."
Write-CSVLog -Type "Param Check" -Output "Remediation is set to: [$Remediation]."
Write-CSVLog -Type "Param Check" -Output "EnablePatchRemediate is set to: [$EnablePatchRemediate]."

$VMware_Tools = "VMware Tools"
$Global:IBM_Bigfix_Client = "Bigfix Client"
$Global:IBM_Bigfix_Service = "BESClient"
$Global:IBM_Bigfix_Client_Path = "\\seemm1app484.world.fluidtechnology.net\Client\"
$Global:IBM_Bigfix_Client_Setup_Path = "setup.exe"
$Global:IBM_Bigfix_Client_Setup_Arguments = '/s /v"/l*voicewarmup \"%Temp%\install.log\" /qn"'
$MachineType_VM = "VM"
$MachineType_Azure = "Virtual Machine"
$MachineType_Physical = "Physical"
$Global:Sentinel1 = "Sentinel"
$Global:Sentinel1_Service = "SentinelAgent"
$Control_M_Application = "Control-M*"
$Control_M_Service = "Control-M/Agent"
$Global:PowerPlan_HighPerformance = "High Performance"
$Global:Application_Services_Text = "Application and Services"
$Global:SWPM_Text = "SWPM"
$Global:Get_MachineType_Text = "Get-MachineType"
$Global:OS_Text = "OS"
$Global:VM_Text = "VM Servers specific checks"
$Global:Physical_Text = "Physical Servers specific checks"
$Global:Summary_Text = "Summary"
$Global:Reg_Text = "Registry"
$Global:PowerPlan_Text = "PowerPlan"
$Global:NetAdapterPowerManagement_Text = "NetAdapterPowerManagement"
$Global:AD_Computer_Text = "AD/Computer Check"
$Global:PatchStatus_Latest_Text = "Patch Status"
$Global:DISM_Text = "DISM Check"

$Global:AD_ParentContainer_SEEMM1_WORLD = "world.fluidtechnology.net/_AccountObjects/SEEMM1/Servers"
$Global:AD_ParentContainer_SEEMM1_DMZ = "emeadmz.net/_AccountObjects/SEEMM1/Servers"

$Global:AD_ParentContainer_DSServer = "world.fluidtechnology.net/_GlobalServers/DSServers"
$Global:ComputerName_SESTO1 = "SESTO1"
$Global:ComputerName_SEEMM1 = "SEEMM1"
$Global:ComputerName_Citrix = "XA"

$Global:AD_Reports_Folder_File = "$env:windir\temp\Merged_AD_computerList.csv"

# Patch Status Variables.
$Global:Patch_Days = "80"

# Registry Variables.
$Global:Property_Value = $null
$Global:VM = $null
$Global:VMware_Tools_Config_TestPath_Check = $null

$AD_Reports_FALFS1_Path = "\\falfs1.world.fluidtechnology.net\resources\AD_Reports\Merged_AD_computerList.csv"
$Global:PSSession_Text = "PSSession Check"

function Test-RegistryValue_Binary {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$RegPath,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$AttrName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )
    $Global:hex = $Value.Split(',') | Select-Object { "0x$_" }

    #Check the registry value
    $AttrValue = @(Get-ItemProperty -Path $RegPath -Name $AttrName).SrvsvcSessionInfo

    if ((!$AttrValue)) {
        return $false
    }

    if ($AttrValue) {
        #convert value to comparable data
        [byte[]]$compvalue = $Value.Split(',')
        #compare object. if null then values match
        $compare = Compare-Object $AttrValue $compvalue

        if ($null -eq $compare) {
            #values match, return true
            return $true
        }
        else {
            return $false
        }
    }
} # End of function Test-RegistryValue_Binary.
function Get-MachineType {
    [CmdletBinding()]
    <#
.Synopsis
   A quick function to determine if a computer is VM or physical box.
.DESCRIPTION
   This function is designed to quickly determine if a local or remote
   computer is a physical machine or a virtual machine.
.NOTES
   Created by: Jason Wasser
   Modified: 9/11/2015 04:12:51 PM

   Changelog:
    * added credential support

   To Do:
    * Find the Model information for other hypervisor VM's like Xen and KVM.
.EXAMPLE
   Get-MachineType
   Query if the local machine is a physical or virtual machine.
.EXAMPLE
   Get-MachineType -ComputerName SERVER01
   Query if SERVER01 is a physical or virtual machine.
.EXAMPLE
   Get-MachineType -ComputerName (Get-Content c:\temp\computerlist.txt)
   Query if a list of computers are physical or virtual machines.
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Get-MachineType-VM-or-ff43f3a9
#>
    [OutputType([int])]
    Param
    (
        # ComputerName
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Begin {
    }
    Process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Checking $Computer"
            try {
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer)
                $ComputerSystemInfo = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $Computer -ErrorAction Stop

                switch -Wildcard ($ComputerSystemInfo.Model) {

                    # Check for Hyper-V Machine Type
                    "Virtual Machine" {
                        $MachineType = "VM"
                    }

                    # Check for VMware Machine Type
                    "VMware Virtual Platform" {
                        $MachineType = "VM"
                    }

                    # Check for VMware Machine Type
                    "VMware*" {
                        $MachineType = "VM"
                    }

                    # Check for Oracle VM Machine Type
                    "VirtualBox" {
                        $MachineType = "VM"
                    }

                    # Check for Azure Virtual Machine Type
                    #"Azure" {
                    #    $MachineType = "Virtual Machine"
                    #}

                    # Check for Xen
                    # I need the values for the Model for which to check.

                    # Check for KVM
                    # I need the values for the Model for which to check.

                    # Otherwise it is a physical Box
                    default {
                        $MachineType = "Physical"
                    }
                }

                # Building MachineTypeInfo Object
                $MachineTypeInfo = New-Object -TypeName PSObject -Property ([ordered]@{
                        ComputerName = $ComputerSystemInfo.PSComputername
                        Type         = $MachineType
                        Manufacturer = $ComputerSystemInfo.Manufacturer
                        Model        = $ComputerSystemInfo.Model
                    })
                $MachineTypeInfo
            }
            catch [Exception] {
                Write-Output "$Computer`: $($_.Exception.Message)"
            }
        }
    }
    End {

    }
} # End of function Get-MachineType.

function Get-Software {
    [OutputType('System.Software.Inventory')]
    [Cmdletbinding()]

    Param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]]$Computername = $env:COMPUTERNAME
    )

    Begin {
    }

    Process {
        foreach ($Computer in  $Computername) {
            if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                $Paths = @("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall", "SOFTWARE\\Wow6432node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
                foreach ($Path in $Paths) {
                    Write-Verbose "Checking Path: $Path"
                    #  Create an instance of the Registry Object and open the HKLM base key
                    try {
                        $reg = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine', $Computer, 'Registry64')
                    }
                    catch {
                        Write-Error $_
                        Continue
                    }
                    #  Drill down into the Uninstall key using the OpenSubKey Method
                    try {
                        $regkey = $reg.OpenSubKey($Path)
                        # Retrieve an array of string that contain all the subkey names
                        $subkeys = $regkey.GetSubKeyNames()
                        # Open each Subkey and use GetValue Method to return the required  values for each
                        foreach ($key in $subkeys) {
                            Write-Verbose "Key: $Key"
                            $thisKey = $Path + "\\" + $key
                            try {
                                $thisSubKey = $reg.OpenSubKey($thisKey)
                                # Prevent Objects with empty DisplayName
                                $DisplayName = $thisSubKey.getValue("DisplayName")
                                if ($DisplayName -AND $DisplayName -notmatch '^Update  for|rollup|^Security Update|^Service Pack|^HotFix') {
                                    $Date = $thisSubKey.GetValue('InstallDate')
                                    if ($Date -match "-") {
                                        $Date = $Date -replace "-", ""
                                    }
                                    if ($Date -match "PST ") {
                                        $Date = $Date -replace "PST ", ""
                                    }
                                    if ($Date -match "CEST ") {
                                        $Date = $Date -replace "CEST ", ""
                                    }

                                    #Write-Host "Date: $Date"
                                    if ($Date) {
                                        try {
                                            $Date = [datetime]::ParseExact($Date, 'yyyyMMdd', [Globalization.CultureInfo]::CreateSpecificCulture('sv-SE'))
                                        }
                                        catch {
                                            Write-Warning "$($Computer): $_ <$($Date)>"
                                            $Date = $Null
                                        }
                                    }
                                    # Create New Object with empty Properties
                                    $Publisher =
                                    if ([string]::IsNullOrWhiteSpace($thisSubKey.GetValue('Publisher'))) {
                                        Write-Debug "Publisher in Key: [$thisSubKey] is null."
                                    }
                                    else {
                                        $thisSubKey.GetValue('Publisher').Trim()
                                    }
                                    $Version =
                                    if ([string]::IsNullOrWhiteSpace($thisSubKey.GetValue('DisplayVersion'))) {
                                        Write-Debug "DisplayVersion in Key: [$thisSubKey] is null."
                                    }
                                    else {
                                        #Some weirdness with trailing [char]0 on some strings
                                        $thisSubKey.GetValue('DisplayVersion').TrimEnd(([char[]](32, 0)))
                                    }
                                    $UninstallString =
                                    if ([string]::IsNullOrWhiteSpace($thisSubKey.GetValue('UninstallString'))) {
                                        Write-Debug "UninstallString in Key: [$thisSubKey] is null."
                                    }
                                    else {
                                        $thisSubKey.GetValue('UninstallString').Trim()
                                    }
                                    $InstallLocation =
                                    if ([string]::IsNullOrWhiteSpace($thisSubKey.GetValue('InstallLocation'))) {
                                        Write-Debug "InstallLocation in Key: [$thisSubKey] is null."
                                    }
                                    else {
                                        $thisSubKey.GetValue('InstallLocation').Trim()
                                    }
                                    $InstallSource = 
                                    if ([string]::IsNullOrWhiteSpace($thisSubKey.GetValue('InstallSource'))) {
                                        Write-Debug "InstallSource in Key: [$thisSubKey] is null."
                                    }
                                    else {
                                        $thisSubKey.GetValue('InstallSource').Trim()
                                    }
                                    $HelpLink =
                                    if ([string]::IsNullOrWhiteSpace($thisSubKey.GetValue('HelpLink'))) {
                                        Write-Debug "HelpLink in Key: [$thisSubKey] is null."
                                    }
                                    else {
                                        $thisSubKey.GetValue('HelpLink').Trim()
                                    }
                                    $Object = [pscustomobject]@{
                                        Computername    = $Computer
                                        DisplayName     = $DisplayName
                                        Version         = $Version
                                        InstallDate     = $Date
                                        Publisher       = $Publisher
                                        UninstallString = $UninstallString
                                        InstallLocation = $InstallLocation
                                        InstallSource   = $InstallSource
                                        HelpLink        = $thisSubKey.GetValue('HelpLink')
                                        EstimatedSizeMB = [decimal]([math]::Round(($thisSubKey.GetValue('EstimatedSize') * 1024) / 1MB, 2))
                                    }
                                    $Object.pstypenames.insert(0, 'System.Software.Inventory')
                                    Write-Output $Object
                                }
                            }
                            catch {
                                Write-Warning "$Key : $_"
                            }
                        }
                    }
                    catch { }
                    $reg.Close()
                }
            }
            else {
                Write-Error "$($Computer): unable to reach remote system!"
            }
        }
    }
} # End of Get-Software
function Pause2 ($Message = "Press any key to continue...") {
    # Check If running in PowerShell ISE
    if ($psISE) {
        # "ReadKey" not supported in PowerShell ISE.
        # Show MessageBox UI
        $Shell = New-Object -ComObject "WScript.Shell"
        $Button = $Shell.Popup("Click OK to continue.", 0, "Hello", 0)
        Return
    }

    $Ignore =
    16, # Shift (left or right)
    17, # Ctrl (left or right)
    18, # Alt (left or right)
    20, # Caps lock
    91, # Windows key (left)
    92, # Windows key (right)
    93, # Menu key
    144, # Num lock
    145, # Scroll lock
    166, # Back
    167, # Forward
    168, # Refresh
    169, # Stop
    170, # Search
    171, # Favorites
    172, # Start/Home
    173, # Mute
    174, # Volume Down
    175, # Volume Up
    176, # Next Track
    177, # Previous Track
    178, # Stop Media
    179, # Play
    180, # Mail
    181, # Select Media
    182, # Application 1
    183  # Application 2

    Write-Host -NoNewline $Message
    While ($Null -eq $KeyInfo.VirtualKeyCode -Or $Ignore -Contains $KeyInfo.VirtualKeyCode) {
        $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    }
} # End of Pause2 function.
function Test-RegistryValue {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    try {
        $Global:Property_Value = Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop
        return $true
    }

    catch {
        return $false
    }
} # End of function Test-RegistryValue.

function Reg_Compliance {
    [CmdletBinding()]

    param (
        #[Parameter (Mandatory = $False)]
        [Parameter (Mandatory = $true, position = 0 , ValueFromPipeline = $True )]
        [String] $RegPath,

        [Parameter (Mandatory = $true, position = 1)]
        [String] $RegName,

        [Parameter (Mandatory = $true, position = 2)]
        [String] $RegType,

        [Parameter (Mandatory = $true, position = 3)]
        [String] $RegValue,

        [Parameter (Mandatory = $true, position = 4)]
        [String] $Remediation,

        [Parameter (Mandatory = $true, position = 4)]
        [String] $Description
    )

    if (($Global:Reg_Compliance = (Test-RegistryValue $RegPath -Value $RegName) -eq $true -and ($Global:Property_Value -eq $RegValue))) {
        Write-CSVLog -Type $Global:Reg_Text -Output "$Description value: [$RegValue] for [$RegPath\$RegName] is compliant!"
    }

    else {
        Write-CSVLog -Type $Global:Reg_Text -Output "$Description value: [$RegValue] is NOT compliant! [$RegPath\$RegName]."

        if ($Remediation -eq $true) {

            if ((Test-Path -Path $RegPath) -eq $false) {
                try {
                    New-Item -Path $RegPath -Force
                    Write-CSVLog -Type $Global:Reg_Text -Output "Remediation is active for $Description, creating the key value [$RegPath]. Rerun the script to rescan."
                }

                catch {
                    Write-CSVLog -Type $Global:Reg_Text -Output "Failed to remediate $Description, creating the key value [$RegPath]." -Throw
                }
            }

            try {
                New-ItemProperty -Path $RegPath -Name $RegName -Type $RegType -Value $RegValue -Force
                Write-CSVLog -Type $Global:Reg_Text -Output "Remediation is active for $Description, creating the value [$RegPath]. Rerun the script to rescan."
            }

            catch {
                Write-CSVLog -Type $Global:Reg_Text -Output "Remediation is active for $Description, creating the value [$RegPath]. Rerun the script to rescan."
            }

        }
    }
} # End of function Reg_Compliance. ATT! Function Test-RegistryValue is required.

function Get-PendingRebootStatus {
    <#
    .Synopsis
        This will check to see if a server or computer has a reboot pending.
        Compatible with PowerShell 5.1 and 7.x
    
    .NOTES
        Name: Get-PendingRebootStatus
        Author: theSysadminChannel (Modified for PS7 compatibility)
        Version: 2.0
        DateCreated: 2018-Jun-6
        DateModified: 2024
    
    .PARAMETER ComputerName
        By default it will check the local computer.
    
    .EXAMPLE
        Get-PendingRebootStatus -ComputerName PAC-DC01, PAC-WIN1001
    
        Description:
        Check the computers PAC-DC01 and PAC-WIN1001 if there are any pending reboots.
    #>
    
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string[]]  $ComputerName = $env:COMPUTERNAME
    )
    
    BEGIN {}
    
    PROCESS {
        Foreach ($Computer in $ComputerName) {
            Try {
                $PendingReboot = $false
                
                # Check if we're running PowerShell Core (7.x)
                $isPSCore = $PSVersionTable.PSVersion.Major -ge 7
                
                if ($isPSCore) {
                    # PowerShell 7.x approach using CIM
                    $sessionOption = New-CimSessionOption -Protocol Default
                    $session = New-CimSession -ComputerName $Computer -SessionOption $sessionOption -ErrorAction Stop
                    
                    # Check Component Based Servicing
                    $cbsReboot = Get-CimInstance -Namespace "ROOT\Microsoft\Windows\CBS" -ClassName "Microsoft_Windows_CBS_UpdateSession" -CimSession $session -ErrorAction SilentlyContinue
                    if ($cbsReboot -and $cbsReboot.RebootPending) { $PendingReboot = $true }
                    
                    # Check Windows Update
                    $wuaReboot = Get-CimInstance -Namespace "ROOT\Microsoft\Windows\WindowsUpdate" -ClassName "SystemRebootRequired" -CimSession $session -ErrorAction SilentlyContinue
                    if ($wuaReboot) { $PendingReboot = $true }
                    
                    # Check SCCM
                    $sccmReboot = Get-CimInstance -Namespace "ROOT\CCM\ClientSDK" -ClassName "CCM_ClientUtilities" -CimSession $session -ErrorAction SilentlyContinue
                    if ($sccmReboot) {
                        $rebootPending = Invoke-CimMethod -InputObject $sccmReboot -MethodName "DetermineIfRebootPending" -CimSession $session
                        if ($rebootPending.RebootPending) { $PendingReboot = $true }
                    }
                    
                    Remove-CimSession -CimSession $session
                }
                else {
                    # PowerShell 5.1 approach using WMI
                    $HKLM = [UInt32] "0x80000002"
                    $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
                    
                    if ($WMI_Reg) {
                        if (($WMI_Reg.EnumKey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")).sNames -contains 'RebootPending') {
                            $PendingReboot = $true
                        }
                        if (($WMI_Reg.EnumKey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")).sNames -contains 'RebootRequired') {
                            $PendingReboot = $true
                        }
                        
                        # Checking for SCCM namespace
                        $SCCM_Namespace = Get-WmiObject -Namespace ROOT\CCM\ClientSDK -List -ComputerName $Computer -ErrorAction SilentlyContinue
                        if ($SCCM_Namespace) {
                            if (([WmiClass]"\\$Computer\ROOT\CCM\ClientSDK:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending -eq $true) {
                                $PendingReboot = $true
                            }
                        }
                    }
                }
                
                [PSCustomObject]@{
                    ComputerName  = $Computer.ToUpper()
                    PendingReboot = $PendingReboot
                    PowerShell    = if ($isPSCore) { "Core 7.x" } else { "5.1" }
                }
                
            }
            catch {
                Write-Error "Error checking $Computer`: $($_.Exception.Message)"
            }
        }
    }
    
    END {}
} # End Function Get-PendingRebootStatus.

function GetPatches_or_InstallPatches_invoke {
    param(
        [Parameter(Position = 0 , Mandatory = $false)]
        [switch] $InstallAllUpdates = $false
    )

    $Script:Messages = New-Object System.Collections.Generic.List[PSObject]

    function Write-Output2 {
        param (
            [Parameter(Mandatory = $true)]
            [String]$Message,
            [String]$ComputerName = $env:COMPUTERNAME
        )

        # Create a PSCustomObject
        $obj = [PSCustomObject]@{
            Time         = $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss.ff')
            ComputerName = $ComputerName
            Message      = $Message
        }

        # Add the PSCustomObject to the script-scoped list
        $Script:Messages.Add($obj)

        # Output the message directly to the console
        Write-Host "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss.ff') | $ComputerName | $Message"

        # Return the PSCustomObject (optional, if you need to use it elsewhere)
        #return $obj
    }

    $ErrorActionPreference = "SilentlyContinue"
    if ($Error) {
        $Error.Clear()
    }
    try {
        Write-output2 "Initializing and Checking for the object Microsoft.Update.Searcher. Please wait ..."
        $Searcher = New-Object -ComObject Microsoft.Update.Searcher
        Write-Output2 "Successfully initialized the Microsoft.Update.Searcher object."
    }
    catch {
        Write-Output2 "Failed to initialize the Microsoft.Update.Searcher object. Error: [$_]."
        throw
    }

    try {
        Write-Output2 "Initializing and Checking for Applicable Updates. Please wait ..."
        $Result = $Searcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
        if ($Result.Updates.Count -eq 0) {
            $msg = "There are no applicable updates for this computer."
            Write-Output2 $msg
            $Needed_Patches = $msg
            $Needed_Patches_Bool = $false
        }
        else {
            Write-Output2 "Preparing List of Applicable Updates For This Computer ..."
            $Needed_Patches = for ($Counter = 0; $Counter -lt $Result.Updates.Count; $Counter++) {
                $DisplayCount = $Counter + 1
                $Update = $Result.Updates.Item($Counter)
                $UpdateTitle = $Update.Title
                [pscustomobject]@{
                    Computer    = $env:COMPUTERNAME
                    UpdateTitle = $UpdateTitle
                }
                Write-Output2 "$DisplayCount -- $UpdateTitle"
            }
            $Needed_Patches_Bool = $true
            $Counter = 0
            $DisplayCount = 0

            if ($InstallAllUpdates) {
                $FireWallRule = "Allow RPC Dynamic Ports - PSWindowsUpdate"
                $FirewallPorts = "49152-65535", 135
                $ModuleName = "PSWindowsUpdate"
                if (Get-Command -Name New-NetFirewallRule -ErrorAction SilentlyContinue) {
                    try {
                        Write-Output2 "The command: [New-NetFirewallRule] exists."
                        if (![bool](Get-NetFirewallRule -DisplayName $FireWallRule -ErrorAction SilentlyContinue)) {
                            Write-Output2 "Trying to create a new Windows Firewall Rule: [$FireWallRule] as the rule doesn't exist."
                            New-NetFirewallRule -DisplayName $FireWallRule -Direction Inbound -Protocol TCP -LocalPort $FirewallPorts -Action Allow -RemoteAddress "10.65.90.208", "10.95.99.156"
                            Write-Output2 "Successfully created a new Windows Firewall Rule: [$FireWallRule]."
                        }
                        else {
                            Write-Output2 "Firewall Rule: [$FireWallRule] already exist."
                        }
                    }
                    catch {
                        Write-Output2 "Failed to create a new Windows Firewall rule. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
                        throw
                    }
                }
                else {
                    Write-Output2 "Command: [New-NetFirewallRule] does NOT exists. Will NOT create a Windows Firewall rule."
                }

                $Get_Module = Get-Module $ModuleName -ListAvailable
                if (!$Get_Module) {
                    Write-Output2 "Module: [$ModuleName] is NOT installed."
                    try {
                        Write-Output2 "Trying to install NuGet provider."
                        # Force PowerShell to use TLS 1.2
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        if (! (Get-PackageProvider -Name NuGet -ListAvailable)) {
                            Install-PackageProvider -Name NuGet -Force -Confirm:$false
                        }
                        Write-Output2 "Successfully installed NuGet provider."
                    }
                    catch {
                        Write-Output2 "Failed to install NuGet provider. Error [$_]."
                    }

                    try {
                        Write-Output2 "Trying to register PSGallery as a trusted repository if not trusted."
                        $repository = Get-PSRepository -Name "PSGallery"
                        if ($repository.InstallationPolicy -ne 'Trusted') {
                            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
                        }
                        Write-Output2 "Successfully register PSGallery as a trusted repository."
                    }
                    catch {
                        Write-Output2 "Failed to register PSGallery as a trusted repository if not trusted. Error: [$_]."
                    }

                    try {
                        Write-Output2 "Trying to install the Module: [$ModuleName] for all users."
                        Install-Module -Name $ModuleName -Scope "AllUsers" -Force -Confirm:$false
                        Write-Output2 "Successfully installed the Module: [$ModuleName] for all users."
                    }
                    catch {
                        Write-Output2 "Failed to install the Module: [$ModuleName] for all users. Error: [$_]."
                    }
                }
                else {
                    Write-Output2 "Module: [$ModuleName] is already installed."
                }

                try {
                    Write-Output2 "Trying to executed [Invoke-WUJob]."
                    Invoke-WUJob -RunNow -Confirm:$false -Verbose
                    Write-Output2 "Successfully executed [Invoke-WUJob]. When the patching is done , check in the Log File: [c:\Windows\Temp\PSWindowsUpdate.log]"
                }
                catch {
                    Write-Output2 "Failed to install all available patches. Error: [$_]."
                }
            }
        }
        Write-Output2 "Successfully checked for applicable updates."
    }
    catch {
        Write-Output2 "Failed to check for applicable updates. Error: [$_]."
        throw
    }

    return [PSCustomObject]@{
        Log                 = $Script:Messages
        Needed_Patches_Bool = $Needed_Patches_Bool
        Needed_Patches      = $Needed_Patches
    }
} # End of function GetPatches_or_InstallPatches_invoke.

function Compliant_Check {
    [CmdletBinding()]

    param (
        #[Parameter (Mandatory = $False)]
        [Parameter (Mandatory = $false, position = 0 , ValueFromPipeline = $True )]
        [String] $Global:Server = $env:COMPUTERNAME,

        [Parameter (Mandatory = $false, position = 1)]
        [Switch] $VM
    )

    if ($VM.IsPresent -eq $true) {
        $Global:VM = $VM
    }

    # Start Copy AD_Reports.
    try {
        Write-CSVLog -Type $Global:PSSession_Text -Target $env:COMPUTERNAME -Output "Trying to check if FALFS1 is accessible."
        if (Test-Path $AD_Reports_FALFS1_Path) {
            Copy-Item $AD_Reports_FALFS1_Path "$env:windir\temp" -Force
        }
    }

    catch {
        Write-CSVLog -Type $Global:PSSession_Text -Target $env:COMPUTERNAME -Output "Failed access FALFS1."
    }
    # End Copy AD_Reports.

    # Start OS check.
    try {
        $Global:OS_Name = (Get-CimInstance -CimInstance Win32_OperatingSystem).Caption
        Write-CSVLog -Type $Global:OS_Text -Output "Successfully checked the OS Version: [$Global:OS_Name]."
    }

    catch {
        Write-CSVLog -Type $Global:OS_Text -Output "Failed to check the OS Version." -Throw
    }

    try {
        $OS_Architecture = (Get-CimInstance -CimInstance Win32_OperatingSystem).OSArchitecture
        Write-CSVLog -Type $Global:OS_Text -Output "Successfully checked the OS Architecture: [$OS_Architecture]."
    }

    catch {
        Write-CSVLog -Type $Global:OS_Text -Output "Failed to check the OS Architecture." -Throw
    }
    # End OS check.

    # Start PS check.

    if ($Global:OS_Name -match "2008 R2|2012|2016|2019|2022|2025" -and $PSVersionTable.PSVersion.Major -ge 5 -and $PSVersionTable.PSVersion.Minor -ge 1) {
        Write-CSVLog -Type $Global:PowerShell_Text -Output "Installed version is Compliant. Version: [$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)]."
    }

    elseif ($Global:OS_Name -match "2008 Enterprise" -or $Global:OS_Name -match "2008 Standard" -and $PSVersionTable.PSVersion.Major -le 3 `
            -and $PSVersionTable.PSVersion.Minor -le 0) {
        Write-CSVLog -Type $Global:PowerShell_Text -Output "Installed version is Compliant. Version: [$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)]."
    }

    else {
        Write-CSVLog -Type $Global:PowerShell_Text -Output "The version: [$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)] is NOT compliant."
    }

    # End PS check.

    # Start AD/Computer name check.
    if (Test-Path $Global:AD_Reports_Folder_File) {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "Successfully located AD file [$Global:AD_Reports_Folder_File]."

        try {
            $Global:AD_ParentContainer_ThisComputer = Import-Csv $Global:AD_Reports_Folder_File |
            Select-Object Name, ParentContainer |
            Where-Object { $_.Name -eq $env:COMPUTERNAME }
            Write-CSVLog -Type $Global:AD_Computer_Text -Output "Successfully imported AD file [$Global:AD_Reports_Folder_File]."
        }

        catch {
            Write-CSVLog -Type $Global:AD_Computer_Text -Output "Failed to imported AD file [$Global:AD_Reports_Folder_File]."
        }
    }

    else {
        #Set-Location "\\falfs1.world.fluidtechnology.net\resources\Scripts\Compliant_Check\"
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "Failed: Cannot find AD file [$Global:AD_Reports_Folder_File]."
    }
    if ($null -eq $Global:AD_ParentContainer_ThisComputer) {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "Failed: Cannot find server in AD list, or list is not copied."
    }

    if ($Global:SEEMM1_Check = $env:COMPUTERNAME -match $Global:ComputerName_SEEMM1) {
        #Write-CSVLog -Type $Global:AD_Computer_Text -Output "This server is located in Emmaboda in OU: [$($Global:AD_ParentContainer_ThisComputer.ParentContainer)]"
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "This server is located in Emmaboda. OU: [$($Global:AD_ParentContainer_ThisComputer.ParentContainer)]."
    }

    elseif ($Global:SESTO1_Check = $env:COMPUTERNAME -match $Global:ComputerName_SESTO1) {
        #Write-CSVLog -Type $Global:AD_Computer_Text -Output "This server is located in Stockholm in OU: [$($Global:AD_ParentContainer_ThisComputer.ParentContainer)]"
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "This server is located in Stockholm. OU: [$($Global:AD_ParentContainer_ThisComputer.ParentContainer)]."
    }

    elseif ($Global:Citrix_XA_Check = $env:COMPUTERNAME -match $Global:ComputerName_Citrix) {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "This is a Citrix XenApp server. OU: [$($Global:AD_ParentContainer_ThisComputer.ParentContainer)]."
    }

    else {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "Else this is NOT Emmaboda, Stockholm or XA machine. OU: [$($Global:AD_ParentContainer_ThisComputer.ParentContainer)]."
    }
    if ($Global:DS_Check = $Global:AD_ParentContainer_ThisComputer.ParentContainer -match "DSServers") {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "This is a DS server. OU: [$($Global:AD_ParentContainer_ThisComputer.ParentContainer)]."
    }

    elseif ($Global:DS_Check -eq $false) {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "This is not a DS server."
    }
    # End AD/Computer name check.

    # Start DISM checks for corruptions.
    if ($Global:OS_Name -match "2008 R2|2012|2016|2019|2022") {
        try {
            Write-CSVLog -Type $Global:DISM_Text -Output "Trying to check for Windows image corruption."
            $Image_Health_State = Dism /Online /Cleanup-Image /CheckHealth
            Write-CSVLog -Type $Global:DISM_Text -Output "Successfully checked Windows image for corruption."
        }

        catch {
            Write-CSVLog -Type $Global:DISM_Text -Output "Trying Failed to check Windows image for corruption." -Throw
        }

        if ($Image_Health_State -match "The component store is repairable") {
            Write-CSVLog -Type $Global:DISM_Text -Output "Found corruption in the Windows Image, need to repair it. NOT Compliant."

            try {
                Write-CSVLog -Type $Global:DISM_Text -Output "Trying to repair image, it will take around 15 minutes."
                DISM /Online /Cleanup-Image /RestoreHealth | Out-Null
            }

            catch {
                Write-CSVLog -Type $Global:DISM_Text -Output "Failed to repair image. You should repair the server using other paramenters for DISM or Repair-WindowsImage. NOT Compliant." -Throw
            }
        }

        else {
            Write-CSVLog -Type $Global:DISM_Text -Output "No corruption detected machine is compliant!"
        }
    }

    else {
        Write-CSVLog -Type $Global:DISM_Text -Output "Cannot check for Windows image corruption, DISM is not supported on legacy OS version, check SUR have to be installed manually."
    }
    # End DISM checks for corruptions.

    # Start Software and services checks.
    $Global:BigFix_Install_Check = Get-Software $Global:Server | Where-Object { $_.DisplayName -match $Global:IBM_Bigfix_Client }

    if ($Global:BigFix_Install_Check -and (Get-Service $Global:IBM_Bigfix_Service -ErrorAction SilentlyContinue).Status -eq "Running") {
        Write-CSVLog -Type $Global:Application_Services_Text -Output "BigFix is installed and the service is running. Is Compliant!"
    }

    else {
        Write-CSVLog -Type $Global:Application_Services_Text -Output "BigFix has some issues or is not installed. NOT Compliant."
    }

    # Start - Check if Azure Connected Machine Agent is installed on 2012 and Defender.
    try {
        Write-CSVLog -Type $Global:Application_Services_Text -Output "Trying to get the Softwares."

        # Determine how to check depending on OS. Defender is only supported on 2012 R2 and later.
        if ($Global:OS_Name -match '2012 R2') {
            # Check if Defender is listed in installed software
            $Defender_Install_Check = Get-Software | Where-Object { $_.DisplayName -match 'Microsoft Defender' }
    
            if ($null -ne $Defender_Install_Check) {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "Defender is installed. Is Compliant! | Is Compliant!"
                $Global:DefenderInstalled = $true
            }
            else {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "Defender is NOT installed. NOT Compliant."
                $Global:DefenderInstalled = $false
            }
        }
        else {
            # For 2016+ we don't check here, it's handled by features
            write-CSVLog -Type $Global:Application_Services_Text -Output "Defender install check not applicable (N/A)."
            $Global:DefenderInstalled = 'N/A'
        }
        # Azure connected machine agent is only supported on 2012 and later. It should be installed in order to retrieve MS patches.
        if ($Global:OS_Name -match '2012') {
            $AzureAgent_Install_Check = Get-Software | Where-Object { $_.DisplayName -eq "Azure Connected Machine Agent" }
            if ($null -ne $AzureAgent_Install_Check) {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "Azure Connected Machine Agent is installed. Is Compliant!"
                $Global:AzureAgentInstalled = $true
            }
            else {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "Azure Connected Machine Agent is NOT installed. NOT Compliant."
                $Global:AzureAgentInstalled = $false
            }
            # Check Azure connected machine agent.
            if ($Global:AzureAgentInstalled -eq $true) {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "Azure Connected Machine Agent is installed."
            }
            else {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "Azure Connected Machine Agent is NOT installed. NOT Compliant."
            }
        }
    }
    catch {
        Write-CSVLog -Type $Global:Application_Services_Text -Output "Failed to get the Softwares." -Throw
    }

    $proc = Get-Process | Where-Object { $_.Name -eq "MsSense" }

    if ($proc) {
        $Global:MsSense_Process_Running = $true
        $MsSense_Process_Status_Text = 'MsSense.exe process is running.'
    }
    else {
        $Global:MsSense_Process_Running = $false
        $MsSense_Process_Status_Text = 'MsSense.exe process is NOT running.'
    }
    Write-CSVLog -Type $Global:Application_Services_Text -Output $MsSense_Process_Status_Text

    $proc = Get-Process | Where-Object { $_.Name -eq "MsMpEng" }
    if ($proc) {
        $Global:MsMpEng_Process_Running = $true
        $MsMpEng_Process_Status_Text = 'MsMpEng.exe process is running.'
    }
    else {
        $Global:MsMpEng_Process_Running = $false
        $MsMpEng_Process_Status_Text = 'MsSense.exe process is NOT running.'
    }

    Write-CSVLog -Type $Global:Application_Services_Text -Output $MsMpEng_Process_Status_Text

    if ($Global:MsMpEng_Process_Running -eq $true -and $Global:MsSense_Process_Running -eq $true) {
        try {
            Write-CSVLog -Type $Global:Application_Services_Text -Output "Both MsMpEng.exe and MsSense.exe processes is running."
            $MP_Status = Get-MpComputerStatus | Select-Object TamperProtectionSource
            Write-CSVLog -Type $Global:Application_Services_Text -Output "TamperProtectionSource: [$($MP_Status.TamperProtectionSource)]."
        }
        catch {
            Write-CSVLog -Type $Global:Application_Services_Text -Output "Failed to get Defender status." -Throw
        }
        if ($MP_Status.TamperProtectionSource -eq "ATP") {
            Write-CSVLog -Type $Global:Application_Services_Text -Output "Tamper Protection is enabled. Is Compliant!"
            $Global:Defender_TamperingProtection = $true
        }
        else {
            $Global:Defender_TamperingProtection = $false
            Write-CSVLog -Type $Global:Application_Services_Text -Output "Tamper Protection is NOT enabled. NOT Compliant."
        }
    }
    # End - Check if Azure Connected Machine Agent is installed on 2012 and Defender.

    # Start - Check if SentinelOne is installed and running, then check version.
    $Global:S1_Agent_Install_Check = Get-Software $Global:Server | Where-Object { $_.DisplayName -match $Global:Sentinel1 }
    $BinaryPathName = Get-Service $Global:Sentinel1_Service -ErrorAction SilentlyContinue

    if ($Global:S1_Agent_Install_Check -and $BinaryPathName.Status -eq "Running") {
        try {
            Write-CSVLog -Type $Global:Application_Services_Text -Output "Trying to check version on $Global:Sentinel1."
            if ($Global:OS_Name -match "2016|2019|2022|2012|2008") {
                $S1BinaryPath = Get-CimInstance -ClassName Win32_Service -Filter "Name='$Global:Sentinel1_Service'" | Select-Object -ExpandProperty PathName
                $S1BinaryPath = $S1BinaryPath.replace('"', '')
            }
            else {
                $S1BinaryPath = Get-CimInstance -ClassName Win32_Service -Filter "Name='$Global:Sentinel1_Service'" | Select-Object -ExpandProperty PathName
                $S1BinaryPath = $S1BinaryPath.replace('"', '')
            }
            $S1Version = (Get-Item $S1BinaryPath).VersionInfo.FileVersion
            Write-CSVLog -Type $Global:Application_Services_Text -Output "Successfully checked version on $Global:Sentinel1."
        }
        catch {
            Write-CSVLog -Type $Global:Application_Services_Text -Output "Failed to check version on $Global:Sentinel1."
        }

        if ($S1Version) {
            if ([version]$S1Version -ge [version]"23.4.4.223") {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "$Global:Sentinel1 is installed and the service is running and it's on compliant version: [$S1Version]. Is Compliant!"
            }
            else {
                Write-CSVLog -Type $Global:Application_Services_Text -Output "$Global:Sentinel1 is installed and the service is running but it's NOT on a compliant version: [$S1Version]. Is NOT Compliant!"
            }
        }
    }
    # End - Check if SentinelOne is installed and running, then check version.

    # Check if either Defender or SentinelOne is installed and running.
    if (($Global:MsMpEng_Process_Running -eq $true -and $Global:MsSense_Process_Running -eq $true -and $Global:Defender_TamperingProtection -eq $true) -or
        ($Global:S1_Agent_Install_Check -and $BinaryPathName.Status -eq "Running")) {
        Write-CSVLog -Type $Global:Application_Services_Text -Output "Either Defender or SentinelOne is installed and running. Is Compliant!"
    }
    else {
        Write-CSVLog -Type $Global:Application_Services_Text -Output "Neither Defender or SentinelOne is installed and running. NOT Compliant."
    }
    # End Software and services checks.

    # Start Get latest patch status.
    try {
        Write-CSVLog -Type $Global:PatchStatus_Latest_Text -Output "Trying to get installed hotfixes using [Get-HotFix]."
        if ($Global:PatchStatus_Latest = (Get-HotFix -ErrorAction SilentlyContinue | Where-Object { $_.InstalledOn -ne $null } | Sort-Object -Property InstalledOn)[-1]) {
            $Global:CurrentDate = Get-Date
            Write-CSVLog -Type $Global:PatchStatus_Latest_Text -Output "Successfully got installed hotfixes using [Get-HotFix]."
            if ($Global:PatchStatus_Check = $Global:CurrentDate.AddDays(-$Global:Patch_Days) -ge $Global:PatchStatus_Latest.InstalledOn -and $Global:OS_Name -notmatch "2003|2008|2000") {
                Write-CSVLog -Type $Global:PatchStatus_Latest_Text -Output "This server hasn't been patched in $Global:Patch_Days days! LastPatchDate: [$($Global:PatchStatus_Latest.InstalledOn)]"
            }

            else {
                Write-CSVLog -Type $Global:PatchStatus_Latest_Text -Output "This server has been patched the last $Global:Patch_Days days. Is Compliant!"
            }
        }

        else {
            Write-CSVLog -Type $Global:PatchStatus_Latest_Text -Output "Cannot find any patch installed with: [Get-HotFix]. Is NOT Compliant!"
        }
    }

    catch {
        Write-CSVLog -Type $Global:PatchStatus_Latest_Text -Output "Failed to get installed hot fixes using [Get-HotFix]." -Throw
    }

    if ($EnablePatchRemediate) {
        try {
            Write-CSVLog -Type $Global:SWPM_Text -Output "Checking if there is any missing patches in SolarWinds Patch Manager."
            $rebootpending = Get-PendingRebootStatus | Select-Object -ExpandProperty PendingReboot   
            $Global:pendingpatches = GetPatches_or_InstallPatches_invoke | Select-Object -ExpandProperty Needed_Patches_Bool
            Write-CSVLog -Type $Global:SWPM_Text -Output "Successfully checked if there is any missing patches in SolarWinds Patch Manager."
        }

        catch {
            Write-CSVLog -Type $Global:SWPM_Text -Output "Failed to check if there is any missing patches in SolarWinds Patch Manager."
        }
        Write-CSVLog -Type $Global:SWPM_Text -Output "Pending patch part."
        if ($Global:pendingpatches -and $Remediation -eq $true -and $EnablePatchRemediate -eq $true) {
            try {
                Write-CSVLog -Type $Global:SWPM_Text -Output "Trying install the patches."
                GetPatches_or_InstallPatches_invoke -InstallAllUpdates
                Write-CSVLog -Type $Global:SWPM_Text -Output "Pending patches: [$Global:pendingpatches] | Reboot Pending patches: [$rebootpending]."
                Write-CSVLog -Type $Global:SWPM_Text -Output "There is missing patches. I'm installing them and breaking the script, run this again until every patch is installed."
                break
            }

            catch {
                Write-CSVLog -Type $Global:SWPM_Text -Output "Failed install the patches."
                Write-CSVLog -Type $Global:SWPM_Text -Output "Pending patches - $Global:pendingpatches but unable to install them, please check further."
            }
        }

        elseif ($Global:pendingpatches) {
            Write-CSVLog -Type $Global:SWPM_Text -Output "Server have missing patches! | Pending patches: [$Global:pendingpatches] | Reboot Pending patches: [$rebootpending]"
        }

        elseif ($Global:PatchStatus_Check -eq $false) {
            Write-CSVLog -Type $Global:SWPM_Text -Output "Server is Compliant! | Pending patches: [$Global:pendingpatches] | Reboot Pending patches: [$rebootpending] | Patch is Compliant."
        }

        elseif ($Global:PatchStatus_Check -eq $true -and $Global:OS_Name -notmatch "2003|2008|2000") {
            Write-CSVLog -Type $Global:SWPM_Text -Output "SWPM probably have some issues, because the server has not been patched for $Global:Patch_Days days or longer!. Is NOT Compliant"
        }
    }
    # End SWPM Patches check.

    # Start PowerPlan.
    if ($Global:OS_Name -match "2008 R2|2012|2016|2019|2022") {
        try {
            $Global:hpPlan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace "root\cimv2\power" | Where-Object { $_.ElementName -eq $Global:PowerPlan_HighPerformance }
            Write-CSVLog -Type $Global:PowerPlan_Text -Output "Successfully checked the PowerPlan for: [$Global:PowerPlan_HighPerformance]."
        }
        catch {
            Write-CSVLog -Type $Global:PowerPlan_Text -Output "Failed to check the PowerPlan for: [$Global:PowerPlan_HighPerformance]." -Throw
        }

        if ($Global:hpPlan.IsActive -eq $true) {
            Write-CSVLog -Type $Global:PowerPlan_Text -Output "Server is using PowerPlan: [$Global:PowerPlan_HighPerformance]."
        }

        elseif ($Global:hpPlan.IsActive -eq $false) {
            Write-CSVLog -Type $Global:PowerPlan_Text -Output "Server is NOT Compliant, it's NOT using correct PowerPlan, activate Remediation to set PowerPlan: [$Global:PowerPlan_HighPerformance]."

            if ($Remediation -eq $true) {
                Write-CSVLog -Type $Global:PowerPlan_Text -Output "Server is NOT using PowerPlan: [$Global:PowerPlan_HighPerformance]. I'm activating it now."

                try {
                    Start-Process "$env:windir\System32\powercfg.exe" -ArgumentList "/s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
                    Write-CSVLog -Type $Global:PowerPlan_Text -Output "Successfully activated PowerPlan: [$Global:PowerPlan_HighPerformance]."
                }

                catch {
                    Write-CSVLog -Type $Global:PowerPlan_Text -Output "Failed to activated the PowerPlan for: [$Global:PowerPlan_HighPerformance]." -Throw
                }
            }
        }

        else {
            Write-CSVLog -Type $Global:PowerPlan_Text -Output "Value not set, activate Remediation to fix to PowerPlan: [$Global:PowerPlan_HighPerformance]. NOT Compliant."
        }

    }
    else {
        Write-CSVLog -Type $Global:PowerPlan_Text -Output "Too old OS to set PowerPlan: [$Global:PowerPlan_HighPerformance]."

    }
    # End PowerPlan.

    # Start Disable network card sleep for 2012+.

    if ($Global:OS_Name -match "2008 R2|2012|2016|2019|2022" -and $Remediation -eq $true) {
        try {
            Write-CSVLog -Type $Global:NetAdapterPowerManagement_Text -Output "Trying to disabled NetworkPowerManagement."
            $Global:NetworkAdapter = Get-NetAdapterPowerManagement
            Disable-NetAdapterPowerManagement -Name $Global:NetworkAdapter.name
            Start-Sleep -Seconds 5
            Write-CSVLog -Type $Global:NetAdapterPowerManagement_Text -Output "Successfully disabled NetworkPowerManagement."
        }

        catch {
            Write-CSVLog -Type $Global:NetAdapterPowerManagement_Text -Output "Failed to disabled NetworkPowerManagement." -Throw
        }
    }

    elseif ($Remediation -eq $false) {
        Write-CSVLog -Type $Global:NetAdapterPowerManagement_Text -Output "The remediation option is not set, will not change the NetworkPowerManagement mode."
        Write-CSVLog -Type $Global:NetAdapterPowerManagement_Text -Output "Please note that for OS 2008 and older does have the command *-NetAdapterPowerManagement, you will have to check this manually."

    }
    # End Disable network card sleep.

    #################### Start Registry checks. ####################
    # Start Registry check if TLS1.0 Server Enabled is inactive.
    $Global:TLS1_0_Enabled_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
    $Global:TLS1_0_Enabled_Reg_DWORD = "Enabled"
    $Global:TLS1_0_Enabled_Reg_DWORD_Value = "0"
    $Global:TLS1_0_Enabled_RegType = "DWORD"
    $Global:TLS1_0_Enabled_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_0_Enabled_Reg_Compliance_Remediation)) {
        $Global:TLS1_0_Enabled_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_0_Enabled_Name = "TLS1.0 Enabled"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_0_Enabled_Reg
        RegName     = $Global:TLS1_0_Enabled_Reg_DWORD
        RegType     = $Global:TLS1_0_Enabled_RegType
        RegValue    = $Global:TLS1_0_Enabled_Reg_DWORD_Value
        Remediation = $Global:TLS1_0_Enabled_Reg_Compliance_Remediation
        Description = $Global:TLS1_0_Enabled_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_0_Enabled_Check = $Global:Reg_Compliance
    # End Registry check if TLS1.0 Server is inactive.

    # Start Registry check if TLS1.2 Server is Enabled.
    $Global:TLS1_2_Enabled_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
    $Global:TLS1_2_Enabled_Reg_DWORD = "Enabled"
    $Global:TLS1_2_Enabled_Reg_DWORD_Value = "1"
    $Global:TLS1_2_Enabled_RegType = "DWORD"
    $Global:TLS1_2_Enabled_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_2_Enabled_Reg_Compliance_Remediation)) {
        $Global:TLS1_2_Enabled_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_2_Enabled_Name = "TLS1.2 Enabled"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_2_Enabled_Reg
        RegName     = $Global:TLS1_2_Enabled_Reg_DWORD
        RegType     = $Global:TLS1_2_Enabled_RegType
        RegValue    = $Global:TLS1_2_Enabled_Reg_DWORD_Value
        Remediation = $Global:TLS1_2_Enabled_Reg_Compliance_Remediation
        Description = $Global:TLS1_2_Enabled_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_2_Enabled_Check = $Global:Reg_Compliance
    # End Registry check if TLS1.2 Server is Enabled.

    # Start Registry check if TLS1.2 Client is Enabled.
    $Global:TLS1_2_Enabled_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
    $Global:TLS1_2_Enabled_Reg_DWORD = "Enabled"
    $Global:TLS1_2_Enabled_Reg_DWORD_Value = "1"
    $Global:TLS1_2_Enabled_RegType = "DWORD"
    $Global:TLS1_2_Enabled_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_2_Enabled_Reg_Compliance_Remediation)) {
        $Global:TLS1_2_Enabled_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_2_Enabled_Name = "TLS1.2 Enabled"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_2_Enabled_Reg
        RegName     = $Global:TLS1_2_Enabled_Reg_DWORD
        RegType     = $Global:TLS1_2_Enabled_RegType
        RegValue    = $Global:TLS1_2_Enabled_Reg_DWORD_Value
        Remediation = $Global:TLS1_2_Enabled_Reg_Compliance_Remediation
        Description = $Global:TLS1_2_Enabled_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_2_Enabled_Check_Client = $Global:Reg_Compliance
    # End Registry check if TLS1.2 Client is Enabled.

    # Start Registry check if TLS1.2 Server DisabledByDefault is inactive.
    $Global:TLS1_2_DisabledByDefault_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
    $Global:TLS1_2_DisabledByDefault_Reg_DWORD = "DisabledByDefault"
    $Global:TLS1_2_DisabledByDefault_Reg_DWORD_Value = "0"
    $Global:TLS1_2_DisabledByDefault_RegType = "DWORD"
    $Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation)) {
        $Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_2_DisabledByDefault_Name = "TLS1.2 DisabledByDefault"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_2_DisabledByDefault_Reg
        RegName     = $Global:TLS1_2_DisabledByDefault_Reg_DWORD
        RegType     = $Global:TLS1_2_DisabledByDefault_RegType
        RegValue    = $Global:TLS1_2_DisabledByDefault_Reg_DWORD_Value
        Remediation = $Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation
        Description = $Global:TLS1_2_DisabledByDefault_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_2_DisabledByDefault_Check = $Global:Reg_Compliance
    # End Registry check if TLS1.2 Server DisabledByDefault is inactive.

    # Start Registry check if TLS1.2 Client DisabledByDefault is inactive.
    $Global:TLS1_2_DisabledByDefault_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
    $Global:TLS1_2_DisabledByDefault_Reg_DWORD = "DisabledByDefault"
    $Global:TLS1_2_DisabledByDefault_Reg_DWORD_Value = "0"
    $Global:TLS1_2_DisabledByDefault_RegType = "DWORD"
    $Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation)) {
        $Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_2_DisabledByDefault_Name = "TLS1.2 DisabledByDefault"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_2_DisabledByDefault_Reg
        RegName     = $Global:TLS1_2_DisabledByDefault_Reg_DWORD
        RegType     = $Global:TLS1_2_DisabledByDefault_RegType
        RegValue    = $Global:TLS1_2_DisabledByDefault_Reg_DWORD_Value
        Remediation = $Global:TLS1_2_DisabledByDefault_Reg_Compliance_Remediation
        Description = $Global:TLS1_2_DisabledByDefault_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_2_DisabledByDefault_Check_Client = $Global:Reg_Compliance
    # End Registry check if TLS1.2 Client DisabledByDefault is inactive.

    # Start Registry check if TLS1.3 Server is Enabled.
    if ($Global:OS_Name -match "2022|2025") {
        $Global:TLS1_3_Enabled_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server"
        $Global:TLS1_3_Enabled_Reg_DWORD = "Enabled"
        $Global:TLS1_3_Enabled_Reg_DWORD_Value = "1"
        $Global:TLS1_3_Enabled_RegType = "DWORD"
        $Global:TLS1_3_Enabled_Reg_Compliance_Remediation = $Remediation
        if (!($Global:TLS1_3_Enabled_Reg_Compliance_Remediation)) {
            $Global:TLS1_3_Enabled_Reg_Compliance_Remediation = $false
        }
        $Global:TLS1_3_Enabled_Name = "TLS1.3 Enabled"

        $Reg_Compliance_Splatter = @{
            RegPath     = $Global:TLS1_3_Enabled_Reg
            RegName     = $Global:TLS1_3_Enabled_Reg_DWORD
            RegType     = $Global:TLS1_3_Enabled_RegType
            RegValue    = $Global:TLS1_3_Enabled_Reg_DWORD_Value
            Remediation = $Global:TLS1_3_Enabled_Reg_Compliance_Remediation
            Description = $Global:TLS1_3_Enabled_Name
        }

        Reg_Compliance @Reg_Compliance_Splatter
        $Global:TLS1_3_Enabled_Check = $Global:Reg_Compliance
        # End Registry check if TLS1.3 is Enabled.

        # Start Registry check if TLS1.3 Client is Enabled.
        $Global:TLS1_3_Enabled_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
        $Global:TLS1_3_Enabled_Reg_DWORD = "Enabled"
        $Global:TLS1_3_Enabled_Reg_DWORD_Value = "1"
        $Global:TLS1_3_Enabled_RegType = "DWORD"
        $Global:TLS1_3_Enabled_Reg_Compliance_Remediation = $Remediation
        if (!($Global:TLS1_3_Enabled_Reg_Compliance_Remediation)) {
            $Global:TLS1_3_Enabled_Reg_Compliance_Remediation = $false
        }
        $Global:TLS1_3_Enabled_Name = "TLS1.3 Enabled"

        $Reg_Compliance_Splatter = @{
            RegPath     = $Global:TLS1_3_Enabled_Reg
            RegName     = $Global:TLS1_3_Enabled_Reg_DWORD
            RegType     = $Global:TLS1_3_Enabled_RegType
            RegValue    = $Global:TLS1_3_Enabled_Reg_DWORD_Value
            Remediation = $Global:TLS1_3_Enabled_Reg_Compliance_Remediation
            Description = $Global:TLS1_3_Enabled_Name
        }

        Reg_Compliance @Reg_Compliance_Splatter
        $Global:TLS1_3_Enabled_Check_Client = $Global:Reg_Compliance
        # End Registry check if TLS1.3 Client is Enabled.

        # Start Registry check if TLS1.3 Server DisabledByDefault is inactive.
        $Global:TLS1_3_DisabledByDefault_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
        $Global:TLS1_3_DisabledByDefault_Reg_DWORD = "DisabledByDefault"
        $Global:TLS1_3_DisabledByDefault_Reg_DWORD_Value = "0"
        $Global:TLS1_3_DisabledByDefault_RegType = "DWORD"
        $Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation = $Remediation
        if (!($Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation)) {
            $Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation = $false
        }
        $Global:TLS1_3_DisabledByDefault_Name = "TLS1.3 DisabledByDefault"

        $Reg_Compliance_Splatter = @{
            RegPath     = $Global:TLS1_3_DisabledByDefault_Reg
            RegName     = $Global:TLS1_3_DisabledByDefault_Reg_DWORD
            RegType     = $Global:TLS1_3_DisabledByDefault_RegType
            RegValue    = $Global:TLS1_3_DisabledByDefault_Reg_DWORD_Value
            Remediation = $Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation
            Description = $Global:TLS1_3_DisabledByDefault_Name
        }

        Reg_Compliance @Reg_Compliance_Splatter
        $Global:TLS1_3_DisabledByDefault_Check = $Global:Reg_Compliance
        # End Registry check if TLS1.3 Server DisabledByDefault is inactive.

        # Start Registry check if TLS1.3 Client DisabledByDefault is inactive.
        $Global:TLS1_3_DisabledByDefault_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
        $Global:TLS1_3_DisabledByDefault_Reg_DWORD = "DisabledByDefault"
        $Global:TLS1_3_DisabledByDefault_Reg_DWORD_Value = "0"
        $Global:TLS1_3_DisabledByDefault_RegType = "DWORD"
        $Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation = $Remediation
        if (!($Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation)) {
            $Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation = $false
        }
        $Global:TLS1_3_DisabledByDefault_Name = "TLS1.3 DisabledByDefault"

        $Reg_Compliance_Splatter = @{
            RegPath     = $Global:TLS1_3_DisabledByDefault_Reg
            RegName     = $Global:TLS1_3_DisabledByDefault_Reg_DWORD
            RegType     = $Global:TLS1_3_DisabledByDefault_RegType
            RegValue    = $Global:TLS1_3_DisabledByDefault_Reg_DWORD_Value
            Remediation = $Global:TLS1_3_DisabledByDefault_Reg_Compliance_Remediation
            Description = $Global:TLS1_3_DisabledByDefault_Name
        }

        Reg_Compliance @Reg_Compliance_Splatter
        $Global:TLS1_3_DisabledByDefault_Check_Client = $Global:Reg_Compliance
    }
    # End Registry check if TLS1.3 Client DisabledByDefault is inactive.

    # Start Registry check if TLS1.0 DisabledByDefault is active.
    $Global:TLS1_0_DisabledByDefault_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
    $Global:TLS1_0_DisabledByDefault_Reg_DWORD = "DisabledByDefault"
    $Global:TLS1_0_DisabledByDefault_Reg_DWORD_Value = "1"
    $Global:TLS1_0_DisabledByDefault_RegType = "DWORD"
    $Global:TLS1_0_DisabledByDefault_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_0_DisabledByDefault_Reg_Compliance_Remediation)) {
        $Global:TLS1_0_DisabledByDefault_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_0_DisabledByDefault_Name = "TLS1.0 DisabledByDefault"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_0_DisabledByDefault_Reg
        RegName     = $Global:TLS1_0_DisabledByDefault_Reg_DWORD
        RegType     = $Global:TLS1_0_DisabledByDefault_RegType
        RegValue    = $Global:TLS1_0_DisabledByDefault_Reg_DWORD_Value
        Remediation = $Global:TLS1_0_DisabledByDefault_Reg_Compliance_Remediation
        Description = $Global:TLS1_0_DisabledByDefault_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_0_DisabledByDefault_Check = $Global:Reg_Compliance
    # End Registry check if TLS1.0 DisabledByDefault is active.

    # Start Registry check if TLS1.1 Enabled is inactive.
    $Global:TLS1_1_Enabled_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    $Global:TLS1_1_Enabled_Reg_DWORD = "Enabled"
    $Global:TLS1_1_Enabled_Reg_DWORD_Value = "0"
    $Global:TLS1_1_Enabled_RegType = "DWORD"
    $Global:TLS1_1_Enabled_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_1_Enabled_Reg_Compliance_Remediation)) {
        $Global:TLS1_1_Enabled_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_1_Enabled_Name = "TLS1.1 Enabled"
    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_1_Enabled_Reg
        RegName     = $Global:TLS1_1_Enabled_Reg_DWORD
        RegType     = $Global:TLS1_1_Enabled_RegType
        RegValue    = $Global:TLS1_1_Enabled_Reg_DWORD_Value
        Remediation = $Global:TLS1_1_Enabled_Reg_Compliance_Remediation
        Description = $Global:TLS1_1_Enabled_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_1_Enabled_Check = $Global:Reg_Compliance
    # End Registry check if TLS1.1 Enabled is inactive.

    # Start Registry check if TLS1.1 DisabledByDefault is active.
    $Global:TLS1_1_DisabledByDefault_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    $Global:TLS1_1_DisabledByDefault_Reg_DWORD = "DisabledByDefault"
    $Global:TLS1_1_DisabledByDefault_Reg_DWORD_Value = "1"
    $Global:TLS1_1_DisabledByDefault_RegType = "DWORD"
    $Global:TLS1_1_DisabledByDefault_Reg_Compliance_Remediation = $Remediation
    if (!($Global:TLS1_1_DisabledByDefault_Reg_Compliance_Remediation)) {
        $Global:TLS1_1_DisabledByDefault_Reg_Compliance_Remediation = $false
    }
    $Global:TLS1_1_DisabledByDefault_Name = "TLS1.1 DisabledByDefault"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:TLS1_1_DisabledByDefault_Reg
        RegName     = $Global:TLS1_1_DisabledByDefault_Reg_DWORD
        RegType     = $Global:TLS1_1_DisabledByDefault_RegType
        RegValue    = $Global:TLS1_1_DisabledByDefault_Reg_DWORD_Value
        Remediation = $Global:TLS1_1_DisabledByDefault_Reg_Compliance_Remediation
        Description = $Global:TLS1_1_DisabledByDefault_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:TLS1_1_DisabledByDefault_Check = $Global:Reg_Compliance
    # End Registry check if TLS1.1 DisabledByDefault is active.

    # Start Registry check if weak ciphers DES/3DES is inactive.
    $Global:Ciphers_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168"
    $Global:Ciphers_Reg_DWORD = "Enabled"
    $Global:Ciphers_Reg_DWORD_Value = "0"
    $Global:Ciphers_RegType = "DWORD"
    $Global:Ciphers_Reg_Compliance_Remediation = $Remediation
    if (!($Global:Ciphers_Reg_Compliance_Remediation)) {
        $Global:Ciphers_Reg_Compliance_Remediation = $false
    }
    $Global:Ciphers_Name = "Ciphers Triple DES 168"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:Ciphers_Reg
        RegName     = $Global:Ciphers_Reg_DWORD
        RegType     = $Global:Ciphers_RegType
        RegValue    = $Global:Ciphers_Reg_DWORD_Value
        Remediation = $Global:Ciphers_Reg_Compliance_Remediation
        Description = $Global:Ciphers_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:DES_3DES_Check = $Global:Reg_Compliance
    # End Registry check if weak ciphers DES/3DES is inactive.

    # Start Registry check if SMB Signed is activated.
    $Global:SMB_Signed_Enabled_Reg = "HKLM:\System\CurrentControlSet\Services\LanManWorkstation\Parameters"
    $Global:SMB_Signed_Enabled_Reg_DWORD = "RequireSecuritySignature"
    $Global:SMB_Signed_Enabled_Reg_DWORD_Value = "1"
    $Global:SMB_Signed_Enabled_RegType = "DWORD"
    $Global:SMB_Signed_Enabled_Reg_Compliance_Remediation = $Remediation
    if (!($Global:SMB_Signed_Enabled_Reg_Compliance_Remediation)) {
        $Global:SMB_Signed_Enabled_Reg_Compliance_Remediation = $false
    }
    $Global:SMB_Signed_Enabled_Name = "SMB Signed is activated"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:SMB_Signed_Enabled_Reg
        RegName     = $Global:SMB_Signed_Enabled_Reg_DWORD
        RegType     = $Global:SMB_Signed_Enabled_RegType
        RegValue    = $Global:SMB_Signed_Enabled_Reg_DWORD_Value
        Remediation = $Global:SMB_Signed_Enabled_Reg_Compliance_Remediation
        Description = $Global:SMB_Signed_Enabled_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:SMB_Signed_Enabled_Check = $Global:Reg_Compliance
    # End Registry check if SMB Signed is activated.

    # Start Registry check if weak cipher RC4 is inactive.
    $Global:RC4_Reg_Key_RC4_40_128 = "RC4 40/128"
    $Global:RC4_Reg_Key_RC4_56_128 = "RC4 56/128"
    $Global:RC4_Reg_Key_RC4_128_128 = "RC4 128/128"
    $Global:RC4_Reg_Keys = "RC4 40/128", "RC4 56/128", "RC4 128/128"
    $Global:Ciphers_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers"
    $Global:Ciphers_Subkey_Ciphers = "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers"
    $Global:RC4_Reg_DWORD_Enabled = "Enabled"

    foreach ($Global:RC4_Reg_Key in $Global:RC4_Reg_Keys) {
        $Global:Ciphers_Reg_RC4_FullPath = "$Global:Ciphers_Reg\$Global:RC4_Reg_Key"

        if (($Global:RC4_Check = (Test-RegistryValue $Global:Ciphers_Reg_RC4_FullPath -Value $Global:RC4_Reg_DWORD_Enabled) -eq $true -and ($Global:Property_Value -eq 0))) {
            Write-CSVLog -Type $Global:Reg_Text -Output "RC4 value [$Global:Ciphers_Reg_RC4_FullPath] is compliant!"
        }

        else {
            Write-CSVLog -Type $Global:Reg_Text -Output "RC4 is value is NOT compliant! [$Global:Ciphers_Reg_RC4_FullPath]."
            if ($Remediation -eq $true -and $Global:RC4_Check -eq $false) {

                try {
                    $Global:Ciphers_Check = (Get-Item HKLM:\).OpenSubKey($Global:Ciphers_Subkey_Ciphers, $true)
                    if ($Global:Ciphers_Check) {
                        $Global:Ciphers_Reg_RC4_FullPath = "$Global:Ciphers_Reg\$Global:RC4_Reg_Key"
                        $Global:Ciphers_Check.CreateSubKey($Global:RC4_Reg_Key)
                        New-ItemProperty -Path $Global:Ciphers_Reg_RC4_FullPath -Name $Global:RC4_Reg_DWORD_Enabled -Type DWORD -Value 0 -Force
                        Write-CSVLog -Type $Global:Reg_Text -Output "Remediation is active, creating the value [$Global:Ciphers_Reg_RC4_FullPath]. Rerun the script to rescan."
                        $Global:Ciphers_Check.Close()
                    }
                }

                catch {
                    Write-CSVLog -Type $Global:Reg_Text -Output "Failed to remediate the registry entry for: [$Global:Ciphers_Reg_RC4_FullPath]." -Throw
                }
            }
        }
    }
    # End Registry check if weak cipher RC4 is inactive.

    # Start Registry check if Autorun on devices plugged in is inactive.
    $Global:InactivateAutorunDevice_Reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer"
    $Global:InactivateAutorunDevice_Reg_DWORD = "NoDriveTypeAutoRun"
    $Global:InactivateAutorunDevice_Reg_DWORD_Value = "255"
    $Global:InactivateAutorunDevice_RegType = "DWORD"
    $Global:InactivateAutorunDevice_Reg_Compliance_Remediation = $Remediation
    if (!($Global:InactivateAutorunDevice_Reg_Compliance_Remediation)) {
        $Global:InactivateAutorunDevice_Reg_Compliance_Remediation = $false
    }
    $Global:InactivateAutorunDevice_Name = "InactivateAutorunDevice"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:InactivateAutorunDevice_Reg
        RegName     = $Global:InactivateAutorunDevice_Reg_DWORD
        RegType     = $Global:InactivateAutorunDevice_RegType
        RegValue    = $Global:InactivateAutorunDevice_Reg_DWORD_Value
        Remediation = $Global:InactivateAutorunDevice_Reg_Compliance_Remediation
        Description = $Global:InactivateAutorunDevice_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:InactivateAutorunDevice_Check = $Global:Reg_Compliance
    # End Registry check if Autorun on devices plugged in is inactive.

    # Start Registry check if Set Cached logons is set to 0.
    $Global:CachedLogons_Reg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $Global:CachedLogons_Reg_DWORD = "CachedLogonsCount"
    $Global:CachedLogons_Reg_DWORD_Value = "0"
    $Global:CachedLogons_RegType = "DWORD"
    $Global:CachedLogons_Reg_Compliance_Remediation = $Remediation
    if (!($Global:CachedLogons_Reg_Compliance_Remediation)) {
        $Global:CachedLogons_Reg_Compliance_Remediation = $false
    }
    $Global:CachedLogons_Name = "CachedLogons"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:CachedLogons_Reg
        RegName     = $Global:CachedLogons_Reg_DWORD
        RegType     = $Global:CachedLogons_RegType
        RegValue    = $Global:CachedLogons_Reg_DWORD_Value
        Remediation = $Global:CachedLogons_Reg_Compliance_Remediation
        Description = $Global:CachedLogons_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:CachedLogons_Check = $Global:Reg_Compliance
    # End Registry check if Set Cached logons is set to 0.

    # Start Registry check if Restrict anonymous is set to 1.
    $Global:RestrictAnonymous_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $Global:RestrictAnonymous_Reg_DWORD = "restrictanonymous"
    $Global:RestrictAnonymous_Reg_DWORD_Value = "1"
    $Global:RestrictAnonymous_RegType = "DWORD"
    $Global:RestrictAnonymous_Reg_Compliance_Remediation = $Remediation
    if (!($Global:RestrictAnonymous_Reg_Compliance_Remediation)) {
        $Global:RestrictAnonymous_Reg_Compliance_Remediation = $false
    }
    $Global:RestrictAnonymous_Name = "Restrict Anonymous"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:RestrictAnonymous_Reg
        RegName     = $Global:RestrictAnonymous_Reg_DWORD
        RegType     = $Global:RestrictAnonymous_RegType
        RegValue    = $Global:RestrictAnonymous_Reg_DWORD_Value
        Remediation = $Global:RestrictAnonymous_Reg_Compliance_Remediation
        Description = $Global:RestrictAnonymous_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:RestrictAnonymous_Check = $Global:Reg_Compliance
    # End Registry check if Restrict anonymous is set to 1.
    
    # Start Registry check RunAsPPL in LSA.
    $Global:RunAsPPL_LSA_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $Global:RunAsPPL_LSA_Reg_DWORD = "RunAsPPL"
    $Global:RunAsPPL_LSA_Reg_DWORD_Value = "1"
    $Global:RunAsPPL_LSA_RegType = "DWORD"
    $Global:RunAsPPL_LSA_Reg_Compliance_Remediation = $Remediation
    if (!($Global:RunAsPPL_LSA_Reg_Compliance_Remediation)) {
        $Global:RunAsPPL_LSA_Reg_Compliance_Remediation = $false
    }
    $Global:RunAsPPL_LSA_Name = "RunAsPPL LSA"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:RunAsPPL_LSA_Reg
        RegName     = $Global:RunAsPPL_LSA_Reg_DWORD
        RegType     = $Global:RunAsPPL_LSA_RegType
        RegValue    = $Global:RunAsPPL_LSA_Reg_DWORD_Value
        Remediation = $Global:RunAsPPL_LSA_Reg_Compliance_Remediation
        Description = $Global:RunAsPPL_LSA_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:RunAsPPL_LSA_Check = $Global:Reg_Compliance
    # End Registry check RunAsPPL in LSA.

    # Start Registry check if Restrict Remote SAM enumeration.
    $Global:RestrictSAM_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $Global:RestrictSAM_Reg_STRING = "RestrictRemoteSam"
    $Global:RestrictSAM_Reg_STRING_Value = "O:BAG:BAD:(A;;RC;;;BA)"
    $Global:RestrictSAM_RegType = "String"
    $Global:RestrictSAM_Reg_Compliance_Remediation = $Remediation
    if (!($Global:RestrictSAM_Reg_Compliance_Remediation)) {
        $Global:RestrictSAM_Reg_Compliance_Remediation = $false
    }
    $Global:RestrictSAM_Name = "Restrict Remote SAM enumeration"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:RestrictSAM_Reg
        RegName     = $Global:RestrictSAM_Reg_STRING
        RegType     = $Global:RestrictSAM_RegType
        RegValue    = $Global:RestrictSAM_Reg_STRING_Value
        Remediation = $Global:RestrictSAM_Reg_Compliance_Remediation
        Description = $Global:RestrictSAM_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:RestrictSAM_Check = $Global:Reg_Compliance
    # End Registry check if Restrict Remote SAM enumeration.

    # Start Registry check if SMBv1 is disabled.
    $Global:SMB1_Reg = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    $Global:SMB1_Reg_DWORD = "SMB1"
    $Global:SMB1_Reg_DWORD_Value = "0"
    $Global:SMB1_RegType = "Dword"
    $Global:SMB1_Reg_Compliance_Remediation = $Remediation
    if (!($Global:SMB1_Reg_Compliance_Remediation)) {
        $Global:SMB1_Reg_Compliance_Remediation = $false
    }
    $Global:SMB1_Name = "SMB1v1"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:SMB1_Reg
        RegName     = $Global:SMB1_Reg_DWORD
        RegType     = $Global:SMB1_RegType
        RegValue    = $Global:SMB1_Reg_DWORD_Value
        Remediation = $Global:SMB1_Reg_Compliance_Remediation
        Description = $Global:SMB1_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:SMB1_Check = $Global:Reg_Compliance
    # End Registry check if SMBv1 is disabled.

    # Start Registry check if RDP is secured.
    $Global:RDP_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    $Global:RDP_Reg_DWORD = "UserAuthentication"
    $Global:RDP_Reg_DWORD_Value = "1"
    $Global:RDP_RegType = "Dword"
    $Global:RDP_Reg_Compliance_Remediation = $Remediation
    if (!($Global:RDP_Reg_Compliance_Remediation)) {
        $Global:RDP_Reg_Compliance_Remediation = $false
    }
    $Global:RDP_Name = "Secure RDP"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:RDP_Reg
        RegName     = $Global:RDP_Reg_DWORD
        RegType     = $Global:RDP_RegType
        RegValue    = $Global:RDP_Reg_DWORD_Value
        Remediation = $Global:RDP_Reg_Compliance_Remediation
        Description = $Global:RDP_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:RDP_Check = $Global:Reg_Compliance
    # End Registry check if RDP is secured.

    # Start Registry check if Powershell logging is active.
    $Global:Reg_PS_Parent = "HKLM:\Software\Policies\Microsoft\Windows"
    $Global:Reg_PS = "Powershell"
    $Global:Reg_PS_FullPath = "$Global:Reg_PS_Parent\$Global:Reg_PS"
    $Global:Reg_PS_ScriptBlockLogging = "ScriptBlockLogging"
    $Global:Reg_PS_ModuleLogging = "ModuleLogging"
    $Global:Reg_PS_ModuleNames = "ModuleNames"
    $Global:Reg_PS_DWORD_EnableScriptBlockLogging = "EnableScriptBlockLogging"

    $Global:Reg_PS_FullPath_ScriptBlockLogging = "$Global:Reg_PS_FullPath\$Global:Reg_PS_ScriptBlockLogging"
    $Global:Reg_PS_FullPath_ModuleLogging = "$Global:Reg_PS_FullPath\$Global:Reg_PS_ModuleLogging"

    $Global:Reg_PS_FullPath_ModuleNames = "$Global:Reg_PS_FullPath\$Global:Reg_PS_ModuleLogging\$Global:Reg_PS_ModuleNames"
    $Global:Reg_PS_String_ModuleNames_Value = "*"
    $Global:Reg_PS_DWORD_EnableScriptBlockLogging_Value = "1"

    if (($Global:Reg_PS_Check1 = Test-Path $Global:Reg_PS_FullPath) -eq $true) {
        Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging Key value for [$Global:Reg_PS_FullPath] is compliant!"
    }

    else {
        Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging Key value for [$Global:Reg_PS_FullPath] does not exists, is NOT compliant!"

        if ($Remediation -eq $true -and $Global:Reg_PS_Check1 -eq $false) {
            try {
                New-Item -Path $Global:Reg_PS_Parent -Name $Global:Reg_PS
                New-Item -Path $Global:Reg_PS_FullPath -Name $Global:Reg_PS_ScriptBlockLogging
                New-Item -Path $Global:Reg_PS_FullPath -Name $Global:Reg_PS_ModuleLogging
                New-Item -Path $Global:Reg_PS_FullPath_ModuleLogging -Name $Global:Reg_PS_ModuleNames

                Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging Remediation is active, creating the values [$Global:Reg_PS,$Global:Reg_PS_ScriptBlockLogging, $Global:Reg_PS_ModuleLogging and $Global:Reg_PS_ModuleNames]. Rerun the script to rescan."
            }

            catch {
                Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging Failed to remediate the registry entry for: [$Global:Reg_PS,$Global:Reg_PS_ScriptBlockLogging, $Global:Reg_PS_ModuleLogging and $Global:Reg_PS_ModuleNames]." -Throw
            }

        }
    }

    if ((($Global:Reg_PS_Check2 = Test-RegistryValue $Global:Reg_PS_FullPath_ScriptBlockLogging -Value $Global:Reg_PS_DWORD_EnableScriptBlockLogging) -eq $true -and `
            ($Global:Property_Value -eq $Global:Reg_PS_DWORD_EnableScriptBlockLogging_Value))) {
        Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging value for [$Global:Reg_PS_FullPath_ScriptBlockLogging] is compliant!"
    }

    else {
        Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging value [$Global:Reg_PS_FullPath_ScriptBlockLogging] is NOT compliant!"

        if ($Remediation -eq $true) {

            try {
                New-ItemProperty -Path $Global:Reg_PS_FullPath_ScriptBlockLogging -Name $Global:Reg_PS_DWORD_EnableScriptBlockLogging -Type DWORD -Value $Global:Reg_PS_DWORD_EnableScriptBlockLogging_Value -Force
                New-ItemProperty -Path $Global:Reg_PS_FullPath_ModuleNames -Name $Global:Reg_PS_String_ModuleNames_Value -Type STRING -Value $Global:Reg_PS_String_ModuleNames_Value -Force
                Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging Remediation is active, creating the value [$Global:Reg_PS_FullPath_ScriptBlockLogging]. Rerun the script to rescan."
            }

            catch {
                Write-CSVLog -Type $Global:Reg_Text -Output "PowerShell Logging Failed to remediate the registry entry for: [$Global:Reg_PS_FullPath_ScriptBlockLogging]." -Throw
            }

        }
    }
    # End Registry check if Powershell logging is active.

    # Start Registry check if Disable Session enumeration.
    $Global:Disable_Ses_enum = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity"
    $Global:Disable_Ses_enum_Binary_SrvsvcSessionInfo = "SrvsvcSessionInfo"
    $Global:Disable_Ses_enum_Binary_SrvsvcSessionInfo_Value = '0x01,0x00,0x04,0x80,0x14,0x00,0x00,0x00,0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x2c,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00,0x02,0x00,0x8c,0x00,0x06,0x00,0x00,0x00,0x00,0x00,0x14,0x00,0x01,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x03,0x00,0x00,0x00,0x00,0x00,0x14,0x00,0x01,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x04,0x00,0x00,0x00,0x00,0x00,0x14,0x00,0x01,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x06,0x00,0x00,0x00,0x00,0x00,0x18,0x00,0x13,0x00,0x0f,0x00,0x01,0x02,0x00,0x00,0x00,0x00,0x00,0x05,0x20,0x00,0x00,0x00,0x20,0x02,0x00,0x00,0x00,0x00,0x18,0x00,0x13,0x00,0x0f,0x00,0x01,0x02,0x00,0x00,0x00,0x00,0x00,0x05,0x20,0x00,0x00,0x00,0x23,0x02,0x00,0x00,0x00,0x00,0x18,0x00,0x13,0x00,0x0f,0x00,0x01,0x02,0x00,0x00,0x00,0x00,0x00,0x05,0x20,0x00,0x00,0x00,0x25,0x02,0x00,0x00'
    $Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath = "$Global:Disable_Ses_enum\$Global:Disable_Ses_enum_Binary_SrvsvcSessionInfo"

    try {
        $Global:Test_RegValue_Binary_Ses_enum = Test-RegistryValue_Binary -RegPath $Global:Disable_Ses_enum -AttrName $Global:Disable_Ses_enum_Binary_SrvsvcSessionInfo -Value $Global:Disable_Ses_enum_Binary_SrvsvcSessionInfo_Value
        Write-CSVLog -Type $Global:Reg_Text -Output "Successfully scanned [Disable Session enumeration] value for [$Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath] with function [Test-RegistryValue_Binary]."
    }

    catch {
        Write-CSVLog -Type $Global:Reg_Text -Output "Failed to scan [Disable Session enumeration] value for [$Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath] with function [Test-RegistryValue_Binary]." -Throw
    }

    if ($Global:Test_RegValue_Binary_Ses_enum -eq $false) {
        Write-CSVLog -Type $Global:Reg_Text -Output "[Disable Session enumeration] value for [$Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath] is NOT compliant!"

        if ($Remediation -eq $true) {
            #Remediation script
            $Global:hex = $Global:Disable_Ses_enum_Binary_SrvsvcSessionInfo_Value.Split(',')

            try {
                New-ItemProperty -Path $Global:Disable_Ses_enum -Name $Global:Disable_Ses_enum_Binary_SrvsvcSessionInfo -PropertyType Binary -Value ([byte[]]$Global:hex) -Force
                Write-CSVLog -Type $Global:Reg_Text -Output "Remediation is active, creating the value [$Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath]. Rerun the script to rescan."
            }

            catch {
                Write-CSVLog -Type $Global:Reg_Text -Output "Failed to remediate the registry entry for: [$Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath]." -Throw
            }
        }
    }

    elseif ($Global:Test_RegValue_Binary_Ses_enum -eq $true) {
        Write-CSVLog -Type $Global:Reg_Text -Output "[Disable Session enumeration] value for [$Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath] is compliant!"
    }

    else {
        Write-CSVLog -Type $Global:Reg_Text -Output "[Disable Session enumeration] value for [$Global:Disable_Ses_enum_SrvsvcSessionInfo_FullPath] is NULL - NOT compliant!"
    }
    # End Registry check if Disable Session enumeration.

    # Start Registry check if Multicast Name Resolution is turned off.
    $Global:Disable_DNS_Client_EnablemultiCast0_Reg = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
    $Global:Disable_DNS_Client_EnablemultiCast0_Reg_DWORD = "EnableMulticast"
    $Global:Disable_DNS_Client_EnablemultiCast0_Reg_DWORD_Value = "0"
    $Global:Disable_DNS_Client_EnablemultiCast0_RegType = "Dword"
    $Global:Disable_DNS_Client_EnablemultiCast0_Reg_Compliance_Remediation = $Remediation
    if (!($Global:Disable_DNS_Client_EnablemultiCast0_Reg_Compliance_Remediation)) {
        $Global:Disable_DNS_Client_EnablemultiCast0_Reg_Compliance_Remediation = $false
    }
    $Global:Disable_DNS_Client_EnablemultiCast0_Name = "Turn off Multicast Name Resolution - Group Policy Setting"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:Disable_DNS_Client_EnablemultiCast0_Reg
        RegName     = $Global:Disable_DNS_Client_EnablemultiCast0_Reg_DWORD
        RegType     = $Global:Disable_DNS_Client_EnablemultiCast0_RegType
        RegValue    = $Global:Disable_DNS_Client_EnablemultiCast0_Reg_DWORD_Value
        Remediation = $Global:Disable_DNS_Client_EnablemultiCast0_Reg_Compliance_Remediation
        Description = $Global:Disable_DNS_Client_EnablemultiCast0_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:Disable_DNS_Client_EnablemultiCast0_Check = $Global:Reg_Compliance
    # End Registry check if Multicast Name Resolution is turned off.

    # Start Registry check if LLMNS is disabled, Same as above but non group policy.
    $Global:Disable_LLMNS_Name = "Turn off Multicast Name Resolution - NON Group Policy Setting"

    if ($Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $false) {
        $Global:Disable_LLMNS_Reg = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
        $Global:Disable_LLMNS_Reg_DWORD = "EnableMulticast"
        $Global:Disable_LLMNS_Reg_DWORD_Value = "0"
        $Global:Disable_LLMNS_RegType = "Dword"
        $Global:Disable_LLMNS_Reg_Compliance_Remediation = $Remediation
        if (!($Global:Disable_LLMNS_Reg_Compliance_Remediation)) {
            $Global:Disable_LLMNS_Reg_Compliance_Remediation = $false
        }
        $Global:Disable_LLMNS_Name = "Turn off Multicast Name Resolution - NON Group Policy Setting"

        $Reg_Compliance_Splatter = @{
            RegPath     = $Global:Disable_LLMNS_Reg
            RegName     = $Global:Disable_LLMNS_Reg_DWORD
            RegType     = $Global:Disable_LLMNS_RegType
            RegValue    = $Global:Disable_LLMNS_Reg_DWORD_Value
            Remediation = $Global:Disable_LLMNS_Reg_Compliance_Remediation
            Description = $Global:Disable_LLMNS_Name
        }

        Reg_Compliance @Reg_Compliance_Splatter
        $Global:Disable_LLMNS_Check = $Global:Reg_Compliance
    }

    else {
        Write-CSVLog -Type $Global:Reg_Text -Output "$Global:Disable_DNS_Client_EnablemultiCast0_Name is not set."
    }
    # End Registry check if LLMNS is disabled.

    # Start Registry check if SSL2 in IIS is inactivated.
    $Global:InactiveSSL2_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"
    $Global:InactiveSSL2_Reg_DWORD = "Enabled"
    $Global:InactiveSSL2_Reg_DWORD_Value = "0"
    $Global:InactiveSSL2_RegType = "Dword"
    $Global:InactiveSSL2_Reg_Compliance_Remediation = $Remediation
    if (!($Global:InactiveSSL2_Reg_Compliance_Remediation)) {
        $Global:InactiveSSL2_Reg_Compliance_Remediation = $false
    }
    $Global:InactiveSSL2_Name = "Inactive SSL2"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:InactiveSSL2_Reg
        RegName     = $Global:InactiveSSL2_Reg_DWORD
        RegType     = $Global:InactiveSSL2_RegType
        RegValue    = $Global:InactiveSSL2_Reg_DWORD_Value
        Remediation = $Global:InactiveSSL2_Reg_Compliance_Remediation
        Description = $Global:InactiveSSL2_Name
    }

    Reg_Compliance @Reg_Compliance_Splatter
    $Global:InactiveSSL2_Reg_Check = $Global:Reg_Compliance
    # End Registry check if SSL2 in IIS is inactivated.

    # Start Registry check if SSL3 in IIS is inactivated.
    $Global:InactiveSSL3_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
    $Global:InactiveSSL3_Reg_DWORD = "Enabled"
    $Global:InactiveSSL3_Reg_DWORD_Value = "0"
    $Global:InactiveSSL3_RegType = "Dword"
    $Global:InactiveSSL3_Reg_Compliance_Remediation = $Remediation
    if (!($Global:InactiveSSL3_Reg_Compliance_Remediation)) {
        $Global:InactiveSSL3_Reg_Compliance_Remediation = $false
    }
    $Global:InactiveSSL3_Name = "Inactive SSL3"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:InactiveSSL3_Reg
        RegName     = $Global:InactiveSSL3_Reg_DWORD
        RegType     = $Global:InactiveSSL3_RegType
        RegValue    = $Global:InactiveSSL3_Reg_DWORD_Value
        Remediation = $Global:InactiveSSL3_Reg_Compliance_Remediation
        Description = $Global:InactiveSSL3_Name
    }
    Reg_Compliance @Reg_Compliance_Splatter
    $Global:InactiveSSL3_Reg_Check = $Global:Reg_Compliance
    # End Registry check if SSL3 in IIS is inactivated.

    # Start Registry check if allowing Meltdown Patches is ok.
    $Global:Allow_Meltdown_Reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\QualityCompat"
    $Global:Allow_Meltdown_Reg_DWORD = "cadca5fe-87d3-4b96-b7fb-a231484277cc"
    $Global:Allow_Meltdown_Reg_DWORD_Value = "0"
    $Global:Allow_Meltdown_RegType = "Dword"
    $Global:Allow_Meltdown_Reg_Compliance_Remediation = $Remediation
    if (!($Global:Allow_Meltdown_Reg_Compliance_Remediation)) {
        $Global:Allow_Meltdown_Reg_Compliance_Remediation = $false
    }
    $Global:Allow_Meltdown_Name = "Allow Meltdown"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:Allow_Meltdown_Reg
        RegName     = $Global:Allow_Meltdown_Reg_DWORD
        RegType     = $Global:Allow_Meltdown_RegType
        RegValue    = $Global:Allow_Meltdown_Reg_DWORD_Value
        Remediation = $Global:Allow_Meltdown_Reg_Compliance_Remediation
        Description = $Global:Allow_Meltdown_Name
    }
    Reg_Compliance @Reg_Compliance_Splatter
    $Global:Allow_Meltdown_Check = $Global:Reg_Compliance
    # End Registry check if allowing Meltdown Patches is ok.

    # Start Registry check if enabling Meltdown Patches FeatureSettingsOverride is ok.
    $Global:Meltdown_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    $Global:Meltdown_Reg_DWORD = "FeatureSettingsOverride"
    $Global:Meltdown_Reg_DWORD_Value = "72"
    $Global:Meltdown_RegType = "Dword"
    $Global:Meltdown_Reg_Compliance_Remediation = $Remediation
    if (!($Global:Meltdown_Reg_Compliance_Remediation)) {
        $Global:Meltdown_Reg_Compliance_Remediation = $false
    }
    $Global:Meltdown_Name = "Allow Meltdown"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:Meltdown_Reg
        RegName     = $Global:Meltdown_Reg_DWORD
        RegType     = $Global:Meltdown_RegType
        RegValue    = $Global:Meltdown_Reg_DWORD_Value
        Remediation = $Global:Meltdown_Reg_Compliance_Remediation
        Description = $Global:Meltdown_Name
    }
    Reg_Compliance @Reg_Compliance_Splatter
    $Global:Meltdown_FeatureSettingsOverride_Check = $Global:Reg_Compliance
    # End Registry check if allowing Meltdown Patches is ok.

    # Start Registry check if enabling Meltdown Patches FeatureSettingsOverrideMask is ok.
    $Global:Meltdown_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    $Global:Meltdown_Reg_DWORD = "FeatureSettingsOverrideMask"
    $Global:Meltdown_Reg_DWORD_Value = "3"
    $Global:Meltdown_RegType = "Dword"
    $Global:Meltdown_Reg_Compliance_Remediation = $Remediation
    if (!($Global:Meltdown_Reg_Compliance_Remediation)) {
        $Global:Meltdown_Reg_Compliance_Remediation = $false
    }
    $Global:Meltdown_Name = "Meltdown FeatureSettingsOverrideMask"

    $Reg_Compliance_Splatter = @{
        RegPath     = $Global:Meltdown_Reg
        RegName     = $Global:Meltdown_Reg_DWORD
        RegType     = $Global:Meltdown_RegType
        RegValue    = $Global:Meltdown_Reg_DWORD_Value
        Remediation = $Global:Meltdown_Reg_Compliance_Remediation
        Description = $Global:Meltdown_Name
    }
    Reg_Compliance @Reg_Compliance_Splatter

    $Global:Meltdown_FeatureSettingsOverrideMask_Check = $Global:Reg_Compliance
    # End Registry check if enabling Meltdown Patches FeatureSettingsOverrideMask is ok.

    # Start Registry check if  WDigest is disabled on 2008 R2.
    if ($Global:OS_Name -match "2008 R2") {
        $Global:WDigest_Reg = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest"
        $Global:WDigest_Reg_DWORD = "UseLogonCredential"
        $Global:WDigest_Reg_DWORD_Value = "0"
        $Global:WDigest_RegType = "Dword"
        $Global:WDigest_Reg_Compliance_Remediation = $Remediation
        if (!($Global:WDigest_Reg_Compliance_Remediation)) {
            $Global:WDigest_Reg_Compliance_Remediation = $false
        }
        $Global:WDigest_Name = "WDigest"

        $Reg_Compliance_Splatter = @{
            RegPath     = $Global:WDigest_Reg
            RegName     = $Global:WDigest_Reg_DWORD
            RegType     = $Global:WDigest_RegType
            RegValue    = $Global:WDigest_Reg_DWORD_Value
            Remediation = $Global:WDigest_Reg_Compliance_Remediation
            Description = $Global:WDigest_Name
        }
        Reg_Compliance @Reg_Compliance_Splatter
        $Global:WDigest_Check = $Global:Reg_Compliance

    }
    # End Registry check if  WDigest is disabled on 2008 R2.
    #################### End Registry checks. ####################

    # Start Registry for WSUS DS.
    if ($Global:DS_Check -eq $true) {
        $Global:WSUS_Reg_DS = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        $Global:WSUS_Reg_DS_DWORD_WUServer = "WUServer"
        $Global:WSUS_Reg_DS_DWORD_WUServer_Value = "http://seemm1dsmgmt01.world.fluidtechnology.net:8530"

        if ((Test-RegistryValue $Global:WSUS_Reg_DS -Value $Global:WSUS_Reg_DS_DWORD_WUServer) -eq $true -and ($Global:Property_Value -eq $Global:WSUS_Reg_DS_DWORD_WUServer_Value) ) {
            Write-CSVLog -Type $Global:Reg_Text -Output "value for [$Global:WSUS_Reg_DS] is compliant!"
        }
        elseif ((Test-RegistryValue $Global:WSUS_Reg_DS -Value $Global:WSUS_Reg_DS_DWORD_WUServer) -eq $true -and -not ($Global:Property_Value -eq $Global:WSUS_Reg_DS_DWORD_WUServer_Value)) {
            Write-CSVLog -Type $Global:Reg_Text -Output "value for [$Global:WSUS_Reg_DS] is NOT compliant! [$Global:WSUS_Reg_DS_DWORD_WUServer = $Global:Property_Value]"
        }
    }
    # End Registry for WSUS DS.

    # End Registry checks.

    # Start VMware Tools checks.
    if ($Global:VM.IsPresent -eq $true) {
        $VMware_Tools = "VMware Tools"
        $Global:VMware_Tools_Install_Check = Get-Software $Global:Server | Where-Object { $_.DisplayName -eq $VMware_Tools }

        if ($Global:VMware_Tools_Install_Check) {
            Write-CSVLog -Type $Global:VM_Text -Output "VMware Tools is installed. Is Compliant."
            $Global:VMware_Tools_Config_Check = $true
        }
        else {
            Write-CSVLog -Type $Global:VM_Text -Output "VMware Tools is NOT installed. Is NOT Compliant."
            $Global:VMware_Tools_Config_Check = $false
        }
    }
    else {
        Write-CSVLog -Type $Global:VM_Text -Output "Not a VM, skipping VMware Tools check."
    }
    # End VMware Tools checks.

    # Start Physical specific checks.
    if (!($Global:VM)) {
        $Global:Control_M_Install_Check = Get-Software $Global:Server | Where-Object { $_.DisplayName -like $Control_M_Application }

        if ($Global:Control_M_Install_Check -and (Get-Service $Control_M_Service -ErrorAction SilentlyContinue).Status -eq "Running") {
            Write-CSVLog -Type $Global:Physical_Text -Output "$Control_M_Service is installed and the service is running. Is Compliant."
        }

        else {
            Write-CSVLog -Type $Global:Physical_Text -Output "$Control_M_Service has some issues or is not installed. Is NOT Compliant."
        }
    }

    # Start VM no DS.
    if (
        $Global:VM.IsPresent -eq $true -and $Global:OS_Name -match "2016|2019|2022|2025" -and 
        ($Global:S1_Agent_Install_Check -or $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running -and $Global:Defender_TamperingProtection) -and
        $Global:RunAsPPL_LSA_Check -eq $true -and $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:VMware_Tools_Config_Check -and $Global:IBM_Bigfix_Service -and $Global:DS_Check -eq $false -and
        $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and
        $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and
        $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and
        $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "2016|2019|2022|2025 Server is Compliant, all parts are OK."
    }
    elseif (
        $Global:VM.IsPresent -eq $true -and $Global:OS_Name -match "2012" -and
        ($Global:S1_Agent_Install_Check -or $Global:DefenderInstalled -and $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running) -and
        $Global:AzureAgentInstalled -and $Global:RunAsPPL_LSA_Check -eq $true -and $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:VMware_Tools_Config_Check -and $Global:IBM_Bigfix_Service -and $Global:DS_Check -eq $false -and
        $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and
        $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and
        $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and
        $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Server 2012 is Compliant, all parts are OK."
    }
    # VM no DS for 2008 R2.
    elseif (
        $Global:VM.IsPresent -eq $true -and $Global:OS_Name -match "2008 R2" -and $Global:McAfee_Agent_Install_Check -or $Global:S1_Agent_Install_Check -or
        $Global:McAfee_McShield_Install_Check -or $Global:McAfee_ENS_Install_Check -or $Global:McAfee_MUP_Install_Check -and
        $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:DS_Check -eq $false -and $Global:VMware_Tools_Config_Check -and $Global:IBM_Bigfix_Service -and $Global:wmicheck -and
        $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and
        $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and
        $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and
        $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:WDigest_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and
        $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and $Global:TLS1_2_Enabled_Check_Client -eq $true -and
        $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Server 2008 R2 is Compliant, all parts are OK."

    }
    elseif ($Global:VM.IsPresent -eq $true -and $Global:DS_Check -eq $false) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Server is NOT Compliant, some parts are missing."
    }
    # End VM no DS.

    # Start VM DS.
    if (
        $Global:VM.IsPresent -eq $true -and $Global:OS_Name -match "2016|2019|2022|2025" -and
        ($Global:S1_Agent_Install_Check -or $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running -and $Global:Defender_TamperingProtection) -and
        $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:VMware_Tools_Config_Check -and $Global:IBM_Bigfix_Service -and $Global:DS_Check -eq $true -and $Global:DES_3DES_Check -eq $true -and
        $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and $Global:RestrictAnonymous_Check -eq $true -and
        $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and $Global:Reg_PS_Check2 -eq $true -and $Global:RunAsPPL_LSA_Check -eq $true -and
        $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:Allow_Meltdown_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and
        $Global:TLS1_2_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and $Global:TLS1_2_Enabled_Check_Client -eq $true -and
        $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Server is Compliant, all parts are OK."
    }
    elseif (
        $Global:VM.IsPresent -eq $true -and $Global:OS_Name -match "2012" -and
        ($Global:S1_Agent_Install_Check -or $Global:DefenderInstalled -and $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running) -and $Global:AzureAgentInstalled -and
        $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and $Global:RunAsPPL_LSA_Check -eq $true -and
        $Global:DS_Check -eq $true -and $Global:VMware_Tools_Config_Check -and
        $Global:IBM_Bigfix_Service -and $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and
        $Global:InactivateAutorunDevice_Check -eq $true -and $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and
        $Global:Reg_PS_Check1 -eq $true -and $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and
        $Global:TLS1_1_DisabledByDefault_Check -eq $true -and $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and
        $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and $Global:Allow_Meltdown_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_0_DisabledByDefault_Check -eq $true -and
        $Global:WDigest_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and
        $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and $Global:TLS1_2_Enabled_Check_Client -eq $true -and $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Server 2008 is Compliant, all parts are OK."
    }

    # VM DS for 2008 R2.
    elseif (
        $Global:VM.IsPresent -eq $true -and $Global:OS_Name -match "2008 R2" -and $Global:S1_Agent_Install_Check -and 
        $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:DS_Check -eq $true -and $Global:VMware_Tools_Config_Check -and
        $Global:IBM_Bigfix_Service -and $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and
        $Global:InactivateAutorunDevice_Check -eq $true -and $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and
        $Global:Reg_PS_Check1 -eq $true -and $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and
        $Global:TLS1_1_DisabledByDefault_Check -eq $true -and $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and
        $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and $Global:Allow_Meltdown_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_0_DisabledByDefault_Check -eq $true -and
        $Global:WDigest_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and
        $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and $Global:TLS1_2_Enabled_Check_Client -eq $true -and $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Server 2008 is Compliant, all parts are OK."
    }

    elseif ($Global:VM.IsPresent -eq $true -and $Global:DS_Check -eq $true) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Server is NOT Compliant, some parts are missing."
    }
    # End VM DS.

    # Start Physical server no DS.
    if (
        $Global:VM.IsPresent -eq $false -and $Global:OS_Name -match "2016|2019|2022|2025" -and 
        ($Global:S1_Agent_Install_Check -and $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running) -and
        $Global:RunAsPPL_LSA_Check -and $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:Control_M_Install_Check -eq $true -eq $true -and
        $Global:IBM_Bigfix_Service -and $Global:DS_Check -eq $false -and
        $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and
        $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and
        $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and
        $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and
        $Global:TLS1_2_Enabled_Check_Client -eq $true -and $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Physical Server is Compliant, all parts are OK."
    }
    # Physical server no DS for 2008 R2.
    elseif (
        $Global:VM.IsPresent -eq $false -and $Global:OS_Name -match "2008 R2" -and
        ($Global:S1_Agent_Install_Check -and $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running) -and
        $Global:RunAsPPL_LSA_Check -and $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:Control_M_Install_Check -eq $true -and
        $Global:DS_Check -eq $false -and
        $Global:IBM_Bigfix_Service -and $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and
        $Global:InactivateAutorunDevice_Check -eq $true -and $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and
        $Global:Reg_PS_Check1 -eq $true -and $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and
        $Global:TLS1_1_DisabledByDefault_Check -eq $true -and $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and
        $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and
        $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:WDigest_Check -eq $true -and
        $Global:TLS1_2_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and $Global:TLS1_2_Enabled_Check_Client -eq $true -and
        $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Physical Server 2008 is Compliant, all parts are OK."
    }

    elseif ($Global:VM.IsPresent -eq $false) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Physical Server is NOT Compliant, some parts are missing."
    }
    # End Physical server no DS.

    # Start Physical server DS.
    if (
        $Global:VM.IsPresent -eq $false -and $Global:OS_Name -match "2016|2019|2022|2025" -and 
        ($Global:S1_Agent_Install_Check -or $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running) -and
        $Global:RunAsPPL_LSA_Check -and $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:Control_M_Install_Check -eq $true -and
        $Global:IBM_Bigfix_Service -and $Global:DS_Check -eq $true -and
        $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and
        $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and
        $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and
        $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and
        $Global:TLS1_2_Enabled_Check_Client -eq $true -and $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Physical Server is Compliant, all parts are OK."
    }
    elseif (
        $Global:VM.IsPresent -eq $false -and $Global:OS_Name -match "2012" -and
        ($Global:S1_Agent_Install_Check -or $Global:DefenderInstalled -and $Global:MsSense_Process_Running -and $Global:MsMpEng_Process_Running) -and $Global:AzureAgentInstalled -and
        $Global:RunAsPPL_LSA_Check -and $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:Control_M_Install_Check -eq $true -and
        $Global:IBM_Bigfix_Service -and $Global:DS_Check -eq $true -and
        $Global:DES_3DES_Check -eq $true -and $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and
        $Global:RestrictAnonymous_Check -eq $true -and $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and
        $Global:CachedLogons_Check -eq $true -and $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and $Global:RestrictSAM_Check -eq $true -and
        $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and $Global:TLS1_0_Enabled_Check -eq $true -and
        $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and
        $Global:TLS1_2_Enabled_Check_Client -eq $true -and $Global:SMB_Signed_Enabled_Check -eq $true -and $Global:WDigest_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Physical Server 2012 is Compliant, all parts are OK."
    }

    elseif (
        $Global:VM.IsPresent -eq $false -and $Global:OS_Name -match "2008 R2" -and
        $Global:S1_Agent_Install_Check -and $Global:RunAsPPL_LSA_Check -eq $true -and $Global:Disable_LLMNS_Check -or $Global:Disable_DNS_Client_EnablemultiCast0_Check -eq $true -and
        $Global:Control_M_Install_Check -eq $true -and $Global:DS_Check -eq $true -and
        $Global:VMware_Tools_Config_Check -and $Global:IBM_Bigfix_Service -and $Global:DES_3DES_Check -eq $true -and
        $Global:RC4_Check -eq $true -and $Global:InactivateAutorunDevice_Check -eq $true -and $Global:RestrictAnonymous_Check -eq $true -and
        $Global:SMB1_Check -eq $true -and $Global:Reg_PS_Check1 -eq $true -and $Global:CachedLogons_Check -eq $true -and
        $Global:TLS1_1_Enabled_Check -eq $true -and $Global:TLS1_1_DisabledByDefault_Check -eq $true -and
        $Global:Reg_PS_Check2 -eq $true -and $Global:InactiveSSL2_Reg_Check -eq $true -and $Global:InactiveSSL3_Reg_Check -eq $true -and
        $Global:RestrictSAM_Check -eq $true -and $Global:Allow_Meltdown_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverride_Check -eq $true -and
        $Global:TLS1_0_Enabled_Check -eq $true -and $Global:Meltdown_FeatureSettingsOverrideMask_Check -eq $true -and
        $Global:TLS1_0_DisabledByDefault_Check -eq $true -and $Global:WDigest_Check -eq $true -and $Global:TLS1_2_Enabled_Check -eq $true -and
        $Global:TLS1_2_DisabledByDefault_Check -eq $true -and $Global:TLS1_2_DisabledByDefault_Check_Client -eq $true -and $Global:TLS1_2_Enabled_Check_Client -eq $true -and
        $Global:SMB_Signed_Enabled_Check -eq $true
    ) {
        Write-CSVLog -Type $Global:Summary_Text -Output "Physical Server 2008 R2 is Compliant, all parts are OK."
        # End Physical server DS.
    }

} # End of function Compliant_Check.

if (($Get_MachineType = Get-MachineType).Model -match "$MachineType_VM|$MachineType_Azure") {
    Write-CSVLog -Type $Global:Get_MachineType_Text -Output "Virtual server found, running Compliant_Check customized for that."
    try {
        Write-CSVLog -Type $Global:Invoke_Text -Output "Trying to invoking Compliant_Check for VM."
        Compliant_Check -VM
    }
    catch {
        Write-CSVLog -Type $Global:Invoke_Text -Output "Failed to invoke Compliant_Check for VM. At Line:[$($_.InvocationInfo.ScriptLineNumber)]." -Throw
    }
}

elseif (($Get_MachineType = Get-MachineType).Type -eq $MachineType_Physical) {
    function Get-UnknownDevices {
        <#
        .Synopsis
           When building a new system image for MDT or SWPM, it is common to need to lay down a new OS image and troubleshoot missing drivers.  This tool simplifies detemining what device is really meant by 'Unknown Device' in the Device Manager
        .DESCRIPTION
           Based off of this great post by Johan Arwidmark of Deployment Research, this cmdlet can be used on a new system to help locate the names and IDs of device drivers.  The Cmdlet can be used without parameters, which will return a listing of all the devices with missing drivers.  Or, it can be run on a machine without web acess, using -Export to export a file.  The file should then be copied to a machine with web access where the -Import param can be used to import this file
        .INPUTS
           To determine drivers from a system without internet access, use the -Import switch to specify the path to an import.csv file
           To determine drivers for the local system, no input is needed
        .OUTPUTs
           In regular mode, emits PowerShell objects, containing a VendorID, DeviceId, DevMgrName and LikelyName properties
           In -Export mode, creates a import.csv file which can be copied and uses on a remote machine to resolve drivers (as web access is needed)
        .EXAMPLE
            .\Get-UnknownDevices.ps1

        VendorID DeviceID DevMgrName                                                                LikelyName
        -------- -------- ----------                                                                ----------
        8086     1E2D     Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controller - 1E2D Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controll...
        8086     1E26     Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controller - 1E26 Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controll...
        1B21     1042     ASMedia USB 3.0 eXtensible Host Controller - 0.96 (Microsoft)             Asmedia ASM104x USB 3.0 Host Controller...
        8086     1E31     Intel(R) USB 3.0 eXtensible Host Controller - 1.0 (Microsoft)
        1B21     1042     ASMedia USB 3.0 eXtensible Host Controller - 0.96 (Microsoft)             Asmedia ASM104x USB 3.0 Host Controller...

        In this case, the cmdlet was run without any parameters which returns a list of any missing drivers and the likely source file, according to the PCIDatabase
        .EXAMPLE
           .\Get-UnknownDevices.ps1 -Export C:\temp\DriverExport.csv

            >Export file created at C:\temp\DriverExport.csv, please copy to a machine with web access, and rerun this tool, using the -Import flag
        .EXAMPLE
            .\Get-UnknownDevices.ps1 -Import C:\temp\DriverExport.csv

        VendorID DeviceID DevMgrName                         LikelyName
        -------- -------- ----------                         ----------
        1186     4300     DGE-530T Gigabit Ethernet Adapter. Used on DGE-528T Gigabit adapt...
        .LINK
           Copy and paste any of the links below for more information about this cmdlet
           start http://www.Foxdeploy.com
           start http://deploymentresearch.com/Research/Post/306/Back-to-basics-Finding-Lenovo-drivers-and-certify-hardware-control-freak-style
        #>
        [CmdletBinding()]
        Param([ValidateScript( { Test-Path (Split-Path $path) })]$Export,
            [ValidateScript( { Test-Path $path })]$Import)
        begin {
            $i = 0

            if ($Import) {
                $devices = Import-Csv $import
            }
            else {
                #Query WMI and get all of the devices with missing drivers
                $devices = Get-CimInstance -ClassName Win32_PNPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } | Select-Object Caption, DeviceID
            }

            #For testing, I'm purposefully pulling Ethernet drivers
            #$unknown_Dev = $devices | where Name -like "*ethernet*"

            #For production
            $unknown_Dev = $devices

            if ($Export) {
                $unknown_Dev | Export-Csv $Export
                Write-Host "Export file created at $Export, please copy to a machine with web access, and rerun this tool, using the -Import flag"
                BREAK
            }




            $unknown_Dev | ForEach-Object { $i++ }
            $count = $i

            Write-Verbose "$i unknown devices found on $env:COMPUTERNAME"
            if ($VerbosePreference -eq 'Continue') {
                $unknown_Dev | Format-Table
            }
        }


        process {
            forEach ($device in $unknown_Dev) {
                Write-Debug "to test the current `$device, stop here"

                #Pull out specific values for VendorID and DeviceID, from the objects in $Unknown_dev
                $vendorID = ($device.DeviceID | Select-String -Pattern 'VEN_....' | Select-Object -expand Matches | Select-Object -expand Value) -replace 'VEN_', ''
                $deviceID = ($device.DeviceID | Select-String -Pattern 'DEV_....' | Select-Object -expand Matches | Select-Object -expand Value) -replace 'DEV_', ''

                if ($deviceID.Length -eq 0) {
                    Write-Verbose "found a null device, skipping..."
                    Continue
                }

                Write-Verbose "Searching for devices with Vendor ID of $vendorID and Device ID of $deviceID "

                $url = "http://www.pcidatabase.com/search.php?device_search_str=$deviceID&device_search=Search"
                $res = Invoke-WebRequest $url -UserAgent InternetExplorer
                $matches = ($res.ParsedHtml.getElementsByTagName('p') | Select-Object -expand innerHtml).Split()[1]
                Write-Verbose "Found $matches matches"

                $htmlCells = $res.ParsedHtml.getElementsByTagName('tr') | Select-Object -Skip 4 -Property *html*
                Write-Debug "test `$htmlCells for the right values $htmlCells"

                #
                $matchingDev = ($htmlCells.InnerHtml | Select-String -Pattern $vendorID | Select-Object -expand Line).ToString().Split("`n")
                if ($matchingDev.count -ge 1) {
                    [pscustomobject]@{VendorID = $vendorID; DeviceID = $deviceID; DevMgrName = $device.Name; LikelyName = $matchingDev[1] -replace '<TD>', '' -replace '</TD>', '' }
                }
                else { CONTINUE }

            }
        }
        end { }
    } # End of function Get-UnknownDevices.
    Write-CSVLog -Type $Global:Get_MachineType_Text -Output "Physical server found, running Compliant_Check customized for that."
    Compliant_Check
}

else {
    Write-CSVLog -Type $Global:Get_MachineType_Text -Output "Neither Physical or VM."
}
# Clean up old report file if exists.
if (Test-Path $Global:AD_Reports_Folder_File) {
    Write-CSVLog -Type $Global:AD_Computer_Text -Output "File: [$Global:AD_Reports_Folder_File] exists, trying to remove it."
    try {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "Trying to remove file: [$Global:AD_Reports_Folder_File]."
        Remove-Item -Force $Global:AD_Reports_Folder_File
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "Successfully removed file: [$Global:AD_Reports_Folder_File]."
    }

    catch {
        Write-CSVLog -Type $Global:AD_Computer_Text -Output "Failed to remove file: [$Global:AD_Reports_Folder_File]."
    }
}
else {
    Write-CSVLog -Type $Global:AD_Computer_Text -Output "File: [$Global:AD_Reports_Folder_File] does not exist, no need to remove it."
}