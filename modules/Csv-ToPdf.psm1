<#
    Csv-ToPdf.psm1
    ----------------
    CSV → PDF converter for OpsToolkit.
    Features:
      - Converts CSV to HTML table
      - Uses wkhtmltopdf for PDF generation
      - Safe temp file handling
      - Interactive wrapper
      - Logging + error handling
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Ensure wkhtmltopdf is available
# -------------------------------
function Assert-WkHtmlToPdf {
    try {
        $null = & wkhtmltopdf --version 2>$null
        return $true
    } catch {
        Write-Host "wkhtmltopdf not found in PATH." -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Convert CSV → HTML
# -------------------------------
function Convert-CsvToHtml {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CsvPath
    )

    try {
        $rows = Import-Csv -LiteralPath $CsvPath
    } catch {
        Write-Host "Failed to read CSV: $CsvPath" -ForegroundColor Red
        return $null
    }

    if (-not $rows) {
        Write-Host "CSV is empty: $CsvPath" -ForegroundColor Yellow
        return $null
    }

    $headers = $rows[0].PSObject.Properties.Name

    $html = @()
    $html += "<html><head><meta charset='UTF-8'>"
    $html += "<style>"
    $html += "table { border-collapse: collapse; width: 100%; font-family: Arial; }"
    $html += "th, td { border: 1px solid #ccc; padding: 6px; font-size: 12px; }"
    $html += "th { background: #f0f0f0; }"
    $html += "</style></head><body>"
    $html += "<table>"
    $html += "<tr>"

    foreach ($h in $headers) {
        $html += "<th>$h</th>"
    }
    $html += "</tr>"

    foreach ($row in $rows) {
        $html += "<tr>"
        foreach ($h in $headers) {
            $val = $row.$h -replace '<','&lt;' -replace '>','&gt;'
            $html += "<td>$val</td>"
        }
        $html += "</tr>"
    }

    $html += "</table></body></html>"

    return ($html -join "`n")
}

# -------------------------------
# Core logic: CSV → PDF
# -------------------------------
function Csv-ToPdf-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CsvPath,

        [Parameter(Mandatory=$true)]
        [string]$PdfPath
    )

    if (-not (Test-Path -LiteralPath $CsvPath)) {
        Write-Host "CSV not found: $CsvPath" -ForegroundColor Red
        return $false
    }

    if (-not (Assert-WkHtmlToPdf)) {
        Write-Host "Install wkhtmltopdf and try again." -ForegroundColor Red
        return $false
    }

    # Build temp HTML
    $tempHtml = Join-Path $env:TEMP ("csv_" + [guid]::NewGuid().Guid + ".html")
    $html = Convert-CsvToHtml -CsvPath $CsvPath

    if (-not $html) {
        return $false
    }

    try {
        $html | Out-File -FilePath $tempHtml -Encoding UTF8
    } catch {
        Write-Host "Failed to write temp HTML: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    # Convert HTML → PDF
    try {
        & wkhtmltopdf "$tempHtml" "$PdfPath"
    } catch {
        Write-Host "wkhtmltopdf failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    if (-not (Test-Path -LiteralPath $PdfPath)) {
        Write-Host "PDF was not created." -ForegroundColor Red
        return $false
    }

    # Cleanup
    try { Remove-Item -LiteralPath $tempHtml -Force } catch {}

    Write-ModuleLog "CSV converted to PDF: $PdfPath"
    return $true
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Csv-ToPdf {
    Write-Host "`n=== CSV → PDF Converter ===" -ForegroundColor Cyan

    $csv = Prompt-Path -Message "CSV file to convert" -Default "C:\Users\$env:USERNAME\Desktop\input.csv"
    $defaultOut = "C:\Users\$env:USERNAME\Desktop\output.pdf"
    $pdf = Prompt-String -Message "Output PDF file" -Default $defaultOut

    Write-Host "`nConverting CSV to PDF..." -ForegroundColor Cyan

    $ok = Csv-ToPdf-Core -CsvPath $csv -PdfPath $pdf

    if ($ok) {
        Write-Host "PDF created successfully!" -ForegroundColor Green
        Write-Host "Saved to:`n$pdf"
    } else {
        Write-Host "CSV → PDF conversion failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Csv-ToPdf, Csv-ToPdf-Core