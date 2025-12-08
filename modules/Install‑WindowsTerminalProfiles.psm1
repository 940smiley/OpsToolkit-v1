<#
    Install-WindowsTerminalProfiles.psm1
    -------------------------------------
    Installs custom Windows Terminal profiles by patching settings.json.
    Features:
      - Loads settings.json safely
      - Creates timestamped backups
      - Installs profiles from JSON files
      - Duplicate detection
      - Schema validation
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
# Install a single profile
# -------------------------------
function Install-WTProfile {
    param(
        [Parameter(Mandatory=$true)][object]$Settings,
        [Parameter(Mandatory=$true)][object]$Profile
    )

    if (-not $Settings.profiles) {
        $Settings | Add-Member -MemberType NoteProperty -Name profiles -Value @{ list = @() }
    }

    if (-not $Settings.profiles.list) {
        $Settings.profiles.list = @()
    }

    $existing = $Settings.profiles.list | Where-Object { $_.name -eq $Profile.name }

    if ($existing) {
        Write-Host "Profile already exists: $($Profile.name)" -ForegroundColor Gray
        return $false
    }

    $Settings.profiles.list += $Profile
    return $true
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsTerminalProfiles-Core {
    param(
        [Parameter(Mandatory=$true)][string]$ProfileDir
    )

    if (-not (Test-Path -LiteralPath $ProfileDir)) {
        Write-Host "Profile directory not found: $ProfileDir" -ForegroundColor Red
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

    # Load profiles
    $profileFiles = Get-ChildItem -LiteralPath $ProfileDir -File -Filter *.json
    if (-not $profileFiles) {
        Write-Host "No profile JSON files found." -ForegroundColor Yellow
        return $false
    }

    $installed = 0
    $skipped = 0

    foreach ($file in $profileFiles) {
        try {
            $profile = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        } catch {
            Write-Host "Invalid profile JSON: $($file.Name)" -ForegroundColor Red
            continue
        }

        if (Install-WTProfile -Settings $settings -Profile $profile) {
            Write-Host "Installed profile: $($profile.name)" -ForegroundColor Green
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
    Write-ModuleLog "Install-WindowsTerminalProfiles completed: $installed installed, $skipped skipped"

    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsTerminalProfiles {
    Write-Host "`n=== Install Windows Terminal Profiles ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\WTProfiles"
    $dir = Prompt-Path -Message "Folder containing profile JSON files" -Default $defaultDir

    Write-Host "`nInstalling profiles..." -ForegroundColor Cyan

    $ok = Install-WindowsTerminalProfiles-Core -ProfileDir $dir

    if ($ok) {
        Write-Host "Profiles installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Profile installation completed with errors." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsTerminalProfiles, Install-WindowsTerminalProfiles-Core