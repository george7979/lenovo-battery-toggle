# lenovo-battery-toggle — guide

One-key toggle for ThinkPad charge thresholds: a .NET Framework 4.8 app plus an Inno Setup
installer. Requirements in [docs/PRD.md](docs/PRD.md), architecture and test procedure in
[docs/TECH.md](docs/TECH.md), stage status in [docs/PLAN.md](docs/PLAN.md).
All documentation, code comments and commit messages are in English.

## Building from WSL

MSBuild is unreliable on `\\wsl.localhost` paths, so copy the tracked files to the Windows
temp folder and build there:

```bash
WIN_TEMP=$(wslpath "$(cmd.exe /c 'echo %TEMP%' 2>/dev/null | tr -d '\r')")
W="$WIN_TEMP/lbt-build"
rm -rf "$W" && mkdir -p "$W" && git ls-files -co --exclude-standard | tar -cf - -T - | tar -xf - -C "$W"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '& "$env:TEMP\lbt-build\build.ps1" -Version 0.1.2 -Iscc "$env:TEMP\lbt-tools\inno\ISCC.exe" -Dotnet "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe"'
```

- `-Dotnet` points at a per-user .NET SDK (`%LOCALAPPDATA%\Microsoft\dotnet`); with a
  machine-wide SDK on `PATH` leave it out.
- Inno Setup 7.1.0 is unpacked portable in `%TEMP%\lbt-tools\inno` (installer with
  `/PORTABLE=1 /CURRENTUSER /DIR=...`). If missing, repeat what the CI step
  *Install Inno Setup* does.
- `rm -rf` fails with *Input/output error* while the previously built installer is still
  running; close it or build into another folder.
- Icons: `uv run --with pillow python assets/make_icon.py` (both `.ico` files and the README
  image come from this one script; never edit the `.ico` files by hand).

## Pitfalls

- **Files with non-ASCII text that Windows tools read need a UTF-8 BOM**: `.ps1` for
  Windows PowerShell 5.1 and the `.iss` script. The Write tool saves without BOM; add it
  back after rewriting such a file.
- **Process checks must exclude their own process.** Filtering `Win32_Process` by a
  command line that contains the searched text also matches the query itself; exclude `$PID`
  or wait on the process object returned by `Start-Process -PassThru`.
- **No braces inside `{ ... }` comments in the `.iss` `[Code]` section**: `{app}` in such a
  comment ends it early (*Identifier expected*). Write "the program folder" instead. Nor may
  a `[Code]` line start with `[` (an array continued on a new line): it is read as a section
  tag (*Invalid section tag*).
- **WQL with quotes inside bash `'...'`** breaks (`''` becomes empty). Put such PowerShell
  in a file under `.work/` and run it with `-File`.
- **Testing toggles the real battery.** Leave thresholds in the state the owner had before
  the test, and say which state that is.
- `ChargeThreshold.exe` must never be committed or attached to releases (`*.exe` is ignored).

## Branches and release

- Work on `dev`; `main` holds released states only. Pushes to either branch that change code
  or the installer build a CI artifact.
- Release, after the owner tested the build on the ThinkPad:
  1. on `dev`: add the `## [x.y.z] - date` section to `CHANGELOG.md`, set `<Version>` in the
     `.csproj`, update the status in `docs/PLAN.md`; push `dev` and wait for a green build,
  2. `git switch main && git merge --no-ff dev -m "Release vx.y.z"`,
  3. `git tag -a vx.y.z -m "Lenovo Battery Toggle x.y.z"` on that merge commit,
  4. push `main` and the tag; CI publishes the release with the changelog section as notes,
  5. `git switch dev` and continue there.
- `build.ps1 -Version` sets the version of both the app and the installer.
