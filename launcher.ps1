<#
    OpsToolkit Launcher
    -------------------
    - Auto‑ingests .ps1 files from /Incoming
    - Detects module vs script
    - Converts modules to .psm1
    - Moves scripts to /Scripts
    - Updates menu.json automatically
    - Loads all modules
    - Builds grouped menu
    - Executes selected module or script
    - Logs everything
#>

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$IncomingDir = Join-Path $Root "Incoming"
$ModulesDir  = Join-Path $Root "Modules"
$ScriptsDir  = Join-Path $Root "Scripts"
$LogsDir     = Join-Path $Root "Logs"
$MenuFile    = Join-Path $Root "menu.json"

# Ensure directories exist
$dirs = @($IncomingDir, $ModulesDir, $ScriptsDir, $LogsDir)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

$IngestionLog = Join-Path $LogsDir "ingestion.log"

function Write-IngestLog($msg) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp  $msg" | Out-File -FilePath $IngestionLog -Append -Encoding UTF8
}

# -------------------------------
# AUTO‑INGEST NEW .PS1 FILES
# -------------------------------
$incomingFiles = Get-ChildItem $IncomingDir -Filter *.ps1 -ErrorAction SilentlyContinue

foreach ($file in $incomingFiles) {
    $content = Get-Content $file.FullName -Raw

    $isModule = $content -match 'function\s+[A-Za-z0-9\-_]+\s*\{'

    if ($isModule) {
        # Convert to .psm1
        $moduleName = [IO.Path]::GetFileNameWithoutExtension($file.Name)
        $modulePath = Join-Path $ModulesDir ($moduleName + ".psm1")

        # Ensure Export-ModuleMember exists
        if ($content -notmatch 'Export-ModuleMember') {
            $content += "`n`nExport-ModuleMember -Function *"
        }

        $content | Out-File -FilePath $modulePath -Encoding UTF8
        Write-IngestLog "Module imported: $moduleName → Modules/"
        
        # Add to menu.json
        Update-MenuJson -ItemName $moduleName -Type "module"
    }
    else {
        # Move to Scripts
        $scriptPath = Join-Path $ScriptsDir $file.Name
        Move-Item -LiteralPath $file.FullName -Destination $scriptPath -Force
        Write-IngestLog "Script imported: $($file.Name) → Scripts/"

        # Add to menu.json
        $scriptName = [IO.Path]::GetFileNameWithoutExtension($file.Name)
        Update-MenuJson -ItemName $scriptName -Type "script"
    }

    # Remove original
    Remove-Item $file.FullName -Force
}

# -------------------------------
# MENU.JSON MANAGEMENT
# -------------------------------
function Update-MenuJson {
    param(
        [string]$ItemName,
        [string]$Type  # module | script
    )

    if (-not (Test-Path $MenuFile)) {
        # Create default menu.json
        @"
{
  "groups": [
    { "name": "Media Tools", "items": [] },
    { "name": "Data Tools", "items": [] },
    { "name": "System Tools", "items": [] },
    { "name": "App Tools", "items": [] },
    { "name": "Standalone Scripts", "items": [] }
  ]
}
"@ | Out-File -FilePath $MenuFile -Encoding UTF8
    }

    $json = Get-Content $MenuFile -Raw | ConvertFrom-Json

    # Determine group
    $targetGroup = if ($Type -eq "script") {
        $json.groups | Where-Object { $_.name -eq "Standalone Scripts" }
    } else {
        # Default: System Tools unless user reorganizes later
        $json.groups | Where-Object { $_.name -eq "System Tools" }
    }

    if ($targetGroup.items -notcontains $ItemName) {
        $targetGroup.items += $ItemName
    }

    $json | ConvertTo-Json -Depth 10 | Out-File -FilePath $MenuFile -Encoding UTF8
}

# -------------------------------
# LOAD MODULES
# -------------------------------
$moduleFiles = Get-ChildItem $ModulesDir -Filter *.psm1 -Recurse
foreach ($m in $moduleFiles) {
    try {
        Import-Module $m.FullName -Force -ErrorAction Stop
        Write-IngestLog "Loaded module: $($m.Name)"
    } catch {
        Write-IngestLog "ERROR loading module $($m.Name): $($_.Exception.Message)"
    }
}

# -------------------------------
# BUILD MENU FROM menu.json
# -------------------------------
if (-not (Test-Path $MenuFile)) {
    Write-Host "menu.json missing. Creating default…" -ForegroundColor Yellow
    Update-MenuJson -ItemName "" -Type "module"
}

$Menu = Get-Content $MenuFile -Raw | ConvertFrom-Json

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "           OpsToolkit Launcher"
    Write-Host "========================================`n"

    $global:MenuMap = @{}
    $index = 1

    foreach ($group in $Menu.groups) {
        if ($group.items.Count -eq 0) { continue }

        Write-Host "[$($group.name)]" -ForegroundColor Yellow
        foreach ($item in $group.items) {
            Write-Host "  [$index] $item"
            $MenuMap[$index] = $item
            $index++
        }
        Write-Host ""
    }

    Write-Host "[0] Exit" -ForegroundColor Red
}

# -------------------------------
# EXECUTION LOOP
# -------------------------------
while ($true) {
    Show-Menu
    $choice = Read-Host "Select an option"

    if ($choice -eq "0") { break }

    if ($choice -as [int] -and $MenuMap.ContainsKey([int]$choice)) {
        $item = $MenuMap[[int]$choice]

        # Try module first
        if (Get-Command $item -ErrorAction SilentlyContinue) {
            Write-Host "`nRunning module: $item" -ForegroundColor Cyan
            try { & $item } catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
            Pause
            continue
        }

        # Try script
        $scriptPath = Join-Path $ScriptsDir ($item + ".ps1")
        if (Test-Path $scriptPath) {
            Write-Host "`nRunning script: $item" -ForegroundColor Cyan
            try { & $scriptPath } catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
            Pause
            continue
        }

        Write-Host "Item not found: $item" -ForegroundColor Red
        Pause
    }
    else {
        Write-Host "Invalid selection." -ForegroundColor Red
        Pause
    }
}