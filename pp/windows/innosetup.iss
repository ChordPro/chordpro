# define APP	"ChordPro"
# define PUBLISHER "ChordPro.ORG"

; These are updated by the vfix program.
# define V_MAJ	0
# define V_MIN	85
# define V_AUX	0
# define BuildNum	27

[Setup]
AppID={{F8D1018C-AAE3-45E6-9447-5997F512F932}
AppName={#APP}
AppVersion={#V_MAJ}.{#V_MIN}.{#V_AUX}.{#BuildNum}.0
AppVerName={#APP} {#V_MAJ}.{#V_MIN}
AppPublisher={#PUBLISHER}
AppPublisherURL=https://www.chordpro.org
DefaultDirName={commonpf}\{#PUBLISHER}\{#APP}
DefaultGroupName=\{#PUBLISHER}\{#APP}
OutputDir=.
OutputBaseFilename={#APP}-installer-{#V_MAJ}-{#V_MIN}-{#V_AUX}-{#BuildNum}-msw-x64
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
Name: {group}\{#APP}; Filename: {app}\bin\wxchordpro.exe; Components: GUI; IconFilename: "{app}\chordpro.ico";
Name: "{group}\{cm:UninstallProgram,{#APP}}"; Filename: "{uninstallexe}"

Name: "{commondesktop}\{#APP}"; Filename: "{app}\wxchordpro.exe"; Tasks: desktopicon\common; IconFilename: "{app}\chordpro.ico";
Name: "{userdesktop}\{#APP}"; Filename: "{app}\wxchordpro.exe"; Tasks: desktopicon\user; IconFilename: "{app}\chordpro.ico";

[Registry]
Root: HKCR; Subkey: ".cho"; ValueType: string; ValueName: ""; ValueData: "org.chordpro.chordpro"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "org.chordpro.chordpro"; ValueType: string; ValueName: ""; ValueData: "ChordPro File"; Flags: uninsdeletekey
Root: HKCR; Subkey: "org.chordpro.chordpro\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\chordpro-doc.ico"
Root: HKCR; Subkey: "org.chordpro.chordpro\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\wxchordpro.exe"" ""%1"""

[Messages]
BeveledLabel=Perl Powered Software by Squirrel Consultancy
