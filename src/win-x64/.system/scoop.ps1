param
(
    [string] $scoop = ""
)

# If $scoop is empty, set it to default value
if ([string]::IsNullOrEmpty($scoop))
{
    $drive = [System.IO.Path]::GetPathRoot($MyInvocation.MyCommand.Path)    
    $scoop = $drive\scoop
}

# Verify that user running script is an administrator
$IsAdmin=[Security.Principal.WindowsIdentity]::GetCurrent()
If ((New-Object Security.Principal.WindowsPrincipal $IsAdmin).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) -eq $FALSE)
{
    Write-Host "Please DO run scoop installation as administrator." -ForegroundColor Red
    exit 1
}

Write-Host "Installing scoop to custom directory $scoop..." -ForegroundColor Green
$env:SCOOP=$scoop
[environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
