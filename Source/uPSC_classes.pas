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
procedure SIRegisterTSTRINGSTREAM(Cl: TPSPascalCompiler);
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
  with Cl.AddClassN(cl.FindClass('TPersistent'), 'TStrings') do
  begin
    IsAbstract := True;
{$IF defined(DELPHI2005UP) or defined(FPC)}
    RegisterMethod('constructor Create;');
{$IFEND}
    RegisterMethod({$IFDEF FPC}'function Add(S: AnsiString): Integer;'{$ELSE}'function Add(S: string): Integer;'{$ENDIF});
    RegisterMethod({$IFDEF FPC}'procedure Append(S: AnsiString);'{$ELSE}'procedure Append(S: string);'{$ENDIF});
    RegisterMethod('procedure AddStrings(Strings: TStrings);');
    RegisterMethod('procedure Clear;');
    RegisterMethod('procedure Delete(Index: Integer);');
    RegisterMethod({$IFDEF FPC}'function IndexOf(const S: AnsiString): Integer; '{$ELSE}'function IndexOf(const S: string): Integer; '{$ENDIF});
    RegisterMethod({$IFDEF FPC}'procedure Insert(Index: Integer; S: AnsiString); '{$ELSE}'procedure Insert(Index: Integer; S: string); '{$ENDIF});
    RegisterProperty('Capacity', 'Integer', iptRW);
    RegisterProperty('Delimiter', 'Char', iptRW);
{$IFDEF DELPHI2006UP}
    RegisterProperty('StrictDelimiter', 'Boolean', iptRW);
{$ENDIF}
    RegisterProperty('DelimitedText', 'string', iptrw);
    RegisterProperty('NameValueSeparator', 'Char', iptRW);
    RegisterProperty('QuoteChar', 'Char', iptRW);
    RegisterProperty('Count', 'Integer', iptR);
    RegisterProperty('Text', 'string', iptrw);
    RegisterProperty('CommaText', 'string', iptrw);
    if Streams then
    begin
      RegisterMethod({$IFDEF FPC}'procedure LoadFromFile(FileName: AnsiString); '{$ELSE}'procedure LoadFromFile(FileName: string); '{$ENDIF});
      RegisterMethod({$IFDEF FPC}'procedure SaveToFile(FileName: AnsiString); '{$ELSE}'procedure SaveToFile(FileName: string); '{$ENDIF});
    end;
    RegisterProperty('Strings', 'string Integer', iptRW);
    SetDefaultPropery('Strings');
    RegisterProperty('Objects', 'TObject Integer', iptRW);

    {$IFNDEF PS_MINIVCL}
    RegisterMethod('procedure BeginUpdate;');
    RegisterMethod('procedure EndUpdate;');
    RegisterMethod('function Equals(Strings: TStrings): Boolean;');
    RegisterMethod('procedure Exchange(Index1, Index2: Integer);');
    RegisterMethod('function IndexOfName(Name: string): Integer;');
    if Streams then
      RegisterMethod('procedure LoadFromStream(Stream: TStream); ');
    RegisterMethod('procedure Move(CurIndex, NewIndex: Integer); ');
    if Streams then
      RegisterMethod('procedure SaveToStream(Stream: TStream); ');
    RegisterMethod('procedure SetText(Text: PChar); ');
    RegisterProperty('Names', 'string Integer', iptr);
    RegisterProperty('Values', 'string string', iptRW);
    RegisterProperty('ValueFromIndex', 'string Integer', iptRW);
    RegisterMethod({$IFDEF FPC}'function AddObject(S: AnsiString; AObject: TObject): Integer'{$ELSE}'function AddObject(S: string; AObject: TObject): Integer'{$ENDIF});
    RegisterMethod('function GetText: PChar');
    RegisterMethod('function IndexOfObject(AObject: TObject): Integer');
    RegisterMethod('procedure InsertObject(Index: Integer; S: string; AObject: TObject)');
    {$ENDIF}
  end;
end;

procedure SIRegisterTSTRINGLIST(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TStrings'), 'TStringList') do
  begin
{$IF defined(DELPHI2005UP) or defined(FPC)}
    RegisterMethod('constructor Create;');
{$IFEND}
    RegisterMethod({$IFDEF FPC}'function Find(S: AnsiString; var Index: Integer): Boolean'{$ELSE}'function Find(S: string; var Index: Integer): Boolean'{$ENDIF});
    RegisterMethod('procedure Sort');
    RegisterProperty('CaseSensitive', 'Boolean', iptrw);
    RegisterProperty('Duplicates', 'TDuplicates', iptrw);
    RegisterProperty('Sorted', 'Boolean', iptrw);
    RegisterProperty('OnChange', 'TNotifyEvent', iptrw);
    RegisterProperty('OnChanging', 'TNotifyEvent', iptrw);
  end;
end;

{$IFNDEF PS_MINIVCL}
procedure SIRegisterTBITS(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TObject'), 'TBits') do
  begin
    {$IFDEF FPC}
    RegisterMethod('constructor Create');
    {$ENDIF}
    RegisterMethod('function OpenBit: Integer');
    RegisterProperty('Bits', 'Boolean Integer', iptrw);
    SetDefaultPropery('Bits');
    RegisterProperty('Size', 'Integer', iptrw);
  end;
end;
{$ENDIF}

procedure SIRegisterTSTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TObject'), 'TStream') do
  begin
    {$IFNDEF DELPHI_SYDNEY_UP}
    IsAbstract := True;
    {$ENDIF}
    RegisterMethod('function Read(Buffer: AnyString; Count: LongInt): LongInt');
    RegisterMethod('function Write(Buffer: AnyString; Count: LongInt): LongInt');
    { Free Pascal's TCustomMemoryStream.Seek, which the run time binds, takes an Int64
      as Delphi's does from XE2 }
    {$IF defined(DELPHI16UP) or defined(FPC)}
    {$IFNDEF PS_NOINT64}
    RegisterMethod('function Seek(Offset: Int64; Origin: Word): Int64');
    {$ENDIF}
    {$ELSE}
    RegisterMethod('function Seek(Offset: LongInt; Origin: Word): LongInt');
    {$IFEND}
    RegisterMethod('procedure ReadBuffer(Buffer: AnyString; Count: LongInt)');
    RegisterMethod('procedure WriteBuffer(Buffer: AnyString; Count: LongInt)');
    {$IFDEF DELPHI4UP}
    {$IFNDEF PS_NOINT64}
    RegisterMethod('function CopyFrom(Source: TStream; Count: Int64): Int64');
    {$ENDIF}
    {$ELSE}
    RegisterMethod('function CopyFrom(Source: TStream; Count: Integer): LongInt');
    {$ENDIF}
    RegisterProperty('Position', 'Int64', iptrw);
    RegisterProperty('Size', 'Int64', iptrw);
  end;
end;

procedure SIRegisterTHANDLESTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TStream'), 'THandleStream') do
  begin
    RegisterMethod('constructor Create(AHandle: THandle)');
    RegisterProperty('Handle', 'THandle', iptr);
  end;
end;

{$IFNDEF PS_MINIVCL}
procedure SIRegisterTMEMORYSTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TCustomMemoryStream'), 'TMemoryStream') do
  begin
    RegisterMethod('procedure Clear');
    RegisterMethod('procedure LoadFromStream(Stream: TStream)');
    RegisterMethod({$IFDEF FPC}'procedure LoadFromFile(FileName: AnsiString)'{$ELSE}'procedure LoadFromFile(FileName: string)'{$ENDIF});
    RegisterMethod('procedure SetSize(NewSize: LongInt)');
  end;
end;
{$ENDIF}

procedure SIRegisterTFILESTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('THandleStream'), 'TFileStream') do
  begin
    RegisterMethod({$IFDEF FPC}'constructor Create(FileName: AnsiString; Mode: Word)'{$ELSE}'constructor Create(FileName: string; Mode: Word)'{$ENDIF});
  end;
end;

procedure SIRegisterTSTRINGSTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TStream'), 'TStringStream') do
  begin
    RegisterMethod('constructor Create(AString: string)');
  end;
end;

{$IFNDEF PS_MINIVCL}
procedure SIRegisterTCUSTOMMEMORYSTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TStream'), 'TCustomMemoryStream') do
  begin
    IsAbstract := True;
    RegisterMethod('procedure SaveToStream(Stream: TStream)');
    RegisterMethod({$IFDEF FPC}'procedure SaveToFile(FileName: AnsiString)'{$ELSE}'procedure SaveToFile(FileName: string)'{$ENDIF});
  end;
end;

procedure SIRegisterTRESOURCESTREAM(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TCustomMemoryStream'), 'TResourceStream') do
  begin
    RegisterMethod({$IFDEF FPC}'constructor Create(Instance: THandle; ResName: AnsiString; ResType: PChar)'{$ELSE}'constructor Create(Instance: THandle; ResName: string; ResType: PChar)'{$ENDIF});
    RegisterMethod('constructor CreateFromID(Instance: THandle; ResID: Integer; ResType: PChar)');
  end;
end;

procedure SIRegisterTPARSER(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TObject'), 'TParser') do
  begin
    RegisterMethod('constructor Create(Stream: TStream)');
    RegisterMethod('procedure CheckToken(T: Char)');
    RegisterMethod({$IFDEF FPC}'procedure CheckTokenSymbol(S: AnsiString)'{$ELSE}'procedure CheckTokenSymbol(S: string)'{$ENDIF});
    RegisterMethod({$IFDEF FPC}'procedure Error(Ident: AnsiString)'{$ELSE}'procedure Error(Ident: string)'{$ENDIF});
    RegisterMethod({$IFDEF FPC}'procedure ErrorStr(Message: AnsiString)'{$ELSE}'procedure ErrorStr(Message: string)'{$ENDIF});
    RegisterMethod('procedure HexToBinary(Stream: TStream)');
    RegisterMethod('function NextToken: Char');
    {$IFDEF DELPHI_TOKYO_UP}
    RegisterMethod('function SourcePos: NativeInt');
    {$ELSE}
    RegisterMethod('function SourcePos: LongInt');
    {$ENDIF}
    RegisterMethod({$IFDEF FPC}'function TokenComponentIdent: AnsiString'{$ELSE}'function TokenComponentIdent: string'{$ENDIF});
    RegisterMethod('function TokenFloat: Extended');
    RegisterMethod('function TokenInt: Int64');
    RegisterMethod({$IFDEF FPC}'function TokenString: AnsiString'{$ELSE}'function TokenString: string'{$ENDIF});
    RegisterMethod({$IFDEF FPC}'function TokenSymbolIs(S: AnsiString): Boolean'{$ELSE}'function TokenSymbolIs(S: string): Boolean'{$ENDIF});
    RegisterProperty('SourceLine', 'Integer', iptr);
    RegisterProperty('Token', 'Char', iptr);
  end;
end;

procedure SIRegisterTCOLLECTIONITEM(CL: TPSPascalCompiler);
Begin
  if cl.FindClass('TCollection') = nil then cl.AddClassN(cl.FindClass('TPersistent'), 'TCollection');
  With cl.AddClassN(cl.FindClass('TPersistent'),'TCollectionItem') do
  begin
  RegisterMethod('constructor Create(Collection: TCollection)');
  RegisterProperty('Collection', 'TCollection', iptrw);
{$IFDEF DELPHI3UP}  RegisterProperty('ID', 'Integer', iptr); {$ENDIF}
  RegisterProperty('Index', 'Integer', iptrw);
{$IFDEF DELPHI3UP}  RegisterProperty('DisplayName', 'string', iptrw); {$ENDIF}
  end;
end;

procedure SIRegisterTCOLLECTION(CL: TPSPascalCompiler);
var
  cr: TPSCompileTimeClass;
Begin
  cr := CL.FindClass('TCollection');
  if cr = nil then cr := cl.AddClassN(cl.FindClass('TPersistent'), 'TCollection');
With cr do
  begin
  { Delphi's Create takes the item class, which a script cannot pass; this one is bound to a routine that
    refuses, for TCollection and every class derived from it that inherits this Create }
  RegisterMethod('constructor Create');
{$IFDEF DELPHI6UP} {$IFNDEF FPC} RegisterMethod('function Owner: TPersistent'); {$ENDIF} {$ENDIF} // no owner in FPC
  RegisterMethod('function Add: TCollectionItem');
  RegisterMethod('procedure BeginUpdate');
  RegisterMethod('procedure Clear');
{$IFDEF DELPHI5UP}  RegisterMethod('procedure Delete(Index: Integer)'); {$ENDIF}
  RegisterMethod('procedure EndUpdate');
{$IFDEF DELPHI3UP}  RegisterMethod('function FindItemID(ID: Integer): TCollectionItem'); {$ENDIF}
{$IFDEF DELPHI3UP}  RegisterMethod('function Insert(Index: Integer): TCollectionItem'); {$ENDIF}
  RegisterProperty('Count', 'Integer', iptr);
{$IFDEF DELPHI3UP}  RegisterProperty('ItemClass', 'TCollectionItemClass', iptr); {$ENDIF}
  RegisterProperty('Items', 'TCollectionItem Integer', iptrw);
  end;
end;

{$IFDEF DELPHI3UP}
procedure SIRegisterTOWNEDCOLLECTION(CL: TPSPascalCompiler);
Begin
With Cl.AddClassN(cl.FindClass('TCollection'),'TOwnedCollection') do
  begin
//  RegisterMethod('constructor Create(AOwner: TPersistent; ItemClass: TCollectionItemClass)');
  end;
end;
{$ENDIF}
{$ENDIF}

procedure SIRegister_Classes_TypesAndConsts(Cl: TPSPascalCompiler);
begin
  cl.AddConstantN('soFromBeginning', 'LongInt').Value.ts32 := 0;
  cl.AddConstantN('soFromCurrent', 'LongInt').Value.ts32 := 1;
  cl.AddConstantN('soFromEnd', 'LongInt').Value.ts32 := 2;
  cl.AddConstantN('toEOF', 'Char').SetString(#0);
  cl.AddConstantN('toSymbol', 'Char').SetString(#1);
  cl.AddConstantN('toString', 'Char').SetString(#2);
  cl.AddConstantN('ToInteger', 'Char').SetString(#3);
  cl.AddConstantN('toFloat', 'Char').SetString(#4);
  { Delphi 2010 changed fmCreate from $FFFF to $FF00, so that it combines with a sharing mode }
  cl.AddConstantN('fmCreate', 'LongInt').Value.ts32 := {$IF Defined(DELPHI2010UP) or Defined(FPC)}$FF00{$ELSE}$FFFF{$IFEND};
  cl.AddConstantN('fmOpenRead', 'LongInt').Value.ts32 := 0;
  cl.AddConstantN('fmOpenWrite', 'LongInt').Value.ts32 := 1;
  cl.AddConstantN('fmOpenReadWrite', 'LongInt').Value.ts32 := 2;
  cl.AddConstantN('fmShareCompat', 'LongInt').Value.ts32 := 0;
  cl.AddConstantN('fmShareExclusive', 'LongInt').Value.ts32 := $10;
  cl.AddConstantN('fmShareDenyWrite', 'LongInt').Value.ts32 := $20;
  cl.AddConstantN('fmShareDenyRead', 'LongInt').Value.ts32 := $30;
  cl.AddConstantN('fmShareDenyNone', 'LongInt').Value.ts32 := $40;
  cl.AddConstantN('SecsPerDay', 'LongInt').Value.ts32 := 86400;
  cl.AddConstantN('MSecPerDay', 'LongInt').Value.ts32 := 86400000;
  cl.AddConstantN('DateDelta', 'LongInt').Value.ts32 := 693594;
  cl.AddTypeS('TAlignment', '(taLeftJustify, taRightJustify, taCenter)');
  cl.AddTypeS('THelpEvent', 'function (Command: Word; Data: ' + {$IFDEF FPC}'Longint'{$ELSE}'NativeInt'{$ENDIF} + '; var CallHelp: Boolean): Boolean');
  cl.AddTypeS('TGetStrProc', 'procedure(const S: ' + {$IF not Defined(FPC) or not Defined(UNICODE)}'string'{$ELSE}'AnsiString'{$IFEND} + ')');
  cl.AddTypeS('TDuplicates', '(dupIgnore, dupAccept, dupError)');
  cl.AddTypeS('TOperation', '(opInsert, opRemove)');
  if cl.FindType('THandle') = nil then
    cl.AddTypeS('THandle', 'NativeUInt');

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
    SIRegisterTSTRINGSTREAM(Cl);
    {$IFNDEF PS_MINIVCL}
    SIRegisterTCUSTOMMEMORYSTREAM(Cl);
    SIRegisterTMEMORYSTREAM(Cl);
    SIRegisterTRESOURCESTREAM(Cl);
    {$ENDIF}
  end;
  {$IFNDEF PS_MINIVCL}
  { a parser is made from a stream and reads one: declared where the stream
    class is, whoever registered it }
  if Cl.FindClass('TStream') <> nil then
    SIRegisterTPARSER(Cl);
  SIRegisterTCOLLECTIONITEM(Cl);
  SIRegisterTCOLLECTION(Cl);
  {$IFDEF DELPHI3UP}
  SIRegisterTOWNEDCOLLECTION(Cl);
  {$ENDIF}
  {$ENDIF}
end;

// PS_MINIVCL changes by Martijn Laan


end.
