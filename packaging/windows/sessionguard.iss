#define AppName "LeoMoon SessionGuard"
#define AppExeName "LeoMoon SessionGuard.exe"
#ifndef AppVersion
  #error AppVersion must be supplied.
#endif
#ifndef StageDir
  #error StageDir must be supplied.
#endif
#ifndef OutputDir
  #error OutputDir must be supplied.
#endif

[Setup]
AppId={{93D9AB2D-8CB1-4C47-B305-932988173887}
AppName={#AppName}
AppVersion={#AppVersion}
VersionInfoVersion={#AppVersion}.0
VersionInfoProductVersion={#AppVersion}.0
AppPublisher=LeoMoon Studios Inc.
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=leomoon-sessionguard-{#AppVersion}-windows-x86-setup
Compression=lzma2/ultra64
SolidCompression=yes
CloseApplications=yes
CloseApplicationsFilter={#AppExeName}
RestartApplications=no
UninstallDisplayIcon={app}\{#AppExeName}
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#StageDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var CurrentValue, InstalledValue: String;
begin
  if CurUninstallStep = usUninstall then begin
    InstalledValue := '"' + ExpandConstant('{app}\{#AppExeName}') + '"';
    if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', '{#AppName}', CurrentValue) and
       (CompareText(CurrentValue, InstalledValue) = 0) then
      RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', '{#AppName}');
  end;
end;
