# List running services and restart a specific one
param(
    [string]$ServiceName = "Spooler"
)

# Get all running services
$runningServices = Get-Service | Where-Object { $_.Status -eq "Running" }
Write-Host "Total running services: $($runningServices.Count)"

# Display top 5 running services
Write-Host "`nTop 5 Running Services:"
$runningServices | Select-Object -First 5 | ForEach-Object {
    Write-Host "  - $($_.DisplayName) [$($_.Name)]"
}

# Restart the specified service
Write-Host "`nRestarting service: $ServiceName"
Restart-Service -Name $ServiceName -Force
$svc = Get-Service -Name $ServiceName
Write-Host "Service '$ServiceName' status: $($svc.Status)"
