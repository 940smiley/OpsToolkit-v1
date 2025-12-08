<#
    Install-WindowsSecurityBaseline.psm1
    -------------------------------------
    Applies hardened security settings.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Set-SecurityReg {
    param([string]$Path, [string]$Name, [object]$Value)

    try {
        New-Item -Path $Path -Force | Out-Null
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-ModuleLog "Security setting applied: $Path -> $Name=$Value"
    } catch {
        Write-Host "Failed: $Path $Name" -ForegroundColor Red
    }
}

function Install-WindowsSecurityBaseline-Core {

    Write-Host "Applying security baseline..." -ForegroundColor Cyan

    # Disable SMBv1
    Set-SecurityReg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "SMB1" 0

    # Enable SmartScreen
    Set-SecurityReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" "RequireAdmin"

    # Disable remote assistance
    Set-SecurityReg "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" 0

    # Enable exploit protection defaults
    Set-SecurityReg "HKLM:\SOFTWARE\Microsoft\Windows Defender\ExploitGuard\ASR" "ExploitGuardEnabled" 1

    Write-Host "Security baseline applied." -ForegroundColor Green
    return $true
}

function Install-WindowsSecurityBaseline {
    Install-WindowsSecurityBaseline-Core
}

Export-ModuleMember -Function Install-WindowsSecurityBaseline, Install-WindowsSecurityBaseline-Core