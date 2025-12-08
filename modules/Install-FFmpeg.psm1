<#
    Install-FFmpeg.psm1
    --------------------
    Installs the latest FFmpeg build (Windows).
    Features:
      - Downloads latest FFmpeg ZIP
      - Extracts safely
      - Adds to PATH (user-level)
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Add a folder to PATH (user-level)
# -------------------------------
function Add-ToUserPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Folder
    )

    $current = [Environment]::GetEnvironmentVariable("PATH", "User")

    if ($current -and $current.Split(";") -contains $Folder) {
        Write-Host "PATH already contains: $Folder" -ForegroundColor Gray
        return $true
    }

    $newPath = if ($current) { "$current;$Folder" } else { $Folder }

    try {
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-ModuleLog "Added to PATH: $Folder"
        return $true
    } catch {
        Write-Host "Failed to update PATH: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-FFmpeg-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$InstallDir
    )

    Ensure-Dir -Path $InstallDir

    $zipPath = Join-Path $InstallDir "ffmpeg.zip"
    $extractDir = Join-Path $InstallDir "ffmpeg"

    # Official Gyan.dev release (stable)
    $url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

    Write-Host "Downloading FFmpeg..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host "Extracting..." -ForegroundColor Cyan

    try {
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force
    } catch {
        Write-Host "Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    # Find the /bin folder inside the extracted directory
    $bin = Get-ChildItem -Path $extractDir -Recurse -Directory |
           Where-Object { $_.Name -eq "bin" } |
           Select-Object -First 1

    if (-not $bin) {
        Write-Host "FFmpeg bin folder not found." -ForegroundColor Red
        return $false
    }

    Write-Host "Adding FFmpeg to PATH..." -ForegroundColor Cyan

    if (-not (Add-ToUserPath -Folder $bin.FullName)) {
        return $false
    }

    Write-ModuleLog "FFmpeg installed at $($bin.FullName)"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-FFmpeg {
    Write-Host "`n=== Install FFmpeg ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\FFmpeg"
    $dir = Prompt-String -Message "Download/extract directory" -Default $defaultDir

    Write-Host "`nInstalling FFmpeg..." -ForegroundColor Cyan

    $ok = Install-FFmpeg-Core -InstallDir $dir

    if ($ok) {
        Write-Host "FFmpeg installed successfully." -ForegroundColor Green
        Write-Host "Restart your terminal to refresh PATH."
    } else {
        Write-Host "FFmpeg installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-FFmpeg, Install-FFmpeg-Core