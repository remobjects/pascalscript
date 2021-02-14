program Invoke_Testing;

uses
  System.StartUpCopy,
  FMX.Forms,
  Invoke_Testing_unit in 'Invoke_Testing_unit.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
