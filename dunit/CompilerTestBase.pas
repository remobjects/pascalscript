
unit CompilerTestBase;

interface

uses Classes, uPSComponent, uPSCompiler, uPSRuntime, fpcunit, uPSC_std, uPSC_classes,
  uPSR_std, uPSR_classes;
     //TestFramework,
     { Project Units }
     //ifps3,
     //ifpscomp,
     //IFPS3CompExec;

type

    { TCompilerTestBase }

    TCompilerTestBase = class(TTestCase)
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    protected
        last_script : string;
        CompExec: TIFPS3CompExec;
        //Compiler: TIFPSPascalCompiler;
        //Exec: TIFPSExec;
        procedure Compile(script: string);
        procedure CompileRun(Script: string);

        procedure OnCompile(Sender: TPSScript); virtual;
        procedure OnExecute(Sender: TPSScript); virtual;
        procedure OnCompImport(Sender: TObject; x: TIFPSPascalCompiler); virtual;
        procedure OnExecImport(Sender: TObject; se: TIFPSExec; x: TIFPSRuntimeClassImporter); virtual;
    end;

implementation

uses StrUtils, SysUtils, Math,
  Dialogs;//,
    { Project Units }
    //ifpiir_std,
    //ifpii_std,
    //ifpiir_stdctrls,
    //ifpii_stdctrls,
    //ifpiir_forms,
    //ifpii_forms,
    //ifpii_graphics,
    //ifpii_controls,
    //ifpii_classes,
    //ifpiir_graphics,
    //ifpiir_controls,
    //ifpiir_classes;

function MyFormat(const Format: string;
  const Args: array of const): string;
begin
  Result := SysUtils.Format(Format, Args);
end;


{ TCompilerTestBase }

procedure TCompilerTestBase.SetUp;
begin
    inherited;
    CompExec := TIFPS3CompExec.Create(nil);
    CompExec.OnCompile := {$IFDEF FPC}@{$ENDIF}OnCompile;
    CompExec.OnExecute := {$IFDEF FPC}@{$ENDIF}OnExecute;
    CompExec.OnCompImport := {$IFDEF FPC}@{$ENDIF}OnCompImport;
    CompExec.OnExecImport := {$IFDEF FPC}@{$ENDIF}OnExecImport;
end;

procedure TCompilerTestBase.TearDown;
begin
    CompExec.Free;
    //Compiler.Free;
    //Exec.Free;
    inherited;
end;

procedure TCompilerTestBase.CompileRun(Script: string);
var
    ok: boolean;
begin
    last_script := Script;

    Compile(script);

    ok := CompExec.Execute;

    Check(ok, 'Exec Error:' + Script + #13#10 +
            CompExec.ExecErrorToString + ' at ' +
            Inttostr(CompExec.ExecErrorProcNo) + '.' +
            Inttostr(CompExec.ExecErrorByteCodePosition));
end;

procedure TCompilerTestBase.OnCompile(Sender: TPSScript);
begin
  Sender.AddFunction(@MyFormat, 'function Format(const Format: string; const Args: array of const): string;');
end;

procedure TCompilerTestBase.OnCompImport(Sender: TObject; x: TIFPSPascalCompiler);
begin
    SIRegister_Std(x);
    SIRegister_Classes(x, true);
end;

procedure TCompilerTestBase.OnExecImport(Sender: TObject; se: TIFPSExec; x: TIFPSRuntimeClassImporter);
begin
    RIRegister_Std(x);
    RIRegister_Classes(x, True);
end;

procedure TCompilerTestBase.OnExecute(Sender: TPSScript);
begin
    //Sender.SetVarToInstance('SELF', Self);
end;

procedure TCompilerTestBase.Compile(script: string);
var
    OutputMessages: string;
    ok: Boolean;
    i: Longint;
begin

    CompExec.Script.Clear;
    CompExec.Script.Add(Script);

    OutputMessages := '';
    ok := CompExec.Compile;
    if (NOT ok) then
    begin
        //Get Compiler Messages now.
        for i := 0 to CompExec.CompilerMessageCount - 1 do
          OutputMessages := OutputMessages + CompExec.CompilerErrorToStr(i);
    end;
    Check(ok, 'Compiling failed:' + Script + #13#10 + OutputMessages);

end;

end.
