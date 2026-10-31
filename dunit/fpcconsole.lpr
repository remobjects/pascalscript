program fpcconsole;
{ Console runner for FreePascal:
    fpc -Mdelphi -Fu../Source -Fi../Source fpcconsole.lpr
    fpc -Mdelphiunicode -dUNICODE -dFPC_UNICODE -Fu../Source -Fi../Source fpcconsole.lpr
    ./fpcconsole --all --format=plain }
{$IFDEF FPC_UNICODE}{$mode delphiunicode}{$ELSE}{$mode delphi}{$ENDIF}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  SysUtils, Classes, consoletestrunner,
  CompilerTestBase, CompilerTestSimple, CompilerTestFunctions, CompileTestExtended,
  CompilerTestSysV;
var
  app: TTestRunner;
begin
  DefaultFormat := fPlain;
  DefaultRunAllTests := True;
  app := TTestRunner.Create(nil);
  app.Initialize;
  app.Title := 'pascalscript';
  app.Run;
  app.Free;
end.
