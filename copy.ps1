$SourceRoot = "c:\Users\PC\Documents\GitHub\TurboAchievementTracker"
$Destination = "C:\Gry\World of Warcraft\_retail_\Interface\AddOns\TurboAchievementTracker"

function Test-FileNeedsUpdate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [string]$DestinationFile
    )

    if (-not (Test-Path -LiteralPath $DestinationFile -PathType Leaf)) {
        return $true
    }

    $sourceItem = Get-Item -LiteralPath $SourceFile
    $destinationItem = Get-Item -LiteralPath $DestinationFile

    if ($sourceItem.Length -ne $destinationItem.Length) {
        return $true
    }

    $sourceHash = (Get-FileHash -LiteralPath $SourceFile -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $DestinationFile -Algorithm SHA256).Hash

    return $sourceHash -ne $destinationHash
}

Write-Host "==== Syncing TurboAchievementTracker ====" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $Destination)) {
    Write-Host "Creating destination directory: $Destination"
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$SourceFiles = Get-ChildItem -LiteralPath $SourceRoot -Recurse -File |
    Where-Object { $_.FullName -notlike "$SourceRoot\.git\*" -and $_.Name -ne "copy.ps1" -and $_.Name -ne "implementation_plan.md" }

$updatedCount = 0

foreach ($SourceFile in $SourceFiles) {
    $relativePath = $SourceFile.FullName.Substring($SourceRoot.Length).TrimStart('\')
    $destinationFile = Join-Path -Path $Destination -ChildPath $relativePath
    $destinationDirectory = Split-Path -Path $destinationFile -Parent

    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }

    if (Test-FileNeedsUpdate -SourceFile $SourceFile.FullName -DestinationFile $destinationFile) {
        Copy-Item -LiteralPath $SourceFile.FullName -Destination $destinationFile -Force
        Write-Host "  Updated: $relativePath" -ForegroundColor Green
        $updatedCount++
    }
}

if ($updatedCount -eq 0) {
    Write-Host "No files needed updating." -ForegroundColor Gray
} else {
    Write-Host "Sync complete. Updated $updatedCount files." -ForegroundColor Green
}

Write-Host "=== Finished ===" -ForegroundColor Cyan
