try {
    $resp = Invoke-WebRequest -Uri "http://localhost:48080/admin-api/system/tenant/simple-list" -TimeoutSec 5 -UseBasicParsing
    Write-Output "Status: $($resp.StatusCode)"
    Write-Output "Content: $($resp.Content)"
} catch {
    Write-Output "Error: $($_.Exception.Message)"
}
