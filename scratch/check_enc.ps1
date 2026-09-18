$path = "d:\mes\mes\docker\start.bat"
$bytes = [System.IO.File]::ReadAllBytes($path)
$cr = 0
$lf = 0
foreach ($b in $bytes) {
    if ($b -eq 13) { $cr++ }
    if ($b -eq 10) { $lf++ }
}
$isUtf8 = $false
try {
    $utf8 = [System.Text.Encoding]::UTF8.GetString($bytes)
    $isUtf8 = $true
} catch {
    $isUtf8 = $false
}
$gbkEnc = [System.Text.Encoding]::GetEncoding("GBK")
$isGbk = $false
try {
    $gbk = $gbkEnc.GetString($bytes)
    $isGbk = $true
} catch {
    $isGbk = $false
}
Write-Output "File length: $($bytes.Length)"
Write-Output "CR count: $cr"
Write-Output "LF count: $lf"
Write-Output "First 20 bytes: $($bytes[0..19] -join ' ')"
