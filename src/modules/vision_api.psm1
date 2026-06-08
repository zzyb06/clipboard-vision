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
    # Retry up to 2 times
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $ApiBase -Method Post `
                -Headers $headers -Body $body -ContentType "application/json" `
                -TimeoutSec 30
            return $response.choices[0].message.content
        } catch {
            $lastError = $_
            if ($attempt -lt 3) {
                Start-Sleep -Seconds 3
            }
        }
    }

    # All retries failed
    return "[API Error] 请求失败（已重试3次）: $($lastError.Exception.Message)"
}
