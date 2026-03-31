$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

$ServerName = "azeemtestvm002"

$Credential_LocalAdmin = Get-Credential -Message "Enter local administrator credentials for server name: [$ServerName]" -UserName "azureuser"
$Credential_ServiceAccount = Get-Credential -Message "Enter service account credentials for server name: [$ServerName]" -UserName "world\svc-joinaadvm"

try {
    #add ad group as local admin so service account can use Invoke-Command
    $addGroup = $Credential_ServiceAccount.UserName
    Write-Information "Post-Deployment - Trying to add Access. Adding group [$addGroup] to local administrator group." 

    Invoke-Command -ComputerName $ServerName -Credential $Credential_LocalAdmin -ScriptBlock {
        $ErrorActionPreference = 'Stop'
        $admins = Get-LocalGroupMember -Group 'Administrators'
        if ($using:addGroup -notin $admins.Name) {
            try {
                Write-Information "Post-Deployment - Add Access - Adding [$using:addGroup] to local administrator group."
                Add-LocalGroupMember -Group 'Administrators' -Member $using:addGroup
                Write-Information "Post-Deployment - Add Access - Successfully added [$using:addGroup] to local administrator group."
            }
            catch {
                throw "Unable to add [$addGroup] to local administrator group. Error: [$($_.Exception.Message)]."
            }
        }
        else {
            Write-Information "Post-Deployment - Add Access - Group [$using:addGroup] is already a member of local administrator group."
        }
    }
}
catch {
    Write-Information "Post-Deployment - Add Access - Unable to add $addGroup to local administrator group. Error: [$_]." 
    $testCommand = Invoke-Command -ComputerName $ServerName -ErrorAction 'SilentlyContinue' -ScriptBlock { $env:COMPUTERNAME } -Credential $Credential_ServiceAccount
    if ($null -eq $testCommand) {
        throw "Unable to add $addGroup to local administrator group.: $($_.Exception.Message)"
    }
    else {
        Write-Information "Post-Deployment - Add Access Account '$($Credential_ServiceAccount.UserName)' has access, continuing" 
    }
}