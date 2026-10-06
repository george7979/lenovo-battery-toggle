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
| `ChargeThresholdTool.cs` | Download, cache and run `ChargeThreshold.exe` (user copy, or the protected copy of an all-users install); parse `status` |
| `Signature.cs` | `WinVerifyTrust` (file hash + chain) plus signer subject with `CN=Lenovo` and `O=Lenovo` as whole name parts |
| `Elevation.cs` | Whether the process is the elevated half of a split UAC token (`TokenElevationTypeFull`) |
| `PowerDriver.cs` | WMI check for the `POWERMGR_COMPONENT` device with status `OK` |
| `Settings.cs` | `config.json`: `start`, `stop` (defaults 75/80, validated) and `notificationSeconds` (default 4, clamped to 2–10; missing in older files) |
| `SettingsForm.cs` | `--settings` window: two `NumericUpDown` fields (0–100), Save enabled only when start < stop; re-applies the values when thresholds are on |
| `Notification.cs` | Borderless, non-activating, timer-closed message (time from settings, errors 6 s) |
| `Text.cs` | Polish/English messages by `CurrentUICulture` |
| `installer/LenovoBatteryToggle.iss` | Inno Setup 7 script |
| `assets/make_icon.py` | Draws `app.ico`, `installer/settings.ico` (app icon with a gear, for the settings shortcut) — 9 sizes, larger battery below 32 px — and `assets/icon-256.png` |
| `build.ps1` | `dotnet build` + `ISCC`, shared by local builds and CI |
| `.github/workflows/build.yml` | CI build; tag `v*` publishes a release |

## Modes

| Command | Used by | Behaviour |
|---|---|---|
| *(none)* | user, F12 | Driver check → settings → tool → toggle → message from read-back state |
| `--on` | installer finish page | As above, but always `on <stop> <start>` (applies the saved values when already on) |
| `--prepare [start stop]` | installer | Write the wizard values (or defaults; the notification time is kept), driver check, download + verify tool, read the state. No UI, no change. Exit `0` ready with thresholds off, `4` ready with thresholds on, `1` failed, `2` driver missing, `3` ChargeThreshold.exe not obtained (download failed or not signed by Lenovo) |
| `--settings` | settings shortcut | Window for start/stop and notification time; current values from `config.json` (defaults if missing or invalid); Save writes the file and, when thresholds are on, runs `on <stop> <start>` |
| `--install-tool` | all-users setup (elevated) | Download `ChargeThreshold.exe` next to the app (`{app}`), verify it there. Exit `0` OK (also when a valid copy is already there), `1` failed, `3` not obtained |
| `--off` | uninstaller, setup's Uninstall action | Switch thresholds off if a tool copy and the driver exist. Never downloads, always exits `0` |

## Files on the user's machine

| Location | Content | Removed by uninstaller |
|---|---|---|
| `%LOCALAPPDATA%\Programs\Lenovo Battery Toggle\` (for me) or `C:\Program Files\Lenovo Battery Toggle\` (all users) | app, `.exe.config`, `settings.ico`, uninstaller | yes |
| `%LOCALAPPDATA%\LenovoBatteryToggle\` | `config.json`, `ChargeThreshold.exe` (per-user install, or fallback) | yes, whole folder |
| `C:\Program Files\Lenovo Battery Toggle\ChargeThreshold.exe` | protected copy (all-users install) | yes |
| Start menu (user or all users) | app shortcut, settings shortcut (`--settings`, gear icon) | yes |
| `HKCU` or `HKLM` `\...\Uninstall\{6C1E8F4A-...}` | Apps entry | yes |

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
- When the file cannot be obtained (`ToolUnavailableException`: download failed, or the
  cached file is not signed by Lenovo and gets deleted), the toggle shows a `MessageBox`
  instead of a notification: the message holds the URL and the target path, and must stay
  until the user has read or copied it. The installer shows the same instructions for exit
  code `3`.

## Technical stack

- C# on **.NET Framework 4.8** (part of Windows 10/11), WinForms, `System.Management`,
  `DataContractJsonSerializer`. SDK-style project; the .NET SDK pulls the net48 reference
  assemblies from NuGet.
- App manifest: `asInvoker`, PerMonitorV2 DPI awareness.
- **Inno Setup 7.1.0**, English and Polish wizard. `PrivilegesRequired=lowest` with
  `PrivilegesRequiredOverridesAllowed=dialog`: setup asks *for me* (no elevation) or
  *all users* (UAC, Program Files). The data folder is always per user; setup runs
  `--prepare` through `ExecAsOriginalUser`, so an elevated setup still writes the settings
  into the signed-in user's profile. The uninstaller removes the data folder of the user
  who runs it.
- **Never elevated with the user's files.** The user's copy of `ChargeThreshold.exe` lives
  in `%LOCALAPPDATA%`, which the same user's unelevated processes can write, so starting it
  from an elevated process would be a UAC bypass. An all-users uninstaller is elevated and
  Inno cannot run anything as the original user at uninstall time, so an all-users setup
  runs `--install-tool` (plain `Exec`, elevated) before `--prepare`: the app downloads the
  tool into `{app}`, writable by administrators only, and checks the signature on the file
  in that final place. Tool lookup (`ChargeThresholdTool`): the protected copy next to the
  app if it is there and signed; otherwise, only when not `Elevation.IsElevated`, the user's
  copy (downloaded if missing). Elevated with no protected copy, `Ensure()` refuses and
  `Existing()` returns null, so `--off` does nothing. A protected copy that fails the check
  is ignored, not deleted (an unelevated process may not delete it). The tool imports only
  `KERNEL32` and `RPCRT4` (KnownDLLs). Without UAC (`TokenElevationTypeDefault`) there is no
  boundary and the user's copy is used as before. Setup's Uninstall action also runs
  `--off` through `ExecAsOriginalUser` before an all-users uninstaller, for an install whose
  `--install-tool` failed. Repair of a 0.1.0 all-users install keeps its old `--off` entry in
  the uninstall log (Repair appends, the latest `RunOnceId` entry runs); it now runs the new
  app, which uses the protected copy.
- **Maintenance page** (custom `[Code]`): not installed → the mode dialog and a normal
  install. Installed (Apps entry `...\Uninstall\{AppId}_is1` under HKCU and/or HKLM) →
  Inno reuses the previous mode (`UsePreviousPrivileges`, no mode dialog) and the page
  offers **Repair** (normal install over the existing one, threshold page prefilled from
  `config.json`) or **Uninstall** (runs the uninstaller of every installation found, silently
  via `ShellExec` so an all-users uninstaller can elevate, then waits for its Apps entry to
  disappear — the uninstaller copies itself to a temp file and returns at once). Changing
  the mode means uninstall + install.

Deliberately: .NET Framework 4.8 instead of .NET 8 — a 45 kB executable (icons included)
with no runtime to install outweighs the newer language and libraries for a tool this small.

Deliberately: no automatic driver installation — it needs elevation and Lenovo's package
URL changes with every version; Windows Update installs the driver reliably.

## Build

Local (Windows, from WSL — see `CLAUDE.md`):

```powershell
.\build.ps1 -Version 0.1.1 -Iscc <path>\ISCC.exe -Dotnet <path>\dotnet.exe
```

CI (`.github/workflows/build.yml`): a push to `dev` or `main` that touches `src/`,
`installer/`, `build.ps1` or the workflow (or a manual run) builds an artifact
`0.0.0-dev.<run>`. A tag `v<version>` always builds and publishes a GitHub release with
`lenovo-battery-toggle-<version>-setup.exe`; the release notes are the `## [<version>]`
section of `CHANGELOG.md` plus the installer's SHA-256 (the job fails if the section is
missing).

Icons: `uv run --with pillow python assets/make_icon.py` regenerates both `.ico` files and
`assets/icon-256.png`.

## Testing

Manual, on a ThinkPad (the behaviour depends on the driver and firmware):

1. Silent install: `setup.exe /VERYSILENT /SUPPRESSMSGBOXES /LANG=pl /CURRENTUSER` → program and data
   folders, both Start menu shortcuts, Apps entry, `config.json` and the tool present.
2. Run the app twice → thresholds on, then off; check with `ChargeThreshold.exe status`
   and the `SetChargeThreshold` events in the `Lenovo-Power-BaseModule/Operational` log.
3. With thresholds on, uninstall silently → nothing left, last log entry
   `SetChargeThreshold start=[0], stop=[0]`.
4. Interactive install: mode dialog on a fresh install, threshold page validation, finish
   page with the current state, the *Switch on now* checkbox (or *Apply now* when already
   on) and the hint to start the app from the Start menu; with the app installed: Repair
   keeps the values, Uninstall removes every installation and closes.
5. All-users install: `ChargeThreshold.exe` in the program folder and none in the profile;
   with thresholds on, uninstall from Windows Settings → thresholds off.

Steps 1–3 are scripted and pass; `--prepare <start> <stop>` was checked to write valid
values, reject invalid ones and keep `notificationSeconds`; a file without that key reads
as 4 s; with 2 s and 4 s the toggle process takes 2.4 s and 4.4 s; replacing the cached
tool with a file signed by someone else makes `--prepare` exit `3` and the toggle delete
the file. `--install-tool` was checked to download and verify the protected copy, to keep a
valid one on Repair, and `--prepare` to use it without creating a profile copy; a
protected copy signed by someone else is ignored and the profile copy is used. Not covered
by the scripts, so checked by hand: the wizard pages (step 4), the all-users uninstall
(step 5), the settings window (Save disabled when start >= stop, values applied at once
when thresholds are on), how the notification looks and that it does not take focus, the
F12 assignment in Vantage, and the installer messages for a missing driver or a failed
download (silent mode suppresses them, and the test machine has the driver).

## Known issues

- An all-users install whose `--install-tool` download failed has no protected copy: its
  uninstaller from Windows Settings leaves the thresholds as they are (setup's Uninstall
  action still switches them off); Repair with an internet connection fixes it.
- Vantage shows the switch as "off" regardless of the state when the
  `PWRMGRV\ConfKeys` branch is missing; fix in README → Troubleshooting.
