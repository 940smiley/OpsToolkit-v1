<#
    Install-PythonPackages.psm1
    -----------------------------
    Installs Python packages via pip.
#>

Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

function Install-PythonPackages-Core {
    param([string[]]$Packages)

    foreach ($pkg in $Packages) {
        Write-Host "Installing Python package: $pkg" -ForegroundColor Cyan
        try {
            pip install $pkg
            Write-ModuleLog "Installed Python package: $pkg"
        } catch {
            Write-Host "Failed to install: $pkg" -ForegroundColor Red
        }
    }

    return $true
}

function Install-PythonPackages {
    $default = @(
        "requests",
        "numpy",
        "pandas",
        "rich",
        "pyyaml"
    )

    Write-Host "Installing default Python packages..." -ForegroundColor Cyan
    Install-PythonPackages-Core -Packages $default
}

Export-ModuleMember -Function Install-PythonPackages, Install-PythonPackages-Core