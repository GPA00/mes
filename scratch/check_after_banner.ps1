$log = "d:\mes\mes\docker\backend\logs\yudao-server.log"
$lines = Get-Content $log
$afterSuccess = $false
$count = 0
foreach ($line in $lines) {
    if ($line -like "*BannerApplicationRunner*") {
        $afterSuccess = $true
    }
    if ($afterSuccess) {
        Write-Output $line
        $count++
        if ($count -ge 50) { break }
    }
}
if (-not $afterSuccess) {
    Write-Output "Banner not found in current log"
}
