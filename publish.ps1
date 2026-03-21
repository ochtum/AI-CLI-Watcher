[CmdletBinding()]
param(
    [string]$Configuration = "Release",
    [string]$Runtime = "win-x64",
    [switch]$SelfContained,
    [switch]$CleanOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Join-Path $rootDir "src/AI-CLI-Watcher.csproj"
$outputDir = Join-Path $rootDir "app"
$settingsFileName = "settings.json"
$settingsPath = Join-Path $outputDir $settingsFileName
$settingsBackupPath = $null

if (-not (Test-Path $projectPath)) {
    throw "Project file not found: $projectPath"
}

if ($CleanOutput -and (Test-Path $settingsPath)) {
    $settingsBackupPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    Copy-Item -Path $settingsPath -Destination $settingsBackupPath -Force
}

if ($CleanOutput -and (Test-Path $outputDir)) {
    Get-ChildItem -Path $outputDir -Force | Remove-Item -Recurse -Force
}

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$publishArgs = @(
    "publish"
    $projectPath
    "-c"
    $Configuration
    "-r"
    $Runtime
    "--self-contained"
    $(if ($SelfContained) { "true" } else { "false" })
    "-o"
    $outputDir
)

Write-Host "Publishing AI-CLI-Watcher..." -ForegroundColor Cyan
Write-Host "  Configuration : $Configuration"
Write-Host "  Runtime       : $Runtime"
Write-Host "  Self-contained: $($SelfContained.IsPresent)"
Write-Host "  Output        : $outputDir"

try {
    & dotnet @publishArgs

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish failed with exit code $LASTEXITCODE"
    }
}
finally {
    if ($settingsBackupPath -and (Test-Path $settingsBackupPath)) {
        Copy-Item -Path $settingsBackupPath -Destination $settingsPath -Force
        Remove-Item -Path $settingsBackupPath -Force
    }
}

Write-Host ""
Write-Host "Publish completed." -ForegroundColor Green
Write-Host "Copy the entire 'app' folder for distribution."
