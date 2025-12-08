<#
    Install-VSCodeExtensions.psm1
    ------------------------------
    Installs VS Code extensions via `code --install-extension`.
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Install-VSCodeExtensions-Core {
    param([string[]]$Extensions)

    foreach ($ext in $Extensions) {
        Write-Host "Installing VS Code extension: $ext" -ForegroundColor Cyan
        try {
            code --install-extension $ext --force
            Write-ModuleLog "Installed VS Code extension: $ext"
        } catch {
            Write-Host "Failed to install: $ext" -ForegroundColor Red
        }
    }

    return $true
}

function Install-VSCodeExtensions {
    $list = @(
        "ms-python.python",
        "ms-vscode.powershell",
        "ms-azuretools.vscode-docker",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint"
    )

    Write-Host "Installing default VS Code extensions..." -ForegroundColor Cyan
    Install-VSCodeExtensions-Core -Extensions $list
}

Export-ModuleMember -Function Install-VSCodeExtensions, Install-VSCodeExtensions-Core