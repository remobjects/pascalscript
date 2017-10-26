unit CompileTestExtended;

interface

uses Classes,
     //TestFramework,
     { Project Units }
     SysUtils,
     //ifps3,
     //ifps3utl,
     //ifpscomp,
     //IFPS3CompExec,
     CompilerTestBase, uPSCompiler, uPSUtils, testregistry;

type
    TCompilerTestExtended = class(TCompilerTestBase)
    private
    protected
      LastResult: string;
      LastResultB: Boolean;
      LastResultI: Longint;
      LastResultD: Double;
      procedure OnCompImport(Sender: TObject; x: TIFPSPascalCompiler); override;
      procedure ResultD(const d: Double);
      procedure ResultS(const s: string);
      procedure ResultB(const val: Boolean);
      procedure ResultI(const val: Longint);
    published
      procedure VariantTest1;
      procedure VariantTest2;
      procedure ArrayTest1;
      procedure CompileDouble;
      procedure ArrayRefCounting;
      procedure ArrayTest;
      procedure FormatTest;
      procedure ExtCharTest;
      procedure StrList;
    end;

implementation


{ TCompilerTestExtended }

procedure TCompilerTestExtended.ArrayRefCounting;
begin
  CompileRun('var e, d: array of string; begin SetArrayLength(d, 1); d[0] := ''123''; e := d;'+
  'setarraylength(d, 0); e[0] := ''321''; d := e;setarraylength(e, 0); d[0] := ''321'';end.');
end;

procedure TCompilerTestExtended.ArrayTest;
begin
  CompileRun('var d,e: array of string; begin SetArrayLength(d, 1); d[0] := ''123''; e := d; setarraylength(e, 0); ResultS(d[0]); end.');
  CheckEquals(LastResult, '123');
end;

procedure TCompilerTestExtended.ArrayTest1;
begin
  CompileRun('type Tstrarr = array of string; var r: TStrArr; i: Longint; Begin'+
  ' setarraylength(r, 3);  r[0] := ''asdf''; r[1] := ''safasf''; ResultS(r[0]+''!''+r[1]); end.');
  CheckEquals('asdf!safasf', LastResult);
end;

procedure TCompilerTestExtended.CompileDouble;
var
  d: double;
begin
  CompileRun('var x: Double; begin x := 1234.54656456; ResultS(Format(''%15.0f'',[2*x]));end.');
  d := 1234.54656456;
  CheckEquals(LastResult, Format('%15.0f',[2*d]));
end;

procedure TCompilerTestExtended.ExtCharTest;
var
  d: double;
begin
  CompileRun('var s:string; i:integer; Res: Double; function Test(i1, i2: Integer): Double; begin Result := Double(i1) / i2; end; '+
  'begin i := ord(''a'');s:=chr(i); i := ord(''a''); s:= chr(i + 1); s := s + chr(i); res := Test(10, 2); ResultS(''Test 1: ''+s+''|Test 2:''+FloatToStr(res));end.');
  d := 10;
  d := d / 2;
  CheckEquals('Test 1: ba|Test 2:'+uPSUtils.FloatToStr(d), LastResult);
end;

procedure TCompilerTestExtended.FormatTest;
begin
  CompileRun('var s: string; begin s := ''TeSTDaTa''; ResultS(''Test: ''+format(''test %s %f'', [s, 2 * PI])); end.');
  CheckEquals('Test: test TeSTDaTa '+SysUtils.Format('%f', [2*pi]), LastResult);

end;

procedure TCompilerTestExtended.OnCompImport(Sender: TObject;
  x: TIFPSPascalCompiler);
begin
  inherited;
  CompExec.AddMethod(Self, @TCompilerTestExtended.ResultS, 'procedure ResultS(const s: string);');
  CompExec.AddMethod(Self, @TCompilerTestExtended.ResultB, 'procedure ResultB(const b: Boolean);');
  CompExec.AddMethod(Self, @TCompilerTestExtended.ResultI, 'procedure ResultI(const I: Longint);');
  CompExec.AddMethod(Self, @TCompilerTestExtended.ResultD, 'procedure ResultD(const D: Double);');
end;

procedure TCompilerTestExtended.ResultB(const val: Boolean);
begin
  LastResultB := Val;
end;

procedure TCompilerTestExtended.ResultD(const d: Double);
begin
  LastResultD := d;
end;

procedure TCompilerTestExtended.ResultI(const val: Integer);
begin
  LastResultI := Val;
end;

procedure TCompilerTestExtended.ResultS(const s: string);
begin
  LastResult := s;
end;

procedure TCompilerTestExtended.StrList;
begin
  CompileRun('var r: TStringList; begin r := TStringList.Create; try  r.Values[''test''] := ''data'';'+
  'ResultS(''Test1: ''+r.Values[''test1'']+#13#10+''Test2: ''+r.Values[''test'']);  finally    r.Free;  end;end.');

  CheckEquals('Test1: '#13#10'Test2: data', Lastresult);
end;

procedure TCompilerTestExtended.VariantTest1;
begin
  CompileRun('var v: variant; Begin v := ''Hey:''; v := v + FloatToStr(Pi); ResultS(v);end.');
  CheckEquals('Hey:'+uPSUtils.FloatToStr(Pi), LastResult);
end;

procedure TCompilerTestExtended.VariantTest2;
begin
  // Does not work in fpc (same code compiled fails too)
//  CompileRun('var  v: variant;  s: string;Begin  v := 123;  s := v;  v := s + ''_test_'';'+
//'  s := v;  v := 123.456;  s := s + v;  v := ''test''  + s; ResultS(v);end.');
//  CheckEquals('test123_test_'+Sysutils.FloatToStr(123.456), LastResult);
end;

initialization
  RegisterTests([TCompilerTestExtended]);

end.
