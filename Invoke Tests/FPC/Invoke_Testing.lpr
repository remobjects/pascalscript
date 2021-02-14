program Invoke_Testing;

{$mode Delphi}{$H+}      //objfpc
//{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  {$IF DEFINED(MSWINDOWS)}
  Windows,
  {$ENDIF}
  Variants,
  uPSComponent, uPSCompiler, uPSRuntime,  {Pascal Script}
  Classes, SysUtils, CustApp
  { you can add units after this };


type
  TPSScriptClass = class
  private
  public
    constructor Create;
    procedure IFPS3ClassesPlugin1ExecImport(Sender : TObject; Exec : TPSExec; x : TPSRuntimeClassImporter);
    procedure PSScriptCompile(Sender : TPSScript);
    procedure PSScriptExecute(Sender: TPSScript);
    procedure PSScriptAfterExecute(Sender: TPSScript);
    procedure IFPS3ClassesPlugin1CompImport(Sender : TObject;
       x : TIFPSPascalcompiler);
    procedure OutputMessages;

    procedure ExecuteScript;

  end;

var PSScript : TPSScriptDebugger;

const TestScript =
'PROGRAM Castlvling;'+sLineBreak+
'var'+sLineBreak+
'CardinalDynArray : TCardinalDynArray;'+sLineBreak+
'ch : String;'+sLineBreak+
'MyExcel : IUnknown;'+sLineBreak+
'PathArray : TPathArray;'+sLineBreak+
'bbb : Integer;'+sLineBreak+
'LandRecord : TMapCell;'+sLineBreak+
'zz : TClilocRec;'+sLineBreak+
'IsOK, TestBool :Boolean;'+sLineBreak+
'I64 : Int64;'+sLineBreak+
'X, Y : Integer;'+sLineBreak+
'SetRes : TTileDataFlagSet;'+sLineBreak+
'MapCellArray : TMapCellArray;'+sLineBreak+
'MapCellDynArray : TMapCellDynArray;'+sLineBreak+
'VariantRes : Variant;'+sLineBreak+
'BigRec : TEndGroup;'+sLineBreak+
'TestWord : Word;'+sLineBreak+
'DelphiCallBackProc : tDelphiCallBackProc;'+sLineBreak+
'//  ScriptCallBackProc : tScriptCallBackProc;'+sLineBreak+
''+sLineBreak+
'function CallRes ( Condition : boolean) :String;'+sLineBreak+
'begin'+sLineBreak+
'if Condition then Result := ''OK'' else Result := ''ERROR'';'+sLineBreak+
'end;'+sLineBreak+
''+sLineBreak+
'function CBf(x : Integer; y : Integer) : Integer;'+sLineBreak+
'begin'+sLineBreak+
'IsOK := (X = $250) and (Y = $251);'+sLineBreak+
'AddToLog('' Script callback method called: '' + CallRes(IsOk));'+sLineBreak+
'Result := 987;'+sLineBreak+
'end;'+sLineBreak+
''+sLineBreak+
'BEGIN'+sLineBreak+
'CardinalDynArray := GetDynArrayReturn;'+sLineBreak+
''+sLineBreak+
'AddToLog(''Dyn Array in return(without params): '''+sLineBreak+
'+ CallRes((CardinalDynArray[1] = 999) and (CardinalDynArray[6] = 777)));'+sLineBreak+
''+sLineBreak+
'LandRecord := GetMapCell2;'+sLineBreak+
'AddToLog(''Record in return(without params): '''+sLineBreak+
'+ CallRes((LandRecord.Tile = 2457) and (LandRecord.Z = 3)));'+sLineBreak+
''+sLineBreak+
'CardinalDynArray := [111,432,669,545];'+sLineBreak+
'SetLength(zz.Items,2);'+sLineBreak+
''+sLineBreak+
'zz.Items[0].ClilocID := 99;'+sLineBreak+
'SetLength(zz.Items[0].Params,1);'+sLineBreak+
'zz.Items[0].Params[0] := ''aa'';'+sLineBreak+
''+sLineBreak+
'zz.Items[1].ClilocID := 101;'+sLineBreak+
'SetLength(zz.Items[1].Params,1);'+sLineBreak+
'zz.Items[1].Params[0] := ''bb'';'+sLineBreak+
''+sLineBreak+
'bbb := 678;'+sLineBreak+
'ch := ''Test'';'+sLineBreak+
''+sLineBreak+
'LandRecord.z := 0;'+sLineBreak+
'LandRecord.Tile := 0;'+sLineBreak+
'LandRecord := GetRecordWithParams([33,66,99],bbb,ch,CardinalDynArray,zz);'+sLineBreak+
''+sLineBreak+
'IsOK := (bbb = 776) and (ch = ''Test'')'+sLineBreak+
'and ( (Length(CardinalDynArray) = 4) and (CardinalDynArray[0]=111) and (CardinalDynArray[1]=432)'+sLineBreak+
'and (CardinalDynArray[2]=669) and (CardinalDynArray[3]=545) )'+sLineBreak+
'and ( (Length(zz.Items) = 3) and (zz.Items[0].Params[0]=''aa'')'+sLineBreak+
'and (zz.Items[1].ClilocID=123) and (zz.Items[1].Params[0]=''bb'')'+sLineBreak+
'and (zz.Items[2].ClilocID=141) and (zz.Items[2].Params[0]=''cc''))'+sLineBreak+
'and ( (LandRecord.Tile = 139) and (LandRecord.Z = 90) )'+sLineBreak+
';'+sLineBreak+
''+sLineBreak+
'AddToLog(''Transfer BACK from Delphi function (openarr, var Integer, String, dynarray, var record) with returned record): '''+sLineBreak+
'+ CallRes(IsOK));'+sLineBreak+
'//'+sLineBreak+
''+sLineBreak+
'bbb := 789;'+sLineBreak+
'MapCellArray[0].Tile:=12;'+sLineBreak+
'MapCellArray[1].Tile:=23;'+sLineBreak+
'MapCellArray[2].Tile:=34;'+sLineBreak+
'MapCellArray[3].Tile:=45;'+sLineBreak+
'MapCellArray[0].Z:=67;'+sLineBreak+
'MapCellArray[1].Z:=68;'+sLineBreak+
'MapCellArray[2].Z:=69;'+sLineBreak+
'MapCellArray[3].Z:=70;'+sLineBreak+
'SetLength(MapCellDynArray,3);'+sLineBreak+
'MapCellDynArray[0].Tile:=232;'+sLineBreak+
'MapCellDynArray[0].Z:=51;'+sLineBreak+
'MapCellDynArray[1].Tile:=233;'+sLineBreak+
'MapCellDynArray[1].Z:=52;'+sLineBreak+
'MapCellDynArray[2].Tile:=234;'+sLineBreak+
'MapCellDynArray[2].Z:=53;'+sLineBreak+
'MyExcel := nil;'+sLineBreak+
''+sLineBreak+
''+sLineBreak+
'SetRes := GetSetWithParams(MapCellArray, bbb, MapCellDynArray, MyExcel);'+sLineBreak+
''+sLineBreak+
'IsOK := (bbb = 887) and (MyExcel <>  NIL)'+sLineBreak+
'and ( (Length(MapCellDynArray) = 3) and (MapCellDynArray[0].Tile=232) and (MapCellDynArray[0].Z=51)'+sLineBreak+
'and (MapCellDynArray[1].Tile=233) and (MapCellDynArray[1].Z=52) and (MapCellDynArray[2].Tile=234) and (MapCellDynArray[2].Z=53)  )'+sLineBreak+
'and (SetRes = [tsfTransparent, tsfDamaging, tlfSurface, tlfUnknown3]);'+sLineBreak+
''+sLineBreak+
''+sLineBreak+
'AddToLog(''Transfer BACK from Delphi function (records arr, var Integer, records dynarray, interface) with returned set: '''+sLineBreak+
'+ CallRes(IsOK));'+sLineBreak+
''+sLineBreak+
'//  AddToLog(MyExcel.Name);'+sLineBreak+
''+sLineBreak+
'//  Exit;'+sLineBreak+
'SetRes := [tsfWet, tlfPrefixAn];'+sLineBreak+
''+sLineBreak+
'VariantRes := GetVariantWithParams(SetRes);'+sLineBreak+
''+sLineBreak+
'IsOK := (VariantRes = ''test84'')  and (SetRes = [tsfWet, tlfPrefixAn]);'+sLineBreak+
''+sLineBreak+
''+sLineBreak+
'AddToLog(''Transfer BACK from Delphi function (set) with returned Variant): '''+sLineBreak+
'+ CallRes(IsOK));'+sLineBreak+
''+sLineBreak+
'I64 := 339993232;'+sLineBreak+
'X := 444;'+sLineBreak+
'Y := 555;'+sLineBreak+
''+sLineBreak+
'BigRec.groupnumber := 39;'+sLineBreak+
'BigRec.Page := 93;'+sLineBreak+
'BigRec.ElemNum := 422;'+sLineBreak+
''+sLineBreak+
'DelphiCallBackProc := GetProcWithBigRecParam(I64, BigRec, X, Y);'+sLineBreak+
''+sLineBreak+
'IsOK := (I64 = 339993232-999);'+sLineBreak+
'AddToLog(''Transfer BACK from Delphi function (var int64, bigrec, int, int) with returned tmethod) '''+sLineBreak+
'+ CallRes(IsOK));'+sLineBreak+
''+sLineBreak+
'AddToLog(''Try to exec Delphi callback mehod from script...'');'+sLineBreak+
'DelphiCallBackProc(X, Y);'+sLineBreak+
'IsOK := (x = 600) and (y = 800);'+sLineBreak+
''+sLineBreak+
'AddToLog('' Delphi callback method called from script, result: '' + CallRes(IsOk));'+sLineBreak+
''+sLineBreak+
''+sLineBreak+
'AddToLog(''Try to exec script callback mehod from Delphi...'');'+sLineBreak+
''+sLineBreak+
'X := 444;'+sLineBreak+
'Y := 555;'+sLineBreak+
'CallCB(@CBf,X,Y);'+sLineBreak+
''+sLineBreak+
'TestWord := 155;'+sLineBreak+
'TestBool := True;'+sLineBreak+
'X := 1;'+sLineBreak+
'Y := 20;'+sLineBreak+
'PathArray := GetPathArray9(TestWord, TestBool, X, Y) ;'+sLineBreak+
'IsOK := (TestBool = False) and (y = -50)'+sLineBreak+
'and (PathArray[0].X = 230) and (PathArray[0].Y = 220) and (PathArray[0].Z = 40)'+sLineBreak+
'and (PathArray[11].X = 130) and (PathArray[11].Y = 120) and (PathArray[11].Z = 30)'+sLineBreak+
'and (PathArray[15].X = 180) and (PathArray[15].Y = 170) and (PathArray[15].Z = 20);'+sLineBreak+
''+sLineBreak+
'AddToLog('' Transfer BACK from Delphi function (word, var boolean, int, var int) with returned static array): '''+sLineBreak+
'+ CallRes(IsOK));'+sLineBreak+
''+sLineBreak+
'end.';


procedure AddToLog(Line : String);
begin
  WriteLn(Line);
  {$IF NOT DEFINED(MSWINDOWS)}
  Log.d(Line);
  {$ELSE}
  OutputDebugString(PChar(Line));
  {$ENDIF}
end;

{$Region 'Test Methods'}
type
TMapCell = packed record
  Tile : Word;
  Z : ShortInt;
end;
TCardinalDynArray = array of Cardinal;
TClilocItemRec = packed record
  ClilocID : Cardinal;
  Params : array of String;
end;

TClilocRec = packed record
  Count : Cardinal;
  Items : array of TClilocItemRec;
end;

TTileDataFlags = (tsfBackground, tsfWeapon, tsfTransparent, tsfTranslucent, tsfWall, tsfDamaging, tsfImpassable, tsfWet, tsfUnknown, tsfSurface, tsfBridge, tsfGeneric, tsfWindow, tsfNoShoot, tsfPrefixA, tsfPrefixAn, tsfInternal, tsfFoliage, tsfPartialHue, tsfUnknown1, tsfMap, tsfContainer, tsfWearable, tsfLightSource, tsfAnimated, tsfNoDiagonal, tsfUnknown2, tsfArmor, tsfRoof, tsfDoor, tsfStairBack, tsfStairRight, tlfTranslucent, tlfWall, tlfDamaging, tlfImpassable, tlfWet, tlfSurface, tlfBridge, tlfPrefixA, tlfPrefixAn, tlfInternal, tlfMap, tlfUnknown3);
TTileDataFlagSet = set of TTileDataFlags;

TMapCellArray = array[0..4] of TMapCell;
TMapCellDynArray =array of TMapCell;

TEndGroup = packed record
  groupnumber : Integer;
  Page : Integer;
  ElemNum : Integer;
end;

TMyPoint = packed record
  X : Word;
  Y : Word;
  Z : ShortInt;
end;
TPathArray = Array[0..999] of TMyPoint;


function _GetMapCell2 : TMapCell;
begin
  Result.Z := SizeOf(TMapCell);
  Result.Tile := 2457;
end;


function _GetDynArrayReturn : TCardinalDynArray;
begin
  SetLength(Result,12);
  Result[1] := 999;
  Result[6] := 777;
end;

function CallRes ( Condition : boolean) :String;
begin
  if Condition then Result := 'OK' else Result := 'ERROR';
end;

function _GetRecordWithParams(Params : array of Word; var a : Integer; b : String; d : TCardinalDynArray; var z : TClilocRec) : TMapCell;
var CR : Boolean;
begin
  CR := (a = 678) and (b = 'Test')
         and ( (Length(Params) = 3) and (Params[0]=33) and (Params[1]=66) and (Params[2]=99) )
         and ( (Length(d) = 4) and (d[0]=111) and (d[1]=432) and (d[2]=669) and (d[3]=545) )
         and ( (Length(z.Items) = 2) and (z.Items[0].Params[0]='aa') and (z.Items[1].ClilocID=101) and (z.Items[1].Params[0]='bb'))
         ;
  AddToLog('Transfer TO Delphi function (openarr, var Integer, String, dynarray, var record) with returned record): '
                      + CallRes(CR));

  a := 776;
  SetLength(z.Items,3);

  z.Items[0].ClilocID := 88;
  SetLength(z.Items[0].Params,1);
  z.Items[0].Params[0] := 'aa';

  z.Items[1].ClilocID := 123;
  SetLength(z.Items[1].Params,1);
  z.Items[1].Params[0] := 'bb';

  z.Items[2].ClilocID := 141;
  SetLength(z.Items[2].Params,1);
  z.Items[2].Params[0] := 'cc';

  Result.Z := 90;
  Result.Tile := 139;
end;


function _GetSetWithParams(Params : TMapCellArray; var a : Integer; b : TMapCellDynArray; var d : IUnknown) : TTileDataFlagSet;
var CR : Boolean;
    t: TInterfacedObject;
begin
  CR := (a = 789) and (not VarIsNull(d)) and (not VarIsEmpty(d))
         and ( (Params[0].Tile=12) and (Params[1].Tile=23) and (Params[2].Tile=34)  and (Params[3].Tile=45) and
               (Params[0].Z=67) and (Params[1].Z=68) and (Params[2].Z=69)  and (Params[3].Z=70)  )
         and ( (Length(b) = 3) and (b[0].Tile=232) and (b[0].Z=51)
               and (b[1].Tile=233) and (b[1].Z=52) and (b[2].Tile=234) and (b[2].Z=53)  )
         ;
  AddToLog('Transfer TO Delphi function (records arr, var Integer, records dynarray, interface) with returned set): '
                      + CallRes(CR));

  a := 887;
  SetLength(b,35);

  b[0].Tile :=132;
  b[0].Z:=53;

  b[14].Tile :=133;
  b[14].Z:=54;

  b[26].Tile :=134;
  b[26].Z:=55;

  t := TInterfacedObject.Create;
  d := t;

  Result := [tsfTransparent, tsfDamaging, tlfSurface, tlfUnknown3];
end;


function _GetVariantWithParams(FlagSet : TTileDataFlagSet) : Variant;
begin
  AddToLog('Transfer TO Delphi function (set) with returned Variant): '
                      + CallRes(FlagSet = [tsfWet, tlfPrefixAn]));
Result := 'test84';
end;

type tCallBackProc = function(x : Integer; y : Integer) : Integer of object;

procedure CB(var x, y : Integer);
begin
  x := 600;
  y := 800;
end;

function _GetProcWithBigRecParam(var z : Int64; BigRec : TEndGroup; X: Integer; Y : Integer): TMethod;
var IsOK : Boolean;
begin
  IsOK := (BigRec.groupnumber = 39) and (BigRec.Page = 93) and (BigRec.ElemNum = 422) and (z = 339993232);


  AddToLog('Transfer TO Delphi function (var int64, bigrec, int, int) with returned tmethod): '
                      + CallRes(IsOK));

  Result.Code := @CB;
  Result.Data := nil;
  z := 339993232-999;
end;

procedure _CallCB(CB : tMethod; X, Y : Integer);
{$IF DEFINED (MSWINDOWS) OR DEFINED (MACOS32)}var CallBackProc : tCallBackProc;
    z : Integer;
{$endif}
begin
  {$IF DEFINED (MSWINDOWS) OR DEFINED (MACOS32)}
  x := $250;
  y := $251;
  CallBackProc := tCallBackProc(CB);
    {$IFDEF CPU64BITS}
    z := CallBackProc(X, Y);
    //passed as (Self : Pointer; Stack : Pointer; Result, EDX : Pointer).
    //Really present realization it very bad, limited&buggy. Need to rewrite.
    {$else}
    z := CallBackProc(X, Y);
    {$endif}
  {$ELSE}
  AddToLog(' Script callback from Delphi works for Win + MacOS32. For other platform will be done later');
  {$endif}

end;

function _GetPathArray9(DestX : Word; var Optimized : Boolean; Accuracy : Integer; var Res : Integer) : TPathArray;
var IsOK:Boolean;
begin
  IsOK := (DestX = 155) and (Optimized = True) and (Accuracy = 1) and (Res = 20);
  AddToLog(' Transfer TO Delphi function (word, var boolean, int, var int) with returned static array): '
                       + CallRes(IsOK));
  Optimized := False;
  Res := -50;
  Result[0].X := 230;
  Result[0].Y := 220;
  Result[0].Z := 40;

  Result[11].X := 130;
  Result[11].Y := 120;
  Result[11].Z := 30;

  Result[15].X := 180;
  Result[15].Y := 170;
  Result[15].Z := 20;

end;

{$EndRegion}

{$Region 'PSScript'}

{$Region 'PluginCompilerImport'}
procedure TPSScriptClass.IFPS3ClassesPlugin1CompImport(Sender : TObject;
  x : TIFPSPascalcompiler);
begin
  x.AddTypeS('TCardinalDynArray', 'array of Cardinal');
  x.AddTypeS('TMyPoint', 'record X : Word; Y : Word; Z : ShortInt; end');
  x.AddTypeS('TPathArray', 'array [  0 ..  999] of TMyPoint');
  x.AddTypeS('TMapCell', 'record Tile : Word; Z : ShortInt; end');
  x.AddTypeS('TClilocItemRec', 'record ClilocID : Cardinal; Params : array of String; end');
  x.AddTypeS('TClilocRec', 'record Count : Cardinal; Items : array of TClilocItemRec; end');

  x.AddTypeS('TTileDataFlags', '( tsfBackground, tsfWeapon, tsfTransparent, ts'
   +'fTranslucent, tsfWall, tsfDamaging, tsfImpassable, tsfWet, tsfUnknown, tsf'
   +'Surface, tsfBridge, tsfGeneric, tsfWindow, tsfNoShoot, tsfPrefixA, tsfPref'
   +'ixAn, tsfInternal, tsfFoliage, tsfPartialHue, tsfUnknown1, tsfMap, tsfCont'
   +'ainer, tsfWearable, tsfLightSource, tsfAnimated, tsfNoDiagonal, tsfUnknown'
   +'2, tsfArmor, tsfRoof, tsfDoor, tsfStairBack, tsfStairRight, tlfTranslucent'
   +', tlfWall, tlfDamaging, tlfImpassable, tlfWet, tlfSurface, tlfBridge, tlfP'
   +'refixA, tlfPrefixAn, tlfInternal, tlfMap, tlfUnknown3 )');
  x.AddTypeS('TTileDataFlagSet', 'set of TTileDataFlags');

  x.AddTypeS('TEndGroup', 'record groupnumber : Integer; Page : Integer; ElemNum : Integer; end');

  x.AddTypeS('TMapCellArray', 'array[0..4] of TMapCell');
  x.AddTypeS('TMapCellDynArray', 'array of TMapCell');
  x.AddTypeS('tScriptCallBackProc', 'function(x : Integer; y : Integer) : Integer');
  x.AddTypeS('tDelphiCallBackProc', 'procedure(var x : Integer; var y : Integer)');

end;

{$EndRegion}

{$Region 'PluginExecImport'}
procedure TPSScriptClass.IFPS3ClassesPlugin1ExecImport(Sender : TObject; Exec : TIFPSExec;
  x : TIFPSRuntimeClassImporter);
begin
  Exec.RegisterDelphiFunction(@_GetMapCell2, 'GetMapCell2', cdRegister);
  Exec.RegisterDelphiFunction(@_GetDynArrayReturn, 'GetDynArrayReturn', cdRegister);
  Exec.RegisterDelphiFunction(@_GetRecordWithParams, 'GetRecordWithParams', cdRegister);
  Exec.RegisterDelphiFunction(@_GetSetWithParams, 'GetSetWithParams', cdRegister);
  Exec.RegisterDelphiFunction(@_GetVariantWithParams, 'GetVariantWithParams', cdRegister);
  Exec.RegisterDelphiFunction(@_GetProcWithBigRecParam, 'GetProcWithBigRecParam', cdRegister);
  Exec.RegisterDelphiFunction(@_CallCB, 'CallCB', cdRegister);
  Exec.RegisterDelphiFunction(@AddToLog, 'AddToLog', cdRegister);
  Exec.RegisterDelphiFunction(@_GetPathArray9, 'GetPathArray9', cdRegister);

end;

{$EndRegion}

{$Region 'PSScriptCompile'}
procedure TPSScriptClass.PSScriptCompile(Sender : TPSScript);
begin

  Sender.AddFunction(@_GetMapCell2, 'function GetMapCell2 : TMapCell;');
  Sender.AddFunction(@_GetDynArrayReturn, 'function GetDynArrayReturn : TCardinalDynArray;');
  Sender.AddFunction(@_GetRecordWithParams, 'function GetRecordWithParams(Params : array of Word; var a : Integer; b : String; d : TCardinalDynArray; var z : TClilocRec) : TMapCell;');
  Sender.AddFunction(@_GetSetWithParams, 'function GetSetWithParams(Params : TMapCellArray; var a : Integer; b : TMapCellDynArray; var d : IUnknown) : TTileDataFlagSet;');
  Sender.AddFunction(@_GetVariantWithParams, 'function GetVariantWithParams(FlagSet : TTileDataFlagSet) : Variant;');
  Sender.AddFunction(@_GetProcWithBigRecParam, 'function GetProcWithBigRecParam(var z : Int64; BigRec : TEndGroup; X: Integer; Y : Integer): tDelphiCallBackProc;');
  Sender.AddFunction(@_CallCB, 'procedure CallCB(CB : tScriptCallBackProc; X, Y : Integer);');
  Sender.AddFunction(@AddToLog, 'procedure AddToLog(Line : String);');
  Sender.AddFunction(@_GetPathArray9, 'function GetPathArray9(DestX : Word; var Optimized : Boolean; Accuracy : Integer; var Res : Integer) : TPathArray;');

end;

{$EndRegion}

{$Region 'PSScriptExecute'}
procedure TPSScriptClass.PSScriptExecute(Sender: TPSScript);
begin
end;

procedure TPSScriptClass.PSScriptAfterExecute(Sender: TPSScript);
begin
{         }
end;
{$EndRegion}

{$Region 'ExecuteScript'}
procedure TPSScriptClass.ExecuteScript;
var NewFileName : String;
    CompileSuccess : Boolean;
begin
  begin  //compile & exec
    AddToLog('Compiling');
    PSScript.Script.Text := TestScript;
    PSScript.MainFileName := '';
    PSScript.Comp.AllowDuplicateRegister := False;
    try
      CompileSuccess := PSScript.Compile;
    except
      CompileSuccess := False;
    end;
    if CompileSuccess then
    begin
      OutputMessages;
      AddToLog('Compiled succesfully');
      if not PSScript.Execute then
      begin
        NewFileName := String(PSScript.ExecErrorFileName);

        AddToLog('Exec: [Error] ('
                                  +NewFileName+' at '
                                  +IntToStr(PSScript.ExecErrorRow)+':'
                                  +IntToStr(PSScript.ExecErrorCol)+'): '
                                  +String(PSScript.ExecErrorToString));
      end
      else
        AddToLog('Succesfully executed');
    end
    else
    begin
      OutputMessages;
      AddToLog('Compiling failed');
    end;
  end;
end;

procedure TPSScriptClass.OutputMessages;
var l : Longint;
begin
  for l := 0 to PSScript.CompilerMessageCount - 1 do
  begin
    with PSScript.CompilerMessages[l] do
    AddToLog('Compiler: ' + '['+String(ErrorType)+'] ('
                              +String(PSScript.CompilerMessages[l].ModuleName)
                              +' at '+IntToStr(PSScript.CompilerMessages[l].Row)+':'
                              +IntToStr(Col)+'): '+String(ShortMessageToString));
  end;
end;

constructor TPSScriptClass.Create;
begin
  PSScript := TPSScriptDebugger.Create(nil);
  PSScript.OnCompile := PSScriptCompile;
  PSScript.OnCompImport := IFPS3ClassesPlugin1CompImport;
  PSScript.OnExecImport := IFPS3ClassesPlugin1ExecImport;
  PSScript.OnExecute := PSScriptExecute;
  PSScript.UsePreProcessor := True;
end;

{$EndRegion}

{$EndRegion}

const ScriptFileName = '..\..\PS_TESTING.rops';

var PSScriptClass : TPSScriptClass;

begin
  PSScriptClass := TPSScriptClass.Create;
  PSScriptClass.ExecuteScript;
  ReadLn;

end.




