<#
    Install-WindowsDeveloperMode.psm1
    ----------------------------------
    Enables Windows Developer Mode + optional dev features.
    Features:
      - Enables Developer Mode
      - Enables Device Portal (optional)
      - Enables Device Discovery (optional)
      - Installs developer features
      - Verifies configuration
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify Developer Mode
# -------------------------------
function Test-DeveloperMode {
    try {
        $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        return ($reg.AllowDevelopmentWithoutDevLicense -eq 1)
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsDeveloperMode-Core {
    param(
        [switch]$EnableDevicePortal,
        [switch]$EnableDeviceDiscovery
    )

    Write-Host "Enabling Developer Mode..." -ForegroundColor Cyan

    try {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
            -Name "AllowDevelopmentWithoutDevLicense" -Value 1
    } catch {
        Write-Host "Failed to enable Developer Mode: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    if ($EnableDevicePortal) {
        Write-Host "Enabling Device Portal..." -ForegroundColor Cyan
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName "WindowsDevicePortal" -All -NoRestart | Out-Null
        } catch {
            Write-Host "Failed to enable Device Portal: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($EnableDeviceDiscovery) {
        Write-Host "Enabling Device Discovery..." -ForegroundColor Cyan
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName "WindowsDeviceDiscovery" -All -NoRestart | Out-Null
        } catch {
            Write-Host "Failed to enable Device Discovery: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "Verifying Developer Mode..." -ForegroundColor Cyan

    if (-not (Test-DeveloperMode)) {
        Write-Host "Developer Mode failed to enable." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Developer Mode enabled (Portal=$EnableDevicePortal, Discovery=$EnableDeviceDiscovery)"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsDeveloperMode {
    Write-Host "`n=== Enable Windows Developer Mode ===" -ForegroundColor Cyan

    $portal = Prompt-YesNo -Message "Enable Device Portal" -Default $false
    $discover = Prompt-YesNo -Message "Enable Device Discovery" -Default $false

    Write-Host "`nApplying Developer Mode settings..." -ForegroundColor Cyan

    $ok = Install-WindowsDeveloperMode-Core -EnableDevicePortal:$portal -EnableDeviceDiscovery:$discover

    if ($ok) {
        Write-Host "Developer Mode enabled successfully." -ForegroundColor Green
    } else {
        Write-Host "Developer Mode enablement failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsDeveloperMode, Install-WindowsDeveloperMode-Core