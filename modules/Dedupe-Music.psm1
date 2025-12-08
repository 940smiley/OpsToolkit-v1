<#
    Dedupe-Music.psm1
    ------------------
    Audio file deduplication for OpsToolkit.
    Features:
      - SHA256 hashing
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
function Dedupe-Music-Core {
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

    $audioExt = @(".mp3", ".wav", ".flac", ".aac", ".m4a", ".ogg")
    $files = Get-ChildItem -LiteralPath $RootDir -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $audioExt -contains $_.Extension.ToLower() }

    if (-not $files) {
        Write-Host "No audio files found." -ForegroundColor Yellow
        return $false
    }

    Write-Host "Hashing audio files..." -ForegroundColor Cyan

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
                Write-ModuleLog "Music duplicate quarantined: $moved"
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
    Write-ModuleLog "Dedupe-Music completed: $processed processed, $dupes duplicates"

    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Dedupe-Music {
    Write-Host "`n=== Music Deduplication ===" -ForegroundColor Cyan

    $root = Prompt-Path -Message "Root folder to scan" -Default "C:\Users\$env:USERNAME\Music"
    $defaultQ = Join-Path $root "_Quarantine"
    $quarantine = Prompt-String -Message "Quarantine folder" -Default $defaultQ

    Write-Host "`nScanning and hashing audio files..." -ForegroundColor Cyan

    $ok = Dedupe-Music-Core -RootDir $root -QuarantineDir $quarantine

    if ($ok) {
        Write-Host "Music dedupe complete." -ForegroundColor Green
    } else {
        Write-Host "Music dedupe failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Dedupe-Music, Dedupe-Music-Core