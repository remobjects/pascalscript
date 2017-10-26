{ console_rops.inc }

procedure dbg(const L: string); inline;
begin
  {$IFDEF MSWINDOWS}
  OutputDebugString(PChar('dbg:> '+StringReplace(TrimRight(L),#9,#32#32,[rfReplaceAll])));
  {$ELSE}
  writeln('dbg:> '+TrimRight(L),#9,#32#32,[rfReplaceAll]);
  {$ENDIF}
end;

procedure DoStrWriteLn(const L: string = '');
begin
  if IsConsole then
    writeln(L)
  else
    dbg(L);
end;

procedure StrWriteLn(S: string = '');
var
  L: string;
begin
  //--S := TrimRight(S);
  L := FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', Now);
  if Length(S) > 0 then
    L := L + '  #  ' + S
  else
    L := L + '  #';
  DoStrWriteLn(L);
end;

function script_Format(const AFormat: string; const Args: array of const): string;
// x.AddDelphiFunction('function Format( const Format : string; const Args : array of const) : string');
// Sender.Exec.RegisterDelphiFunction(@Format, 'Format', cdRegister);
// or
// Sender.Exec.RegisterDelphiFunction(@script_Format, 'Format', cdRegister);
var
  i, ArgsLen: integer;
  p: pointer;
  s: string;
  //iPos: integer;
  //}
begin
  //Result := '';
  (*
  s := AFormat;
  ArgsLen := Length(Args);
  if ArgsLen > 0 then begin
    i := 0;
    iPos := pos('%s', s);
    while (iPos > 0) and (i < ArgsLen) do begin
      s := stringreplace(s, '%s', string(Args[i].VChar), []);
      inc(i);
      iPos := pos('%s', s);
    end;
  end;
  Result := s;//*)
  //(*
  ArgsLen := Length(Args);
  if ArgsLen = 0{1} then begin
    //Result := Format(AFormat, Args);
    Result := AFormat;
    Exit;
  end;
  //writeln('  #  Length(Args): '+inttostr(ArgsLen));
  for i := 0 to ArgsLen-1 do begin // check memory access
    //case Args[i].VType of
    p := Args[i].VPointer;
    if p = nil then
      dbg('error: args['+string(inttostr(i))+']');
    //s := string(Args[i].VChar);
  end;//}
  s := Format(AFormat, Args);
  Result := s;
  //*)
end;

function script_test_params7(p1: Integer; p2, p3: string; b4: Boolean; d5: Double; ca6: Char; cw7: Char): string;
//  x.AddDelphiFunction('function test_params7(p1: Integer; p2, p3: string; b4: Boolean; d5: Double; ca6: Char; cw7: Char): string');
//  Sender.Exec.RegisterDelphiFunction(@script_test_params7, 'test_params7', cdRegister);
begin
  Result := Format('p1: %d; p2: %s; p3: %s; b4: %d; d5: %f; ca6: %s; cw7: %s',[p1,p2,string(p3),byte(b4),d5,string(ca6),string(cw7)]);
end;

function script_test_openArray7s(args: array of const): string;
//  x.AddDelphiFunction('function test_openArray7s(args: array of const): string');
//  Sender.Exec.RegisterDelphiFunction(@script_test_openArray7s, 'test_openArray7s', cdRegister);
begin
  if Length(args) = 7
  then Result := Format('p1: %s; p2: %s; p2: %s; p4: %s; p5: %s; p6: %s; p7: %s;',args)
  else Result := 'warn: required 7 string parameters';
end;

{$i console_rops_test_fp64.inc} // 64 params

type
  EScriptException = class(Exception);
procedure script_RaiseExceptionMessage(s: string);
// x.AddDelphiFunction('procedure RaiseExceptionMessage(s: string)');
// Sender.Exec.RegisterDelphiFunction(@script_RaiseExceptionMessage, 'RaiseExceptionMessage', cdRegister);
begin
  if s = '' then s := 'Script exception';
  raise EScriptException.Create(s);
end;

var
  ScriptsFolder: string;
type
  TPSExecAccess = class(TPSExec);
  TPSDebugExecAccess = class(TPSDebugExec);
  EScriptRaise = class(EAbort) // Exception
    EClass: ExceptClass;
    ExProc, ExPos: Cardinal;
    eRow, eCol: Cardinal;
    sFn: uPSUtils.tbtString;
    ExParam: uPSUtils.tbtString;
    constructor Create(PSExec: TPSExec); overload;
  end;
  TPSDebugExecRaise = class(TPSDebugExec) // implemented raise
  protected
    procedure ExceptionProc(proc, Position: Cardinal; Ex: TPSError; const s: tbtstring; NewObject: TObject); override;
    //
    function script_ExceptionText(): string;
    procedure script_RaiseCurrentException();
  end;
  {$if not Declared(TPSExceptionHandler)} // uPSRuntime.pas implementaion
  TPSExceptionHandlerHack = class
    CurrProc: TPSInternalProcRec;
    BasePtr, StackSize: Cardinal;
    FinallyOffset, ExceptOffset, Finally2Offset, EndOfBlock: Cardinal;
    ExceptionData: TPSError;
    CurrentExceptionObject: TObject; // !!! required access
    ExceptionParam: tbtString;
  end;
  TPSExceptionHandler = TPSExceptionHandlerHack;
  {$ifend}
constructor EScriptRaise.Create(PSExec: TPSExec);
var
  FExceptionStack: TPSList;
  E: TObject;
var
  DExec: TPSDebugExecAccess;
  ePos: Cardinal;
begin
  EClass := Exception;
  if (TPSExecAccess(PSExec).ExObject is Exception) then begin
    EClass := ExceptClass(Exception(TPSExecAccess(PSExec).ExObject).ClassType);
  end else begin
    FExceptionStack := TPSExecAccess(PSExec).FExceptionStack;
    if FExceptionStack.Count > 0 then begin
      E := TPSExceptionHandler(FExceptionStack[FExceptionStack.Count-1]).CurrentExceptionObject;
      if Assigned(E) and (E is Exception) then begin
        EClass := ExceptClass(E.ClassType);
      end;
    end;
  end;

  ExParam := TPSExecAccess(PSExec).ExParam;
  if PSExec is TPSDebugExec then begin
    DExec := TPSDebugExecAccess(PSExec);
    if DExec.TranslatePositionEx(DExec.ExProc, DExec.ExPos, ePos, eRow, eCol, sFn) then begin
      ExProc := DExec.ExProc;
      ExPos := DExec.ExPos;
    end;
  end;

  inherited Create('internal: raise');
end;
procedure TPSDebugExecRaise.ExceptionProc(proc, Position: Cardinal; Ex: TPSError; const s: tbtstring; NewObject: TObject);
var
  E: EScriptRaise;
  ERaise: Exception;
begin
  if Assigned(NewObject) and (NewObject.ClassType = EScriptRaise) then begin
    try
      E := EScriptRaise(NewObject);
      // restore state:
      FCurrentRow := E.eRow; // for show error pos in "function ExecuteScript"
      FCurrentCol := E.eCol; // for show error pos in "function ExecuteScript"
      FCurrentFile := E.sFn; // for show error pos in "function ExecuteScript"
      //ExProc := E.ExProc;
      //ExPos := E.ExPos;
      //ExParam := E.ExParam;
      // restore state.

      ERaise := E.EClass.Create(string(E.ExParam)); // simple clone exception (no clone extended fields)
      inherited ExceptionProc(E.ExProc, E.ExPos, erException, E.ExParam, {NewObject:}ERaise);
    finally
      NewObject.Free;
    end;
  end
  else
    inherited ExceptionProc(proc, Position, Ex, s, NewObject);
end;
function CompactScriptFileName(const sFile, ScriptsFolder: string): string;
begin
  if (sFile <> '') then begin
    Result := ScriptsFolder + PathDelim;
    if SameText(Result, Copy(sFile, 1, Length(Result))) then begin
      Result := Copy(sFile, Length(Result)+1, Length(sFile));
      Exit;
    end;
  end;
  Result := ExtractFilename(sFile);
end;
function TPSDebugExecRaise.script_ExceptionText(): string;
// x.AddDelphiFunction('function ExceptionText: string');
// Sender.Exec.RegisterDelphiMethod(Self, @TPSDebugExecRaise.script_ExceptionText, 'ExceptionText', ACallType);
var
  DExec: TPSDebugExecAccess;
  eRow, eCol: Cardinal;
  ePos: Cardinal;
  sFn: uPSUtils.tbtString;
var
  ASelf: TPSExec;
begin
  ASelf := Self;
  Result := string(TPSExecAccess(ASelf).ExParam);
  if ASelf is TPSDebugExec then begin
    DExec := TPSDebugExecAccess(ASelf);
    if DExec.TranslatePositionEx(DExec.ExceptionProcNo, DExec.ExceptionPos, ePos, eRow, eCol, sFn) then begin
      Result := Format('Message: "%s"; File: "%s"; Pos: (%d, %d)', [
        {message:}Result,
        {file:}CompactScriptFileName(string(sFn), ScriptsFolder),
        {position:}eRow, eCol]);
      //dbg('ERROR: '+Result);
    end;
  end;
end;
procedure TPSDebugExecRaise.script_RaiseCurrentException();
// x.AddDelphiFunction('procedure raise');
// Sender.Exec.RegisterDelphiMethod(Sender.Exec, @TPSDebugExecRaise.script_RaiseCurrentException, 'raise', cdRegister);
var
  ASelf: TPSExec;
begin
  ASelf := Self;
  if ASelf.ExceptionObject <> nil then begin // ASelf.ExecErrorCode == erException
    ASelf.RaiseCurrentException;
  end else if TPSExecAccess(ASelf).FExceptionStack.Count > 0 then begin
    raise EScriptRaise.Create(ASelf);

    {FExceptionStack := TPSExecAccess(PSExec).FExceptionStack;
    E := TPSExceptionHandler(FExceptionStack[FExceptionStack.Count-1]).ExceptionObject;
    if Assigned(E) then begin
      FExceptionStack.DeleteLast;
      raise E;
    end;}
  end;
end;
procedure PSScript_CompImport(ASelf: TPSScript; Sender: TObject; x: TPSPascalCompiler);
begin
  x.AddDelphiFunction('procedure dbg(const L: string)'); // OutputDebugString
  x.AddDelphiFunction('procedure WriteLn(S: string)');
  x.AddDelphiFunction('function Format( const Format : string; const Args : array of const) : string');
  x.AddDelphiFunction('procedure RaiseExceptionMessage(s: string)');
  x.AddDelphiFunction('function ExceptionText: string');
  x.AddDelphiFunction('procedure raise');

  // asm call tests:
  x.AddDelphiFunction('function test_params7(p1: Integer; p2, p3: string; b4: Boolean; d5: Double; ca6: Char; cw7: Char): string');
  x.AddDelphiFunction('function test_openArray7s(args: array of const): string');
  x.AddDelphiFunction(fp64_decl());
end;
procedure PSScript_Compile(ASelf: TPSScript; Sender: TPSScript);
begin
  Sender.Exec.RegisterDelphiFunction(@dbg, 'dbg', cdRegister);
  Sender.Exec.RegisterDelphiFunction(@StrWriteLn, 'WriteLn', cdRegister);

//  Sender.Exec.RegisterDelphiFunction(@Format, 'Format', cdRegister);
  Sender.Exec.RegisterDelphiFunction(@script_Format, 'Format', cdRegister);

  Sender.Exec.RegisterDelphiFunction(@script_RaiseExceptionMessage, 'RaiseExceptionMessage', cdRegister);
  Sender.Exec.RegisterDelphiMethod(Sender.Exec, @TPSDebugExecRaise.script_ExceptionText, 'ExceptionText', cdRegister);
  Sender.Exec.RegisterDelphiMethod(Sender.Exec, @TPSDebugExecRaise.script_RaiseCurrentException, 'raise', cdRegister);

  // asm call tests:
  Sender.Exec.RegisterDelphiFunction(@script_test_params7, 'test_params7', cdRegister);
  Sender.Exec.RegisterDelphiFunction(@script_test_openArray7s, 'test_openArray7s', cdRegister);
  Sender.Exec.RegisterDelphiFunction(@script_fp64, 'fp64', cdRegister);

//  {$IFDEF VCL}
//  // Application:
//  Sender.AddRegisteredVariable('APPLICATION', 'TApplication');
//  {$ENDIF VCL}
end;
procedure PSScript_Execute(ASelf: TPSScript; Sender: TPSScript);
begin
//  {$IFDEF VCL}
//  // Application:
//  PSScript.SetVarToInstance('APPLICATION', Application);
//  {$ENDIF VCL}
end;
function PSScript_NeedFile(ASelf: TPSScript; Sender: TObject; const OrginFileName: tbtString;
  var FileName, Output: tbtString): Boolean;
//for include file like: {$i sub\sub_1.inc}
var
  i: Integer;
  sFileName, sPath, sFileSource: string;
  sCode: tbtString;
  OK: Boolean;
begin
  Result := False;
  OK := False;

  sFileName := string(FileName);

  i := Length(OrginFileName);
  if i > 0 then begin
    sPath := string(OrginFileName);
    sPath := ExtractFilePath(sPath);
    i := Length(sPath);
    {$IFDEF MSWINDOWS} // name like: {$i sub\sub_1.inc}
    if (i>2) then begin
      if (sPath[2] <> ':')
        or (
          (sPath[1] <> '\') and (sPath[2] <> '\')
        )
      then
        i := 0;
    end;
    {$ENDIF MSWINDOWS}
    if (i>0) then begin
      if (sPath[i]=PathDelim) then begin
        SetLength(sPath, i-1);
        dec(i);
      end;
      if (i>0) then begin
        if sPath = PathDelim then
          sPath := '';
        sFileSource := sPath + PathDelim + sFileName;
        OK := FileExists(sFileSource);
      end;
    end else begin
      if ScriptsFolder <> ''
      then sFileSource := ScriptsFolder + PathDelim + sFileName
      else sFileSource := sFileName;
      OK := FileExists(sFileSource);
    end;
  end;
  //
  if OK then begin
    with TStringList.Create do
    try
      try
        LoadFromFile(sFileSource);
        sCode := tbtString(Text);
        Result := True;
      except
      end;
    finally
      Free;
    end;
    if Result then begin
      Output := sCode;
      FileName := tbtString(sFileSource);
    end;
  end;
end;
procedure PSExec_OnException(Sender: TPSExec; ExError: TPSError; const ExParam: tbtstring; ExObject: TObject; ProcNo, Position: Cardinal);
// for traccig all exceptions
var
  DExec: TPSDebugExecAccess;
  //PSScript: TPSScript; //@dbg
  ScriptFile, sMessage: string;
  eRow, eCol: Cardinal;
  //ePos: Cardinal;
  //sFn: uPSUtils.tbtString;
begin
  if (ExError <> eNoError) and Assigned(Sender) and (Length(ExParam) > 0) then begin
    if Assigned(ExObject) and (ExObject.ClassType = EScriptRaise) then Exit;
    //PSScript := TPSScript(Sender.Id); //@dbg
    DExec := TPSDebugExecAccess(Sender as TPSDebugExec);
    eRow := DExec.FCurrentRow;
    if eRow > 0 then begin
      eCol := DExec.FCurrentCol;
      ScriptFile := CompactScriptFileName(string(DExec.FCurrentFile), ScriptsFolder);
    //if DExec.TranslatePositionEx(ProcNo, Position, ePos, eRow, eCol, sFn) then begin ScriptFile := CompactScriptFileName(string(sFn), ScriptsFolder);
      sMessage := TrimRight(string(ExParam));
      sMessage := Format('Message: "%s"; File: "%s"; Pos: (%d, %d)', [sMessage, ScriptFile, eRow, eCol]);
      //DoStrWriteLn('ERROR: '+sMessage);{}
      dbg('ERROR: '+sMessage);
    end;
  end;
end;
function MakeMethod(Code, Data: Pointer): TMethod; inline;
begin
  Result.Code := Code;
  Result.Data := Data;
end;
  {$if not Declared(PSDebugExecClass)} // uPSCompomnent.pas
    {$ifdef FPC}{$notes off}{$endif}
    {$hints off}
    type
      TPSScriptHack = class(TComponent)
      private
        FOnGetNotificationVariant: TPSOnGetNotVariant;
        FOnSetNotificationVariant: TPSOnSetNotVariant;
        FCanAdd: Boolean;
        FComp: TPSPascalCompiler;
        FCompOptions: TPSCompOptions;
        FExec: TPSDebugExec; // !!! Need access to it field !!!
      end;
    {$ifdef FPC}{$notes on}{$endif}
    {$hints on}
  {$ifend}
function ExecuteScript(ScriptText: string; ScriptFile: string = '';
  TraceAllExceptions: Boolean = {$IFDEF  DEBUG}True{$ELSE}False{$ENDIF}): integer;
var
  Compiler: TPSPascalCompiler;
  OK: Boolean;
  i: integer;
  sMessage: string;
  Exec: TPSDebugExec;
  DExec: TPSDebugExecAccess absolute Exec;
  {$if not Declared(PSDebugExecClass)} // uPSCompomnent.pas
  ExecNew: TPSDebugExec;
  {$ifend}
  PSScript: TPSScript;
  eRow, eCol: Cardinal;
  //ePos: Cardinal;
  //sFn: uPSUtils.tbtString;
begin
  Result := 1; // == %errorlevel%

  {$if Declared(PSDebugExecClass)} // uPSCompomnent.pas
    PSDebugExecClass := TPSDebugExecRaise; // implemented raise
  {$ifend}

  PSScript := TPSScript.Create(nil);
  try
    PSScript.CompilerOptions := [icAllowNoBegin, icAllowUnit, icAllowNoEnd]; // TPSCompOptions = set of (icAllowNoBegin, icAllowUnit, icAllowNoEnd, icBooleanShortCircuit);
    PSScript.UsePreProcessor := True;
    PSScript.OnCompImport := TPSOnCompImportEvent(MakeMethod(@PSScript_CompImport, PSScript));
    PSScript.OnCompile := TPSEvent(MakeMethod(@PSScript_Compile, PSScript));
    PSScript.OnExecute := TPSEvent(MakeMethod(@PSScript_Execute, PSScript));
    PSScript.OnNeedFile := TPSOnNeedFile(MakeMethod(@PSScript_NeedFile, PSScript)); // for include directive: {$i %includ-file%}

    Compiler := PSScript.Comp; // get an instance of the compiler.
    Exec := PSScript.Exec; // get an instance of the executer.

    {$if not Declared(PSDebugExecClass)} // uPSCompomnent.pas
    //HACK: emulation of implementation "raise"
    if TPSScriptHack(Pointer(PSScript)).FExec = Exec then // Check fild offet equal for TPSScriptHack and TPSScript
    begin // replañe "PSScript.FExec:TPSDebugExec" to "...TPSDebugExecRaise"
      ExecNew := TPSDebugExecRaise.Create;
      TPSScriptHack(Pointer(PSScript)).FExec := ExecNew;
      begin // ExecNew.Assign(Exec) :
        ExecNew.Id := Exec.Id;
        ExecNew.OnRunLine:= Exec.OnRunLine;
        ExecNew.OnGetNVariant := Exec.OnGetNVariant;
        ExecNew.OnSetNVariant := Exec.OnSetNVariant;
      end;
      Exec.Free;
      Exec := ExecNew; // get an instance of the executer.
      ExecNew := nil;
    end else begin
      dbg('warn: not implemented "raise"');
    end;
    //HACK.
    {$ifend}

    if ScriptFile <> '' then begin
      PSScript.Script.LoadFromFile(ScriptFile);
      PSScript.MainFileName := tbtString(ExtractFileName(ScriptFile));
    end else begin
      PSScript.Script.Text := ScriptText;
      PSScript.MainFileName := tbtString('<memory>');
    end;

    StrWriteLn;
    StrWriteLn('#rps:> Compilation:');
    OK := PSScript.Compile; // Compile the script.
    if not OK then
      StrWriteLn('#rps:> Failed compilation:');
    i := PSScript.CompilerMessageCount;
    if i > 0 then begin
      StrWriteLn('#rps:>   Messages:');
      for i := 0 to i -1 do begin
        sMessage := string(Compiler.Msg[i].MessageToString);
        StrWriteLn('#rps:>     '+TrimRight(sMessage));
      end;
    end;
    StrWriteLn('#rps:> Compilation.');
    StrWriteLn;

    if not OK then  // Compile the Pascal script into bytecode.
    begin
      // You could raise an exception here.
      Exit;
    end;

    if TraceAllExceptions then
      Exec.OnException := @PSExec_OnException; // for traccing all exceptions

    try
      OK := PSScript.Execute; // Run the script.
      if OK then
        Result := 0 // == %errorlevel%
      else begin  //@dbg: TPSExecAccess(DExec).FExceptionStack.Count

        {if (Exec.ExceptionObject <> nil) and (Exec.ExceptionObject.ClassType = EScriptRaise) then begin
          sMessage := string(EScriptRaise(Exec.ExceptionObject).ExParam);
          raise EScriptRaise(Exec.ExceptionObject).EClass.Create(sMessage);
        end;}

        //
        // Calculate script error pos:
        //
        eRow := DExec.FCurrentRow;
        if eRow > 0 then begin
          eCol := DExec.FCurrentCol;
          ScriptFile := CompactScriptFileName(string(DExec.FCurrentFile), ScriptsFolder);
        //if Exec.TranslatePositionEx(Exec.ExceptionProcNo, Exec.ExceptionPos, ePos, eRow, eCol, sFn) then begin ScriptFile := CompactScriptFileName(string(sFn), ScriptsFolder);
          sMessage := TrimRight(string(Exec.ExceptionString));
          sMessage := Format('Message: "%s"; File: "%s"; Pos: (%d, %d)', [sMessage, ScriptFile, eRow, eCol]);
          DoStrWriteLn('ERROR: '+sMessage);{}
        end;
        //
        // Calculate script error pos.
        //
        OK := True;
        if Exec.ExceptionObject <> nil then begin // PSScript.ExecErrorCode == erException //@dbg: Exception(Exec.ExceptionObject)
          Exec.RaiseCurrentException;
        end else begin
          raise Exception.Create('failed script exec');
        end;
      end;
    except
      on e: Exception do begin
        if not OK then begin
          eRow := DExec.FCurrentRow;
          if eRow > 0 then begin
            eCol := DExec.FCurrentCol;
            ScriptFile := CompactScriptFileName(string(DExec.FCurrentFile), ScriptsFolder);
          //if Exec.TranslatePositionEx(Exec.ExceptionProcNo, Exec.ExceptionPos, ePos, eRow, eCol, sFn) then begin ScriptFile := CompactScriptFileName(string(sFn), ScriptsFolder);
            sMessage := TrimRight(e.Message);
            sMessage := Format('Message: "%s"; File: "%s"; Pos: (%d, %d)', [sMessage, ScriptFile, eRow, eCol]);
            DoStrWriteLn('ERROR: '+sMessage);{}
            //e.Messsage := sMessage;
          end;
        end;
        raise;
      end;
    end;
  finally
    try
      PSScript.Destroy; // TODO: FPC: OpenArray fail (AV). Sample script: "begin format('%s; %s',['2','2']); end."
    except
      on e: Exception do begin
        sMessage := 'Exception(internal): '+Format('Class: %s; Message: %s',[e.ClassName,e.Message]);
        dbg(sMessage);
        DoStrWriteLn(sMessage);
      end;
    end;
  end;
end;
