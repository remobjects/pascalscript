unit ide_debugoutput;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  Tdebugoutput = class(TForm)
    output: TMemo;
  private
  public
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  debugoutput: Tdebugoutput;

implementation

{$R *.dfm}

{ Tdebugoutput }

procedure Tdebugoutput.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle  := Params.ExStyle or WS_EX_APPWINDOW;
end;

end.
