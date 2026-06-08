# vision_api.psm1
# Calls 豆包/火山引擎 Vision API with image

function Send-DoubaoVisionRequest {
    param(
        [string]$ImagePath,
        [string]$Model,
        [string]$ApiBase,
        [string]$ApiKey,
        [string]$SystemPrompt
    )

    $base64 = Get-ImageBase64 -ImagePath $ImagePath
    if ([string]::IsNullOrEmpty($base64)) {
        return "[API Error] 无法读取图片文件: $ImagePath"
    }
    $dataUrl = "data:image/png;base64,$base64"

    $body = @{
        model = $Model
        messages = @(
            @{
                role = "system"
                content = $SystemPrompt
            }
            @{
                role = "user"
                content = @(
                    @{ type = "image_url"; image_url = @{ url = $dataUrl } }
                )
            }
        )
        max_tokens = 2048
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type"  = "application/json"
    }

    $lastError = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $ApiBase -Method Post `
                -Headers $headers -Body $body -ContentType "application/json" `
                -TimeoutSec 30
            return $response.choices[0].message.content
        } catch {
            $lastError = $_
            $statusCode = $_.Exception.Response.StatusCode.value__

            # Don't retry client errors (4xx) — they're permanent
            if ($statusCode -ge 400 -and $statusCode -lt 500) {
                return "[API Error] 请求被拒绝 (HTTP $statusCode): $($_.Exception.Message)"
            }

            # Retry server errors and network issues (5xx, timeout, etc.)
            if ($attempt -lt 3) {
                Start-Sleep -Seconds ([Math]::Min($attempt * 3, 10))
            }
        }
    }

    return "[API Error] 请求失败（已重试3次）: $($lastError.Exception.Message)"
}
