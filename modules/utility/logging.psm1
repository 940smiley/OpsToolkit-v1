<#
    Logging.psm1
    ------------
    Centralized logging utilities for OpsToolkit modules.
    Provides timestamped logging, module‑scoped logs, and
    automatic directory creation.
#>

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolkitRoot = Split-Path -Parent $Root
$LogsDir = Join-Path $ToolkitRoot "Logs"

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

# -------------------------------
# Write a line to a specific log file
# -------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$LogName
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp  $Message"

    $logPath = Join-Path $LogsDir $LogName

    try {
        $line | Out-File -FilePath $logPath -Append -Encoding UTF8
    } catch {
        Write-Host "Logging failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# -------------------------------
# Write to the shared module log
# -------------------------------
function Write-ModuleLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    Write-Log -Message $Message -LogName "module.log"
}

# -------------------------------
# Write to the ingestion log
# -------------------------------
function Write-IngestionLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    Write-Log -Message $Message -LogName "ingestion.log"
}

Export-ModuleMember -Function Write-Log, Write-ModuleLog, Write-IngestionLog