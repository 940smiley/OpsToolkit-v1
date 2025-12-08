<#
    Install-WindowsContextMenu.psm1
    --------------------------------
    Adds or removes custom context menu entries.
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Add-ContextMenuItem {
    param(
        [string]$Name,
        [string]$Command
    )

    $path = "HKCR:\*\shell\$Name"
    $cmdPath = "$path\command"

    try {
        New-Item -Path $path -Force | Out-Null
        New-Item -Path $cmdPath -Force | Out-Null
        Set-ItemProperty -Path $cmdPath -Name "(Default)" -Value $Command
        Write-ModuleLog "Context menu added: $Name -> $Command"
    } catch {
        Write-Host "Failed to add context menu item: $Name" -ForegroundColor Red
    }
}

function Install-WindowsContextMenu-Core {
    param([string]$Label, [string]$Command)

    Add-ContextMenuItem -Name $Label -Command $Command
    return $true
}

function Install-WindowsContextMenu {
    $label = Prompt-String -Message "Menu label" -Default "Open with PowerShell"
    $cmd   = Prompt-String -Message "Command" -Default "pwsh.exe -NoExit -Command `"cd '%V'`""

    Install-WindowsContextMenu-Core -Label $label -Command $cmd
}

Export-ModuleMember -Function Install-WindowsContextMenu, Install-WindowsContextMenu-Core