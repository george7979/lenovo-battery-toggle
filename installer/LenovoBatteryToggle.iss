; Inno Setup 6 script. Build: ISCC.exe /DAppVersion=0.1.0 /DSourceDir=<folder with the built .exe> LenovoBatteryToggle.iss
; Setup asks: install for me (no administrator rights, %LOCALAPPDATA%\Programs) or for all
; users (UAC, Program Files). Settings and the Lenovo tool always live in the user's profile.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\src\LenovoBatteryToggle\bin\Release\net48"
#endif

#define AppName "Lenovo Battery Toggle"
#define AppExe "lenovo-battery-toggle.exe"
; Must match ChargeThresholdTool.DownloadUrl in the app
#define ToolUrl "https://download.lenovo.com/pccbbs//thinkvantage_en/metroapps/Vantage/ChargeThreshold/ChargeThreshold.exe"
; Must match Settings.DataDirectory in the app
#define DataDir "{localappdata}\LenovoBatteryToggle"

[Setup]
AppId={{6C1E8F4A-2B7D-4E59-9A3C-5D0F1B8E7A24}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Jerzy Maczewski
AppPublisherURL=https://github.com/george7979/lenovo-battery-toggle
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Settings are per user by design; the data folder belongs to the user who runs setup
UsedUserAreasWarning=no
OutputDir=..\artifacts
OutputBaseFilename=lenovo-battery-toggle-{#AppVersion}-setup
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
MinVersion=10.0
SetupIconFile=..\src\LenovoBatteryToggle\app.ico

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "pl"; MessagesFile: "compiler:Languages\Polish.isl"

[CustomMessages]
en.ThresholdsCaption=Charge thresholds
pl.ThresholdsCaption=Progi ładowania
en.ThresholdsDescription=Values used when the toggle switches thresholds on.
pl.ThresholdsDescription=Wartości używane, gdy przełącznik włącza progi.
en.ThresholdsPrompt=The battery starts charging below the start value and stops at the stop value. You can change them later with "Lenovo Battery Toggle Settings" in the Start menu.
pl.ThresholdsPrompt=Bateria zaczyna się ładować poniżej wartości „start” i przestaje przy wartości „stop”. Możesz je zmienić później skrótem „Lenovo Battery Toggle Settings” w menu Start.
en.StartLabel=Start charging below (%):
pl.StartLabel=Ładuj, gdy poziom spadnie poniżej (%):
en.StopLabel=Stop charging at (%):
pl.StopLabel=Przestań ładować przy (%):
en.InvalidThresholds=Enter whole numbers with 0 <= start < stop <= 100.
pl.InvalidThresholds=Wpisz liczby całkowite spełniające 0 <= start < stop <= 100.
en.DriverMissing=The Lenovo Power and Battery driver was not found.%n%nThe app needs it to change charge thresholds. Run Windows Update, or install package DS541411 from Lenovo Support, then use the app.
pl.DriverMissing=Nie znaleziono sterownika Lenovo Power and Battery.%n%nAplikacja potrzebuje go do zmiany progów ładowania. Uruchom Windows Update albo zainstaluj paczkę DS541411 ze strony wsparcia Lenovo, a potem użyj aplikacji.
en.ToolUnavailable=Could not download ChargeThreshold.exe from Lenovo (no internet connection, or the file is no longer available at Lenovo). The app cannot switch thresholds without it.%n%nDownload it manually from:%n{#ToolUrl}%n%nand save it as:%n{#DataDir}\ChargeThreshold.exe%n%nThe app accepts the file only with a valid Lenovo signature. (Ctrl+C copies this message.)
pl.ToolUnavailable=Nie udało się pobrać ChargeThreshold.exe od Lenovo (brak internetu albo plik nie jest już dostępny u Lenovo). Bez niego aplikacja nie przełączy progów.%n%nPobierz go ręcznie z:%n{#ToolUrl}%n%ni zapisz jako:%n{#DataDir}\ChargeThreshold.exe%n%nAplikacja przyjmie plik tylko z ważnym podpisem Lenovo. (Ctrl+C kopiuje treść tego komunikatu.)
en.PrepareFailed=The app could not be prepared now. It will try again on first use.
pl.PrepareFailed=Nie udało się teraz przygotować aplikacji. Spróbuje ponownie przy pierwszym użyciu.
en.MaintenanceCaption=Lenovo Battery Toggle is already installed
pl.MaintenanceCaption=Lenovo Battery Toggle jest już zainstalowany
en.MaintenanceDescription=Choose what you want to do.
pl.MaintenanceDescription=Wybierz, co chcesz zrobić.
en.InstalledForMe=Installed for you:
pl.InstalledForMe=Zainstalowany tylko dla Ciebie:
en.InstalledForAll=Installed for all users:
pl.InstalledForAll=Zainstalowany dla wszystkich użytkowników:
en.ActionRepair=Repair: restore the program files and shortcuts, keep the settings (also updates to this version)
pl.ActionRepair=Napraw: przywróć pliki programu i skróty, zachowaj ustawienia (także aktualizacja do tej wersji)
en.ActionUninstall=Uninstall: switch the charge thresholds off and delete the program and all its files
pl.ActionUninstall=Odinstaluj: wyłącz progi ładowania i usuń program oraz wszystkie jego pliki
en.Uninstalled=Lenovo Battery Toggle has been uninstalled.
pl.Uninstalled=Lenovo Battery Toggle został odinstalowany.
en.UninstallFailed=The program could not be uninstalled completely. Remove it from Windows Settings, Apps.
pl.UninstallFailed=Nie udało się całkowicie odinstalować programu. Usuń go w Ustawieniach Windows (Aplikacje).
en.ThresholdsAreOff=Charge thresholds are off now: the battery charges to 100%.
pl.ThresholdsAreOff=Progi ładowania są teraz wyłączone: bateria ładuje się do 100 %.
en.ThresholdsAreOn=Charge thresholds are on now.
pl.ThresholdsAreOn=Progi ładowania są teraz włączone.
en.SwitchOnNow=Switch charge thresholds on now (start below %1%%, stop at %2%%)
pl.SwitchOnNow=Włącz teraz progi ładowania (start poniżej %1 %%, stop przy %2 %%)
en.ApplyNow=Apply these charge thresholds now (start below %1%%, stop at %2%%)
pl.ApplyNow=Zastosuj teraz te progi ładowania (start poniżej %1 %%, stop przy %2 %%)
en.FinishedHint=To switch the charge thresholds on or off later, start Lenovo Battery Toggle from the Start menu. Each start toggles them.
pl.FinishedHint=Aby później włączyć lub wyłączyć progi ładowania, uruchom Lenovo Battery Toggle z menu Start. Każde uruchomienie je przełącza.

[Files]
Source: "{#SourceDir}\{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\{#AppExe}.config"; DestDir: "{app}"; Flags: ignoreversion
Source: "settings.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
; Named after the app so the Start menu lists it right below the app itself
Name: "{autoprograms}\{#AppName} Settings"; Filename: "{app}\{#AppExe}"; Parameters: "--settings"; IconFilename: "{app}\settings.ico"

[InstallDelete]
; Settings shortcut names used by pre-release builds; Repair replaces them with the one above
Type: files; Name: "{autoprograms}\Ustawienia progów ładowania.lnk"
Type: files; Name: "{autoprograms}\Charge threshold settings.lnk"

[Run]
; Finish page checkbox, so the user decides and knows the state when setup closes. Runs as
; the signed-in user; silent installs leave the thresholds as they are.
Filename: "{app}\{#AppExe}"; Parameters: "--on"; Description: "{code:SwitchOnDescription}"; Flags: postinstall runasoriginaluser nowait skipifsilent; Check: CanSwitchOn

[UninstallRun]
; Leave the battery at its factory behaviour before the files go away. A per-user uninstaller
; runs unelevated and uses the user's copy of the Lenovo tool; an all-users uninstaller is
; elevated and the app then uses only the copy setup put in {app} (see --install-tool).
Filename: "{app}\{#AppExe}"; Parameters: "--off"; Flags: runhidden waituntilterminated; RunOnceId: "TurnOffThresholds"

[UninstallDelete]
; Everything the app ever wrote: config.json, the downloaded ChargeThreshold.exe, any subfolder
Type: filesandordirs; Name: "{#DataDir}"
; Downloaded by --install-tool, so not removed with the [Files] entries
Type: files; Name: "{app}\ChargeThreshold.exe"
; {app} is not listed: Inno removes its own files and the empty folder, and a
; filesandordirs entry would wipe a pre-existing folder chosen as the install directory

[Code]
const
  { Inno appends _is1 to AppId. A per-user install registers under HKCU, an all-users install
    under HKLM; both can exist at the same time. }
  UninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{6C1E8F4A-2B7D-4E59-9A3C-5D0F1B8E7A24}_is1';
  ActionRepair = 0;
  ActionUninstall = 1;
  { Exit codes of --prepare }
  PrepareThresholdsOff = 0;
  PrepareThresholdsOn = 4;

var
  ThresholdPage: TInputQueryWizardPage;
  MaintenancePage: TInputOptionWizardPage;
  InstalledForMe, InstalledForAll: Boolean;
  Leaving: Boolean;
  PrepareResult: Integer;

{ CustomMessage leaves %n as text; turn it into a line break }
function Msg(const Name: String): String;
begin
  Result := CustomMessage(Name);
  StringChangeEx(Result, '%n', #13#10, True);
end;

function RegValue(Root: Integer; const Name: String): String;
begin
  if not RegQueryStringValue(Root, UninstallKey, Name, Result) then Result := '';
end;

{ Closes the wizard without the "Exit Setup?" question }
procedure Leave;
begin
  Leaving := True;
  WizardForm.Close;
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  if Leaving then Confirm := False;
end;

{ Runs one installation's uninstaller silently and waits until it is gone. ShellExec lets an
  all-users uninstaller ask for elevation. The uninstaller copies itself to a temporary file
  and returns at once, so wait for its Apps entry to disappear, not for the process. }
function UninstallFrom(Root: Integer): Boolean;
var
  ResultCode, Waited: Integer;
begin
  ShellExec('', RemoveQuotes(RegValue(Root, 'UninstallString')),
    '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Waited := 0;
  while RegKeyExists(Root, UninstallKey) and (Waited < 60000) do
  begin
    Sleep(250);
    Waited := Waited + 250;
  end;
  Result := not RegKeyExists(Root, UninstallKey);
end;

{ Fallback for an all-users install whose --install-tool failed: its elevated uninstaller has
  no tool it may run, so switch thresholds off here, as the signed-in user, before starting it }
procedure TurnOffAsOriginalUser(Root: Integer);
var
  ResultCode: Integer;
begin
  try
    ExecAsOriginalUser(AddBackslash(RegValue(Root, 'InstallLocation')) + '{#AppExe}', '--off',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  except
    { Uninstall goes on; thresholds stay as they are }
  end;
end;

function ConfigPath: String;
begin
  Result := ExpandConstant('{#DataDir}\config.json');
end;

{ Reads "key": number from the existing config.json; Default when absent }
function ReadConfigValue(const Json, Key: String; Default: Integer): Integer;
var
  P, I: Integer;
  Digits: String;
begin
  Result := Default;
  P := Pos('"' + Key + '"', Json);
  if P = 0 then Exit;
  I := P + Length(Key) + 2;
  while (I <= Length(Json)) and ((Json[I] = ':') or (Json[I] = ' ') or (Json[I] = #9)) do
    I := I + 1;
  Digits := '';
  while (I <= Length(Json)) and (Json[I] >= '0') and (Json[I] <= '9') do
  begin
    Digits := Digits + Json[I];
    I := I + 1;
  end;
  Result := StrToIntDef(Digits, Default);
end;

procedure InitializeWizard;
var
  Json: AnsiString;
  Start, Stop: Integer;
  Where: String;
begin
  PrepareResult := -1;
  Start := 75;
  Stop := 80;
  { An upgrade keeps the user's values }
  if LoadStringFromFile(ConfigPath, Json) then
  begin
    Start := ReadConfigValue(Json, 'start', Start);
    Stop := ReadConfigValue(Json, 'stop', Stop);
  end;

  { Inno reuses the mode of an existing installation and skips the mode dialog, so Repair
    always works on the installation that is there }
  InstalledForMe := RegKeyExists(HKCU, UninstallKey);
  InstalledForAll := RegKeyExists(HKLM, UninstallKey);
  Where := '';
  if InstalledForMe then
    Where := Where + CustomMessage('InstalledForMe') + #13#10 + RegValue(HKCU, 'InstallLocation') + #13#10#13#10;
  if InstalledForAll then
    Where := Where + CustomMessage('InstalledForAll') + #13#10 + RegValue(HKLM, 'InstallLocation') + #13#10#13#10;
  MaintenancePage := CreateInputOptionPage(wpWelcome,
    CustomMessage('MaintenanceCaption'), CustomMessage('MaintenanceDescription'),
    Trim(Where), True, False);
  MaintenancePage.Add(CustomMessage('ActionRepair'));
  MaintenancePage.Add(CustomMessage('ActionUninstall'));
  MaintenancePage.SelectedValueIndex := ActionRepair;

  ThresholdPage := CreateInputQueryPage(wpSelectDir,
    CustomMessage('ThresholdsCaption'), CustomMessage('ThresholdsDescription'),
    CustomMessage('ThresholdsPrompt'));
  ThresholdPage.Add(CustomMessage('StartLabel'), False);
  ThresholdPage.Add(CustomMessage('StopLabel'), False);
  ThresholdPage.Values[0] := IntToStr(Start);
  ThresholdPage.Values[1] := IntToStr(Stop);
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = MaintenancePage.ID) and not (InstalledForMe or InstalledForAll);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Start, Stop: Integer;
  Removed: Boolean;
begin
  Result := True;
  if (CurPageID = MaintenancePage.ID) and (MaintenancePage.SelectedValueIndex = ActionUninstall) then
  begin
    { Removes every installation found, so nothing is left even if both exist }
    Result := False;
    Removed := True;
    { First, while the Lenovo tool is still there: an elevated setup starts the per-user
      uninstaller elevated too, so its own --off does nothing, and it deletes the tool }
    if InstalledForAll then TurnOffAsOriginalUser(HKLM);
    if InstalledForMe then Removed := UninstallFrom(HKCU) and Removed;
    if InstalledForAll then Removed := UninstallFrom(HKLM) and Removed;
    if Removed then
      MsgBox(CustomMessage('Uninstalled'), mbInformation, MB_OK)
    else
      MsgBox(CustomMessage('UninstallFailed'), mbError, MB_OK);
    Leave;
  end
  else if CurPageID = ThresholdPage.ID then
  begin
    Start := StrToIntDef(Trim(ThresholdPage.Values[0]), -1);
    Stop := StrToIntDef(Trim(ThresholdPage.Values[1]), -1);
    if not ((Start >= 0) and (Stop <= 100) and (Start < Stop)) then
    begin
      MsgBox(CustomMessage('InvalidThresholds'), mbError, MB_OK);
      Result := False;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep <> ssPostInstall then Exit;

  { All users: download the Lenovo tool into the program folder, where only administrators
    can write, so the elevated uninstaller has a copy it may run. Done first, so --prepare
    uses this copy instead of downloading one into the profile. If it fails, --prepare falls
    back to the profile and reports as usual. }
  if IsAdminInstallMode then
    Exec(ExpandConstant('{app}\{#AppExe}'), '--install-tool', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  { The app writes the settings, checks the driver and downloads the Lenovo tool, so the first
    key press works offline. It runs as the signed-in user: with an all-users install setup is
    elevated, and the settings must still land in that user's profile. }
  if ExecAsOriginalUser(ExpandConstant('{app}\{#AppExe}'),
    '--prepare ' + Trim(ThresholdPage.Values[0]) + ' ' + Trim(ThresholdPage.Values[1]),
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    PrepareResult := ResultCode;
    if ResultCode = 2 then
      SuppressibleMsgBox(Msg('DriverMissing'), mbError, MB_OK, IDOK)
    else if ResultCode = 3 then
      SuppressibleMsgBox(ExpandConstant(Msg('ToolUnavailable')), mbError, MB_OK, IDOK)
    else if (ResultCode <> PrepareThresholdsOff) and (ResultCode <> PrepareThresholdsOn) then
      SuppressibleMsgBox(Msg('PrepareFailed'), mbInformation, MB_OK, IDOK);
  end;
end;

{ The finish page checkbox appears only when --prepare could read the state }
function CanSwitchOn: Boolean;
begin
  Result := (PrepareResult = PrepareThresholdsOff) or (PrepareResult = PrepareThresholdsOn);
end;

function SwitchOnDescription(Param: String): String;
var
  Name: String;
begin
  if PrepareResult = PrepareThresholdsOn then Name := 'ApplyNow' else Name := 'SwitchOnNow';
  { A line must not start with "[": the compiler would read it as a section tag }
  Result := FmtMessage(CustomMessage(Name), [Trim(ThresholdPage.Values[0]),
    Trim(ThresholdPage.Values[1])]);
end;

procedure CurPageChanged(CurPageID: Integer);
var
  State: String;
begin
  if CurPageID <> wpFinished then Exit;
  State := '';
  if PrepareResult = PrepareThresholdsOff then State := Msg('ThresholdsAreOff') + #13#10#13#10;
  if PrepareResult = PrepareThresholdsOn then State := Msg('ThresholdsAreOn') + #13#10#13#10;
  WizardForm.FinishedLabel.Caption := WizardForm.FinishedLabel.Caption + #13#10#13#10 +
    State + ExpandConstant(Msg('FinishedHint'));
  { The checkbox list was placed under the shorter text; move it below the longer one }
  WizardForm.RunList.Top := WizardForm.RunList.Top + WizardForm.AdjustLabelHeight(WizardForm.FinishedLabel);
end;
