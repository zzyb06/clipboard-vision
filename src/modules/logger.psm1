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

    # Trim old entries if exceeding max_history
    $lines = Get-Content $LogPath -Encoding UTF8
    if ($lines.Count -gt ($MaxHistory * 5 + 10)) {
        # Keep the header line + recent entries
        $header = $lines[0]
        $recentLines = $lines[-1..(-($MaxHistory * 5))] | Where-Object { $_ -ne $null }
        $header, "", $recentLines | Set-Content $LogPath -Encoding UTF8
    }
}

Export-ModuleMember -Function Write-VisionLog
