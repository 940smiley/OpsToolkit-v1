<#
    Install-WindowsTerminalIcons.psm1
    ----------------------------------
    Installs icon packs and patches Windows Terminal profiles.
    Features:
      - Installs PNG/SVG icons
      - Validates file types
      - Loads settings.json safely
      - Creates timestamped backups
      - Patches profiles with icons
      - Logging
      - Interactive wrapper
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Locate settings.json
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
# Load settings.json
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
# Save settings.json
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
# Install icons into a directory
# -------------------------------
function Install-WTIcons {
    param(
        [Parameter(Mandatory=$true)][string]$SourceDir,
        [Parameter(Mandatory=$true)][string]$DestDir
    )

    Ensure-Dir -Path $DestDir

    $icons = Get-ChildItem -LiteralPath $SourceDir -File -Include *.png, *.svg -ErrorAction SilentlyContinue

    if (-not $icons) {
        Write-Host "No icon files found in $SourceDir" -ForegroundColor Yellow
        return @()
    }

    $installed = @()

    foreach ($icon in $icons) {
        $dest = Join-Path $DestDir $icon.Name
        Copy-Item -LiteralPath $icon.FullName -Destination $dest -Force
        $installed += $dest
        Write-ModuleLog "Installed icon: $dest"
    }

    return $installed
}

# -------------------------------
# Patch profiles with icons
# -------------------------------
function Patch-WTProfilesWithIcons {
    param(
        [Parameter(Mandatory=$true)][object]$Settings,
        [Parameter(Mandatory=$true)][string]$IconDir
    )

    if (-not $Settings.profiles -or -not $Settings.profiles.list) {
        Write-Host "No profiles found in settings.json" -ForegroundColor Red
        return $false
    }

    $icons = Get-ChildItem -LiteralPath $IconDir -File -Include *.png, *.svg -ErrorAction SilentlyContinue

    if (-not $icons) {
        Write-Host "No icons found in $IconDir" -ForegroundColor Red
        return $false
    }

    $map = @{}
    foreach ($i in $icons) {
        $map[$i.BaseName.ToLower()] = $i.FullName
    }

    $patched = 0
    $skipped = 0

    foreach ($profile in $Settings.profiles.list) {
        $key = $profile.name.ToLower()

        if ($map.ContainsKey($key)) {
            $profile.icon = $map[$key]
            $patched++
            Write-Host "Patched icon for profile: $($profile.name)" -ForegroundColor Green
        } else {
            $skipped++
        }
    }

    Write-ModuleLog "Patched $patched profiles, skipped $skipped"
    return $true
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsTerminalIcons-Core {
    param(
        [Parameter(Mandatory=$true)][string]$IconSourceDir,
        [Parameter(Mandatory=$true)][string]$IconInstallDir
    )

    if (-not (Test-Path -LiteralPath $IconSourceDir)) {
        Write-Host "Icon source directory not found: $IconSourceDir" -ForegroundColor Red
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

    # Install icons
    $installedIcons = Install-WTIcons -SourceDir $IconSourceDir -DestDir $IconInstallDir

    if (-not $installedIcons) {
        Write-Host "No icons installed." -ForegroundColor Yellow
    }

    # Patch profiles
    Patch-WTProfilesWithIcons -Settings $settings -IconDir $IconInstallDir | Out-Null

    # Save
    if (-not (Save-WTSettings -Path $settingsPath -Data $settings)) {
        Write-Host "Failed to save updated settings.json" -ForegroundColor Red
        return $false
    }

    Write-Host "`nIcon installation complete." -ForegroundColor Cyan
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsTerminalIcons {
    Write-Host "`n=== Install Windows Terminal Icons ===" -ForegroundColor Cyan

    $defaultSource = "C:\Users\$env:USERNAME\Downloads\WTIcons"
    $defaultDest   = "C:\Users\$env:USERNAME\Pictures\WTIcons"

    $src = Prompt-Path -Message "Folder containing icon files (.png/.svg)" -Default $defaultSource
    $dst = Prompt-Path -Message "Destination folder for installed icons" -Default $defaultDest

    Write-Host "`nInstalling icons..." -ForegroundColor Cyan

    $ok = Install-WindowsTerminalIcons-Core -IconSourceDir $src -IconInstallDir $dst

    if ($ok) {
        Write-Host "Icons installed and profiles patched successfully." -ForegroundColor Green
    } else {
        Write-Host "Icon installation completed with errors." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsTerminalIcons, Install-WindowsTerminalIcons-Core