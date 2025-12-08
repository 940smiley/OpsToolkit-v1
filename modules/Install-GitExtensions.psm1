<#
    Install-GitExtensions.psm1
    ---------------------------
    Installs Git Extensions silently.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Test-GitExtensions {
    return (Test-Path "C:\Program Files\GitExtensions\GitExtensions.exe")
}

function Install-GitExtensions-Core {
    param([string]$DownloadDir)

    $url = "https://github.com/gitextensions/gitextensions/releases/latest/download/GitExtensions-Portable.zip"
    $zip = Join-Path $DownloadDir "gitextensions.zip"
    $dest = "C:\Program Files\GitExtensions"

    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null

    Write-Host "Downloading Git Extensions..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

    Write-Host "Extracting..." -ForegroundColor Cyan
    Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force

    if (Test-GitExtensions) {
        Write-ModuleLog "Git Extensions installed"
        Write-Host "Git Extensions installed." -ForegroundColor Green
        return $true
    }

    Write-Host "Git Extensions installation failed." -ForegroundColor Red
    return $false
}

function Install-GitExtensions {
    $default = "C:\Users\$env:USERNAME\Downloads\GitExtensions"
    Install-GitExtensions-Core -DownloadDir $default
}

Export-ModuleMember -Function Install-GitExtensions, Install-GitExtensions-Core