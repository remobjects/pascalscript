unit FormSettings;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TfrmSettings = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    edtOutPutDir: TEdit;
    cbUseUnitAtCompileTime: TCheckBox;
    btnOutPutDir: TButton;
    cbCreateOneImportfile: TCheckBox;
    Bevel1: TBevel;
    Default: TCheckBox;
    edtPrefix: TEdit;
    Label2: TLabel;
    procedure btnOutPutDirClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSettings: TfrmSettings;

implementation

uses FileCtrl;

{$R *.DFM}

procedure TfrmSettings.btnOutPutDirClick(Sender: TObject);
var
  dir : String;
begin
  Dir := edtOutPutDir.Text;
  if SelectDirectory(Dir, [sdAllowCreate, sdPerformCreate, sdPrompt], 0) then
                     edtOutPutDir.Text := Dir;
end;

end.
