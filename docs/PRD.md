# Product Requirements - Lenovo Battery Toggle

## Summary

A one-key switch for ThinkPad battery charge thresholds: thresholds on for everyday work
on the charger, off when a full battery is needed now.

## Problem

- A ThinkPad that stays on the charger wears its battery less with charge thresholds
  (for example 75–80%). Lenovo Vantage sets them.
- Sometimes the thresholds have to go away for a moment: before a trip, a long meeting
  or a day away from the desk, the battery should charge to 100% quickly.
- In Vantage this takes several clicks each way, and it is easy to forget to switch the
  thresholds back on afterwards.
- Many ThinkPads have a user-defined key (F12) that can open any program. A program that
  toggles the thresholds turns that key into a dedicated threshold switch.

## Users

ThinkPad owners who keep the laptop on the charger most of the time and occasionally
need a full battery. The author is the first user; the app is published on GitHub for
other ThinkPad owners.

## Functional requirements

### FR1: Toggle
- Running the app with no arguments switches thresholds off when they are on, and on
  when they are off.
- "On" uses the start/stop values from the settings.
- A press during a running toggle does nothing, so a double press cannot flip the state
  back.

### FR2: Feedback
- After the change the app shows the state it read back from the system, not the one it
  intended to set.
- The message closes by itself (2 s; errors 6 s), needs no click and does not take focus
  from the active window.
- Messages are in Polish on a Polish Windows and in English everywhere else.

### FR3: Settings
- Start and stop values are set in a small settings window opened from the Start menu.
  It accepts only valid values, so a typo cannot break the settings; when thresholds are on,
  saving applies the new values right away.
- The installer asks for the values and keeps the current ones on upgrade.
- Invalid values (not `0 <= start < stop <= 100`) are reported, never sent to the battery.

### FR4: Prerequisites
- The app needs the Lenovo Power and Battery driver and checks for it; it does not
  install drivers. Lenovo Vantage is optional.
- The Lenovo tool `ChargeThreshold.exe` is downloaded from Lenovo, never shipped with
  the app, and used only with a valid Lenovo signature.

### FR5: Install and uninstall
- A standard Windows installer with a Start menu entry and an entry in Apps.
- The uninstaller switches thresholds off and removes everything the app wrote,
  including folders.

## Non-functional requirements

- **No administrator rights** for installing, running or uninstalling.
- **Small and dependency-free:** runs on any Windows 10/11 without installing a runtime.
- **Offline after installation:** the installer prepares everything the first press needs.

## Constraints

- Works only on ThinkPads whose firmware supports charge thresholds and with the Lenovo
  Power and Battery driver present.
- One pair of thresholds for all batteries (a limit of `ChargeThreshold.exe`).

## Acceptance criteria

- Pressing the assigned key toggles thresholds and shows the new state within about 3 s.
- The Vantage threshold switch shows the same state as the app.
- After uninstall the program folder, the data folder, the Start menu entries and the
  Apps entry are gone, and thresholds are off.
