param
(
    [string]$Title = $null,
    [string]$Ime = "en-US"
)

# Define Win32 API functions
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32
{
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

# If no window title is provided, activate the current window
if ([string]::IsNullOrEmpty($Title))
{
    $hwnd = [Win32]::GetForegroundWindow()
}
else
{
    $hwnd = [Win32]::FindWindow($null, $WindowTitle)
}

# Try to activate the window
if ($hwnd -ne [IntPtr]::Zero)
{
    $result = [Win32]::SetForegroundWindow($hwnd)
}

# Try to setup the IME if need
if (-not [string]::IsNullOrEmpty($Ime))
{
    Add-Type -AssemblyName "System.Windows.Forms"

    $currentInputLanguage = [System.Windows.Forms.InputLanguage]::CurrentInputLanguage
    if ($currentInputLanguage.Culture.Name -ne $Ime)
    {
        $englishInputLanguage = [System.Windows.Forms.InputLanguage]::InstalledInputLanguages | Where-Object { $_.Culture.Name -eq $Ime }
        if ($null -ne $englishInputLanguage)
        {
            [System.Windows.Forms.InputLanguage]::CurrentInputLanguage = $englishInputLanguage
        }
    }
}
