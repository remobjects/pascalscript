program TestApplication;

uses
  Forms,
  fMain in 'fMain.pas' {Form1},
  uPSComponent_COM in '..\..\Source\uPSComponent_COM.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Test Application';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
