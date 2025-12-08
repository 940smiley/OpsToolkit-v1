<#
    bootstrap.ps1
    --------------
    One‑liner bootstrap script for OpsToolkit.

    Features:
      - Downloads OpsToolkit from GitHub
      - Extracts into user profile
      - Registers module path
      - Launches OpsToolkit Launcher
      - Safe, auditable, no elevation required
#>

param(
    [string]$Branch = "main"
)

Write-Host "`n=== OpsToolkit Bootstrap ===" -ForegroundColor Cyan

# Target install directory
$installRoot = Join-Path $env:USERPROFILE "OpsToolkit"
$tempZip     = Join-Path $env:TEMP "OpsToolkit.zip"

# GitHub repo
$repoUrl = "https://github.com/940smiley/OpsToolkit-v1/archive/refs/heads/$Branch.zip"

Write-Host "Downloading OpsToolkit ($Branch branch)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip -UseBasicParsing

Write-Host "Extracting..." -ForegroundColor Cyan
if (Test-Path $installRoot) { Remove-Item $installRoot -Recurse -Force }
Expand-Archive -LiteralPath $tempZip -DestinationPath $env:USERPROFILE -Force

# GitHub zips extract as OpsToolkit-v1-main or OpsToolkit-v1-branch
$extracted = Get-ChildItem $env:USERPROFILE -Directory | Where-Object {
    $_.Name -like "OpsToolkit-v1*"
} | Select-Object -First 1

if (-not $extracted) {
    Write-Host "Extraction failed." -ForegroundColor Red
    exit 1
}

Rename-Item -Path $extracted.FullName -NewName "OpsToolkit" -Force

# Register module path
$modulePath = Join-Path $installRoot "OpsToolkit"
$profilePath = $PROFILE

Write-Host "Registering OpsToolkit module path..." -ForegroundColor Cyan

$importLine = "Import-Module `"$modulePath`" -Force"
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

if (-not (Select-String -Path $profilePath -Pattern "OpsToolkit" -Quiet)) {
    Add-Content -Path $profilePath -Value "`n# OpsToolkit`n$importLine"
}

Write-Host "Launching OpsToolkit..." -ForegroundColor Green

Import-Module "$installRoot\Launcher\OpsToolkitLauncher.psm1" -Force
Start-OpsToolkitLauncher