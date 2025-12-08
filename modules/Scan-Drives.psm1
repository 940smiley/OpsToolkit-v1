<#
    Scan-Drives.psm1
    -----------------
    Drive enumeration tool for OpsToolkit.
    Features:
      - Lists all drives
      - Shows free/used/total space
      - Detects drive type
      - Interactive wrapper
      - Logging
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Core logic
# -------------------------------
function Scan-Drives-Core {

    $drives = Get-PSDrive -PSProvider FileSystem | Sort-Object Name

    if (-not $drives) {
        Write-Host "No drives found." -ForegroundColor Yellow
        return $false
    }

    $results = @()

    foreach ($d in $drives) {
        $used = $d.Used
        $free = $d.Free
        $total = $used + $free

        $type = try {
            (Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($d.Name):'").DriveType
        } catch {
            0
        }

        $typeName = switch ($type) {
            2 { "Removable" }
            3 { "Fixed" }
            4 { "Network" }
            5 { "CD-ROM" }
            6 { "RAM Disk" }
            default { "Unknown" }
        }

        $results += [PSCustomObject]@{
            Drive     = "$($d.Name):"
            Type      = $typeName
            FreeGB    = "{0:N2}" -f ($free / 1GB)
            UsedGB    = "{0:N2}" -f ($used / 1GB)
            TotalGB   = "{0:N2}" -f ($total / 1GB)
        }
    }

    Write-ModuleLog "Scan-Drives executed: $($results.Count) drives found"
    return $results
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Scan-Drives {
    Write-Host "`n=== Drive Scanner ===" -ForegroundColor Cyan

    $results = Scan-Drives-Core

    if (-not $results) {
        Write-Host "Drive scan failed." -ForegroundColor Red
        return
    }

    Write-Host ""
    $results | Format-Table -AutoSize
    Write-Host ""
}

Export-ModuleMember -Function Scan-Drives, Scan-Drives-Core