<#
    Install-WindowsPrivacySettings.psm1
    ------------------------------------
    Applies privacy‑focused registry and service settings.
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Set-PrivacyReg {
    param([string]$Path, [string]$Name, [object]$Value)

    try {
        New-Item -Path $Path -Force | Out-Null
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-ModuleLog "Privacy setting applied: $Path -> $Name=$Value"
    } catch {
        Write-Host "Failed: $Path $Name" -ForegroundColor Red
    }
}

function Install-WindowsPrivacySettings-Core {

    Write-Host "Applying privacy settings..." -ForegroundColor Cyan

    # Disable telemetry
    Set-PrivacyReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0

    # Disable advertising ID
    Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0

    # Disable location tracking
    Set-PrivacyReg "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" "Status" 0

    # Disable tailored experiences
    Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0

    Write-Host "Privacy settings applied." -ForegroundColor Green
    return $true
}

function Install-WindowsPrivacySettings {
    Install-WindowsPrivacySettings-Core
}

Export-ModuleMember -Function Install-WindowsPrivacySettings, Install-WindowsPrivacySettings-Core