# config.ps1
# Loads config.json and validates required fields

$script:ConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "config.json"

function Get-Config {
    if (-not (Test-Path $ConfigPath)) {
        Write-Error "config.json not found at: $ConfigPath"
        exit 1
    }

    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "config.json is not valid JSON. Run install.ps1 to regenerate it."
        exit 1
    }

    $required = @("api_key", "model", "api_base")
    $missing = $required | Where-Object { [string]::IsNullOrWhiteSpace($config.$_) }
    if ($missing) {
        Write-Error "Missing or empty required config fields: $($missing -join ', ')"
        Write-Error "Run install.ps1 to set up config.json"
        exit 1
    }

    return $config
}
