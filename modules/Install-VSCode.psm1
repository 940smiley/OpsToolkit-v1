<#
    Install-VSCode.psm1
    ---------------------
    Installs Visual Studio Code silently.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Test-VSCode {
    return (Test-Path "C:\Program Files\Microsoft VS Code\Code.exe")
}

function Install-VSCode-Core {
    param([string]$DownloadDir)

    $url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $exe = Join-Path $DownloadDir "vscode.exe"

    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null

    Write-Host "Downloading VS Code..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing

    Write-Host "Installing VS Code..." -ForegroundColor Cyan
    Start-Process $exe -ArgumentList "/VERYSILENT /NORESTART" -Wait

    if (Test-VSCode) {
        Write-ModuleLog "VS Code installed"
        Write-Host "VS Code installed." -ForegroundColor Green
        return $true
    }

    Write-Host "VS Code installation failed." -ForegroundColor Red
    return $false
}

function Install-VSCode {
    $default = "C:\Users\$env:USERNAME\Downloads\VSCode"
    Install-VSCode-Core -DownloadDir $default
}

Export-ModuleMember -Function Install-VSCode, Install-VSCode-Core