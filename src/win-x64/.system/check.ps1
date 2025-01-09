param
(
    [string]$instruction,
    [switch]$cmd = $false,
    [string]$prompt = $null,
    [switch]$color = $true,
    [switch]$debug = $false
)

if($prompt)
{
    Write-Host "$prompt" -NoNewline
}

$exit = 1
if($cmd)
{
    if($debug)
    {
        Write-Host
        Write-Host "[DEBUG] Command: $instruction 2>&1" -ForegroundColor: Yellow
    }
    $output = cmd /c "$instruction 2>&1" | Out-String
    $exit = $LASTEXITCODE
    if($debug)
    {
        Write-Host "[DEBUG] Output: $output" -ForegroundColor Yellow
        Write-Host "[DEBUG] Exit: $exit" -ForegroundColor Yellow
    }
}
else
{
    if($debug)
    {
        Write-Host
        Write-Host "[DEBUG] Invoke: $instruction 2>&1" -ForegroundColor Yellow
    }
    $output = Invoke-Expression "$instruction 2>&1" | Out-String
    $exit = $LASTEXITCODE
    if($debug)
    {
        Write-Host "[DEBUG] Output: $output" -ForegroundColor Yellow
        Write-Host "[DEBUG] Exit: $exit" -ForegroundColor Yellow
    }
}

if($prompt)
{
    $message = if ($exit -eq 0) { "OK" } else { "FAILED" }
    $foreground = if ($exit -eq 0) { "Green" } else { "Red" }
    if ($color)
    {
        Write-Host $message -ForegroundColor $foreground
    }
    else
    {
        Write-Host $message
    }
}

exit $exit
