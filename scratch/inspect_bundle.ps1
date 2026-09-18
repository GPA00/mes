$f = "d:\mes\mes\docker\uniapp\dist\assets\pages-core-auth-login.BZ7S4tKF.js"
$content = [System.IO.File]::ReadAllText($f)
Write-Output "File length: $($content.Length)"
Write-Output "Has wd-button: $($content.Contains('wd-button'))"
Write-Output "Has wd-input: $($content.Contains('wd-input'))"
Write-Output "Has wd-icon: $($content.Contains('wd-icon'))"
Write-Output "Has resolveComponent: $($content.Contains('resolveComponent'))"
if ($content.Contains('resolveComponent')) {
    $idx = 0
    while (($idx = $content.IndexOf('resolveComponent', $idx)) -ge 0) {
        $start = [Math]::Max(0, $idx - 30)
        $len = [Math]::Min(120, $content.Length - $start)
        Write-Output "Snippet: $($content.Substring($start, $len))"
        $idx += 16
    }
}
