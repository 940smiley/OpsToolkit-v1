<#
    Install-WindowsTerminalDefaults.psm1
    -------------------------------------
    Applies default settings to Windows Terminal.
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Get-WTSettingsPath {
    $base = Join-Path $env:LOCALAPPDATA "Packages"
    $folder = Get-ChildItem $base -Directory |
        Where-Object { $_.Name -like "Microsoft.WindowsTerminal_*" } |
        Select-Object -First 1
    if (-not $folder) { return $null }
    return Join-Path $folder.FullName "LocalState\settings.json"
}

function Install-WindowsTerminalDefaults-Core {
    param([string]$DefaultsFile)

    if (-not (Test-Path $DefaultsFile)) {
        Write-Host "Defaults file not found." -ForegroundColor Red
        return $false
    }

    $settingsPath = Get-WTSettingsPath
    if (-not $settingsPath) { return $false }

    $backup = "$settingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $settingsPath $backup -Force

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $defaults = Get-Content $DefaultsFile -Raw | ConvertFrom-Json

    $settings.defaults = $defaults

    $settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding UTF8
    Write-ModuleLog "Applied Windows Terminal defaults"
    return $true
}

function Install-WindowsTerminalDefaults {
    $default = "C:\Users\$env:USERNAME\Downloads\WTDefaults\defaults.json"
    $file = Prompt-Path -Message "Defaults JSON file" -Default $default
    Install-WindowsTerminalDefaults-Core -DefaultsFile $file
}

Export-ModuleMember -Function Install-WindowsTerminalDefaults, Install-WindowsTerminalDefaults-Core