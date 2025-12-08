<#
    Install-WindowsPackageManager.psm1
    -----------------------------------
    Ensures all dependencies for Windows Package Manager (Winget).
    Features:
      - Installs VCLibs
      - Installs UI.Xaml Framework
      - Installs App Installer (Winget)
      - Verifies installation
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify winget
# -------------------------------
function Test-Winget {
    try {
        $v = & winget --version 2>$null
        return $v -ne $null
    } catch {
        return $false
    }
}

# -------------------------------
# Install MSIX package
# -------------------------------
function Install-MSIX {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        Add-AppxPackage -Path $Path -ForceApplicationShutdown
        return $true
    } catch {
        Write-Host "Failed to install package: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsPackageManager-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    # Package URLs
    $vclibsUrl   = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $xamlUrl     = "https://github.com/microsoft/microsoft-ui-xaml/releases/latest/download/Microsoft.UI.Xaml.2.8.x64.appx"
    $appInstallerUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    # Local paths
    $vclibsPath  = Join-Path $DownloadDir "vclibs.appx"
    $xamlPath    = Join-Path $DownloadDir "xaml.appx"
    $appPath     = Join-Path $DownloadDir "appinstaller.msixbundle"

    Write-Host "Downloading dependencies..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $vclibsUrl -OutFile $vclibsPath -UseBasicParsing
        Invoke-WebRequest -Uri $xamlUrl   -OutFile $xamlPath   -UseBasicParsing
        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $appPath -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Installing VCLibs..." -ForegroundColor Cyan
    if (-not (Install-MSIX -Path $vclibsPath)) { return $false }

    Write-Host "Installing UI.Xaml..." -ForegroundColor Cyan
    if (-not (Install-MSIX -Path $xamlPath)) { return $false }

    Write-Host "Installing App Installer (Winget)..." -ForegroundColor Cyan
    if (-not (Install-MSIX -Path $appPath)) { return $false }

    Write-Host "Verifying Winget..." -ForegroundColor Cyan

    if (-not (Test-Winget)) {
        Write-Host "Winget installation failed or PATH not updated." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Windows Package Manager installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsPackageManager {
    Write-Host "`n=== Install Windows Package Manager (Winget) ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\WinPkgMgr"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling Windows Package Manager..." -ForegroundColor Cyan

    $ok = Install-WindowsPackageManager-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "Windows Package Manager installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Windows Package Manager installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsPackageManager, Install-WindowsPackageManager-Core