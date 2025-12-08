<#
    Install-WindowsDeveloperTools.psm1
    -----------------------------------
    Installs core Windows developer tools:
      - Visual Studio Build Tools
      - .NET SDK
      - Windows SDK
      - Git for Windows
    Features:
      - Silent installs
      - Dependency-safe
      - Verification
      - Logging
      - Interactive wrapper
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verification helpers
# -------------------------------
function Test-VSBuildTools {
    return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe")
}

function Test-DotNet {
    try { & dotnet --version 2>$null; return $true } catch { return $false }
}

function Test-Git {
    try { & git --version 2>$null; return $true } catch { return $false }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsDeveloperTools-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadDir,

        [switch]$InstallVSBuildTools,
        [switch]$InstallDotNetSDK,
        [switch]$InstallWindowsSDK,
        [switch]$InstallGit
    )

    Ensure-Dir -Path $DownloadDir

    # ---------------------------
    # Visual Studio Build Tools
    # ---------------------------
    if ($InstallVSBuildTools) {
        Write-Host "`nInstalling Visual Studio Build Tools..." -ForegroundColor Cyan

        $vsExe = Join-Path $DownloadDir "vs_buildtools.exe"
        $vsUrl = "https://aka.ms/vs/17/release/vs_BuildTools.exe"

        try {
            Invoke-WebRequest -Uri $vsUrl -OutFile $vsExe -UseBasicParsing
            Start-Process -FilePath $vsExe -ArgumentList `
                "--quiet --wait --norestart --nocache --installPath `"C:\BuildTools`" `
                 --add Microsoft.VisualStudio.Workload.VCTools `
                 --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools `
                 --add Microsoft.VisualStudio.Workload.NetCoreBuildTools" -Wait
        } catch {
            Write-Host "VS Build Tools install failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        if (Test-VSBuildTools) {
            Write-ModuleLog "VS Build Tools installed"
        } else {
            Write-Host "VS Build Tools verification failed." -ForegroundColor Red
        }
    }

    # ---------------------------
    # .NET SDK
    # ---------------------------
    if ($InstallDotNetSDK) {
        Write-Host "`nInstalling .NET SDK..." -ForegroundColor Cyan

        $dotnetExe = Join-Path $DownloadDir "dotnet-sdk.exe"
        $dotnetUrl = "https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-8.0.100-windows-x64-installer"

        try {
            Invoke-WebRequest -Uri $dotnetUrl -OutFile $dotnetExe -UseBasicParsing
            Start-Process -FilePath $dotnetExe -ArgumentList "/quiet /norestart" -Wait
        } catch {
            Write-Host ".NET SDK install failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        if (Test-DotNet) {
            Write-ModuleLog ".NET SDK installed"
        } else {
            Write-Host ".NET SDK verification failed." -ForegroundColor Red
        }
    }

    # ---------------------------
    # Windows SDK
    # ---------------------------
    if ($InstallWindowsSDK) {
        Write-Host "`nInstalling Windows SDK..." -ForegroundColor Cyan

        $sdkExe = Join-Path $DownloadDir "winsdk.exe"
        $sdkUrl = "https://go.microsoft.com/fwlink/?linkid=2243390"

        try {
            Invoke-WebRequest -Uri $sdkUrl -OutFile $sdkExe -UseBasicParsing
            Start-Process -FilePath $sdkExe -ArgumentList "/quiet /norestart" -Wait
        } catch {
            Write-Host "Windows SDK install failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-ModuleLog "Windows SDK installation attempted"
    }

    # ---------------------------
    # Git for Windows
    # ---------------------------
    if ($InstallGit) {
        Write-Host "`nInstalling Git for Windows..." -ForegroundColor Cyan

        $gitExe = Join-Path $DownloadDir "git.exe"
        $gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe"

        try {
            Invoke-WebRequest -Uri $gitUrl -OutFile $gitExe -UseBasicParsing
            Start-Process -FilePath $gitExe -ArgumentList "/VERYSILENT /NORESTART" -Wait
        } catch {
            Write-Host "Git install failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        if (Test-Git) {
            Write-ModuleLog "Git installed"
        } else {
            Write-Host "Git verification failed." -ForegroundColor Red
        }
    }

    Write-Host "`nDeveloper tools installation complete." -ForegroundColor Green
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsDeveloperTools {
    Write-Host "`n=== Install Windows Developer Tools ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\DevTools"
    $dir = Prompt-String -Message "Download directory" -Default $defaultDir

    $vs   = Prompt-YesNo -Message "Install Visual Studio Build Tools" -Default $true
    $dot  = Prompt-YesNo -Message "Install .NET SDK" -Default $true
    $sdk  = Prompt-YesNo -Message "Install Windows SDK" -Default $true
    $git  = Prompt-YesNo -Message "Install Git for Windows" -Default $true

    Install-WindowsDeveloperTools-Core `
        -DownloadDir $dir `
        -InstallVSBuildTools:$vs `
        -InstallDotNetSDK:$dot `
        -InstallWindowsSDK:$sdk `
        -InstallGit:$git
}

Export-ModuleMember -Function Install-WindowsDeveloperTools, Install-WindowsDeveloperTools-Core