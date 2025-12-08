<#
    Install-WindowsFonts.psm1
    --------------------------
    Installs custom fonts (.ttf, .otf) safely.
    Features:
      - Duplicate detection
      - Registry-safe installation
      - Copies to Windows Fonts directory
      - Verification
      - Logging
      - Interactive wrapper
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Verify a font is installed
# -------------------------------
function Test-FontInstalled {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FontFile
    )

    $name = Split-Path $FontFile -Leaf
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

    try {
        $entries = Get-ItemProperty -Path $regPath
        return ($entries.PSObject.Properties.Value -contains $name)
    } catch {
        return $false
    }
}

# -------------------------------
# Install a single font
# -------------------------------
function Install-FontSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FontPath
    )

    $fontName = Split-Path $FontPath -Leaf
    $fontsDir = "$env:WINDIR\Fonts"
    $destPath = Join-Path $fontsDir $fontName

    if (Test-FontInstalled -FontFile $fontName) {
        Write-Host "Already installed: $fontName" -ForegroundColor Gray
        return $true
    }

    Write-Host "Installing: $fontName..." -ForegroundColor Cyan

    try {
        Copy-Item -LiteralPath $FontPath -Destination $destPath -Force
    } catch {
        Write-Host "Failed to copy font: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    # Registry entry
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $regName = [System.IO.Path]::GetFileNameWithoutExtension($fontName) + " (TrueType)"

    try {
        New-ItemProperty -Path $regPath -Name $regName -Value $fontName -PropertyType String -Force | Out-Null
    } catch {
        Write-Host "Failed to write registry entry: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-ModuleLog "Installed font: $fontName"
    return $true
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsFonts-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceDir
    )

    if (-not (Test-Path -LiteralPath $SourceDir)) {
        Write-Host "Directory not found: $SourceDir" -ForegroundColor Red
        return $false
    }

    $fonts = Get-ChildItem -LiteralPath $SourceDir -File -Include *.ttf, *.otf -ErrorAction SilentlyContinue

    if (-not $fonts) {
        Write-Host "No font files found." -ForegroundColor Yellow
        return $false
    }

    $success = 0
    $fail = 0

    foreach ($f in $fonts) {
        if (Install-FontSafe -FontPath $f.FullName) {
            $success++
        } else {
            $fail++
        }
    }

    Write-Host "`nDone. Installed: $success  Failed: $fail" -ForegroundColor Cyan
    Write-ModuleLog "Install-WindowsFonts completed: $success success, $fail failed"

    return ($fail -eq 0)
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsFonts {
    Write-Host "`n=== Install Windows Fonts ===" -ForegroundColor Cyan

    $defaultDir = "C:\Users\$env:USERNAME\Downloads\Fonts"
    $dir = Prompt-Path -Message "Folder containing .ttf/.otf files" -Default $defaultDir

    Write-Host "`nInstalling fonts..." -ForegroundColor Cyan

    $ok = Install-WindowsFonts-Core -SourceDir $dir

    if ($ok) {
        Write-Host "Fonts installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Font installation completed with errors." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Install-WindowsFonts, Install-WindowsFonts-Core