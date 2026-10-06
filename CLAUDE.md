# lenovo-battery-toggle — guide

One-key toggle for ThinkPad charge thresholds: a .NET Framework 4.8 app plus an Inno Setup
installer. Requirements in [docs/PRD.md](docs/PRD.md), architecture and test procedure in
[docs/TECH.md](docs/TECH.md), stage status in [docs/PLAN.md](docs/PLAN.md).
All documentation, code comments and commit messages are in English.

## Building from WSL

MSBuild is unreliable on `\\wsl.localhost` paths, so copy the tracked files to a Windows
folder and build there:

```bash
W=/mnt/c/Users/LENOVO/AppData/Local/Temp/lbt-build
rm -rf $W && mkdir -p $W && git ls-files -co --exclude-standard | tar -cf - -T - | tar -xf - -C $W
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\Users\LENOVO\AppData\Local\Temp\lbt-build\build.ps1' -Version 0.1.0 -Iscc \"\$env:TEMP\lbt-tools\inno\ISCC.exe\" -Dotnet \"\$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe\""
```

- .NET SDK is per-user: `%LOCALAPPDATA%\Microsoft\dotnet\dotnet.exe`.
- Inno Setup 7.1.0 is unpacked portable in `%TEMP%\lbt-tools\inno` (installer with
  `/PORTABLE=1 /CURRENTUSER /DIR=...`). If missing, repeat what the CI step
  *Install Inno Setup* does.
- Icons: `uv run --with pillow python assets/make_icon.py` (both `.ico` files and the README
  image come from this one script; never edit the `.ico` files by hand).

## Pitfalls

- **Files with non-ASCII text that Windows tools read need a UTF-8 BOM**: `.ps1` for
  Windows PowerShell 5.1 and the `.iss` script. The Write tool saves without BOM; add it
  back after rewriting such a file.
- **Process checks must exclude their own process.** Filtering `Win32_Process` by a
  command line that contains the searched text also matches the query itself; exclude `$PID`
  or wait on the process object returned by `Start-Process -PassThru`.
- **WQL with quotes inside bash `'...'`** breaks (`''` becomes empty). Put such PowerShell
  in a file under `.work/` and run it with `-File`.
- **Testing toggles the real battery.** Leave thresholds in the state the owner had before
  the test, and say which state that is.
- `ChargeThreshold.exe` must never be committed or attached to releases (`*.exe` is ignored).

## Release

A push to `main` that changes code or the installer builds a CI artifact. A release is a
tag `v<version>` on `main`; propose the tag only after the owner tested the build on the
ThinkPad. `build.ps1 -Version` sets the version of both the app and the installer.
