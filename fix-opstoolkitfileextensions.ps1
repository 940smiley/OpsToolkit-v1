<#
    Fix-OpsToolkitFileExtensions.ps1
    --------------------------------
    Explicitly fixes bad extensions in the OpsToolkit tree.

    Examples:
      C:\OpsToolkit\Install-OpsToolkit.psm1.txt      -> Install-OpsToolkit.psm1
      C:\OpsToolkit\modules\Csv-ToPdf.psm1.log       -> Csv-ToPdf.psm1
#>

param(
    [string]$Root = "C:\OpsToolkit"
)

if (-not (Test-Path $Root)) {
    Write-Host "Root path not found: $Root" -ForegroundColor Red
    exit 1
}

$logDir  = Join-Path $Root "logs"
$logPath = Join-Path $logDir "FileFix.log"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
New-Item -ItemType File -Path $logPath -Force | Out-Null

function Write-FixLog {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logPath -Value $line
}

Write-Host ""
Write-Host "=== OpsToolkit File Extension Fixer (Explicit) ===" -ForegroundColor Cyan
Write-FixLog "Starting explicit file extension fix in $Root"

# Ordered from most specific to least
$patterns = @(
    @{ Suffix = ".psm1.txt"; TargetExt = ".psm1" },
    @{ Suffix = ".psm1.log"; TargetExt = ".psm1" },
    @{ Suffix = ".ps1.txt";  TargetExt = ".ps1"  },
    @{ Suffix = ".ps1.log";  TargetExt = ".ps1"  },
    @{ Suffix = ".md.txt";   TargetExt = ".md"   },
    @{ Suffix = ".json.txt"; TargetExt = ".json" },
    @{ Suffix = ".log.txt";  TargetExt = ".log"  }
)

$renamed = 0
$skipped = 0

$allFiles = Get-ChildItem -Path $Root -Recurse -File

foreach ($file in $allFiles) {
    $name     = $file.Name
    $fullPath = $file.FullName
    $newName  = $null

    foreach ($p in $patterns) {
        $suffix    = $p.Suffix
        $targetExt = $p.TargetExt

        if ($name.ToLowerInvariant().EndsWith($suffix)) {
            $base = $name.Substring(0, $name.Length - $suffix.Length)
            $newName = $base + $targetExt
            break
        }
    }

    if (-not $newName) {
        $skipped++
        continue
    }

    if ($newName -eq $name) {
        $skipped++
        continue
    }

    $newPath = Join-Path $file.DirectoryName $newName

    if (Test-Path $newPath) {
        Write-Host "SKIP (target exists): ${name} -> ${newName}" -ForegroundColor Yellow
        Write-FixLog "Skipped rename (target exists): ${fullPath} -> ${newPath}"
        $skipped++
        continue
    }

    Write-Host "RENAME: ${name} -> ${newName}" -ForegroundColor Green
    Write-FixLog "Renamed: ${fullPath} -> ${newPath}"

    try {
        Rename-Item -LiteralPath $fullPath -NewName $newName -Force
        $renamed++
    } catch {
        Write-Host "ERROR renaming ${name}: $($_.Exception.Message)" -ForegroundColor Red
        Write-FixLog "ERROR renaming ${fullPath}: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host "  Renamed: $renamed"
Write-Host "  Skipped: $skipped"
Write-FixLog "Explicit extension fix complete. Renamed=$renamed, Skipped=$skipped"