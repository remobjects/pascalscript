program ifps3_DUnit_Auto;
{$APPTYPE CONSOLE}

uses
  TestFramework,
  TextTestRunner,
  CompilerTestBase in 'CompilerTestBase.pas',
  CompilerTestSimple in 'CompilerTestSimple.pas',
  CompilerTestFunctions in 'CompilerTestFunctions.pas',
  CompileTestExtended in 'CompileTestExtended.pas';

exports
  RegisteredTests name 'Test';
  
{$R *.RES}  
begin
  RunRegisteredTests(rxbHaltOnFailures);
end.
