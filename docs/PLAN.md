# Plan - Lenovo Battery Toggle

## Stages

| Stage | Scope | Status |
|---|---|---|
| 0.1 | App (toggle, notification with adjustable time, settings window, driver check, icons), Inno Setup installer (install mode choice, threshold page, Repair / Uninstall, manual-download instructions, full uninstall), CI with releases | released as **v0.1.0** |
| 0.1.1 | Security review fixes (no elevated run of the user's tool copy, protected copy for all-users installs, exact signer check), finish page with the threshold state and a switch-on option, shorter closing hint | released as **v0.1.1** |

## Milestones

- **v0.1.0** — first GitHub release ([CHANGELOG](../CHANGELOG.md)).
- **v0.1.1** — security fixes and the finish page.

## Backlog

- **Current state in the settings window** — one line ("Charge thresholds are on/off now")
  read when the window opens, as a lightweight alternative to a tray icon (see TECH →
  *Deliberately: no tray icon*).
