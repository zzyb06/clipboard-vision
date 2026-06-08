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
    $Image.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ms.Close()
    $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
    return [BitConverter]::ToString($hash) -replace '-', ''
}

function Save-ClipboardImage {
    param(
        [System.Drawing.Image]$Image,
        [string]$OutputDir
    )
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "clip_$timestamp.png"
    $path = Join-Path $OutputDir $filename
    $Image.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    return @{ Path = $path; Filename = $filename }
}

function Get-ImageBase64 {
    param([string]$ImagePath)
    $bytes = [System.IO.File]::ReadAllBytes($ImagePath)
    return [Convert]::ToBase64String($bytes)
}

Export-ModuleMember -Function Get-ClipboardImage, Get-ImageHash, Save-ClipboardImage, Get-ImageBase64
