# Install.ps1
# Installs Find-History into the PowerShell profile

$scriptName = "PowerShell-Advanced-History.ps1"
$scriptSource = Join-Path $PSScriptRoot "PowerShell\$scriptName"

if (-not (Test-Path $scriptSource)) {
    Write-Host "Error: $scriptSource not found." -ForegroundColor Red
    Write-Host "Run this script from the repository root." -ForegroundColor Red
    exit 1
}

# Installation directory
$installDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "PowerShell\Scripts"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Copy the script
$installPath = Join-Path $installDir $scriptName
Copy-Item -Path $scriptSource -Destination $installPath -Force
Write-Host "Script copied to: $installPath" -ForegroundColor Green

# Add to PowerShell profile
$profilePath = $PROFILE.CurrentUserCurrentHost

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "PowerShell profile created: $profilePath" -ForegroundColor Yellow
}

$sourceLine = ". `"$installPath`""

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -and $profileContent.Contains($sourceLine)) {
    Write-Host "Already present in profile. Nothing to add." -ForegroundColor DarkGray
} else {
    Add-Content -Path $profilePath -Value "`n# PowerShell-Advanced-History: interactive history search (Ctrl+H)`n$sourceLine"
    Write-Host "Line added to profile: $profilePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host "Restart PowerShell or run:" -ForegroundColor Gray
Write-Host "  . `"$installPath`"" -ForegroundColor White
Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  Ctrl+H  -  Interactive search (injects directly onto the prompt)" -ForegroundColor White
Write-Host "  pah     -  Interactive search (copies to clipboard)" -ForegroundColor White
