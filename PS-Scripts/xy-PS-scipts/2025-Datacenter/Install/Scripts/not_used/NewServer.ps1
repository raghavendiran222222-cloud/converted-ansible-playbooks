# Set-ExecutionPolicy -Scope Process Unrestricted
<#
.SYNOPSIS
    GUI for joining server to domain.
#>

Param(
    [Parameter(Mandatory = $true)] [string]$ServerName
)
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
    "NewServer.ps1"
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
    $wrapper | Export-Csv -Path $FilePath_Log -NoTypeInformation -Append
} # End of Function Write-CSVLog.
function Test-OnlineFast {
    param
    (
        # make parameter pipeline-aware
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName,

        $TimeoutMillisec = 1000
    )

    # hash table with error code to text translation
    $StatusCode_ReturnValue =
    @{
        0     = 'Success'
        11001 = 'Buffer Too Small'
        11002 = 'Destination Net Unreachable'
        11003 = 'Destination Host Unreachable'
        11004 = 'Destination Protocol Unreachable'
        11005 = 'Destination Port Unreachable'
        11006 = 'No Resources'
        11007 = 'Bad Option'
        11008 = 'Hardware Error'
        11009 = 'Packet Too Big'
        11010 = 'Request Timed Out'
        11011 = 'Bad Request'
        11012 = 'Bad Route'
        11013 = 'TimeToLive Expired Transit'
        11014 = 'TimeToLive Expired Reassembly'
        11015 = 'Parameter Problem'
        11016 = 'Source Quench'
        11017 = 'Option Too Big'
        11018 = 'Bad Destination'
        11032 = 'Negotiating IPSEC'
        11050 = 'General Failure'
    }

    # hash table with calculated property that translates
    # numeric return value into friendly text

    $statusFriendlyText = @{
        # name of column
        Name       = 'Status'
        # code to calculate content of column
        Expression = {
            # take status code and use it as index into
            # the hash table with friendly names
            # make sure the key is of same data type (int)
            $StatusCode_ReturnValue[([int]$_.StatusCode)]
        }
    }

    # calculated property that returns $true when status -eq 0
    $IsOnline = @{
        Name       = 'Online'
        Expression = { $_.StatusCode -eq 0 }
    }

    # do DNS resolution when system responds to ping
    $DNSName = @{
        Name       = 'DNSName'
        Expression = { if ($_.StatusCode -eq 0) {
                if ($_.Address -like '*.*.*.*')
                { [Net.DNS]::GetHostByAddress($_.Address).HostName }
                else
                { [Net.DNS]::GetHostByName($_.Address).HostName }
            }
        }
    }

    # convert list of computers into a WMI query string
    $query = $ComputerName -join "' or Address='"

    Get-CimInstance -ClassName Win32_PingStatus -Filter "(Address='$query') and timeout=$TimeoutMillisec" |
    Select-Object -Property Address, $IsOnline, $DNSName, $statusFriendlyText
}
function Pause2 ($Message = "Press any key to reboot the machine...") {
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

$CSV_LogType = "CSV Import"
$GUI_Select_LogType = "GUI Select."
$DHCP_IsActive_LogType = "DHCP is active."
$GUI_SelectIPCheck_LogType = "GUI select. Static IP Check."
$Duplicate_IPSearch_LogType = "Duplicate search static IP."
$Credentials_LogType = "Credentials."
$JoinServer_LogType = "Function: Add-Computer - Join Server."
$Test_OnlineFast_LogType = "Test-OnlineFast"
$Important_Information_LogType = "Join Server Important Information"
$Install_Altiris_Logtype = "Altiris Installation."
$Install_SCCM_Logtype = "SCCM Installation."
$Install_S1_Logtype = "Sentinel1 Installation."
$Execute_Compliance_Check_Logtype = "Compliance Check Script."
$ExitCode_LogType = "Exitcode"
$Test_Connection_LogType = "Test Connection."
$regex1 = "/(.*)"
$Backslash = '[\\/]'

$GotFocus_Username = 'Example: world\so-gdc-ssvensson'
$Regex_Servername = "^[a-zA-Z0-9\-]{1,15}$"

try {
    Write-CSVLog -Type $CSV_LogType -Output "Trying to import file: [$("$PSScriptRoot\OUs.csv")] using function [Import-Csv]."
    $OUs = Import-Csv -Delimiter ";" "$PSScriptRoot\OUs.csv"
    Write-CSVLog -Type $CSV_LogType -Output "Successfully imported file: [$("$PSScriptRoot\OUs.csv")] using function [Import-Csv]."
}

catch {
    Write-CSVLog -Type $CSV_LogType -Output "Failed to import file: [$("$PSScriptRoot\OUs.csv")] using function [Import-Csv]. Exit script." -Throw
}

$Domains = $OUs.ParentContainer -Replace $regex1, ""
$Domains = $Domains | Select-Object -Unique | Sort-Object

Add-Type -AssemblyName PresentationFramework

# Dynamically create variables.
foreach ($Domain in $Domains) {
    New-Variable -Name "Domain_$Domain" -Value $Domain -Force | Where-Object { $_ -match $Domain } | Sort-Object
}

$JoinedObjects = foreach ($row in $Domains) {
    [pscustomobject]@{
        Domain = $row
        OU     = $Ous.ParentContainer | Where-Object { $_ -match $row }
    }
}

foreach ($JoinedObject in $JoinedObjects) {
    New-Variable -Name "OU_$($JoinedObject.domain)" -Value $JoinedObject.ou  -force | Where-Object { $_ -match $JoinedObject.domain } | Sort-Object
}

# XAML for GUI
$xaml = $null
[xml]$xaml = $null
$xaml2 = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        Title="New Server" Height="691" Width="378.65" HorizontalContentAlignment="Left">
    <Grid Margin="10,10,10,0" RenderTransformOrigin="0.0,0.0" HorizontalAlignment="Stretch" Width="Auto" Height="650" VerticalAlignment="Top">

        <Image Name="image" HorizontalAlignment="Left" Height="46" Margin="10,10,0,0" VerticalAlignment="Top" Width="210" Source="$ScriptDir\300px-Xylem_Logo.svg.png" Grid.ColumnSpan="2"/>
        <TextBox x:Name="TextBox_servername" IsEnabled="False" VerticalAlignment="Top" ScrollViewer.HorizontalScrollBarVisibility="Disabled" ScrollViewer.VerticalScrollBarVisibility="Disabled" TextWrapping="NoWrap" Text="$ServerName" HorizontalScrollBarVisibility="Disabled" Margin="0,88,0,0" Height="25" AcceptsReturn="False" TabIndex="0" />
        <Button x:Name="Button_OK" Content="Ok" Margin="0,606,0,0" VerticalAlignment="Top" Height="20" RenderTransformOrigin="0.522,-1.231"/>
        <TextBlock x:Name="textBlock_Domain" Height="21" Margin="0,118,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="Select Domain:"/>
        <ComboBox x:Name="ComboBox1_Domain" VerticalAlignment="Top" Margin="0,139,0,0" Height="22" TabIndex="1">
            <ComboBoxItem>${Domain_world.fluidtechnology.net}</ComboBoxItem>
            <ComboBoxItem>${Domain_emeadmz.net}</ComboBoxItem>
            <ComboBoxItem>${Domain_emea.sensus.net}</ComboBoxItem>
            <ComboBoxItem>${Domain_lab.sensus.net}</ComboBoxItem>
            <ComboBoxItem>${Domain_na.sensus.net}</ComboBoxItem>
            <ComboBoxItem>${Domain_sensus.net}</ComboBoxItem>
        </ComboBox>
        <TextBlock x:Name="textBlock_Servername" Height="20" Margin="0,62,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="Servername:"/>
        <TextBlock x:Name="textBlock_OU1" Height="21" Margin="0,166,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="Select OU:"/>
        <ComboBox x:Name="ComboBox2OU" VerticalAlignment="Top" Margin="0,186,0,0" Height="22" TabIndex="2"/>
        <TextBox x:Name="textBox_Username" VerticalAlignment="Top" Height="25" Margin="0,235,0,0" AcceptsReturn="False" Text="$GotFocus_Username" TextWrapping="NoWrap" TabIndex="3"/>
        <TextBlock x:Name="textBlock_Username" HorizontalAlignment="Left" Height="21" Margin="12,213,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="278" FontSize="14" FontWeight="Bold" Text="Username:"/>
        <TextBlock x:Name="textBlock_Password" HorizontalAlignment="Left" Height="21" Margin="12,260,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="278" FontSize="14" FontWeight="Bold" Text="Password:"/>
        <PasswordBox x:Name="PasswordBox_Password" VerticalAlignment="Top" Height="25" Margin="0,281,0,0" TabIndex="4"/>
        <CheckBox x:Name="checkbox_dhcp" Content="DHCP" Margin="0,331,0,0" VerticalAlignment="Top" IsChecked="True" TabIndex="5"/>
        <TextBlock x:Name="textBlock_Network" Height="20" Margin="0,311,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="Network Setup"/>
        <TextBox x:Name="textBox_IP" IsEnabled="False" AcceptsReturn="False" TextWrapping="NoWrap" VerticalAlignment="Top" Text="$GotFocus_IP" Height="25" Margin="0,372,0,0" TabIndex="6"/>
        <TextBox x:Name="textBox_gateway" IsEnabled="False" AcceptsReturn="False" TextWrapping="NoWrap" VerticalAlignment="Top" Text="$GotFocus_Gateway" Height="25" Margin="0,474,0,0" TabIndex="8"/>
        <TextBlock x:Name="textBlock_IP" Height="21" Margin="0,351,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="IP:"/>
        <TextBlock x:Name="textBlock_gateway" Height="21" Margin="0,453,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="Gateway:"/>
        <TextBox x:Name="textBox_Subnetmask" IsEnabled="False" AcceptsReturn="False" TextWrapping="NoWrap" VerticalAlignment="Top" Text="$GotFocus_Subnetmask" Height="25" Margin="0,423,0,0" TabIndex="7"/>
        <TextBlock x:Name="textBlock_subnetmask" Height="21" Margin="0,402,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="Subnetmask:"/>
        <TextBox x:Name="textBox_DNS1" IsEnabled="False" AcceptsReturn="False" TextWrapping="NoWrap" VerticalAlignment="Top" Text="$GotFocus_DNS1" Height="25" Margin="0,525,0,0" TabIndex="9"/>
        <TextBlock x:Name="textBlock_DNS1" Height="21" Margin="0,504,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="DNS 1:"/>
        <TextBox x:Name="textBox_DNS2" IsEnabled="False" AcceptsReturn="False" TextWrapping="NoWrap" Text="$GotFocus_DNS2" Margin="0,576,0,0" TabIndex="10" VerticalAlignment="Top" Height="25"/>
        <TextBlock x:Name="textBlock_DNS2" Height="21" Margin="0,555,0,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" Text="DNS 2:"/>
    </Grid>
</Window>
"@
[xml]$xaml = $xaml2 -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
#Load XAML.
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $Window = [Windows.Markup.XamlReader]::Load($reader)
}

catch {
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}
$window.ShowInTaskbar = $true
$window.Visibiliy.Visible
$window.Activate()

#Bind WPF elements to PS variables
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try {
        Set-Variable -Name "$($_.Name)" -Value $Window.FindName($_.Name) -ErrorAction Stop
    }

    catch {
        throw
    }
}

$PasswordBox_Password.Add_GotFocus( {
        $PasswordBox_Password.Clear()
    })

$textBox_Username.Add_GotFocus( {
        $textBox_Username.Clear()
    })

$checkbox_dhcp.Add_Click( {
        if (-not (($checkbox_dhcp.isChecked))) {
            "DHCP is inactive." | Out-Host
            $textBox_IP.IsEnabled = $true
            $textBox_Subnetmask.IsEnabled = $true
            $textBox_gateway.IsEnabled = $true
            $textBox_DNS1.IsEnabled = $true
            $textBox_DNS2.IsEnabled = $true
        }
        if ($checkbox_dhcp.isChecked) {
            $DHCP_IsActive_LogType | Out-Host
            $textBox_IP.IsEnabled = $false
            $textBox_Subnetmask.IsEnabled = $false
            $textBox_gateway.IsEnabled = $false
            $textBox_DNS1.IsEnabled = $false
            $textBox_DNS2.IsEnabled = $false
        }
    })

$Button_OK.Add_Click( {
        if ($checkbox_dhcp.isChecked) {
            try {
                Write-CSVLog -Type $DHCP_IsActive_LogType -Output "Trying to activate DHCP."
                $Script:Get_CIMInstance = Get-CimInstance -classname Win32_NetworkAdapterConfiguration -Filter "ipenabled = 'true'"
                $Script:Get_CIMInstance | Invoke-CimMethod  -MethodName EnableDHCP #-WhatIf #change
                $Script:Get_CIMInstance | Invoke-CimMethod  -MethodName SetDNSServerSearchOrder #-WhatIf #change
                Write-CSVLog -Type $DHCP_IsActive_LogType -Output "Successfully activated DHCP."
            }

            catch {
                Write-CSVLog -Type $DHCP_IsActive_LogType -Output "Failed to activate DHCP. Error: [$_]"
            }
        }

        if ((-not ($checkbox_dhcp.isChecked))) {

            try {
                Write-CSVLog -Type $GUI_SelectIPCheck_LogType -Output "Trying to check the static IP."

                $Script:names = @(
                    $textBox_IP.Text
                    $textBox_Subnetmask.Text
                    $textBox_gateway.Text
                    $textBox_DNS1.Text
                    $textBox_DNS2.Text
                )

                $pattern = "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"
                $Script:IP_Regex_Check = foreach ($name in $Script:names) {
                    New-Object -TypeName PSObject -Property @{ComputerName = $name; Results = ($name -match $pattern) }
                }
                Write-CSVLog -Type $GUI_SelectIPCheck_LogType -Output "Successfully executed regex scan on the static IPs."
            }

            catch {
                Write-CSVLog -Type $GUI_SelectIPCheck_LogType -Output "Failed to check the static IP. Error: [$_]."
            }

            try {
                Write-CSVLog -Type $Duplicate_IPSearch_LogType -Output "Trying to search for duplicates in entered IP list."
                $IP_unique = $Script:IP_Regex_Check.ComputerName | Select-Object -unique
                $Duplicate_IP_Scan = Compare-object -referenceobject $IP_unique -differenceobject $Script:IP_Regex_Check.ComputerName
                Write-CSVLog -Type $Duplicate_IPSearch_LogType -Output "Successfully searched for duplicates in entered IP list."
            }

            catch {
                Write-CSVLog -Type $Duplicate_IPSearch_LogType -Output "Failed to search for duplicates in entered IP list. Error: [$_]."
            }

            if ($Duplicate_IP_Scan) {
                Write-CSVLog -Type $Duplicate_IPSearch_LogType -Output "Input Failed: Found duplicates in the entered IP list. Please enter unique IP entries."
            }

            elseif (-not ($Duplicate_IP_Scan) -and (-not ($Script:IP_Regex_Check | Where-Object { $_ -match $false }))) {
                Write-CSVLog -Type $Duplicate_IPSearch_LogType -Output "Input Success: No duplicates entered in the IP list and the IP seems to be correctly entered."
            }

            elseif (-not ($Duplicate_IP_Scan) -and ($Script:IP_Regex_Check | Where-Object { $_ -match $false })) {
                Write-CSVLog -Type $Duplicate_IPSearch_LogType -Output "Input Failed: No duplicates entered in the IP list but the IP seems to be incorrect entered."
            }

            else {
                Write-CSVLog -Type $GUI_SelectIPCheck_LogType -Output "Input Failed: Please fill in correct network information."
            }

            if ($textBox_IP.Text -eq "" -or $textBox_Subnetmask.Text -eq "" -or $textBox_gateway.Text -eq "" -or $textBox_DNS1.Text -eq "" -or $textBox_DNS2.Text -eq "") {
                Write-CSVLog -Type $Duplicate_IPSearch_LogType -Output "Blank network information is not allowed, all fields is mandatory."
            }
        }

        if (($textBox_IP.Text) -and ($textBox_Subnetmask.Text) -and ($textBox_gateway.Text) -and ($textBox_DNS1.Text) -and ($textBox_DNS2.Text) -and
            (-not ($Script:IP_Regex_Check | Where-Object { $_ -match $false })) -and (-not ($Duplicate_IP_Scan)) -and (-not ($checkbox_dhcp.isChecked)) ) {
            $staticIp = @("$($textBox_IP.Text)")
            $subnetMask = @("$($textBox_Subnetmask.Text)")
            $gateway = @("$($textBox_gateway.Text)")
            $dnsserver = "$($textBox_DNS1.Text)", "$($textBox_DNS2.Text)"
            $mt = @([uint16]1)
            function Set-StaticIP {
                [CmdletBinding()]

                param (
                    [Parameter (Mandatory = $false)]
                    [Switch] $EnableStatic,
                    [Parameter (Mandatory = $false)]
                    [Array] $staticIp,
                    [Parameter (Mandatory = $false)]
                    [Array] $subnetMask,
                    [Parameter (Mandatory = $false)]
                    [Switch] $SetGateways,
                    [Parameter (Mandatory = $false)]
                    [Array] $gateway,
                    [Parameter (Mandatory = $false)]
                    [Switch] $SetDNSServer,
                    [Parameter (Mandatory = $false)]
                    [Array] $dnsserver
                )

                $ErrorActionPreference = "Stop"
                $Methodname_Static = "EnableStatic"
                $Methodname_SetGateways = "SetGateways"
                $Methodname_SetDNSServerSearchOrder = "SetDNSServerSearchOrder"
                $Script:List = @()
                $Set_StaticIP_LogType = "Function: Set-StaticIP"
                try {
                    Write-CSVLog -Type $Set_StaticIP_LogType -Output "Trying to get CIM instance using command: [Get-CimInstance]."
                    $Script:Get_CIMInstance = Get-CimInstance -classname Win32_NetworkAdapterConfiguration -Filter "ipenabled = 'true'"
                    Write-CSVLog -Type $Set_StaticIP_LogType -Output "Successfully set CIM instance using command: [Get-CimInstance]."
                }

                catch {
                    Write-CSVLog -Type $Set_StaticIP_LogType -Output "Failed to get CIM instance using command: [Get-CimInstance]."
                }

                if ($EnableStatic -eq $true) {
                    try {
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_Static" -Output "Trying to set machine to static IP: [$staticIp]. SubnetMask: [$subnetMask]."
                        $Script:List += $Get_CIMInstance | Invoke-CimMethod -MethodName $Methodname_Static -Arguments @{IPAddress = $staticIp; SubnetMask = $subnetMask } |
                        Add-Member -force -MemberType ScriptProperty -Name Type -Passthru -Value { $Methodname_Static }
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_Static" -Output "Successfully set machine static IP: [$staticIp]. SubnetMask: [$subnetMask]."
                    }

                    catch {
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_Static" -Output "Failed to set machine static IP: [$staticIp]. SubnetMask: [$subnetMask]."
                    }
                }

                if ($SetGateways -eq $true) {
                    try {
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_SetGateways" -Output "Trying to set machine to static Gateway: [$gateway]."
                        $mt = @([uint16]1)
                        $Script:List += $Script:Get_CIMInstance | Invoke-CimMethod -MethodName $Methodname_SetGateways -Arguments @{DefaultIPGateway = $gateway; GatewayCostMetric = $mt } |
                        Add-Member -force -MemberType ScriptProperty -Name Type -Passthru -Value { $Methodname_SetGateways }
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_SetGateways" -Output "Successfully set machine to static Gateway: [$gateway]."
                    }

                    catch {
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_SetGateways" -Output "Failed to set machine to static Gateway: [$gateway]."
                    }
                }

                if ($SetDNSServer -eq $true) {
                    try {
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_SetDNSServerSearchOrder"  -Output "Trying to set machine to static DNSServers: [$dnsserver]."
                        $Script:List += $Script:Get_CIMInstance | Invoke-CimMethod -MethodName $Methodname_SetDNSServerSearchOrder -Arguments @{DNSServerSearchOrder = $dnsserver } |
                        Add-Member -force -MemberType ScriptProperty -Name Type -Passthru -Value { $Methodname_SetDNSServerSearchOrder }
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_SetDNSServerSearchOrder"  -Output "Successfully set machine static DNSServers: [$dnsserver]."
                    }

                    catch {
                        Write-CSVLog -Type "$Set_StaticIP_LogType - $Methodname_SetDNSServerSearchOrder"  -Output "Failed to set machine to static DNSServers: [$dnsserver]."
                    }
                }

                foreach ($row in $Script:List) {
                    $row | Add-Member -MemberType ScriptProperty -Name ReturnValueFriendly -Passthru -Value {
                        switch ([int]$this.ReturnValue) {
                            0 { 'Successful completion, no reboot required' }
                            1 { 'Successful completion, reboot required' }
                            64 { 'Method not supported on this platform' }
                            65 { 'Unknown failure' }
                            66 { 'Invalid subnet mask' }
                            67 { 'An error occurred while processing an Instance that was returned' }
                            68 { 'Invalid input parameter' }
                            69 { 'More than 5 gateways specified' }
                            70 { 'Invalid IP address' }
                            71 { 'Invalid gateway IP address' }
                            72 { 'An error occurred while accessing the Registry for the requested information' }
                            73 { 'Invalid domain name' }
                            74 { 'Invalid host name' }
                            75 { 'No primary/secondary WINS server defined' }
                            76 { 'Invalid file' }
                            77 { 'Invalid system path' }
                            78 { 'File copy failed' }
                            79 { 'Invalid security parameter' }
                            80 { 'Unable to configure TCP/IP service' }
                            81 { 'Unable to configure DHCP service' }
                            82 { 'Unable to renew DHCP lease' }
                            83 { 'Unable to release DHCP lease' }
                            84 { 'IP not enabled on adapter' }
                            85 { 'IPX not enabled on adapter' }
                            86 { 'Frame/network number bounds error' }
                            87 { 'Invalid frame type' }
                            88 { 'Invalid network number' }
                            89 { 'Duplicate network number' }
                            90 { 'Parameter out of bounds' }
                            91 { 'Access denied' }
                            92 { 'Out of memory' }
                            93 { 'Already exists' }
                            94 { 'Path, file or object not found' }
                            95 { 'Unable to notify service' }
                            96 { 'Unable to notify DNS service' }
                            97 { 'Interface not configurable' }
                            98 { 'Not all DHCP leases could be released/renewed' }
                            100 { 'DHCP not enabled on adapter' }
                            default { 'Unknown Error ' }
                        }
                    }
                }
            } # End of Set-StaticIP
            Set-StaticIP -EnableStatic -staticIp $staticIp -subnetMask $subnetMask -SetGateways -gateway $gateway -SetDNSServer -dnsserv $dnsserver
        }

        try {
            Write-CSVLog -Type "Resolve-DnsName" -Output "Trying to executed command with a delay of 5 seconds before executing the command."
            Start-Sleep -Seconds 5
            Write-CSVLog -Type "Resolve-DnsName" -Output "Trying to see if I can resolve the DNS name on selected Domain: [$($ComboBox1_Domain.Text)]."
            $DNS_Addresses = Resolve-DnsName $ComboBox1_Domain.Text -Type "A"
            Write-CSVLog -Type "Resolve-DnsName" -Output "Successfully resolved the DNS name on selected Domain: [$($ComboBox1_Domain.Text)]."
            $Resolve_DNS_Check = $true
        }

        catch {
            Write-CSVLog -Type "Resolve-DnsName" -Output "Failed to resolve the DNS name on the selected Domain: [$($ComboBox1_Domain.Text)]. Check network cards in vSphere or IP settings on the machine."
            $Resolve_DNS_Check = $false
        }

        try {
            Write-CSVLog -Type $Test_OnlineFast_LogType -Output "Trying to find a domain controller that is online [$($ComboBox1_Domain.Text)]."
            $Pingable_DNSes = foreach ($DNS_Address in $DNS_Addresses) {
                Test-OnlineFast -ComputerName  $DNS_Address.IPAddress | Where-Object { $_.Online -eq $true }
            }
            $Script:Check_Connection = $Pingable_DNSes | Select-Object -First 1
            Write-CSVLog -Type $Test_OnlineFast_LogType -Output "Successfully found a domain controller that is online [$($ComboBox1_Domain.Text)]."
            $Ping_Check = $true
        }
        catch {
            Write-CSVLog -Type $Test_OnlineFast_LogType -Output "Failed to find a domain controller that is online [$($ComboBox1_Domain.Text)]."
            $Ping_Check = $false
        }

        $If_Statement = ($Script:Check_Connection.Online -eq $true -and $textBox_Servername.Text -match $Regex_Servername -and $ComboBox1_Domain.Text -and
            $ComboBox2OU.Text -and $PasswordBox_Password.Password -and $textBox_Username.Text -match $Backslash -and $textBox_Username.Text -and
            $checkbox_dhcp.isChecked) -or ($Script:Check_Connection.Online -eq $true -and $textBox_Servername.Text -match $Regex_Servername -and
            $ComboBox1_Domain.Text -and $ComboBox2OU.Text -and $PasswordBox_Password.Password -and $textBox_Username.Text -match $Backslash -and
            $textBox_Username.Text -and $textBox_IP.Text -and $textBox_Subnetmask.Text -and $textBox_gateway.Text -and $textBox_DNS1.Text -and
            $textBox_DNS2.Text -and (-not ($Script:IP_Regex_Check | Where-Object { $_ -match $false })) -and (-not ($Duplicate_IP_Scan)))

        if ($If_Statement) {
            Write-CSVLog -Type $GUI_Select_LogType -Output "Servername accepted, WORLD and OU selected."
            $Script:Cleaned_servername = $textBox_Servername.Text.ToUpper()
            try {
                $Username = "$($textBox_Username.Text)"
                Write-CSVLog -Type $Credentials_LogType -Output "Trying to set credentials, User: [$Username]."
                $PWord = ConvertTo-SecureString -String $PasswordBox_Password.Password -AsPlainText -Force
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $PWord
                Write-CSVLog -Type $Credentials_LogType -Output "Successfully set credentials, User: [$Username]."
            }

            catch {
                Write-CSVLog -Type $Credentials_LogType -Output "Failed to set credentials, User: [$Username]."
            }

            try {
                Write-CSVLog -Type $JoinServer_LogType -Output "Trying to join join the Machine: [$env:COMPUTERNAME] to OU: [$($ComboBox2OU.Text)]."
                $DN = $OUs | Where-Object { $_.ParentContainer -eq $ComboBox2OU.Text } | Select-Object -ExpandProperty ParentContainerDN
                $Add_Computer_Splatter = @{
                    DomainName  = $ComboBox1_Domain.Text
                    OUPath      = $DN
                    Credential  = $Credential
                    ErrorAction = 'Stop'
                    Force       = $true
                    #WhatIf       = $true #Change
                }

                Add-Computer @Add_Computer_Splatter
                $Check_DomainJoin = $true
                Write-CSVLog -Type $JoinServer_LogType -Output "Successfully joined the Machine: [$env:COMPUTERNAME] to OU: [$($ComboBox2OU.Text)]."
            }

            catch {
                $Check_DomainJoin = $false
                Write-CSVLog -Type $JoinServer_LogType -Output "Failed to join the Machine: [$env:COMPUTERNAME] to OU: [$($ComboBox2OU.Text)]. Error: [$_]"
            }
        }

        elseif (!($Script:Check_Connection.Online)) {
            Write-CSVLog -Type $Test_Connection_LogType -Output "Failed to get connection to the domain: [$($ComboBox1_Domain.Text)]. Check network adapter in vSphere - VLAN and IP settings on this machine using Start - Run - ncpa.cpl. Fix this then click OK again."
        }

        elseif (-not ($textBox_Servername.Text -match $Regex_Servername)) {
            Write-CSVLog -Type $GUI_Select_LogType -Output "Failed to accept servername. Use 1-15 alphanumeric. Dash: [-] could also be used. Fix this then press OK again."
        }
        elseif (-not ($ComboBox1_Domain.Text) -or (-not ($ComboBox2OU.Text))) {
            Write-CSVLog -Type $GUI_Select_LogType -Output "Input Failed: Please select both Domain and OU. Fix this then click OK again."
        }
        elseif (-not ($PasswordBox_Password.Password) -or (-not ($textBox_Username.Text))) {
            Write-CSVLog -Type $GUI_Select_LogType -Output "Input Failed: Please enter both username and password. Fix this then click OK again."
        }
        elseif ($textBox_Username.Text -notmatch $Backslash) {
            Write-CSVLog -Type $GUI_Select_LogType -Output "Input Failed: Please enter username with domain. Fix this then click OK again."
        }

        else {
            Write-CSVLog -Type $GUI_Select_LogType -Output "Input Failed: Check all red messages above, fix and click OK again."
        }

        if ($Check_DomainJoin) {
            if (($ComboBox2OU.Text -match "SEEMM1") -or ($ComboBox2OU.Text -match "SESTO") -or ($ComboBox2OU.Text -match "emeadmz")) {
                if ($ComboBox2OU.Text -match "emeadmz") {
                    try {
                        Write-CSVLog -Type $Install_SCCM_Logtype -Output "Server is located in a GDC OU: [$($ComboBox2OU.Text)]."
                        Write-CSVLog -Type $Install_SCCM_Logtype -Output "Trying to install SCCM."
                        Start-Process -FilePath PowerShell.exe -ArgumentList "$PSScriptRoot\40_Install_SCCM.ps1" -PassThru -Wait #Change
                        Write-CSVLog -Type $Install_SCCM_Logtype -Output "Successfully installed SCCM."
                        $Check_SCCM = $true
                    }

                    catch {
                        $Check_SCCM = $false
                        Write-CSVLog -Type $Install_SCCM_Logtype -Output "Failed to install SCCM."
                    }
                }
                else {
                    Write-CSVLog -Type $Install_SCCM_Logtype -Output "Server is located in a GDC OU: [$($ComboBox2OU.Text)]."
                    Write-CSVLog -Type $Install_SCCM_Logtype -Output "Trying to install SCCM."
                    Start-Process -FilePath PowerShell.exe -ArgumentList "$PSScriptRoot\40_Install_SCCM.ps1 -WORLD" -PassThru -Wait   #Change
                    Write-CSVLog -Type $Install_SCCM_Logtype -Output "Successfully installed SCCM."
                    $Check_SCCM = $true
                }
            }

            else {
                try {
                    Write-CSVLog -Type $Install_Altiris_Logtype -Output "Server is located in a LDC OU: [$($ComboBox2OU.Text)]."
                    Write-CSVLog -Type $Install_Altiris_Logtype -Output "Trying to install Altiris."
                    $p2 = Start-Process -FilePath PowerShell.exe -ArgumentList "$PSScriptRoot\install_altiris.ps1" -PassThru -Wait #Change

                    if ($p2.ExitCode -lt 1) {
                        Write-CSVLog  -Type $Install_Altiris_Logtype -Output "Successfully installed Altiris ExitCode: [$($p2.ExitCode)].]"
                        $Check_Altiris = $true
                    }
                    else {
                        $Check_Altiris = $false
                        Write-CSVLog -Type $Install_Altiris_Logtype -Output "Failed to install Altiris. ExitCode: [$($p2.ExitCode)]]. Exiting the script." -Throw
                    }
                }

                catch {
                    $Check_Altiris = $false
                    Write-CSVLog -Type $Install_Altiris_Logtype -Output "Failed to install Altiris."
                }
            }

            try {
                Write-CSVLog -Type $Install_S1_Logtype -Output "Trying to install Sentinel1."
                $p3 = Start-Process -FilePath PowerShell.exe -ArgumentList "$PSScriptRoot\42_Install_Sentinel1.ps1" #Change

                if ($p3.ExitCode -lt 1) {
                    Write-CSVLog -Type $Install_S1_Logtype -Output "Successfully installed $Sentinel_One ExitCode: [$($p3.ExitCode)]."
                    $Check_S1 = $true
                }
                else {
                    Write-CSVLog -Type $Install_S1_Logtype -Output "Failed to install $Sentinel_One. ExitCode: [$($p3.ExitCode)]. Exiting the script." -Throw
                }
            }

            catch {
                $Check_S1 = $false
                Write-CSVLog -Type $Install_S1_Logtype -Output "Failed to install Sentinel1."
            }

            try {
                Write-CSVLog -Type $Execute_Compliance_Check_Logtype -Output "Trying to execute Compliance Check script."
                $p4 = Start-Process -FilePath PowerShell.exe -ArgumentList "$PSScriptRoot\99_Compliant_Check_Invoke.ps1" -PassThru -Wait #Change

                if ($p4.ExitCode -lt 1) {
                    Write-CSVLog -Type $Execute_Compliance_Check_Logtype -Output "Successfully executed Compliance Check script."
                    $Check_CompCheck = $true
                }
                else {
                    $Check_CompCheck = $false
                    Write-CSVLog -Type $Execute_Compliance_Check_Logtype -Output "Failed to execute Compliance Check script. ExitCode: [$($p3.ExitCode)]. Exiting the script." -Throw
                }
            }

            catch {
                $Check_CompCheck = $false
                Write-CSVLog -Type $Execute_Compliance_Check_Logtype -Output "Failed to execute Compliance Check script."
            }

            $If_Statement2 = ($Check_Altiris -eq $true) -or ($Check_SCCM -eq $true) -and ($Check_S1 -eq $true) -and
            ($Check_CompCheck -eq $true) -and ($Check_DomainJoin -eq $true)

            if ($If_Statement2) {
                if ($checkbox_dhcp.isChecked) {
                    Write-CSVLog -Type $Important_Information_LogType -Output "DHCP is used, please set a reservation for this server in the DHCP server!"
                }
                Write-CSVLog -Type $Important_Information_LogType -Output "The local administrator account will be renamed from: Administrator to root ones you join the domain."
                Write-CSVLog -Type $Important_Information_LogType -Output "For Permanent Access, mail: [SmartSupport@Xyleminc.com] and ask them to create a case to the [SD2-Access Rights Security] group."
                Write-CSVLog -Type $Important_Information_LogType -Output "Tell Smart Support/Access Rights which groups and users that should be added in to the group. Group name for this server is [$("Server - Administrator - " + $Script:Cleaned_servername)]."
                Write-CSVLog -Type $Important_Information_LogType -Output "For more information check Wintel OneNote: [onenote:https://connect.xylem.com/sites/IS/dc/Win/Wintel%20OneNote/Microsoft.one#Creating%20of%20a%20Server%202019%20from%20ISO%20(beta)&section-id={93AFC023-BC59-4779-A6FF-DD4C45AE29C8}&page-id={91E89DCB-54EB-401D-93EF-6E0B17DA2A74}&object-id={21DAA489-48CD-0FB6-06FA-1D8AF66D9104}&10]. Open link in Internet Explorer."
                Write-CSVLog -Type $Important_Information_LogType -Output "Please note that you have to order the server via XOC also: [http://xoc.xylem.com/]."
                Write-CSVLog -Type $Important_Information_LogType -Output "Temporarily access for 2 weeks will be created."
                Write-CSVLog -Type $Important_Information_LogType -Output "Reboot the server now and try to login to the domain, if you cannot login please restart the server again in about 5 minutes."
                #$Window.Close() | Out-Null
                Pause2
                Restart-Computer #-WhatIf #Change
            }
            elseif ($Check_Altiris -eq $false) {
                Write-CSVLog -Type "Not complete!" -Output "Altiris failed to install. Please Mail: [stefan.svensson@xyleminc.com] with the CSV logs from: [C:\temp\install\scripts\*.csv]."
            }
            elseif ($Check_SCCM -eq $false) {
                Write-CSVLog -Type "Not complete!" -Output "SCCM failed to install. Please Mail: [stefan.svensson@xyleminc.com] with the CSV logs from: [C:\temp\install\scripts\*.csv]."
            }
            elseif ($Check_S1 -eq $false) {
                Write-CSVLog -Type "Not complete!" -Output "Sentinel1 failed to install. Please Mail: [stefan.svensson@xyleminc.com] with the CSV logs from: [C:\temp\install\scripts\*.csv]."
            }
            elseif ($Check_CompCheck -eq $false) {
                Write-CSVLog -Type "Not complete!" -Output "Compliance Check failed to install. Please Mail: [stefan.svensson@xyleminc.com] with the CSV logs from: [C:\temp\install\scripts\*.csv]."
            }
            elseif ($Check_DomainJoin -eq $false) {
                Write-CSVLog -Type "Not complete!" -Output "Failed to join the domain. Please Mail: [stefan.svensson@xyleminc.com] with the CSV logs from: [C:\temp\install\scripts\*.csv]."
            }
            else {
                Write-CSVLog -Type "Not complete!" -Output "Something else failed. Please Mail: [stefan.svensson@xyleminc.com] with the CSV logs from: [C:\temp\install\scripts\*.csv]."
            }
        }

    })

#Event: when ComboBox1_Domain is closed.
$ComboBox1_Domain.Add_DropDownClosed( {

        #Empty ComboBox2_OU.
        $ComboBox2OU.Items.Clear()

        #Depending on ComboBox1_Domain value.
        switch ($ComboBox1_Domain.Text) {

            ${Domain_world.fluidtechnology.net} {
                foreach ($JoinedObject1 in ($JoinedObjects.ou | Where-Object { $_ -match ${Domain_world.fluidtechnology.net} } | Sort-Object)) {
                    $ComboBox2OU.Items.Add( ($JoinedObject1) )
                }
            }

            ${Domain_emeadmz.net} {
                foreach ($JoinedObject1 in ($JoinedObjects.ou | Where-Object { $_ -match ${Domain_emeadmz.net} } | Sort-Object)) {
                    $ComboBox2OU.Items.Add( ($JoinedObject1) )
                }
            }

            ${Domain_emea.sensus.net} {
                foreach ($JoinedObject1 in ($JoinedObjects.ou | Where-Object { $_ -match ${Domain_emea.sensus.net} } | Sort-Object)) {
                    $ComboBox2OU.Items.Add( ($JoinedObject1) )
                }
            }

            ${Domain_lab.sensus.net} {
                foreach ($JoinedObject1 in ($JoinedObjects.ou | Where-Object { $_ -match ${Domain_lab.sensus.net} } | Sort-Object)) {
                    $ComboBox2OU.Items.Add( ($JoinedObject1) )
                }
            }

            ${Domain_sensus.net} {
                foreach ($JoinedObject1 in ($JoinedObjects.ou | Where-Object { $_ -match ${Domain_sensus.net} } | Sort-Object)) {
                    $ComboBox2OU.Items.Add( ($JoinedObject1) )
                }
            }

            ${Domain_na.sensus.net} {
                foreach ($JoinedObject1 in ($JoinedObjects.ou | Where-Object { $_ -match ${Domain_na.sensus.net} } | Sort-Object)) {
                    $ComboBox2OU.Items.Add( ($JoinedObject1) )
                }
            }
        }
    })

#Show window.
$async = $Window.Dispatcher.InvokeAsync( {
        $Window.Activate()
        $Window.ShowDialog() | Out-Null
    })
$async.Wait() | Out-Null