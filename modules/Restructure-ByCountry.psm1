<#
    Restructure-ByCountry.psm1
    ---------------------------
    Automatically reorganizes files into country-based folders.
    Features:
      - Detects country codes in filenames
      - Auto-creates country folders
      - Collision-proof moves
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Extract country code from filename
# Supports:
#   - USA_123.jpg
#   - CAN-001.png
#   - DE 554.jpg
#   - FRA (12).tif
# -------------------------------
function Get-CountryCodeFromName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    # Match 2–4 uppercase letters at start of filename
    $pattern = '^(?<code>[A-Z]{2,4})[\s\-_\.]'
    $m = [regex]::Match($Name, $pattern)

    if ($m.Success) {
        return $m.Groups["code"].Value
    }

    return $null
}

# -------------------------------
# Core logic
# -------------------------------
function Restructure-ByCountry-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RootDir
    )

    if (-not (Test-Path -LiteralPath $RootDir)) {
        Write-Host "Directory not found: $RootDir" -ForegroundColor Red
        return $false
    }

    $files = Get-ChildItem -LiteralPath $RootDir -Recurse -File -ErrorAction SilentlyContinue

    if (-not $files) {
        Write-Host "No files found." -ForegroundColor Yellow
        return $false
    }

    $moved = 0
    $skipped = 0

    foreach ($file in $files) {
        $code = Get-CountryCodeFromName -Name $file.Name

        if (-not $code) {
            $skipped++
            continue
        }

        $targetDir = Join-Path $RootDir $code
        Ensure-Dir -Path $targetDir

        $dest = Join-Path $targetDir $file.Name
        $movedPath = Move-FileSafe -Source $file.FullName -Destination $dest

        if ($movedPath) {
            Write-ModuleLog "Moved: $($file.FullName) → $movedPath"
            $moved++
        } else {
            Write-Host "Failed to move: $($file.FullName)" -ForegroundColor Red
        }
    }

    Write-Host "`nMoved: $moved" -ForegroundColor Cyan
    Write-Host "Skipped (no country code): $skipped" -ForegroundColor Cyan
    Write-ModuleLog "Restructure-ByCountry completed: $moved moved, $skipped skipped"

    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Restructure-ByCountry {
    Write-Host "`n=== Restructure Files by Country ===" -ForegroundColor Cyan

    $root = Prompt-Path -Message "Root folder to scan" -Default "C:\Users\$env:USERNAME\Pictures"

    Write-Host "`nScanning and restructuring..." -ForegroundColor Cyan

    $ok = Restructure-ByCountry-Core -RootDir $root

    if ($ok) {
        Write-Host "Restructure complete." -ForegroundColor Green
    } else {
        Write-Host "Restructure failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Restructure-ByCountry, Restructure-ByCountry-Core