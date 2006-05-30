program Import;

uses
  QForms,
  fMain in 'fMain.pas' {MainForm},
  fDwin in 'fDwin.pas' {dwin};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(Tdwin, dwin);
  Application.Run;
end.

