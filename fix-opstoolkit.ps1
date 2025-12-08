<#
    Fix-OpsToolkit.ps1
    -------------------
    Smarter linter/fixer for the OpsToolkit tree.

    Features:
      - Fixes bad extensions (.psm1.txt, .ps1.txt.log, .md.txt, etc.)
      - Uses content heuristics to infer correct extension when needed
      - Generates a sanity report for PowerShell modules
      - Logs everything to logs\OpsToolkitFix.log
#>

param(
    [string]$Root = "$env:USERPROFILE\OpsToolkit"
)

if (-not (Test-Path $Root)) {
    Write-Host "Root path not found: $Root" -ForegroundColor Red
    exit 1
}

$logDir  = Join-Path $Root "logs"
$logPath = Join-Path $logDir "OpsToolkitFix.log"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
New-Item -ItemType File -Path $logPath -Force | Out-Null

function Write-FixLog {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logPath -Value $line
}

Write-Host ""
Write-Host "=== OpsToolkit Linter + Fixer ===" -ForegroundColor Cyan
Write-FixLog "Starting OpsToolkit fix in $Root"

# Known suffix fix patterns (order matters: longer first)
$knownPatterns = @(
    ".psm1.txt.log",
    ".psm1.txt",
    ".ps1.txt.log",
    ".ps1.txt",
    ".md.txt.log",
    ".md.txt",
    ".json.txt.log",
    ".json.txt",
    ".log.txt"
)

$patternToExt = @{
    ".psm1.txt.log" = ".psm1"
    ".psm1.txt"     = ".psm1"
    ".ps1.txt.log"  = ".ps1"
    ".ps1.txt"      = ".ps1"
    ".md.txt.log"   = ".md"
    ".md.txt"       = ".md"
    ".json.txt.log" = ".json"
    ".json.txt"     = ".json"
    ".log.txt"      = ".log"
}

# Heuristic content classifier
function Get-InferredExtension {
    param([string]$Path)

    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    # If already a "good" extension, return as-is
    if ($ext -in @(".psm1", ".ps1", ".md", ".json", ".log")) {
        return $ext
    }

    $sample = ""
    try {
        $sample = Get-Content -Path $Path -TotalCount 20 -ErrorAction Stop | Out-String
    } catch {
        return $ext
    }

    if ($sample -match "Export-ModuleMember" -or $sample -match "\.psm1") {
        return ".psm1"
    }

    if ($sample -match "^param\(" -or $sample -match "function " -or $sample -match "Write-Host") {
        return ".ps1"
    }

    if ($sample.TrimStart().StartsWith("{") -or $sample.TrimStart().StartsWith("[")) {
        return ".json"
    }

    if ($sample -match "# " -or $sample -match "## " -or $sample -match "\[.*\]\(.*\)") {
        return ".md"
    }

    return $ext
}

$renamedCount = 0
$skippedCount = 0

# Pass 1: extension fixing
$allFiles = Get-ChildItem -Path $Root -Recurse -File

foreach ($file in $allFiles) {
    $originalName = $file.Name
    $fullPath     = $file.FullName
    $newName      = $null

    # First: see if it matches any known "bad" pattern
    foreach ($badPattern in $knownPatterns) {
        if ($originalName.ToLowerInvariant().EndsWith($badPattern)) {
            $targetExt = $patternToExt[$badPattern]
            $baseName  = $originalName.Substring(0, $originalName.Length - $badPattern.Length)
            $newName   = $baseName + $targetExt
            break
        }
    }

    # If no direct pattern match, optionally use content inference
    if (-not $newName -and ($originalName -match "\.psm1\." -or $originalName -match "\.ps1\.")) {
        $inferred = Get-InferredExtension -Path $fullPath
        if ($inferred -in @(".psm1", ".ps1")) {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($originalName)
            $newName = $base + $inferred
        }
    }

    if (-not $newName) {
        $skippedCount++
        continue
    }

    if ($newName -eq $originalName) {
        $skippedCount++
        continue
    }

    $newPath = Join-Path $file.DirectoryName $newName

    if (Test-Path $newPath) {
        Write-Host "SKIP (exists): ${originalName} -> ${newName}" -ForegroundColor Yellow
        Write-FixLog "Skipped rename (target exists): ${fullPath} -> ${newPath}"
        $skippedCount++
        continue
    }

    Write-Host "RENAME: ${originalName} -> ${newName}" -ForegroundColor Green
    Write-FixLog "Renamed: ${fullPath} -> ${newPath}"

    try {
        Rename-Item -LiteralPath $fullPath -NewName $newName -Force
        $renamedCount++
    } catch {
        Write-Host "ERROR renaming ${originalName}: $($_.Exception.Message)" -ForegroundColor Red
        Write-FixLog "ERROR renaming ${fullPath}: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Extension fix summary:" -ForegroundColor Cyan
Write-Host "  Renamed: $renamedCount"
Write-Host "  Skipped: $skippedCount"
Write-FixLog "Extension fix complete. Renamed=$renamedCount, Skipped=$skippedCount"

# Pass 2: module sanity report
Write-Host ""
Write-Host "Analyzing modules for sanity checks..." -ForegroundColor Cyan
Write-FixLog "Starting module sanity analysis"

$moduleReport = @()

$moduleFiles = Get-ChildItem -Path $Root -Recurse -File -Include *.psm1

foreach ($mod in $moduleFiles) {
    $text = ""
    try {
        $text = Get-Content -Path $mod.FullName -Raw -ErrorAction Stop
    } catch {
        continue
    }

    $exports = @()
    if ($text -match "Export-ModuleMember") {
        $exportLines = $text -split "`n" | Where-Object { $_ -match "Export-ModuleMember" }
        $exports = $exportLines
    }

    $hasCore = ($text -match "-Core")
    $importsUtility = ($text -match "Utility\\Prompts.psm1" -or $text -match "Utility\\Logging.psm1" -or $text -match "Utility\\FileSystem.psm1")

    $moduleReport += [pscustomobject]@{
        Path           = $mod.FullName
        Name           = $mod.Name
        HasExports     = [bool]$exports
        HasCoreFunc    = $hasCore
        ImportsUtility = $importsUtility
    }
}

$reportPath = Join-Path $logDir "OpsToolkitModuleReport.csv"
$moduleReport | Export-Csv -Path $reportPath -NoTypeInformation -Force

Write-Host "Module sanity report written to:" -ForegroundColor Cyan
Write-Host "  $reportPath"
Write-FixLog "Module sanity report saved to $reportPath"

Write-Host ""
Write-Host "OpsToolkit Linter + Fixer complete." -ForegroundColor Green
Write-FixLog "OpsToolkit fix complete."