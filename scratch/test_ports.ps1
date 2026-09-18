foreach ($port in @(1228, 1229, 3307, 6379, 48080)) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $tcp.BeginConnect("127.0.0.1", $port, $null, $null)
        $wait = $iar.AsyncWaitHandle.WaitOne(1000, $false)
        if ($wait) {
            $tcp.EndConnect($iar)
            Write-Output "Port ${port} is OPEN"
        } else {
            Write-Output "Port ${port} is TIMEOUT"
        }
    } catch {
        Write-Output "Port ${port} is CLOSED"
    } finally {
        $tcp.Close()
    }
}
