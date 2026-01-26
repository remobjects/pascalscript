unit PascalScriptTests;

interface

uses
  System.SysUtils, TestFramework,
  uPSCompiler, uPSComponent, uPSRuntime, uPSUtils;

type
  TPascalScriptTests = class(TTestCase)
  type
    TPSPluginClass = class of TPSPlugin;
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
    procedure Test_Tag;
  end;

implementation

uses
  uPSC_classes, uPSC_controls, uPSC_stdctrls, uPSComponent_Default,
  uPSR_classes, uPSR_controls, uPSR_stdctrls;

procedure TPascalScriptTests.SetUp;
begin
  inherited;
  FScripter := TPSScript.Create(nil);

  for var c in [TPSImport_Classes] do
    (FScripter.Plugins.Add as TPSPluginItem).Plugin := TPSPluginClass(c).Create(FScripter);

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
  SIRegister_Classes(x, True);
  SIRegister_Controls(x);
  SIRegister_StdCtrls(x);
end;

procedure TPascalScriptTests.OnExecImport(Sender: TObject; se: TPSExec;
  x: TPSRuntimeClassImporter);
begin
  RIRegister_Classes(x, True);
  RIRegister_Controls(x);
  RIRegister_StdCtrls(x);
end;

procedure TPascalScriptTests.TearDown;
begin
  FScripter.Free;
  inherited;
end;

procedure TPascalScriptTests.Test_Tag;
begin
  CheckEquals(
    '100'
  , Execute<string>('''
    var Response: string;

    function Execute: string;
    var B: TButton;
    begin
      B := TButton.Create(nil);
      try
        B.Tag := 100;
        Result := IntToStr(B.Tag);
      finally
        B.Free;
      end;
    end;
    ''')
  );
end;

initialization
  RegisterTest(TPascalScriptTests.Suite);
end.
