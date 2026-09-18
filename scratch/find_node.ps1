Write-Output "Env Path: $env:PATH"
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) { Write-Output "Node: $($nodeCmd.Source)" }
$pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue
if ($pnpmCmd) { Write-Output "Pnpm: $($pnpmCmd.Source)" }

$searchPaths = @(
    "C:\Program Files\nodejs",
    "C:\Program Files (x86)\nodejs",
    "$env:APPDATA\npm",
    "$env:LOCALAPPDATA\pnpm",
    "C:\nvm"
)
foreach ($sp in $searchPaths) {
    if (Test-Path $sp) {
        Write-Output "Exists: $sp"
        Get-ChildItem $sp | Select-Object -ExpandProperty Name
    }
}
