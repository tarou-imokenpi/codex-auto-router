$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$Dest = Join-Path $CodexHome "agents"
$Config = Join-Path $CodexHome "config.toml"
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

if (Test-Path $Config) {
    Copy-Item $Config "$Config.bak.$Stamp"
    $Lines = [System.Collections.Generic.List[string]](Get-Content $Config)
} else {
    $Lines = [System.Collections.Generic.List[string]]::new()
}

$AgentStart = -1
$AgentEnd = $Lines.Count
for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^\s*\[agents\]\s*$') {
        $AgentStart = $i
        for ($j = $i + 1; $j -lt $Lines.Count; $j++) {
            if ($Lines[$j] -match '^\s*\[[^]]+\]\s*$') {
                $AgentEnd = $j
                break
            }
        }
        break
    }
}

if ($AgentStart -lt 0) {
    if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne "") { $Lines.Add("") }
    $Lines.Add("[agents]")
    $Lines.Add("max_threads = 6")
    $Lines.Add("max_depth = 2")
} else {
    $DepthIndex = -1
    $ThreadsIndex = -1
    for ($i = $AgentStart + 1; $i -lt $AgentEnd; $i++) {
        if ($Lines[$i] -match '^\s*max_depth\s*=\s*(\d+)') {
            $DepthIndex = $i
            if ([int]$Matches[1] -lt 2) { $Lines[$i] = "max_depth = 2" }
        }
        if ($Lines[$i] -match '^\s*max_threads\s*=') { $ThreadsIndex = $i }
    }
    $InsertAt = $AgentStart + 1
    if ($ThreadsIndex -lt 0) {
        $Lines.Insert($InsertAt, "max_threads = 6")
        $InsertAt++
        if ($DepthIndex -ge $InsertAt) { $DepthIndex++ }
    }
    if ($DepthIndex -lt 0) {
        $Lines.Insert($InsertAt, "max_depth = 2")
    }
}

Set-Content -Path $Config -Value $Lines -Encoding UTF8
Write-Host ""
Write-Host "Configured nested custom agents in: $Config"
Write-Host "Required: [agents] max_depth >= 2"
Write-Host "Restart the ChatGPT desktop app or start a new Codex task so the custom-agent registry reloads."
Write-Host "Then run: ./scripts/verify-install.ps1"
