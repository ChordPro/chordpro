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
DefaultDirName={pf}\{#PUBLISHER}\{#APP}
DefaultGroupName=\{#PUBLISHER}\{#APP}
OutputDir={#DEST}
OutputBaseFilename={#APP}-GUI-installer-{#V_MAJ}-{#V_MIN}-{#V_AUX}-{#BuildNum}-msw-x64
Compression=lzma/Max
SolidCompression=true
AppCopyright=Copyright (C) 2017 {#PUBLISHER}
PrivilegesRequired=none
InternalCompressLevel=Max
ShowLanguageDialog=no
LanguageDetectionMethod=none
WizardImageFile={#SRC}\chordproinst.bmp

[Tasks]
Name: desktopicon; Description: "Create desktop icons"; GroupDescription: "Additional icons:"
Name: desktopicon\common; Description: "For all users"; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\user; Description: "For the current user only"; GroupDescription: "Additional icons:"; Flags: exclusive unchecked

[Files]
Source: {#SRC}\wxchordpro.exe; DestDir: {app}\bin; Flags: ignoreversion recursesubdirs createallsubdirs overwritereadonly 64bit;

[Icons]
Name: {group}\{#APP}; Filename: {app}\bin\wxchordpro.exe; IconFilename: "{#SRC}\chordpro.ico";
Name: "{group}\{cm:UninstallProgram,{#APP}}"; Filename: "{uninstallexe}"

Name: "{commondesktop}\{#APP}"; Filename: "{app}\bin\wxchordpro.exe"; Tasks: desktopicon\common; IconFilename: "{#SRC}\chordpro.ico";
Name: "{userdesktop}\{#APP}"; Filename: "{app}\bin\wxchordpro.exe"; Tasks: desktopicon\user; IconFilename: "{#SRC}\chordpro.ico";

[Run]
Filename: "{app}\bin\wxchordpro.exe"; Description: "Prepare"; Parameters: "--quit"; StatusMsg: "Preparing... (be patient)..."

[Messages]
BeveledLabel=Perl Powered Software by Squirrel Consultancy
