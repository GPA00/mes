$git = "C:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path $git)) {
    $git = "git"
}
& $git log -S "WotResolver" -p -n 2
