unit CompilerTestSimple;

interface

uses Classes,
     //TestFramework,
     //{ Project Units }
     //ifps3,
     //ifpscomp,
     //IFPS3CompExec,
     CompilerTestBase, uPSCompiler, testregistry;

type
    TCompilerTestSimple = class(TCompilerTestBase)
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
      procedure EmptyScript;
      procedure VarDecl;
      procedure ForLoop;
      procedure WhileLoop;
      procedure CaseStatement;
      procedure RepeatLoop;
      procedure IfTest;
      procedure IfTest2;
      procedure FunctionTest;
      procedure CreateObject;
      procedure CharTest;
      procedure CharTest2;
      procedure StrConcat;
      procedure StringCharTest;
      procedure CastDoubleTest;
      procedure ConstTest;
      procedure CheckArrayProperties;
    end;

implementation

uses StrUtils, SysUtils, Math, Dialogs;
//,
//    { Project Units }
//    ifpiir_std,
//    ifpii_std,
//    ifpiir_stdctrls,
//    ifpii_stdctrls,
//    ifpiir_forms,
//    ifpii_forms,
//    ifpii_graphics,
//    ifpii_controls,
//    ifpii_classes,
//    ifpiir_graphics,
//    ifpiir_controls,
//    ifpiir_classes;

{ TCompilerTestSimple }


procedure TCompilerTestSimple.OnCompImport(Sender: TObject;
  x: TIFPSPascalCompiler);
begin
  inherited;
  CompExec.AddMethod(Self, @TCompilerTestSimple.ResultS, 'procedure ResultS(const s: string);');
  CompExec.AddMethod(Self, @TCompilerTestSimple.ResultB, 'procedure ResultB(const b: Boolean);');
  CompExec.AddMethod(Self, @TCompilerTestSimple.ResultI, 'procedure ResultI(const I: Longint);');
  CompExec.AddMethod(Self, @TCompilerTestSimple.ResultD, 'procedure ResultD(const D: Double);');
end;                  


procedure TCompilerTestSimple.ResultS(const s: string);
begin
  LastResult := s;
end;


const
  CaseScript =
  'Program Test; begin case %d of 0: ResultS(''0'');1: ResultS(''1'');2: ResultS(''2'');'+
  '3: ResultS(''3'');else Results(''e''); end;end.';

procedure TCompilerTestSimple.CaseStatement;
begin
  CompileRun(Format(CaseScript, [-10]));
  CheckEquals('e', LastResult, last_script);
  CompileRun(Format(CaseScript, [0]));
  CheckEquals('0', LastResult, last_script);
  CompileRun(Format(CaseScript, [2]));
  CheckEquals('2', LastResult, last_script);
  CompileRun(Format(CaseScript, [3]));
  CheckEquals('3', LastResult, last_script);
  CompileRun(Format(CaseScript, [4]));
  CheckEquals('e', LastResult, last_script);
end;

procedure TCompilerTestSimple.EmptyScript;
begin
  CompileRun('Program Test; begin end.');
  CompileRun('begin end.');
end;

procedure TCompilerTestSimple.ForLoop;
begin
  CompileRun('var i, j: Integer; begin for i := 0 to 100 do j := j + i; ResultI(j); end.');
  CheckEquals(5050, LastResultI, last_script);
  CompileRun('var i, j: Integer; begin j := 1; for i := 1 to 10 do j := j * i; ResultI(j); end.');
  CheckEquals(3628800, LastResultI, last_script);
end;

procedure TCompilerTestSimple.FunctionTest;
begin
  CompileRun('function test: string; begin Result := ''Func_Res''; end; begin ResultS(test+''+test''); end.');
  CheckEquals('Func_Res+test', LastResult, last_script);
end;

procedure TCompilerTestSimple.IfTest;
begin
  CompileRun('begin if true then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);
  CompileRun('begin if false then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);

  CompileRun('begin if not true then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);
  CompileRun('begin if not false then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);

  CompileRun('begin if not (true) then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);
  CompileRun('begin if not (false) then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);

  CompileRun('begin if (not true) then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);
  CompileRun('begin if (not false) then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);

  CompileRun('begin if true and true then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);
  CompileRun('begin if true and false then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);
  CompileRun('begin if false and true then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);
  CompileRun('begin if false and false then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);

  CompileRun('begin if true or true then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);
  CompileRun('begin if true or false then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);
  CompileRun('begin if false or true then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);
  CompileRun('begin if false or false then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);

  CompileRun('begin if true xor true then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);
  CompileRun('begin if true xor false then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);
  CompileRun('begin if false xor true then ResultB(True) else ResultB(False); end.');
  CheckEquals(true, LastResultB, last_script);
  CompileRun('begin if false xor false then ResultB(True) else ResultB(False); end.');
  CheckEquals(False, LastResultB, last_script);
end;



procedure TCompilerTestSimple.RepeatLoop;
begin
  CompileRun('var i: Integer; begin Repeat i := i + 8; until i mod 7 = 6; ResultI(I); end.');
  CheckEquals(48, LastResultI, last_script);
end;


procedure TCompilerTestSimple.WhileLoop;
begin
  CompileRun('var i, j: Integer; begin while i < 10 do begin j := j + 1; i := j; end; ResultI(i+j); end.');
  CheckEquals(20, LastResultI, last_script);
end;

procedure TCompilerTestSimple.CharTest;
begin
  CompileRun('var s: string; begin s := ''''+chr(32) + chr(45) + chr(45); ResultS(s); end.');
  CheckEquals(#32#45#45, LastResult, last_script);
  CompileRun('var s: string; begin s := chr(32) + chr(45) + chr(45); ResultS(s); end.');
  CheckEquals(#32#45#45, LastResult, last_script);
end;

procedure TCompilerTestSimple.StringCharTest;
begin
  CompileRun('var s: string; begin s:=''123456789''; s[1]:=s[2]; ResultS(s); end.');
  CheckEquals('223456789', LastResult, last_script);
end;

procedure TCompilerTestSimple.CastDoubleTest;
begin
  CompileRun('function Test(i1, i2: Integer): Double; begin Result := Double(i1) / i2; end; var Res: Double; begin res := Test(10, 2); ResultD(Res); end.');
  CheckEquals(10/2, LastResultD, 0.000001, last_script);
end;

procedure TCompilerTestSimple.ResultB(const val: Boolean);
begin
  LastResultB := Val;
end;

procedure TCompilerTestSimple.ResultI(const val: Integer);
begin
  LastResultI := Val;
end;

procedure TCompilerTestSimple.ResultD(const d: Double);
begin
  LastResultD := D;
end;

procedure TCompilerTestSimple.ConstTest;
begin
  CompileRun('const a = 10; b = a * 3; begin ResultI(b);end.');
  CheckEquals(30, LastResultI, last_script);
  CompileRun('const a = (1+4)*6+1; begin ResultI(a);end.');
  CheckEquals(31, LastResultI, last_script);
  CompileRun('const a = 2 * -(3 + 4) + (5 + 6) mod 5; begin ResultI(a);end.');
  CheckEquals(-13, LastResultI, last_script);
  CompileRun('const b = ''a''+''b''+''c'';a = b = ''a''+''b''+''c'';begin ResultB(a);end.');
  CheckEquals(true, LastResultB, last_script);
end;

const
  IfTest2Script = 'var  backclicked: Boolean;  curpage: integer;  wpselectdir: integer;'+
'procedure Beep(i: Longint); begin if i = 2 then RaiseException(erCustomError, ''currpage <> '+
'wpSelectDir''); if i = 3 then RaiseException(erCustomError, ''not False and False'');end;'+
'Begin backclicked := false; curpage := 0; wpSelectDir := 5; if not BackClicked then Beep(1);'+
'if CurPage = wpSelectDir then Beep(2); if not BackClicked and (CurPage = wpSelectDir) then Beep(3);End.';


procedure TCompilerTestSimple.IfTest2;
begin
  CompileRun(IfTest2Script);
  CompileRun('Program IFSTest; type TShiftStates = (ssCtrl, ssShift); TShiftState = set of TShiftStates; var shift: TShiftState; Begin if shift = [ssCtrl, ssShift] then End.');
end;

procedure TCompilerTestSimple.checkArrayProperties;
begin
  CompileRun('var r: TStringList; begin r := TStringList.Create; r.Values[''test''] := ''data''; ResultS(r.text); r.Free;end.');
  CheckEquals('test=data'+LineEnding, LastResult);
end;

procedure TCompilerTestSimple.VarDecl;
begin
  CompileRun('Program test; var i: Longint; begin end.');

end;

procedure TCompilerTestSimple.StrConcat;
begin
  CompileRun('var s: string; begin s := ''test''; s := s + ''TESTED''; ResultS(s); End.');
  CheckEquals('testTESTED', LastResult);
end;

procedure TCompilerTestSimple.CreateObject;
begin
  CompileRun('var r: TObject; begin r := TObject.Create; r.Free; end.');
end;

procedure TCompilerTestSimple.CharTest2;
begin
CompileRun('var s:string; i:integer; begin i := ord(''a''); s:=chr(i); '+
  'i := ord(''a'');s:=chr(i + 1); end.');

end;

initialization
  RegisterTests([TCompilerTestSimple]);

end.
