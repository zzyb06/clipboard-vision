#!/usr/bin/env pwsh
# start.ps1 — Launch Clipboard Vision monitor

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$monitorPath = Join-Path (Join-Path $ProjectRoot "src") "monitor.ps1"

if (-not (Test-Path $monitorPath)) {
    Write-Host "monitor.ps1 not found at: $monitorPath" -ForegroundColor Red
    exit 1
}

Write-Host "Starting Clipboard Vision monitor..." -ForegroundColor Cyan
Write-Host "Monitor runs in this window. Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

# Run in foreground so user sees logs and can Ctrl+C
& $monitorPath
