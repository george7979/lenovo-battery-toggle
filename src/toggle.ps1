# Toggles ThinkPad battery charge thresholds: on <-> off.
# Threshold values come from config.json next to this script. The result is shown
# in a notification that closes by itself.

$dir = $PSScriptRoot
$exe = Join-Path $dir 'ChargeThreshold.exe'
$configPath = Join-Path $dir 'config.json'
$polish = (Get-UICulture).TwoLetterISOLanguageName -eq 'pl'

function Text([string]$pl, [string]$en) { if ($polish) { $pl } else { $en } }

function Show-Message([string]$text, [bool]$isError = $false) {
    # Borderless notification in the bottom-right corner, closed by a timer, not by the user.
    # WScript.Shell.Popup is not used: it needs an OK click when its timeout is ignored.
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'Manual'
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.AutoSize = $true
    $form.AutoSizeMode = 'GrowAndShrink'
    $form.BackColor = if ($isError) { [System.Drawing.Color]::FromArgb(160, 30, 30) } else { [System.Drawing.Color]::FromArgb(32, 32, 32) }

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $text
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Font = New-Object System.Drawing.Font('Segoe UI', 12)
    $label.AutoSize = $true
    $label.MaximumSize = New-Object System.Drawing.Size(520, 0)
    $label.Padding = New-Object System.Windows.Forms.Padding(18, 14, 18, 14)
    $form.Controls.Add($label)

    $form.Add_Load({
        $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $form.Location = New-Object System.Drawing.Point(($area.Right - $form.Width - 24), ($area.Bottom - $form.Height - 24))
    })
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = if ($isError) { 6000 } else { 2000 }
    $timer.Add_Tick({ $timer.Stop(); $form.Close() })
    $timer.Start()
    [System.Windows.Forms.Application]::Run($form)
}

function Invoke-ChargeThreshold([string[]]$arguments) {
    $output = (& $exe @arguments | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw (Text "ChargeThreshold.exe $arguments zwrócił kod $LASTEXITCODE.`n$output" `
                    "ChargeThreshold.exe $arguments returned code $LASTEXITCODE.`n$output")
    }
    return $output
}

try {
    if (-not (Test-Path $exe)) {
        throw (Text "Brak pliku ChargeThreshold.exe w $dir. Uruchom install.ps1." `
                    "ChargeThreshold.exe not found in $dir. Run install.ps1.")
    }

    $start = 75; $stop = 80
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $start = [int]$config.start; $stop = [int]$config.stop
    }
    if (-not ($start -ge 0 -and $stop -le 100 -and $start -lt $stop)) {
        throw (Text "Błędne progi w config.json: start=$start, stop=$stop. Wymagane 0 <= start < stop <= 100." `
                    "Invalid thresholds in config.json: start=$start, stop=$stop. Required 0 <= start < stop <= 100.")
    }

    # ChargeThreshold.exe prints English text regardless of the Windows language
    $before = Invoke-ChargeThreshold @('status')
    if ($before -match ':\s*OFF\.') {
        Invoke-ChargeThreshold @('on', $stop, $start) | Out-Null
    } elseif ($before -match 'Start at \d+%') {
        Invoke-ChargeThreshold @('off') | Out-Null
    } else {
        throw (Text "Nieznany stan progów:`n$before" "Unknown threshold state:`n$before")
    }

    # The message reflects the state read back after the change, not the intent
    $after = Invoke-ChargeThreshold @('status')
    if ($after -match ':\s*OFF\.') {
        Show-Message (Text 'Progi WYŁĄCZONE: bateria ładuje się do 100 %.' `
                           'Charge thresholds OFF: the battery charges to 100%.')
    } elseif ($after -match 'Start at (\d+)%, Stop at (\d+)%') {
        Show-Message (Text "Progi WŁĄCZONE: ładowanie od $($Matches[1]) %, stop przy $($Matches[2]) %." `
                           "Charge thresholds ON: charging starts below $($Matches[1])%, stops at $($Matches[2])%.")
    } else {
        throw (Text "Nieznany stan progów po zmianie:`n$after" "Unknown threshold state after the change:`n$after")
    }
} catch {
    Show-Message ((Text 'Błąd: ' 'Error: ') + $_.Exception.Message) $true
    exit 1
}
