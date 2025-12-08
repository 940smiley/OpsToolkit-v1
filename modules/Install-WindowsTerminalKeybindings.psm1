<#
    Install-WindowsTerminalKeybindings.psm1
    ----------------------------------------
    Installs custom keybindings into settings.json.
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

function Install-WindowsTerminalKeybindings-Core {
    param([string]$BindingsFile)

    if (-not (Test-Path $BindingsFile)) {
        Write-Host "Keybindings file not found." -ForegroundColor Red
        return $false
    }

    $settingsPath = Get-WTSettingsPath
    if (-not $settingsPath) { return $false }

    $backup = "$settingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $settingsPath $backup -Force

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $bindings = Get-Content $BindingsFile -Raw | ConvertFrom-Json

    $settings.actions = $bindings.actions

    $settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding UTF8
    Write-ModuleLog "Installed keybindings from $BindingsFile"
    return $true
}

function Install-WindowsTerminalKeybindings {
    $default = "C:\Users\$env:USERNAME\Downloads\WTKeybindings\keybindings.json"
    $file = Prompt-Path -Message "Keybindings JSON file" -Default $default
    Install-WindowsTerminalKeybindings-Core -BindingsFile $file
}

Export-ModuleMember -Function Install-WindowsTerminalKeybindings, Install-WindowsTerminalKeybindings-Core