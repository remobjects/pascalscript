program ifps3_DUnit;

uses
  Forms,
  TestFramework,
  GUITestRunner,
  CompilerTestBase in 'CompilerTestBase.pas',
  CompilerTestSimple in 'CompilerTestSimple.pas',
  CompilerTestFunctions in 'CompilerTestFunctions.pas',
  CompileTestExtended in 'CompileTestExtended.pas';

{$R *.res}

var
    AGUITestRunner: TGUITestRunner;
begin
    Application.Initialize;
    Application.CreateForm(TGUITestRunner, AGUITestRunner);
  AGUITestRunner.Suite := RegisteredTests;
    Application.Run;
end.
