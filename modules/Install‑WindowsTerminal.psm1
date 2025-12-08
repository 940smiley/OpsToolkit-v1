<#
    Install-WindowsTerminal.psm1
    -----------------------------
    Installs the latest Windows Terminal (MSIXBundle).
    Features:
      - Downloads latest MSIXBundle
      - Silent install
      - Verifies wt.exe
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify wt.exe
# -------------------------------
function Test-WindowsTerminal {
    try {
        $wt = & wt --version 2>$null
        return $wt -ne $null
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsTerminal-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    $bundlePath = Join-Path $DownloadDir "windows_terminal.msixbundle"

    # Official Windows Terminal MSIXBundle (latest stable)
    $url = "https://github.com/microsoft/terminal/releases/latest/download/Microsoft.WindowsTerminal_8wekyb3d8bbwe.msixbundle"

    Write-Host "Downloading Windows Terminal..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $bundlePath -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Installing Windows Terminal..." -ForegroundColor Cyan

    try {
        Add-AppxPackage -Path $bundlePath -ForceApplicationShutdown
    } catch {
        Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Verifying installation..." -ForegroundColor Cyan

    if (-not (Test-WindowsTerminal)) {
        Write-Host "Windows Terminal installation failed or PATH not updated." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Windows Terminal installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsTerminal {
    Write-Host "`n=== Install Windows Terminal ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\WindowsTerminal"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling Windows Terminal..." -ForegroundColor Cyan

    $ok = Install-WindowsTerminal-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "Windows Terminal installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Windows Terminal installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsTerminal, Install-WindowsTerminal-Core