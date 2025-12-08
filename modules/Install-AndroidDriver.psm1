<#
    Install-AndroidDriver.psm1
    ---------------------------
    Installs the official Google USB Driver for Android devices.
    Features:
      - Downloads latest Google USB driver ZIP
      - Extracts safely
      - Installs via pnputil
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Core logic
# -------------------------------
function Install-AndroidDriver-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    $zipPath = Join-Path $DownloadDir "google_usb_driver.zip"
    $extractDir = Join-Path $DownloadDir "google_usb_driver"

    $url = "https://dl.google.com/android/repository/latest_usb_driver_windows.zip"

    Write-Host "Downloading Google USB Driver..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Extracting..." -ForegroundColor Cyan

    try {
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force
    } catch {
        Write-Host "Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    $inf = Get-ChildItem -Path $extractDir -Filter "*.inf" -Recurse | Select-Object -First 1

    if (-not $inf) {
        Write-Host "Driver INF not found." -ForegroundColor Red
        return $false
    }

    Write-Host "Installing driver via pnputil..." -ForegroundColor Cyan

    try {
        pnputil /add-driver "$($inf.FullName)" /install | Out-Null
    } catch {
        Write-Host "Driver install failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Android driver installed from $($inf.FullName)"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-AndroidDriver {
    Write-Host "`n=== Install Android USB Driver ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\AndroidDriver"
    $dir = Prompt-String -Message "Download/extract directory" -Default $defaultDir

    Write-Host "`nInstalling Android USB driver..." -ForegroundColor Cyan

    $ok = Install-AndroidDriver-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "Android USB driver installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Driver installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-AndroidDriver, Install-AndroidDriver-Core