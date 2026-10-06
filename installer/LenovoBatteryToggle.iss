; Inno Setup 6 script. Build: ISCC.exe /DAppVersion=0.1.0 /DSourceDir=<folder with the built .exe> LenovoBatteryToggle.iss
; Per-user install, no administrator rights: the app itself never needs elevation either.

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
OutputDir=..\artifacts
OutputBaseFilename=lenovo-battery-toggle-{#AppVersion}-setup
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
MinVersion=10.0

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
var
  ThresholdPage: TInputQueryWizardPage;

{ CustomMessage leaves %n as text; turn it into a line break }
function Msg(const Name: String): String;
begin
  Result := CustomMessage(Name);
  StringChangeEx(Result, '%n', #13#10, True);
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

  ThresholdPage := CreateInputQueryPage(wpSelectDir,
    CustomMessage('ThresholdsCaption'), CustomMessage('ThresholdsDescription'),
    CustomMessage('ThresholdsPrompt'));
  ThresholdPage.Add(CustomMessage('StartLabel'), False);
  ThresholdPage.Add(CustomMessage('StopLabel'), False);
  ThresholdPage.Values[0] := IntToStr(Start);
  ThresholdPage.Values[1] := IntToStr(Stop);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Start, Stop: Integer;
begin
  Result := True;
  if CurPageID = ThresholdPage.ID then
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

  ForceDirectories(ExpandConstant('{#DataDir}'));
  SaveStringToFile(ConfigPath,
    '{' + #13#10 +
    '  "start": ' + Trim(ThresholdPage.Values[0]) + ',' + #13#10 +
    '  "stop": ' + Trim(ThresholdPage.Values[1]) + #13#10 +
    '}' + #13#10, False);

  { Check the driver and download the Lenovo tool now, so the first key press works offline }
  if Exec(ExpandConstant('{app}\{#AppExe}'), '--prepare', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
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
