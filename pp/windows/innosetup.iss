# define APP	"ChordPro"
# define APPID	"ChordPro-Sm9oYW4gIFZyb21hbnMK-6"
# define APPID	"{{F8D1018C-AAE3-45E6-9447-5997F512F932}"
# define PUBLISHER "ChordPro.ORG"

; These are updated by the vfix program.
# define V_MAJ	0
# define V_MIN	85
# define V_AUX	0
# define BuildNum	27

[Setup]
ArchitecturesInstallIn64BitMode=x64 arm64
ArchitecturesAllowed=x64 arm64
AppID={#APPID}
AppName={#APP}
AppVersion={#V_MAJ}.{#V_MIN}.{#V_AUX}.{#BuildNum}.0
AppVerName={#APP} {#V_MAJ}.{#V_MIN}
AppPublisher={#PUBLISHER}
AppPublisherURL=https://www.chordpro.org
DefaultDirName={commonpf}\{#PUBLISHER}\{#APP}
DefaultGroupName=\{#PUBLISHER}\{#APP}
OutputDir=.
OutputBaseFilename={#APP}-Installer-{#V_MAJ}-{#V_MIN}-{#V_AUX}-{#BuildNum}-msw-x64
Compression=lzma/Max
SolidCompression=true
AppCopyright=Copyright (C) 2015,2017,2020 {#PUBLISHER}
PrivilegesRequired=none
InternalCompressLevel=Max
ShowLanguageDialog=no
LanguageDetectionMethod=none
WizardImageFile=chordproinst.bmp
InfoAfterFile=infoafter.txt
ChangesAssociations=yes

[Components]
Name: GUI; Description: "ChordPro GUI application"; Types: full compact
Name: CLI; Description: "ChordPro command line application"; Types: full

[Tasks]
Name: desktopicon; Description: "Create desktop icons"; Components: GUI; GroupDescription: "Additional icons:"
Name: desktopicon\common; Description: "For all users"; Components: GUI; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\user; Description: "For the current user only"; Components: GUI; GroupDescription: "Additional icons:"; Flags: exclusive unchecked

[Files]
Source: "build\*"; DestDir: {app}; Flags: recursesubdirs createallsubdirs overwritereadonly ignoreversion;

[Icons]
Name: {group}\{#APP}; Filename: {app}\wxchordpro.exe; Components: GUI; IconFilename: "{app}\chordpro.ico";
Name: "{group}\{cm:UninstallProgram,{#APP}}"; Filename: "{uninstallexe}"

Name: "{commondesktop}\{#APP}"; Filename: "{app}\wxchordpro.exe"; Tasks: desktopicon\common; IconFilename: "{app}\chordpro.ico";
Name: "{userdesktop}\{#APP}"; Filename: "{app}\wxchordpro.exe"; Tasks: desktopicon\user; IconFilename: "{app}\chordpro.ico";

[Registry]
Root: HKA; Subkey: "Software\Classes\.cho\OpenWithProgids"; ValueType: string; ValueName: ""; ValueData: "org.chordpro.chordpro"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\.crd\OpenWithProgids"; ValueType: string; ValueName: ""; ValueData: "org.chordpro.chordpro"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\org.chordpro.chordpro"; ValueType: string; ValueName: ""; ValueData: "ChordPro File"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\org.chordpro.chordpro\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\chordpro-doc.ico"""
Root: HKA; Subkey: "Software\Classes\org.chordpro.chordpro\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\wxchordpro.exe"" ""%1"""
Root: HKA; Subkey: "Software\Classes\Applications\wxchordpro.exe\SupportedTypes"; ValueType: string; ValueName: ".cho"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\Applications\wxchordpro.exe\SupportedTypes"; ValueType: string; ValueName: ".crd"; ValueData: ""

[Messages]
BeveledLabel=Perl Powered Software by Squirrel Consultancy

[InstallDelete]
Type: files; Name: "{app}\perl530.dll";
Type: files; Name: "{app}\wx*32u*.dll";
