# Set-ExecutionPolicy -Scope Process Unrestricted
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,

    [ValidateSet("Test_Saturday", "Test_Sunday", "Test_nonreboot" , "Prod_Saturday", "Prod_Sunday", "Prod_Sunday_Late", "Prod_nonreboot", "Patch_Excluded", "Prod_Azure", "Test_Azure")]
    [Parameter(Mandatory = $true)]
    [String] $TargetGroup,

    [Parameter(Mandatory = $true)]
    [ValidateSet("USE2AZSLWSUS01.world.fluidtechnology.net","SEEMM1APP1396.world.fluidtechnology.net", "AUSYD2AS-09.world.fluidtechnology.net", "USEVI1APP043.world.fluidtechnology.net" , "ZAJNB1WSUS01.world.fluidtechnology.net")]
    [String] $WSUS_FQDN
)

$ErrorActionPreference = 'Stop'
$InformationPreference = "SilentlyContinue"
$CCMPath = "C:\Windows\ccmsetup\ccmsetup.exe"
$WSUS_Web = "http://$WSUS_FQDN" + ":8530"
$TempFolder = "c:\Temp\"
$SolarWindsCertLocal = "c:\Temp\Wsus_cert.cer"
$SolarWindsCertFolder = "\\seemm1netapp1.world.fluidtechnology.net\resources\Scripts\SolarWindsPatch"
$SolarWindsCert_PSDrive = "V"
$SolarWindsCert_MappedNetwork = "V:"
$SolarWindsCert_Mapped = $SolarWindsCert_PSDrive + ":\"
$SolarWindsCert_Mapped_Copy = $SolarWindsCert_Mapped + "Wsus_cert.cer"
$Altiris = "Altiris"
$SCCM = "SCCM"
$script:Messages = New-Object System.Collections.Generic.List[PSObject]

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
    $script:Messages.Add($obj)

    # Output the message directly to the console
    Write-Host "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss.ff') | $ComputerName | $Message"

    # Return the PSCustomObject (optional, if you need to use it elsewhere)
    return $obj
}

function Get-ItemPropertyValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Path,

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    process {
        foreach ($regPath in $Path) {
            try {
                $regKey = Get-Item -Path $regPath -ErrorAction Stop
                $regValue = $regKey.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                if ($regValue) {
                    $regValue
                }
            }
            catch {
                Write-Debug "Unable to retrieve registry value from path: $regPath"
            }
        }
    }
}
function Import-Certificate2 {
    <#
  .SYNOPSIS
  Import  a certificate from a local or remote system.

  .DESCRIPTION
  Import  a certificate from a local or remote system.

  .PARAMETER  Computername
  A  single or  list of computer names to  perform search against

  .PARAMETER  StoreName
  The  name of  the certificate store name that  you want to search

  .PARAMETER  StoreLocation
  The  location  of the certificate store.

  .NOTES
  Name: Import-Certificate
  Author:  Boe Prox
  Version  History:
  1.0  -  Initial Version

  .EXAMPLE
  $File =  "C:\temp\SomeRootCA.cer"
  $Computername = 'Server1','Server2','Client1','Client2'
  Import-Certificate -Certificate $File -StoreName Root -StoreLocation  LocalMachine -ComputerName $Computername

  Description
  -----------
  Adds  the SomeRootCA certificate to the Trusted Root Certificate Authority store on  the remote systems.
#>
    [cmdletbinding(
        SupportsShouldProcess = $True
    )]

    Param (
        [parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('PSComputername', '__Server', 'IPAddress')]
        [string[]]$Computername = $env:COMPUTERNAME,
        [parameter(Mandatory = $True)]
        [string]$Certificate,
        [System.Security.Cryptography.X509Certificates.StoreName]$StoreName = 'My',
        [System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = 'LocalMachine',
        [System.Management.Automation.PSCredential]$Credential = $Credential
    )

    Begin {
        $CertificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $CertificateObject.Import($Certificate)
    }

    Process {
        ForEach ($Computer in  $Computername) {
            Try {
                Write-Verbose ("Connecting to {0}\{1}" -f "\\$($Computername)\$($StoreName)", $StoreLocation)

                If ($Global:Verbose_Check -eq $true) {
                    Write-CSVLog -Output ("Connecting to {0}\{1}" -f "\\$($Computername)\$($StoreName)", $StoreLocation)
                }

                $CertStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList "\\$($Computername)\$($StoreName)", $StoreLocation
                $CertStore.Open('ReadWrite')

                If ($PSCmdlet.ShouldProcess("$($StoreName)\$($StoreLocation)", "Add  $Certificate")) {
                    $CertStore.Add($CertificateObject)
                }
            }
            Catch {
                Throw "$($Computer): $_"
            }
        }
    }
}

Write-Output2 "TargetGroup: [$TargetGroup]. Cred UserName: [$($Credential.UserName)]. WSUS:[$WSUS_FQDN]."      

#Disconect all mapped network devices
net use * /delete /yes

#Region ####################################### New-PSDrive ################################################
try {
    Write-Output2 "Trying to mount Folder: [$SolarWindsCertFolder]. Cred UserName: [$($Credential.UserName)]."
    & NET USE $SolarWindsCert_MappedNetwork $SolarWindsCertFolder /user:$($Credential.UserName) $($Credential.GetNetworkCredential().Password)
    Write-Output2 "Successfully mounted Folder: [$SolarWindsCertFolder] Cred UserName: [$($Credential.UserName)]."
}
catch {
    Write-Output2 "Failed to mount Folder: [$SolarWindsCertFolder] Cred UserName: [$($Credential.UserName)]. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
    throw
}
#Endregion #################################### New-PSDrive ################################################

#Region ####################################### Create folder and Copy Cert ################################
if (!(Test-Path $TempFolder)) {
    try {
        Write-Output2 "Trying to create a Folder: [$TempFolder]."
        New-Item -ItemType Directory $TempFolder
        Write-Output2 "Successfully created Folder: [$TempFolder]."
    }
    catch {
        Write-Output2 "Failed to create a Folder: [$TempFolder]. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
        throw
    }
}
else {
    Write-Output2 "Folder: [$TempFolder] already exists."
}

if (!(Test-Path $SolarWindsCertLocal)) {
    try {
        Write-Output2 "Trying to copy the Cert: [$SolarWindsCert_Mapped_Copy] to [$TempFolder]."
        Copy-Item $SolarWindsCert_Mapped_Copy $TempFolder -Force
        Write-Output2 "Successfully copied the Cert: [$SolarWindsCert_Mapped_Copy] to [$TempFolder]."
    }
    catch {
        Write-Output2 "Failed to copy the Cert: [$SolarWindsCert_Mapped_Copy] to [$TempFolder]. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
        throw
    }
}
else {
    Write-Output2 "Certificate Path: [$SolarWindsCertLocal] already exists."
}
#Endregion #################################### Create folder and Copy Cert ################################

#Region ####################################### Import Certificate #########################################
if (Get-Command -Name Import-Certificate -ErrorAction SilentlyContinue) {
    try {
        Write-Output2 "Trying to import the Certificate: [$SolarWindsCertLocal] to [Trusted Root Certification Authorities] and [TrustedPublisher]."
        Import-Certificate -FilePath $SolarWindsCertLocal -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
        Import-Certificate -FilePath $SolarWindsCertLocal -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
        Write-Output2 "Successfully imported the Certificate: [$SolarWindsCertLocal] to [Trusted Root Certification Authorities] and [TrustedPublisher]."
    }
    catch {
        Write-Output2 "Failed to import the Certificate: [$SolarWindsCertLocal]. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
        throw
    }
}
else {
    try {
        Write-Output2 "Trying to import the Certificate2: [$SolarWindsCertLocal] to [Trusted Root Certification Authorities] and [TrustedPublisher]."
        Import-Certificate2 -Computername $env:COMPUTERNAME -Certificate $SolarWindsCertLocal -StoreName Root -StoreLocation LocalMachine | Out-Null
        Import-Certificate2 -Computername $env:COMPUTERNAME -Certificate $SolarWindsCertLocal -StoreName TrustedPublisher -StoreLocation LocalMachine | Out-Null
        Write-Output2 "Successfully imported the Certificate2: [$SolarWindsCertLocal] to [Trusted Root Certification Authorities] and [TrustedPublisher]."
    }
    catch {
        Write-Output2 "Failed to import the Certificate2: [$SolarWindsCertLocal]. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
        throw
    }
}
#Endregion #################################### Import Certificate #########################################

#Region ####################################### New Firewall Rule #########################################
$FireWallRule = "SolarWinds Patch Manager"
$FirewallPorts = 135, 137, 139, 445, 4091, 49701, "49152-65535"
if (Get-Command -Name New-NetFirewallRule -ErrorAction SilentlyContinue) {
    try {
        Write-Output2 "The command: [New-NetFirewallRule] exists."
        if (![bool](Get-NetFirewallRule -DisplayName $FireWallRule -ErrorAction SilentlyContinue)) {
            Write-Output2 "Trying to create a new Windows Firewall Rule: [$FireWallRule] as the rule doesn't exist."
            New-NetFirewallRule -DisplayName $FireWallRule -Direction Inbound -Protocol TCP -LocalPort $FirewallPorts -Action Allow -RemoteAddress "10.95.99.30"
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
#Endregion #################################### New Firewall Rule #########################################

#Region ####################################### Remove-PSDrive #############################################
try {
    Write-Output2 "Trying to unmount Folder: [$SolarWindsCert_PSDrive]."
    Remove-PSDrive -Name $SolarWindsCert_PSDrive -Force | Out-Null
    Write-Output2 "Successfully unmount Folder: [$SolarWindsCert_PSDrive]."
}
catch {
    Write-Output2 "Failed to unmount Folder: [$SolarWindsCert_PSDrive]. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
    throw
}
#Endregion #################################### Remove-PSDrive #############################################

#Region ####################################### Altiris Check ##############################################
$Altiris_CheckFolder = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Altiris\Altiris Agent\" -Name "InstallDir" -ErrorAction SilentlyContinue

if (!($null -eq $Altiris_CheckFolder -or $Altiris_CheckFolder -match '^\s*$')) {
    $AltirisAgent = "AeXAgentUtil.exe"
    $AltirisClient = "$Altiris_CheckFolder\$AltirisAgent"
    if (Test-Path $AltirisClient) {
        Write-Output2 "$Altiris is installed. Uninstalling it now."

        $p = Start-Process -FilePath $AltirisClient -Args "/clean" -PassThru -Wait -NoNewWindow
        if ($p.ExitCode -eq 0) {
            Write-Output2 "Successfully uninstalled $Altiris."
        }
        else {
            Write-Output2 "Failed to uninstall $Altiris."
        }
    }
}
else {
    Write-Output2 "$Altiris is NOT installed."
}
#Endregion #################################### Altiris Check ##############################################

#Region ######################################## SCCM Check ################################################
# Run SCCM remove
# $CCMPath is path to SCCM Agent's own uninstall routine.
# And if it exists we will remove it, or else we will silently fail.
if (Test-Path $CCMPath) {
    $SCCM_Services = @(
        'ccmsetup'
        'CcmExec'
        'smstsmgr'
        'CmRcService'
    )
    $CCMexec = "ccmexec"
    Write-Output2 "$SCCM is installed. Uninstalling it now."
    Start-Process -FilePath $CCMPath -Args "/uninstall" -PassThru -Wait -NoNewWindow
    # wait for exit
    $CCMProcess = Get-Process "ccmsetup" -ErrorAction SilentlyContinue
    try {
        Write-Output2 "Waiting for the Service: [$CCMexec] to exit."
        $CCMProcess.WaitForExit()
        Write-Output2 "The Service: [$CCMexec] has left the building."
    }
    catch {
        Write-Output2 "Failed to wait for the Service: [$CCMexec] to exit."
    }

    # Stop Services
    foreach ($SCCM_Service in $SCCM_Services) {
        Stop-Service -Name $SCCM_Service -Force -ErrorAction SilentlyContinue
    }

    # Wait for services to exit
    $CCMProcess = Get-Process $CCMexec -ErrorAction SilentlyContinue
    try {
        Write-Output2 "Waiting for the Service: [$CCMexec] to exit."
        $CCMProcess.WaitForExit()
        Write-Output2 "The Service: [$CCMexec] has left the building."
    }
    catch {
        Write-Output2 "Failed waiting for the Service: [$CCMexec] to exit."
    }

    if (Get-Command -Name Get-CimInstance -ErrorAction SilentlyContinue) {
        # Remove WMI Namespaces
        try {
            Write-Output2 "Trying to remove WMI instance for SCCM."
            Get-CimInstance -ClassName "__Namespace" -Namespace "root" -Filter "Name='ccm'" | Remove-CimInstance
            Get-CimInstance -ClassName "__Namespace" -Namespace "root\cimv2" -Filter "Name='sms'" | Remove-CimInstance
            Write-Output2 "Successfully removed WMI instance for SCCM."
        }
        catch {
            Write-Output2 "Failed to remove WMI instance for SCCM. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
            throw
        }
    }
    else {
        # Remove WMI Namespaces
        try {
            Write-Output2 "Trying to remove WMI instance for SCCM."
            Get-WmiObject -Query "SELECT * FROM __Namespace WHERE Name='ccm'" -Namespace root | Remove-WmiObject
            Get-WmiObject -Query "SELECT * FROM __Namespace WHERE Name='sms'" -Namespace root\cimv2 | Remove-WmiObject
            Write-Output2 "Successfully removed WMI instance for SCCM."
        }
        catch {
            Write-Output2 "Failed to remove WMI instance for SCCM. Error: [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
            throw
        }
    }

    # Remove Services from Registry
    # Set $CurrentPath to services registry keys
    $CurrentPath = "HKLM:\SYSTEM\CurrentControlSet\Services"
    # Stop Services
    foreach ($SCCM_Service in $SCCM_Services) {
        Remove-Item -Path "$CurrentPath\$SCCM_Service" -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Remove SCCM Client from Registry
    # Update $CurrentPath to HKLM/Software/Microsoft
    $CurrentPath = "HKLM:\SOFTWARE\Microsoft"
    Remove-Item -Path "$CurrentPath\CCM" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$CurrentPath\CCMSetup" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$CurrentPath\SMS" -Force -Recurse -ErrorAction SilentlyContinue

    # Reset MDM Authority
    # CurrentPath should still be correct, we are removing this key: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\DeviceManageabilityCSP
    Remove-Item -Path "$CurrentPath\DeviceManageabilityCSP" -Force -Recurse -ErrorAction SilentlyContinue

    # Remove Folders and Files
    # Tidy up garbage in Windows folder
    $CurrentPath = $env:WinDir
    Get-ChildItem -Path "$CurrentPath\CCM" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$CurrentPath\CCM" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$CurrentPath\ccmsetup" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$CurrentPath\SMSCFG.ini" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$CurrentPath\SMS*.mif" -Force -ErrorAction SilentlyContinue

    # Remove the link of Software Center
    $folderPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Endpoint Manager\Configuration Manager"
    $softwareCenterLnk = "$folderPath\Software Center.lnk"

    if (Test-Path $folderPath) {
        $contents = Get-ChildItem $folderPath
        if ($contents.Count -eq 1 -and $contents.Name -contains "Software Center.lnk") {
            # Remove the entire folder recursively
            Remove-Item $folderPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output2 "The folder '$folderPath' containing only 'Software Center.lnk' has been deleted."
        }
        elseif (Test-Path $softwareCenterLnk) {
            # Remove only the 'Software Center.lnk' file
            Remove-Item $softwareCenterLnk -Force -ErrorAction SilentlyContinue
            Write-Output2 "'Software Center.lnk' has been deleted from '$folderPath'."
        }
        else {
            Write-Output2 "The folder '$folderPath' does not contain 'Software Center.lnk'."
        }
    }
    else {
        Write-Output2 "The folder '$folderPath' does not exist."
    }
}
else {
    Write-Output2 "$SCCM is NOT installed."
}
#EndRegion ##################################### SCCM Check ################################################

#Region ############################# Import to SolarWinds Patch Manager ###################################
try {
    Write-Output2 "Trying to add the registry entries for SolarWinds Patch Manager."
    $RegKey_Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
    # Create the WindowsUpdate key if it does not exist
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force | Out-Null

    # Add the values under the WindowsUpdate key
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate" -Name "AcceptTrustedPublisherCerts" -Value 1 -Type DWord -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate" -Name "TargetGroupEnabled" -Value 1 -Type DWord -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate" -Name "TargetGroup" -Value $TargetGroup -Type String -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate" -Name "WUServer" -Value $WSUS_Web -Type String -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate" -Name "WUStatusServer" -Value $WSUS_Web -Type String -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate" -Name "DoNotEnforceEnterpriseTLSCertPinningForUpdateDetection" -Value 1 -Type DWord -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate" -Name "SetProxyBehaviorForUpdateDetection" -Value 0 -Type DWord -Force | Out-Null
    $SUSClientID = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "SUSClientID" -ErrorAction SilentlyContinue
    if ($SUSClientID) {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "SUSClientID" -Force | Out-Null
    }
    # Create the AU key if it does not exist
    New-Item -Path "$RegKey_Path\WindowsUpdate\AU" -Force | Out-Null

    # Add the values under the AU key
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0 -Type DWord -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate\AU" -Name "AUOptions" -Value 3 -Type DWord -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate\AU" -Name "ScheduledInstallDay" -Value 0 -Type DWord -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate\AU" -Name "ScheduledInstallTime" -Value 3 -Type DWord -Force | Out-Null
    New-ItemProperty -Path "$RegKey_Path\WindowsUpdate\AU" -Name "UseWUServer" -Value 1 -Type DWord -Force | Out-Null
    Write-Output2 "Successfully added the registry entries for SolarWinds Patch Manager."
}
catch {
    Write-Output2 "Failed to add the registry entries for SolarWinds Patch Manager Error [$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
    throw
}

$services = "wuauserv", "cryptSvc", "bits", "msiserver"

foreach ($service in $services) {
    try {
        Write-Output2 "Trying to stop Service: [$service]."
        Stop-Service $service -Force | Out-Null
        Write-Output2 "Successfully stopped Service: [$service]."
    }
    catch {
        Write-Output2 "Failed to stop Service: [$service]. Error[$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
    }
}

Write-Output2 "###### Removing WSUS cache files ######"
Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output2 "###### Starting Windows Update Service ######"
foreach ($service in $services) {
    try {
        Write-Output2 "Trying to start Services: [$service]."
        Start-Service $service | Out-Null
        Write-Output2 "Successfully started Services: [$service]."
    }
    catch {
        Write-Output2 "Failed to start Services: [$service]. Error[$_] at Line:[$($_.InvocationInfo.ScriptLineNumber)]."
    }
}

$ErrorActionPreference = "SilentlyContinue"
if ($Error) {
    $Error.Clear()
}
$UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
$Searcher = New-Object -ComObject Microsoft.Update.Searcher
$Session = New-Object -ComObject Microsoft.Update.Session

Write-Output2 "Initializing and Checking for Applicable Updates. Please wait ..."
$Result = $Searcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

if ($Result.Updates.Count -eq 0) {
    Write-Output2 "There are no applicable updates for this computer."
}
else {
    Write-Output2 "Preparing List of Applicable Updates For This Computer ..."
    for ($Counter = 0; $Counter -lt $Result.Updates.Count; $Counter++) {
        $DisplayCount = $Counter + 1
        $Update = $Result.Updates.Item($Counter)
        $UpdateTitle = $Update.Title
        Write-Output2 "$DisplayCount -- $UpdateTitle"
    }
    $Counter = 0
    $DisplayCount = 0
}
#EndRegion ########################## Import to SolarWinds Patch Manager ###################################

#Region ######################################## Error Check ################################################
# If error write out that.
if ($Error) {
    $LASTEXITCODE = 1
    Write-Output2 "Exitcode: An error has occurred, please check further."
}
# If everything went fine.
else {
    Write-Output2 "Exitcode: Everything went fine."
}
#EndRegion ##################################### Error Check ################################################
$null = $Credential
return $Messages