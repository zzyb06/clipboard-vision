# clipboard.psm1
# Clipboard image retrieval, hashing, and saving

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-ClipboardImage {
    try {
        $img = [System.Windows.Forms.Clipboard]::GetImage()
        return $img
    } catch {
        return $null
    }
}

function Get-ImageHash {
    param([System.Drawing.Image]$Image)
    if (-not $Image) { return "" }

    $ms = New-Object System.IO.MemoryStream
    try {
        $Image.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $bytes = $ms.ToArray()
    } finally {
        $ms.Close()
    }

    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $hash = $md5.ComputeHash($bytes)
        return [BitConverter]::ToString($hash) -replace '-', ''
    } finally {
        $md5.Dispose()
    }
}

function Save-ClipboardImage {
    param(
        [System.Drawing.Image]$Image,
        [string]$OutputDir
    )

    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmssfff"
    $filename = "clip_$timestamp.png"
    $path = Join-Path $OutputDir $filename
    $Image.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    return @{ Path = $path; Filename = $filename }
}

function Get-ImageBase64 {
    param([string]$ImagePath)
    if (-not (Test-Path $ImagePath)) {
        return ""
    }
    $bytes = [System.IO.File]::ReadAllBytes($ImagePath)
    return [Convert]::ToBase64String($bytes)
}

Export-ModuleMember -Function Get-ClipboardImage, Get-ImageHash, Save-ClipboardImage, Get-ImageBase64
