param(
    [string]$OutputName = "ATools_Setup.exe"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$BuildRoot = Join-Path $Root "build"
$DistDir = Join-Path $Root "dist"
$GeneratedInstaller = Join-Path $BuildRoot "AToolsSimpleInstaller.generated.ahk"

function Find-Ahk2Exe {
    $command = Get-Command Ahk2Exe.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\Compiler\Ahk2Exe.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return $candidate
        }
    }

    return $null
}

function Find-AutoHotkeyV2Runtime {
    $candidates = @(
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf) -and ((Get-Item -LiteralPath $candidate).Length -gt 0)) {
            return $candidate
        }
    }

    return $null
}

function ConvertTo-AhkSingleQuotedString {
    param([Parameter(Mandatory = $true)][string]$Value)
    return "'" + $Value.Replace("'", "''") + "'"
}

function New-IcoFromPng {
    param(
        [Parameter(Mandatory = $true)][string]$PngPath,
        [Parameter(Mandatory = $true)][string]$IcoPath
    )

    $pngBytes = [System.IO.File]::ReadAllBytes($PngPath)
    $width = 0
    $height = 0

    if ($pngBytes.Length -ge 24 -and
        $pngBytes[0] -eq 0x89 -and $pngBytes[1] -eq 0x50 -and $pngBytes[2] -eq 0x4E -and $pngBytes[3] -eq 0x47) {
        $width = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($pngBytes, 16))
        $height = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($pngBytes, 20))
    }

    if ($width -le 0 -or $height -le 0) {
        throw "Could not read PNG dimensions: $PngPath"
    }

    $iconWidth = if ($width -ge 256) { 0 } else { [byte]$width }
    $iconHeight = if ($height -ge 256) { 0 } else { [byte]$height }
    $imageOffset = 6 + 16

    $stream = [System.IO.File]::Create($IcoPath)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([UInt16]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]1)
        $writer.Write([byte]$iconWidth)
        $writer.Write([byte]$iconHeight)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]32)
        $writer.Write([UInt32]$pngBytes.Length)
        $writer.Write([UInt32]$imageOffset)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Add-PayloadFile {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [System.Collections.Generic.HashSet[string]]$Dirs,
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$RelativeDestination
    )

    $sourceFull = [System.IO.Path]::GetFullPath($Source)
    $relative = $RelativeDestination.Replace("/", "\")
    $destDir = Split-Path -Parent $relative

    if ($destDir -and $Dirs.Add($destDir)) {
        $Lines.Add("    DirCreate installDir " + (ConvertTo-AhkSingleQuotedString ("\" + $destDir)))
    }

    $Lines.Add("    FileInstall " + (ConvertTo-AhkSingleQuotedString $sourceFull) + ", installDir " + (ConvertTo-AhkSingleQuotedString ("\" + $relative)) + ", true")
}

$version = (Get-Content -LiteralPath (Join-Path $Root "version.txt") -Raw).Trim()
if (-not $version) {
    throw "version.txt is empty."
}

$compiler = Find-Ahk2Exe
if (-not $compiler) {
    throw "Ahk2Exe.exe was not found. Install AutoHotkey v2 with compiler support."
}

$runtime = Find-AutoHotkeyV2Runtime
if (-not $runtime) {
    throw "AutoHotkey v2 x64 runtime was not found."
}

New-Item -ItemType Directory -Path $BuildRoot -Force | Out-Null
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

$iconPng = Join-Path $Root "assets\icons\ugta_mark.png"
$iconIco = Join-Path $BuildRoot "ugta_mark.ico"
if (-not (Test-Path -LiteralPath $iconPng -PathType Leaf)) {
    throw "Installer icon was not found: $iconPng"
}
New-IcoFromPng -PngPath $iconPng -IcoPath $iconIco

$payloadLines = [System.Collections.Generic.List[string]]::new()
$payloadDirs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$payloadRoots = @("atools.ahk", "version.txt", "README.md", "assets", "sounds", "tools")
foreach ($payloadRoot in $payloadRoots) {
    $sourcePath = Join-Path $Root $payloadRoot
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        continue
    }

    if (Test-Path -LiteralPath $sourcePath -PathType Container) {
        Get-ChildItem -LiteralPath $sourcePath -Recurse -File | Sort-Object FullName | ForEach-Object {
            $relative = $_.FullName.Substring($Root.TrimEnd("\").Length + 1)
            Add-PayloadFile -Lines $payloadLines -Dirs $payloadDirs -Source $_.FullName -RelativeDestination $relative
        }
    } else {
        Add-PayloadFile -Lines $payloadLines -Dirs $payloadDirs -Source $sourcePath -RelativeDestination $payloadRoot
    }
}

Add-PayloadFile -Lines $payloadLines -Dirs $payloadDirs -Source $runtime -RelativeDestination "runtime\AutoHotkey64.exe"
Add-PayloadFile -Lines $payloadLines -Dirs $payloadDirs -Source $iconIco -RelativeDestination "assets\icons\ugta_mark.ico"

$license = Join-Path (Split-Path -Parent (Split-Path -Parent $runtime)) "license.txt"
if (Test-Path -LiteralPath $license -PathType Leaf) {
    Add-PayloadFile -Lines $payloadLines -Dirs $payloadDirs -Source $license -RelativeDestination "runtime\AutoHotkey-license.txt"
}

$payloadBlock = $payloadLines -join [Environment]::NewLine
$installerSource = @"
#Requires AutoHotkey v2.0
#SingleInstance Force

appName := "ATools NextGen"
appVersion := "$version"
installDir := EnvGet("LOCALAPPDATA") "\ATools"
silent := false
launchAfterInstall := true
createShortcuts := true

for arg in A_Args {
    argLower := StrLower(arg)
    if (argLower = "/s" || argLower = "/silent") {
        silent := true
        launchAfterInstall := false
    } else if (argLower = "/nolaunch") {
        launchAfterInstall := false
    } else if (argLower = "/noshortcuts") {
        createShortcuts := false
    } else if (SubStr(argLower, 1, 5) = "/dir=") {
        installDir := SubStr(arg, 6)
    }
}

if (!silent) {
    answer := MsgBox("Install " appName " v" appVersion " to:" Chr(10) installDir "?", appName " Setup", "YesNo Iconi")
    if (answer != "Yes")
        ExitApp()
}

try {
    DirCreate installDir
$payloadBlock

    runtimePath := installDir "\runtime\AutoHotkey64.exe"
    scriptPath := installDir "\atools.ahk"
    iconPath := installDir "\assets\icons\ugta_mark.ico"

    if (createShortcuts) {
        CreateShortcut(A_Desktop "\ATools.lnk", runtimePath, '"' scriptPath '"', installDir, iconPath)
    }

    if (!silent && launchAfterInstall) {
        launch := MsgBox("ATools was installed successfully." Chr(10) Chr(10) "Launch now?", appName " Setup", "YesNo Iconi")
        launchAfterInstall := launch = "Yes"
    }

    if (launchAfterInstall)
        Run('"' runtimePath '" "' scriptPath '"', installDir)
} catch as err {
    if (!silent)
        MsgBox("Install error:" Chr(10) Chr(10) err.Message, appName " Setup", "Icon!")
    ExitApp(1)
}

CreateShortcut(linkPath, targetPath, args, workingDir, iconPath := "") {
    shell := ComObject("WScript.Shell")
    shortcut := shell.CreateShortcut(linkPath)
    shortcut.TargetPath := targetPath
    shortcut.Arguments := args
    shortcut.WorkingDirectory := workingDir
    shortcut.IconLocation := FileExist(iconPath) ? iconPath : targetPath
    shortcut.Description := "ATools NextGen"
    shortcut.Save()
}
"@

Set-Content -LiteralPath $GeneratedInstaller -Value $installerSource -Encoding UTF8

$outputPath = Join-Path $DistDir $OutputName
& $compiler /in $GeneratedInstaller /out $outputPath /base $runtime /icon $iconIco
if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "Ahk2Exe did not create the installer."
}

Write-Host "Simple installer created: $outputPath"
