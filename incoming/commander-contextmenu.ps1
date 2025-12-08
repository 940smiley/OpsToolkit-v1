<#
    Commander-ContextMenu.ps1
    Author: Josh + Copilot

    Features:
      - Adds a unified "Commander" submenu to the context menu for:
          * Files (*)
          * Folders (Directory)
          * Directory background (Directory\Background)
      - Within Commander:
          * PowerShell tools
          * Copy tools (many variants)
          * Folder tools
      - Master toggle: Enable/Disable Commander
      - Installer, Disabler, Uninstaller (all HKCU, no admin required)
#>

# =========================
# Configuration
# =========================

$CommanderKeyName   = "Commander"
$CommanderDisplay   = "Commander"
$CommanderRootFiles = "HKCU:\Software\Classes\*\shell\$CommanderKeyName"
$CommanderRootDir   = "HKCU:\Software\Classes\Directory\shell\$CommanderKeyName"
$CommanderRootBg    = "HKCU:\Software\Classes\Directory\Background\shell\$CommanderKeyName"

$PwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
$VSCodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
$TerminalPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe" # Windows Terminal (if present)

# =========================
# Helper functions
# =========================

function New-RegistryKey {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    New-RegistryKey -Path $Path
    Set-ItemProperty -Path $Path -Name $Name -Value $Value
}

function Remove-RegistryKeySafe {
    param(
        [string]$Path
    )
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }
}

# =========================
# Copy command builders
# =========================

function Get-CmdCopyLiteral {
    param([string]$Placeholder)
    # Placeholder is "%1" or "%V"
    "cmd.exe /c echo|set /p=`"$Placeholder`" | clip"
}

function Get-CmdCopyUNC {
    param([string]$Placeholder)
    # Basic UNC-style (for local drives it will look similar, but useful for shares)
    "cmd.exe /c for %A in ($Placeholder) do @echo \\%computername%\%~pA%~nxA | clip"
}

function Get-PwshCopyScript {
    param([string]$Script)
    # Wrap a PowerShell snippet as a command
    "powershell.exe -NoLogo -NoProfile -Command $Script"
}

# =========================
# Commander structure
# =========================

function Install-Commander-Core {
    Write-Host "Installing Commander core menus..." -ForegroundColor Cyan

    # 1. Files root
    New-RegistryKey -Path $CommanderRootFiles
    Set-RegistryValue -Path $CommanderRootFiles -Name "(Default)" -Value $CommanderDisplay
    Set-RegistryValue -Path $CommanderRootFiles -Name "SubCommands" -Value ""
    Set-RegistryValue -Path $CommanderRootFiles -Name "Icon" -Value "imageres.dll,-5302"

    # 2. Folders root
    New-RegistryKey -Path $CommanderRootDir
    Set-RegistryValue -Path $CommanderRootDir -Name "(Default)" -Value $CommanderDisplay
    Set-RegistryValue -Path $CommanderRootDir -Name "SubCommands" -Value ""
    Set-RegistryValue -Path $CommanderRootDir -Name "Icon" -Value "imageres.dll,-5302"

    # 3. Directory background root
    New-RegistryKey -Path $CommanderRootBg
    Set-RegistryValue -Path $CommanderRootBg -Name "(Default)" -Value $CommanderDisplay
    Set-RegistryValue -Path $CommanderRootBg -Name "SubCommands" -Value ""
    Set-RegistryValue -Path $CommanderRootBg -Name "Icon" -Value "imageres.dll,-5302"
}

# -------------------------
# PowerShell submenu
# -------------------------
function Install-Commander-PowerShell {
    Write-Host "Installing Commander PowerShell tools..." -ForegroundColor Cyan

    if (-not (Test-Path $PwshPath)) {
        Write-Warning "PowerShell 7 not found at $PwshPath. PowerShell 7 items will still be created but may not work until pwsh is installed."
    }

    # Files - PowerShell submenu
    $psFiles = "$CommanderRootFiles\shell\ps"
    New-RegistryKey -Path $psFiles
    Set-RegistryValue -Path $psFiles -Name "(Default)" -Value "PowerShell"
    Set-RegistryValue -Path $psFiles -Name "Icon" -Value $PwshPath

    # Run with PowerShell 7
    $run7 = "$psFiles\shell\runpwsh7"
    New-RegistryKey -Path $run7
    Set-RegistryValue -Path $run7 -Name "(Default)" -Value "Run with PowerShell 7"
    Set-RegistryValue -Path $run7 -Name "Icon" -Value $PwshPath
    New-RegistryKey -Path "$run7\command"
    Set-RegistryValue -Path "$run7\command" -Name "(Default)" -Value "`"$PwshPath`" -NoExit -File `"%1`""

    # Open with PowerShell 7
    $open7 = "$psFiles\shell\openpwsh7"
    New-RegistryKey -Path $open7
    Set-RegistryValue -Path $open7 -Name "(Default)" -Value "Open with PowerShell 7"
    Set-RegistryValue -Path $open7 -Name "Icon" -Value $PwshPath
    New-RegistryKey -Path "$open7\command"
    Set-RegistryValue -Path "$open7\command" -Name "(Default)" -Value "`"$PwshPath`" `"%1`""

    # Edit in Notepad
    $editNotepad = "$psFiles\shell\edit_notepad"
    New-RegistryKey -Path $editNotepad
    Set-RegistryValue -Path $editNotepad -Name "(Default)" -Value "Edit in Notepad"
    New-RegistryKey -Path "$editNotepad\command"
    Set-RegistryValue -Path "$editNotepad\command" -Name "(Default)" -Value "notepad.exe `"%1`""

    # Edit in PowerShell ISE
    $editISE = "$psFiles\shell\edit_ise"
    New-RegistryKey -Path $editISE
    Set-RegistryValue -Path $editISE -Name "(Default)" -Value "Edit in PowerShell ISE"
    New-RegistryKey -Path "$editISE\command"
    Set-RegistryValue -Path "$editISE\command" -Name "(Default)" -Value "powershell_ise.exe `"%1`""

    # Edit in VS Code (if available)
    if (Test-Path $VSCodePath) {
        $editCode = "$psFiles\shell\edit_code"
        New-RegistryKey -Path $editCode
        Set-RegistryValue -Path $editCode -Name "(Default)" -Value "Edit in VS Code"
        Set-RegistryValue -Path $editCode -Name "Icon" -Value $VSCodePath
        New-RegistryKey -Path "$editCode\command"
        Set-RegistryValue -Path "$editCode\command" -Name "(Default)" -Value "`"$VSCodePath`" `"%1`""
    }

    # Folder: Open PowerShell 7 here
    $psDir = "$CommanderRootDir\shell\ps_here"
    New-RegistryKey -Path $psDir
    Set-RegistryValue -Path $psDir -Name "(Default)" -Value "Open PowerShell 7 Here"
    Set-RegistryValue -Path $psDir -Name "Icon" -Value $PwshPath
    New-RegistryKey -Path "$psDir\command"
    Set-RegistryValue -Path "$psDir\command" -Name "(Default)" -Value "`"$PwshPath`" -NoExit -Command Set-Location '%1'"

    # Background: Open PowerShell 7 here
    $psBg = "$CommanderRootBg\shell\ps_here"
    New-RegistryKey -Path $psBg
    Set-RegistryValue -Path $psBg -Name "(Default)" -Value "Open PowerShell 7 Here"
    Set-RegistryValue -Path $psBg -Name "Icon" -Value $PwshPath
    New-RegistryKey -Path "$psBg\command"
    Set-RegistryValue -Path "$psBg\command" -Name "(Default)" -Value "`"$PwshPath`" -NoExit -Command Set-Location '%V'"

    # Folder: Open in VS Code (if available)
    if (Test-Path $VSCodePath) {
        $codeDir = "$CommanderRootDir\shell\code_here"
        New-RegistryKey -Path $codeDir
        Set-RegistryValue -Path $codeDir -Name "(Default)" -Value "Open Folder in VS Code"
        Set-RegistryValue -Path $codeDir -Name "Icon" -Value $VSCodePath
        New-RegistryKey -Path "$codeDir\command"
        Set-RegistryValue -Path "$codeDir\command" -Name "(Default)" -Value "`"$VSCodePath`" `"%1`""
    }

    # Folder: Open in Terminal (if available)
    if (Test-Path $TerminalPath) {
        $termDir = "$CommanderRootDir\shell\terminal_here"
        New-RegistryKey -Path $termDir
        Set-RegistryValue -Path $termDir -Name "(Default)" -Value "Open in Terminal"
        Set-RegistryValue -Path $termDir -Name "Icon" -Value $TerminalPath
        New-RegistryKey -Path "$termDir\command"
        Set-RegistryValue -Path "$termDir\command" -Name "(Default)" -Value "`"$TerminalPath`" -d `"%1`""
    }
}

# -------------------------
# Copy submenu
# -------------------------
function Install-Commander-Copy {
    Write-Host "Installing Commander Copy tools..." -ForegroundColor Cyan

    # Files copy submenu
    $copyFiles = "$CommanderRootFiles\shell\copy"
    New-RegistryKey -Path $copyFiles
    Set-RegistryValue -Path $copyFiles -Name "(Default)" -Value "Copy"
    Set-RegistryValue -Path $copyFiles -Name "Icon" -Value "imageres.dll,-5302"

    # Basic: Copy as Path
    $copyPath = "$copyFiles\shell\copy_path"
    New-RegistryKey -Path $copyPath
    Set-RegistryValue -Path $copyPath -Name "(Default)" -Value "Copy as Path"
    New-RegistryKey -Path "$copyPath\command"
    Set-RegistryValue -Path "$copyPath\command" -Name "(Default)" -Value (Get-CmdCopyLiteral "%1")

    # UNC path
    $copyUNC = "$copyFiles\shell\copy_unc"
    New-RegistryKey -Path $copyUNC
    Set-RegistryValue -Path $copyUNC -Name "(Default)" -Value "Copy UNC Path"
    New-RegistryKey -Path "$copyUNC\command"
    Set-RegistryValue -Path "$copyUNC\command" -Name "(Default)" -Value (Get-CmdCopyUNC "%1")

    # Filename only
    $copyFilename = "$copyFiles\shell\copy_filename"
    New-RegistryKey -Path $copyFilename
    Set-RegistryValue -Path $copyFilename -Name "(Default)" -Value "Copy Filename"
    New-RegistryKey -Path "$copyFilename\command"
    $scriptFilename = " "`"`$p=`"%1`"; [IO.Path]::GetFileName(`$p) | Set-Clipboard"
    Set-RegistryValue -Path "$copyFilename\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptFilename)

    # Parent folder path
    $copyParent = "$copyFiles\shell\copy_parent"
    New-RegistryKey -Path $copyParent
    Set-RegistryValue -Path $copyParent -Name "(Default)" -Value "Copy Parent Folder Path"
    New-RegistryKey -Path "$copyParent\command"
    $scriptParent = " "`"`$p=`"%1`"; [IO.Path]::GetDirectoryName(`$p) | Set-Clipboard"
    Set-RegistryValue -Path "$copyParent\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptParent)

    # Relative path (relative to current folder)
    $copyRel = "$copyFiles\shell\copy_relative"
    New-RegistryKey -Path $copyRel
    Set-RegistryValue -Path $copyRel -Name "(Default)" -Value "Copy Relative Path"
    New-RegistryKey -Path "$copyRel\command"
    $scriptRel = " "`"`$p=`"%1`"; `$cwd=(Get-Location).ProviderPath; `$rel=[IO.Path]::GetRelativePath(`$cwd, `$p); `$rel | Set-Clipboard"
    Set-RegistryValue -Path "$copyRel\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptRel)

    # WSL path (/mnt/c/...)
    $copyWSL = "$copyFiles\shell\copy_wsl"
    New-RegistryKey -Path $copyWSL
    Set-RegistryValue -Path $copyWSL -Name "(Default)" -Value "Copy WSL Path"
    New-RegistryKey -Path "$copyWSL\command"
    $scriptWSL = " "`"`$p=`"%1`"; `$p = `$p -replace '\\','/'; `$wsl = '/mnt/' + `$p.Substring(0,1).ToLower() + `$p.Substring(2); `$wsl | Set-Clipboard"
    Set-RegistryValue -Path "$copyWSL\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptWSL)

    # Git-style path (c:/path/file)
    $copyGit = "$copyFiles\shell\copy_git"
    New-RegistryKey -Path $copyGit
    Set-RegistryValue -Path $copyGit -Name "(Default)" -Value "Copy Git Path"
    New-RegistryKey -Path "$copyGit\command"
    $scriptGit = " "`"`$p=`"%1`"; `$git = `$p -replace '\\','/'; `$git | Set-Clipboard"
    Set-RegistryValue -Path "$copyGit\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptGit)

    # JSON-escaped path
    $copyJson = "$copyFiles\shell\copy_json"
    New-RegistryKey -Path $copyJson
    Set-RegistryValue -Path $copyJson -Name "(Default)" -Value "Copy JSON-Escaped Path"
    New-RegistryKey -Path "$copyJson\command"
    $scriptJson = " "`"`$p=`"%1`"; `$json = [System.Text.Json.JsonSerializer]::Serialize(`$p); `$json | Set-Clipboard"
    Set-RegistryValue -Path "$copyJson\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptJson)

    # PowerShell-escaped path
    $copyPS = "$copyFiles\shell\copy_ps"
    New-RegistryKey -Path $copyPS
    Set-RegistryValue -Path $copyPS -Name "(Default)" -Value "Copy PowerShell-Escaped Path"
    New-RegistryKey -Path "$copyPS\command"
    $scriptPS = " "`"`$p=`"%1`"; `$esc = `$p -replace '`'', ''''''; `$out = '`'' + `$esc + '`''; `$out | Set-Clipboard"
    Set-RegistryValue -Path "$copyPS\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptPS)

    # URL-encoded path
    $copyUrl = "$copyFiles\shell\copy_url"
    New-RegistryKey -Path $copyUrl
    Set-RegistryValue -Path $copyUrl -Name "(Default)" -Value "Copy URL-Encoded Path"
    New-RegistryKey -Path "$copyUrl\command"
    $scriptUrl = " "`"`$p=`"%1`"; `$enc = [System.Uri]::EscapeDataString(`$p); `$enc | Set-Clipboard"
    Set-RegistryValue -Path "$copyUrl\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptUrl)

    # Base64-encoded path
    $copyB64 = "$copyFiles\shell\copy_b64"
    New-RegistryKey -Path $copyB64
    Set-RegistryValue -Path $copyB64 -Name "(Default)" -Value "Copy Base64-Encoded Path"
    New-RegistryKey -Path "$copyB64\command"
    $scriptB64 = " "`"`$p=`"%1`"; `$bytes = [System.Text.Encoding]::UTF8.GetBytes(`$p); `$b64 = [Convert]::ToBase64String(`$bytes); `$b64 | Set-Clipboard"
    Set-RegistryValue -Path "$copyB64\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptB64)

    # Folders: Copy folder path
    $copyDir = "$CommanderRootDir\shell\copy_folder"
    New-RegistryKey -Path $copyDir
    Set-RegistryValue -Path $copyDir -Name "(Default)" -Value "Copy Folder Path"
    New-RegistryKey -Path "$copyDir\command"
    Set-RegistryValue -Path "$copyDir\command" -Name "(Default)" -Value (Get-CmdCopyLiteral "%1")

    # Background: Copy current folder path
    $copyBg = "$CommanderRootBg\shell\copy_folder"
    New-RegistryKey -Path $copyBg
    Set-RegistryValue -Path $copyBg -Name "(Default)" -Value "Copy Folder Path"
    New-RegistryKey -Path "$copyBg\command"
    Set-RegistryValue -Path "$copyBg\command" -Name "(Default)" -Value (Get-CmdCopyLiteral "%V")
}

# -------------------------
# Extra tools (file metadata)
# -------------------------
function Install-Commander-Extras {
    Write-Host "Installing Commander extra tools..." -ForegroundColor Cyan

    $extraFiles = "$CommanderRootFiles\shell\extra"
    New-RegistryKey -Path $extraFiles
    Set-RegistryValue -Path $extraFiles -Name "(Default)" -Value "Extra"
    Set-RegistryValue -Path $extraFiles -Name "Icon" -Value "imageres.dll,-5302"

    # Hash (SHA256)
    $hashKey = "$extraFiles\shell\hash"
    New-RegistryKey -Path $hashKey
    Set-RegistryValue -Path $hashKey -Name "(Default)" -Value "Copy SHA256 Hash"
    New-RegistryKey -Path "$hashKey\command"
    $scriptHash = " "`"`$p=`"%1`"; `$hash = Get-FileHash -Algorithm SHA256 -Path `$p; `$hash.Hash | Set-Clipboard"
    Set-RegistryValue -Path "$hashKey\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptHash)

    # File size
    $sizeKey = "$extraFiles\shell\size"
    New-RegistryKey -Path $sizeKey
    Set-RegistryValue -Path $sizeKey -Name "(Default)" -Value "Copy File Size (bytes)"
    New-RegistryKey -Path "$sizeKey\command"
    $scriptSize = " "`"`$p=`"%1`"; `$info = Get-Item `$p; `$info.Length.ToString() | Set-Clipboard"
    Set-RegistryValue -Path "$sizeKey\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptSize)

    # File type (extension)
    $typeKey = "$extraFiles\shell\type"
    New-RegistryKey -Path $typeKey
    Set-RegistryValue -Path $typeKey -Name "(Default)" -Value "Copy File Type"
    New-RegistryKey -Path "$typeKey\command"
    $scriptType = " "`"`$p=`"%1`"; `$ext = [IO.Path]::GetExtension(`$p); `$ext | Set-Clipboard"
    Set-RegistryValue -Path "$typeKey\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptType)

    # Creation date
    $createKey = "$extraFiles\shell\created"
    New-RegistryKey -Path $createKey
    Set-RegistryValue -Path $createKey -Name "(Default)" -Value "Copy Creation Date"
    New-RegistryKey -Path "$createKey\command"
    $scriptCreate = " "`"`$p=`"%1`"; `$info = Get-Item `$p; `$info.CreationTime.ToString('o') | Set-Clipboard"
    Set-RegistryValue -Path "$createKey\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptCreate)

    # Modified date
    $modKey = "$extraFiles\shell\modified"
    New-RegistryKey -Path $modKey
    Set-RegistryValue -Path $modKey -Name "(Default)" -Value "Copy Modified Date"
    New-RegistryKey -Path "$modKey\command"
    $scriptMod = " "`"`$p=`"%1`"; `$info = Get-Item `$p; `$info.LastWriteTime.ToString('o') | Set-Clipboard"
    Set-RegistryValue -Path "$modKey\command" -Name "(Default)" -Value (Get-PwshCopyScript $scriptMod)
}

# =========================
# Enable/Disable Commander
# =========================

function Disable-Commander {
    Write-Host "Disabling Commander (hiding context entries)..." -ForegroundColor Yellow

    foreach ($root in @($CommanderRootFiles, $CommanderRootDir, $CommanderRootBg)) {
        if (Test-Path $root) {
            Set-RegistryValue -Path $root -Name "LegacyDisable" -Value ""
        }
    }
}

function Enable-Commander {
    Write-Host "Enabling Commander (showing context entries)..." -ForegroundColor Green

    foreach ($root in @($CommanderRootFiles, $CommanderRootDir, $CommanderRootBg)) {
        if (Test-Path $root) {
            Remove-ItemProperty -Path $root -Name "LegacyDisable" -ErrorAction SilentlyContinue
        }
    }
}

function Uninstall-Commander {
    Write-Host "Uninstalling Commander (removing all registry entries)..." -ForegroundColor Red

    Remove-RegistryKeySafe -Path $CommanderRootFiles
    Remove-RegistryKeySafe -Path $CommanderRootDir
    Remove-RegistryKeySafe -Path $CommanderRootBg
}

# =========================
# Master Menu
# =========================

Write-Host ""
Write-Host "Commander Context Menu Suite" -ForegroundColor Cyan
Write-Host "1. Install / Update Commander"
Write-Host "2. Enable Commander (show choices)"
Write-Host "3. Disable Commander (hide choices)"
Write-Host "4. Uninstall Commander (remove everything)"
Write-Host ""

$choice = Read-Host "Select an option (1-4)"

switch ($choice) {
    "1" {
        Install-Commander-Core
        Install-Commander-PowerShell
        Install-Commander-Copy
        Install-Commander-Extras
        Enable-Commander
        Write-Host "Commander installed and enabled." -ForegroundColor Green
    }
    "2" {
        Enable-Commander
        Write-Host "Commander enabled." -ForegroundColor Green
    }
    "3" {
        Disable-Commander
        Write-Host "Commander disabled (entries hidden)." -ForegroundColor Yellow
    }
    "4" {
        Uninstall-Commander
        Write-Host "Commander uninstalled." -ForegroundColor Red
    }
    default {
        Write-Host "No valid selection made. Exiting." -ForegroundColor DarkGray
    }
}