unit fMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, uPSCompiler, uPSRuntime, uPSDisassembly, uPSPreprocessor, uPSUtils,
  Menus, uPSC_comobj, uPSR_comobj;

type
  TMainForm = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    Splitter1: TSplitter;
    MainMenu1: TMainMenu;
    Toosl1: TMenuItem;
    Compile1: TMenuItem;
    CompilewithTimer1: TMenuItem;
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
    procedure CompilewithTimer1Click(Sender: TObject);
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
  uPSC_dll, uPSR_dll, uPSDebugger,
  uPSR_std, uPSC_std, uPSR_stdctrls, uPSC_stdctrls,
  uPSR_forms, uPSC_forms,

  uPSC_graphics,
  uPSC_controls,
  uPSC_classes,
  uPSR_graphics,
  uPSR_controls,
  uPSR_classes,
  fDwin;

{$R *.DFM}

var
  Imp: TPSRuntimeClassImporter;

function StringLoadFile(const Filename: string): string;
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(Filename, fmOpenread or fmSharedenywrite);
  try
    SetLength(Result, Stream.Size);
    Stream.Read(Result[1], Length(Result));
  finally
    Stream.Free;
  end;
end;

function OnNeedFile(Sender: TPSPreProcessor; const callingfilename: AnsiString; var FileName, Output: AnsiString): Boolean;
var
  s: string;
begin
  s := ExtractFilePath(callingfilename);
  if s = '' then s := ExtractFilePath(Paramstr(0));
  Filename := s + Filename;
  if FileExists(Filename) then
  begin
    Output := StringLoadFile(Filename);
    Result := True;
  end else
    Result := False;
end;

function MyOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    TPSPascalCompiler(Sender).AddFunction('procedure Writeln(s: string);');
    TPSPascalCompiler(Sender).AddFunction('function Readln(question: string): string;');
    Sender.AddDelphiFunction('function ImportTest(S1: string; s2: Longint; s3: Byte; s4: word; var s5: string): string;');

    Sender.AddConstantN('NaN', 'extended').Value.textended := 0.0 / 0.0;
    Sender.AddConstantN('Infinity', 'extended').Value.textended := 1.0 / 0.0;
    Sender.AddConstantN('NegInfinity', 'extended').Value.textended := - 1.0 / 0.0;

    SIRegister_Std(Sender);
    SIRegister_Classes(Sender, True);
    SIRegister_Graphics(Sender, True);
    SIRegister_Controls(Sender);
    SIRegister_stdctrls(Sender);
    SIRegister_Forms(Sender);
    SIRegister_ComObj(Sender);

    AddImportedClassVariable(Sender, 'Memo1', 'TMemo');
    AddImportedClassVariable(Sender, 'Memo2', 'TMemo');
    AddImportedClassVariable(Sender, 'Self', 'TForm');
    AddImportedClassVariable(Sender, 'Application', 'TApplication');

    Result := True;
  end
  else
  begin
    TPSPascalCompiler(Sender).MakeError('', ecUnknownIdentifier, '');
    Result := False;
  end;
end;

function MyWriteln(Caller: TPSExec; p: TIFExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  PStart: Cardinal;
begin
  if Global = nil then begin result := false; exit; end;
  PStart := Stack.Count - 1;
  MainForm.Memo2.Lines.Add(Stack.GetString(PStart));
  Result := True;
end;

function MyReadln(Caller: TPSExec; p: TIFExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  PStart: Cardinal;
begin
  if Global = nil then begin result := false; exit; end;
  PStart := Stack.Count - 2;
  Stack.SetString(PStart + 1, InputBox(MainForm.Caption, Stack.GetString(PStart), ''));
  Result := True;
end;

function ImportTest(S1: string; s2: Longint; s3: Byte; s4: word; var s5: string): string;
begin
  Result := s1 + ' ' + IntToStr(s2) + ' ' + IntToStr(s3) + ' ' + IntToStr(s4) + ' - OK!';
  S5 := s5 + ' '+ result + ' -   OK2!';
end;

var
  IgnoreRunline: Boolean = False;
  I: Integer;

procedure RunLine(Sender: TPSExec);
begin
  if IgnoreRunline then Exit;
  i := (i + 1) mod 15;
  Sender.GetVar('');
  if i = 0 then Application.ProcessMessages;
end;

function MyExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;
begin
  Result := True;
end;


procedure TMainForm.Compile1Click(Sender: TObject);
var
  x1: TPSPascalCompiler;
  x2: TPSDebugExec;
  xpre: TPSPreProcessor;
  s, d: AnsiString;

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
  xpre := TPSPreProcessor.Create;
  try
    xpre.OnNeedFile := OnNeedFile;
    xpre.MainFileName := fn;
    xpre.MainFile := Memo1.Text;
    xpre.PreProcess(xpre.MainFileName, s);

    x1 := TPSPascalCompiler.Create;
    x1.OnExportCheck := MyExportCheck;
    x1.OnUses := MyOnUses;
    x1.OnExternalProc := DllExternalProc;
    x1.AllowNoEnd := true;
    if x1.Compile(s) then
    begin
      Outputtxt('Successfully compiled');
      xpre.AdjustMessages(x1);
      OutputMsgs;
      if not x1.GetOutput(s) then
      begin
        x1.Free;
        Outputtxt('[Error] : Could not get data');
        exit;
      end;
      x1.GetDebugOutput(d);
      x1.Free;
      x2 := TPSDebugExec.Create;
      try
        RegisterDLLRuntime(x2);
        RegisterClassLibraryRuntime(x2, Imp);
        RIRegister_ComObj(x2);

        tag := longint(x2);
        if sender <> nil then
          x2.OnRunLine := RunLine;
        x2.RegisterFunctionName('WRITELN', MyWriteln, nil, nil);
        x2.RegisterFunctionName('READLN', MyReadln, nil, nil);
        x2.RegisterDelphiFunction(@ImportTest, 'IMPORTTEST', cdRegister);
        if not x2.LoadData(s) then
        begin
          Outputtxt('[Error] : Could not load data: '+TIFErrorToString(x2.ExceptionCode, x2.ExceptionString));
          tag := 0;
          exit;
        end;
        x2.LoadDebugData(d);
        SetVariantToClass(x2.GetVarNo(x2.GetVar('MEMO1')), Memo1);
        SetVariantToClass(x2.GetVarNo(x2.GetVar('MEMO2')), Memo2);
        SetVariantToClass(x2.GetVarNo(x2.GetVar('SELF')), Self);
        SetVariantToClass(x2.GetVarNo(x2.GetVar('APPLICATION')), Application);

        x2.RunScript;
        if x2.ExceptionCode <> erNoError then
          Outputtxt('[Runtime Error] : ' + TIFErrorToString(x2.ExceptionCode, x2.ExceptionString) +
            ' in ' + IntToStr(x2.ExceptionProcNo) + ' at ' + IntToSTr(x2.ExceptionPos))
        else
          OutputTxt('Successfully executed');
      finally
        tag := 0;
        x2.Free;
      end;
    end
    else
    begin
      Outputtxt('Failed when compiling');
      xpre.AdjustMessages(x1);
      OutputMsgs;
      x1.Free;
    end;
  finally
    Xpre.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := 'RemObjects Pascal Script';
  fn := '';
  changed := False;
  Memo1.Lines.Text := 'Program Test;'#13#10'Begin'#13#10'End.';
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.New1Click(Sender: TObject);
begin
  if not SaveTest then
    exit;
  Memo1.Lines.Text := 'Program Test;'#13#10'Begin'#13#10'End.';
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
    TPSExec(tag).Stop;
end;

procedure TMainForm.CompileandDisassemble1Click(Sender: TObject);
var
  x1: TPSPascalCompiler;
  xpre: TPSPreProcessor;
  s: AnsiString;
  s2: string;

  procedure OutputMsgs;
  var
    l: Integer;
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
  xpre := TPSPreProcessor.Create;
  try
    xpre.OnNeedFile := OnNeedFile;
    xpre.MainFileName := fn;
    xpre.MainFile := Memo1.Text;
    xpre.PreProcess(xpre.MainFileName, s);
    x1 := TPSPascalCompiler.Create;
    x1.OnExternalProc := DllExternalProc;
    x1.OnUses := MyOnUses;
    if x1.Compile(s) then
    begin
      Memo2.Lines.Add('Successfully compiled');
      xpre.AdjustMessages(x1);
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
      xpre.AdjustMessages(x1);
      OutputMsgs;
      x1.Free;
    end;
  finally
    xPre.Free;
  end;
end;


procedure TMainForm.CompilewithTimer1Click(Sender: TObject);
var
  Freq, Time1, Time2: Comp;
begin
  if not QueryPerformanceFrequency(TLargeInteger((@Freq)^)) then
  begin
    ShowMessage('Your computer does not support Performance Timers!');
    exit;
  end;
  QueryPerformanceCounter(TLargeInteger((@Time1)^));
  IgnoreRunline := True;
  try
    Compile1Click(nil);
  except
  end;
  IgnoreRunline := False;
  QueryPerformanceCounter(TLargeInteger((@Time2)^));
  Memo2.Lines.Add('Time: ' + Sysutils.FloatToStr((Time2 - Time1) / Freq) +
    ' sec');
end;

initialization
  Imp := TPSRuntimeClassImporter.Create;
  RIRegister_Std(Imp);
  RIRegister_Classes(Imp, True);
  RIRegister_Graphics(Imp, True);
  RIRegister_Controls(Imp);
  RIRegister_stdctrls(imp);
  RIRegister_Forms(Imp);
finalization
  Imp.Free;
end.
