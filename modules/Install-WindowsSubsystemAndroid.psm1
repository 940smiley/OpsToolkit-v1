<#
    Install-WindowsSubsystemAndroid.psm1
    -------------------------------------
    Installs Windows Subsystem for Android (WSA) + Amazon Appstore.
    Features:
      - Enables virtualization features
      - Installs WSA MSIXBundle
      - Installs Amazon Appstore
      - Verifies installation
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify WSA
# -------------------------------
function Test-WSA {
    try {
        $pkg = Get-AppxPackage -Name "MicrosoftCorporationII.WindowsSubsystemForAndroid" -ErrorAction Stop
        return $pkg -ne $null
    } catch {
        return $false
    }
}

# -------------------------------
# Enable virtualization features
# -------------------------------
function Enable-VirtualizationFeatures {
    Write-Host "Enabling virtualization features..." -ForegroundColor Cyan

    try {
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
        dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
        return $true
    } catch {
        Write-Host "Failed to enable virtualization features: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsSubsystemAndroid-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    if (-not (Enable-VirtualizationFeatures)) {
        return $false
    }

    # URLs
    $wsaUrl = "https://aka.ms/WSA"
    $amazonUrl = "https://www.microsoft.com/store/productId/9NJHK44TTKSX"

    # Local paths
    $wsaBundle = Join-Path $DownloadDir "wsa.msixbundle"

    Write-Host "Downloading Windows Subsystem for Android..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $wsaUrl -OutFile $wsaBundle -UseBasicParsing
    } catch {
        Write-Host "WSA download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Installing Windows Subsystem for Android..." -ForegroundColor Cyan

    try {
        Add-AppxPackage -Path $wsaBundle -ForceApplicationShutdown
    } catch {
        Write-Host "WSA installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Installing Amazon Appstore (opens Microsoft Store)..." -ForegroundColor Cyan
    Start-Process $amazonUrl

    Write-Host "Verifying WSA installation..." -ForegroundColor Cyan

    if (-not (Test-WSA)) {
        Write-Host "WSA installation failed." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "WSA installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsSubsystemAndroid {
    Write-Host "`n=== Install Windows Subsystem for Android ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\WSA"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling Windows Subsystem for Android..." -ForegroundColor Cyan

    $ok = Install-WindowsSubsystemAndroid-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "WSA installed successfully." -ForegroundColor Green
        Write-Host "Amazon Appstore window should now be open."
    } else {
        Write-Host "WSA installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsSubsystemAndroid, Install-WindowsSubsystemAndroid-Core