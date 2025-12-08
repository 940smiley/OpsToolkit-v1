<#
    Export-EdgeBookmarks.psm1
    --------------------------
    Unified Edge bookmark extractor for OpsToolkit.
    Features:
      - Reads Bookmarks.bak JSON
      - Recursively extracts bookmark URLs
      - Outputs valid Netscape-format HTML
      - Interactive wrapper
      - Logging + error handling
#>

Import-Module "$PSScriptRoot\Utility\Prompts.psm1" -Force
Import-Module "$PSScriptRoot\Utility\FileSystem.psm1" -Force
Import-Module "$PSScriptRoot\Utility\Logging.psm1" -Force

# -------------------------------
# Recursively extract bookmarks
# -------------------------------
function Get-BookmarksRecursive {
    param(
        [Parameter(Mandatory=$true)]
        $Node
    )

    $results = @()

    if ($null -ne $Node.children) {
        foreach ($child in $Node.children) {
            $results += Get-BookmarksRecursive -Node $child
        }
    }
    elseif ($Node.type -eq "url") {
        $results += [PSCustomObject]@{
            Name = $Node.name
            URL  = $Node.url
        }
    }

    return $results
}

# -------------------------------
# Core logic: Export bookmarks
# -------------------------------
function Export-EdgeBookmarks-Core {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupFile,

        [Parameter(Mandatory=$true)]
        [string]$OutputFile
    )

    if (-not (Test-Path -LiteralPath $BackupFile)) {
        Write-Host "Backup file not found: $BackupFile" -ForegroundColor Red
        return $false
    }

    try {
        $json = Get-Content $BackupFile -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Failed to parse JSON: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    $bookmarks = @()
    $roots = @(
        $json.roots.bookmark_bar,
        $json.roots.other,
        $json.roots.synced
    )

    foreach ($root in $roots) {
        if ($null -ne $root) {
            $bookmarks += Get-BookmarksRecursive -Node $root
        }
    }

    # Build HTML
    $html = @()
    $html += '<!DOCTYPE NETSCAPE-Bookmark-file-1>'
    $html += '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">'
    $html += '<TITLE>Bookmarks</TITLE>'
    $html += '<H1>Bookmarks</H1>'
    $html += '<DL><p>'

    foreach ($bm in $bookmarks) {
        $nameEsc = [System.Web.HttpUtility]::HtmlEncode($bm.Name)
        $urlEsc  = [System.Web.HttpUtility]::HtmlEncode($bm.URL)
        $html += "<DT><A HREF=""$urlEsc"">$nameEsc</A>"
    }

    $html += '</DL><p>'

    try {
        $html | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-ModuleLog "Exported Edge bookmarks to $OutputFile"
        return $true
    } catch {
        Write-Host "Failed to write HTML: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -------------------------------
# Interactive wrapper
# -------------------------------
function Export-EdgeBookmarks {
    Write-Host "`n=== Export Edge Bookmarks ===" -ForegroundColor Cyan

    $defaultBak = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks.bak"
    $backupFile = Prompt-Path -Message "Path to Bookmarks.bak" -Default $defaultBak

    $defaultOut = "C:\Users\$env:USERNAME\Desktop\edge_bookmarks.html"
    $outputFile = Prompt-String -Message "Output HTML file" -Default $defaultOut

    Write-Host "`nExtracting bookmarks..." -ForegroundColor Cyan

    $ok = Export-EdgeBookmarks-Core -BackupFile $backupFile -OutputFile $outputFile

    if ($ok) {
        Write-Host "Bookmarks exported to:`n$outputFile" -ForegroundColor Green
    } else {
        Write-Host "Bookmark export failed." -ForegroundColor Red
    }
}

Export-ModuleMember -Function Export-EdgeBookmarks, Export-EdgeBookmarks-Core