$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$Dest = Join-Path $CodexHome "agents"
$Stamp = Get-Date -Format "yyyyMMddHHmmss"

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Get-ChildItem (Join-Path $Root "agents") -Filter "*.toml" | ForEach-Object {
    $Target = Join-Path $Dest $_.Name
    if (Test-Path $Target) {
        Copy-Item $Target "$Target.bak.$Stamp"
    }
    Copy-Item -Force $_.FullName $Target
    Write-Host "Installed: $Target"
}

Write-Host ""
Write-Host "Custom agents installed. Restart Codex or start a new task."
