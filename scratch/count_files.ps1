$dirs = @(
    'yudao-ui/yudao-ui-admin-vue3/.pnpm-store',
    'yudao-ui/yudao-ui-admin-uniapp/node_modules',
    'yudao-ui/yudao-ui-admin-vue3/node_modules',
    'yudao-ui/yudao-ui-admin-uniapp/dist',
    'yudao-ui/yudao-ui-admin-vue3/dist-prod',
    'docker'
)

foreach ($d in $dirs) {
    if (Test-Path $d) {
        $files = [System.IO.Directory]::GetFiles((Resolve-Path $d), '*', [System.IO.SearchOption]::AllDirectories)
        Write-Output "$d : $($files.Length) files"
    } else {
        Write-Output "$d does not exist"
    }
}
