<#
    Straighten-Images.psm1
    -----------------------
    Auto-straightens images using ImageMagick.
    Features:
      - Auto-orient
      - Deskew (auto-straighten)
      - Timestamp preservation
      - Batch processing
      - Interactive wrapper
      - Logging
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
# Core logic: straighten a single image
# -------------------------------
function Straighten-Images-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath,

        [switch]$DryRun
    )

    $srcItem = Get-Item -LiteralPath $SourcePath -ErrorAction Stop
    $origCT  = $srcItem.CreationTimeUtc
    $origWT  = $srcItem.LastWriteTimeUtc

    if ($DryRun) {
        Write-Host "[DRYRUN] magick `"$SourcePath`" -auto-orient -deskew 40% `"$OutputPath`""
        return $true
    }

    & magick "$SourcePath" -auto-orient -deskew 40% "$OutputPath"

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath)) {
        Write-Host "Straighten failed: $SourcePath" -ForegroundColor Red
        return $false
    }

    # Restore timestamps
    try {
        $outItem = Get-Item -LiteralPath $OutputPath -ErrorAction Stop
        $outItem.CreationTimeUtc  = $origCT
        $outItem.LastWriteTimeUtc = $origWT
    } catch {
        Write-Host "Warning: Could not set timestamps for $OutputPath" -ForegroundColor Yellow
    }

    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Straighten-Images {
    Write-Host "`n=== Auto-Straighten Images ===" -ForegroundColor Cyan

    if (-not (Assert-ImageMagick)) {
        Write-Host "Install ImageMagick and try again." -ForegroundColor Red
        return
    }

    $root = Prompt-Path -Message "Root folder to scan" -Default "C:\Users\$env:USERNAME\Pictures"
    $dry = Prompt-YesNo -Message "Dry run only" -Default $false

    $extensions = @(".jpg", ".jpeg", ".png", ".tif", ".tiff", ".heic", ".webp")

    Write-Host "`nScanning for images..." -ForegroundColor Cyan

    $targets = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
               Where-Object { $extensions -contains $_.Extension.ToLower() }

    if (-not $targets) {
        Write-Host "No images found." -ForegroundColor Yellow
        return
    }

    $success = 0
    $fail = 0

    foreach ($t in $targets) {
        $outPath = $t.FullName  # overwrite in place

        if (Straighten-Images-Core -SourcePath $t.FullName -OutputPath $outPath -DryRun:$dry) {
            Write-Host "Straightened: $($t.Name)" -ForegroundColor Green
            $success++
        } else {
            $fail++
        }
    }

    Write-Host "`nDone. Success: $success  Failed: $fail" -ForegroundColor Cyan
    Write-ModuleLog "Straighten-Images completed: $success success, $fail failed"
}

Export-ModuleMember -Function Straighten-Images, Straighten-Images-Core