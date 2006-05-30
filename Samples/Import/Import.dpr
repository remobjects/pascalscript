program Import;

uses
  Forms,
  fMain in 'fMain.pas' {MainForm},
  fDwin in 'fDwin.pas' {dwin};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Import Sample';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(Tdwin, dwin);
  Application.Run;
end.

