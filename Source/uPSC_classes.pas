{ Compiletime Classes support }
unit uPSC_classes;

{$I PascalScript.inc}
interface
uses
  uPSCompiler, uPSUtils;

{
  Will register files from:
    Classes (exception TPersistent and TComponent)
 
  Register STD first

}

procedure SIRegister_Classes_TypesAndConsts(Cl: TPSPascalCompiler);

procedure SIRegisterTStrings(cl: TPSPascalCompiler; Streams: Boolean);
procedure SIRegisterTStringList(cl: TPSPascalCompiler);
{$IFNDEF PS_MINIVCL}
procedure SIRegisterTBITS(Cl: TPSPascalCompiler);
{$ENDIF}
procedure SIRegisterTSTREAM(Cl: TPSPascalCompiler);
procedure SIRegisterTHANDLESTREAM(Cl: TPSPascalCompiler);
{$IFNDEF PS_MINIVCL}
procedure SIRegisterTMEMORYSTREAM(Cl: TPSPascalCompiler);
{$ENDIF}
procedure SIRegisterTFILESTREAM(Cl: TPSPascalCompiler);
{$IFNDEF PS_MINIVCL}
procedure SIRegisterTCUSTOMMEMORYSTREAM(Cl: TPSPascalCompiler);
procedure SIRegisterTRESOURCESTREAM(Cl: TPSPascalCompiler);
procedure SIRegisterTPARSER(Cl: TPSPascalCompiler);
procedure SIRegisterTCOLLECTIONITEM(CL: TPSPascalCompiler);
procedure SIRegisterTCOLLECTION(CL: TPSPascalCompiler);
{$IFDEF DELPHI3UP}
procedure SIRegisterTOWNEDCOLLECTION(CL: TPSPascalCompiler);
{$ENDIF}
{$ENDIF}

procedure SIRegister_Classes(Cl: TPSPascalCompiler; Streams: Boolean{$IFDEF D4PLUS}=True{$ENDIF});

implementation

procedure SIRegisterTStrings(cl: TPSPascalCompiler; Streams: Boolean); // requires TPersistent
begin
  with Cl.AddClassN(cl.FindClass('TPersistent'), 'TSTRINGS') do
  begin
    IsAbstract := True;
    RegisterMethod('function Add(S: NativeString): Integer;');
    RegisterMethod('procedure Append(S: NativeString);');
    RegisterMethod('procedure AddStrings(NativeString: TStrings);');
    RegisterMethod('procedure Clear;');
    RegisterMethod('procedure Delete(Index: Integer);');
    RegisterMethod('function IndexOf(const S: NativeString): Integer; ');
    RegisterMethod('procedure Insert(Index: Integer; S: NativeString); ');
    RegisterProperty('Count', 'Integer', iptR);
    RegisterProperty('Text', 'NativeString', iptrw);
    RegisterProperty('CommaText', 'NativeString', iptrw);
    if Streams then
    begin
      RegisterMethod('procedure LoadFromFile(FileName: NativeString); ');
      RegisterMethod('procedure SaveToFile(FileName: NativeString); ');
    end;
    RegisterProperty('Strings', 'NativeString Integer', iptRW);
    SetDefaultPropery('Strings');
    RegisterProperty('Objects', 'TObject Integer', iptRW);

    {$IFNDEF PS_MINIVCL}
    RegisterMethod('procedure BeginUpdate;');
    RegisterMethod('procedure EndUpdate;');
    RegisterMethod('function Equals(Strings: TStrings): Boolean;');
    RegisterMethod('procedure Exchange(Index1, Index2: Integer);');
    RegisterMethod('function IndexOfName(Name: NativeString): Integer;');
    if Streams then
      RegisterMethod('procedure LoadFromStream(Stream: TStream); ');
    RegisterMethod('procedure Move(CurIndex, NewIndex: Integer); ');
    if Streams then
      RegisterMethod('procedure SaveToStream(Stream: TStream); ');
    RegisterMethod('procedure SetText(Text: PChar); ');
    RegisterProperty('Names', 'NativeString Integer', iptr);
    RegisterProperty('Values', 'NativeString NativeString', iptRW);
    RegisterMethod('function ADDOBJECT(S:NativeString;AOBJECT:TOBJECT):INTEGER');
    RegisterMethod('function GETTEXT:PCHAR');
    RegisterMethod('function INDEXOFOBJECT(AOBJECT:TOBJECT):INTEGER');
    RegisterMethod('procedure INSERTOBJECT(INDEX:INTEGER;S:NativeString;AOBJECT:TOBJECT)');
    {$ENDIF}
  end;
end;

procedure SIRegisterTSTRINGLIST(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TSTRINGS'), 'TSTRINGLIST') do
  begin
    RegisterMethod('function FIND(S:STRING;var INDEX:INTEGER):BOOLEAN');
    RegisterMethod('procedure SORT');
    RegisterProperty('DUPLICATES', 'TDUPLICATES', iptrw);
    RegisterProperty('SORTED', 'BOOLEAN', iptrw);
    RegisterProperty('ONCHANGE', 'TNOTIFYEVENT', iptrw);
    RegisterProperty('ONCHANGING', 'TNOTIFYEVENT', iptrw);
  end;
end;

{$IFNDEF PS_MINIVCL}
procedure SIRegisterTBITS(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TObject'), 'TBITS') do
  begin
    RegisterMethod('function OPENBIT:INTEGER');
    RegisterProperty('BITS', 'BOOLEAN INTEGER', iptrw);
    RegisterProperty('SIZE', 'INTEGER', iptrw);
  end;
end;
{$ENDIF}

procedure SIRegisterTSTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TOBJECT'), 'TSTREAM') do
  begin
    IsAbstract := True;
    RegisterMethod('function READ(BUFFER:STRING;COUNT:LONGINT):LONGINT');
    RegisterMethod('function WRITE(BUFFER:STRING;COUNT:LONGINT):LONGINT');
    RegisterMethod('function SEEK(OFFSET:LONGINT;ORIGIN:WORD):LONGINT');
    RegisterMethod('procedure READBUFFER(BUFFER:STRING;COUNT:LONGINT)');
    RegisterMethod('procedure WRITEBUFFER(BUFFER:STRING;COUNT:LONGINT)');
    {$IFDEF DELPHI4UP}
    RegisterMethod('function COPYFROM(SOURCE:TSTREAM;COUNT:INT64):LONGINT');
    {$ELSE}
    RegisterMethod('function COPYFROM(SOURCE:TSTREAM;COUNT:Integer):LONGINT');
    {$ENDIF}
    RegisterProperty('POSITION', 'LONGINT', iptrw);
    RegisterProperty('SIZE', 'LONGINT', iptrw);
  end;
end;

procedure SIRegisterTHANDLESTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TSTREAM'), 'THANDLESTREAM') do
  begin
    RegisterMethod('constructor CREATE(AHANDLE:INTEGER)');
    RegisterProperty('HANDLE', 'INTEGER', iptr);
  end;
end;

{$IFNDEF PS_MINIVCL}
procedure SIRegisterTMEMORYSTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TCUSTOMMEMORYSTREAM'), 'TMEMORYSTREAM') do
  begin
    RegisterMethod('procedure CLEAR');
    RegisterMethod('procedure LOADFROMSTREAM(STREAM:TSTREAM)');
    RegisterMethod('procedure LOADFROMFILE(FILENAME:NativeString)');
    RegisterMethod('procedure SETSIZE(NEWSIZE:LONGINT)');
  end;
end;
{$ENDIF}

procedure SIRegisterTFILESTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('THANDLESTREAM'), 'TFILESTREAM') do
  begin
    RegisterMethod('constructor CREATE(FILENAME:NativeString;MODE:WORD)');
  end;
end;

{$IFNDEF PS_MINIVCL}
procedure SIRegisterTCUSTOMMEMORYSTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TSTREAM'), 'TCUSTOMMEMORYSTREAM') do
  begin
    IsAbstract := True;
    RegisterMethod('procedure SAVETOSTREAM(STREAM:TSTREAM)');
    RegisterMethod('procedure SAVETOFILE(FILENAME:NativeString)');
  end;
end;

procedure SIRegisterTRESOURCESTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TCUSTOMMEMORYSTREAM'), 'TRESOURCESTREAM') do
  begin
    RegisterMethod('constructor CREATE(INSTANCE:THANDLE;RESNAME:NativeString;RESTYPE:NativeString)');
    RegisterMethod('constructor CREATEFROMID(INSTANCE:THANDLE;RESID:INTEGER;RESTYPE:NativeString)');
  end;
end;

procedure SIRegisterTPARSER(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TOBJECT'), 'TPARSER') do
  begin
    RegisterMethod('constructor CREATE(STREAM:TSTREAM)');
    RegisterMethod('procedure CHECKTOKEN(T:CHAR)');
    RegisterMethod('procedure CHECKTOKENSYMBOL(S:NativeString)');
    RegisterMethod('procedure ERROR(IDENT:INTEGER)');
    RegisterMethod('procedure ERRORSTR(MESSAGE:NativeString)');
    RegisterMethod('procedure HEXTOBINARY(STREAM:TSTREAM)');
    RegisterMethod('function NEXTTOKEN:CHAR');
    RegisterMethod('function SOURCEPOS:LONGINT');
    RegisterMethod('function TOKENCOMPONENTIDENT:NativeString');
    RegisterMethod('function TOKENFLOAT:EXTENDED');
    RegisterMethod('function TOKENINT:LONGINT');
    RegisterMethod('function TOKENSTRING:NativeString');
    RegisterMethod('function TOKENSYMBOLIS(S:NativeString):BOOLEAN');
    RegisterProperty('SOURCELINE', 'INTEGER', iptr);
    RegisterProperty('TOKEN', 'CHAR', iptr);
  end;
end;

procedure SIRegisterTCOLLECTIONITEM(CL: TPSPascalCompiler);
Begin
  if cl.FindClass('TCOLLECTION') = nil then cl.AddClassN(cl.FindClass('TPERSISTENT'), 'TCOLLECTION');
  With cl.AddClassN(cl.FindClass('TPERSISTENT'),'TCOLLECTIONITEM') do
  begin
  RegisterMethod('Constructor CREATE( COLLECTION : TCOLLECTION)');
  RegisterProperty('COLLECTION', 'TCOLLECTION', iptrw);
{$IFDEF DELPHI3UP}  RegisterProperty('ID', 'INTEGER', iptr); {$ENDIF}
  RegisterProperty('INDEX', 'INTEGER', iptrw);
{$IFDEF DELPHI3UP}  RegisterProperty('DISPLAYNAME', 'NativeString', iptrw); {$ENDIF}
  end;
end;

procedure SIRegisterTCOLLECTION(CL: TPSPascalCompiler);
var
  cr: TPSCompileTimeClass;
Begin
  cr := CL.FindClass('TCOLLECTION');
  if cr = nil then cr := cl.AddClassN(cl.FindClass('TPERSISTENT'), 'TCOLLECTION');
With cr do
  begin
//  RegisterMethod('Constructor CREATE( ITEMCLASS : TCOLLECTIONITEMCLASS)');
{$IFDEF DELPHI3UP}  RegisterMethod('Function OWNER : TPERSISTENT'); {$ENDIF}
  RegisterMethod('Function ADD : TCOLLECTIONITEM');
  RegisterMethod('Procedure BEGINUPDATE');
  RegisterMethod('Procedure CLEAR');
{$IFDEF DELPHI5UP}  RegisterMethod('Procedure DELETE( INDEX : INTEGER)'); {$ENDIF}
  RegisterMethod('Procedure ENDUPDATE');
{$IFDEF DELPHI3UP}  RegisterMethod('Function FINDITEMID( ID : INTEGER) : TCOLLECTIONITEM'); {$ENDIF}
{$IFDEF DELPHI3UP}  RegisterMethod('Function INSERT( INDEX : INTEGER) : TCOLLECTIONITEM'); {$ENDIF}
  RegisterProperty('COUNT', 'INTEGER', iptr);
{$IFDEF DELPHI3UP}  RegisterProperty('ITEMCLASS', 'TCOLLECTIONITEMCLASS', iptr); {$ENDIF}
  RegisterProperty('ITEMS', 'TCOLLECTIONITEM INTEGER', iptrw);
  end;
end;

{$IFDEF DELPHI3UP}
procedure SIRegisterTOWNEDCOLLECTION(CL: TPSPascalCompiler);
Begin
With Cl.AddClassN(cl.FindClass('TCOLLECTION'),'TOWNEDCOLLECTION') do
  begin
//  RegisterMethod('Constructor CREATE( AOWNER : TPERSISTENT; ITEMCLASS : TCOLLECTIONITEMCLASS)');
  end;
end;
{$ENDIF}
{$ENDIF}

procedure SIRegister_Classes_TypesAndConsts(Cl: TPSPascalCompiler);
begin
  cl.AddConstantN('soFromBeginning', 'Longint').Value.ts32 := 0;
  cl.AddConstantN('soFromCurrent', 'Longint').Value.ts32 := 1;
  cl.AddConstantN('soFromEnd', 'Longint').Value.ts32 := 2;
  cl.AddConstantN('toEOF', 'Char').Value.tchar := #0;
  cl.AddConstantN('toSymbol', 'Char').Value.tchar := #1;
  cl.AddConstantN('toString', 'Char').Value.tchar := #2;
  cl.AddConstantN('toInteger', 'Char').Value.tchar := #3;
  cl.AddConstantN('toFloat', 'Char').Value.tchar := #4;
  cl.AddConstantN('fmCreate', 'Longint').Value.ts32 := $FFFF;
  cl.AddConstantN('fmOpenRead', 'Longint').Value.ts32 := 0;
  cl.AddConstantN('fmOpenWrite', 'Longint').Value.ts32 := 1;
  cl.AddConstantN('fmOpenReadWrite', 'Longint').Value.ts32 := 2;
  cl.AddConstantN('fmShareCompat', 'Longint').Value.ts32 := 0;
  cl.AddConstantN('fmShareExclusive', 'Longint').Value.ts32 := $10;
  cl.AddConstantN('fmShareDenyWrite', 'Longint').Value.ts32 := $20;
  cl.AddConstantN('fmShareDenyRead', 'Longint').Value.ts32 := $30;
  cl.AddConstantN('fmShareDenyNone', 'Longint').Value.ts32 := $40;
  cl.AddConstantN('SecsPerDay', 'Longint').Value.ts32 := 86400;
  cl.AddConstantN('MSecPerDay', 'Longint').Value.ts32 := 86400000;
  cl.AddConstantN('DateDelta', 'Longint').Value.ts32 := 693594;
  cl.AddTypeS('TAlignment', '(taLeftJustify, taRightJustify, taCenter)');
  cl.AddTypeS('THelpEvent', 'function (Command: Word; Data: Longint; var CallHelp: Boolean): Boolean');
  cl.AddTypeS('TGetStrProc', 'procedure(const S: NativeString)');
  cl.AddTypeS('TDuplicates', '(dupIgnore, dupAccept, dupError)');
  cl.AddTypeS('TOperation', '(opInsert, opRemove)');
  cl.AddTypeS('THANDLE', 'Longint');

  cl.AddTypeS('TNotifyEvent', 'procedure (Sender: TObject)');
end;

procedure SIRegister_Classes(Cl: TPSPascalCompiler; Streams: Boolean);
begin
  SIRegister_Classes_TypesAndConsts(Cl);
  if Streams then
    SIRegisterTSTREAM(Cl);
  SIRegisterTStrings(cl, Streams);
  SIRegisterTStringList(cl);
  {$IFNDEF PS_MINIVCL}
  SIRegisterTBITS(cl);
  {$ENDIF}
  if Streams then
  begin
    SIRegisterTHANDLESTREAM(Cl);
    SIRegisterTFILESTREAM(Cl);
    {$IFNDEF PS_MINIVCL}
    SIRegisterTCUSTOMMEMORYSTREAM(Cl);
    SIRegisterTMEMORYSTREAM(Cl);
    SIRegisterTRESOURCESTREAM(Cl);
    {$ENDIF}
  end;
  {$IFNDEF PS_MINIVCL}
  SIRegisterTPARSER(Cl);
  SIRegisterTCOLLECTIONITEM(Cl);
  SIRegisterTCOLLECTION(Cl);
  {$IFDEF DELPHI3UP}
  SIRegisterTOWNEDCOLLECTION(Cl);
  {$ENDIF}
  {$ENDIF}
end;

// PS_MINIVCL changes by Martijn Laan (mlaan at wintax _dot_ nl)


end.
