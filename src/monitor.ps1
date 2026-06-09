#!/usr/bin/env pwsh
# monitor.ps1 - Clipboard Vision main loop
# Watches clipboard for images and processes them via Vision API
# Works regardless of whether Claude Code is the active window

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
$outputDir = Join-Path $ProjectRoot $config.output_dir
$imagesDir = Join-Path $outputDir "images"
$logPath = Join-Path $outputDir "vision_log.md"
$flagPath = Join-Path $outputDir "new_image.flag"
if (-not (Test-Path $imagesDir)) { New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null }

# === State ===
$script:lastClipboardHash = ""    # hash of image currently on clipboard
$script:cachedImageHash  = ""     # hash of cached image waiting to be processed
$script:cachedImagePath  = ""     # path to cached image file
$script:lastProcessedHash = ""    # hash of last image sent to API
$script:isProcessing = $false     # API call in flight

Write-Host "[Clipboard Vision] Started - polling every $($config.poll_interval_ms)ms"
Write-Host "[Clipboard Vision] Always watching clipboard, processing when Claude Code is active"
Write-Host "[Clipboard Vision] Press Ctrl+C to stop"

# Trap Ctrl+C for clean exit
try { [Console]::TreatControlCAsInput = $true } catch {}

while ($true) {
    Start-Sleep -Milliseconds $config.poll_interval_ms

    # === Check for Ctrl+C ===
    $gotCtrlC = $false
    try {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Modifiers -band [ConsoleModifiers]'Control' -and $key.Key -eq 'C') {
                $gotCtrlC = $true
            }
        }
    } catch { }
    if ($gotCtrlC) {
        Write-Host "`n[Clipboard Vision] Stopped."
        exit 0
    }

    # === Step 1: Always check clipboard for new images ===
    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
        $image = Get-ClipboardImage
        if ($image) {
            $hash = Get-ImageHash -Image $image

            # Only cache if this is a genuinely new image
            if ($hash -ne $script:lastClipboardHash -and `
                $hash -ne $script:cachedImageHash -and `
                $hash -ne $script:lastProcessedHash) {

                $saved = Save-ClipboardImage -Image $image -OutputDir $imagesDir
                $script:cachedImageHash = $hash
                $script:cachedImagePath = $saved.Path
                # Raise flag for Claude Code
                Set-Content -Path $flagPath -Value "pending" -Encoding UTF8 -NoNewline
                Write-Host "[Clipboard Vision] New image cached (hash: $($hash.Substring(0,8)))"
            }
            $script:lastClipboardHash = $hash
            $image.Dispose()
        }
    }

    # === Step 2: Process cached image if Claude Code is active ===
    $isActive = Test-IsClaudeCodeActive -Keywords $config.claude_code_window_keywords

    if ($isActive -and $script:cachedImageHash -and -not $script:isProcessing) {
        if ($script:cachedImageHash -ne $script:lastProcessedHash) {
            $script:isProcessing = $true
            Write-Host "[Clipboard Vision] Processing cached image (hash: $($script:cachedImageHash.Substring(0,8)))..."

            try {
                $result = Send-DoubaoVisionRequest -ImagePath $script:cachedImagePath `
                    -Model $config.model `
                    -ApiBase $config.api_base `
                    -ApiKey $config.api_key `
                    -SystemPrompt $config.system_prompt

                if ($result -notmatch '^\[API Error\]') {
                    # Write to both log files
                    Write-VisionLog -LogPath $logPath `
                        -ImageFilename (Split-Path $script:cachedImagePath -Leaf) `
                        -Content $result `
                        -MaxHistory $config.max_history
                    Write-LatestVision -OutputDir $outputDir `
                        -ImageFilename (Split-Path $script:cachedImagePath -Leaf) `
                        -Content $result

                    $script:lastProcessedHash = $script:cachedImageHash
                    # Clear flag: processing complete
                    if (Test-Path $flagPath) { Remove-Item $flagPath -Force }
                    Write-Host "[Clipboard Vision] Result written"
                } else {
                    Write-Host "[Clipboard Vision] $result" -ForegroundColor Red
                }
            } catch {
                Write-Host "[Clipboard Vision] Error: $($_.Exception.Message)" -ForegroundColor Red
            } finally {
                $script:isProcessing = $false
                if ($script:lastProcessedHash -eq $script:cachedImageHash) {
                    $script:cachedImageHash = ""
                    $script:cachedImagePath = ""
                }
            }
        } else {
            $script:cachedImageHash = ""
            $script:cachedImagePath = ""
        }
    }
}
