<#
    Install-Python.psm1
    --------------------
    Installs the latest Python (Windows).
    Features:
      - Downloads latest Python installer
      - Silent install with pip
      - Adds Python to PATH
      - Verifies python + pip
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify python + pip
# -------------------------------
function Test-PythonInstall {
    try {
        $py  = & python --version 2>$null
        $pip = & pip --version 2>$null
        return ($py -and $pip)
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-Python-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    $exePath = Join-Path $DownloadDir "python-installer.exe"

    # Official Python download (latest stable Windows x64)
    $url = "https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe"

    Write-Host "Downloading Python..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $exePath -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Running silent installer..." -ForegroundColor Cyan

    try {
        Start-Process -FilePath $exePath -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_pip=1" -Wait
    } catch {
        Write-Host "Installer failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Verifying installation..." -ForegroundColor Cyan

    if (-not (Test-PythonInstall)) {
        Write-Host "Python installation failed or PATH not updated." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Python installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-Python {
    Write-Host "`n=== Install Python ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\Python"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling Python..." -ForegroundColor Cyan

    $ok = Install-Python-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "Python installed successfully." -ForegroundColor Green
        Write-Host "Restart your terminal to refresh PATH."
    } else {
        Write-Host "Python installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-Python, Install-Python-Core