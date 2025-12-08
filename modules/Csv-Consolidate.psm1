<#
    Csv-Consolidate.psm1
    ---------------------
    Unified CSV consolidation tool for OpsToolkit.
    Features:
      - Interactive prompts
      - Recursively finds CSV files
      - Merges all rows into one output CSV
      - UTF-8 safe
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Core logic
# -------------------------------
function Csv-Consolidate-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceDir,

        [Parameter(Mandatory=$true)]
        [string]$OutputFile
    )

    if (-not (Test-Path -LiteralPath $SourceDir)) {
        Write-Host "Source directory not found: $SourceDir" -ForegroundColor Red
        return $false
    }

    $csvFiles = Get-ChildItem -Path $SourceDir -Filter *.csv -Recurse -ErrorAction SilentlyContinue

    if (-not $csvFiles) {
        Write-Host "No CSV files found in: $SourceDir" -ForegroundColor Yellow
        return $false
    }

    $data = @()

    foreach ($file in $csvFiles) {
        try {
            $content = Import-Csv -LiteralPath $file.FullName
            $data += $content
        } catch {
            Write-Host "Failed to read: $($file.FullName)" -ForegroundColor Red
            Write-ModuleLog "CSV read error: $($file.FullName) :: $($_.Exception.Message)"
        }
    }

    try {
        $data | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
        Write-ModuleLog "CSV consolidated: $OutputFile"
        return $true
    } catch {
        Write-Host "Failed to write output CSV: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Csv-Consolidate {
    Write-Host "`n=== CSV Consolidation Tool ===" -ForegroundColor Cyan

    $source = Prompt-Path -Message "Directory containing CSV files" -Default "C:\Users\$env:USERNAME\Documents"
    $defaultOut = "C:\Users\$env:USERNAME\Desktop\consolidated.csv"
    $output = Prompt-String -Message "Output CSV file" -Default $defaultOut

    Write-Host "`nConsolidating CSV files..." -ForegroundColor Cyan

    $ok = Csv-Consolidate-Core -SourceDir $source -OutputFile $output

    if ($ok) {
        Write-Host "CSV consolidation complete!" -ForegroundColor Green
        Write-Host "Saved to:`n$output"
    } else {
        Write-Host "CSV consolidation failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Csv-Consolidate, Csv-Consolidate-Core