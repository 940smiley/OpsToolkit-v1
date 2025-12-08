<#
    Install-Node.psm1
    ------------------
    Installs the latest Node.js LTS (Windows).
    Features:
      - Downloads latest Node.js LTS MSI
      - Silent install
      - Verifies node + npm
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify node + npm
# -------------------------------
function Test-NodeInstall {
    try {
        $node = & node -v 2>$null
        $npm  = & npm -v 2>$null
        return ($node -and $npm)
    } catch {
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-Node-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir
    )

    Ensure-Dir -Path $DownloadDir

    $msiPath = Join-Path $DownloadDir "node-lts.msi"

    # Official Node.js LTS MSI (latest)
    $url = "https://nodejs.org/dist/latest-lts/win-x64/node-v*-x64.msi"

    Write-Host "Downloading Node.js LTS..." -ForegroundColor Cyan

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

    if (-not (Test-NodeInstall)) {
        Write-Host "Node.js installation failed or PATH not updated." -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Node.js installed successfully"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-Node {
    Write-Host "`n=== Install Node.js LTS ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\NodeJS"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    Write-Host "`nInstalling Node.js..." -ForegroundColor Cyan

    $ok = Install-Node-Core -DownloadDir $dir

    if ($ok) {
        Write-Host "Node.js installed successfully." -ForegroundColor Green
        Write-Host "Restart your terminal to refresh PATH."
    } else {
        Write-Host "Node.js installation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-Node, Install-Node-Core