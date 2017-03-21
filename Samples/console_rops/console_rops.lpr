program console_rops;
// Lazarus project
//
// sample run:
//
//> console_rops.exe sample_hello.rops
//
{$mode objfpc}{$H+}
{$R *.res}
uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,
  { you can add units after this }
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  uPSDebugger, uPSComponent, uPSUtils, uPSCompiler, uPSRuntime;

{$i console_rops.inc}

type

  { TConsoleROPS }

  TConsoleROPS = class(TCustomApplication)
  protected
    ErrorLevel: integer;

    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TConsoleROPS }

procedure TConsoleROPS.DoRun;
const
  Script : string = 'var s: string; begin s := ''Hello script :)''; writeln(S); end.';
var
  ScriptFile: string;
begin
  { add your program here }

  ErrorLevel := 1;

  //
  // parse params
  //
  if (ParamCount>0) then begin
    // quick check parameters
    if SameText(ExtractFileExt(ParamStr(1)),'.rops') then begin
      ScriptFile := ParamStr(1);
    end else begin
      WriteHelp();
      if HasOption('h', 'help') then begin
        ErrorLevel := 0;
      end
      else
        ErrorLevel := 2;
      Terminate;
      Exit;
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
  {$IFDEF WIN32}
  DoStrWriteLn('# WIN32');
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}

  DoStrWriteLn('Demo start: file: "' + ExtractFileName(ScriptFile) + '"' );
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
//  if ErrorLevel <> 0 then
//    Halt(ErrorLevel);

  // stop program loop
  Terminate;
end;

constructor TConsoleROPS.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TConsoleROPS.Destroy;
begin
  inherited Destroy;
end;

procedure TConsoleROPS.WriteHelp;
begin
  { add your help code here }
  //writeln('Usage: ', ExeName, ' -h');
  DoStrWriteLn('');
  DoStrWriteLn('Usage as: console_rops.exe *.rops');
  DoStrWriteLn('');
end;

var
  Application: TConsoleROPS;

var
  ErrorLevel: integer;
begin
  Application:=TConsoleROPS.Create(nil);
  Application.Title:='Console ROPS';
  Application.Run;
  ErrorLevel := Application.ErrorLevel;
  writeln('# errorlevel == '+inttostr(ErrorLevel));
  Application.Free;
  if ErrorLevel <> 0 then
    Halt(ErrorLevel);
end.
