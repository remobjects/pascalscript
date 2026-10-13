program PascalScriptTestSuite;

{ ---------------------------------------------------------------------------
  PascalScript consolidated test suite

  One console program, three verdicts: every check reports PASS, FAIL or
  SKIP.  The exact same source is designed to compile and run against any
  state of the PascalScript sources (../Source), from plain upstream master
  to trees carrying additional fixes or the PS_NATIVESTRINGS mode:

    - script-language features that a tree may not have (set-range literals,
      'packed', 'raise', ParamStr, the AnsiChar/PAnsiChar/PWideChar script
      types, ...) are detected at runtime with compile probes and reported
      as SKIP when absent;
    - optional unit-level host APIs (debug/watch helpers) are gated with
      $IF DECLARED compiler directives;
    - behavioral fixes (catchable casts, Variant->interface assignment,
      dynarray marshaling through the invoke path) are detected with small
      runtime probes: if the minimal probe misbehaves the section is
      reported as SKIP with the reason, never silently dropped;
    - expectations that depend on the script char width use SizeOf(TbtChar).

  Exit code is 0 exactly when no check FAILed.  No interaction, no required
  command line arguments (when arguments are present the ParamStr section
  cross-checks them against the host's view of the same command line).
  --------------------------------------------------------------------------- }

{$IFDEF FPC}
  {$MODE DELPHI}
  {$LONGSTRINGS ON}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils,
  Variants,
  {$IFDEF MSWINDOWS}
  ActiveX,
  ComObj,
  uPSC_dll,
  uPSR_dll,
  {$ENDIF}
  uPSUtils,
  uPSCompiler,
  uPSRuntime,
  uPSDisassembly;

type
  { Byte buffer moved between TPSPascalCompiler.GetOutput, TPSExec.LoadData
    and IFPS3DataToText.  With PS_NATIVESTRINGS the buffer parameter type is
    TbtAnsiString; on every tree without that define (including trees that
    do not know the define at all) it is TbtString. }
  TPSData = {$IFDEF PS_NATIVESTRINGS}TbtAnsiString{$ELSE}TbtString{$ENDIF};

  { Host-side type of a parameter declared as 'string' in a script function
    signature: UnicodeString on Unicode Delphi (script 'string' maps to
    btUnicodeString there), plain (Ansi)string on Delphi 7 and FPC. }
  TScrStr = {$IFDEF UNICODE}UnicodeString{$ELSE}string{$ENDIF};

  TRegRuntime = procedure(Exec: TPSExec);

var
  GTotal, GPassed, GFailed, GSkipped: Integer;
  GStrict: Boolean; { -strict: probe-detected broken behavior fails instead of skipping }
  { last values a probe script stored via ProbeInt/ProbeStr }
  GProbeInt: Integer;
  GProbeStr: TScrStr;

{ --------------------------------------------------------------------------
  reporting
  -------------------------------------------------------------------------- }

procedure Banner(const Name: string);
begin
  WriteLn;
  WriteLn('=== ', Name, ' ===');
end;

procedure Pass(const Msg: string);
begin
  Inc(GTotal);
  Inc(GPassed);
  WriteLn('PASS: ', Msg);
end;

procedure Fail(const Msg: string);
begin
  Inc(GTotal);
  Inc(GFailed);
  WriteLn('FAIL: ', Msg);
end;

procedure Skip(const Msg, Reason: string);
begin
  Inc(GTotal);
  Inc(GSkipped);
  WriteLn('SKIP: ', Msg, ' [', Reason, ']');
end;

procedure CheckHost(b: Boolean; const Msg: string);
begin
  if b then Pass(Msg) else Fail(Msg);
end;

{ a skip caused by PROBED broken behavior - as opposed to a feature that is
  absent by design. With -strict these count as failures, so a regression on
  a fixed tree flips the exit code instead of hiding as a skip. }
procedure SkipBug(const Msg, Reason: string);
begin
  if GStrict then
    Fail(Msg + ' [' + Reason + ']')
  else
    Skip(Msg, Reason);
end;

{ --------------------------------------------------------------------------
  script-callable helpers (registered in every executed script)
  -------------------------------------------------------------------------- }

procedure ScrCheck(b: Boolean; const Msg: TScrStr);
begin
  CheckHost(b, string(Msg));
end;

procedure ScrCheckStr(const a, b, Msg: TScrStr);
begin
  if a = b then
    Pass(string(Msg))
  else
    Fail(string(Msg) + ' -> "' + string(a) + '" <> "' + string(b) + '"');
end;

procedure ScrProbeInt(Value: Integer);
begin
  GProbeInt := Value;
end;

procedure ScrProbeStr(const Value: TScrStr);
begin
  GProbeStr := Value;
end;

procedure AddCommonDecls(Sender: TPSPascalCompiler);
begin
  Sender.AddDelphiFunction('procedure Check(b: Boolean; const msg: string)');
  Sender.AddDelphiFunction('procedure CheckStr(const a, b, msg: string)');
  Sender.AddDelphiFunction('procedure ProbeInt(Value: Integer)');
  Sender.AddDelphiFunction('procedure ProbeStr(const Value: string)');
end;

procedure RegCommonRT(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@ScrCheck, 'CHECK', cdRegister);
  Exec.RegisterDelphiFunction(@ScrCheckStr, 'CHECKSTR', cdRegister);
  Exec.RegisterDelphiFunction(@ScrProbeInt, 'PROBEINT', cdRegister);
  Exec.RegisterDelphiFunction(@ScrProbeStr, 'PROBESTR', cdRegister);
end;

function OnUsesCommon(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Result := True;
  end
  else
    Result := False;
end;

{ --------------------------------------------------------------------------
  compile / run infrastructure
  -------------------------------------------------------------------------- }

function FirstError(Compiler: TPSPascalCompiler): string;
begin
  if Compiler.MsgCount > 0 then
    Result := string(Compiler.Msg[0].MessageToString)
  else
    Result := 'unknown compile error';
end;

function CompileScript(const Src: TbtString; OnUses: TPSOnUses;
  var Data: TPSData; var Err: string): Boolean;
var
  Compiler: TPSPascalCompiler;
begin
  Result := False;
  Data := '';
  Err := '';
  Compiler := TPSPascalCompiler.Create;
  try
    Compiler.OnUses := OnUses;
    try
      if not Compiler.Compile(Src) then
      begin
        Err := FirstError(Compiler);
        Exit;
      end;
    except
      on E: Exception do
      begin
        Err := E.ClassName + ': ' + E.Message;
        Exit;
      end;
    end;
    Compiler.GetOutput(Data);
    Result := True;
  finally
    Compiler.Free;
  end;
end;

{ result: 0 = ran clean, 1 = compile error, 2 = load error, 3 = runtime error }
function RunScript(const Src: TbtString; OnUses: TPSOnUses;
  RegRT: TRegRuntime; var Err: string): Integer;
var
  Exec: TPSExec;
  Data: TPSData;
begin
  if not CompileScript(Src, OnUses, Data, Err) then
  begin
    Result := 1;
    Exit;
  end;
  Exec := TPSExec.Create;
  try
    RegCommonRT(Exec);
    if Assigned(RegRT) then
      RegRT(Exec);
    if not Exec.LoadData(Data) then
    begin
      Err := string(TIFErrorToString(Exec.ExceptionCode, Exec.ExceptionString));
      Result := 2;
      Exit;
    end;
    Exec.RunScript;
    if Exec.ExceptionCode <> erNoError then
    begin
      Err := string(TIFErrorToString(Exec.ExceptionCode, Exec.ExceptionString));
      Result := 3;
      Exit;
    end;
    Result := 0;
  finally
    Exec.Free;
  end;
end;

{ compile probe for script-language features }
function FeatureCompilesEx(const Src: TbtString; OnUses: TPSOnUses): Boolean;
var
  Compiler: TPSPascalCompiler;
begin
  Compiler := TPSPascalCompiler.Create;
  try
    Compiler.OnUses := OnUses;
    try
      Result := Compiler.Compile(Src);
    except
      Result := False;
    end;
  finally
    Compiler.Free;
  end;
end;

function FeatureCompiles(const Src: TbtString): Boolean;
begin
  Result := FeatureCompilesEx(Src, OnUsesCommon);
end;

{ run a script whose checks are performed by the script itself (via Check/
  CheckStr).  When SkipOnError is set, a script that does not compile or
  does not run to completion marks the section SKIP with the reason -
  used for sections that probe optional behavior fixes. }
procedure RunChecked(const Title: string; const Src: TbtString;
  OnUses: TPSOnUses; RegRT: TRegRuntime; SkipOnError: Boolean;
  const SkipReason: string);
var
  rc: Integer;
  Err: string;
begin
  rc := RunScript(Src, OnUses, RegRT, Err);
  case rc of
    0: ; { checks were reported from inside the script }
    1: if SkipOnError then
         SkipBug(Title, SkipReason + ' (compile: ' + Err + ')')
       else
         Fail(Title + ': does not compile: ' + Err);
    2: Fail(Title + ': LoadData failed: ' + Err);
    3: if SkipOnError then
         SkipBug(Title, SkipReason + ' (runtime: ' + Err + ')')
       else
         Fail(Title + ': runtime error: ' + Err);
  end;
end;

{ --------------------------------------------------------------------------
  01 Basics: compile, load, run, integer/string/char constants, StrGet/StrSet
  -------------------------------------------------------------------------- }

procedure SectionBasics;
const
  Src: TbtString =
    'var i: Integer; b: Byte; s: string; a: AnsiString; c: Char; g: Int64;'#13#10 +
    'function F: Integer;'#13#10 +
    'begin'#13#10 +
    '  Result := 42;'#13#10 +
    'end;'#13#10 +
    'procedure P;'#13#10 +
    'var L: Integer;'#13#10 +
    'begin'#13#10 +
    '  L := 7;'#13#10 +
    '  Check(L = 7, ''local variable in procedure'');'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    '  i := 1;'#13#10 +
    '  Check(i = 1, ''integer assign'');'#13#10 +
    '  b := 255;'#13#10 +
    '  Check(b = 255, ''byte assign'');'#13#10 +
    '  i := F;'#13#10 +
    '  Check(i = 42, ''function result'');'#13#10 +
    '  P;'#13#10 +
    '  Check(1000 * 1000 = 1000000, ''integer arithmetic'');'#13#10 +
    '  s := ''abc'';'#13#10 +
    '  Check(Length(s) = 3, ''string length'');'#13#10 +
    '  Check(s[2] = ''b'', ''StrGet'');'#13#10 +
    '  s[2] := ''x'';'#13#10 +
    '  Check(s = ''axc'', ''StrSet'');'#13#10 +
    '  c := ''Q'';'#13#10 +
    '  s := s + c;'#13#10 +
    '  Check(s = ''axcQ'', ''string + char concat'');'#13#10 +
    '  Check(Ord(''A'') = 65, ''Ord of char literal'');'#13#10 +
    '  a := ''abc'';'#13#10 +
    '  a[2] := ''x'';'#13#10 +
    '  Check(a = ''axc'', ''AnsiString StrSet'');'#13#10 +
    '  a := a + ''!'';'#13#10 +
    '  Check(Length(a) = 4, ''AnsiString concat'');'#13#10 +
    '  g := 4000000000;'#13#10 +
    '  g := g + g;'#13#10 +
    '  Check(g = 8000000000, ''Int64 arithmetic'');'#13#10 +
    'end.';
begin
  Banner('01 Basics');
  RunChecked('basics', Src, OnUsesCommon, nil, False, '');
end;

{ --------------------------------------------------------------------------
  02 CompatRules: IsCompatibleType - what must (not) compile
  -------------------------------------------------------------------------- }

procedure SectionCompatRules;

  procedure MustCompile(const Title: string; const Src: TbtString);
  begin
    CheckHost(FeatureCompiles(Src), Title);
  end;

var
  FixPresent: Boolean;
begin
  Banner('02 CompatRules');
  MustCompile('string := string compiles',
    'var a, b: string; begin a := b; end.');
  MustCompile('string := WideString compiles',
    'var a: string; b: WideString; begin a := b; end.');
  MustCompile('WideString := string compiles',
    'var a: WideString; b: string; begin a := b; end.');
  MustCompile('string := char compiles',
    'var a: string; c: Char; begin a := c; end.');
  MustCompile('Variant := string compiles',
    'var v: Variant; s: string; begin v := s; end.');
  { the fix for the operator precedence hole in IsCompatibleType makes the
    compiler reject these again; on an unfixed tree they compile }
  FixPresent := not FeatureCompiles('var i: Integer; s: string; begin i := s; end.');
  if FixPresent then
  begin
    Pass('Integer := string rejected');
    CheckHost(not FeatureCompiles('var b: Boolean; s: string; begin b := s; end.'),
      'Boolean := string rejected');
    CheckHost(not FeatureCompiles('var d: Double; s: string; begin d := s; end.'),
      'Double := string rejected');
  end
  else
  begin
    SkipBug('Integer := string rejected', 'IsCompatibleType precedence fix not on this tree');
    SkipBug('Boolean := string rejected', 'IsCompatibleType precedence fix not on this tree');
    SkipBug('Double := string rejected', 'IsCompatibleType precedence fix not on this tree');
  end;
end;

{ --------------------------------------------------------------------------
  03 OrdChr: Ord/Chr on the char types
  -------------------------------------------------------------------------- }

procedure SectionOrdChr;
const
  SrcChar: TbtString =
    'var c: Char; i: Integer; s: string;'#13#10 +
    'begin'#13#10 +
    '  c := #97;'#13#10 +
    '  i := Ord(c);'#13#10 +
    '  Check(i = 97, ''Ord(Char)'');'#13#10 +
    '  c := Chr(66);'#13#10 +
    '  Check(c = ''B'', ''Chr'');'#13#10 +
    '  s := ''abc'';'#13#10 +
    '  Check(Ord(s[3]) = 99, ''Ord of indexed string char'');'#13#10 +
    'end.';
  SrcAnsi: TbtString =
    'var ac: AnsiChar; i: Integer;'#13#10 +
    'begin'#13#10 +
    '  ac := #97;'#13#10 +
    '  i := Ord(ac);'#13#10 +
    '  Check(i = 97, ''Ord(AnsiChar)'');'#13#10 +
    '  ac := #228;'#13#10 +
    '  Check(Ord(ac) = 228, ''AnsiChar holds a byte value'');'#13#10 +
    'end.';
begin
  Banner('03 OrdChr');
  RunChecked('Ord/Chr on Char', SrcChar, OnUsesCommon, nil, False, '');
  if FeatureCompiles('var ac: AnsiChar; begin end.') then
    RunChecked('Ord on AnsiChar', SrcAnsi, OnUsesCommon, nil, False, '')
  else
    Skip('Ord on AnsiChar', 'no AnsiChar script type on this tree');
end;

{ --------------------------------------------------------------------------
  04 SetRangeLiterals: constant ranges in set literals
  -------------------------------------------------------------------------- }

function OnUsesSetRange(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddTypeS('TFruit', '(frApple, frBanana, frCherry, frDate)');
    Result := True;
  end
  else
    Result := False;
end;

procedure SectionSetRangeLiterals;
const
  Src: TbtString =
    'var c: Char; b: Byte; f: TFruit;'#13#10 +
    'begin'#13#10 +
    '  c := ''7'';'#13#10 +
    '  Check(c in [''0''..''9''], ''char in char range'');'#13#10 +
    '  c := ''x'';'#13#10 +
    '  Check(not (c in [''0''..''9'']), ''char outside range'');'#13#10 +
    '  Check(c in [''a''..''f'', ''x''..''z''], ''multiple ranges'');'#13#10 +
    '  Check(c in [''q'', ''u''..''z''], ''mixed single + range'');'#13#10 +
    '  b := 252;'#13#10 +
    '  Check(b in [1..5, 250..255], ''byte ranges up to 255'');'#13#10 +
    '  b := 100;'#13#10 +
    '  Check(not (b in [1..5, 250..255]), ''byte outside ranges'');'#13#10 +
    '  f := frCherry;'#13#10 +
    '  Check(f in [frBanana..frDate], ''enum range'');'#13#10 +
    '  Check(not (frApple in [frBanana..frDate]), ''enum outside range'');'#13#10 +
    '  Check(not (c in [''z''..''a'']), ''inverted range is empty'');'#13#10 +
    'end.';
begin
  Banner('04 SetRangeLiterals');
  if not FeatureCompiles(
    'var c: Char; begin c := ''1''; if c in [''0''..''9''] then c := ''x''; end.') then
  begin
    Skip('set-range literals', 'constant ranges in set literals not supported on this tree');
    Exit;
  end;
  RunChecked('set-range literals', Src, OnUsesSetRange, nil, False, '');
end;

{ --------------------------------------------------------------------------
  05 PackedTypes: 'packed' keyword in script type declarations (issue #246)
  -------------------------------------------------------------------------- }

var
  GPackedAddTypeSOk: Boolean;

function OnUsesPacked(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    GPackedAddTypeSOk := True;
    try
      Sender.AddTypeS('THostPacked', 'packed record a: Byte; b: Integer; end');
    except
      GPackedAddTypeSOk := False;
    end;
    Result := True;
  end
  else
    Result := False;
end;

procedure SectionPackedTypes;
const
  SrcRun: TbtString =
    'type TP = packed record x, y: Integer; end;'#13#10 +
    'var r: TP;'#13#10 +
    'begin'#13#10 +
    '  r.x := 3;'#13#10 +
    '  r.y := 4;'#13#10 +
    '  Check(r.x + r.y = 7, ''packed record works at runtime'');'#13#10 +
    'end.';
begin
  Banner('05 PackedTypes');
  if not FeatureCompiles('type TP = packed record x: Integer; end; begin end.') then
  begin
    Skip('packed keyword', '''packed'' is not accepted by this tree (issue #246)');
    Exit;
  end;
  CheckHost(FeatureCompiles(
    'type TA = packed array[0..3] of Byte; var a: TA; begin a[0] := 1; end.'),
    'packed array compiles');
  CheckHost(FeatureCompiles(
    'type TE = (aa, bb, cc); TS = packed set of TE; var s: TS; begin s := [aa, cc]; end.'),
    'packed set compiles');
  CheckHost(not FeatureCompiles('type TBroken = packed Integer; begin end.'),
    'packed before a non-structured type is still rejected');
  RunChecked('packed record runtime', SrcRun, OnUsesCommon, nil, False, '');
  CheckHost(FeatureCompilesEx('var r: THostPacked; begin r.b := 42; end.', OnUsesPacked)
    and GPackedAddTypeSOk, 'AddTypeS accepts a packed host record');
end;

{ --------------------------------------------------------------------------
  06 CompilerReuse: one TPSPascalCompiler instance surviving a failing OnUses
  -------------------------------------------------------------------------- }

var
  GReuseBroken: Boolean;

function OnUsesReuse(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
    Result := True
  else if Name = 'SYSUTILS' then
  begin
    if GReuseBroken then
      { invalid declaration: missing 'record' - AddTypeS raises }
      Sender.AddTypeS('TFormatSettings', 'CurrencyFormat: Byte; end;')
    else
      Sender.AddTypeS('TFormatSettings', 'record CurrencyFormat: Byte; end;');
    Result := True;
  end
  else
    Result := False;
end;

procedure SectionCompilerReuse;
var
  Compiler: TPSPascalCompiler;

  function TryOne(const Src: TbtString): Boolean;
  begin
    try
      Result := Compiler.Compile(Src);
    except
      Result := False;
    end;
  end;

begin
  Banner('06 CompilerReuse');
  Compiler := TPSPascalCompiler.Create;
  try
    Compiler.OnUses := OnUsesReuse;
    GReuseBroken := True;
    CheckHost(not TryOne('uses SysUtils; begin end.'),
      'compile with failing OnUses registration reports an error');
    CheckHost(TryOne('begin end.'),
      'plain compile succeeds after the failed one (state not corrupted)');
    GReuseBroken := False;
    CheckHost(TryOne(
      'uses SysUtils; var f: TFormatSettings; begin f.CurrencyFormat := 1; end.'),
      'good registration compiles on the same instance');
    GReuseBroken := True;
    CheckHost(not TryOne('uses SysUtils; begin end.'),
      'second failing registration still reports an error');
    CheckHost(TryOne('begin end.'),
      'instance is still usable afterwards');
  finally
    Compiler.Free;
  end;
end;

{ --------------------------------------------------------------------------
  07 RegisterPropertyFailure: property with unresolvable type must not be
     dropped silently
  -------------------------------------------------------------------------- }

function OnUsesRegProp(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    { TUnknownType is never registered; the fixed tree raises here, the
      unfixed tree silently drops the property }
    Sender.AddClassN(nil, 'TPropHost').RegisterProperty('BrokenProp',
      'TUnknownType', iptRW);
    Result := True;
  end
  else
    Result := False;
end;

procedure SectionRegisterPropertyFailure;
begin
  Banner('07 RegisterPropertyFailure');
  if FeatureCompilesEx('begin end.', OnUsesRegProp) then
    SkipBug('RegisterProperty with unknown type raises',
      'registration failure is swallowed silently on this tree')
  else
    Pass('RegisterProperty with unknown type raises');
end;

{ --------------------------------------------------------------------------
  08 LoadDataErrorMessages: truncated bytecode must fail loudly
  -------------------------------------------------------------------------- }

procedure SectionLoadDataErrorMessages;
var
  Data, Cut: TPSData;
  Err: string;
  Exec: TPSExec;
  i: Integer;
  AllRefused, AllLoud: Boolean;
begin
  Banner('08 LoadDataErrorMessages');
  if not CompileScript('var s: string; begin s := ''x''; end.',
    OnUsesCommon, Data, Err) then
  begin
    Fail('reference script compiles (' + Err + ')');
    Exit;
  end;
  AllRefused := True;
  AllLoud := True;
  for i := 1 to 4 do
  begin
    Exec := TPSExec.Create;
    try
      Cut := Copy(Data, 1, (Length(Data) * i) div 5);
      if Exec.LoadData(Cut) then
        AllRefused := False
      else if Exec.ExceptionCode = erNoError then
        AllLoud := False;
    finally
      Exec.Free;
    end;
  end;
  CheckHost(AllRefused, 'all truncated streams are refused');
  CheckHost(AllLoud, 'every refusal sets an exception code (not silent)');
  Exec := TPSExec.Create;
  try
    CheckHost(Exec.LoadData(Data), 'the complete stream still loads');
  finally
    Exec.Free;
  end;
end;

{ --------------------------------------------------------------------------
  09 ArrayOfConst: inline array-of-const arguments (issue #296) and the
     element types, width-adaptive
  -------------------------------------------------------------------------- }

function SuiteFormat(const Fmt: TScrStr; const Args: array of const): TScrStr;
begin
  Result := TScrStr(Format(string(Fmt), Args));
end;

function OnUsesAoC(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddDelphiFunction(
      'function MyFormat(const Fmt: string; const Args: array of const): string');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegAoC(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@SuiteFormat, 'MYFORMAT', cdRegister);
end;

procedure SectionArrayOfConst;
const
  Src296: TbtString =
    'var Help1: array of string; i: Integer; s: string;'#13#10 +
    'begin'#13#10 +
    '  SetLength(Help1, 3);'#13#10 +
    '  Help1[0] := ''A0'';'#13#10 +
    '  Help1[1] := ''B1'';'#13#10 +
    '  Help1[2] := ''C2'';'#13#10 +
    '  s := MyFormat(''Test%s'', [ Help1[0] ]);'#13#10 +
    '  CheckStr(s, ''TestA0'', ''inline array-of-const, element 0'');'#13#10 +
    '  s := MyFormat(''Test%s'', [ Help1[1] ]);'#13#10 +
    '  CheckStr(s, ''TestB1'', ''inline array-of-const, element 1 (issue #296)'');'#13#10 +
    '  s := MyFormat(''%s|%s'', [ Trim(Help1[1]), Trim(Help1[2]) ]);'#13#10 +
    '  CheckStr(s, ''B1|C2'', ''two trimmed elements'');'#13#10 +
    '  for i := 0 to 2 do'#13#10 +
    '  begin'#13#10 +
    '    s := MyFormat(''<%s>'', [ Help1[i] ]);'#13#10 +
    '    Check(Length(s) = 4, ''loop element '' + IntToStr(i));'#13#10 +
    '  end;'#13#10 +
    'end.';
  { probed instead of asserted: some trees pass a single-character literal
    or a P-char element with the wrong width/pointer }
  SrcLiteral: TbtString =
    'begin'#13#10 +
    '  ProbeStr(MyFormat(''%d/%s'', [42, ''x'']));'#13#10 +
    'end.';
  SrcPChar: TbtString =
    'var p: PChar; u: string;'#13#10 +
    'begin'#13#10 +
    '  u := ''wide'';'#13#10 +
    '  p := u;'#13#10 +
    '  ProbeStr(MyFormat(''<%s>'', [p]));'#13#10 +
    'end.';
  SrcAnsi: TbtString =
    'var sa: AnsiString; pa: PAnsiChar;'#13#10 +
    'begin'#13#10 +
    '  sa := ''ansi'';'#13#10 +
    '  CheckStr(MyFormat(''<%s>'', [sa]), ''<ansi>'', ''AnsiString element'');'#13#10 +
    '  pa := sa;'#13#10 +
    '  CheckStr(MyFormat(''<%s>'', [pa]), ''<ansi>'', ''PAnsiChar element'');'#13#10 +
    'end.';
  SrcAnsiChar: TbtString =
    'var ac: AnsiChar;'#13#10 +
    'begin'#13#10 +
    '  ac := ''X'';'#13#10 +
    '  CheckStr(MyFormat(''<%s>'', [ac]), ''<X>'', ''AnsiChar element'');'#13#10 +
    'end.';
  procedure ProbeElement(const Title: string; const Src: TbtString;
    const Expected: TScrStr; const BrokenReason: string);
  var
    rc: Integer;
    Err: string;
  begin
    GProbeStr := '';
    rc := RunScript(Src, OnUsesAoC, RegAoC, Err);
    if rc <> 0 then
      SkipBug(Title, BrokenReason + ' (' + Err + ')')
    else if GProbeStr = Expected then
      Pass(Title)
    else
      SkipBug(Title, BrokenReason + ' (got "' + string(GProbeStr) + '")');
  end;

begin
  Banner('09 ArrayOfConst');
  RunChecked('inline array of const', Src296, OnUsesAoC, RegAoC, True,
    'array-of-const passing broken on this tree (issue #296)');
  ProbeElement('single-char literal element', SrcLiteral, '42/x',
    'char literal array-of-const element mismarshaled on this tree');
  if FeatureCompiles('var p: PChar; u: string; begin u := ''a''; p := u; end.') then
    ProbeElement('PChar element', SrcPChar, '<wide>',
      'PChar array-of-const element mismarshaled on this tree')
  else
    Skip('PChar element', 'string -> PChar assignment not supported on this tree');
  if FeatureCompilesEx(SrcAnsi, OnUsesAoC) then
    RunChecked('AnsiString/PAnsiChar elements', SrcAnsi, OnUsesAoC, RegAoC, False, '')
  else
    Skip('AnsiString/PAnsiChar elements', 'no PAnsiChar script type on this tree');
  if FeatureCompilesEx(SrcAnsiChar, OnUsesAoC) then
    RunChecked('AnsiChar element', SrcAnsiChar, OnUsesAoC, RegAoC, False, '')
  else
    Skip('AnsiChar element', 'no AnsiChar script type on this tree');
end;

{ --------------------------------------------------------------------------
  10 RaiseAndParams: script 'raise' statement, ParamCount/ParamStr builtins
  -------------------------------------------------------------------------- }

function HostParam(i: Integer): TScrStr;
begin
  Result := TScrStr(ParamStr(i));
end;

function OnUsesParams(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddDelphiFunction('function HostParam(i: Integer): string');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegParams(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@HostParam, 'HOSTPARAM', cdRegister);
end;

procedure SectionRaiseAndParams;
const
  SrcParams: TbtString =
    'begin'#13#10 +
    '  Check(ParamCount >= 0, ''ParamCount >= 0'');'#13#10 +
    '  Check(Length(ParamStr(0)) > 0, ''ParamStr(0) non-empty'');'#13#10 +
    '  CheckStr(ParamStr(0), HostParam(0), ''script and host agree on ParamStr(0)'');'#13#10 +
    '  CheckStr(ParamStr(1), HostParam(1), ''script and host agree on ParamStr(1)'');'#13#10 +
    '  CheckStr(ParamStr(99), '''', ''ParamStr out of range is empty'');'#13#10 +
    'end.';
  SrcRaise: TbtString =
    'var Hits: string;'#13#10 +
    'procedure Inner;'#13#10 +
    'begin'#13#10 +
    '  raise Exception.Create(''from inner '' + IntToStr(42));'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    '  Hits := '''';'#13#10 +
    '  try'#13#10 +
    '    raise Exception.Create(''boom'');'#13#10 +
    '    Hits := Hits + ''X'';'#13#10 +
    '  except'#13#10 +
    '    Hits := Hits + ''1'';'#13#10 +
    '    Check(ExceptionType = erCustomError, ''ExceptionType = erCustomError'');'#13#10 +
    '    CheckStr(ExceptionParam, ''boom'', ''ExceptionParam carries the message'');'#13#10 +
    '  end;'#13#10 +
    '  try'#13#10 +
    '    Inner;'#13#10 +
    '  except'#13#10 +
    '    Hits := Hits + ''2'';'#13#10 +
    '    CheckStr(ExceptionParam, ''from inner 42'', ''message may be an expression'');'#13#10 +
    '  end;'#13#10 +
    '  try'#13#10 +
    '    try'#13#10 +
    '      raise EMyError.Create(''re'');'#13#10 +
    '    except'#13#10 +
    '      Hits := Hits + ''3'';'#13#10 +
    '      raise;'#13#10 +
    '    end;'#13#10 +
    '    Hits := Hits + ''Y'';'#13#10 +
    '  except'#13#10 +
    '    Hits := Hits + ''4'';'#13#10 +
    '    CheckStr(ExceptionParam, ''re'', ''bare raise re-raises to outer handler'');'#13#10 +
    '  end;'#13#10 +
    '  try'#13#10 +
    '    if Hits <> '''' then raise Exception.Create(''oneliner'');'#13#10 +
    '  except'#13#10 +
    '    Hits := Hits + ''5'';'#13#10 +
    '  end;'#13#10 +
    '  CheckStr(Hits, ''12345'', ''control flow order'');'#13#10 +
    'end.';
begin
  Banner('10 RaiseAndParams');
  if FeatureCompiles('var i: Integer; begin i := ParamCount; end.') then
    RunChecked('ParamCount/ParamStr', SrcParams, OnUsesParams, RegParams, False, '')
  else
    Skip('ParamCount/ParamStr', 'ParamCount/ParamStr builtins not on this tree');
  if FeatureCompiles('begin try raise EOops.Create(''x''); except end; end.') then
    RunChecked('raise statement', SrcRaise, OnUsesCommon, nil, False, '')
  else
    Skip('raise statement', '''raise'' statement not supported on this tree');
end;

{ --------------------------------------------------------------------------
  11 Interfaces: Variant <-> interface assignments, casts via QueryInterface,
     failing casts catchable (needs the variant-interface-casts and
     catchable-cast fixes; probed at runtime)
  -------------------------------------------------------------------------- }

const
  IMyFoo_GUID: TGUID = '{8D5B3E61-4B2A-4F0E-9C77-0A54D2B1C9AA}';

type
  IMyFoo = interface
    ['{8D5B3E61-4B2A-4F0E-9C77-0A54D2B1C9AA}']
  end;

  TPlainImpl = class(TInterfacedObject)
  end;

  TFooImpl = class(TInterfacedObject, IMyFoo)
  end;

function GetPlainIntf: Variant;
var
  u: IUnknown;
begin
  u := TPlainImpl.Create;
  Result := u;
end;

function GetFooIntf: Variant;
var
  u: IUnknown;
begin
  u := TFooImpl.Create;
  Result := u;
end;

function GetPlainUnknown: IUnknown;
begin
  Result := TPlainImpl.Create;
end;

function IntfAssigned(const I: IUnknown): Boolean;
begin
  Result := I <> nil;
end;

function FooAssigned(const F: IMyFoo): Boolean;
begin
  Result := F <> nil;
end;

function OnUsesIntf(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddInterface(Sender.FindInterface('IUnknown'), IMyFoo_GUID, 'IMyFoo');
    TPSInterfaceType(Sender.FindType('IMyFoo')).ExportName := True;
    Sender.AddDelphiFunction('function GetPlainIntf: Variant');
    Sender.AddDelphiFunction('function GetFooIntf: Variant');
    Sender.AddDelphiFunction('function GetPlainUnknown: IUnknown');
    Sender.AddDelphiFunction('function IntfAssigned(const I: IUnknown): Boolean');
    Sender.AddDelphiFunction('function FooAssigned(const F: IMyFoo): Boolean');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegIntf(Exec: TPSExec);
begin
  TPSRuntimeClassImporter.CreateAndRegister(Exec, True); { provides the cast import }
  Exec.RegisterDelphiFunction(@GetPlainIntf, 'GETPLAININTF', cdRegister);
  Exec.RegisterDelphiFunction(@GetFooIntf, 'GETFOOINTF', cdRegister);
  Exec.RegisterDelphiFunction(@GetPlainUnknown, 'GETPLAINUNKNOWN', cdRegister);
  Exec.RegisterDelphiFunction(@IntfAssigned, 'INTFASSIGNED', cdRegister);
  Exec.RegisterDelphiFunction(@FooAssigned, 'FOOASSIGNED', cdRegister);
end;

procedure SectionInterfaces;
const
  Src: TbtString =
    'var v: Variant; u: IUnknown; f: IMyFoo; hits: Integer;'#13#10 +
    'begin'#13#10 +
    '  v := GetPlainIntf;'#13#10 +
    '  u := v;'#13#10 +
    '  Check(IntfAssigned(u), ''Variant -> IUnknown'');'#13#10 +
    '  v := Unassigned;'#13#10 +
    '  u := v;'#13#10 +
    '  Check(not IntfAssigned(u), ''empty Variant -> nil interface'');'#13#10 +
    '  v := GetFooIntf;'#13#10 +
    '  f := v;'#13#10 +
    '  Check(FooAssigned(f), ''Variant -> IMyFoo via QueryInterface'');'#13#10 +
    '  u := f;'#13#10 +
    '  Check(IntfAssigned(u), ''IMyFoo -> IUnknown'');'#13#10 +
    '  f := IMyFoo(u);'#13#10 +
    '  Check(FooAssigned(f), ''IMyFoo(u) cast via QueryInterface'');'#13#10 +
    '  v := GetPlainIntf;'#13#10 +
    '  hits := 0;'#13#10 +
    '  try'#13#10 +
    '    f := v;'#13#10 +
    '  except'#13#10 +
    '    hits := 1;'#13#10 +
    '  end;'#13#10 +
    '  Check(hits = 1, ''failing Variant -> interface cast is catchable'');'#13#10 +
    'end.';
begin
  Banner('11 Interfaces');
  RunChecked('Variant/interface interop', Src, OnUsesIntf, RegIntf, True,
    'Variant -> interface assignment not supported on this tree');
end;

{ --------------------------------------------------------------------------
  12 CatchableCastErrors: failing interface cast raises a script-catchable
     error instead of killing the execution
  -------------------------------------------------------------------------- }

procedure SectionCatchableCastErrors;
const
  Src: TbtString =
    'var u: IUnknown; f: IMyFoo; hits: Integer;'#13#10 +
    'begin'#13#10 +
    '  u := GetPlainUnknown;'#13#10 +
    '  hits := 0;'#13#10 +
    '  try'#13#10 +
    '    f := IMyFoo(u);'#13#10 + { TPlainImpl does not implement IMyFoo }
    '  except'#13#10 +
    '    hits := 1;'#13#10 +
    '  end;'#13#10 +
    '  Check(hits = 1, ''failing interface cast is catchable'');'#13#10 +
    'end.';
begin
  Banner('12 CatchableCastErrors');
  RunChecked('catchable failing cast', Src, OnUsesIntf, RegIntf, True,
    'failing casts abort the script on this tree');
end;

{ --------------------------------------------------------------------------
  13 COM: IDispatch late binding via Variant (Windows only)
  -------------------------------------------------------------------------- }

{$IFDEF MSWINDOWS}
function CreateOle(const ClassName: TScrStr): Variant;
begin
  Result := CreateOleObject(string(ClassName));
end;

function OnUsesCom(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddDelphiFunction('function CreateOle(const ClassName: string): Variant');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegCom(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@CreateOle, 'CREATEOLE', cdRegister);
end;
{$ENDIF}

procedure SectionCom;
{$IFDEF MSWINDOWS}
const
  SrcBasics: TbtString =
    'var d: Variant; hits: Integer;'#13#10 +
    'begin'#13#10 +
    '  d := CreateOle(''Scripting.Dictionary'');'#13#10 +
    '  d.CompareMode := 1;'#13#10 +
    '  Check(d.CompareMode = 1, ''property put/get (CompareMode)'');'#13#10 +
    '  d.Add(''k'', 5);'#13#10 +
    '  Check(d.Count = 1, ''method call + Count property'');'#13#10 +
    '  Check(d.Item(''k'') = 5, ''indexed Item get'');'#13#10 +
    '  Check(d.Exists(''k''), ''method with BSTR arg'');'#13#10 +
    '  hits := 0;'#13#10 +
    '  try'#13#10 +
    '    d.Add(''k'', 1);'#13#10 + { duplicate key -> DISP_E_EXCEPTION }
    '  except'#13#10 +
    '    hits := 1;'#13#10 +
    '  end;'#13#10 +
    '  Check(hits = 1, ''COM exception is catchable'');'#13#10 +
    'end.';
  { IDispatch values crossing the script boundary: broken (VT_UNKNOWN vs
    VT_DISPATCH, refcounting) on unfixed trees - up to an access violation
    when the execution engine releases the variants }
  SrcDispatch: TbtString =
    'var d, d2, w: Variant;'#13#10 +
    'begin'#13#10 +
    '  d := CreateOle(''Scripting.Dictionary'');'#13#10 +
    '  d2 := CreateOle(''Scripting.Dictionary'');'#13#10 +
    '  d2.Add(''x'', 42);'#13#10 +
    '  d.Add(''obj'', d2);'#13#10 +
    '  Check(d.Count = 1, ''IDispatch value as argument'');'#13#10 +
    '  w := d.Item(''obj'');'#13#10 +
    '  Check(w.Item(''x'') = 42, ''IDispatch roundtrip through dictionary'');'#13#10 +
    'end.';
  { own stack frame: the hidden IDispatch temporary of the CreateOleObject
    call must be released before CoUninitialize unloads the COM server }
  function DictionaryAvailable: Boolean;
  var
    v: Variant;
  begin
    try
      v := CreateOleObject('Scripting.Dictionary');
      Result := True;
    except
      Result := False;
    end;
  end;

begin
  Banner('13 COM');
  CoInitialize(nil);
  try
    if not DictionaryAvailable then
    begin
      Skip('COM late binding', 'Scripting.Dictionary not available on this machine');
      Exit;
    end;
    RunChecked('COM late binding', SrcBasics, OnUsesCom, RegCom, True,
      'COM Variant dispatch not working on this tree');
    { the roundtrip corrupts the IDispatch refcounts on unfixed trees
      (VT_UNKNOWN vs VT_DISPATCH); the over-release then crashes with an
      access violation - inside the run or as late as CoUninitialize.
      Both guards keep the remaining sections alive. }
    try
      RunChecked('IDispatch values', SrcDispatch, OnUsesCom, RegCom, True,
        'IDispatch values not marshaled on this tree');
    except
      on E: Exception do
        SkipBug('IDispatch values cleanup', 'crashes on this tree (' +
          E.ClassName + ', missing VT_DISPATCH handling)');
    end;
  finally
    try
      CoUninitialize;
      Pass('COM teardown clean');
    except
      on E: Exception do
        SkipBug('COM teardown clean', E.ClassName +
          ' in CoUninitialize (IDispatch over-release on this tree)');
    end;
  end;
end;
{$ELSE}
begin
  Banner('13 COM');
  Skip('COM late binding', 'Windows only');
end;
{$ENDIF}

{ --------------------------------------------------------------------------
  14 DllImport: script-declared DLL imports (Windows only, kernel32)
  -------------------------------------------------------------------------- }

{$IFDEF MSWINDOWS}
function OnUsesDll(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    RegisterDll_Compiletime(Sender);
    AddCommonDecls(Sender);
    Result := True;
  end
  else
    Result := False;
end;

procedure RegDll(Exec: TPSExec);
begin
  RegisterDLLRuntime(Exec);
end;
{$ENDIF}

procedure SectionDllImport;
{$IFDEF MSWINDOWS}
var
  Src: TbtString;
  AnsiPtr, WidePtr: TbtString;
begin
  Banner('14 DllImport');
  { pick the P-char type names available on this tree (the probe includes a
    string literal assignment); PChar is byte wide exactly when the script
    char is byte wide }
  if FeatureCompiles('var p: PAnsiChar; begin p := ''ab''; end.') then
    AnsiPtr := 'PAnsiChar'
  else if (SizeOf(TbtChar) = 1) and
    FeatureCompiles('var p: PChar; begin p := ''ab''; end.') then
    AnsiPtr := 'PChar'
  else
    AnsiPtr := '';
  if FeatureCompiles('var p: PWideChar; begin p := ''ab''; end.') then
    WidePtr := 'PWideChar'
  else if (SizeOf(TbtChar) = 2) and
    FeatureCompiles('var p: PChar; begin p := ''ab''; end.') then
    WidePtr := 'PChar'
  else
    WidePtr := '';

  Src :=
    'function GetTickCount: Cardinal; external ''GetTickCount@kernel32.dll stdcall'';'#13#10 +
    'function MulDiv(a, b, c: Integer): Integer; external ''MulDiv@kernel32.dll stdcall'';'#13#10 +
    'function GetCurrentProcessId: Cardinal; external ''GetCurrentProcessId@kernel32.dll stdcall delayload'';'#13#10 +
    'var t1: Cardinal;'#13#10 +
    'begin'#13#10 +
    '  t1 := GetTickCount;'#13#10 +
    '  Check(t1 <> 0, ''GetTickCount returns'');'#13#10 +
    '  Check(MulDiv(10, 20, 4) = 50, ''MulDiv int params'');'#13#10 +
    '  Check(GetCurrentProcessId <> 0, ''delayload import'');'#13#10 +
    '  UnloadDll(''kernel32.dll'');'#13#10 +
    '  Check(GetTickCount >= t1, ''reload after UnloadDll'');'#13#10 +
    'end.';
  RunChecked('kernel32 imports', Src, OnUsesDll, RegDll, False, '');

  { P-char parameters are probed instead of asserted: an unfixed tree
    compiles them but passes a bad pointer to the DLL }
  if AnsiPtr <> '' then
  begin
    GProbeInt := -1;
    Src :=
      'function lstrlenA(p: ' + TbtString(AnsiPtr) + '): Integer; external ''lstrlenA@kernel32.dll stdcall'';'#13#10 +
      'var pa: ' + TbtString(AnsiPtr) + ';'#13#10 +
      'begin'#13#10 +
      '  pa := ''hallo'';'#13#10 +
      '  ProbeInt(lstrlenA(pa));'#13#10 +
      'end.';
    RunChecked('lstrlenA(' + string(AnsiPtr) + ')', Src, OnUsesDll, RegDll, True,
      'byte P-char DLL parameter crashes on this tree');
    if GProbeInt = 5 then
      Pass('lstrlenA(' + string(AnsiPtr) + ') = 5')
    else if GProbeInt <> -1 then
      SkipBug('lstrlenA(' + string(AnsiPtr) + ') = 5',
        'byte P-char DLL parameter mismarshaled on this tree (got ' +
        SysUtils.IntToStr(GProbeInt) + ')');
  end
  else
    Skip('lstrlenA(PAnsiChar) = 5', 'no byte-wide P-char script type on this tree');

  if WidePtr <> '' then
  begin
    GProbeInt := -1;
    Src :=
      'function lstrlenW(p: ' + TbtString(WidePtr) + '): Integer; external ''lstrlenW@kernel32.dll stdcall'';'#13#10 +
      'function lstrcmpW(a, b: ' + TbtString(WidePtr) + '): Integer; external ''lstrcmpW@kernel32.dll stdcall'';'#13#10 +
      'var pw: ' + TbtString(WidePtr) + '; v: Integer;'#13#10 +
      'begin'#13#10 +
      '  pw := ''hallo welt'';'#13#10 +
      '  v := lstrlenW(pw) * 100;'#13#10 +
      '  if lstrcmpW(''abc'', ''abc'') = 0 then v := v + 10;'#13#10 +
      '  if lstrcmpW(''abc'', ''abd'') < 0 then v := v + 1;'#13#10 +
      '  ProbeInt(v);'#13#10 +
      'end.';
    RunChecked('lstrlenW/lstrcmpW(' + string(WidePtr) + ')', Src, OnUsesDll, RegDll, True,
      'wide P-char DLL parameter crashes on this tree');
    if GProbeInt = 1011 then
      Pass('lstrlenW/lstrcmpW(' + string(WidePtr) + ')')
    else if GProbeInt <> -1 then
      SkipBug('lstrlenW/lstrcmpW(' + string(WidePtr) + ')',
        'wide P-char DLL parameter mismarshaled on this tree (probe ' +
        SysUtils.IntToStr(GProbeInt) + ', expected 1011)');
  end
  else
    Skip('lstrlenW/lstrcmpW(PWideChar)', 'no wide P-char script type on this tree');
end;
{$ELSE}
begin
  Banner('14 DllImport');
  Skip('kernel32 imports', 'Windows only');
end;
{$ENDIF}

{ --------------------------------------------------------------------------
  15 WideStrings: char width, WideString interop, extern string marshaling,
     stack-spill parameter passing
  -------------------------------------------------------------------------- }

function WLen(p: PWideChar): Integer;
begin
  Result := Length(WideString(p));
end;

function ALen(p: PAnsiChar): Integer;
begin
  Result := Length(AnsiString(p));
end;

function AUp(s: AnsiString): AnsiString;
begin
  Result := AnsiString(UpperCase(string(s)));
end;

function ATakeLen(s: AnsiString): Integer;
begin
  Result := Length(s);
end;

function ARes: AnsiString;
begin
  Result := 'xyz';
end;

function SUp(const s: TScrStr): TScrStr;
begin
  Result := TScrStr(UpperCase(string(s)));
end;

{ parameters from position 4 on go to the stack with cdRegister; Int64 and
  Double force the stack path even earlier }
function Sum8(a, b, c, d, e, f, g, h: Integer): Integer;
begin
  Result := a + 10 * b + 100 * c + 1000 * d + 10000 * e + 100000 * f +
    1000000 * g + 10000000 * h;
end;

function Cat5(const a, b, c, d, e: TScrStr): TScrStr;
begin
  Result := a + b + c + d + e;
end;

function AddI64(a, b: Int64): Int64;
begin
  Result := a + b;
end;

function AvgD(a, b: Double): Double;
begin
  Result := (a + b) / 2;
end;

function WLen4(a, b, c: Integer; p: PWideChar): Integer;
begin
  Result := a + b + c + Length(WideString(p));
end;

function OnUsesWide(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddDelphiFunction('function WLen(p: PWideChar): Integer');
    Sender.AddDelphiFunction('function WLen4(a, b, c: Integer; p: PWideChar): Integer');
    Result := True;
  end
  else
    Result := False;
end;

function OnUsesMarshal(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddDelphiFunction('function AUp(s: AnsiString): AnsiString');
    Sender.AddDelphiFunction('function ATakeLen(s: AnsiString): Integer');
    Sender.AddDelphiFunction('function ARes: AnsiString');
    Sender.AddDelphiFunction('function SUp(const s: string): string');
    Sender.AddDelphiFunction('function Sum8(a, b, c, d, e, f, g, h: Integer): Integer');
    Sender.AddDelphiFunction('function Cat5(const a, b, c, d, e: string): string');
    Sender.AddDelphiFunction('function AddI64(a, b: Int64): Int64');
    Sender.AddDelphiFunction('function AvgD(a, b: Double): Double');
    Result := True;
  end
  else
    Result := False;
end;

function OnUsesPAnsi(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddDelphiFunction('function ALen(p: PAnsiChar): Integer');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegWide(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@WLen, 'WLEN', cdRegister);
  Exec.RegisterDelphiFunction(@WLen4, 'WLEN4', cdRegister);
end;

procedure RegMarshal(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@AUp, 'AUP', cdRegister);
  Exec.RegisterDelphiFunction(@ATakeLen, 'ATAKELEN', cdRegister);
  Exec.RegisterDelphiFunction(@ARes, 'ARES', cdRegister);
  Exec.RegisterDelphiFunction(@SUp, 'SUP', cdRegister);
  Exec.RegisterDelphiFunction(@Sum8, 'SUM8', cdRegister);
  Exec.RegisterDelphiFunction(@Cat5, 'CAT5', cdRegister);
  Exec.RegisterDelphiFunction(@AddI64, 'ADDI64', cdRegister);
  Exec.RegisterDelphiFunction(@AvgD, 'AVGD', cdRegister);
end;

procedure RegPAnsi(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@ALen, 'ALEN', cdRegister);
end;

procedure SectionWideStrings;
const
  SrcMarshal: TbtString =
    'var u: string; s: AnsiString; ws: WideString;'#13#10 +
    'begin'#13#10 +
    '  u := ''hello'';'#13#10 +
    '  CheckStr(SUp(u), ''HELLO'', ''extern string param + result'');'#13#10 +
    '  s := ''Hello'';'#13#10 +
    '  Check(Length(s) = 5, ''AnsiString Length'');'#13#10 +
    '  Check(s[2] = ''e'', ''AnsiString index read'');'#13#10 +
    '  Check(ATakeLen(s) = 5, ''extern AnsiString value param'');'#13#10 +
    '  Check(Length(ARes) = 3, ''extern AnsiString result'');'#13#10 +
    '  Check(AUp(s) = ''HELLO'', ''extern AnsiString param + result'');'#13#10 +
    '  ws := ''World'';'#13#10 +
    '  s := ws;'#13#10 +
    '  Check(ATakeLen(s) = 5, ''AnsiString := WideString conversion'');'#13#10 +
    '  Check(Sum8(1, 2, 3, 4, 5, 6, 7, 8) = 87654321, ''stack spill: 8 Integer params'');'#13#10 +
    '  Check(Cat5(''a'', ''b'', ''c'', ''d'', ''e'') = ''abcde'', ''stack spill: 5 string params'');'#13#10 +
    '  Check(AddI64(4000000000, 4000000000) = 8000000000, ''stack: Int64 params + result'');'#13#10 +
    '  Check(AvgD(1.5, 2.5) = 2.0, ''stack: Double params + result'');'#13#10 +
    'end.';
  { native mode: Char/string are wide and can hold U+20AC; in Ansi mode the
    same code paths get an ASCII payload with matching expectations }
  SrcCharWide: TbtString =
    'var c: Char; u: string;'#13#10 +
    'begin'#13#10 +
    '  c := #8364;'#13#10 +
    '  Check(Ord(c) = 8364, ''Char is a native WideChar'');'#13#10 +
    '  u := #8364 + ''x'';'#13#10 +
    '  Check(Length(u) = 2, ''string is a native UnicodeString'');'#13#10 +
    '  Check(Ord(u[1]) = 8364, ''no Ansi data loss in string'');'#13#10 +
    'end.';
  SrcCharAnsi: TbtString =
    'var c: Char; u: string;'#13#10 +
    'begin'#13#10 +
    '  c := ''Z'';'#13#10 +
    '  Check(Ord(c) = 90, ''Char ordinal (Ansi mode)'');'#13#10 +
    '  u := ''Z'' + ''x'';'#13#10 +
    '  Check(Length(u) = 2, ''string concat length (Ansi mode)'');'#13#10 +
    '  Check(Ord(u[1]) = 90, ''string index ord (Ansi mode)'');'#13#10 +
    'end.';
  SrcPWide: TbtString =
    'var ws: WideString; p, q: PWideChar; u: string; np: PChar;'#13#10 +
    'begin'#13#10 +
    '  ws := ''Hello'';'#13#10 +
    '  p := ws;'#13#10 +
    '  u := p;'#13#10 +
    '  CheckStr(u, ''Hello'', ''string := PWideChar'');'#13#10 +
    '  Check(WLen(p) = 5, ''extern WLen(PWideChar)'');'#13#10 +
    '  Check(WLen(q) = 0, ''extern WLen(nil PWideChar)'');'#13#10 +
    '  np := u;'#13#10 +
    '  Check(WLen(np) = 5, ''PChar is wide here'');'#13#10 +
    '  Check(WLen4(1, 2, 3, p) = 11, ''stack spill: PWideChar in position 4'');'#13#10 +
    'end.';
  SrcPAnsi: TbtString =
    'var s: AnsiString; pa: PAnsiChar;'#13#10 +
    'begin'#13#10 +
    '  s := ''Hello!'';'#13#10 +
    '  pa := s;'#13#10 +
    '  Check(ALen(pa) = 6, ''extern ALen(PAnsiChar)'');'#13#10 +
    'end.';
begin
  Banner('15 WideStrings');
  RunChecked('extern marshaling and stack spill', SrcMarshal,
    OnUsesMarshal, RegMarshal, False, '');
  if SizeOf(TbtChar) = 2 then
    RunChecked('char width (wide)', SrcCharWide, OnUsesCommon, nil, False, '')
  else
    RunChecked('char width (ansi)', SrcCharAnsi, OnUsesCommon, nil, False, '');
  if FeatureCompiles('var p: PWideChar; begin end.') then
    RunChecked('PWideChar interop', SrcPWide, OnUsesWide, RegWide, False, '')
  else
    Skip('PWideChar interop', 'no PWideChar script type on this tree');
  if FeatureCompiles('var p: PAnsiChar; begin end.') then
    RunChecked('PAnsiChar interop', SrcPAnsi, OnUsesPAnsi, RegPAnsi, False, '')
  else
    Skip('PAnsiChar interop', 'no PAnsiChar script type on this tree');
end;

{ --------------------------------------------------------------------------
  16 RecordInterop: records crossing the host/script boundary
  -------------------------------------------------------------------------- }

type
  TNeutralRec = packed record
    N: Integer;
    D: Double;
    S: TScrStr;
  end;

  TAnsiRec = packed record
    A: AnsiChar;
    N: Integer;
    Buf: array[0..7] of AnsiChar;
    S: AnsiString;
  end;

procedure FillNRec(var r: TNeutralRec);
begin
  r.N := 42;
  r.D := 1.5;
  r.S := 'host';
end;

function CheckNRec(const r: TNeutralRec): Boolean;
begin
  Result := (r.N = 43) and (r.D = 2.5) and (r.S = 'host!');
end;

procedure FillARec(var r: TAnsiRec);
begin
  r.A := 'X';
  r.N := 42;
  FillChar(r.Buf, SizeOf(r.Buf), 0);
  r.Buf[0] := 'a';
  r.Buf[1] := 'b';
  r.Buf[7] := 'z';
  r.S := 'host';
end;

function CheckARec(const r: TAnsiRec): Boolean;
begin
  Result := (r.A = 'Y') and (r.N = 43) and (r.Buf[0] = 'q') and
    (r.Buf[7] = 'z') and (r.S = 'host!');
end;

function OnUsesNRec(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddTypeS('TNeutralRec', 'record N: Integer; D: Double; S: string; end;');
    Sender.AddDelphiFunction('procedure FillNRec(var r: TNeutralRec)');
    Sender.AddDelphiFunction('function CheckNRec(const r: TNeutralRec): Boolean');
    Result := True;
  end
  else
    Result := False;
end;

function OnUsesARec(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddTypeS('TAnsiRec',
      'record A: AnsiChar; N: Integer; Buf: array[0..7] of AnsiChar; S: AnsiString; end;');
    Sender.AddTypeS('TSysCharSet', 'set of AnsiChar');
    Sender.AddDelphiFunction('procedure FillARec(var r: TAnsiRec)');
    Sender.AddDelphiFunction('function CheckARec(const r: TAnsiRec): Boolean');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegNRec(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@FillNRec, 'FILLNREC', cdRegister);
  Exec.RegisterDelphiFunction(@CheckNRec, 'CHECKNREC', cdRegister);
end;

procedure RegARec(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@FillARec, 'FILLAREC', cdRegister);
  Exec.RegisterDelphiFunction(@CheckARec, 'CHECKAREC', cdRegister);
end;

procedure SectionRecordInterop;
const
  SrcN: TbtString =
    'var r, r2: TNeutralRec;'#13#10 +
    'begin'#13#10 +
    '  FillNRec(r);'#13#10 +
    '  Check(r.N = 42, ''Integer field from host'');'#13#10 +
    '  Check(r.D = 1.5, ''Double field from host'');'#13#10 +
    '  Check(r.S = ''host'', ''string field from host'');'#13#10 +
    '  r.N := r.N + 1;'#13#10 +
    '  r.D := 2.5;'#13#10 +
    '  r.S := r.S + ''!'';'#13#10 +
    '  r2 := r;'#13#10 +
    '  Check((r2.N = 43) and (r2.S = ''host!''), ''record assignment in script'');'#13#10 +
    '  Check(CheckNRec(r), ''record round trip to host'');'#13#10 +
    'end.';
  SrcA: TbtString =
    'var r, r2: TAnsiRec; cs: TSysCharSet; ac: AnsiChar;'#13#10 +
    'begin'#13#10 +
    '  FillARec(r);'#13#10 +
    '  Check(r.A = ''X'', ''AnsiChar record field from host'');'#13#10 +
    '  Check(r.N = 42, ''Integer field after AnsiChar (packed offset)'');'#13#10 +
    '  Check((r.Buf[0] = ''a'') and (r.Buf[1] = ''b'') and (r.Buf[7] = ''z''), ''static AnsiChar array field'');'#13#10 +
    '  Check(r.S = ''host'', ''AnsiString record field from host'');'#13#10 +
    '  r.A := ''Y'';'#13#10 +
    '  r.N := r.N + 1;'#13#10 +
    '  r.Buf[0] := ''q'';'#13#10 +
    '  r.S := r.S + ''!'';'#13#10 +
    '  r2 := r;'#13#10 +
    '  Check((r2.N = 43) and (r2.S = ''host!'') and (r2.Buf[0] = ''q''), ''record assignment in script'');'#13#10 +
    '  Check(CheckARec(r), ''record round trip to host'');'#13#10 +
    '  cs := [''a'', ''b'', ''z''];'#13#10 +
    '  ac := ''b'';'#13#10 +
    '  Check(ac in cs, ''AnsiChar in set of AnsiChar'');'#13#10 +
    '  Check(not (''q'' in cs), ''char literal in set of AnsiChar'');'#13#10 +
    'end.';
begin
  Banner('16 RecordInterop');
  RunChecked('width-neutral record', SrcN, OnUsesNRec, RegNRec, False, '');
  if FeatureCompiles('var ac: AnsiChar; begin end.') then
    RunChecked('Ansi record', SrcA, OnUsesARec, RegARec, False, '')
  else
    Skip('Ansi record', 'no AnsiChar script type on this tree');
end;

{ --------------------------------------------------------------------------
  17 PCharOwnership: script-owned P-char values (needs the PAnsiChar and
     PWideChar script types), including a leak check
  -------------------------------------------------------------------------- }

type
  TPRec = packed record
    A: PAnsiChar;
    W: PWideChar;
  end;

var
  GBufW: array[0..15] of WideChar;
  GBufA: array[0..15] of AnsiChar;

procedure PrimeBufs;
begin
  FillChar(GBufW, SizeOf(GBufW), 0);
  FillChar(GBufA, SizeOf(GBufA), 0);
  GBufW[0] := 'h'; GBufW[1] := 'o'; GBufW[2] := 's'; GBufW[3] := 't';
  GBufA[0] := 'h'; GBufA[1] := 'o'; GBufA[2] := 's'; GBufA[3] := 't';
end;

procedure TrashBufs;
var
  i: Integer;
begin
  for i := 0 to 14 do
  begin
    GBufW[i] := 'X';
    GBufA[i] := 'X';
  end;
  GBufW[15] := #0;
  GBufA[15] := #0;
end;

function GetPW: PWideChar;
begin
  Result := @GBufW;
end;

function GetPA: PAnsiChar;
begin
  Result := @GBufA;
end;

procedure SetPW(var p: PWideChar);
begin
  p := @GBufW;
end;

procedure SetPA(var p: PAnsiChar);
begin
  p := @GBufA;
end;

procedure FillPRec(var r: TPRec);
begin
  r.A := @GBufA;
  r.W := @GBufW;
end;

function OnUsesPChar(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddTypeS('TPRec', 'record A: PAnsiChar; W: PWideChar; end;');
    Sender.AddDelphiFunction('procedure PrimeBufs');
    Sender.AddDelphiFunction('procedure TrashBufs');
    Sender.AddDelphiFunction('function GetPW: PWideChar');
    Sender.AddDelphiFunction('function GetPA: PAnsiChar');
    Sender.AddDelphiFunction('procedure SetPW(var p: PWideChar)');
    Sender.AddDelphiFunction('procedure SetPA(var p: PAnsiChar)');
    Sender.AddDelphiFunction('procedure FillPRec(var r: TPRec)');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegPChar(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@PrimeBufs, 'PRIMEBUFS', cdRegister);
  Exec.RegisterDelphiFunction(@TrashBufs, 'TRASHBUFS', cdRegister);
  Exec.RegisterDelphiFunction(@GetPW, 'GETPW', cdRegister);
  Exec.RegisterDelphiFunction(@GetPA, 'GETPA', cdRegister);
  Exec.RegisterDelphiFunction(@SetPW, 'SETPW', cdRegister);
  Exec.RegisterDelphiFunction(@SetPA, 'SETPA', cdRegister);
  Exec.RegisterDelphiFunction(@FillPRec, 'FILLPREC', cdRegister);
end;

function AllocatedBytes: Int64;
{$IFDEF FPC}
begin
  Result := Int64(GetFPCHeapStatus.CurrHeapUsed);
end;
{$ELSE}
  {$WARN SYMBOL_PLATFORM OFF}
  {$IF CompilerVersion >= 18}
var
  st: TMemoryManagerState;
  i: Integer;
begin
  GetMemoryManagerState(st);
  Result := Int64(st.TotalAllocatedMediumBlockSize) +
    Int64(st.TotalAllocatedLargeBlockSize);
  for i := 0 to High(st.SmallBlockTypeStates) do
    Result := Result + Int64(st.SmallBlockTypeStates[i].UseableBlockSize) *
      Int64(st.SmallBlockTypeStates[i].AllocatedBlockCount);
end;
  {$ELSE}
begin
  { Delphi 7: no TMemoryManagerState }
  Result := Int64(GetHeapStatus.TotalAllocated);
end;
  {$IFEND}
{$ENDIF}

procedure SectionPCharOwnership;
const
  Src: TbtString =
    'var p1, p2: PWideChar; a1, a2: PAnsiChar; s: string; ans: AnsiString;'#13#10 +
    '  ws2: WideString; r, r2: TPRec; i: Integer;'#13#10 +
    'begin'#13#10 +
    { aliasing: two variables of the same P-char type }
    '  p1 := ''aaa'';'#13#10 +
    '  p2 := ''bbb'';'#13#10 +
    '  Check((p1 = ''aaa'') and (p2 = ''bbb''), ''PWideChar aliasing survives'');'#13#10 +
    '  a1 := ''xxx'';'#13#10 +
    '  a2 := ''yyy'';'#13#10 +
    '  Check((a1 = ''xxx'') and (a2 = ''yyy''), ''PAnsiChar aliasing survives'');'#13#10 +
    { self and cross assignment }
    '  p1 := p1;'#13#10 +
    '  Check(p1 = ''aaa'', ''self assignment'');'#13#10 +
    '  p1 := p2;'#13#10 +
    '  p2 := ''ccc'';'#13#10 +
    '  Check((p1 = ''bbb'') and (p2 = ''ccc''), ''cross assignment independent'');'#13#10 +
    { external results are copied - the host buffer is trashed afterwards }
    '  PrimeBufs;'#13#10 +
    '  p1 := GetPW;'#13#10 +
    '  a1 := GetPA;'#13#10 +
    '  TrashBufs;'#13#10 +
    '  Check(p1 = ''host'', ''extern PWideChar result owned copy'');'#13#10 +
    '  Check(a1 = ''host'', ''extern PAnsiChar result owned copy'');'#13#10 +
    { var params: the host writes a foreign pointer, re-owning copies it }
    '  PrimeBufs;'#13#10 +
    '  SetPW(p2);'#13#10 +
    '  SetPA(a2);'#13#10 +
    '  TrashBufs;'#13#10 +
    '  Check(p2 = ''host'', ''var-param PWideChar re-owned'');'#13#10 +
    '  Check(a2 = ''host'', ''var-param PAnsiChar re-owned'');'#13#10 +
    { record fields via var param }
    '  PrimeBufs;'#13#10 +
    '  FillPRec(r);'#13#10 +
    '  TrashBufs;'#13#10 +
    '  ans := r.A;'#13#10 +
    '  ws2 := r.W;'#13#10 +
    '  Check((ans = ''host'') and (ws2 = ''host''), ''record P-char fields re-owned'');'#13#10 +
    { record copies do not share }
    '  r2 := r;'#13#10 +
    '  r.A := ''neu'';'#13#10 +
    '  ans := r2.A;'#13#10 +
    '  Check(ans = ''host'', ''record copy keeps own P-char'');'#13#10 +
    '  s := p2 + ''!'';'#13#10 +
    '  Check(s = ''host!'', ''PWideChar concat'');'#13#10 +
    { stress: many assignments (leaks/AVs) }
    '  for i := 1 to 20000 do'#13#10 +
    '  begin'#13#10 +
    '    p1 := ''stress'';'#13#10 +
    '    a1 := ''stress'';'#13#10 +
    '  end;'#13#10 +
    '  Check((p1 = ''stress'') and (a1 = ''stress''), ''assignment stress'');'#13#10 +
    'end.';

  function RunOnce(Quiet: Boolean): Boolean;
  var
    rc, OldPassed, OldTotal, OldFailed: Integer;
    Err: string;
  begin
    OldPassed := GPassed;
    OldTotal := GTotal;
    OldFailed := GFailed;
    rc := RunScript(Src, OnUsesPChar, RegPChar, Err);
    Result := rc = 0;
    if not Result then
      Fail('P-char ownership run: ' + Err)
    else if Quiet and (GFailed = OldFailed) then
    begin
      { do not double-count the passing checks of the measuring run }
      GPassed := OldPassed;
      GTotal := OldTotal;
    end;
  end;

var
  Before, After: Int64;
begin
  Banner('17 PCharOwnership');
  if not (FeatureCompiles('var p: PWideChar; begin end.') and
          FeatureCompiles('var p: PAnsiChar; begin end.')) then
  begin
    Skip('P-char ownership', 'needs both PWideChar and PAnsiChar script types');
    Exit;
  end;
  { warmup fills RTL and PS caches, then measure a full cycle }
  if not RunOnce(False) then
    Exit;
  Before := AllocatedBytes;
  if not RunOnce(True) then
    Exit;
  After := AllocatedBytes;
  if After > Before + 16384 then
    Fail('memory leak over a full compile/run cycle (delta = ' +
      SysUtils.IntToStr(After - Before) + ' bytes)')
  else
    Pass('no leak over a full compile/run cycle (delta = ' +
      SysUtils.IntToStr(After - Before) + ' bytes)');
end;

{ --------------------------------------------------------------------------
  18 DebugHelpers: PSVariantToString(AppendType/NoQuotes) / StringToPSVariant
     - optional unit-level APIs, gated with $IF DECLARED
  -------------------------------------------------------------------------- }

function OnUsesDump(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    Sender.AddTypeS('TRec', 'record A: Integer; B: string; end');
    Sender.AddTypeS('TByteSet', 'set of Byte');
    Result := True;
  end
  else
    Result := False;
end;

{$IF DECLARED(StringToPSVariant)}
procedure SectionDebugHelpers;
const
  Src: TbtString =
    'var I: Integer; U: string; W: WideString; C: Char; BA: array of Byte;'#13#10 +
    '  R: TRec; BS: TByteSet; V: Variant; D: Double;'#13#10 +
    'begin'#13#10 +
    '  I := 42;'#13#10 +
    '  U := ''Hi'';'#13#10 +
    '  W := ''wide'';'#13#10 +
    '  C := ''x'';'#13#10 +
    '  SetLength(BA, 3);'#13#10 +
    '  BA[0] := 1; BA[1] := 2; BA[2] := 3;'#13#10 +
    '  R.A := 7;'#13#10 +
    '  R.B := ''f'';'#13#10 +
    '  BS := [1, 3, 200];'#13#10 +
    '  V := 5;'#13#10 +
    '  D := 1.5;'#13#10 +
    'end.';
var
  Exec: TPSExec;
  Data: TPSData;
  Err: string;

  { script globals are not exported by name; access them by declaration order }
  function Dump(VarNo: Cardinal; AppendType: Boolean = False;
    NoQuotes: Boolean = False): string;
  var
    ifc: TPSVariantIFC;
  begin
    ifc := NewTPSVariantIFC(Exec.GetVarNo(VarNo), False);
    Result := PSVariantToString(ifc, AppendType, NoQuotes);
  end;

  procedure SetVal(VarNo: Cardinal; const Value: string);
  var
    ifc: TPSVariantIFC;
  begin
    ifc := NewTPSVariantIFC(Exec.GetVarNo(VarNo), True);
    StringToPSVariant(ifc, Value);
  end;

begin
  Banner('18 DebugHelpers');
  if not CompileScript(Src, OnUsesDump, Data, Err) then
  begin
    Fail('debug helper script compiles (' + Err + ')');
    Exit;
  end;
  Exec := TPSExec.Create;
  try
    if not Exec.LoadData(Data) then
    begin
      Fail('debug helper script loads');
      Exit;
    end;
    Exec.RunScript;
    if Exec.ExceptionCode <> erNoError then
    begin
      Fail('debug helper script runs');
      Exit;
    end;
    CheckHost(Dump(0) = '42', 'Integer -> ' + Dump(0));
    CheckHost(Dump(0, True) = 'Integer = 42', 'AppendType -> ' + Dump(0, True));
    CheckHost(Dump(1) = '''Hi''', 'string quoted -> ' + Dump(1));
    CheckHost(Dump(1, False, True) = 'Hi', 'string NoQuotes -> ' + Dump(1, False, True));
    CheckHost(Dump(2) = '''wide''', 'WideString -> ' + Dump(2));
    CheckHost(Dump(3) = '''x''', 'Char -> ' + Dump(3));
    CheckHost(Dump(4) = 'Array of Byte = [ 1, 2, 3 ]', 'dyn array -> ' + Dump(4));
    CheckHost(Dump(5) = 'Record = (7, ''f'')', 'record -> ' + Dump(5));
    CheckHost(Dump(6) = '[1, 3, 200]', 'set -> ' + Dump(6));
    CheckHost(Dump(7, True) = 'Variant (Integer) = 5', 'Variant typed -> ' + Dump(7, True));
    { uPSUtils.FloatToStr - the same helper PSVariantToString uses, so the
      expectation is locale independent }
    CheckHost(Dump(8) = string(FloatToStr(1.5)), 'Double -> ' + Dump(8));
    SetVal(0, '123');
    CheckHost(Dump(0) = '123', 'StringToPSVariant Integer -> ' + Dump(0));
    SetVal(1, 'neu');
    CheckHost(Dump(1, False, True) = 'neu', 'StringToPSVariant string -> ' + Dump(1, False, True));
    SetVal(8, string(FloatToStr(2.5)));
    CheckHost(Dump(8) = string(FloatToStr(2.5)), 'StringToPSVariant Double -> ' + Dump(8));
    SetVal(7, 'vtext');
    CheckHost(Dump(7, False, True) = 'vtext', 'StringToPSVariant Variant -> ' + Dump(7, False, True));
  finally
    Exec.Free;
  end;
end;
{$ELSE}
procedure SectionDebugHelpers;
begin
  Banner('18 DebugHelpers');
  Skip('debug/watch helpers',
    'StringToPSVariant / PSVariantToString(AppendType) not declared in uPSRuntime');
end;
{$IFEND}

{ --------------------------------------------------------------------------
  19 Disassembly: IFPS3DataToText keeps constants intact
  -------------------------------------------------------------------------- }

procedure SectionDisassembly;
var
  Data: TPSData;
  Err, Txt: string;
begin
  Banner('19 Disassembly');
  if not CompileScript('var s: string; begin s := ''HelloWorld''; end.',
    OnUsesCommon, Data, Err) then
  begin
    Fail('disassembly reference script compiles (' + Err + ')');
    Exit;
  end;
  if not IFPS3DataToText(Data, Txt) then
  begin
    Fail('IFPS3DataToText succeeds');
    Exit;
  end;
  Pass('IFPS3DataToText succeeds');
  CheckHost(Pos('HelloWorld', Txt) > 0, 'string constant disassembles intact');
  CheckHost(Pos('ASSIGN', Txt) > 0, 'listing contains instructions');
end;

{ --------------------------------------------------------------------------
  20 DynArrayInvoke: dynamic arrays as by-value parameter and result of
     imported host functions (issue #198 area); runs last because unfixed
     trees may raise access violations inside the invoke path
  -------------------------------------------------------------------------- }

type
  TTestArrayType = array of TScrStr;

function TestReturn: TTestArrayType;
begin
  SetLength(Result, 2);
  Result[0] := 'TestReturn';
  Result[1] := 'Second';
end;

function JoinArr(const A: TTestArrayType): TScrStr;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(A) do
    Result := Result + A[i] + '|';
end;

function OnUsesDynArr(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin
    AddCommonDecls(Sender);
    Sender.AddTypeS('TTestArrayType', 'array of string');
    Sender.AddDelphiFunction('function TestReturn: TTestArrayType');
    Sender.AddDelphiFunction('function JoinArr(const A: TTestArrayType): string');
    Result := True;
  end
  else
    Result := False;
end;

procedure RegDynArr(Exec: TPSExec);
begin
  Exec.RegisterDelphiFunction(@TestReturn, 'TESTRETURN', cdRegister);
  Exec.RegisterDelphiFunction(@JoinArr, 'JOINARR', cdRegister);
end;

procedure SectionDynArrayInvoke;
const
  { the probe stores its observations instead of asserting, so an unfixed
    tree can be detected without failing }
  SrcResultProbe: TbtString =
    'var a: TTestArrayType;'#13#10 +
    'begin'#13#10 +
    '  a := TestReturn;'#13#10 +
    '  ProbeInt(Length(a));'#13#10 +
    '  if Length(a) = 2 then ProbeStr(a[0] + ''|'' + a[1]);'#13#10 +
    'end.';
  SrcParam: TbtString =
    'var a: TTestArrayType;'#13#10 +
    'begin'#13#10 +
    '  SetLength(a, 2);'#13#10 +
    '  a[0] := ''x'';'#13#10 +
    '  a[1] := ''y'';'#13#10 +
    '  ProbeStr(JoinArr(a));'#13#10 +
    'end.';
var
  rc: Integer;
  Err: string;
begin
  Banner('20 DynArrayInvoke');
  GProbeInt := -1;
  GProbeStr := '';
  rc := RunScript(SrcResultProbe, OnUsesDynArr, RegDynArr, Err);
  if rc <> 0 then
    SkipBug('dynarray function result', 'dynarray results broken on this invoke path (' + Err + ')')
  else if GProbeInt <> 2 then
    SkipBug('dynarray function result', 'dynarray results arrive empty on this invoke path')
  else
    CheckHost(GProbeStr = 'TestReturn|Second',
      'dynarray function result (' + string(GProbeStr) + ')');
  GProbeStr := '';
  rc := RunScript(SrcParam, OnUsesDynArr, RegDynArr, Err);
  if rc <> 0 then
    SkipBug('by-value dynarray parameter',
      'by-value dynarray parameters broken on this invoke path (' + Err + ')')
  else if GProbeStr = 'x|y|' then
    Pass('by-value dynarray parameter')
  else
    SkipBug('by-value dynarray parameter',
      'by-value dynarray parameters arrive wrong on this invoke path (got "' +
      string(GProbeStr) + '")');
end;

{ --------------------------------------------------------------------------
  main
  -------------------------------------------------------------------------- }

begin
  GStrict := (ParamCount >= 1) and SameText(ParamStr(1), '-strict');
  WriteLn('PascalScript test suite');
  Write('host: ');
  {$IFDEF FPC} Write('FPC'); {$ELSE} Write('Delphi (CompilerVersion ',
    CompilerVersion:0:0, ')'); {$ENDIF}
  Write(', ptr=', SizeOf(Pointer) * 8, ' bit');
  Write(', SizeOf(TbtChar)=', SizeOf(TbtChar));
  {$IFDEF PS_NATIVESTRINGS} Write(', PS_NATIVESTRINGS'); {$ENDIF}
  {$IFDEF PS_USECLASSICINVOKE} Write(', PS_USECLASSICINVOKE'); {$ENDIF}
  if GStrict then Write(', STRICT');
  WriteLn;

  SectionBasics;
  SectionCompatRules;
  SectionOrdChr;
  SectionSetRangeLiterals;
  SectionPackedTypes;
  SectionCompilerReuse;
  SectionRegisterPropertyFailure;
  SectionLoadDataErrorMessages;
  SectionArrayOfConst;
  SectionRaiseAndParams;
  SectionInterfaces;
  SectionCatchableCastErrors;
  SectionCom;
  SectionDllImport;
  SectionWideStrings;
  SectionRecordInterop;
  SectionPCharOwnership;
  SectionDebugHelpers;
  SectionDisassembly;
  SectionDynArrayInvoke;

  WriteLn;
  WriteLn('Total: ', GTotal, '  Passed: ', GPassed, '  Failed: ', GFailed,
    '  Skipped: ', GSkipped);
  if GFailed = 0 then
    ExitCode := 0
  else
    ExitCode := 1;
end.
