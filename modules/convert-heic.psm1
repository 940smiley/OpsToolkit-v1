<#
    Convert-Heic.psm1
    ------------------
    Unified HEIC → JPG converter for OpsToolkit.
    Features:
      - ImageMagick detection
      - Auto-orient
      - Quality control
      - Timestamp preservation
      - Duplicate JPG detection
      - Dry-run mode
      - Recursive scanning
      - Interactive wrapper
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Ensure ImageMagick is available
# -------------------------------
function Assert-ImageMagick {
    try {
        $null = & magick -version 2>$null
        return $true
    } catch {
        Write-Host "ImageMagick (magick.exe) not found in PATH." -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Convert a single HEIC file
# -------------------------------
function Convert-Heic-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,

        [Parameter(Mandatory=$true)]
        [string]$JpgPath,

        [int]$Quality = 92,

        [switch]$DryRun
    )

    $srcItem = Get-Item -LiteralPath $SourcePath -ErrorAction Stop
    $origCT  = $srcItem.CreationTimeUtc
    $origWT  = $srcItem.LastWriteTimeUtc

    if ($DryRun) {
        Write-Host "[DRYRUN] magick `"$SourcePath`" -auto-orient -quality $Quality `"$JpgPath`""
        return $true
    }

    & magick "$SourcePath" -auto-orient -quality $Quality "$JpgPath"

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $JpgPath)) {
        Write-Host "Conversion failed: $SourcePath" -ForegroundColor Red
        return $false
    }

    # Restore timestamps
    try {
        $jpgItem = Get-Item -LiteralPath $JpgPath -ErrorAction Stop
        $jpgItem.CreationTimeUtc  = $origCT
        $jpgItem.LastWriteTimeUtc = $origWT
    } catch {
        Write-Host "Warning: Could not set timestamps for $JpgPath" -ForegroundColor Yellow
    }

    # Remove original
    try {
        Remove-Item -LiteralPath $SourcePath -Force -ErrorAction Stop
    } catch {
        Write-Host "Warning: Could not delete HEIC: $SourcePath" -ForegroundColor Yellow
        return $false
    }

    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Convert-Heic {
    Write-Host "`n=== HEIC → JPG Converter ===" -ForegroundColor Cyan

    if (-not (Assert-ImageMagick)) {
        Write-Host "Install ImageMagick and try again." -ForegroundColor Red
        return
    }

    $root = Prompt-Path -Message "Enter root folder to scan" -Default "C:\Users\$env:USERNAME\Pictures"
    $quality = Prompt-Int -Message "JPEG quality (1–100)" -Default 92
    $dry = Prompt-YesNo -Message "Dry run only" -Default $false

    Write-Host "`nScanning for HEIC/HEIF files..." -ForegroundColor Cyan

    $targets = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Extension -match '^\.(heic|heif)$' }

    if (-not $targets) {
        Write-Host "No HEIC files found." -ForegroundColor Yellow
        return
    }

    $success = 0
    $fail = 0

    foreach ($t in $targets) {
        $jpg = [IO.Path]::ChangeExtension($t.FullName, '.jpg')

        if (Test-Path -LiteralPath $jpg) {
            Write-Host "JPG already exists, removing HEIC: $($t.FullName)" -ForegroundColor Gray
            if (-not $dry) {
                try {
                    Remove-Item -LiteralPath $t.FullName -Force -ErrorAction Stop
                    $success++
                } catch {
                    Write-Host "Failed to delete HEIC: $($t.FullName)" -ForegroundColor Red
                    $fail++
                }
            } else {
                $success++
            }
            continue
        }

        if (Convert-Heic-Core -SourcePath $t.FullName -JpgPath $jpg -Quality $quality -DryRun:$dry) {
            Write-Host "Converted: $([IO.Path]::GetFileName($jpg))" -ForegroundColor Green
            $success++
        } else {
            $fail++
        }
    }

    Write-Host "`nDone. Success: $success  Failed: $fail" -ForegroundColor Cyan
    Write-ModuleLog "Convert-Heic completed: $success success, $fail failed"
}

Export-ModuleMember -Function Convert-Heic, Convert-Heic-Core