$f = "d:\mes\mes\docker\uniapp\dist\assets\pages-core-auth-login.BZ7S4tKF.js"
$content = [System.IO.File]::ReadAllText($f)
$idx = $content.IndexOf("wd-button")
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 100)
    $len = [Math]::Min(300, $content.Length - $start)
    Write-Output "Snippet: $($content.Substring($start, $len))"
}
$idx2 = $content.IndexOf("wd-input")
if ($idx2 -ge 0) {
    $start = [Math]::Max(0, $idx2 - 100)
    $len = [Math]::Min(300, $content.Length - $start)
    Write-Output "Snippet wd-input: $($content.Substring($start, $len))"
}
