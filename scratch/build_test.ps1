cd "d:\mes\mes\yudao-ui\yudao-ui-admin-uniapp"
$pnpm = "pnpm"
where.exe pnpm
if ($LASTEXITCODE -ne 0) {
    Write-Output "pnpm not in standard PATH, searching AppData..."
    $found = Get-ChildItem "$env:LOCALAPPDATA" -Filter "pnpm.cmd" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $pnpm = $found.FullName
        Write-Output "Found pnpm at $pnpm"
    }
}
& $pnpm run build:h5:prod
