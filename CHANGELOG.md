# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- The settings window shows whether the charge thresholds are on or off right now.

### Fixed

- Uninstalling an all-users installation from Windows Settings now switches the thresholds
  off even when the installer could not download `ChargeThreshold.exe`: the uninstaller
  copies the user's copy into the program folder and uses it only after checking it there
  (Lenovo signature and the exact file Lenovo publishes). No internet is needed.
- The documentation gives the right folder for an all-users installation:
  `C:\Program Files (x86)\Lenovo Battery Toggle`.

## [0.1.1] - 2026-10-06

Security fixes and a clearer end of installation.

### Added

- The installer's last page says whether the charge thresholds are on or off and offers to
  switch them on with the values just chosen (checked by default), so the state is clear
  when setup closes. Silent installs leave the thresholds as they are.

### Changed

- The installer's closing hint now just says to start the app from the Start menu, instead
  of describing the key setup in Lenovo Vantage (which differs between Vantage versions;
  the README still explains it).

### Security

- The app no longer starts `ChargeThreshold.exe` from the user's profile with
  administrator rights. The profile can be changed by programs running without those
  rights, so the elevated uninstaller of an all-users installation could be used to bypass
  UAC. An all-users installation now keeps its own copy of the tool in the program folder,
  which only administrators can change, and the uninstaller uses that copy; uninstalling
  from Windows Settings or from the installer switches the thresholds off as before.
- The signature check requires `CN=Lenovo` and `O=Lenovo` as whole parts of the signer
  name instead of the text `O=Lenovo` anywhere in it.

## [0.1.0] - 2026-10-06

First release.

### Added

- **One-key toggle** for ThinkPad battery charge thresholds: every start of
  `lenovo-battery-toggle.exe` switches the thresholds off when they are on and on when they
  are off, using Lenovo's official `ChargeThreshold.exe` and the Lenovo Power and Battery
  driver (Lenovo Vantage is not required).
- **Notification** in the corner of the screen with the state read back from the system;
  it closes by itself, does not take focus and needs no click. Polish or English, following
  the Windows display language.
- **Settings window** (Start menu → *Lenovo Battery Toggle Settings*): start and stop
  thresholds, and how long the notification stays on screen (2–10 s). It accepts only valid
  values; when thresholds are on, saving applies the new values at once.
- **Installer** (Inno Setup, Polish and English):
  - install for the current user only (no administrator rights) or for all users,
  - threshold page, prefilled with the current values on repair,
  - checks the Lenovo Power and Battery driver and downloads `ChargeThreshold.exe` from
    Lenovo, accepting it only with a valid Lenovo signature; if the download fails, it shows
    where to get the file and where to save it,
  - with the app installed it offers **Repair** (keeps settings, also used for updates) or
    **Uninstall** (removes every installation found).
- **Uninstaller** switches the thresholds off and removes the program, the settings, the
  downloaded Lenovo tool and the Start menu entries.
- App and settings icons.
