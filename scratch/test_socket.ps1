$tcp = New-Object System.Net.Sockets.TcpClient
try {
    $tcp.Connect("127.0.0.1", 48080)
    Write-Output "TCP 48080 is CONNECTED"
    $tcp.Close()
} catch {
    Write-Output "TCP 48080 Connection failed: $($_.Exception.Message)"
}
