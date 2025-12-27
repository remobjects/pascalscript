unit PascalScriptTests;

interface

uses
  System.SysUtils, TestFramework,
  uPSCompiler, uPSComponent, uPSRuntime, uPSUtils;

type
  TPascalScriptTests = class(TTestCase)
  type
    TExecute<T> = function: T of object;
  private
    FScripter: TPSScript;
    procedure OnCompImport(Sender: TObject; x: TPSPascalCompiler);
    procedure OnExecImport(Sender: TObject; se: TPSExec; x:
            TPSRuntimeClassImporter);
    function Execute<T>(aScript: string): T;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Format;
    procedure Test_CreateOleObject;
    procedure Test_BadVariableType;
  end;

implementation

uses
  Winapi.ActiveX,
  uPSC_comobj, uPSR_comobj;

procedure TPascalScriptTests.SetUp;
begin
  inherited;
  FScripter := TPSScript.Create(nil);
  FScripter.OnCompImport := OnCompImport;
  FScripter.OnExecImport := OnExecImport;
end;

function TPascalScriptTests.Execute<T>(aScript: string): T;
begin
  FScripter.Script.Text := aScript;
  FScripter.CompilerOptions := FScripter.CompilerOptions + [icAllowNoBegin, icAllowNoEnd];

  if not FScripter.Compile then begin
    var A: TArray<string>;
    for var i := 0 to FScripter.CompilerMessageCount - 1 do
      A := A + [string(FScripter.CompilerMessages[i].MessageToString)];
    Status(string.Join(sLineBreak, A));
  end;

  var Execute := TExecute<T>(FScripter.GetProcMethod('Execute'));
  Result := Execute;
end;

procedure TPascalScriptTests.OnCompImport(Sender: TObject;
  x: TPSPascalCompiler);
begin
  x.AddDelphiFunction('function Format(const Format: string; const Args: array of const): string');
  SIRegister_ComObj(x);
end;

procedure TPascalScriptTests.OnExecImport(Sender: TObject; se: TPSExec;
  x: TPSRuntimeClassImporter);
begin
  se.RegisterDelphiFunction(@Format, 'Format', cdRegister);
  RIRegister_ComObj(se);
end;

procedure TPascalScriptTests.TearDown;
begin
  FScripter.Free;
  inherited;
end;

procedure TPascalScriptTests.Test_CreateOleObject;
begin
  CoInitialize(nil);
  try
    CheckEquals(
      'True'
    , Execute<string>('''
      function Execute: string;
      var o: Variant;
      begin
        o := CreateOleObject('Schedule.Service.1');
        o.Connect('');
        Result := o.Connected;
      end;
      ''')
      );
  finally
    CoUninitialize;
  end;
end;

procedure TPascalScriptTests.Test_Format;
begin
  CheckEquals(
    'Print Hello World 123456'
  , Execute<string>('''
    function Execute: string;
    begin
      Result := Format('Print %s %d', ['Hello World', 123456]);
    end;
    ''')
  );
end;

procedure TPascalScriptTests.Test_BadVariableType;
begin
  CheckNotEquals(
    ''
  , Execute<string>('''
    function Execute: string;
    var o, F, T: Variant;
        R: string;
    begin
      o := CreateOleObject('Schedule.Service.1');
      o.Connect;

      F := o.GetFolder('\');
      T := F.GetTasks(0);

      R := T.Item[1].NextRunTime;
      Result := R;

      R := T.Item[1].Name;
      Result := Result + #13#10 + R;

      R := T.Item[1].NumberOfMissedRuns;
      Result := Result + #13#10 + R;

      R := T.Item[1].Enabled;
      Result := Result + #13#10 + R;
    end;
    ''')
  );
end;

initialization
  RegisterTest(TPascalScriptTests.Suite);
end.
