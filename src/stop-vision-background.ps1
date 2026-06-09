#!/usr/bin/env pwsh
# stop-vision-background.ps1
# Stops clipboard-vision monitor by PID file

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$pidFile = Join-Path (Join-Path $ProjectRoot "output") "monitor.pid"

if (-not (Test-Path $pidFile)) {
    Write-Host "[Clipboard Vision] Not running (no PID file)"
    exit 0
}

$monitorPid = (Get-Content $pidFile -Raw -Encoding UTF8).Trim()

$proc = Get-Process -Id $monitorPid -ErrorAction SilentlyContinue
if ($proc) {
    Stop-Process -Id $monitorPid -Force -ErrorAction SilentlyContinue
    Write-Host "[Clipboard Vision] Stopped (PID: $monitorPid)"
} else {
    Write-Host "[Clipboard Vision] Process not found (PID: $monitorPid, may have exited)"
}

Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
exit 0
