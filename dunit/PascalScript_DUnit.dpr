program PascalScript_DUnit;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  TestFramework,
  DunitTestRunner,
  {$IFDEF TESTINSIGHT}TestInsight.DUnit,{$ENDIF}
  PascalScriptTests in 'PascalScriptTests.pas';

begin
  RunRegisteredTests;
end.
