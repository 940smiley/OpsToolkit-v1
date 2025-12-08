<#
    Install-ImageMagick.psm1
    -------------------------
    Installs the latest ImageMagick build (Windows).
    Features:
      - Downloads latest ImageMagick installer
      - Silent install
      - Verifies magick.exe
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify magick.exe exists
# -------------------------------
function Test-ImageMagick {
    try {
        $null = & magick -version 2>$null
        return $true
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-ImageMagick-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    $installer = Join-Path $DownloadDir "ImageMagick.exe"

    # Official ImageMagick download (latest Q16 HDRI build)
    $url = "https://imagemagick.org/archive/binaries/ImageMagick-7.1.1-32-Q16-HDRI-x64-dll.exe"

    Write-Host "Downloading ImageMagick..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Running silent installer..." -ForegroundColor Cyan

    try {
        Start-Process -FilePath $installer -ArgumentList "/silent" -Wait
    } catch {
        Write-Host "Installer failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Verifying installation..." -ForegroundColor Cyan

    if (-not (Test-ImageMagick)) {
        Write-Host "ImageMagick installation failed or magick.exe not in PATH." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "ImageMagick installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-ImageMagick {
    Write-Host "`n=== Install ImageMagick ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\ImageMagick"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling ImageMagick..." -ForegroundColor Cyan

    $ok = Install-ImageMagick-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "ImageMagick installed successfully." -ForegroundColor Green
    } else {
        Write-Host "ImageMagick installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-ImageMagick, Install-ImageMagick-Core