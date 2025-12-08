<#
    Install-WindowsPowerSettings.psm1
    ----------------------------------
    Applies power plan and performance settings.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Install-WindowsPowerSettings-Core {

    Write-Host "Applying power settings..." -ForegroundColor Cyan

    # Set High Performance plan
    powercfg -setactive SCHEME_MIN

    # Disable sleep
    powercfg -change -standby-timeout-ac 0
    powercfg -change -hibernate-timeout-ac 0

    # Disable display timeout
    powercfg -change -monitor-timeout-ac 0

    Write-ModuleLog "Power settings applied"
    Write-Host "Power settings applied." -ForegroundColor Green
    return $true
}

function Install-WindowsPowerSettings {
    Install-WindowsPowerSettings-Core
}

Export-ModuleMember -Function Install-WindowsPowerSettings, Install-WindowsPowerSettings-Core