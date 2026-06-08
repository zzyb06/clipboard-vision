#!/usr/bin/env pwsh
# monitor.ps1 — Clipboard Vision main loop
# Watches clipboard for images when Claude Code is active

# Resolve project root (parent of src/)
$ProjectRoot = Split-Path $PSScriptRoot -Parent

# Load config
. (Join-Path $PSScriptRoot "config.ps1")
$config = Get-Config

# Load modules
Import-Module (Join-Path $PSScriptRoot "modules\window.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "modules\clipboard.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "modules\vision_api.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "modules\logger.psm1") -Force

# Resolve output paths
$imagesDir = Join-Path $ProjectRoot $config.output_dir "images"
$logPath = Join-Path $ProjectRoot $config.output_dir "vision_log.md"
if (-not (Test-Path $imagesDir)) { New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null }

# State
$script:lastImageHash = ""
$script:isProcessing = $false

Write-Host "[Clipboard Vision] Started — polling every $($config.poll_interval_ms)ms"
Write-Host "[Clipboard Vision] Checking for keywords: $($config.claude_code_window_keywords -join ', ')"
Write-Host "[Clipboard Vision] Press Ctrl+C to stop"

# Trap Ctrl+C for clean exit
[Console]::TreatControlCAsInput = $true

while ($true) {
    # Check for Ctrl+C
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Modifiers -band [ConsoleModifiers]'Control' -and $key.Key -eq 'C') {
            Write-Host "`n[Clipboard Vision] Stopped."
            exit 0
        }
    }

    # 1. Skip if API call in flight
    if ($script:isProcessing) {
        Start-Sleep -Milliseconds $config.poll_interval_ms
        continue
    }

    # 2. Check if Claude Code is active
    $isActive = Test-IsClaudeCodeActive -Keywords $config.claude_code_window_keywords
    if (-not $isActive) {
        Start-Sleep -Milliseconds $config.poll_interval_ms
        continue
    }

    # 3. Get clipboard image
    $image = Get-ClipboardImage
    if (-not $image) {
        Start-Sleep -Milliseconds $config.poll_interval_ms
        continue
    }

    # 4. Deduplicate by hash
    $hash = Get-ImageHash -Image $image
    if ($hash -eq $script:lastImageHash) {
        $image.Dispose()
        Start-Sleep -Milliseconds $config.poll_interval_ms
        continue
    }

    # 5. Process the new image
    $script:isProcessing = $true
    Write-Host "[Clipboard Vision] New image detected (hash: $($hash.Substring(0,8)))..."

    try {
        $saved = Save-ClipboardImage -Image $image -OutputDir $imagesDir
        $result = Send-DoubaoVisionRequest -ImagePath $saved.Path `
            -Model $config.model `
            -ApiBase $config.api_base `
            -ApiKey $config.api_key `
            -SystemPrompt $config.system_prompt

        # Only advance hash on successful API response
        if ($result -notmatch '^\[API Error\]') {
            Write-VisionLog -LogPath $logPath `
                -ImageFilename $saved.Filename `
                -Content $result `
                -MaxHistory $config.max_history

            $script:lastImageHash = $hash
            Write-Host "[Clipboard Vision] Result written to $logPath"
        } else {
            Write-Host "[Clipboard Vision] $result" -ForegroundColor Red
            # Don't advance hash — will retry same image next time
        }
    } catch {
        Write-Host "[Clipboard Vision] Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        # Don't advance hash — will retry same image next time
    } finally {
        $image.Dispose()
        $script:isProcessing = $false
    }
}
