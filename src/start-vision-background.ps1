#!/usr/bin/env pwsh
# start-vision-background.ps1
# Starts clipboard-vision monitor in a hidden window with PID tracking
# Designed to be called from Claude Code SessionStart hook

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$monitorPath = Join-Path (Join-Path $ProjectRoot "src") "monitor.ps1"
$pidDir = Join-Path $ProjectRoot "output"
$pidFile = Join-Path $pidDir "monitor.pid"

if (-not (Test-Path $pidDir)) {
    New-Item -ItemType Directory -Path $pidDir -Force | Out-Null
}

# Check if already running via PID file
if (Test-Path $pidFile) {
    $monitorPid = (Get-Content $pidFile -Raw -Encoding UTF8).Trim()
    $alreadyRunning = Get-Process -Id $monitorPid -ErrorAction SilentlyContinue
    if ($alreadyRunning) {
        Write-Host "[Clipboard Vision] Already running (PID: $monitorPid)"
        exit 0
    }
    # Stale PID file, clean it up
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

# Launch monitor in hidden window
$proc = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$monitorPath`"" -WindowStyle Hidden -PassThru

# Save PID for later cleanup
    $monitorPid = $proc.Id
    $monitorPid | Out-File -FilePath $pidFile -Encoding UTF8

Write-Host "[Clipboard Vision] Started in background (PID: $monitorPid)"
exit 0
