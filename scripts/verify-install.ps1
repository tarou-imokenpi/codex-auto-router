$ErrorActionPreference = "Stop"

$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$Config = Join-Path $CodexHome "config.toml"
$Failed = $false

$Expected = @{
    "terra-explorer.toml" = "gpt-5.6-terra"
    "terra-reviewer.toml" = "gpt-5.6-terra"
    "terra-worker.toml" = "gpt-5.6-terra"
    "spark-scanner.toml" = "gpt-5.3-codex-spark"
    "luna-scanner.toml" = "gpt-5.6-luna"
    "luna-verifier.toml" = "gpt-5.6-luna"
}

foreach ($Name in $Expected.Keys) {
    $Path = Join-Path (Join-Path $CodexHome "agents") $Name
    if (-not (Test-Path $Path)) {
        Write-Host "MISSING: $Path"
        $Failed = $true
        continue
    }
    $Text = Get-Content -Raw $Path
    $Model = [regex]::Escape($Expected[$Name])
    if ($Text -notmatch "(?m)^\s*model\s*=\s*`"$Model`"") {
        Write-Host "WRONG MODEL: $Path (expected $($Expected[$Name]))"
        $Failed = $true
        continue
    }
    Write-Host "OK: $Name -> $($Expected[$Name])"
}

if (-not (Test-Path $Config)) {
    Write-Host "MISSING: $Config"
    $Failed = $true
} else {
    $Text = Get-Content -Raw $Config
    $Match = [regex]::Match($Text, '(?ms)^\s*\[agents\]\s*$.*?^\s*max_depth\s*=\s*(\d+)')
    if (-not $Match.Success -or [int]$Match.Groups[1].Value -lt 2) {
        Write-Host "INVALID: [agents] max_depth must be >= 2 in $Config"
        $Failed = $true
    } else {
        Write-Host "OK: agents.max_depth=$($Match.Groups[1].Value)"
    }
}

if ($Failed) {
    Write-Host ""
    Write-Host "Auto Router setup is incomplete. Run ./scripts/install-agents.ps1 and restart Codex."
    exit 1
}

Write-Host ""
Write-Host "Installation files are correct. Spark account/session availability is checked at runtime; Luna Scanner is the fallback."
Write-Host "Restart Codex or start a new task before testing @Auto Router."
