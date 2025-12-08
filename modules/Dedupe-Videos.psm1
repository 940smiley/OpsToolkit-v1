<#
    Dedupe-Videos.psm1
    -------------------
    Video file deduplication for OpsToolkit.
    Features:
      - SHA256 hashing (large-file safe)
      - Duplicate detection
      - Quarantine folder
      - Recursive scanning
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Hashing.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Core logic
# -------------------------------
function Dedupe-Videos-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RootDir,

        [Parameter(Mandatory=$true)]
        [string]$QuarantineDir
    )

    if (-not (Test-Path -LiteralPath $RootDir)) {
        Write-Host "Directory not found: $RootDir" -ForegroundColor Red
        return $false
    }

    Ensure-Dir -Path $QuarantineDir

    $videoExt = @(".mp4", ".mov", ".avi", ".mkv", ".wmv", ".flv", ".m4v")
    $files = Get-ChildItem -LiteralPath $RootDir -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $videoExt -contains $_.Extension.ToLower() }

    if (-not $files) {
        Write-Host "No video files found." -ForegroundColor Yellow
        return $false
    }

    Write-Host "Hashing video files (this may take a while)..." -ForegroundColor Cyan

    $hashMap = @{}   # hash → original file
    $dupes = 0
    $processed = 0

    foreach ($file in $files) {
        $processed++

        $hash = Get-HashSHA256 -Path $file.FullName
        if (-not $hash) {
            Write-Host "Skipping unreadable file: $($file.FullName)" -ForegroundColor Yellow
            continue
        }

        if ($hashMap.ContainsKey($hash)) {
            # Duplicate found
            $orig = $hashMap[$hash]
            Write-Host "Duplicate detected:" -ForegroundColor Yellow
            Write-Host "  Original:   $orig"
            Write-Host "  Duplicate:  $($file.FullName)"

            $quarantinePath = Get-QuarantinePath -QuarantineRoot $QuarantineDir -SourcePath $file.FullName
            $moved = Move-FileSafe -Source $file.FullName -Destination $quarantinePath

            if ($moved) {
                Write-ModuleLog "Video duplicate quarantined: $moved"
                $dupes++
            } else {
                Write-Host "Failed to quarantine duplicate." -ForegroundColor Red
            }
        }
        else {
            # First time seeing this hash
            $hashMap[$hash] = $file.FullName
        }
    }

    Write-Host "`nProcessed: $processed" -ForegroundColor Cyan
    Write-Host "Duplicates moved: $dupes" -ForegroundColor Cyan
    Write-ModuleLog "Dedupe-Videos completed: $processed processed, $dupes duplicates"

    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Dedupe-Videos {
    Write-Host "`n=== Video Deduplication ===" -ForegroundColor Cyan

    $root = Prompt-Path -Message "Root folder to scan" -Default "C:\Users\$env:USERNAME\Videos"
    $defaultQ = Join-Path $root "_Quarantine"
    $quarantine = Prompt-String -Message "Quarantine folder" -Default $defaultQ

    Write-Host "`nScanning and hashing video files..." -ForegroundColor Cyan

    $ok = Dedupe-Videos-Core -RootDir $root -QuarantineDir $quarantine

    if ($ok) {
        Write-Host "Video dedupe complete." -ForegroundColor Green
    } else {
        Write-Host "Video dedupe failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Dedupe-Videos, Dedupe-Videos-Core