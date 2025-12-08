<#
    Install-WindowsExplorerTweaks.psm1
    -----------------------------------
    Applies Explorer UI and behavior tweaks.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Set-ExplorerReg {
    param([string]$Path, [string]$Name, [object]$Value)

    try {
        New-Item -Path $Path -Force | Out-Null
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-ModuleLog "Explorer tweak applied: $Path -> $Name=$Value"
    } catch {
        Write-Host "Failed: $Path $Name" -ForegroundColor Red
    }
}

function Install-WindowsExplorerTweaks-Core {

    Write-Host "Applying Explorer tweaks..." -ForegroundColor Cyan

    # Show file extensions
    Set-ExplorerReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0

    # Show hidden files
    Set-ExplorerReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1

    # Disable Quick Access recent files
    Set-ExplorerReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0

    # Disable Quick Access frequent folders
    Set-ExplorerReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0

    Write-Host "Explorer tweaks applied." -ForegroundColor Green
    return $true
}

function Install-WindowsExplorerTweaks {
    Install-WindowsExplorerTweaks-Core
}

Export-ModuleMember -Function Install-WindowsExplorerTweaks, Install-WindowsExplorerTweaks-Core