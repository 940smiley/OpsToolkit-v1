<#
    FileSystem.psm1
    ----------------
    Shared filesystem utilities for OpsToolkit.
    Provides safe directory creation, safe file moves,
    collision-proof renaming, and path helpers.
#>

# -------------------------------
# Ensure a directory exists
# -------------------------------
function Ensure-Dir {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        } catch {
            Write-Host "Failed to create directory: $Path" -ForegroundColor Red
        }
    }
}

# -------------------------------
# Normalize a path (resolve ., .., slashes)
# -------------------------------
function Normalize-Path {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        return (Resolve-Path -LiteralPath $Path).Path
    } catch {
        return $Path  # fallback to raw
    }
}

# -------------------------------
# Move a file safely
# - Creates destination directory if needed
# - Handles name collisions by appending (1), (2), etc.
# -------------------------------
function Move-FileSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source,

        [Parameter(Mandatory=$true)]
        [string]$Destination
    )

    $destDir = Split-Path -Parent $Destination
    Ensure-Dir -Path $destDir

    $target = $Destination
    $i = 1

    while (Test-Path -LiteralPath $target) {
        $base = [IO.Path]::GetFileNameWithoutExtension($Destination)
        $ext  = [IO.Path]::GetExtension($Destination)
        $dir  = [IO.Path]::GetDirectoryName($Destination)
        $target = Join-Path $dir ("{0} ({1}){2}" -f $base, $i, $ext)
        $i++
    }

    try {
        Move-Item -LiteralPath $Source -Destination $target -Force
        return $target
    } catch {
        Write-Host "Move failed: $Source -> $target" -ForegroundColor Red
        return $null
    }
}

# -------------------------------
# Copy a file safely (same collision logic)
# -------------------------------
function Copy-FileSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source,

        [Parameter(Mandatory=$true)]
        [string]$Destination
    )

    $destDir = Split-Path -Parent $Destination
    Ensure-Dir -Path $destDir

    $target = $Destination
    $i = 1

    while (Test-Path -LiteralPath $target) {
        $base = [IO.Path]::GetFileNameWithoutExtension($Destination)
        $ext  = [IO.Path]::GetExtension($Destination)
        $dir  = [IO.Path]::GetDirectoryName($Destination)
        $target = Join-Path $dir ("{0} ({1}){2}" -f $base, $i, $ext)
        $i++
    }

    try {
        Copy-Item -LiteralPath $Source -Destination $target -Force
        return $target
    } catch {
        Write-Host "Copy failed: $Source -> $target" -ForegroundColor Red
        return $null
    }
}

# -------------------------------
# Build a quarantine path for a file
# -------------------------------
function Get-QuarantinePath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$QuarantineRoot,

        [Parameter(Mandatory=$true)]
        [string]$SourcePath
    )

    Ensure-Dir -Path $QuarantineRoot

    $fileName = [IO.Path]::GetFileName($SourcePath)
    return Join-Path $QuarantineRoot $fileName
}

Export-ModuleMember -Function Ensure-Dir, Normalize-Path, Move-FileSafe, Copy-FileSafe, Get-QuarantinePath