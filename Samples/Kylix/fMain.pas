unit fMain;

interface

uses
  Classes, QGraphics, QControls, QForms, QDialogs,
  uPSCompiler, uPSRuntime, uPSUtils, QMenus, QTypes, QStdCtrls, QExtCtrls;

type
  TMainForm = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    Splitter1: TSplitter;
    MainMenu1: TMainMenu;
    Toosl1: TMenuItem;
    Compile1: TMenuItem;
    File1: TMenuItem;
    Exit1: TMenuItem;
    N1: TMenuItem;
    SaveAs1: TMenuItem;
    Save1: TMenuItem;
    Open1: TMenuItem;
    New1: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    N2: TMenuItem;
    Stop1: TMenuItem;
    N3: TMenuItem;
    CompileandDisassemble1: TMenuItem;
    procedure Compile1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure New1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Stop1Click(Sender: TObject);
    procedure CompileandDisassemble1Click(Sender: TObject);
  private
    fn: string;
    changed: Boolean;
    function SaveTest: Boolean;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses
  fDwin, uPSDisassembly, uPSC_dll, uPSR_dll;
{$R *.dfm}

function MyOnUses(Sender: TIFPSPascalCompiler; const Name: string): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    TIFPSPascalCompiler(Sender).AddFunction('procedure Writeln(s: string);');
    TIFPSPascalCompiler(Sender).AddFunction('function Readln(question: string): string;');
    Sender.AddConstantN('NaN', 'extended').SetExtended(0.0 / 0.0);
    Sender.AddConstantN('Infinity', 'extended').SetExtended(1.0 / 0.0);
    Sender.AddConstantN('NegInfinity', 'extended').SetExtended(1.0 / 0.0);
    Sender.AddDelphiFunction('function ImportTest(S1: string; s2: Longint; s3: Byte; s4: word; var s5: string): string;');
    Result := True;
  end
  else
  begin
    TIFPSPascalCompiler(Sender).MakeError('', ecUnknownIdentifier, '');
    Result := False;
  end;
end;

function MyWriteln(Caller: TIFPSExec; p: TPSExternalProcRec; Global, Stack: TIFPSStack): Boolean;
begin
  MainForm.Memo2.Lines.Add(Stack.GetString(-1));
  Result := True;
end;

function MyReadln(Caller: TIFPSExec; p: TPSExternalProcRec; Global, Stack: TIFPSStack): Boolean;
begin
  Stack.SetString(-1,InputBox(MainForm.Caption, Stack.GetString(-2), ''));
  Result := True;
end;

function ImportTest(S1: string; s2: Longint; s3: Byte; s4: word; var s5: string): string;
begin
  Result := s1 + ' ' + IntToStr(s2) + ' ' + IntToStr(s3) + ' ' + IntToStr(s4) + ' - OK!';
  S5 := s5 + ' '+ result + ' -   OK2!';
end;

var
  I: Integer;

procedure RunLine(Sender: TIFPSExec);
begin
  i := (i + 1) mod 15;
  if i = 0 then Application.ProcessMessages;
end;

function MyExportCheck(Sender: TIFPSPascalCompiler; Proc: TIFPSInternalProcedure; const ProcDecl: string): Boolean;
begin
  Result := TRue;
end;


procedure TMainForm.Compile1Click(Sender: TObject);
var
  x1: TIFPSPascalCompiler;
  x2: TIFPSExec;
  s: string;

  procedure Outputtxt(const s: string);
  begin
    Memo2.Lines.Add(s);
  end;

  procedure OutputMsgs;
  var
    l: Longint;
    b: Boolean;
  begin
    b := False;
    for l := 0 to x1.MsgCount - 1 do
    begin
      Outputtxt(x1.Msg[l].MessageToString);
      if (not b) and (x1.Msg[l] is TPSPascalCompilerError) then
      begin
        b := True;
        Memo1.SelStart := X1.Msg[l].Pos;
      end;
    end;
  end;
begin
  if tag <> 0 then exit;
  Memo2.Clear;
  x1 := TIFPSPascalCompiler.Create;
  x1.OnExportCheck := MyExportCheck;
  x1.OnUses := MyOnUses;
  x1.OnExternalProc := DllExternalProc;
  if x1.Compile(Memo1.Text) then
  begin
    Outputtxt('Successfully compiled');
    OutputMsgs;
    if not x1.GetOutput(s) then
    begin
      x1.Free;
      Outputtxt('[Error] : Could not get data');
      exit;
    end;
    x1.Free;
    x2 := TIFPSExec.Create;
    RegisterDLLRuntime(x2);
    tag := longint(x2);
    if sender <> nil then
      x2.OnRunLine := RunLine;
    x2.RegisterFunctionName('WRITELN', MyWriteln, nil, nil);
    x2.RegisterFunctionName('READLN', MyReadln, nil, nil);
    x2.RegisterDelphiFunction(@importtest, 'IMPORTTEST', cdRegister);
    if not x2.LoadData(s) then begin
      Outputtxt('[Error] : Could not load data');
      x2.Free;
      exit;
    end;
    x2.RunScript;
    if x2.ExceptionCode <> ENoError then
      Outputtxt('[Runtime Error] : ' + TIFErrorToString(x2.ExceptionCode, x2.ExceptionString) +
        ' in ' + IntToStr(x2.ExceptionProcNo) + ' at ' + IntToSTr(x2.ExceptionPos))
    else
      OutputTxt('Successfully executed');

    tag := 0;
    x2.Free;
  end
  else
  begin
    Outputtxt('Failed when compiling');
    OutputMsgs;
    x1.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := 'RemObjects Pascal Script';
  fn := '';
  changed := False;
  Memo1.Lines.Text := 'Program ROTEST;'#13#10'Begin'#13#10'End.';
end;


procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.New1Click(Sender: TObject);
begin
  if not SaveTest then
    exit;
  Memo1.Lines.Text := 'Program ROTEST;'#13#10'Begin'#13#10'End.';
  Memo2.Lines.Clear;
  fn := '';
end;

function TMainForm.SaveTest: Boolean;
begin
  if changed then
  begin
    case MessageDlg('File is not saved, save now?', mtWarning, mbYesNoCancel, 0) of
      mrYes:
        begin
          Save1Click(nil);
          Result := not changed;
        end;
      mrNo: Result := True;
    else
      Result := False;
    end;
  end
  else
    Result := True;
end;

procedure TMainForm.Open1Click(Sender: TObject);
begin
  if not SaveTest then
    exit;
  if OpenDialog1.Execute then
  begin
    Memo1.Lines.LoadFromFile(OpenDialog1.FileName);
    changed := False;
    Memo2.Lines.Clear;
    fn := OpenDialog1.FileName;
  end;
end;

procedure TMainForm.Save1Click(Sender: TObject);
begin
  if fn = '' then
  begin
    Saveas1Click(nil);
  end
  else
  begin
    Memo1.Lines.SaveToFile(fn);
    changed := False;
  end;
end;

procedure TMainForm.SaveAs1Click(Sender: TObject);
begin
  SaveDialog1.FileName := '';
  if SaveDialog1.Execute then
  begin
    fn := SaveDialog1.FileName;
    Memo1.Lines.SaveToFile(fn);
    changed := False;
  end;
end;

procedure TMainForm.Memo1Change(Sender: TObject);
begin
  changed := True;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := SaveTest;
end;

procedure TMainForm.Stop1Click(Sender: TObject);
begin
  if tag <> 0 then
    TIFPSExec(tag).Stop;
end;

procedure TMainForm.CompileandDisassemble1Click(Sender: TObject);
var
  x1: TIFPSPascalCompiler;
  s, s2: string;

  procedure OutputMsgs;
  var
    l: Longint;
    b: Boolean;
  begin
    b := False;
    for l := 0 to x1.MsgCount - 1 do
    begin
      Memo2.Lines.Add(x1.Msg[l].MessageToString);
      if (not b) and (x1.Msg[l] is TPSPascalCompilerError) then
      begin
        b := True;
        Memo1.SelStart := X1.Msg[l].Pos;
      end;
    end;
  end;
begin
  if tag <> 0 then exit;
  Memo2.Clear;
  x1 := TIFPSPascalCompiler.Create;
  x1.OnExternalProc := DllExternalProc;
  x1.OnUses := MyOnUses;
  if x1.Compile(Memo1.Text) then
  begin
    Memo2.Lines.Add('Successfully compiled');
    OutputMsgs;
    if not x1.GetOutput(s) then
    begin
      x1.Free;
      Memo2.Lines.Add('[Error] : Could not get data');
      exit;
    end;
    x1.Free;
    IFPS3DataToText(s, s2);
    dwin.Memo1.Text := s2;
    dwin.showmodal;
  end
  else
  begin
    Memo2.Lines.Add('Failed when compiling');
    OutputMsgs;
    x1.Free;
  end;
end;

end.
