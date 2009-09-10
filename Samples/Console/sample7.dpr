program sample7;

uses
  uPSCompiler,
  uPSRuntime,
  uPSUtils,

  Dialogs

  ;

procedure MyOwnFunction(const Data: string);
begin
  // Do something with Data
  ShowMessage(Data);
end;

{$IFDEF UNICODE}
function ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;
{$ELSE}
function ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: string): Boolean;
{$ENDIF}
{
  The OnExportCheck callback function is called for each function in the script
  (Also for the main proc, with '!MAIN' as a Proc^.Name). ProcDecl contains the
  result type and parameter types of a function using this format:
  ProcDecl: ResultType + ' ' + Parameter1 + ' ' + Parameter2 + ' '+Parameter3 + .....
  Parameter: ParameterType+TypeName
  ParameterType is @ for a normal parameter and ! for a var parameter.
  A result type of 0 means no result.
}
begin
  if Proc.Name = 'TEST' then // Check if the proc is the Test proc we want.
  begin
    if ProcDecl <> '0 @TSTRINGARRAY' then // Check if the proc has the correct params.
    begin
      { Something is wrong, so cause an error. }
      Sender.MakeError('', ecTypeMismatch, '');
      Result := False;
      Exit;
    end;
    { Export the proc; This is needed because PS doesn't store the name of a
      function by default }
    Result := True;
  end else Result := True;
end;

{$IFDEF UNICODE}
function ScriptOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
{$ELSE}
function ScriptOnUses(Sender: TPSPascalCompiler; const Name: string): Boolean;
{$ENDIF}
{ the OnUses callback function is called for each "uses" in the script.
  It's always called with the parameter 'SYSTEM' at the top of the script. 
  For example: uses ii1, ii2;
  This will call this function 3 times. First with 'SYSTEM' then 'II1' and then 'II2'.
}
begin
  if Name = 'SYSTEM' then
  begin

    Sender.AddDelphiFunction('procedure MyOwnFunction(Data: string)');
    { This will register the function to the script engine. Now it can be used from within the script. }

    Sender.AddTypeS('TSTRINGARRAY', 'array of string').ExportName := True;
    { Add the type to the script engine (and export it) }

    Result := True;
  end else
    Result := False;
end;

type
  TStringArr = array[0..1] of string;

procedure ExecuteScript(const Script: string);
var
  Compiler: TPSPascalCompiler;
  { TPSPascalCompiler is the compiler part of the scriptengine. This will
    translate a Pascal script into a compiled form the executer understands. }
  Exec: TPSExec;
   { TPSExec is the executer part of the scriptengine. It uses the output of
    the compiler to run a script. }
  {$IFDEF UNICODE}Data: AnsiString;{$ELSE}Data: string;{$ENDIF}

  N: PIfVariant;
  { The variant in which we are going to store the parameter }
  ParamList: TIfList;
  { The parameter list}
begin
  Compiler := TPSPascalCompiler.Create; // create an instance of the compiler.
  Compiler.OnUses := ScriptOnUses; // assign the OnUses event.

  Compiler.OnExportCheck := ScriptOnExportCheck; // Assign the onExportCheck event.

  if not Compiler.Compile(Script) then  // Compile the Pascal script into bytecode.
  begin
    Compiler.Free;
     // You could raise an exception here.
    Exit;
  end;

  Compiler.GetOutput(Data); // Save the output of the compiler in the string Data.
  Compiler.Free; // After compiling the script, there is no need for the compiler anymore.

  Exec := TPSExec.Create;  // Create an instance of the executer.

  Exec.RegisterDelphiFunction(@MyOwnFunction, 'MYOWNFUNCTION', cdRegister);

  if not Exec.LoadData(Data) then // Load the data from the Data string.
  begin
    { For some reason the script could not be loaded. This is usually the case when a 
      library that has been used at compile time isn't registered at runtime. }
    Exec.Free;
     // You could raise an exception here.
    Exit;
  end;

  ParamList := TIfList.Create; // Create the parameter list

  n := CreateHeapVariant(Exec.GetTypeNo(Exec.GetType('TSTRINGARRAY')));
  { Create a variant for the array parameter }
  if n = nil then
  begin
    { Something is wrong. Exit here }
    ParamList.Free;
    Exec.Free;
    Exit;
  end;

  PSDynArraySetLength(PPSVariantDynamicArray(n).Data, PPSVariantDynamicArray(n).VI.FType, 2); // Put two items in the array
  TStringArr(PPSVariantDynamicArray(n).Data^)[0] := 'First item';
  TStringArr(PPSVariantDynamicArray(n).Data^)[1] := 'Second item';
  // Put something in the string parameter.

  ParamList.Add(n); // Add it to the parameter list.

  Exec.RunProc(ParamList, Exec.GetProc('TEST'));
  { This will call the test proc that was exported before }

  FreePIFVariantList(ParamList); // Cleanup the parameters (This will also free N)

  Exec.Free; // Free the executer.
end;



const
  Script = 'procedure test(s: tstringarray); var i: Longint; begin for i := 0 to GetArrayLength(S) -1 do MyOwnFunction(''Test is called: ''+s[i]);end; begin end.';

begin
  ExecuteScript(Script);
end.
