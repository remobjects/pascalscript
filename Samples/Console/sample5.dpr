program sample5;

uses
  uPSCompiler,
  uPSRuntime,
  uPSC_std,
  uPSC_controls,
  uPSC_stdctrls,
  uPSC_forms,
  uPSR_std,
  uPSR_controls,
  uPSR_stdctrls,
  uPSR_forms,
  forms

  ;

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
    SIRegister_Std(Sender);
    { This will register the declarations of these classes:
      TObject, TPersisent. This can be found
      in the uPSC_std.pas unit. }
    SIRegister_Controls(Sender);
    { This will register the declarations of these classes:
      TControl, TWinControl, TFont, TStrings, TStringList, TGraphicControl. This can be found
      in the uPSC_controls.pas unit. }

    SIRegister_Forms(Sender);
    { This will register: TScrollingWinControl, TCustomForm, TForm and TApplication. uPSC_forms.pas unit. }

    SIRegister_stdctrls(Sender);
     { This will register: TButtonContol, TButton, TCustomCheckbox, TCheckBox, TCustomEdit, TEdit, TCustomMemo, TMemo,
      TCustomLabel and TLabel. Can be found in the uPSC_stdctrls.pas unit. }

    AddImportedClassVariable(Sender, 'Application', 'TApplication');
    // Registers the application variable to the script engine.

    Result := True;
  end else
    Result := False;
end;

procedure ExecuteScript(const Script: string);
var
  Compiler: TPSPascalCompiler;
  { TPSPascalCompiler is the compiler part of the scriptengine. This will 
    translate a Pascal script into a compiled form the executer understands. } 
  Exec: TPSExec;
   { TPSExec is the executer part of the scriptengine. It uses the output of
    the compiler to run a script. }
  {$IFDEF UNICODE}Data: AnsiString;{$ELSE}Data: string;{$ENDIF}
  CI: TPSRuntimeClassImporter; 
begin
  Compiler := TPSPascalCompiler.Create; // create an instance of the compiler.
  Compiler.OnUses := ScriptOnUses; // assign the OnUses event.
  if not Compiler.Compile(Script) then  // Compile the Pascal script into bytecode.
  begin
    Compiler.Free;
     // You could raise an exception here.
    Exit;
  end;

  Compiler.GetOutput(Data); // Save the output of the compiler in the string Data.
  Compiler.Free; // After compiling the script, there is no need for the compiler anymore.

  CI := TPSRuntimeClassImporter.Create;
  { Create an instance of the runtime class importer.}
  
  RIRegister_Std(CI);  // uPSR_std.pas unit.
  RIRegister_Controls(CI); // uPSR_controls.pas unti.
  RIRegister_stdctrls(CI);  // uPSR_stdctrls.pas unit.
  RIRegister_Forms(CI);  // uPSR_forms.pas unit.

  Exec := TPSExec.Create;  // Create an instance of the executer.

  RegisterClassLibraryRuntime(Exec, CI);
  // Assign the runtime class importer to the executer.
  
  if not  Exec.LoadData(Data) then // Load the data from the Data string.
  begin
    { For some reason the script could not be loaded. This is usually the case when a
      library that has been used at compile time isn't registered at runtime. }
    Exec.Free;
     // You could raise an exception here.
    Exit;
  end;

  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('APPLICATION')), Application);
   // This will set the script's Application variable to the real Application variable.

  Exec.RunScript; // Run the script.
  Exec.Free; // Free the executer.
  CI.Free;  // Free the runtime class importer. 
end;




const
  Script =
    'var f: TForm; i: Longint; begin f := TForm.CreateNew(f, 0); f.Show; while f.Visible do Application.ProcessMessages; F.free;  end.';

begin
  ExecuteScript(Script);
end.
