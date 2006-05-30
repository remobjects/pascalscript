program imp;

uses
  Forms,
  Main in 'Main.pas' {frmMain},
  ParserU in 'ParserU.pas',
  ParserUtils in 'ParserUtils.pas',
  BigIni in 'BigIni.pas',
  FormSettings in 'FormSettings.pas' {frmSettings},
  UFrmGotoLine in 'UFrmGotoLine.pas' {frmGotoLine};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmGotoLine, frmGotoLine);
  Application.Run;
end.
