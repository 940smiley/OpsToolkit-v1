<#
    Install-OpsToolkit.psm1
    -----------------------
    Master installer and orchestrator for OpsToolkit.

    Features:
      - Environment checks (OS, PowerShell, Admin)
      - Loads all install modules
      - Menu-driven selection of installers
      - Basic unattended mode (by module key)
      - Logging hooks
#>

# Root = ...\OpsToolkit
$Script:Root = Split-Path -Parent $PSCommandPath

Import-Module "$Script:Root\Modules\Utility\Prompts.psm1" -Force
Import-Module "$Script:Root\Modules\Utility\FileSystem.psm1" -Force
Import-Module "$Script:Root\Modules\Utility\Logging.psm1" -Force

# Core installer modules
$installerModules = @(
    "Install-WindowsTerminal",
    "Install-WindowsSubsystemLinux",
    "Install-WindowsPackageManager",
    "Install-WindowsDeveloperMode",
    "Install-WindowsFeatures",
    "Install-WindowsSubsystemAndroid",
    "Install-WindowsDeveloperTools",
    "Install-WindowsFonts",
    "Install-WindowsTerminalThemes",
    "Install-WindowsTerminalProfiles",
    "Install-WindowsTerminalIcons",
    "Install-WindowsTerminalExtensions",
    "Install-WindowsTerminalKeybindings",
    "Install-WindowsTerminalColorSchemes",
    "Install-WindowsTerminalDefaults",
    "Install-WindowsTerminalBackup",
    "Install-WindowsPrivacySettings",
    "Install-WindowsSecurityBaseline",
    "Install-WindowsPowerSettings",
    "Install-WindowsExplorerTweaks",
    "Install-WindowsContextMenu",
    "Install-GitExtensions",
    "Install-VSCode",
    "Install-VSCodeExtensions",
    "Install-DockerDesktop",
    "Install-PythonPackages"
)

# -------------------------------
# Environment checks
# -------------------------------
function Test-OpsToolkitEnvironment {
    [OutputType([bool])]
    param()

    $ok = $true

    # PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "PowerShell 5 or later required." -ForegroundColor Red
        $ok = $false
    }

    # OS
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    if ($os -notmatch "Windows 10|Windows 11") {
        Write-Host "OpsToolkit is optimized for Windows 10/11. Detected: $os" -ForegroundColor Yellow
    }

    # Admin
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Installer should be run as Administrator." -ForegroundColor Yellow
    }

    return $ok
}

# -------------------------------
# Module loader
# -------------------------------
function Import-OpsToolkitModules {
    foreach ($name in $installerModules) {
        $path = Join-Path "$Script:Root\Modules" "$name.psm1"
        if (Test-Path $path) {
            try {
                Import-Module $path -Force
                Write-ModuleLog "Loaded module: $name"
            } catch {
                Write-Host "Failed to load module: $name" -ForegroundColor Red
            }
        } else {
            Write-Host "Module missing: $name" -ForegroundColor Yellow
        }
    }
}

# -------------------------------
# Menu definition
# -------------------------------
$Script:InstallerMenu = @(
    @{ Key = "1";  Name = "Windows Terminal";                     Command = "Install-WindowsTerminal" }
    @{ Key = "2";  Name = "Windows Subsystem for Linux (WSL)";    Command = "Install-WindowsSubsystemLinux" }
    @{ Key = "3";  Name = "Windows Package Manager (winget)";     Command = "Install-WindowsPackageManager" }
    @{ Key = "4";  Name = "Windows Developer Mode";               Command = "Install-WindowsDeveloperMode" }
    @{ Key = "5";  Name = "Optional Windows Features";            Command = "Install-WindowsFeatures" }
    @{ Key = "6";  Name = "Windows Subsystem for Android (WSA)";  Command = "Install-WindowsSubsystemAndroid" }
    @{ Key = "7";  Name = "Windows Developer Tools";              Command = "Install-WindowsDeveloperTools" }
    @{ Key = "8";  Name = "Fonts";                                Command = "Install-WindowsFonts" }
    @{ Key = "9";  Name = "WT Themes";                            Command = "Install-WindowsTerminalThemes" }
    @{ Key = "10"; Name = "WT Profiles";                          Command = "Install-WindowsTerminalProfiles" }
    @{ Key = "11"; Name = "WT Icons";                             Command = "Install-WindowsTerminalIcons" }
    @{ Key = "12"; Name = "WT Extensions";                        Command = "Install-WindowsTerminalExtensions" }
    @{ Key = "13"; Name = "WT Keybindings";                       Command = "Install-WindowsTerminalKeybindings" }
    @{ Key = "14"; Name = "WT Color Schemes";                     Command = "Install-WindowsTerminalColorSchemes" }
    @{ Key = "15"; Name = "WT Defaults";                          Command = "Install-WindowsTerminalDefaults" }
    @{ Key = "16"; Name = "WT Backup";                            Command = "Install-WindowsTerminalBackup" }
    @{ Key = "17"; Name = "Privacy Settings";                     Command = "Install-WindowsPrivacySettings" }
    @{ Key = "18"; Name = "Security Baseline";                    Command = "Install-WindowsSecurityBaseline" }
    @{ Key = "19"; Name = "Power Settings";                       Command = "Install-WindowsPowerSettings" }
    @{ Key = "20"; Name = "Explorer Tweaks";                      Command = "Install-WindowsExplorerTweaks" }
    @{ Key = "21"; Name = "Context Menu Entry";                   Command = "Install-WindowsContextMenu" }
    @{ Key = "22"; Name = "Git Extensions";                       Command = "Install-GitExtensions" }
    @{ Key = "23"; Name = "VS Code";                              Command = "Install-VSCode" }
    @{ Key = "24"; Name = "VS Code Extensions";                   Command = "Install-VSCodeExtensions" }
    @{ Key = "25"; Name = "Docker Desktop";                       Command = "Install-DockerDesktop" }
    @{ Key = "26"; Name = "Python Packages";                      Command = "Install-PythonPackages" }
)

# -------------------------------
# Invocation helper
# -------------------------------
function Invoke-OpsToolkitInstallerItem {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [string]$Label
    )

    Write-Host "`n>>> Running: $Label ($Command) <<<`n" -ForegroundColor Cyan
    Write-ModuleLog "Starting installer: $Label ($Command)"

    try {
        & $Command
        Write-ModuleLog "Completed installer: $Label ($Command)"
    } catch {
        Write-Host "Error running $Command: $($_.Exception.Message)" -ForegroundColor Red
        Write-ModuleLog "ERROR in installer $Label: $($_.Exception.Message)"
    }
}

# -------------------------------
# Interactive menu
# -------------------------------
function Show-OpsToolkitMenu {
    while ($true) {
        Write-Host "`n=== OpsToolkit Master Installer ===" -ForegroundColor Cyan
        foreach ($item in $Script:InstallerMenu) {
            Write-Host ("{0,2}. {1}" -f [int]$item.Key, $item.Name)
        }
        Write-Host "  X. Exit" -ForegroundColor Yellow

        $choice = Read-Host "Select an item (number or X)"
        if ($choice -match '^[Xx]$') { break }

        $match = $Script:InstallerMenu | Where-Object { $_.Key -eq $choice }
        if (-not $match) {
            Write-Host "Invalid selection." -ForegroundColor Red
            continue
        }

        Invoke-OpsToolkitInstallerItem -Command $match.Command -Label $match.Name
    }
}

# -------------------------------
# Public entrypoints
# -------------------------------
function Install-OpsToolkit {
    param(
        [string]$UnattendedKey
    )

    if (-not (Test-OpsToolkitEnvironment)) {
        Write-Host "Environment checks failed; aborting." -ForegroundColor Red
        return
    }

    Import-OpsToolkitModules

    if ($UnattendedKey) {
        $match = $Script:InstallerMenu | Where-Object { $_.Key -eq $UnattendedKey }
        if (-not $match) {
            Write-Host "Invalid unattended key: $UnattendedKey" -ForegroundColor Red
            return
        }
        Invoke-OpsToolkitInstallerItem -Command $match.Command -Label $match.Name
    } else {
        Show-OpsToolkitMenu
    }
}

Export-ModuleMember -Function Install-OpsToolkit