<#
    Install-DockerDesktop.psm1
    ----------------------------
    Installs Docker Desktop silently.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Test-DockerDesktop {
    return (Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe")
}

function Install-DockerDesktop-Core {
    param([string]$DownloadDir)

    $url = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $exe = Join-Path $DownloadDir "docker.exe"

    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null

    Write-Host "Downloading Docker Desktop..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing

    Write-Host "Installing Docker Desktop..." -ForegroundColor Cyan
    Start-Process $exe -ArgumentList "install --quiet" -Wait

    if (Test-DockerDesktop) {
        Write-ModuleLog "Docker Desktop installed"
        Write-Host "Docker Desktop installed." -ForegroundColor Green
        return $true
    }

    Write-Host "Docker Desktop installation failed." -ForegroundColor Red
    return $false
}

function Install-DockerDesktop {
    $default = "C:\Users\$env:USERNAME\Downloads\Docker"
    Install-DockerDesktop-Core -DownloadDir $default
}

Export-ModuleMember -Function Install-DockerDesktop, Install-DockerDesktop-Core