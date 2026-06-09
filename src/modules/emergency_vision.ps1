#!/usr/bin/env pwsh
# emergency_vision.ps1 — Immediate clipboard image processing
# Called by Claude Code as fallback when monitor misses an image.
# Saves clipboard image and calls Vision API synchronously.

$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path (Split-Path $PSScriptRoot -Parent) "config.ps1")
$config = Get-Config

Import-Module (Join-Path $PSScriptRoot "clipboard.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "vision_api.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "logger.psm1") -Force

$outputDir = Join-Path $ProjectRoot $config.output_dir
$imagesDir = Join-Path $outputDir "images"
if (-not (Test-Path $imagesDir)) { New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null }

if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
    Write-Output "ERROR: No image on clipboard"
    exit 1
}

$image = Get-ClipboardImage
if (-not $image) {
    Write-Output "ERROR: Failed to get clipboard image"
    exit 1
}

$hash = Get-ImageHash -Image $image
$saved = Save-ClipboardImage -Image $image -OutputDir $imagesDir
$image.Dispose()

Write-Output "Processing clipboard image: $($saved.Filename)"

$result = Send-DoubaoVisionRequest -ImagePath $saved.Path `
    -Model $config.model `
    -ApiBase $config.api_base `
    -ApiKey $config.api_key `
    -SystemPrompt $config.system_prompt

if ($result -match '^\[API Error\]') {
    Write-Output "ERROR: $result"
    exit 1
}

$logPath = Join-Path $outputDir "vision_log.md"
Write-VisionLog -LogPath $logPath `
    -ImageFilename $saved.Filename `
    -Content $result `
    -MaxHistory $config.max_history
Write-LatestVision -OutputDir $outputDir `
    -ImageFilename $saved.Filename `
    -Content $result

# Save hash so monitor doesn't re-process this image on next startup
$hashPath = Join-Path $outputDir ".last_hash"
$hash | Set-Content -Path $hashPath -Encoding UTF8 -NoNewline

Write-Output "SUCCESS: Result written to $outputDir"
