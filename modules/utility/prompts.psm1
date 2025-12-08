<#
    Prompts.psm1
    ------------
    Shared interactive prompt utilities for OpsToolkit.
    Provides:
      - Input prompts with defaults
      - Yes/No prompts
      - Required input enforcement
      - Path prompts with validation
      - Numeric prompts
#>

# -------------------------------
# Prompt for a string with optional default
# -------------------------------
function Prompt-String {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [string]$Default = ""
    )

    $suffix = if ($Default) { " (default: $Default)" } else { "" }
    $resp = Read-Host "$Message$suffix"

    if ([string]::IsNullOrWhiteSpace($resp)) {
        return $Default
    }

    return $resp
}

# -------------------------------
# Prompt for a required string (no empty allowed)
# -------------------------------
function Prompt-Required {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    while ($true) {
        $resp = Read-Host $Message
        if (-not [string]::IsNullOrWhiteSpace($resp)) {
            return $resp
        }
        Write-Host "Input required." -ForegroundColor Yellow
    }
}

# -------------------------------
# Prompt for Yes/No with default
# -------------------------------
function Prompt-YesNo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [bool]$Default = $true
    )

    $suffix = if ($Default) { "[Y/n]" } else { "[y/N]" }

    while ($true) {
        $resp = Read-Host "$Message $suffix"

        if ([string]::IsNullOrWhiteSpace($resp)) {
            return $Default
        }

        $r = $resp.ToLowerInvariant()

        if ($r -eq "y" -or $r -eq "yes") { return $true }
        if ($r -eq "n" -or $r -eq "no")  { return $false }

        Write-Host "Please enter y or n." -ForegroundColor Yellow
    }
}

# -------------------------------
# Prompt for a valid directory path
# -------------------------------
function Prompt-Path {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [string]$Default = ""
    )

    while ($true) {
        $resp = Prompt-String -Message $Message -Default $Default

        if (Test-Path -LiteralPath $resp) {
            return $resp
        }

        Write-Host "Path does not exist: $resp" -ForegroundColor Yellow
    }
}

# -------------------------------
# Prompt for an integer with optional default
# -------------------------------
function Prompt-Int {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [int]$Default = 0
    )

    while ($true) {
        $resp = Prompt-String -Message $Message -Default $Default

        if ($resp -as [int]) {
            return [int]$resp
        }

        Write-Host "Please enter a valid number." -ForegroundColor Yellow
    }
}

Export-ModuleMember -Function Prompt-String, Prompt-Required, Prompt-YesNo, Prompt-Path, Prompt-Int