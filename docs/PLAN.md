# Plan - Lenovo Battery Toggle

## Stages

| Stage | Scope | Status |
|---|---|---|
| 0.1 | App (toggle, notification with adjustable time, settings window, driver check, icons), Inno Setup installer (install mode choice, threshold page, Repair / Uninstall, manual-download instructions, full uninstall), CI with releases | released as **v0.1.0** |
| 0.1.1 | Security review fixes (no elevated run of the user's tool copy, protected copy for all-users installs, exact signer check), finish page with the threshold state and a switch-on option, shorter closing hint | released as **v0.1.1** |
| 0.1.2 | Uninstall without a protected copy promotes the user's copy (no internet needed), current state in the settings window, correct all-users folder in the docs | released as **v0.1.2** |

## Milestones

- **v0.1.0** — first GitHub release ([CHANGELOG](../CHANGELOG.md)).
- **v0.1.1** — security fixes and the finish page.
- **v0.1.2** — uninstall without network for all-users installs, state in the settings window.
