<#
    Install-WindowsTerminalExtensions.psm1
    ---------------------------------------
    Installs Windows Terminal extensions (JSON patches).
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

function Install-WindowsTerminalExtensions-Core {
    param([string]$ExtensionDir)

    if (-not (Test-Path $ExtensionDir)) {
        Write-Host "Extension directory not found." -ForegroundColor Red
        return $false
    }

    $settingsPath = Get-WTSettingsPath
    if (-not $settingsPath) { return $false }

    $backup = "$settingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $settingsPath $backup -Force

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    $files = Get-ChildItem $ExtensionDir -File -Filter *.json
    foreach ($file in $files) {
        try {
            $patch = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $settings.extensions += $patch
            Write-ModuleLog "Installed extension: $($file.Name)"
        } catch {
            Write-Host "Invalid extension JSON: $($file.Name)" -ForegroundColor Red
        }
    }

    $settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding UTF8
    return $true
}

function Install-WindowsTerminalExtensions {
    $default = "C:\Users\$env:USERNAME\Downloads\WTExtensions"
    $dir = Prompt-Path -Message "Folder containing extension JSON files" -Default $default
    Install-WindowsTerminalExtensions-Core -ExtensionDir $dir
}

Export-ModuleMember -Function Install-WindowsTerminalExtensions, Install-WindowsTerminalExtensions-Core