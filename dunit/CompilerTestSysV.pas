unit CompilerTestSysV;
{ x86_64 System V calling convention, both directions:
  script procedures called as Pascal methods (GetProcAsMethod) and
  native methods called from a script. }

interface

{$IF defined(FPC) and defined(cpux86_64) and defined(unix)}
uses
  SysUtils, Classes, Variants, fpcunit, testregistry,
  uPSCompiler, uPSRuntime, uPSUtils, uPSC_std, uPSR_std;

type
  TSmall = record a, b: Integer; end;
  TTwo = record x, y: Int64; end;
  TDbl = record x, y: Double; end;
  TMix = record i: Int64; d: Double; end;
  TBig = record a, b, c: Int64; end;
  TIA = array of Integer;
  TSA = array of string;
  TCb = function(n: Integer): Integer of object;

  TF1 = function(a: Integer): Integer of object;
  TF7 = function(a, b, c, d, e, f, g: Integer): Integer of object;
  TFI64 = function(a: Int64; b: Cardinal; c: Byte; d: Word; e: Boolean): Int64 of object;
  TFD = function(a: Double; b: Single; c: Double): Double of object;
  TFS1 = function(a: Single): Single of object;
  TF9D = function(a, b, c, d, e, f, g, h, i: Double): Double of object;
  TFMix = function(i: Integer; d: Double; const s: string; x: Single; j: Int64): string of object;
  TFMany = function(a: Integer; b: Double; c: Integer; d: Double; e, f, g, h, i: Integer;
    j, k, l, m, n, o, p: Double; q: string): string of object;
  TFExt = function(a: Extended; b: Integer; c: Extended): Extended of object;
  TFCur = function(a: Currency; b: Integer): Currency of object;
  TFStr = function(const a: string): string of object;
  TFVar = procedure(var a: Integer; var b: string; var c: Double; var d: Int64) of object;
  TFArr = function(n: Integer): TIA of object;
  TFArrP = function(const a: TIA): Integer of object;
  TFVt = function(const a: Variant): Variant of object;
  TFSm = function(const a: TSmall): TSmall of object;
  TFTwo = function(const a: TTwo): TTwo of object;
  TFDbl = function(const a: TDbl): TDbl of object;
  TFMx = function(const a: TMix): TMix of object;
  TFBig = function(const a: TBig): TBig of object;
  TFBigV = function(a: TBig; b: Integer; c: Double): TBig of object;
  TFBig3 = function(x: Integer; a: TBig; b: TBig; y: Integer): Int64 of object;
  TFObj = function(a: TObject): Integer of object;
  TFProc = procedure of object;
  THost = class
    log: string;
    Exec: TPSExec;
    function I7(a, b, c, d, e, f, g: Integer): Integer;
    function Sum9(a, b, c, d, e, f, g, h, i: Double): Double;
    function Mix(i: Integer; d: Double; const s: string; x: Single; j: Int64): string;
    function ExtF(a: Extended; b: Integer; c: Extended): Extended;
    function CurF(a: Currency; b: Integer): Currency;
    function SngF(a: Single): Single;
    function I64(a: Int64): Int64;
    function I64b(p: Integer; a: Int64): string;
    function Str(const a: string): string;
    procedure Vars(var a: Integer; var b: string; var c: Double; var d: Int64);
    function Arr(n: Integer): TIA;
    function Len(const a: TIA): Integer;
    function Strs(const a: TSA): string;
    function Open(const a: array of Integer): Integer;
    function Vt(const a: Variant): Variant;
    function Sm(const a: TSmall): TSmall;
    function Two(const a: TTwo): TTwo;
    function Db(const a: TDbl): TDbl;
    function Bg(const a: TBig): TBig;
    function BgV(a: TBig; b: Integer; c: Double): TBig;
    function Bg3(x: Integer; a, b: TBig; y: Integer): Int64;
    function Fmt(const f: string; const a: array of const): string;
    function Boom(n: Integer): Integer;
    function Call(const name: string; n: Integer): Integer;
    procedure Log1(const s: string);
  end;


  TSysVTest = class(TTestCase)
  private
    x: TPSExec;
    imp: TPSRuntimeClassImporter;
    procedure Load(const src: tbtstring; aOnUses: TPSOnUses);
    procedure Chk(const n: string; ok: Boolean; const v: string = '');
    function Bind(const n: tbtstring): TMethod;
  protected
    procedure TearDown; override;
  published
    procedure ScriptCalledAsMethod;
    procedure NativeCalledFromScript;
  end;
{$IFEND}

implementation

{$IF defined(FPC) and defined(cpux86_64) and defined(unix)}

function THost.I7(a, b, c, d, e, f, g: Integer): Integer;
begin result := a + 10*b + 100*c + 1000*d + 10000*e + 100000*f + 1000000*g; end;
function THost.Sum9(a, b, c, d, e, f, g, h, i: Double): Double;
begin result := a+2*b+3*c+4*d+5*e+6*f+7*g+8*h+9*i; end;
function THost.Mix(i: Integer; d: Double; const s: string; x: Single; j: Int64): string;
begin result := IntToStr(i)+':'+s+':'+IntToStr(j)+':'+FloatToStr(d)+':'+FloatToStr(x); end;
function THost.ExtF(a: Extended; b: Integer; c: Extended): Extended;
begin result := a * b + c; end;
function THost.CurF(a: Currency; b: Integer): Currency;
begin result := a * b; end;
function THost.SngF(a: Single): Single;
begin result := a * 2; end;
function THost.I64(a: Int64): Int64;
begin result := a; end;
function THost.I64b(p: Integer; a: Int64): string;
begin result := IntToStr(a); end;
function THost.Str(const a: string): string;
begin result := a + a; end;
procedure THost.Vars(var a: Integer; var b: string; var c: Double; var d: Int64);
begin a := a + 1; b := b + '!'; c := c * 2; d := d + 5; end;
function THost.Arr(n: Integer): TIA;
var i: Integer;
begin SetLength(result, n); for i := 0 to n - 1 do result[i] := i * i; end;
function THost.Len(const a: TIA): Integer;
begin result := Length(a); end;
function THost.Strs(const a: TSA): string;
var i: Integer;
begin result := ''; for i := 0 to High(a) do result := result + a[i]; end;
function THost.Open(const a: array of Integer): Integer;
var i: Integer;
begin result := 0; for i := 0 to High(a) do result := result + a[i]; end;
function THost.Vt(const a: Variant): Variant;
begin result := a; end;
function THost.Sm(const a: TSmall): TSmall;
begin result.a := a.b; result.b := a.a; end;
function THost.Two(const a: TTwo): TTwo;
begin result.x := a.y; result.y := a.x; end;
function THost.Db(const a: TDbl): TDbl;
begin result.x := a.y; result.y := a.x; end;
function THost.Bg(const a: TBig): TBig;
begin result.a := a.c; result.b := a.b; result.c := a.a; end;
function THost.BgV(a: TBig; b: Integer; c: Double): TBig;
begin result.a := a.c + b; result.b := a.b; result.c := a.a + Trunc(c); end;
function THost.Bg3(x: Integer; a, b: TBig; y: Integer): Int64;
begin result := x + a.c + 10*b.c + 100*y; end;
function THost.Fmt(const f: string; const a: array of const): string;
begin result := Format(f, a); end;
function THost.Boom(n: Integer): Integer;
begin raise Exception.Create('ax host'); end;
function THost.Call(const name: string; n: Integer): Integer;
var m: TMethod;
begin
  m := Exec.GetProcAsMethodN(UTF8Encode(UpperCase(name)));
  result := TCb(m)(n);
end;
procedure THost.Log1(const s: string);
begin log := log + s + ';'; end;

function Dbl(a, b: Double): Boolean;
begin
  Result := Abs(a - b) < 1e-6;
end;

function MethodUses(Sender: TPSPascalCompiler; const Name: tbtstring): Boolean;
begin
  Result := Name = 'SYSTEM';
  if Result then
    SIRegister_Std(Sender);
end;

function HostUses(Sender: TPSPascalCompiler; const Name: tbtstring): Boolean;
begin
  Result := Name = 'SYSTEM';
  if not Result then
    Exit;
  Sender.AddTypeS('TSmall', 'record a, b: Integer; end');
  Sender.AddTypeS('TTwo', 'record x, y: Int64; end');
  Sender.AddTypeS('TDbl', 'record x, y: Double; end');
  Sender.AddTypeS('TBig', 'record a, b, c: Int64; end');
  Sender.AddTypeS('TIA', 'array of Integer');
  Sender.AddTypeS('TSA', 'array of string');
  Sender.AddDelphiFunction('function I7(a, b, c, d, e, f, g: Integer): Integer');
  Sender.AddDelphiFunction('function Sum9(a, b, c, d, e, f, g, h, i: Double): Double');
  Sender.AddDelphiFunction('function Mix(i: Integer; d: Double; const s: string; x: Single; j: Int64): string');
  Sender.AddDelphiFunction('function ExtF(a: Extended; b: Integer; c: Extended): Extended');
  Sender.AddDelphiFunction('function CurF(a: Currency; b: Integer): Currency');
  Sender.AddDelphiFunction('function SngF(a: Single): Single');
  Sender.AddDelphiFunction('function I64(a: Int64): Int64');
  Sender.AddDelphiFunction('function I64b(p: Integer; a: Int64): string');
  Sender.AddDelphiFunction('function Str(const a: string): string');
  Sender.AddDelphiFunction('procedure Vars(var a: Integer; var b: string; var c: Double; var d: Int64)');
  Sender.AddDelphiFunction('function Arr(n: Integer): TIA');
  Sender.AddDelphiFunction('function Len(const a: TIA): Integer');
  Sender.AddDelphiFunction('function Strs(const a: TSA): string');
  Sender.AddDelphiFunction('function Open(const a: array of Integer): Integer');
  Sender.AddDelphiFunction('function Vt(const a: Variant): Variant');
  Sender.AddDelphiFunction('function Sm(const a: TSmall): TSmall');
  Sender.AddDelphiFunction('function Two(const a: TTwo): TTwo');
  Sender.AddDelphiFunction('function Db(const a: TDbl): TDbl');
  Sender.AddDelphiFunction('function Bg(const a: TBig): TBig');
  Sender.AddDelphiFunction('function BgV(a: TBig; b: Integer; c: Double): TBig');
  Sender.AddDelphiFunction('function Bg3(x: Integer; a, b: TBig; y: Integer): Int64');
  Sender.AddDelphiFunction('function Fmt(const f: string; const a: array of const): string');
  Sender.AddDelphiFunction('function Boom(n: Integer): Integer');
  Sender.AddDelphiFunction('function Call(const name: string; n: Integer): Integer');
  Sender.AddDelphiFunction('procedure Log1(const s: string)');
end;

const
  SRC_METHODS =
  'type TSmall = record a, b: Integer; end; TTwo = record x, y: Int64; end;'#10 +
  'TDbl = record x, y: Double; end; TMix = record i: Int64; d: Double; end;'#10 +
  'TBig = record a, b, c: Int64; end; TIA = array of Integer;'#10 +
  'function F1(a: Integer): Integer; begin result := a * 2; end;'#10 +
  'function F7(a, b, c, d, e, f, g: Integer): Integer; begin result := a + 10*b + 100*c + 1000*d + 10000*e + 100000*f + 1000000*g; end;'#10 +
  'function FI64(a: Int64; b: Cardinal; c: Byte; d: Word; e: Boolean): Int64; begin result := a + b + c + d; if e then result := result + 1; end;'#10 +
  'function FD(a: Double; b: Single; c: Double): Double; begin result := a + 10*b + 100*c; end;'#10 +
  'function FS1(a: Single): Single; begin result := a * 2; end;'#10 +
  'function F9D(a, b, c, d, e, f, g, h, i: Double): Double; begin result := a+2*b+3*c+4*d+5*e+6*f+7*g+8*h+9*i; end;'#10 +
  'function FMix(i: Integer; d: Double; const s: string; x: Single; j: Int64): string; begin result := IntToStr(i)+'':''+s+'':''+IntToStr(j)+'':''+FloatToStr(d)+'':''+FloatToStr(x); end;'#10 +
  'function FMany(a: Integer; b: Double; c: Integer; d: Double; e, f, g, h, i: Integer; j, k, l, m, n, o, p: Double; q: string): string; begin result := q+IntToStr(a+c+e+f+g+h+i)+'':''+FloatToStr(b+d+j+k+l+m+n+o+p); end;'#10 +
  'function FExt(a: Extended; b: Integer; c: Extended): Extended; begin result := a * b + c; end;'#10 +
  'function FCur(a: Currency; b: Integer): Currency; begin result := a * b; end;'#10 +
  'function FStr(const a: string): string; begin result := a + a; end;'#10 +
  'procedure FVar(var a: Integer; var b: string; var c: Double; var d: Int64); begin a := a + 1; b := b + ''!''; c := c * 2; d := d + 5; end;'#10 +
  'function FArr(n: Integer): TIA; var i: Integer; begin SetArrayLength(result, n); for i := 0 to n - 1 do result[i] := i * i; end;'#10 +
  'function FArrP(const a: TIA): Integer; var i: Integer; begin result := 0; for i := 0 to GetArrayLength(a) - 1 do result := result + a[i]; end;'#10 +
  'function FVt(const a: Variant): Variant; begin result := a; end;'#10 +
  'function FSm(const a: TSmall): TSmall; begin result.a := a.b; result.b := a.a; end;'#10 +
  'function FTwo(const a: TTwo): TTwo; begin result.x := a.y; result.y := a.x; end;'#10 +
  'function FDbl(const a: TDbl): TDbl; begin result.x := a.y; result.y := a.x; end;'#10 +
  'function FMx(const a: TMix): TMix; begin result.i := a.i + 1; result.d := a.d + 1; end;'#10 +
  'function FBig(const a: TBig): TBig; begin result.a := a.c; result.b := a.b; result.c := a.a; end;'#10 +
  'function FBigV(a: TBig; b: Integer; c: Double): TBig; begin result.a := a.c + b; result.b := a.b; result.c := a.a + Trunc(c); end;'#10 +
  'function FBig3(x: Integer; a: TBig; b: TBig; y: Integer): Int64; begin result := x + a.c + 10*b.c + 100*y; end;'#10 +
  'function FObj(a: TObject): Integer; begin if a = nil then result := 0 else result := 1; end;'#10 +
  'procedure FBoom; var a: array of Integer; begin SetArrayLength(a, 1); a[3] := 1; end;'#10 +
  'begin end.';

  SRC_HOST =
  'procedure Ok(const n: string; b: Boolean); begin if b then Log1(''+'') else Log1(''-''+n); end;'#10 +
  'function Fact(n: Integer): Integer; begin if n <= 1 then result := 1 else result := n * Call(''Fact'', n - 1); end;'#10 +
  'var a: Integer; s: string; d: Double; i: Int64; ia: TIA; sa: TSA; sm1: TSmall; tw: TTwo; db1: TDbl; bg1: TBig; v: Variant; e: Extended; c: Currency;'#10 +
  'begin'#10 +
  ' Ok(''I7'', I7(1,2,3,4,5,6,7) = 7654321);'#10 +
  ' Ok(''Sum9'', Abs(Sum9(1,2,3,4,5,6,7,8,9) - 285) < 0.0001);'#10 +
  ' i := 1000000; i := i * 5000; Ok(''I64'', I64(i) = i); Ok(''I64b'', I64b(1, i) = ''5000000000''); s := Mix(7, 1.5, ''Sample'', 2.5, i); Ok(''Mix'', Copy(s, 1, 19) = ''7:Sample:5000000000'');'#10 +
  ' e := ExtF(1.5, 4, 0.25); Ok(''ExtF'', Abs(e - 6.25) < 0.0001);'#10 +
  ' c := CurF(1.25, 3); Ok(''CurF'', Abs(c - 3.75) < 0.0001);'#10 +
  ' Ok(''SngF'', Abs(SngF(1.25) - 2.5) < 0.0001);'#10 +
  ' Ok(''Str'', Str(''ab'') = ''abab'');'#10 +
  ' a := 1; s := ''x''; d := 1.5; i := 7; Vars(a, s, d, i); Ok(''Vars'', (a = 2) and (s = ''x!'') and (Abs(d - 3) < 0.0001) and (i = 12));'#10 +
  ' ia := Arr(5); Ok(''Arr'', (GetArrayLength(ia) = 5) and (ia[4] = 16) and (Len(ia) = 5));'#10 +
  ' SetArrayLength(sa, 2); sa[0] := ''a''; sa[1] := ''b''; Ok(''Strs'', Strs(sa) = ''ab'');'#10 +
  ' Ok(''Open'', Open([1, 2, 3]) = 6);'#10 +
  ' v := ''t''; v := Vt(v); Ok(''Vt'', v = ''t'');'#10 +
  ' sm1.a := 1; sm1.b := 2; sm1 := Sm(sm1); Ok(''Sm'', (sm1.a = 2) and (sm1.b = 1));'#10 +
  ' tw.x := 1; tw.y := 2; tw := Two(tw); Ok(''Two'', (tw.x = 2) and (tw.y = 1));'#10 +
  ' db1.x := 1.5; db1.y := 2.5; db1 := Db(db1); Ok(''Db'', (Abs(db1.x - 2.5) < 0.0001) and (Abs(db1.y - 1.5) < 0.0001));'#10 +
  ' bg1.a := 1; bg1.b := 2; bg1.c := 3; bg1 := Bg(bg1); Ok(''Bg'', (bg1.a = 3) and (bg1.c = 1));'#10 +
  ' bg1.a := 1; bg1.b := 2; bg1.c := 3; bg1 := BgV(bg1, 10, 7.5); Ok(''BgV'', (bg1.a = 13) and (bg1.b = 2) and (bg1.c = 8));'#10 +
  ' bg1.a := 1; bg1.b := 2; bg1.c := 3; Ok(''Bg3'', Bg3(1, bg1, bg1, 2) = 234); i := 1000000; i := i * 5000; Ok(''IntToStr'', IntToStr(i) = ''5000000000'');'#10 +
  ' Ok(''Fmt'', Fmt(''%s-%d'', [''a'', 5]) = ''a-5'');'#10 +
  ' a := 0; try Boom(1); except a := 1; end; Ok(''Boom'', a = 1);'#10 +
  ' Ok(''Fact'', Fact(10) = 3628800);'#10 +
  'end.';

procedure Reg(x: TPSExec; h: THost);
begin
  x.RegisterDelphiMethod(h, @THost.I7, 'I7', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Sum9, 'SUM9', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Mix, 'MIX', cdRegister);
  x.RegisterDelphiMethod(h, @THost.ExtF, 'EXTF', cdRegister);
  x.RegisterDelphiMethod(h, @THost.CurF, 'CURF', cdRegister);
  x.RegisterDelphiMethod(h, @THost.SngF, 'SNGF', cdRegister);
  x.RegisterDelphiMethod(h, @THost.I64, 'I64', cdRegister);
  x.RegisterDelphiMethod(h, @THost.I64b, 'I64B', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Str, 'STR', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Vars, 'VARS', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Arr, 'ARR', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Len, 'LEN', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Strs, 'STRS', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Open, 'OPEN', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Vt, 'VT', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Sm, 'SM', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Two, 'TWO', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Db, 'DB', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Bg, 'BG', cdRegister);
  x.RegisterDelphiMethod(h, @THost.BgV, 'BGV', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Bg3, 'BG3', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Fmt, 'FMT', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Boom, 'BOOM', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Call, 'CALL', cdRegister);
  x.RegisterDelphiMethod(h, @THost.Log1, 'LOG1', cdRegister);
end;


procedure TSysVTest.Chk(const n: string; ok: Boolean; const v: string);
begin
  AssertTrue(n + ': ' + v, ok);
end;

function TSysVTest.Bind(const n: tbtstring): TMethod;
begin
  Result := x.GetProcAsMethodN(n);
  AssertNotNull(string(n), Result.Code);
end;

procedure TSysVTest.Load(const src: tbtstring; aOnUses: TPSOnUses);
var
  c: TPSPascalCompiler;
  bin: tbtstring;
  i: Integer;
  msg: string;
begin
  c := TPSPascalCompiler.Create;
  try
    c.OnUses := aOnUses;
    if not c.Compile(src) then
    begin
      msg := '';
      for i := 0 to c.MsgCount - 1 do
        msg := msg + string(c.Msg[i].MessageToString) + LineEnding;
      Fail(msg);
    end;
    c.GetOutput(bin);
  finally
    c.Free;
  end;
  AssertTrue('LoadData', x.LoadData(bin));
end;

procedure TSysVTest.TearDown;
begin
  FreeAndNil(x);
  FreeAndNil(imp);
  inherited;
end;

procedure TSysVTest.ScriptCalledAsMethod;
var
  m: TMethod; a: Integer; s: string; d: Double; i64: Int64; e: Extended; c: Currency;
  ia: TIA; v: Variant; sm: TSmall; tw: TTwo; db: TDbl; mx: TMix; bg: TBig; o: TObject; ok: Boolean;
begin
  x := TPSExec.Create;
  imp := TPSRuntimeClassImporter.Create;
  RIRegister_Std(imp);
  RegisterClassLibraryRuntime(x, imp);
  Load(tbtstring(SRC_METHODS), @MethodUses);
  AssertTrue(x.RunScript);
  m := Bind('F1'); Chk('F1', TF1(m)(21) = 42);
  m := Bind('F7'); a := TF7(m)(1, 2, 3, 4, 5, 6, 7); Chk('F7', a = 7654321, IntToStr(a));
  m := Bind('FI64'); i64 := TFI64(m)(5000000000, 4000000000, 200, 60000, True);
  Chk('FI64', i64 = 9000060201, IntToStr(i64));
  m := Bind('FD'); d := TFD(m)(1.5, 2.5, 3.5); Chk('FD', Dbl(d, 376.5), FloatToStr(d));
  m := Bind('FS1'); Chk('FS1', Dbl(TFS1(m)(1.25), 2.5));
  m := Bind('F9D'); d := TF9D(m)(1, 2, 3, 4, 5, 6, 7, 8, 9); Chk('F9D', Dbl(d, 285), FloatToStr(d));
  m := Bind('FMix'); s := TFMix(m)(7, 1.5, 'Sample', 2.5, 5000000000);
  Chk('FMix', Pos('7:Sample:5000000000:', s) = 1, s);
  m := Bind('FMany'); s := TFMany(m)(1, 1, 2, 2, 3, 4, 5, 6, 7, 3, 4, 5, 6, 7, 8, 9, 'a');
  Chk('FMany', Pos('a28:45', s) = 1, s);
  m := Bind('FCur'); c := TFCur(m)(1.25, 3); Chk('FCur', c = 3.75, CurrToStr(c));
  m := Bind('FExt'); e := TFExt(m)(1.5, 4, 0.25); Chk('FExt', Abs(e - 6.25) < 1e-9, FloatToStr(e));
  m := Bind('FStr'); s := TFStr(m)('ab'); Chk('FStr', s = 'abab', s);
  a := 1; s := 'x'; d := 1.5; i64 := 7;
  m := Bind('FVar'); TFVar(m)(a, s, d, i64);
  Chk('FVar', (a = 2) and (s = 'x!') and Dbl(d, 3) and (i64 = 12), s);
  m := Bind('FArr'); ia := TFArr(m)(5); Chk('FArr', (Length(ia) = 5) and (ia[4] = 16));
  m := Bind('FArrP'); Chk('FArrP', TFArrP(m)(ia) = 30);
  m := Bind('FVt'); v := TFVt(m)('test'); Chk('FVt str', VarToStr(v) = 'test', VarToStr(v));
  v := TFVt(m)(12.5); Chk('FVt num', Dbl(v, 12.5));
  sm.a := 1; sm.b := 2; m := Bind('FSm'); sm := TFSm(m)(sm); Chk('FSm', (sm.a = 2) and (sm.b = 1));
  tw.x := 1; tw.y := 5000000000; m := Bind('FTwo'); tw := TFTwo(m)(tw);
  Chk('FTwo', (tw.x = 5000000000) and (tw.y = 1), IntToStr(tw.x) + ',' + IntToStr(tw.y));
  db.x := 1.5; db.y := 2.5; m := Bind('FDbl'); db := TFDbl(m)(db);
  Chk('FDbl', Dbl(db.x, 2.5) and Dbl(db.y, 1.5), FloatToStr(db.x));
  mx.i := 1; mx.d := 1.5; m := Bind('FMx'); mx := TFMx(m)(mx);
  Chk('FMx', (mx.i = 2) and Dbl(mx.d, 2.5), IntToStr(mx.i) + ',' + FloatToStr(mx.d));
  bg.a := 1; bg.b := 2; bg.c := 3; m := Bind('FBig'); bg := TFBig(m)(bg);
  Chk('FBig', (bg.a = 3) and (bg.b = 2) and (bg.c = 1), IntToStr(bg.a));
  bg.a := 1; bg.b := 2; bg.c := 3; m := Bind('FBigV'); bg := TFBigV(m)(bg, 10, 7.5);
  Chk('FBigV', (bg.a = 13) and (bg.b = 2) and (bg.c = 8), IntToStr(bg.a));
  bg.a := 1; bg.b := 2; bg.c := 3; m := Bind('FBig3'); i64 := TFBig3(m)(1, bg, bg, 2);
  Chk('FBig3', i64 = 234, IntToStr(i64));
  o := TObject.Create; m := Bind('FObj'); Chk('FObj', (TFObj(m)(o) = 1) and (TFObj(m)(nil) = 0)); o.Free;
  m := Bind('FBoom'); ok := false;
  try
    TFProc(m)();
  except
    on E: Exception do ok := true;
  end;
  Chk('exception reaches Pascal', ok);
end;

procedure TSysVTest.NativeCalledFromScript;
var
  h: THost;
begin
  x := TPSExec.Create;
  h := THost.Create;
  try
    h.Exec := x;
    Reg(x, h);
    Load(tbtstring(SRC_HOST), @HostUses);
    AssertTrue(string(PSErrorToString(x.ExceptionCode, x.ExceptionString)), x.RunScript);
    AssertEquals('all checks passed', 0, Pos('-', h.log));
    AssertTrue(h.log, Length(h.log) > 20);
  finally
    h.Free;
  end;
end;

initialization
  RegisterTest(TSysVTest);
{$IFEND}
end.
