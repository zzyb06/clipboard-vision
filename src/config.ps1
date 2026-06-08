# config.ps1
# Loads config.json and validates required fields

$script:ConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "config.json"

function Get-Config {
    if (-not (Test-Path $ConfigPath)) {
        Write-Error "config.json not found at: $ConfigPath"
        exit 1
    }

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    $required = @("api_key", "model", "api_base")
    $missing = $required | Where-Object { -not $config.$_ }
    if ($missing) {
        Write-Error "Missing required config fields: $($missing -join ', ')"
        Write-Error "Run install.ps1 to set up config.json"
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($config.api_key)) {
        Write-Error "api_key is empty. Run install.ps1 to configure."
        exit 1
    }

    return $config
}
