# Find and remove temp files older than N days
param(
    [string]$TargetPath = "$env:TEMP",
    [int]$DaysOld = 30
)

$cutoffDate = (Get-Date).AddDays(-$DaysOld)

# Find old files
$oldFiles = Get-ChildItem -Path $TargetPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

Write-Host "Scanning: $TargetPath"
Write-Host "Files older than $DaysOld days (before $($cutoffDate.ToString('yyyy-MM-dd'))):"
Write-Host "  Found: $($oldFiles.Count) files"

if ($oldFiles.Count -gt 0) {
    $totalSize = ($oldFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  Total size: $([math]::Round($totalSize, 2)) MB"

    # Remove the files
    $oldFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  Cleanup complete."
} else {
    Write-Host "  Nothing to clean up."
}
