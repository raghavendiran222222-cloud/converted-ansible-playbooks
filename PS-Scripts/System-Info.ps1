# Gather basic system information and write to a report file
$reportPath = "$env:TEMP\system-report.txt"

$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$cpuInfo = Get-CimInstance -ClassName Win32_Processor
$diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"

$report = @"
===== System Report =====
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

OS:        $($osInfo.Caption) $($osInfo.Version)
Computer:  $($osInfo.CSName)
Uptime:    $((Get-Date) - $osInfo.LastBootUpTime | ForEach-Object { "$($_.Days)d $($_.Hours)h $($_.Minutes)m" })

CPU:       $($cpuInfo.Name)
Cores:     $($cpuInfo.NumberOfCores)

Disk Usage:
"@

foreach ($disk in $diskInfo) {
    $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
    $totalGB = [math]::Round($disk.Size / 1GB, 2)
    $report += "`n  $($disk.DeviceID) $usedGB GB / $totalGB GB"
}

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host $report
Write-Host "`nReport saved to: $reportPath"
