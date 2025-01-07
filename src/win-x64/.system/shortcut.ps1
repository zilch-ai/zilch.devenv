param
(
    [string]$shortcut,
    [string]$target,
    [string]$arguments = $null,
    [string]$location = $null,
    [string]$icon = $null,
    [string]$desktop = $null,
    [switch]$admin = $false
)

Write-Host "Shortcut: $shortcut" -ForegroundColor Yellow
Write-Host "Target: $target" -ForegroundColor Yellow
Write-Host "Args: $arguments" -ForegroundColor Yellow
Write-Host "Location: $location" -ForegroundColor Yellow
Write-Host "Icon: $icon" -ForegroundColor Yellow
Write-Host "Desktop: $desktop" -ForegroundColor Yellow
Write-Host "Admin: $admin" -ForegroundColor Yellow

# Check if shortcut name is null
if (-not $shortcut)
{
    Write-Error "Empty shortcut name: $shortcut."
    exit 1
}

# Check if target path exists
if (-not (Test-Path $target))
{
    Write-Error "Target path does not exist: $target."
    exit 1
}

# Warn if icon file is not specified, and skip icon setting
if ($icon -and -not (Test-Path $icon))
{
    Write-Host "Icon file does not exist: $icon." -ForegroundColor Yellow
    $icon = $null
}

# Use target directory as default working directory if not specified
if (-not $location)
{
    $location = [System.IO.Path]::GetDirectoryName($target)
}

# Use Desktop as default shortcut directory if not specified
if (-not $desktop)
{
    $desktop = [System.Environment]::GetFolderPath('Desktop')
}

try
{
    $shortcutFile = Join-Path $desktop "$shortcut.lnk"
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcutLink = $wshShell.CreateShortcut($shortcutFile)
    $shortcutLink.TargetPath = $target
    $shortcutLink.WorkingDirectory = $location
    if ($arguments)
    {
        $shortcutLink.Arguments = $arguments
    }
    if ($icon)
    {
        $shortcutLink.IconLocation = "$icon, 0"
    }
    $shortcutLink.Save()
    Write-Host "Shortcut created at: $shortcutFile" -ForegroundColor Green
}
catch
{
    Write-Error "Failed to create shortcut. $_"
    exit 1
}

# Enable "Run as Administrator" if need
if ($admin)
{
    try 
    {
        # Set the shortcut's extended properties to run as administrator    
        $Bytes = [System.IO.File]::ReadAllBytes($shortcutFile)
        $Bytes[21] = $Bytes[21] -bor 0x20
        [System.IO.File]::WriteAllBytes($shortcutFile, $Bytes)
        Write-Host "The shortcut is set to run as Administrator by default." -ForegroundColor Green
    }
    catch
    {
        Write-Error "Failed to enable admin mode for the shortcut. $_"
    }
}
