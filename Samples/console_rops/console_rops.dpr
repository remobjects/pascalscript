program console_rops;
// Delphi project
{$apptype console}
{$R console_rops.res}
//
// make:
//   D2007
//     make_prj.cmd 11 console_rops.dpr
//   XE3
//     make_prj.cmd 17 console_rops.dpr
//     make_prj.cmd 17w64 console_rops.dpr
//   DX 10.1 Berlin
//     make_prj.cmd 24w32 console_rops.dpr
//     make_prj.cmd 24w64 console_rops.dpr
//
// sample run:
//
//> console_rops.exe sample_hello.rops
//
uses
  SysUtils, Classes, Windows,
  uPSDebugger, uPSComponent, uPSUtils,
  uPSCompiler, uPSRuntime;

{$i console_rops.inc}

const
  Script : string = 'var s: string; begin s := ''Hello script :)''; writeln(S); end.';
var
  ScriptFile: string;
  ErrorLevel: integer;
begin
  //
  // parse params
  //
  if (ParamCount>0) then begin
    if SameText(ExtractFileExt(ParamStr(1)),'.rops') then begin
      ScriptFile := ParamStr(1);
    end else begin
      DoStrWriteLn('');
      DoStrWriteLn('Usage as: console_rops.exe *.rops');
      DoStrWriteLn('');
      if (ScriptFile = '/?') or (ScriptFile = '/?help') or (ScriptFile = '-help') or (ScriptFile = '/?') then
        Exit
      else
        Halt(2);
    end;
  end else begin
    ScriptFile := ExtractFilePath(ParamStr(0)) + PathDelim + 'sample_default.rops';
    if not FileExists(ScriptFile) then
      ScriptFile := '';
  end;
  if ScriptFile <> '' then begin
    ScriptsFolder := ExtractFilePath(ScriptFile);
    if ScriptsFolder = '' then
      ScriptsFolder := GetCurrentDir();
  end else begin
    //--ScriptsFolder := ExtractFilePath(ParamStr(0));
    ScriptsFolder := GetCurrentDir();
  end;
  //
  // go: ...
  //
  ErrorLevel := 1;
  DoStrWriteLn;

  {$IFDEF CPUX64}
  DoStrWriteLn('# CPUX64');
  {$ELSE}
  {$IFDEF CPU64}
  DoStrWriteLn('# CPU64');
  {$ELSE}
  {$IFDEF 32BIT}
  DoStrWriteLn('# 32BIT');
  {$ELSE}
  {.$IFNDEF UNICODE}{$IFNDEF FPC}
  DoStrWriteLn('# X86');
  {$ENDIF}{.$ENDIF}
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}

  DoStrWriteLn('Demo start: file: "' + ExtractFileName(ScriptFile) + '"');
  DoStrWriteLn('-----------');
  try

    ErrorLevel := ExecuteScript(Script, ScriptFile);

    DoStrWriteLn('-----------');

    if ErrorLevel <> 0
    then DoStrWriteLn('Demo failed.')
    else DoStrWriteLn('Demo finish.');
  except
    on e: Exception do
    begin
      DoStrWriteLn;
      DoStrWriteLn('Exception: '+Format('Class: %s; Message: %s',[e.ClassName,e.Message]));
    end;
  end;
  DoStrWriteLn;
  writeln('# errorlevel == '+inttostr(ErrorLevel));
  if ErrorLevel <> 0 then
    Halt(ErrorLevel);
end.
