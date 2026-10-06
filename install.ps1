# Installs the threshold toggle into the target folder. No administrator rights needed.
# Overwrites toggle.ps1; copies config.json only if it does not exist yet.

param([string]$Target = 'C:\Tools\lenovo-battery-toggle')

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'src'
$exe = Join-Path $Target 'ChargeThreshold.exe'
$url = 'https://download.lenovo.com/pccbbs//thinkvantage_en/metroapps/Vantage/ChargeThreshold/ChargeThreshold.exe'

New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item (Join-Path $src 'toggle.ps1') $Target -Force
if (-not (Test-Path (Join-Path $Target 'config.json'))) {
    Copy-Item (Join-Path $src 'config.json') $Target
}

if (-not (Test-Path $exe)) {
    Invoke-WebRequest -UseBasicParsing $url -OutFile $exe
}
$signature = Get-AuthenticodeSignature $exe
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Lenovo') {
    Remove-Item $exe
    throw "ChargeThreshold.exe has no valid Lenovo signature ($($signature.Status)); file removed."
}

# The shortcut runs the script without a console window; assign this file to the F12 key in Vantage
$shortcutPath = Join-Path $Target 'Toggle charge thresholds.lnk'
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\conhost.exe'
$shortcut.Arguments = "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $Target 'toggle.ps1')`""
$shortcut.WorkingDirectory = $Target
$shortcut.IconLocation = Join-Path $env:SystemRoot 'System32\powercpl.dll,0'
$shortcut.Description = 'Toggles ThinkPad battery charge thresholds'
$shortcut.Save()

Write-Host "Installed to $Target"
Write-Host "Shortcut: $shortcutPath"
Write-Host (& $exe status | Out-String).Trim()
