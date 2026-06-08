# window.psm1
# Detects foreground window and checks if Claude Code is active

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
}
"@

function Get-ForegroundWindowTitle {
    $hwnd = [WindowHelper]::GetForegroundWindow()
    $sb = New-Object System.Text.StringBuilder 256
    [WindowHelper]::GetWindowText($hwnd, $sb, 256) | Out-Null
    return $sb.ToString()
}

function Test-IsClaudeCodeActive {
    param([string[]]$Keywords)
    $title = Get-ForegroundWindowTitle
    if ([string]::IsNullOrWhiteSpace($title)) { return $false }
    foreach ($kw in $Keywords) {
        if ($title -match [regex]::Escape($kw)) { return $true }
    }
    return $false
}

Export-ModuleMember -Function Get-ForegroundWindowTitle, Test-IsClaudeCodeActive
