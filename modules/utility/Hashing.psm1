<#
    Hashing.psm1
    ------------
    Centralized hashing utilities for OpsToolkit.
    Provides SHA1, SHA256, safe hashing with error handling,
    and comparison helpers.
#>

# -------------------------------
# Compute SHA1 hash of a file
# -------------------------------
function Get-HashSHA1 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        return (Get-FileHash -Algorithm SHA1 -LiteralPath $Path).Hash
    } catch {
        Write-Host "SHA1 failed for: $Path  -> $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

# -------------------------------
# Compute SHA256 hash of a file
# -------------------------------
function Get-HashSHA256 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    } catch {
        Write-Host "SHA256 failed for: $Path  -> $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

# -------------------------------
# Compare two files by SHA256
# -------------------------------
function Compare-FileHash {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PathA,

        [Parameter(Mandatory=$true)]
        [string]$PathB
    )

    $h1 = Get-HashSHA256 -Path $PathA
    $h2 = Get-HashSHA256 -Path $PathB

    if (-not $h1 -or -not $h2) { return $false }

    return ($h1 -eq $h2)
}

# -------------------------------
# Hash a list of files efficiently
# -------------------------------
function Get-HashBatch {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Paths,

        [ValidateSet("SHA1","SHA256")]
        [string]$Algorithm = "SHA256"
    )

    $results = @{}

    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) {
            $results[$p] = $null
            continue
        }

        $hash = if ($Algorithm -eq "SHA1") {
            Get-HashSHA1 -Path $p
        } else {
            Get-HashSHA256 -Path $p
        }

        $results[$p] = $hash
    }

    return $results
}

Export-ModuleMember -Function Get-HashSHA1, Get-HashSHA256, Compare-FileHash, Get-HashBatch