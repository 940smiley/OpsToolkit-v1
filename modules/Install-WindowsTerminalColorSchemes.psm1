<#
    Install-WindowsTerminalColorSchemes.psm1
    -----------------------------------------
    Installs color schemes into settings.json.
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

function Install-WindowsTerminalColorSchemes-Core {
    param([string]$SchemeDir)

    if (-not (Test-Path $SchemeDir)) {
        Write-Host "Scheme directory not found." -ForegroundColor Red
        return $false
    }

    $settingsPath = Get-WTSettingsPath
    if (-not $settingsPath) { return $false }

    $backup = "$settingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $settingsPath $backup -Force

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    if (-not $settings.schemes) { $settings.schemes = @() }

    $files = Get-ChildItem $SchemeDir -File -Filter *.json
    foreach ($file in $files) {
        try {
            $scheme = Get-Content $file.FullName -Raw | ConvertFrom-Json
            if (-not ($settings.schemes | Where-Object { $_.name -eq $scheme.name })) {
                $settings.schemes += $scheme
                Write-ModuleLog "Installed color scheme: $($scheme.name)"
            }
        } catch {
            Write-Host "Invalid scheme JSON: $($file.Name)" -ForegroundColor Red
        }
    }

    $settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding UTF8
    return $true
}

function Install-WindowsTerminalColorSchemes {
    $default = "C:\Users\$env:USERNAME\Downloads\WTSchemes"
    $dir = Prompt-Path -Message "Folder containing color scheme JSON files" -Default $default
    Install-WindowsTerminalColorSchemes-Core -SchemeDir $dir
}

Export-ModuleMember -Function Install-WindowsTerminalColorSchemes, Install-WindowsTerminalColorSchemes-Core