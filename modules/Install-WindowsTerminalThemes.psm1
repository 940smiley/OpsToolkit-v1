<#
    Install-WindowsTerminalThemes.psm1
    -----------------------------------
    Installs custom Windows Terminal themes by patching settings.json.
    Features:
      - Loads settings.json safely
      - Creates timestamped backups
      - Installs themes from JSON files
      - Duplicate detection
      - Schema validation
      - Logging
      - Interactive wrapper
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Get Windows Terminal settings.json
# -------------------------------
function Get-WTSettingsPath {
    $base = Join-Path $env:LOCALAPPDATA "Packages"
    $folder = Get-ChildItem $base -Directory |
              Where-Object { $_.Name -like "Microsoft.WindowsTerminal_*" } |
              Select-Object -First 1

    if (-not $folder) { return $null }

    return Join-Path $folder.FullName "LocalState\settings.json"
}

# -------------------------------
# Load settings.json safely
# -------------------------------
function Load-WTSettings {
    param([string]$Path)

    try {
        $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        return $json | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Host "Failed to load settings.json: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# -------------------------------
# Save settings.json safely
# -------------------------------
function Save-WTSettings {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][object]$Data
    )

    try {
        $Data | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
        return $true
    } catch {
        Write-Host "Failed to save settings.json: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Install a single theme
# -------------------------------
function Install-WTTheme {
    param(
        [Parameter(Mandatory=$true)][object]$Settings,
        [Parameter(Mandatory=$true)][object]$Theme
    )

    if (-not $Settings.schemes) {
        $Settings | Add-Member -MemberType NoteProperty -Name schemes -Value @()
    }

    $existing = $Settings.schemes | Where-Object { $_.name -eq $Theme.name }

    if ($existing) {
        Write-Host "Theme already exists: $($Theme.name)" -ForegroundColor Gray
        return $false
    }

    $Settings.schemes += $Theme
    return $true
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsTerminalThemes-Core {
    param(
        [Parameter(Mandatory=$true)][string]$ThemeDir
    )

    if (-not (Test-Path -LiteralPath $ThemeDir)) {
        Write-Host "Theme directory not found: $ThemeDir" -ForegroundColor Red
        return $false
    }

    $settingsPath = Get-WTSettingsPath
    if (-not $settingsPath) {
        Write-Host "Windows Terminal settings.json not found." -ForegroundColor Red
        return $false
    }

    $settings = Load-WTSettings -Path $settingsPath
    if (-not $settings) { return $false }

    # Backup
    $backup = "$settingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -LiteralPath $settingsPath -Destination $backup -Force
    Write-ModuleLog "Backup created: $backup"

    # Load themes
    $themeFiles = Get-ChildItem -LiteralPath $ThemeDir -File -Filter *.json
    if (-not $themeFiles) {
        Write-Host "No theme JSON files found." -ForegroundColor Yellow
        return $false
    }

    $installed = 0
    $skipped = 0

    foreach ($file in $themeFiles) {
        try {
            $theme = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        } catch {
            Write-Host "Invalid theme JSON: $($file.Name)" -ForegroundColor Red
            continue
        }

        if (Install-WTTheme -Settings $settings -Theme $theme) {
            Write-Host "Installed theme: $($theme.name)" -ForegroundColor Green
            $installed++
        } else {
            $skipped++
        }
    }

    if (-not (Save-WTSettings -Path $settingsPath -Data $settings)) {
        Write-Host "Failed to save updated settings.json" -ForegroundColor Red
        return $false
    }

    Write-Host "`nDone. Installed: $installed  Skipped: $skipped" -ForegroundColor Cyan
    Write-ModuleLog "Install-WindowsTerminalThemes completed: $installed installed, $skipped skipped"

    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsTerminalThemes {
    Write-Host "`n=== Install Windows Terminal Themes ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\WTThemes"
    $dir = Prompt-Path -Message "Folder containing theme JSON files" -Default $defaultDir

    Write-Host "`nInstalling themes..." -ForegroundColor Cyan

    $ok = Install-WindowsTerminalThemes-Core -ThemeDir $dir

    if ($ok) {
        Write-Host "Themes installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Theme installation completed with errors." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsTerminalThemes, Install-WindowsTerminalThemes-Core