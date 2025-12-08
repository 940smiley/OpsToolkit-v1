<#
    Consolidate-Scripts.ps1
    Prompts for a directory.
    Merges all .ps1 files into Combined.ps1.
    Deletes originals after merging.
#>

# Ask user for directory
$dir = Read-Host "Enter directory containing scripts"

if (-not (Test-Path $dir)) {
    Write-Host "Directory does not exist."
    exit
}

$files = Get-ChildItem -Path $dir -Filter *.ps1 -File

if ($files.Count -eq 0) {
    Write-Host "No .ps1 files found in $dir"
    exit
}

$combined = Join-Path $dir "Combined.ps1"

Write-Host "Creating combined script: $combined"

# Start fresh
"" | Set-Content $combined -Encoding UTF8

foreach ($file in $files) {
    Write-Host "Adding: $($file.Name)"

    Add-Content $combined "`n# ================================"
    Add-Content $combined "# Source: $($file.Name)"
    Add-Content $combined "# ================================`n"

    Get-Content $file.FullName | Add-Content $combined
}

# Remove originals except the combined file
foreach ($file in $files) {
    if ($file.FullName -ne $combined) {
        Write-Host "Deleting: $($file.Name)"
        Remove-Item $file.FullName -Force
    }
}

Write-Host "Consolidation complete."