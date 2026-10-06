# Builds the app and the installer. Used locally and by GitHub Actions.
#   .\build.ps1 -Version 0.1.1 -Iscc "C:\path\to\ISCC.exe"
# Output: artifacts\lenovo-battery-toggle-<version>-setup.exe

param(
    [string]$Version = '0.0.0',
    [string]$Iscc = 'ISCC.exe',
    [string]$Dotnet = 'dotnet'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$project = Join-Path $root 'src\LenovoBatteryToggle\LenovoBatteryToggle.csproj'
$appOut = Join-Path $root 'artifacts\app'

& $Dotnet build $project -c Release -nologo -p:Version=$Version -o $appOut
if ($LASTEXITCODE -ne 0) { throw "dotnet build failed ($LASTEXITCODE)" }

& $Iscc /Q "/DAppVersion=$Version" "/DSourceDir=$appOut" "/O$(Join-Path $root 'artifacts')" (Join-Path $root 'installer\LenovoBatteryToggle.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC failed ($LASTEXITCODE)" }

Get-ChildItem (Join-Path $root 'artifacts') -Filter '*-setup.exe' | ForEach-Object { "Built: $($_.FullName)" }
