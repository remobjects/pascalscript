unit fDwin;

interface

uses
  SysUtils, Classes, QGraphics, QControls, QForms, QDialogs, QStdCtrls,
  QExtCtrls;

type
  Tdwin = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dwin: Tdwin;

implementation

{$R *.dfm}

end.
