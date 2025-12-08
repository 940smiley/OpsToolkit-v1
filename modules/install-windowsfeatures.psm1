<#
    Install-WindowsFeatures.psm1
    -----------------------------
    Enables optional Windows features via menu selection.
    Features:
      - Curated feature list
      - Multi-select
      - Dependency-safe enabling
      - Logging
      - Interactive wrapper
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Curated feature list
# -------------------------------
$Global:WindowsFeatureList = @(
    @{ Name = "Microsoft-Windows-Subsystem-Linux"; Label = "WSL (Windows Subsystem for Linux)" }
    @{ Name = "VirtualMachinePlatform"; Label = "Virtual Machine Platform" }
    @{ Name = "NetFx3"; Label = ".NET Framework 3.5" }
    @{ Name = "TelnetClient"; Label = "Telnet Client" }
    @{ Name = "TFTP"; Label = "TFTP Client" }
    @{ Name = "Containers"; Label = "Windows Containers" }
    @{ Name = "Microsoft-Hyper-V-All"; Label = "Hyper-V (All Components)" }
    @{ Name = "SMB1Protocol"; Label = "SMB 1.0 Support" }
    @{ Name = "IIS-WebServerRole"; Label = "IIS Web Server" }
)

# -------------------------------
# Enable a single feature
# -------------------------------
function Enable-WindowsFeatureSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureName
    )

    try {
        $state = (Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop).State
    } catch {
        Write-Host "Unknown feature: $FeatureName" -ForegroundColor Red
        return $false
    }

    if ($state -eq "Enabled") {
        Write-Host "Already enabled: $FeatureName" -ForegroundColor Gray
        return $true
    }

    Write-Host "Enabling: $FeatureName..." -ForegroundColor Cyan

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -All -NoRestart | Out-Null
        Write-ModuleLog "Enabled Windows feature: $FeatureName"
        return $true
    } catch {
        Write-Host "Failed to enable $FeatureName: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Core logic
# -------------------------------
function Install-WindowsFeatures-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Features
    )

    $success = 0
    $fail = 0

    foreach ($f in $Features) {
        if (Enable-WindowsFeatureSafe -FeatureName $f) {
            $success++
        } else {
            $fail++
        }
    }

    Write-Host "`nCompleted. Success: $success  Failed: $fail" -ForegroundColor Cyan
    Write-ModuleLog "Install-WindowsFeatures completed: $success success, $fail failed"

    return ($fail -eq 0)
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Install-WindowsFeatures {
    Write-Host "`n=== Install Optional Windows Features ===" -ForegroundColor Cyan

    Write-Host "`nAvailable features:" -ForegroundColor Cyan

    $i = 1
    foreach ($f in $Global:WindowsFeatureList) {
        Write-Host "  [$i] $($f.Label)"
        $i++
    }

    $choice = Prompt-String -Message "Enter numbers separated by commas" -Default "1,2"

    $indexes = $choice -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    $selected = @()

    foreach ($idx in $indexes) {
        $i = [int]$idx - 1
        if ($i -ge 0 -and $i -lt $Global:WindowsFeatureList.Count) {
            $selected += $Global:WindowsFeatureList[$i].Name
        }
    }

    if (-not $selected) {
        Write-Host "No valid selections." -ForegroundColor Red
        return
    }

    Write-Host "`nEnabling selected features..." -ForegroundColor Cyan

    Install-WindowsFeatures-Core -Features $selected
}

Export-ModuleMember -Function Install-WindowsFeatures, Install-WindowsFeatures-Core