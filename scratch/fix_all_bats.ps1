$files = Get-ChildItem -Path "d:\mes\mes\docker" -Filter "*.bat" -Recurse

foreach ($file in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    
    # Check if there is BOM (EF BB BF)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    if ($hasBom) {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    }

    # Normalize to CRLF: first replace all \r\n with \n, then all \r with \n, then \n with \r\n
    $normalizedText = $text -replace "`r`n", "`n" -replace "`r", "`n" -replace "`n", "`r`n"
    
    # Save as UTF-8 without BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($file.FullName, $normalizedText, $utf8NoBom)
    
    # Verify result
    $newBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $cr = ($newBytes | Where-Object { $_ -eq 13 }).Count
    $lf = ($newBytes | Where-Object { $_ -eq 10 }).Count
    Write-Output "Fixed: $($file.FullName) | Bytes: $($newBytes.Length) | CR: $cr | LF: $lf"
}
