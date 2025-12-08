<#
    Install-PowerShell.psm1
    ------------------------
    Installs the latest PowerShell 7 (Windows).
    Features:
      - Downloads latest PowerShell MSI
      - Silent install
      - Verifies pwsh
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify pwsh
# -------------------------------
function Test-PwshInstall {
    try {
        $pwsh = & pwsh --version 2>$null
        return $pwsh -ne $null
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-PowerShell-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    $msiPath = Join-Path $DownloadDir "powershell.msi"

    # Official PowerShell 7 MSI (latest stable)
    $url = "https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.4.0-win-x64.msi"

    Write-Host "Downloading PowerShell..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $msiPath -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Running silent installer..." -ForegroundColor Cyan

    try {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn" -Wait
    } catch {
        Write-Host "Installer failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Verifying installation..." -ForegroundColor Cyan

    if (-not (Test-PwshInstall)) {
        Write-Host "PowerShell installation failed or PATH not updated." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "PowerShell installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-PowerShell {
    Write-Host "`n=== Install PowerShell 7 ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\PowerShell"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling PowerShell..." -ForegroundColor Cyan

    $ok = Install-PowerShell-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "PowerShell installed successfully." -ForegroundColor Green
        Write-Host "Restart your terminal to refresh PATH."
    } else {
        Write-Host "PowerShell installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-PowerShell, Install-PowerShell-Core