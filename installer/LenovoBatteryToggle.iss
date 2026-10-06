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
en.SettingsShortcut=Charge threshold settings
pl.SettingsShortcut=Ustawienia progów ładowania
en.ThresholdsCaption=Charge thresholds
pl.ThresholdsCaption=Progi ładowania
en.ThresholdsDescription=Values used when the toggle switches thresholds on.
pl.ThresholdsDescription=Wartości używane, gdy przełącznik włącza progi.
en.ThresholdsPrompt=The battery starts charging below the start value and stops at the stop value. You can change them later from the Start menu.
pl.ThresholdsPrompt=Bateria zaczyna się ładować poniżej wartości „start” i przestaje przy wartości „stop”. Możesz je zmienić później z menu Start.
en.StartLabel=Start charging below (%):
pl.StartLabel=Ładuj, gdy poziom spadnie poniżej (%):
en.StopLabel=Stop charging at (%):
pl.StopLabel=Przestań ładować przy (%):
en.InvalidThresholds=Enter whole numbers with 0 <= start < stop <= 100.
pl.InvalidThresholds=Wpisz liczby całkowite spełniające 0 <= start < stop <= 100.
en.DriverMissing=The Lenovo Power and Battery driver was not found.%n%nThe app needs it to change charge thresholds. Run Windows Update, or install package DS541411 from Lenovo Support, then use the app.
pl.DriverMissing=Nie znaleziono sterownika Lenovo Power and Battery.%n%nAplikacja potrzebuje go do zmiany progów ładowania. Uruchom Windows Update albo zainstaluj paczkę DS541411 ze strony wsparcia Lenovo, a potem użyj aplikacji.
en.PrepareFailed=Could not download ChargeThreshold.exe from Lenovo now. The app will try again on first use.
pl.PrepareFailed=Nie udało się teraz pobrać ChargeThreshold.exe od Lenovo. Aplikacja spróbuje ponownie przy pierwszym użyciu.
en.MaintenanceCaption=Lenovo Battery Toggle is already installed
pl.MaintenanceCaption=Lenovo Battery Toggle jest już zainstalowany
en.MaintenanceDescription=Choose what you want to do.
pl.MaintenanceDescription=Wybierz, co chcesz zrobić.
en.MaintenancePrompt=Repair keeps your threshold settings and also updates the program to this version. Reinstall and Remove switch the charge thresholds off and delete the settings.
pl.MaintenancePrompt=Naprawa zachowuje ustawienia progów i aktualizuje program do tej wersji. Ponowna instalacja i usunięcie wyłączają progi ładowania i kasują ustawienia.
en.ActionRepair=Repair: restore the program files and shortcuts
pl.ActionRepair=Napraw: przywróć pliki programu i skróty
en.ActionReinstall=Reinstall: remove the program, then install it from scratch
pl.ActionReinstall=Zainstaluj ponownie: usuń program i zainstaluj go od nowa
en.ActionRemove=Remove: uninstall the program and delete all its files
pl.ActionRemove=Usuń: odinstaluj program i skasuj wszystkie jego pliki
en.UninstallTimeout=The previous installation could not be removed. Remove it from Windows Settings, Apps, and run setup again.
pl.UninstallTimeout=Nie udało się usunąć poprzedniej instalacji. Usuń ją w Ustawieniach Windows (Aplikacje) i uruchom instalator ponownie.
en.FinishedHint=To toggle thresholds with one key, open Lenovo Vantage, find the user-defined key (F12 on many ThinkPads) and set it to open:%n%n{app}\{#AppExe}
pl.FinishedHint=Aby przełączać progi jednym klawiszem, otwórz Lenovo Vantage, znajdź klawisz definiowany przez użytkownika (F12 w wielu ThinkPadach) i ustaw w nim otwieranie pliku:%n%n{app}\{#AppExe}

[Files]
Source: "{#SourceDir}\{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\{#AppExe}.config"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autoprograms}\{cm:SettingsShortcut}"; Filename: "{sys}\notepad.exe"; Parameters: """{#DataDir}\config.json"""

[UninstallRun]
; Leave the battery at its factory behaviour before the files go away
Filename: "{app}\{#AppExe}"; Parameters: "--off"; Flags: runhidden waituntilterminated; RunOnceId: "TurnOffThresholds"

[UninstallDelete]
; Everything the app ever wrote: config.json, the downloaded ChargeThreshold.exe, any subfolder
Type: filesandordirs; Name: "{#DataDir}"
; {app} is not listed: Inno removes its own files and the empty folder, and a
; filesandordirs entry would wipe a pre-existing folder chosen as the install directory

[Code]
const
  { Inno appends _is1 to AppId; HKA is HKCU for a per-user install and HKLM for all users }
  UninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{6C1E8F4A-2B7D-4E59-9A3C-5D0F1B8E7A24}_is1';
  ActionRepair = 0;
  ActionReinstall = 1;
  ActionRemove = 2;

var
  ThresholdPage: TInputQueryWizardPage;
  MaintenancePage: TInputOptionWizardPage;
  IsInstalled: Boolean;
  Leaving: Boolean;

{ CustomMessage leaves %n as text; turn it into a line break }
function Msg(const Name: String): String;
begin
  Result := CustomMessage(Name);
  StringChangeEx(Result, '%n', #13#10, True);
end;

{ The uninstaller of the existing installation, or '' when there is none }
function ExistingUninstaller: String;
var
  Value: String;
begin
  Result := '';
  if RegQueryStringValue(HKA, UninstallKey, 'UninstallString', Value) then
    Result := RemoveQuotes(Value);
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

{ Runs the existing uninstaller silently and waits until it is gone. The uninstaller copies
  itself to a temporary file and returns at once, so waiting for the process is not enough:
  wait for its Apps entry to disappear. }
function UninstallSilently: Boolean;
var
  ResultCode, Waited: Integer;
begin
  Exec(ExistingUninstaller, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Waited := 0;
  while RegKeyExists(HKA, UninstallKey) and (Waited < 60000) do
  begin
    Sleep(250);
    Waited := Waited + 250;
  end;
  Result := not RegKeyExists(HKA, UninstallKey);
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
begin
  Start := 75;
  Stop := 80;
  { An upgrade keeps the user's values }
  if LoadStringFromFile(ConfigPath, Json) then
  begin
    Start := ReadConfigValue(Json, 'start', Start);
    Stop := ReadConfigValue(Json, 'stop', Stop);
  end;

  IsInstalled := ExistingUninstaller <> '';
  MaintenancePage := CreateInputOptionPage(wpWelcome,
    CustomMessage('MaintenanceCaption'), CustomMessage('MaintenanceDescription'),
    CustomMessage('MaintenancePrompt'), True, False);
  MaintenancePage.Add(CustomMessage('ActionRepair'));
  MaintenancePage.Add(CustomMessage('ActionReinstall'));
  MaintenancePage.Add(CustomMessage('ActionRemove'));
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
  Result := (PageID = MaintenancePage.ID) and not IsInstalled;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Start, Stop, ResultCode: Integer;
begin
  Result := True;
  if CurPageID = MaintenancePage.ID then
  begin
    case MaintenancePage.SelectedValueIndex of
      ActionReinstall:
        begin
          Result := False;
          if UninstallSilently then
          begin
            { A fresh setup sees no installation, so it asks for the install mode again.
              It runs as the signed-in user even when this setup is elevated. }
            ExecAsOriginalUser(ExpandConstant('{srcexe}'), '/LANG=' + ActiveLanguage, '',
              SW_SHOW, ewNoWait, ResultCode);
            Leave;
          end
          else
            MsgBox(CustomMessage('UninstallTimeout'), mbError, MB_OK);
        end;
      ActionRemove:
        begin
          Result := False;
          Exec(ExistingUninstaller, '', '', SW_SHOW, ewNoWait, ResultCode);
          Leave;
        end;
    end;
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

  { The app writes the settings, checks the driver and downloads the Lenovo tool, so the first
    key press works offline. It runs as the signed-in user: with an all-users install setup is
    elevated, and the settings must still land in that user's profile. }
  if ExecAsOriginalUser(ExpandConstant('{app}\{#AppExe}'),
    '--prepare ' + Trim(ThresholdPage.Values[0]) + ' ' + Trim(ThresholdPage.Values[1]),
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if ResultCode = 2 then
      SuppressibleMsgBox(Msg('DriverMissing'), mbError, MB_OK, IDOK)
    else if ResultCode <> 0 then
      SuppressibleMsgBox(Msg('PrepareFailed'), mbInformation, MB_OK, IDOK);
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
    WizardForm.FinishedLabel.Caption := WizardForm.FinishedLabel.Caption + #13#10#13#10 +
      ExpandConstant(Msg('FinishedHint'));
end;
