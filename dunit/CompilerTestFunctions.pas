
unit CompilerTestFunctions;

{$IFDEF fpc}
  {$IFnDEF cpu86}         // Has MyAllMethodsHandler
    {$define empty_methods_handler}
  {$ENDIF}
{$ENDIF}

{$IFnDEF empty_methods_handler}
{$ENDIF}

interface

uses Classes,
     //TestFramework,
     //{ Project Units }
     //ifps3,
     //ifpscomp,
     //ifps3utl,
     //IFPS3CompExec,
     CompilerTestBase, uPSComponent, testregistry;

type

    { TCompilerTestFunctions }

    TCompilerTestFunctions = class(TCompilerTestBase)
    private
      function MethodTest(const s: string): string;
      procedure AssertS(s1, s2: string);
      procedure AssertI(s1, s2: Longint);
      procedure AssertE(s1, s2: extended);
    protected
        procedure OnCompile(Sender: TPSScript); override;
        procedure OnExecute(Sender: TPSScript); override;
    published
        procedure CallProcedure;
        procedure CallMethod;
{$IFnDEF empty_methods_handler}
        procedure CallScriptFunctionAsMethod;
{$ENDIF}
        procedure WideStringFunctions;
        procedure CheckConsts;
    end;

    {
    TVariablesTest = class(TCompilerTest)
    private
    published
    end; }

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


{ TFunctionsTest }

var
    vResultS: string;
    vResultSw: WideString;
    aWideString: WideString;

procedure ResultS(const s: string);
begin
    vResultS := s;
end;

procedure ResultSw(const s: WideString);
begin
    vResultSw := s;
end;

function getWideString(): WideString;
begin
    Result := aWideString;
end;


function MyWide2String(s: WideString): String;
begin
    Result := s + '+Wide2String';
end;

function MyString2Wide(s: String): WideString;
begin
    Result := s + '+String2Wide';
end;

function MyWide2Wide(s: WideString): WideString;
begin
    Result := s + '+Wide2Wide';
end;

procedure TCompilerTestFunctions.OnCompile(Sender: TPSScript);
begin
    inherited;
    Sender.AddMethod(Self, @TCompilerTestFunctions.AssertS, 'procedure AssertS(s1, s2: string);');
    Sender.AddMethod(Self, @TCompilerTestFunctions.AssertI, 'procedure AssertI(s1, s2: Longint);');
    Sender.AddMethod(Self, @TCompilerTestFunctions.AssertE, 'procedure AssertE(s1, s2: Extended);');


    Sender.AddFunction(@ResultS, 'procedure ResultS(s: string);');
    Sender.AddFunction(@ResultSw, 'procedure ResultSw(s: WideString);');
    Sender.AddFunction(@MyString2Wide, 'function MyString2Wide(s: String): Widestring;');
    Sender.AddFunction(@MyWide2String, 'function MyWide2String(s: Widestring): string;');
    Sender.AddFunction(@MyWide2Wide, 'function MyWide2Wide(s: Widestring): Widestring;');
    Sender.AddFunction(@getWideString, 'function getWideString(): Widestring;');
    Sender.AddMethod(Self, @TCompilerTestFunctions.MethodTest, 'function MethodTest(s: string): string');
    //Sender.AddRegisteredVariable('aWideString', 'WideString');
end;

procedure TCompilerTestFunctions.OnExecute(Sender: TPSScript);
begin
    inherited;
    //Sender.SetVarToInstance('aWideString', aWideString);
end;

procedure TCompilerTestFunctions.CallProcedure;
begin
    CompileRun('begin ResultS(''hello''); end.');
    CheckEquals('hello', vResultS, last_script);
end;


procedure TCompilerTestFunctions.WideStringFunctions;
begin
    CompileRun('begin ResultS(MyString2Wide(''hello'')); end.');
    CheckEquals('hello+String2Wide', vResultS, last_script);

    CompileRun('begin ResultS(MyWide2String(''hello'')); end.');
    CheckEquals('hello+Wide2String', vResultS, last_script);

    CompileRun('begin ResultS(MyWide2Wide(''hello'')); end.');
    CheckEquals('hello+Wide2Wide', vResultS, last_script);

    aWideString := 'Unicode=[' + WideChar($1F04) + WideChar($4004) + ']';
    CompileRun('begin ResultSw(getWideString()); end.');
    CheckEquals(aWideString, vResultSw, last_script);
end;

function TCompilerTestFunctions.MethodTest(const s: string): string;
begin
  Result := 'Test+'+s;
end;

procedure TCompilerTestFunctions.CallMethod;
begin
    CompileRun('begin ResultS(MethodTest(''hello'')); end.');
    CheckEquals('Test+hello', vResultS, last_script);
end;

{$IFnDEF empty_methods_handler}
type
  TTestMethod = function (s: string): string of object;

procedure TCompilerTestFunctions.CallScriptFunctionAsMethod;
var
  Meth: TTestMethod;
begin
  Compile('function Test(s:string): string; begin Result := ''Test Results: ''+s;end; begin end.');
  Meth := TTestMethod(CompExec.GetProcMethod('Test'));
  Check(@Meth <> nil, 'Unable to find function');
  CheckEquals('Test Results: INDATA', Meth('INDATA'));
end;
{$ENDIF}


procedure TCompilerTestFunctions.CheckConsts;
begin
  CompileRun('const s1 = ''test''; s2 = ''data: ''+s1; s3 = s2 + ''324''; i1 = 123; i2 = i1+123; '#13#10+
  'i3 = 123 + i2; r1 = 123.0; r2 = 4123; r3 = r1 + r2; r4 = 2344.4 + r1; r5 = 23 + r1; r6 = r1 + 2344.4; '#13#10+
  'r7 = r6 + 23; begin AssertS(s1, ''test''); AssertS(s2, ''data: test''); AssertS(s3, ''data: test324'');'#13#10+
  'AssertI(i1, 123);AssertI(i2, 246);AssertI(i3, 369);AssertE(r1, 123);AssertE(r1, 123.0);AssertE(r2, 4123);'#13#10+
  'AssertE(r2, 4123.0);AssertE(r3, 4123 + 123);AssertE(r3, 4246);AssertE(r4, 2344.4 + 123);AssertE(r4, 2467.4);'#13#10+
  'AssertE(r5, 123 + 23);AssertE(r5, 123.0 + 23.0);AssertE(r5, 146.0);AssertE(r6, 2344.4 + 123);AssertE(r6, 2467.4);'#13#10+
  'AssertE(r7, 2467.4 + 23);AssertE(r7, 2490.4);end.');

end;

procedure TCompilerTestFunctions.AssertE(s1, s2: extended);
begin
  if abs(s1 - s2) > 0.0001 then
    raise Exception.Create('AssertE: '+floattostr(s1)+' '+floattostr(s2));
end;

procedure TCompilerTestFunctions.AssertI(s1, s2: Longint);
begin
  if s1 <> s2 then
    raise Exception.Create('AssertI: '+inttostr(s1)+' '+inttostr(s2));
end;

procedure TCompilerTestFunctions.AssertS(s1, s2: string);
begin
  if s1 <> s2 then
    raise Exception.Create('AssertS: '+s1+' '+s2);
end;

initialization
  RegisterTests([ TCompilerTestFunctions ]);

end.
