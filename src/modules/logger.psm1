# logger.psm1
# Vision log writer — markdown format with history management

function Write-VisionLog {
    param(
        [string]$LogPath,
        [string]$ImageFilename,
        [string]$Content,
        [int]$MaxHistory = 100
    )

    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = @"

## $timestamp | $ImageFilename
---
$Content
---
"@

    Add-Content -Path $LogPath -Value $entry -Encoding UTF8

    # Trim old entries: count "## " lines; if > MaxHistory, keep only recent ones
    $allLines = Get-Content $LogPath -Encoding UTF8
    $headerLines = @()
    $entryLines = @()
    $currentEntry = @()
    $inHeader = $true
    $entryCount = 0

    foreach ($line in $allLines) {
        if ($line -match '^## ') {
            $entryCount++
            if ($inHeader) {
                $inHeader = $false
            } else {
                # Save previous entry
                if ($currentEntry.Count -gt 0) {
                    $entryLines += ,@($currentEntry)
                }
            }
            $currentEntry = @($line)
        } elseif ($inHeader) {
            $headerLines += $line
        } else {
            $currentEntry += $line
        }
    }
    # Save last entry
    if ($currentEntry.Count -gt 0) {
        $entryLines += ,@($currentEntry)
    }

    if ($entryCount -gt $MaxHistory) {
        $keep = $entryLines[-$MaxHistory..-1]
        $output = @($headerLines -join "`n")
        foreach ($e in $keep) {
            $output += $e -join "`n"
        }
        $output -join "`n" | Set-Content $LogPath -Encoding UTF8
    }
}

Export-ModuleMember -Function Write-VisionLog
