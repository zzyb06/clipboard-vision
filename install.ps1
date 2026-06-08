#!/usr/bin/env pwsh
# install.ps1 — Install and configure Clipboard Vision

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$configPath = Join-Path $ProjectRoot "config.json"

Write-Host "=== Clipboard Vision Installer ===" -ForegroundColor Cyan
Write-Host ""

# Check if config already has an API key
$existingKey = ""
if (Test-Path $configPath) {
    $existing = Get-Content $configPath -Raw | ConvertFrom-Json
    $existingKey = $existing.api_key
}

# 1. API Key
if ($existingKey) {
    Write-Host "Existing API Key found: $($existingKey.Substring(0,8))..." -ForegroundColor Green
    $change = Read-Host "Change it? (y/N)"
    if ($change -eq 'y') { $existingKey = "" }
}

if (-not $existingKey) {
    Write-Host "Enter your 豆包/火山引擎 API Key:" -ForegroundColor Yellow
    $apiKey = Read-Host -MaskInput
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host "API Key is required. Aborting." -ForegroundColor Red
        exit 1
    }
    $existingKey = $apiKey
}

# 2. Model name
Write-Host ""
Write-Host "Enter your 豆包视觉模型名称 (e.g., doubao-vision-pro-32k):" -ForegroundColor Yellow
$model = Read-Host "Model"
if ([string]::IsNullOrWhiteSpace($model)) { $model = "doubao-vision-pro-32k" }

# 3. Build config
$config = @{
    api_key = $existingKey
    model   = $model
    api_base = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
    system_prompt = "你是一个视觉识别模块，请详细描述这张图片的内容，包括其中的文字、布局、颜色等关键信息。"
    poll_interval_ms = 2000
    claude_code_window_keywords = @("Claude Code", "claude")
    output_dir = "output"
    max_history = 100
}

$config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
Write-Host ""
Write-Host "Config saved to $configPath" -ForegroundColor Green

# 4. Test API connection
Write-Host ""
Write-Host "Testing API connection..." -ForegroundColor Yellow
$testBody = @{
    model = $model
    messages = @(@{ role = "user"; content = "Hello" })
    max_tokens = 10
} | ConvertTo-Json

try {
    $headers = @{ "Authorization" = "Bearer $existingKey"; "Content-Type" = "application/json" }
    $response = Invoke-RestMethod -Uri $config.api_base -Method Post -Headers $headers -Body $testBody -TimeoutSec 15
    Write-Host "API connection OK!" -ForegroundColor Green
} catch {
    Write-Host "API connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your API Key and model name, then re-run install.ps1" -ForegroundColor Yellow
}

# 5. Optional startup
Write-Host ""
$startup = Read-Host "Add to startup (auto-start on login)? (y/N)"
if ($startup -eq 'y') {
    $startupPath = [Environment]::GetFolderPath("Startup")
    $lnkPath = Join-Path $startupPath "ClipboardVision.lnk"
    $wshell = New-Object -ComObject WScript.Shell
    $shortcut = $wshell.CreateShortcut($lnkPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = '-WindowStyle Hidden -File "' + (Join-Path $ProjectRoot 'src\monitor.ps1') + '"'
    $shortcut.Save()
    Write-Host "Startup shortcut created." -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host "Run .\start.ps1 to start monitoring." -ForegroundColor Cyan

