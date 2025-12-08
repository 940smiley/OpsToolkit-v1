<#
    Install-WindowsSubsystemLinux.psm1
    -----------------------------------
    Installs WSL + WSL2 + a Linux distro.
    Features:
      - Enables required Windows features
      - Installs WSL + WSL2
      - Installs user-selected distro
      - Verifies installation
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify WSL
# -------------------------------
function Test-WSL {
    try {
        $v = & wsl --version 2>$null
        return $v -ne $null
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsSubsystemLinux-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Distro
    )

    Write-Host "Enabling WSL optional components..." -ForegroundColor Cyan

    try {
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    } catch {
        Write-Host "Failed to enable WSL features: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Installing WSL..." -ForegroundColor Cyan

    try {
        wsl --install --no-distribution
    } catch {
        Write-Host "WSL installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Setting WSL2 as default..." -ForegroundColor Cyan

    try {
        wsl --set-default-version 2
    } catch {
        Write-Host "Failed to set WSL2 as default: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Installing distro: $Distro..." -ForegroundColor Cyan

    try {
        wsl --install -d $Distro
    } catch {
        Write-Host "Distro installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Verifying WSL installation..." -ForegroundColor Cyan

    if (-not (Test-WSL)) {
        Write-Host "WSL installation failed or PATH not updated." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "WSL installed successfully with distro: $Distro"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsSubsystemLinux {
    Write-Host "`n=== Install Windows Subsystem for Linux ===" -ForegroundColor Cyan

    $distros = @(
        "Ubuntu",
        "Ubuntu-22.04",
        "Debian",
        "kali-linux",
        "openSUSE-Leap-15.5",
        "SUSE-Linux-Enterprise-Server-15-SP4"
    )

    Write-Host "`nAvailable distros:" -ForegroundColor Cyan
    $i = 1
    foreach ($d in $distros) {
        Write-Host "  [$i] $d"
        $i++
    }

    $choice = Prompt-String -Message "Choose a distro by number" -Default "1"
    $index = [int]$choice - 1

    if ($index -lt 0 -or $index -ge $distros.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return
    }

    $selected = $distros[$index]

    Write-Host "`nInstalling WSL with distro: $selected..." -ForegroundColor Cyan

    $ok = Install-WindowsSubsystemLinux-Core -Distro $selected

    if ($ok) {
        Write-Host "WSL installed successfully with $selected." -ForegroundColor Green
    } else {
        Write-Host "WSL installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsSubsystemLinux, Install-WindowsSubsystemLinux-Core