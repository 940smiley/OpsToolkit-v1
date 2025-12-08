<#
    Install-WindowsTerminalBackup.psm1
    -----------------------------------
    Creates backups of settings.json on demand.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Get-WTSettingsPath {
    $base = Join-Path $env:LOCALAPPDATA "Packages"
    $folder = Get-ChildItem $base -Directory |
        Where-Object { $_.Name -like "Microsoft.WindowsTerminal_*" } |
        Select-Object -First 1
    if (-not $folder) { return $null }
    return Join-Path $folder.FullName "LocalState\settings.json"
}

function Install-WindowsTerminalBackup-Core {
    $settingsPath = Get-WTSettingsPath
    if (-not $settingsPath) {
        Write-Host "settings.json not found." -ForegroundColor Red
        return $false
    }

    $backup = "$settingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $settingsPath $backup -Force
    Write-ModuleLog "Backup created: $backup"
    Write-Host "Backup created: $backup" -ForegroundColor Green
    return $true
}

function Install-WindowsTerminalBackup {
    Install-WindowsTerminalBackup-Core
}

Export-ModuleMember -Function Install-WindowsTerminalBackup, Install-WindowsTerminalBackup-Core