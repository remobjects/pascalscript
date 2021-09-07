program Invoke_Testing;

uses
  Vcl.Forms,
  Invoke_Testing_unit in 'Invoke_Testing_unit.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
