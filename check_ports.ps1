$ports = @(80, 1228, 3306, 3307, 48080, 6379)
foreach ($p in $ports) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect('127.0.0.1', $p, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne(500, $false)
        if ($success -and $tcp.Connected) {
            Write-Host "Port $p is OPEN"
        } else {
            Write-Host "Port $p is CLOSED"
        }
        $tcp.Close()
    } catch {
        Write-Host "Port $p is ERROR: $_"
    }
}
