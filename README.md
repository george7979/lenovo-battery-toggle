# Lenovo Battery Toggle

Turn ThinkPad battery charge thresholds on or off with a single key press.

Charge thresholds keep a ThinkPad that lives on the charger between, say, 75% and 80%,
which slows battery wear. Before a trip you want the opposite: a full battery, right now.
Lenovo Vantage can switch the thresholds, but it takes several clicks every time.
This app does it in one step, and it fits the user-defined key that many ThinkPads have
on **F12**.

Press the key and a short message appears in the corner of the screen:

> Charge thresholds OFF: the battery charges to 100%.

Press it again:

> Charge thresholds ON: charging starts below 75%, stops at 80%.

The message closes by itself after two seconds. There is nothing to click.

## Requirements

- A **ThinkPad** with Windows 10 or 11.
- The **Lenovo Power and Battery** driver. Windows Update installs it automatically on
  ThinkPads; it is also available from Lenovo Support as package
  [DS541411](https://support.lenovo.com/downloads/ds541411). The installer checks for it.
- **Lenovo Vantage is not required.** If you have it, both work side by side and the
  threshold switch in Vantage shows the state set by this app.

No administrator rights are needed, neither to install nor to run the app.

## Install

1. Download `lenovo-battery-toggle-<version>-setup.exe` from the
   [latest release](https://github.com/george7979/lenovo-battery-toggle/releases/latest).
2. Run it. The installer is not code-signed, so Windows SmartScreen may show
   "Windows protected your PC" on the first run: choose **More info → Run anyway**.
   On the **Charge thresholds** page choose the values used when thresholds are on
   (default: start below 75%, stop at 80%).
3. At the end the installer downloads Lenovo's `ChargeThreshold.exe` and checks its
   digital signature, so the first key press works offline.

## Assign the F12 key

1. Open **Lenovo Vantage** and find the **user-defined key** setting (F12 on many ThinkPads;
   the exact menu name depends on the Vantage version).
2. Choose the action that opens an application or file and select:

   ```
   %LOCALAPPDATA%\Programs\Lenovo Battery Toggle\lenovo-battery-toggle.exe
   ```

The app also has a Start menu entry, so any launcher or keyboard tool can start it.

## Change the thresholds

Start menu → **Charge threshold settings** opens the settings file in Notepad:

```json
{
  "start": 75,
  "stop": 80
}
```

`start` is the level below which charging starts, `stop` the level at which it stops.
Rules: whole numbers, `0 <= start < stop <= 100`. The new values apply the next time the
toggle switches thresholds on. Running the installer again also shows the current values
and lets you change them.

## Uninstall

Windows Settings → Apps → **Lenovo Battery Toggle** → Uninstall. The uninstaller:

- switches the charge thresholds **off**, so the battery returns to its factory behaviour,
- removes the program folder, the settings, the downloaded Lenovo tool and the Start menu
  entries.

Nothing is left behind: the app writes only to two folders, and both are deleted.

## How it works

The app is a small Windows program (about 20 kB, .NET Framework 4.8, which is part of
Windows). It runs Lenovo's official command-line tool
[`ChargeThreshold.exe`](https://forums.lenovo.com/t5/Lenovo-Vantage-Knowledge-Base/Q-amp-A-setting-a-ThinkPad-battery-charge-threshold-by-script/ta-p/4345631),
which sends the setting to the Lenovo Power and Battery driver, the same component
Lenovo Vantage uses. The tool belongs to Lenovo, so this project does not redistribute it:
the app downloads it from `download.lenovo.com` and accepts it only with a valid
Lenovo signature. Technical details: [docs/TECH.md](docs/TECH.md).

## Troubleshooting

**"The Lenovo Power and Battery driver is missing"** — run Windows Update, or install
package DS541411 from Lenovo Support.

**The threshold switch in Lenovo Vantage always shows "off", although the thresholds
work.** Vantage reads the state from a registry branch that the driver creates only on
its first installation. If that branch was deleted (for example after moving a disk to
another ThinkPad), reinstall the driver from scratch: in an administrator terminal run
`pnputil /remove-device` for the *Lenovo Power and Battery* device and
`pnputil /delete-driver` for its `powermgr.inf` package, then restart; Windows Update
installs it again and creates the branch.

## Disclaimer

Not affiliated with or endorsed by Lenovo. Lenovo, ThinkPad and Vantage are trademarks
of Lenovo. Use at your own risk.

## License

[MIT](LICENSE)
