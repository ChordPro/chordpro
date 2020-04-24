# define APP	"ChordPro"
# define V_MAJ	0
# define V_MIN	85
# define V_AUX	0
# define BuildNum	27
# define PUBLISHER "ChordPro.ORG"
# define SRC	"C:\Users\Johan\Documents\ChordPro"
# define DEST	"C:\Users\Johan\Documents\ChordPro"

; Increment the build number by one.
;#define BuildNum Int(ReadIni(SourcePath	+ "BuildInfo.ini","Info","Build","0"))
;#expr BuildNum = BuildNum + 1
;#expr WriteIni(SourcePath + "BuildInfo.ini","Info","Build", BuildNum)

[Setup]
AppID={{F8D1018C-AAE3-45E6-9447-5997F512F932}
AppName={#APP}
AppVersion={#V_MAJ}.{#V_MIN}.{#V_AUX}.{#BuildNum}.0
AppVerName={#APP} {#V_MAJ}.{#V_MIN}
AppPublisher={#PUBLISHER}
AppPublisherURL=https://www.chordpro.org
DefaultDirName={pf}\{#PUBLISHER}\{#APP}
DefaultGroupName=\{#PUBLISHER}\{#APP}
OutputDir=.
OutputBaseFilename={#APP}-GUI-installer-{#V_MAJ}-{#V_MIN}-{#V_AUX}-{#BuildNum}-msw-x64
Compression=lzma/Max
SolidCompression=true
AppCopyright=Copyright (C) 2015,2017,2020 {#PUBLISHER}
PrivilegesRequired=none
InternalCompressLevel=Max
ShowLanguageDialog=no
LanguageDetectionMethod=none
WizardImageFile=chordproinst.bmp
InfoAfterFile=infoafter.txt

[Components]
Name: GUI; Description: "ChordPro GUI application"; Types: full compact
Name: CLI; Description: "ChordPro command line application"; Types: full

[Tasks]
Name: desktopicon; Description: "Create desktop icons"; Components: GUI; GroupDescription: "Additional icons:"
Name: desktopicon\common; Description: "For all users"; Components: GUI; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\user; Description: "For the current user only"; Components: GUI; GroupDescription: "Additional icons:"; Flags: exclusive unchecked

[Files]
Source: chordpro.ico;   DestDir: {app};     Components: GUI; Flags: overwritereadonly;
Source: wxchordpro.exe; DestDir: {app}\bin; Components: GUI; Flags: ignoreversion recursesubdirs createallsubdirs overwritereadonly 64bit;
Source: chordpro.exe;   DestDir: {app}\bin; Components: CLI; Flags: ignoreversion recursesubdirs createallsubdirs overwritereadonly 64bit;

[Icons]
Name: {group}\{#APP}; Filename: {app}\bin\wxchordpro.exe; Components: GUI; IconFilename: "{app}\chordpro.ico";
Name: "{group}\{cm:UninstallProgram,{#APP}}"; Filename: "{uninstallexe}"

Name: "{commondesktop}\{#APP}"; Filename: "{app}\bin\wxchordpro.exe"; Tasks: desktopicon\common; IconFilename: "{app}\chordpro.ico";
Name: "{userdesktop}\{#APP}"; Filename: "{app}\bin\wxchordpro.exe"; Tasks: desktopicon\user; IconFilename: "{app}\chordpro.ico";

[Run]
Filename: "{app}\bin\wxchordpro.exe"; Description: "Prepare"; Components: GUI; Parameters: "--quit"; StatusMsg: "Preparing... (be patient)..."
Filename: "{app}\bin\chordpro.exe"; Description: "Prepare"; Components: CLI; Parameters: "--version"; StatusMsg: "Preparing... (be patient)..."

[Messages]
BeveledLabel=Perl Powered Software by Squirrel Consultancy
