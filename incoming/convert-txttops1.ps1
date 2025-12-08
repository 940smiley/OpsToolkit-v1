<#
    Convert-TxtToPs1.ps1
    Drag-and-drop or run manually.
    Converts .txt files into .ps1 files (same name, same folder).
#>

param(
    [Parameter(ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
    [string[]]$Paths
)

if (-not $Paths) {
    Write-Host "Drag .txt files onto this script or pass paths manually."
    exit
}

foreach ($path in $Paths) {
    if (-not (Test-Path $path)) {
        Write-Warning "File not found: $path"
        continue
    }

    if ($path -notmatch '\.txt$') {
        Write-Warning "Skipping non-txt file: $path"
        continue
    }

    $newPath = $path -replace '\.txt$', '.ps1'

    Write-Host "Converting: $path → $newPath"

    Get-Content $path | Set-Content $newPath -Encoding UTF8
}