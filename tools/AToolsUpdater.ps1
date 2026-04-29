param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    [Parameter(Mandatory = $true)]
    [string]$InstallDir,

    [Parameter(Mandatory = $true)]
    [string]$LaunchPath,

    [string]$AhkExe = "",

    [int]$CallerPid = 0,

    [switch]$NoRelaunch
)

$ErrorActionPreference = "Stop"

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path)
}

function Remove-TempItem {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $fullPath = Get-FullPath $Path
    $tempRoot = Get-FullPath ([System.IO.Path]::GetTempPath())
    if ($fullPath.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$installRoot = Get-FullPath $InstallDir
if (-not (Test-Path -LiteralPath $installRoot -PathType Container)) {
    throw "InstallDir does not exist: $installRoot"
}

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Update archive does not exist: $ZipPath"
}

if ($CallerPid -gt 0) {
    try {
        Wait-Process -Id $CallerPid -Timeout 20 -ErrorAction SilentlyContinue
    } catch {
        Start-Sleep -Seconds 2
    }
}

$extractDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ATools_Update_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $extractDir | Out-Null

try {
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractDir -Force
    $repoRoot = Get-ChildItem -LiteralPath $extractDir -Directory | Select-Object -First 1
    if (-not $repoRoot) {
        throw "Update archive does not contain repository files."
    }

    foreach ($item in Get-ChildItem -LiteralPath $repoRoot.FullName -Force) {
        if ($item.Name -in @(".git", ".github")) {
            continue
        }

        Copy-Item -LiteralPath $item.FullName -Destination $installRoot -Recurse -Force
    }

    $logPath = Join-Path $installRoot "update.log"
    "Updated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content -LiteralPath $logPath -Encoding UTF8
} finally {
    Remove-TempItem $extractDir
    Remove-TempItem $ZipPath
    Remove-TempItem $PSCommandPath
}

if (-not $NoRelaunch) {
    if ($AhkExe -and (Test-Path -LiteralPath $AhkExe -PathType Leaf) -and ([System.IO.Path]::GetExtension($LaunchPath) -ieq ".ahk")) {
        Start-Process -FilePath $AhkExe -ArgumentList ('"' + $LaunchPath + '"') -WorkingDirectory $installRoot
    } else {
        Start-Process -FilePath $LaunchPath -WorkingDirectory $installRoot
    }
}
