<#
    OpsToolkitLauncher.psm1
    ------------------------
    Main launcher UI for OpsToolkit.

    Features:
      - Category-based navigation
      - Search
      - Integration with all installer modules
      - Auto-update hook
      - Logging
#>

$Script:Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

Import-Module "$Script:Root\Modules\Utility\Prompts.psm1" -Force
Import-Module "$Script:Root\Modules\Utility\Logging.psm1" -Force
Import-Module "$Script:Root\Install-OpsToolkit.psm1" -Force

# -------------------------------
# Category definitions
# -------------------------------
$Script:Categories = @(
    @{
        Name = "Windows Terminal"
        Items = @(
            @{ Label = "Install Windows Terminal";               Command = "Install-WindowsTerminal" }
            @{ Label = "Install WT Themes";                      Command = "Install-WindowsTerminalThemes" }
            @{ Label = "Install WT Profiles";                    Command = "Install-WindowsTerminalProfiles" }
            @{ Label = "Install WT Icons";                       Command = "Install-WindowsTerminalIcons" }
            @{ Label = "Install WT Extensions";                  Command = "Install-WindowsTerminalExtensions" }
            @{ Label = "Install WT Keybindings";                 Command = "Install-WindowsTerminalKeybindings" }
            @{ Label = "Install WT Color Schemes";               Command = "Install-WindowsTerminalColorSchemes" }
            @{ Label = "Apply WT Defaults";                      Command = "Install-WindowsTerminalDefaults" }
            @{ Label = "Backup WT Settings";                     Command = "Install-WindowsTerminalBackup" }
        )
    }

    @{
        Name = "Windows System"
        Items = @(
            @{ Label = "Install Windows Subsystem for Linux";    Command = "Install-WindowsSubsystemLinux" }
            @{ Label = "Install Windows Subsystem for Android";  Command = "Install-WindowsSubsystemAndroid" }
            @{ Label = "Install Windows Package Manager";        Command = "Install-WindowsPackageManager" }
            @{ Label = "Enable Developer Mode";                  Command = "Install-WindowsDeveloperMode" }
            @{ Label = "Install Optional Windows Features";      Command = "Install-WindowsFeatures" }
            @{ Label = "Apply Privacy Settings";                 Command = "Install-WindowsPrivacySettings" }
            @{ Label = "Apply Security Baseline";                Command = "Install-WindowsSecurityBaseline" }
            @{ Label = "Apply Power Settings";                   Command = "Install-WindowsPowerSettings" }
            @{ Label = "Apply Explorer Tweaks";                  Command = "Install-WindowsExplorerTweaks" }
            @{ Label = "Add Context Menu Entry";                 Command = "Install-WindowsContextMenu" }
        )
    }

    @{
        Name = "Developer Tools"
        Items = @(
            @{ Label = "Install Windows Developer Tools";        Command = "Install-WindowsDeveloperTools" }
            @{ Label = "Install Git Extensions";                 Command = "Install-GitExtensions" }
            @{ Label = "Install VS Code";                        Command = "Install-VSCode" }
            @{ Label = "Install VS Code Extensions";             Command = "Install-VSCodeExtensions" }
            @{ Label = "Install Docker Desktop";                 Command = "Install-DockerDesktop" }
            @{ Label = "Install Python Packages";                Command = "Install-PythonPackages" }
        )
    }
)

# -------------------------------
# Auto-update hook
# -------------------------------
function Invoke-OpsToolkitUpdate {
    Write-Host "`nChecking for updates..." -ForegroundColor Cyan
    Write-ModuleLog "Launcher invoked update check"

    # Component #5 will implement this
    try {
        Update-OpsToolkit
    } catch {
        Write-Host "Auto-update module not installed yet." -ForegroundColor Yellow
    }
}

# -------------------------------
# Execute a launcher item
# -------------------------------
function Invoke-OpsToolkitLauncherItem {
    param(
        [string]$Command,
        [string]$Label
    )

    Write-Host "`n>>> Running: $Label <<<" -ForegroundColor Cyan
    Write-ModuleLog "Launcher executing: $Label ($Command)"

    try {
        & $Command
    } catch {
        Write-Host "Error running $Command: $($_.Exception.Message)" -ForegroundColor Red
        Write-ModuleLog "ERROR: $($_.Exception.Message)"
    }
}

# -------------------------------
# Category menu
# -------------------------------
function Show-OpsToolkitCategory {
    param([object]$Category)

    while ($true) {
        Write-Host "`n=== $($Category.Name) ===" -ForegroundColor Cyan

        for ($i = 0; $i -lt $Category.Items.Count; $i++) {
            Write-Host ("{0,2}. {1}" -f ($i + 1), $Category.Items[$i].Label)
        }

        Write-Host "  B. Back" -ForegroundColor Yellow

        $choice = Read-Host "Select an item"
        if ($choice -match '^[Bb]$') { return }

        if ($choice -as [int] -and $choice -ge 1 -and $choice -le $Category.Items.Count) {
            $item = $Category.Items[$choice - 1]
            Invoke-OpsToolkitLauncherItem -Command $item.Command -Label $item.Label
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }
}

# -------------------------------
# Search
# -------------------------------
function Search-OpsToolkit {
    $term = Read-Host "Search term"
    $results = @()

    foreach ($cat in $Script:Categories) {
        foreach ($item in $cat.Items) {
            if ($item.Label -like "*$term*") {
                $results += @{
                    Category = $cat.Name
                    Label    = $item.Label
                    Command  = $item.Command
                }
            }
        }
    }

    if ($results.Count -eq 0) {
        Write-Host "No matches found." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Search Results ===" -ForegroundColor Cyan
    for ($i = 0; $i -lt $results.Count; $i++) {
        Write-Host ("{0,2}. [{1}] {2}" -f ($i + 1), $results[$i].Category, $results[$i].Label)
    }

    $choice = Read-Host "Select an item or press Enter to cancel"
    if (-not $choice) { return }

    if ($choice -as [int] -and $choice -ge 1 -and $choice -le $results.Count) {
        $item = $results[$choice - 1]
        Invoke-OpsToolkitLauncherItem -Command $item.Command -Label $item.Label
    }
}

# -------------------------------
# Main launcher menu
# -------------------------------
function Start-OpsToolkitLauncher {

    while ($true) {
        Write-Host "`n=== OpsToolkit Launcher ===" -ForegroundColor Cyan

        for ($i = 0; $i -lt $Script:Categories.Count; $i++) {
            Write-Host ("{0,2}. {1}" -f ($i + 1), $Script:Categories[$i].Name)
        }

        Write-Host "  S. Search"
        Write-Host "  U. Check for Updates"
        Write-Host "  X. Exit" -ForegroundColor Yellow

        $choice = Read-Host "Select an option"

        switch -Regex ($choice) {
            '^[Xx]$' { return }
            '^[Ss]$' { Search-OpsToolkit }
            '^[Uu]$' { Invoke-OpsToolkitUpdate }
            default {
                if ($choice -as [int] -and $choice -ge 1 -and $choice -le $Script:Categories.Count) {
                    Show-OpsToolkitCategory -Category $Script:Categories[$choice - 1]
                } else {
                    Write-Host "Invalid selection." -ForegroundColor Red
                }
            }
        }
    }
}

Export-ModuleMember -Function Start-OpsToolkitLauncher