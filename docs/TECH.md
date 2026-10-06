# Technical Architecture - Lenovo Battery Toggle

## Overview

```
F12 (Vantage user-defined key) / Start menu
        │
        ▼
lenovo-battery-toggle.exe  ──►  ChargeThreshold.exe (Lenovo)  ──RPC──►  PowerMgr
   (.NET Framework 4.8)          status | on <stop> <start> | off       (Lenovo Power and Battery driver)
        │                                                                   │
        ▼                                                                   ▼
 notification (WinForms)                                        EC firmware + registry state
                                                                 read by Lenovo Vantage
```

The app never talks to the driver itself. Lenovo's `ChargeThreshold.exe` connects to
`PowerMgr` over the same RPC channel Vantage uses, so the driver applies the threshold to
the embedded controller and records the state in
`HKLM\SOFTWARE\WOW6432Node\Lenovo\PWRMGRV\ConfKeys\Data\<battery barcode>`, which is
where the Vantage switch reads it from.

## Components

| File | Role |
|---|---|
| `src/LenovoBatteryToggle/Program.cs` | Modes, single-instance mutex, toggle flow |
| `ChargeThresholdTool.cs` | Download, cache and run `ChargeThreshold.exe`; parse `status` |
| `Signature.cs` | `WinVerifyTrust` (file hash + chain) plus signer subject `O=Lenovo` |
| `PowerDriver.cs` | WMI check for the `POWERMGR_COMPONENT` device with status `OK` |
| `Settings.cs` | `config.json` (start/stop), defaults 75/80, validation |
| `Notification.cs` | Borderless, non-activating, timer-closed message |
| `Text.cs` | Polish/English messages by `CurrentUICulture` |
| `installer/LenovoBatteryToggle.iss` | Inno Setup 7 script |
| `build.ps1` | `dotnet build` + `ISCC`, shared by local builds and CI |
| `.github/workflows/build.yml` | CI build; tag `v*` publishes a release |

## Modes

| Command | Used by | Behaviour |
|---|---|---|
| *(none)* | user, F12 | Driver check → settings → tool → toggle → message from read-back state |
| `--prepare` | installer | Driver check, write default settings, download + verify tool. No UI, no toggle. Exit `0` OK, `1` failed (retried on first use), `2` driver missing |
| `--off` | uninstaller | Switch thresholds off if the cached tool and driver exist. Never downloads, always exits `0` |

## Files on the user's machine

| Location | Content | Removed by uninstaller |
|---|---|---|
| `%LOCALAPPDATA%\Programs\Lenovo Battery Toggle\` | app, `.exe.config`, uninstaller | yes |
| `%LOCALAPPDATA%\LenovoBatteryToggle\` | `config.json`, `ChargeThreshold.exe` | yes, whole folder |
| Start menu (user) | app shortcut, settings shortcut (Notepad) | yes |
| `HKCU\...\Uninstall\{6C1E8F4A-...}` | Apps entry | yes |

The app writes nothing else: no registry values, no services, no scheduled tasks.
`config.json` is created with defaults on first run if the installer did not write it.

## ChargeThreshold.exe

- Source: `https://download.lenovo.com/pccbbs//thinkvantage_en/metroapps/Vantage/ChargeThreshold/ChargeThreshold.exe`
  (v1.0.0.2, built 2019-01-07, signed `CN=Lenovo`).
- Works **without elevation**; needs the Lenovo Power and Battery driver.
- `status` prints English in every Windows language:
  `Charge threshold for Battery #1: OFF.` or
  `Charge threshold for Battery #1: Start at 75%, Stop at 80%.`
- `off` clears only the `*Control` flags; the percentages stay in the registry.

## Technical stack

- C# on **.NET Framework 4.8** (part of Windows 10/11), WinForms, `System.Management`,
  `DataContractJsonSerializer`. SDK-style project; the .NET SDK pulls the net48 reference
  assemblies from NuGet.
- App manifest: `asInvoker`, PerMonitorV2 DPI awareness.
- **Inno Setup 7.1.0**, per-user (`PrivilegesRequired=lowest`), English and Polish wizard.
  CI and local builds use the same pinned version in portable mode.

Deliberately: .NET Framework 4.8 instead of .NET 8 — a 17 kB executable with no runtime to
install outweighs the newer language and libraries for a tool this small.

Deliberately: no automatic driver installation — it needs elevation and Lenovo's package
URL changes with every version; Windows Update installs the driver reliably.

## Build

Local (Windows, from WSL — see `CLAUDE.md`):

```powershell
.\build.ps1 -Version 0.1.0 -Iscc <path>\ISCC.exe -Dotnet <path>\dotnet.exe
```

CI: push to `main` builds an artifact `0.0.0-dev.<run>`; tag `v<version>` builds and
publishes a GitHub release with `lenovo-battery-toggle-<version>-setup.exe`.

## Testing

Manual, on a ThinkPad (the behaviour depends on the driver and firmware):

1. Silent install: `setup.exe /VERYSILENT /SUPPRESSMSGBOXES /LANG=pl` → program and data
   folders, both Start menu shortcuts, Apps entry, `config.json` and the tool present.
2. Run the app twice → thresholds on, then off; check with `ChargeThreshold.exe status`
   and the `SetChargeThreshold` events in the `Lenovo-Power-BaseModule/Operational` log.
3. With thresholds on, uninstall silently → nothing left, last log entry
   `SetChargeThreshold start=[0], stop=[0]`.
4. Interactive install: threshold page validation, finish page hint, upgrade keeps values.

Steps 1–3 are scripted and pass. Not covered by them, so checked by hand: the wizard
pages (step 4), how the notification looks and that it does not take focus, the F12
assignment in Vantage, and the installer messages for a missing driver or a failed
download (silent mode suppresses them, and the test machine has the driver).

## Known issues

- Vantage shows the switch as "off" regardless of the state when the
  `PWRMGRV\ConfKeys` branch is missing; fix in README → Troubleshooting.
