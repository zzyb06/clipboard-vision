$files = @(
    'D:\APPtest1\clipboard-vision\src\config.ps1',
    'D:\APPtest1\clipboard-vision\src\modules\window.psm1',
    'D:\APPtest1\clipboard-vision\src\modules\clipboard.psm1',
    'D:\APPtest1\clipboard-vision\src\modules\vision_api.psm1',
    'D:\APPtest1\clipboard-vision\src\modules\logger.psm1',
    'D:\APPtest1\clipboard-vision\src\monitor.ps1',
    'D:\APPtest1\clipboard-vision\install.ps1',
    'D:\APPtest1\clipboard-vision\start.ps1'
)
$allOk = $true
foreach ($f in $files) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        Write-Host "FAIL: $f" -ForegroundColor Red
        foreach ($e in $errors) { Write-Host "  $($e.Message) at line $($e.Extent.StartLine)" -ForegroundColor Red }
        $allOk = $false
    } else {
        Write-Host "PASS: $f" -ForegroundColor Green
    }
}
if ($allOk) { Write-Host "`nAll files pass syntax check!" -ForegroundColor Green }
else { Write-Host "`nSome files have syntax errors!" -ForegroundColor Red }
