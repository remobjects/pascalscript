unit uFrmGotoLine;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SynEditTypes;

type
  TfrmGotoLine = class(TForm)
    edtCharNumber: TEdit;
    edtLineNumber: TEdit;
    Button1: TButton;
    btnGoto: TButton;
    lblLineNumber: TLabel;
    lblCharNumber: TLabel;
    procedure FormShow(Sender: TObject);
  private
    function GetCaret: TBufferCoord;
    procedure SetCaret(const Value: TBufferCoord);
    procedure SetChar(const Value: Integer);
    procedure SetLine(const Value: Integer);
    function GetChar: Integer;
    function GetLine: Integer;
    { Private declarations }
  public
    { Public declarations }
    property Char : Integer read GetChar write SetChar;
    property Line : Integer read GetLine write setLine;
    property CaretXY:TBufferCoord read GetCaret write SetCaret;
  end;

var
  frmGotoLine: TfrmGotoLine;

implementation

{$R *.dfm}

{ TfrmGotoLine }

function TfrmGotoLine.GetCaret: TBufferCoord;
begin
  Result.Char := StrToInt(edtCharNumber.Text);
  Result.Line := StrToInt(edtLineNumber.Text);
end;

function TfrmGotoLine.GetChar: Integer;
begin
  Result := StrToInt(edtCharNumber.Text)
end;

function TfrmGotoLine.GetLine: Integer;
begin
  Result := StrToInt(edtLineNumber.Text)
end;

procedure TfrmGotoLine.SetCaret(const Value: TBufferCoord);
begin
  edtCharNumber.Text := IntToStr(Value.Char);
  edtLineNumber.Text := IntToStr(Value.Line);
end;

procedure TfrmGotoLine.SetChar(const Value: Integer);
begin
  edtCharNumber.Text := IntToStr(Value);
end;

procedure TfrmGotoLine.SetLine(const Value: Integer);
begin
  edtLineNumber.Text := IntToStr(Value);
end;

procedure TfrmGotoLine.FormShow(Sender: TObject);
begin
  edtLineNumber.SetFocus;
end;

end.
