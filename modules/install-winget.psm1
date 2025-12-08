<#
    Install-Winget.psm1
    --------------------
    Installs the latest Winget (App Installer) package.
    Features:
      - Downloads latest MSIXBundle
      - Silent install
      - Verifies winget
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify winget
# -------------------------------
function Test-WingetInstall {
    try {
        $wg = & winget --version 2>$null
        return $wg -ne $null
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-Winget-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    $bundlePath = Join-Path $DownloadDir "winget.msixbundle"

    # Official Winget / App Installer package
    $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    Write-Host "Downloading Winget..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $bundlePath -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Installing Winget..." -ForegroundColor Cyan

    try {
        Add-AppxPackage -Path $bundlePath -ForceApplicationShutdown
    } catch {
        Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Verifying installation..." -ForegroundColor Cyan

    if (-not (Test-WingetInstall)) {
        Write-Host "Winget installation failed or PATH not updated." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Winget installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-Winget {
    Write-Host "`n=== Install Winget ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\Winget"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling Winget..." -ForegroundColor Cyan

    $ok = Install-Winget-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "Winget installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Winget installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-Winget, Install-Winget-Core