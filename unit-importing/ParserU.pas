{
  20050712 jgv
  add parsing of untyped parameter (with warning)
  fix parsing of overloaded procedure/function (ie not method)
  add parsing of class method member
  add parsing of "array of const"
  fix parsing of constant expression for chr and ord case.
  add parsing of reintroduced property specifier (stored)
}

unit ParserU;
{version: 20041219}

interface
  uses uPSUtils, SysUtils, StrUtils, ParserUtils, BigIni, Classes;

type
  TProcAttr = set of (PublicProc, IsDone, IsHelper);

(*----------------------------------------------------------------------------*)
  TProcList = class(TStringList)
  public
    ProcAttr : TProcAttr;
    Name     : string;
  end;

  TWriteln = procedure(const S: string) of object;
  TReadln = procedure(var S: string; const Promote, Caption: string) of object;

(*----------------------------------------------------------------------------*)
  TPasToken = record
    ID: TPSPasToken;
    Data: string;
    Org : String;
    row, col: integer;
  end;

  TProcDeclOptions = set of (IsMethod, IsPointer);
  TProcDeclInfo    = set of (IsVirtual, IsAbstract, IsConstructor, IsDestructor, IsFunction, IsCallHelper);

  // CompileTime RunTime
  TTimeMode = (CompileTime, RunTime);

(*----------------------------------------------------------------------------*)
  TUnitParser = class
  private
    fWriteln: TWriteln;
    fReadln: TReadln;
    FUnitPrefix,
    FCompPage,
    fCompPrefix : String;
    FSingleUnit: Boolean;
    FCompileTimeFunctions : Boolean;
    FAfterInterfaceDeclaration: string;
    FAutoRenameOverloadedMethods: Boolean;
    procedure SetWriteln(aWriteln: TWriteln);
    procedure SetReadln(aReadln: TReadln);
  private
    fParser: TPsPascalParser;
    fToken, fPrevToken: TPasToken;
//    fprevOrgToken: string;
    Ini: TBigIniFile;
    FRenamingHelper: Integer;
  private
    LastTokens: array of TPasToken;
    FTail, FHead, TokenHistoryCount, TokenHistoryLength: integer;
    procedure AddToTokenHistory(const aToken: TPasToken);
    function RemoveFromTokenHistory(var aToken: TPasToken): boolean;
  private
    property TokenID: TPsPasToken read fToken.ID;
    property PrevTokenID: TPsPasToken read fPrevToken.ID;
    property TokenRow: integer read fToken.Row;
    property TokenCol: integer read fToken.Col;
   // Property PrevTokenPos : integer read fPrevToken.Pos;
    property Token: string read fToken.data;
    property OrgToken: string read fToken.Org;
//    property PrevToken: string read fPrevToken.data;
    property PrevOrgToken: string read fPrevToken.Org;

    procedure SetToken(aTokenID: TPsPasToken; aToken: string; aTokenRow, aTokenCol: integer);
    procedure NextToken;

    procedure skipToSemicolon; //Birb
    function IfMatch(atoken: TPsPasToken): boolean;
    procedure Match(atoken: TPsPasToken; err: string = '');
  private
    FOutUnitList            : TStringList;    // teo

    FRunTimeProcList        : TStringList;
    FCompileTimeProcList    : TStringList;
    fCurrentDTProc          : TProcList;
    fCurrentRTProc          : TProcList;

    fRunTimeUnitList        : TStringList;
    fRunTimeUnitListImp     : TStringList;
    fCompileTimeUnitList    : TStringList;
    fCompileTimeUnitListImp : TStringList;

    RunTimeProcType: set of (InterfaceImporter, ClassImporter, RoutineImporter); //Birb
    procedure AddRequiredUnit(const UnitName: string;
      TimeMode: TTimeMode;
      InterfaceSection: boolean);
    function RegisterProc(const ProcName: string; TimeMode: TTimeMode; Attr: TProcAttr): TProcList;
  //  Procedure AddVarToProc(const ProcName : string;CompileTime : TCompileTime;
  //                         const VarString : string);
    procedure FinishProcs;
  private
    procedure StartParse;
    procedure FinishParse;
    procedure FinishParseSingleUnit;   // teo

    procedure ParseUnitHeader;
    procedure ParseGlobalDeclarations;

    function  GetConstantType: string;
    function  GetAsString(const ConstType, ConstValue: string): string;

    function  ParseConstantExpression(var ExpType: string): string;
    procedure ParseConstants;
    procedure ParseVariables;
    procedure ParseRoutines;
    procedure ParseTypes;
    // parses a type delcaration
    procedure ParseType(aTokenID: TPsPasToken; const TypeName: string;
      var TypeDescriptor: string; var CheckSemiColon: boolean);
    // helper method which parses a class or interface definition //Birb
    procedure ParseClassOrInterfaceDef(const aClassName: string; const isInterface: boolean); //Birb
    // helper method which parses a interface definition
    procedure ParseInterfaceDef(const aInterfaceName: string);
    // helper method which parses a class definition
    procedure ParseClassDef(const aClassName: string);
    // helper method which parses a routine decl (after the procedure name)
    function ParseProcDecl(var ProcName, decl, CallingConvention: string;
      Options: TProcDeclOptions; OwnerClass:String=''): TProcDeclInfo;
  public
    constructor Create(const IniFilename: string; aTokenHistoryLength: Integer = 5);
    destructor Destroy; override;
  public
    // output
    Unitname, OutputRT, OutputDT: string;
    // Controls went registering classes, at design time
    // the actual class type is used
    WriteDefines, UseUnitAtDT: boolean;
    // Class this to parse a unit
    procedure ParseUnit(const Input: string);
    procedure ParserError(Parser: TObject; Kind: TPSParserErrorKind);

    function  UnitNameRT: string;
    function  UnitNameCT: string;
    function  UnitNameCmp: string;
    procedure SaveToPath(const Path: string);

    property Writeln: TWriteln read fWriteln write SetWriteln;
    property Readln: TReadln read fReadln write setReadln;

    property SingleUnit : Boolean read FSingleUnit write FSingleUnit;  // teo
    property UnitPrefix : string read FUnitPrefix write FUnitPrefix;   // teo
    property CompPage   : String read FCompPage write FCompPage; // Niels
    property CompPrefix : String read FCompPrefix write FCompPrefix; // Niels
    property AfterInterfaceDeclaration: string read FAfterInterfaceDeclaration write FAfterInterfaceDeclaration;
    property AutoRenameOverloadedMethods: Boolean read FAutoRenameOverloadedMethods write FAutoRenameOverloadedMethods;


    property OutUnitList : TStringList read FOutUnitList;              // teo
  end; {TUnitParser}

const
  MaxSearchCount = 100;

implementation

const
 STR_IINTERFACE='IUNKNOWN';

procedure DefReadln(var S: string; const Promote, Caption: string);
begin
  S := '';
end; {DefReadln}

procedure DefWriteln(const S: string);
begin
end; {DefWriteln}

// Some method declaratinos may be very long.
// Delphi can't compile these, so we need to spit them manually.
function SplitIntoLines(AString: string): string;
const
  cSplitPosition: Byte = 200;
begin
  Result := '';
  while (Length(AString) > cSplitPosition) do
  begin
    Result := Result + LeftStr(AString, cSplitPosition) +
      ''' +' + #13 + #10  + '      ''';
    Delete(AString, 1, cSplitPosition);
  end;
  Result := Result + AString;
end;

constructor TUnitParser.Create(const IniFilename: string; aTokenHistoryLength: Integer = 5);
begin
  inherited create;
  FUnitPrefix := 'uPS';
  FCompPage   := 'Pascal Script';
  FCompPrefix := 'TPSImport';
  FCompileTimeFunctions := false;
  Writeln := nil;
  Readln := nil;
  Ini := TBigIniFile.Create(IniFilename);
  Ini.FlagDropApostrophes := True;
  ini.FlagDropCommentLines := True;
  Ini.FlagTrimRight := True;
  Ini.FlagFilterOutInvalid := True;

  fParser := TPSPascalParser.create;
  TokenHistoryLength := aTokenHistoryLength;
  if TokenHistoryLength > 0 then
    Setlength(LastTokens, TokenHistoryLength);

  FOutUnitList := TStringList.Create;
  FSingleUnit := True;
end; {Create}

destructor TUnitParser.Destroy;
begin
  FOutUnitList.Free;
  fParser.free;
  ini.free;
  inherited;
end; {Destroy}

procedure TUnitParser.SetWriteln(aWriteln: TWriteln);
begin
  if assigned(aWriteln) then
    fWriteln := aWriteln
//else
//  fWriteln := DefWriteln;
end; {SetWriteln}

procedure TUnitParser.SetReadln(aReadln: TReadln);
begin
  if assigned(aReadln) then
    fReadln := aReadln
//else
//  fReadln := DefReadln;
end; {SetWriteln}

procedure TUnitParser.AddToTokenHistory(const aToken: TPasToken);
begin
  if TokenHistoryLength <= 0 then exit;
  LastTokens[FTail] := aToken;
  FTail := (FTail + 1) mod TokenHistoryLength;
  if FTail = FHead then
    FHead := (FHead + 1) mod TokenHistoryLength
  else
    inc(TokenHistoryCount);
end; {AddToTokenHistory}

function TUnitParser.RemoveFromTokenHistory(var aToken: TPasToken): boolean;
begin
  Result := (TokenHistoryLength > 0) and (TokenHistoryCount <> 0);
  if result then
  begin
    aToken := LastTokens[FHead];
    FHead := (FHead + 1) mod TokenHistoryLength;
    dec(TokenHistoryCount);
  end;
end; {RemoveFromTokenHistory}
(*----------------------------------------------------------------------------*)
procedure TUnitParser.SetToken(aTokenID: TPSPasToken; aToken: string;  aTokenRow, aTokenCol: integer);
begin
  fToken.ID := aTokenID;
  fToken.data := Uppercase(aToken);
  fToken.Org  := aToken;
  fToken.row := aTokenRow;
  fToken.col := aTokenCol;
  AddToTokenHistory(fToken);
end; {InsertToken}

procedure TUnitParser.NextToken;
begin
  fPrevToken := fToken;
//  fprevOrgToken := fparser.OriginalToken;
  fParser.next;
  fToken.ID := fParser.CurrTokenID;
  fToken.data := fParser.GetToken;
  fToken.Org  := fParser.OriginalToken;
  fToken.row := fParser.Row;
  fToken.col := fParser.Col;
  AddToTokenHistory(fToken);
end; {NextToken}

// -----------------------------------------------------------------------------

procedure TUnitParser.skipToSemicolon; //Birb
begin
  while not ifmatch(CSTI_SemiColon) do //assuming EOF checks aren't needed since everywhere in this code it's done similarly (maybe parser throws exception at EOF so that loops similar to this one don't go on forever)
    NextToken;
end;

function TUnitParser.Ifmatch(atoken: TPSPasToken): boolean;
begin
  Result := TokenID = atoken;
  if result then
    NextToken;
end; {Ifmatch}

procedure TUnitParser.Match(atoken: TPSPasToken; err: string = '');
var
  Errormsg: string;
  TokenList: string;
  OldToken: TPasToken;
begin
  if not Ifmatch(atoken) then
  begin
    if err = '' then
      err := GetTokenName(atoken);
    Errormsg := 'Expecting Token ''' + err + ''' but ';
    case TokenID of
      CSTI_Identifier: Errormsg := Errormsg + 'Identifier ''' + Token;
      CSTI_Integer: Errormsg := Errormsg + 'Integer number ''' + Token;
      CSTI_Real: Errormsg := Errormsg + 'Floatpoint number ''' + Token;
      CSTI_String: Errormsg := Errormsg + 'String ''' + Token;
      CSTI_Char: Errormsg := Errormsg + 'Character ''' + Token;
      CSTI_HexInt: Errormsg := Errormsg + 'Hexadecimal number ''' + Token;
    else Errormsg := Errormsg + 'token ''' + GetTokenName(TokenID);
    end;
  // build the list of tokens
    TokenList := '';
    while RemoveFromTokenHistory(OldToken) do
    begin
      if OldToken.ID in [CSTI_Identifier, CSTI_Integer, CSTI_Real,
        CSTI_String, CSTI_Char, CSTI_HexInt] then
        TokenList := TokenList + OldToken.Data + ' '
      else
        TokenList := TokenList + GetTokenName(OldToken.ID) + ' ';
    end;
    RaiseError(Errormsg + ''' found' + NewLine + 'Previous tokens : ''' + TokenList + '''', TokenRow, TokenCol);
  end;
end; {Match}

// -----------------------------------------------------------------------------

procedure TUnitParser.ParseUnit(const Input: string);
begin
  UnitName := '';
  FOutUnitList.Clear;
  fparser.OnParserError := ParserError;
  fParser.SetText(Input);
  try
    StartParse;
    ParseUnitHeader;
    ParseGlobalDeclarations;
  finally
    case FSingleUnit of
      False : FinishParse;
      True  : FinishParseSingleUnit;
    end;
  end;
end; {ParseUnit}
(*----------------------------------------------------------------------------*)
procedure TUnitParser.AddRequiredUnit(const UnitName: string; TimeMode: TTimeMode; InterfaceSection: boolean);
var
  Unitlist : TStringList;  { ref }
  Index    : integer;
begin
// choice the correct list to Add it to
  Unitlist := nil;
  case TimeMode of
    CompileTime  : if InterfaceSection then
                     Unitlist := fCompileTimeUnitList
                   else Unitlist := fCompileTimeUnitListImp;
    RunTime      : if InterfaceSection then
                     Unitlist := fRunTimeUnitList
                   else Unitlist := fRunTimeUnitListImp;
    else         RaiseError('Unable to deterimine which used unit list' + ' to Add the unit ''' + UnitName + ''' to', TokenRow, TokenCol);
  end;
  Index := Unitlist.Indexof(UnitName);
  if Index = -1 then
    Unitlist.Add(UnitName)
end; {AddRequiredUnit}
(*----------------------------------------------------------------------------*)
function TUnitParser.RegisterProc(const ProcName: string; TimeMode: TTimeMode; Attr: TProcAttr): TProcList;
var
  proclist: TStringList;
  Index: integer;
begin
  if ProcName = '' then
    RaiseError('Invalid procedure name', TokenRow, TokenCol);

  if TimeMode = CompileTime then
    proclist := fCompileTimeproclist
  else proclist := fRunTimeProclist;
  
  assert(proclist <> nil);
  Index := proclist.IndexOf(ProcName);
  if Index = -1 then
  begin
    Result := TProcList.create;
    try
      Result.Add(ProcName);
      if not (IsHelper in Attr) then
        Result.Add('begin');
      Result.ProcAttr := Attr;
      proclist.AddObject(ProcName, Result);
    except
      Result.free;
      raise
    end;
  end
  else
    Result := proclist.Objects[Index] as TProcList;
end; {RegisterProc}
(*----------------------------------------------------------------------------*)
procedure TUnitParser.FinishProcs;
var
  Index: integer;
  obj: TObject;
begin
  if FRunTimeProcList <> nil then
    for Index := FRunTimeProcList.count - 1 downto 0 do
    begin
      obj := FRunTimeProcList.Objects[Index];
      if (obj is TProcList) and
        not (IsHelper in TProcList(obj).ProcAttr) then
        TProcList(obj).Add('end;');
    end;
  if FCompileTimeProcList <> nil then
    for Index := FCompileTimeProcList.count - 1 downto 0 do
    begin
      obj := FCompileTimeProcList.Objects[Index];
      if (obj is TProcList) and
        not (IsHelper in TProcList(obj).ProcAttr) then
        TProcList(obj).Add('end;');
    end;
end; {FinishProcs}

(*
Procedure TUnitParser.AddVarToProc(const ProcName : string;
                                   CompileTime : TCompileTime;
                                   const VarString : string);
var
  proc : TStringList;
begin
proc := RegisterProc(ProcName,CompileTime,false);
If Proc = nil then
  RaiseError('Procedure :"'+ProcName+'" can not be found');
If fastUppercase(Proc[1]) = 'VAR' then
  Proc.Insert(2,VarString)
else
  Proc.Insert(1,'var'+newline+VarString)
end; {AddVarToProc}
*)
(*----------------------------------------------------------------------------*)
procedure TUnitParser.StartParse;
begin
  SetToken(fParser.CurrTokenID, fParser.OriginalToken, fParser.Row, FParser.Col);
  OutputDT := '';
  OutputRT := '';

  FRunTimeProcList := TStringList.create;
  FCompileTimeProcList := TStringList.create;

  fRunTimeUnitList := TStringList.create;
  fRunTimeUnitListImp := TStringList.create;
  fCompileTimeUnitList := TStringList.create;
  fCompileTimeUnitListImp := TStringList.create;
end; {StartParse}
(*----------------------------------------------------------------------------*)
function  TUnitParser.UnitNameRT: string;
begin
  Result := Format('%sR_%s.pas', [FUnitPrefix, UnitName]);
end;
(*----------------------------------------------------------------------------*)
function  TUnitParser.UnitNameCT: string;
begin
  Result := Format('%sC_%s.pas', [FUnitPrefix, UnitName]);
end;

function TUnitParser.UnitNameCmp: string;
begin
  Result := Format('%sI_%s.pas', [FUnitPrefix, UnitName]);
end;


(*----------------------------------------------------------------------------*)
procedure TUnitParser.SaveToPath(const Path: string);
var
  List   : TStringList;
begin
  if SingleUnit then
  begin
    FOutUnitList.SaveToFile(Path + UnitNameCmp);
  end else begin
    List := TStringList.Create;
    try
      List.Text := OutputRT;
      List.SaveToFile(Path + UnitnameRT);

      List.Text := OutputDT;
      List.SaveToFile(Path + UnitnameCT);
    finally
      List.Free;
    end;
  end;
end;
(*----------------------------------------------------------------------------*)
procedure TUnitParser.FinishParse;
var
  OutPut  : TStringList;
  obj         : TObject;
  Index       : integer;
  S           : string;
begin
  try
    FinishProcs;

    {===================================================================================}
    // write out the design time unit
    if FCompileTimeProcList <> nil then
    begin
      OutPut := TStringList.create;
      try
        // insert the front of the text body   //FUnitPrefix
        //OutPutList.Add('unit ifpii_' + UnitName + ';');
        OutPut.Add('unit ' + ChangeFileExt(UnitNameCT, '') + ';');
        OutPut.Add(GetLicence);
//        OutPut.Add('{$I PascalScript.inc}');
        OutPut.Add('interface');
        OutPut.Add(FAfterInterfaceDeclaration);
        OutPut.Add(GetUsedUnitList(fCompileTimeUnitList) + Newline);

        for Index := FCompileTimeProcList.count - 1 downto 0 do
        begin
          obj := FCompileTimeProcList.objects[Index];
          if (obj is TProcList) and
            (PublicProc in TProcList(obj).ProcAttr) then
            OutPut.Add(FCompileTimeProcList[Index]);
        end;

        OutPut.Add('implementation');
        // insert the Designtime unit importer into the used unit list
        S := GetUsedUnitList(fCompileTimeUnitListImp);
        if S <> '' then
        begin
          Delete(S, length(S), 1);
          OutPut.Add(S);
(*          if WriteDefines then
          begin
            OutPut.Add('{$IFDEF USEIMPORTER}');
            OutPut.Add('  ,CIImporterU');
            OutPut.Add('{$ENDIF};');
          end;*)
          OutPut.Add(';');
        end else  begin
(*          if WriteDefines then
          begin
            OutPut.Add('{$IFDEF USEIMPORTER}');
            OutPut.Add('  uses CIImporterU;');
            OutPut.Add('{$ENDIF}');
          end;*)
        end;

        //OutPut.Add('');
        //Output.Add('const IID__DUMMY: TGUID = ''{00000000-0000-0000-0000-000000000000}'';'); //Birb (!!!could set some attribute to avoid spitting that out when not needed)
        //Output.Add('');

        // reinsert the main text body
        for Index := FCompileTimeProcList.count - 1 downto 0 do
        begin
          obj := FCompileTimeProcList.objects[Index];
          if (obj is TProcList) and
            (IsHelper in TProcList(obj).ProcAttr) then
            OutPut.Add(TStringList(obj).text);
        end;

        for Index := FCompileTimeProcList.count - 1 downto 0 do
        begin
          obj := FCompileTimeProcList.objects[Index];
          if (obj is TProcList) and
            (PublicProc in TProcList(obj).ProcAttr) then
            OutPut.Add(TStringList(obj).text);
        end;

        // insert the Runtime unit importer code into the end of the unit
(*        if WriteDefines then
        begin
          OutPut.Add('{$IFDEF USEIMPORTER}');
          OutPut.Add('initialization');
          OutPut.Add('CIImporter.AddCallBack(@SIRegister_' + UnitName + ',PT_ClassImport);');
          OutPut.Add('{$ENDIF}');
        end;*)
        OutPut.Add('end.');

      finally
        if OutPut <> nil then
          OutputDT := OutPut.text;
        OutPut.free;
      end;
    end;



   {===================================================================================}
   // write out the run time import unit
    if FRunTimeProcList <> nil then
    begin
      OutPut := TStringList.create;
      try
        OutPut.Add('unit ' + ChangeFileExt(UnitNameRT, '') + ';');
        OutPut.Add(GetLicence);
//        OutPut.Add('{$I PascalScript.inc}');
        OutPut.Add('interface');
        OutPut.Add(FAfterInterfaceDeclaration);        
        OutPut.Add(GetUsedUnitList(fRunTimeUnitList) + Newline);
        for Index := FRunTimeProcList.count - 1 downto 0 do
        begin
          obj := FRunTimeProcList.objects[Index];
          if (obj is TProcList) and
            (PublicProc in TProcList(obj).ProcAttr) then
            OutPut.Add(FRunTimeProcList[Index]);
        end;

        OutPut.Add('');
        OutPut.Add('implementation');

        // insert the Runtime unit importer into the used unit list
        S := GetUsedUnitList(fRunTimeUnitListImp);
        if RunTimeProcType <> [] then
        begin
          if S <> '' then
          begin
            Delete(S, length(S), 1);
            OutPut.Add(S);
(*            if WriteDefines then
            begin
              OutPut.Add('{$IFDEF USEIMPORTER}');
              OutPut.Add('  ,RIImporterU');
              OutPut.Add('{$ENDIF};');
            end;*)
            OutPut.Add(';');
          end
          else
          begin
(*            if WriteDefines then
            begin
              OutPut.Add('{$IFDEF USEIMPORTER}');
              OutPut.Add('  uses RIImporterU;');
              OutPut.Add('{$ENDIF}');
            end;*)
          end;
        end
        else OutPut.Add(S);

         // reinsert the main text body --IsHelper
        for Index := FRunTimeProcList.count - 1 downto 0 do
        begin
          obj := FRunTimeProcList.objects[Index];
          if (obj is TProcList) and
            (IsHelper in TProcList(obj).ProcAttr) then
            OutPut.Add(TProcList(obj).text);
        end;

        // reinsert the main text body  --PublicProc
        for Index := FRunTimeProcList.count - 1 downto 0 do
        begin
          obj := FRunTimeProcList.objects[Index];
          if (obj is TProcList) and
            (PublicProc in TProcList(obj).ProcAttr) then
            OutPut.Add(TProcList(obj).text);
        end;

        // Add the ending of the unit
        // insert the Runtime unit importer code into the end of the unit
        if RunTimeProcType <> [] then
        begin
(*          if WriteDefines then
          begin
            OutPut.Add('{$IFDEF USEIMPORTER}');
            OutPut.Add('initialization');
            if RoutineImporter in RunTimeProcType then
              OutPut.Add('RIImporter.AddCallBack(RIRegister_' + UnitName + '_Routines);');
            if ClassImporter in RunTimeProcType then
              OutPut.Add('RIImporter.Invoke(RIRegister_' + UnitName + ');');
            OutPut.Add('{$ENDIF}');
          end;*)
        end;
        OutPut.Add('end.');
      finally
        if OutPut <> nil then
          OutputRT := OutPut.text;
        OutPut.free;
      end;
    end;
  finally

    for Index := FRunTimeProcList.Count - 1 downto 0 do
    begin
      FRunTimeProcList.Objects[Index].Free;
    end;
    FreeAndNil(FRunTimeProcList);
    for Index := FCompileTimeProcList.Count - 1 downto 0 do
    begin
      FCompileTimeProcList.Objects[Index].Free;
    end;

    FreeAndNil(FCompileTimeProcList);
    FreeAndNil(fRunTimeUnitList);
    FreeAndNil(fRunTimeUnitListImp);
    FreeAndNil(fCompileTimeUnitList);
    FreeAndNil(fCompileTimeUnitListImp);
  end;
end; {FinishParse}

(*----------------------------------------------------------------------------*)
procedure TUnitParser.FinishParseSingleUnit;
  {-------------------------------------------}
  procedure ProcessUsesList(List: TStrings);
  var
    i : Integer;
  begin
    if List.Count > 0 then
    begin
      List[0] := '   ' + List[0];

      for i := 1 to List.Count - 1 do
        List[i] := '  ,' + List[i];

      List.Insert(0, 'uses');
      List.Add('  ;')
    end;
  end;
  {-------------------------------------------}
  procedure AddToUsesList(UsesList, CheckList: TStrings; const AUnitName: string);
  var
    i : Integer;
    S : string;
  begin
    S := UpperCase(AUnitName);

    if Assigned(CheckList) then
    begin
      for i := 0 to CheckList.Count - 1 do
        if UpperCase(CheckList[i]) = S then
          Exit; //==>
    end;

    for i := 0 to UsesList.Count - 1 do
      if UpperCase(UsesList[i]) = S then
       Exit; //==>

    UsesList.Add(AUnitName);
  end;
var
  OutPutList  : TStringList;
  InterfaceUsesList       : TStringList; { helper }
  ImplementationUsesList  : TStringList; { helper }
  List                    : TStringList;
  obj         : TObject;
  Index       : integer;
  //S           : string;
  i           : Integer;
  sClassName  : string;
begin
  OutPutList := TStringList.Create;
  ImplementationUsesList       := TStringList.Create;
  InterfaceUsesList            := TStringList.Create;
  List                         := TStringList.Create;

//  ImplementationUsesList .CaseSensitive := False;
//  InterfaceUsesList      .CaseSensitive := False;
  try
    FinishProcs;

    { unit name, etc. }
    OutPutList.Add('unit ' + ChangeFileExt(UnitNameCmp, '') + ';');
    OutPutList.Add(GetLicence);
//    OutPutList.Add('{$I PascalScript.inc}');
    OutPutList.Add('interface');
    OutPutList.Add(' ');
    OutPutList.Add(FAfterInterfaceDeclaration);
    OutPutList.Add(' ');    

    { interface uses clause list }
    AddToUsesList(InterfaceUsesList, nil, 'SysUtils');
    AddToUsesList(InterfaceUsesList, nil, 'Classes');
    AddToUsesList(InterfaceUsesList, nil, 'uPSComponent');
    AddToUsesList(InterfaceUsesList, nil, 'uPSRuntime');
    AddToUsesList(InterfaceUsesList, nil, 'uPSCompiler');

    if Assigned(FCompileTimeProcList) then
      for i := 0 to FCompileTimeUnitList.Count - 1 do
        AddToUsesList(InterfaceUsesList, nil, FCompileTimeUnitList[i]);

    if Assigned(FRunTimeProcList) then
      for i := 0 to FRunTimeUnitList.Count - 1 do
        AddToUsesList(InterfaceUsesList, nil, FRunTimeUnitList[i]);

    List.Assign(InterfaceUsesList);
    ProcessUsesList(List);
    OutPutList.AddStrings(List);
    OutPutList.Add(' ');

    sClassName := FCompPrefix + '_' + UnitName ;
    OutPutList.Add('type ');
    OutPutList.Add('(*----------------------------------------------------------------------------*)');
    OutPutList.Add(Format('  %s = class(TPSPlugin)', [sClassName]));
    OutPutList.Add('  public');
//  OutPutList.Add('    procedure CompOnUses(CompExec: TPSScript); override;');
//  OutPutList.Add('    procedure ExecOnUses(CompExec: TPSScript); override;');
    OutPutList.Add('    procedure CompileImport1(CompExec: TPSScript); override;');
//  OutPutList.Add('    procedure CompileImport2(CompExec: TPSScript); override;');
    OutPutList.Add('    procedure ExecImport1(CompExec: TPSScript; const ri: TPSRuntimeClassImporter); override;');
//  OutPutList.Add('    procedure ExecImport2(CompExec: TPSScript; const ri: TPSRuntimeClassImporter); override;');
    OutPutList.Add('  end;');
    OutPutList.Add(' ');
    OutPutList.Add(' ');


    { compile-time function declarations }
      if Assigned(FCompileTimeProcList) then
      begin
        OutPutList.Add('{ compile-time registration functions }');
        for Index := FCompileTimeProcList.count - 1 downto 0 do
        begin
          obj := FCompileTimeProcList.objects[Index];
          if (obj is TProcList) and
            (PublicProc in TProcList(obj).ProcAttr) then
            OutPutList.Add(FCompileTimeProcList[Index]);
        end;
      end;

      OutPutList.Add('');

      { run-time function declarations }
      if Assigned(FRunTimeProcList) then
      begin
        OutPutList.Add('{ run-time registration functions }');
        for Index := FRunTimeProcList.count - 1 downto 0 do
        begin
          obj := FRunTimeProcList.objects[Index];
          if (obj is TProcList) and
            (PublicProc in TProcList(obj).ProcAttr) then
            OutPutList.Add(FRunTimeProcList[Index]);
        end;
      end;

    OutPutList.Add('');

    OutPutList.Add('procedure Register;');

    OutPutList.Add('');
    OutPutList.Add('implementation');
    OutPutList.Add('');
    OutPutList.Add('');


    { implementation uses clause }
     if Assigned(FCompileTimeProcList) then
       for i := 0 to FCompileTimeUnitListImp.Count - 1 do
         AddToUsesList(ImplementationUsesList, InterfaceUsesList, FCompileTimeUnitListImp[i]);


    if Assigned(FRunTimeProcList) then
       for i := 0 to FRunTimeUnitListImp.Count - 1 do
         AddToUsesList(ImplementationUsesList, InterfaceUsesList, FRunTimeUnitListImp[i]);

(*    if WriteDefines then
    begin
      ImplementationUsesList.Add('CIImporterU');
      if RunTimeProcType <> [] then
        ImplementationUsesList.Add('RIImporterU');
    end;*)

    List.Assign(ImplementationUsesList);
    ProcessUsesList(List);
    (*
    i := List.IndexOf('CIImporterU');
    if i <> -1 then
    begin
      if i = 1 then
        List[i] := '{$IFDEF USEIMPORTER} CIImporterU {$ENDIF}'
      else List[i] := '{$IFDEF USEIMPORTER} ,CIImporterU {$ENDIF}';
    end;
    i := List.IndexOf('RIImporterU');
    if i <> -1 then
    begin
      if i = 1 then
        List[i] := '{$IFDEF USEIMPORTER} RIImporterU {$ENDIF}'
      else List[i] := '{$IFDEF USEIMPORTER} ,RIImporterU {$ENDIF}';
    end;

*)


    OutPutList.AddStrings(List);
    OutPutList.Add(' ');
    OutPutList.Add(' ');
          OutPutList.Add('procedure Register;');
          OutPutList.Add('begin');
          OutPutList.Add('  RegisterComponents('''+FCompPage+''', ['+FCompPrefix + '_' + UnitName+']);');
          OutPutList.Add('end;');
          OutPutList.Add('');

    { compile-time function definitions }
    if Assigned(FCompileTimeProcList) then
    begin
      OutPutList.Add('(* === compile-time registration functions === *)');

      // reinsert the main text body
      for Index := FCompileTimeProcList.count - 1 downto 0 do
      begin
        obj := FCompileTimeProcList.objects[Index];
        if (obj is TProcList) and (IsHelper in TProcList(obj).ProcAttr) then
        begin
          OutPutList.Add('(*----------------------------------------------------------------------------*)');
          OutPutList.Add(TStringList(obj).text);
        end;
      end;

      for Index := FCompileTimeProcList.count - 1 downto 0 do
      begin
        obj := FCompileTimeProcList.objects[Index];
        if (obj is TProcList) and (PublicProc in TProcList(obj).ProcAttr) then
        begin
          OutPutList.Add('(*----------------------------------------------------------------------------*)');
          OutPutList.Add(TStringList(obj).text);
        end;
      end;
    end;

    { run-time function definitions }
    if Assigned(FRunTimeProcList) then
    begin
      OutPutList.Add('(* === run-time registration functions === *)');

      // reinsert the main text body --IsHelper
      for Index := FRunTimeProcList.count - 1 downto 0 do
      begin
        obj := FRunTimeProcList.objects[Index];
        if (obj is TProcList) and (IsHelper in TProcList(obj).ProcAttr) then
        begin
          OutPutList.Add('(*----------------------------------------------------------------------------*)');
          OutPutList.Add(TProcList(obj).text);
        end;
      end;

      // reinsert the main text body  --PublicProc
      for Index := FRunTimeProcList.count - 1 downto 0 do
      begin
        obj := FRunTimeProcList.objects[Index];
        if (obj is TProcList) and (PublicProc in TProcList(obj).ProcAttr) then
        begin
          OutPutList.Add('(*----------------------------------------------------------------------------*)');
          OutPutList.Add(TProcList(obj).text);
        end;
      end;
    end;

    OutPutList.Add(' ');
    OutPutList.Add(' ');
    OutPutList.Add(Format('{ %s }', [sClassName]));
    OutPutList.Add('(*----------------------------------------------------------------------------*)');
    OutPutList.Add(Format('procedure %s.CompileImport1(CompExec: TPSScript);', [sClassName]));
    OutPutList.Add('begin');
    OutPutList.Add(Format('  SIRegister_%s(CompExec.Comp);', [UnitName]));
    OutPutList.Add('end;');
    OutPutList.Add('(*----------------------------------------------------------------------------*)');
    OutPutList.Add(Format('procedure %s.ExecImport1(CompExec: TPSScript; const ri: TPSRuntimeClassImporter);', [sClassName]));
    OutPutList.Add('begin');

    // Birb: (!!!) should fix it so that this line is never added if there's
    // no RIRegister...routine (e.g. if unit has just constants)
    if (ClassImporter in RunTimeProcType) then
      OutPutList.Add(Format('  RIRegister_%s(ri);', [UnitName]));

    if RoutineImporter in RunTimeProcType then
      OutPutList.Add(Format('  RIRegister_%s_Routines(CompExec.Exec); // comment it if no routines', [UnitName]));

    OutPutList.Add('end;');
    OutPutList.Add('(*----------------------------------------------------------------------------*)');


    OutPutList.Add(' ');
    OutPutList.Add(' ');

    OutPutList.Add('end.');
  finally
    for Index := FRunTimeProcList.Count - 1 downto 0 do
    begin
      FRunTimeProcList.Objects[Index].Free;
    end;
    FreeAndNil(FRunTimeProcList);
    for Index := FCompileTimeProcList.Count - 1 downto 0 do
    begin
      FCompileTimeProcList.Objects[Index].Free;
    end;

    FreeAndNil(FCompileTimeProcList);
    FreeAndNil(fRunTimeUnitList);
    FreeAndNil(fRunTimeUnitListImp);
    FreeAndNil(fCompileTimeUnitList);
    FreeAndNil(fCompileTimeUnitListImp);

    List.Free;
    ImplementationUsesList.Free;
    InterfaceUsesList.Free;
    FOutUnitList.Assign(OutPutList);
    OutPutList.Free;
  end;

end;
(*----------------------------------------------------------------------------*)
procedure TUnitParser.ParseUnitHeader;
begin
// parser 'Unit <identifier>;'
  Match(CSTII_Unit);
  Match(CSTI_Identifier);
  Unitname := prevOrgToken;
  Match(CSTI_SemiColon);
  Match(CSTII_Interface);
// parser the units clause 'uses <identifier>[, <identifier>];'
  if IfMatch(CSTII_uses) then
  begin
    repeat
      Match(CSTI_Identifier);
      AddRequiredUnit(PrevOrgToken, RunTime, false);
//    AddRequiredUnit(PrevToken,CompileTime,false);
      if TokenID = CSTI_SemiColon then
      begin
        Match(CSTI_SemiColon);
        break;
      end
      else
        Match(CSTI_Comma, ','' or '';');
    until false;
  end;

  AddRequiredUnit(UnitName, RunTime, false);
  fCurrentDTProc := RegisterProc('procedure SIRegister_' + UnitName +
                       '(CL: TPSPascalCompiler);', CompileTime, [PublicProc]);
  AddRequiredUnit('uPSCompiler', CompileTime, True);
  AddRequiredUnit('uPSRuntime', RunTime, true);

  RunTimeProcType := [];
  fCurrentRTProc := nil;
end; 
(*----------------------------------------------------------------------------*)
procedure TUnitParser.ParseGlobalDeclarations;
begin
  while not IfMatch(CSTII_Implementation) do
    case TokenID of
      CSTII_var       : ParseVariables;
      CSTII_const     : ParseConstants;
      CSTII_type      : ParseTypes;
      CSTII_procedure ,
      CSTII_function  : ParseRoutines;
      CSTI_Identifier : RaiseError('Declaration expected but identifier ''' + OrgToken + ''' found', TokenRow, TokenCol);
      else              RaiseError('Unknown keyword ''' + GetTokenName(TokenID) + '''', TokenRow, TokenCol);
    end;
end;
(*----------------------------------------------------------------------------*)
function TUnitParser.GetConstantType: string;
var
  value: int64;
begin
  Result := '';
// determine the constant type
  case TokenID of
    CSTI_Integer:
      begin
        value := StrToInt64(Token);
        if (value < low(Longint)) then
          Result := 'Int64'
        else if value > High(Longint) then
        begin
          if value > High(longword) then
            Result := 'Int64'
          else
            Result := 'LongWord'
        end
        else
          Result := 'LongInt';
      end;
    CSTI_HexInt: Result := 'LongWord';
    CSTI_Real: Result := 'Extended';
    CSTI_String: Result := 'String';
    CSTI_Char: Result := 'Char';
    CSTI_Identifier:
      begin // unknown identifier
        if (Token = 'FALSE') or
          (Token = 'TRUE') then
          Result := 'Boolean';
      end;
  else RaiseError('Expected valid type, but found ''' + GetTokenName(TokenID) + '''', TokenRow, TokenCol);
  end; {case}
end; {GetConstantType}

function TUnitParser.ParseConstantExpression(var ExpType: string): string;
var
  BracketCount: integer;
  BlkBracketCount: integer;
begin
  result := '';
  BracketCount := 0;
  BlkBracketCount := 0;
  repeat
  // generate the actual string
    case TokenID of
      CSTI_OpenBlock:
        BEGIN
          ExpType := 'ConstSet';
          Inc(BlkBracketCount);
        end;
      CSTI_Comma: If BlkBracketCount>0 then
        Result := Result + ' or ';
      CSTI_CloseBlock:
        begin // prevent adding brakets when there should not be
          if blkBracketCount <> 0 then
          begin
            dec(BlkBracketCount);
            if (Result = '') and (BlkBracketCount = 0) then Result := '0';
          end
          else break;
        end;
      CSTI_Integer, CSTI_HexInt, CSTI_Real,
        CSTI_String, CSTI_Char, CSTI_Identifier:
        begin
          if (TokenId = CSTI_Identifier) and (BlkBracketCount>0) then begin
            result := result + 'ord('+orgtoken+')';
          end else begin
            ExpType := GetConstantType;
            // convert sveral consecutive characters into a string
            if (PrevTokenID = CSTI_Char) and
              (TokenID = CSTI_Char) then
            begin
              Result := Result + orgtoken;
              ExpType := 'String';
            end
            else
              Result := Result + ' ' + orgToken;
          end;
        end;
      CSTI_Equal: Result := Result + ' =';
      CSTI_NotEqual: Result := Result + ' <>';
      CSTI_Greater: Result := Result + ' >';
      CSTI_GreaterEqual: Result := Result + ' >=';
      CSTI_Less: Result := Result + ' <';
      CSTI_LessEqual: Result := Result + ' <=';
      CSTI_Plus: Result := Result + ' +';
      CSTI_Minus: Result := Result + ' -';
      CSTI_Divide: begin Result := Result + ' /'; ExpType := 'Extended'; end;
      CSTII_div: Result := Result + ' div';
      CSTI_Multiply: Result := Result + ' *';
      CSTI_AddressOf: Result := Result + ' @';
      CSTI_Dereference: Result := Result + ' ^';
      CSTII_and: Result := Result + ' and';
      CSTII_mod: Result := Result + ' mod';
      CSTII_not: Result := Result + ' not';
      CSTII_or: Result := Result + ' or';
      CSTII_shl: Result := Result + ' shl';
      CSTII_shr: Result := Result + ' shr';
      CSTII_xor: Result := Result + ' xor';
      CSTII_Chr: begin
                   // jgv
                   Result := Result + ' char(';
                   NextToken;
                   Match (CSTI_OpenRound);
                   Result := Result + ParseConstantExpression(ExpType) + ')';
                   Match (CSTI_CloseRound);
                   break;
                   //Result := Result + ' char(' + ParseConstantExpression(ExpType) + ')';
                 end;
      CSTII_Ord: begin
                   // jgv
                   Result := Result + ' ord(';
                   NextToken;
                   Match (CSTI_OpenRound);
                   Result := Result + ParseConstantExpression(ExpType);
                   Match (CSTI_CloseRound);
                   break;
                   //Result := Result + ' ord(' + ParseConstantExpression(ExpType) + ')';
                 end;
      CSTI_OpenRound: begin Result := Result + ' ('; inc(BracketCount); end;
      CSTI_CloseRound:
        begin // prevent adding brakets when there should not be
          if BracketCount <> 0 then
          begin
            Result := Result + ' )';
            dec(BracketCount)
          end
          else break;
        end;
    end;
    NextToken; 
  until (not (TokenID in [CSTI_Integer, CSTI_HexInt, CSTI_Real, CSTI_String, CSTI_Char,
    CSTI_Equal, CSTI_NotEqual, CSTI_Greater, CSTI_GreaterEqual,
      CSTI_Less, CSTI_LessEqual, CSTI_Plus, CSTI_Minus, CSTI_Divide,
      CSTII_div, CSTI_Multiply, CSTI_AddressOf, CSTI_Dereference,
      CSTII_and, CSTII_mod, CSTII_not, CSTII_or, CSTII_shl, CSTII_shr,
      CSTII_xor, CSTII_Chr, CSTII_Ord, CSTI_OpenRound, CSTI_CloseRound])) and ((BlkBracketCount=0) or
      not (TokenID in [CSTI_COmma,CSTI_Identifier, CSTI_CloseBlock ])) ;
end; {ParseConstantExpression}

function TUnitParser.GetAsString(const ConstType, ConstValue: string): string;
begin
  if ConstType = 'BOOLEAN' then
  begin
    with RegisterProc('Function BoolToStr(value : boolean) : string;', CompileTime, [IsHelper]) do
    begin
      if IsDone in ProcAttr then exit;
      include(ProcAttr, IsDone);
      Add('Begin If value then Result := ''TRUE'' else Result := ''FALSE'' End;');
    end;
    Result := 'BoolToStr(' + ConstValue + ')';
  end
  else If ConstType = 'CONSTSET' then
    result := '.Value.ts32 := '+ConstValue
//  Result := ConstValue
//else If ConstType = 'CHAR' then
//  Result := ''
  else
  begin
    AddRequiredUnit('Sysutils', CompileTime, false);
    if (ConstType = 'BOOLEAN') then
      Result := '.SetInt(Ord(' + Constvalue + '))'
    else if (ConstType = 'LONGINT') or (ConstType = 'INTEGER') then
      Result := '.SetInt(' + ConstValue + ')'
    else if (ConstType = 'INT64') then
      Result := '.SetInt64(' + ConstValue + ')'
    else if (ConstType = 'LONGWORD') or (ConstType = 'BYTE') or (ConstType = 'WORD') then
      Result := '.SetUInt(' + ConstValue + ')'
    else if (ConstType = 'EXTENDED') or (ConstType = 'DOUBLE') or (ConstType = 'SINGLE') then
      Result := '.setExtended(' + ConstValue + ')'
    else
      Result := '.SetString(' + ConstValue + ')';
  end;
end; {GetAsString}

procedure TUnitParser.ParseConstants;
var
  ConstName, ConstType, ConstValue, Expression: string;
  l: Longint;
begin
  Match(CSTII_const);
  repeat
    try
      Match(CSTI_Identifier);
      ConstName := PrevOrgToken;
      if IfMatch(CSTI_Colon) then
      begin
        ConstType := OrgToken;
        NextToken;
        Match(CSTI_Equal);
        Expression := ParseConstantExpression(Expression);
      end else begin
        Match(CSTI_Equal, ':'' or ''=');
        Expression := ParseConstantExpression(ConstType);
      end;
      Match(CSTI_SemiColon);
      if UseUnitAtDT then
        ConstValue := ConstName
      else
        ConstValue := Expression;
      if ConstType = '' then
        ReadLn(ConstType, 'Expression (' + Expression + ') :', 'Unable to determine expression type');
      // now output the value   //   String(   //teo
      If ConstType = 'ConstSet' then
        fCurrentDTProc.Add(' CL.AddConstantN(''' + ConstName + ''',' + '''LongInt'')' + GetAsString(FastUppercase(ConstType), ConstValue) + ';')
      else
        fCurrentDTProc.Add(' CL.AddConstantN(''' + ConstName + ''',' + '''' + ConstType + ''')' + GetAsString(FastUppercase(ConstType), ConstValue) + ';');
    except
   // Hack: We cannot succesfully parse this, but that doesn't mean we should stop.
      on e: Exception do
      begin
        Writeln('Warning, could not parse const: ' + e.Message);
        l := 0;
        while TokenId <> CSTI_Eof do
        begin
          NextToken;
          if TokenId = CSTI_OpenBlock then
            inc(l)
          else if TokenId = CSTI_CloseBlock then
            Dec(l)
          else if TokenId = CSTI_OpenRound then
            inc(l)
          else if TokenId = CSTI_CloseRound then
            Dec(l)
          else if (TokenId = CSTI_SemiColon) and (l <= 0) then
            break;
        end;
        Match(CSTI_Semicolon);
      end;
    end;
  until (TokenID <> CSTI_Identifier);
end; {ParseConstants}

procedure TUnitParser.ParseVariables;
begin
{todo 3-cWishList : generate wrapper code to allow a script to access a variable}
  Match(CSTII_var);
  repeat
    Match(CSTI_Identifier);
    Match(CSTI_Colon);
    NextToken;
    if IfMatch(CSTI_Equal) then
      NextToken;
    Match(CSTI_SemiColon);
  until (TokenID <> CSTI_Identifier);
end; {ParseVariables}

function TUnitParser.ParseProcDecl(var ProcName, decl, CallingConvention: string;
  Options: TProcDeclOptions; OwnerClass:String=''): TProcDeclInfo;
var
  VarListFirst: boolean;
  FinishedProcDecl: boolean;
  ParamNames: TStringList;
  Olddecl, OldProcName, ParamStr,
  s, Decl2: string;
  Index: integer;
  CheckSemiColon: boolean;
  Proc: TProcList;
begin
  Result := [];
  if IfMatch(CSTII_function) then
  begin
    Include(Result, IsFunction);
    decl := 'Function ';
  end
  else if IfMatch(CSTII_Procedure) then
    decl := 'Procedure '
  else if IfMatch(CSTII_Constructor) then
  begin
    if not (IsMethod in Options) then
      RaiseError('Constructor directive only applies to methods: '+OwnerClass, TokenRow, TokenCol);
    Include(Result, IsConstructor);
    decl := 'Constructor '
  end
  else if IfMatch(CSTII_Destructor) then
  begin
    if not (IsMethod in Options) then
      RaiseError('Destructor directive only applies to methods: '+OwnerClass, TokenRow, TokenCol);
    Include(Result, IsDestructor);
    decl := 'Destructor '
  end
  else
    Match(CSTII_Procedure, 'Function'' Or ''Procedure');

  if not (Ispointer in Options) then
  begin
    Match(CSTI_Identifier);
    ProcName := PrevOrgToken;
    decl := decl + PrevOrgToken;
  end
  else
    ProcName := '';
  ParamNames := TStringList.create;
  try
    if IfMatch(CSTI_OpenRound) then
    begin
      decl := decl + '( ';
      while not IfMatch(CSTI_CloseRound) do
      begin
        if IfMatch(CSTII_var) then
          decl := decl + 'var '
        else if Ifmatch(CSTII_out) then //Birb
          decl := decl + 'out '         //Birb
        else if Ifmatch(CSTII_const) then
          decl := decl + 'const ';
    // get the list of variable names
        VarListFirst := true;
        repeat
          Match(CSTI_Identifier);
          if VarListFirst then
          begin
            VarListFirst := false;
            decl := decl + PrevOrgToken;
          end
          else
            decl := decl + ', ' + PrevOrgToken;
          ParamNames.Add(PrevOrgToken);
          if TokenID = CSTI_Colon then
            Break;

          //-- jgv untyped parameters
          if TokenID in [CSTI_CloseRound, CSTI_SemiColon] then begin
            Writeln('Untyped Pointers parameters are not supported, this declaration will fail. At position :' + inttostr(TokenRow) + ':' + inttostr(TokenCol));
            if TokenID = CSTI_SemiColon then begin
              NextToken;
              Continue;
            end
            else
              Break; // jgv untyped parameter
          end;

          IfMatch(CSTI_Comma);
        until false;

        // jgv untyped parameter
        if not (TokenID in [CSTI_CloseRound, CSTI_SemiColon]) then begin
          Match(CSTI_Colon);
          // get the type
          decl := decl + ' : ';
          CheckSemiColon := true;
          ParseType(TokenID, ProcName, decl, CheckSemiColon);
        end; //-- end jgv

        if TokenID = CSTI_Equal then
        begin // stip the default part of the varaible declaration
          NextToken;
          ParseConstantExpression(ParamStr);
        end;
        if CheckSemiColon and Ifmatch(CSTI_SemiColon) and
          (TokenID <> CSTI_CloseRound) then
          decl := decl + '; '
      end;
      decl := decl + ')';
    end;
// parse the ' : <typename>' part of a function
    if IsFunction in Result then
    begin
      Match(CSTI_Colon);
      Match(CSTI_Identifier);
      decl := decl + ' : ' + PrevOrgToken;
    end;
// parse Calling Conventions & other misc bits that are taken to
// the end of a routine declaration
    CallingConvention := 'cdRegister';
    FinishedProcDecl := false;
// check if we are a method pointer
    if IsPointer in Options then
    begin
      if Ifmatch(CSTII_of) then
      begin
        if (TokenID <> CSTI_Identifier) or
          (Token <> 'OBJECT') then
          RaiseError('Expecting Token ''Object'' but found ''' + GetTokenName(TokenID) + '''', TokenRow, TokenCol)
        else NextToken;
      end
      else
    {todo 1 -cWishList : normal function pointers are not supported by the script, only method pointers}
        Decl := '';
    end;
    Match(CSTI_Semicolon);
    repeat
      case TokenID of
        CSTII_External:
          begin
            if (IsPointer in Options) or
              (IsMethod in Options) then
              RaiseError('External directive only applies to routines ('+OwnerClass + ProcName + ')', TokenRow, TokenCol);
            NextToken;
            Match(CSTI_Semicolon);
          end;
        CSTII_Export:
          begin
            if (IsPointer in Options) or
              (IsMethod in Options) then
              RaiseError('Export directive only applies to routines (' + OwnerClass +ProcName + ')', TokenRow, TokenCol);
            NextToken;
            Match(CSTI_Semicolon);
          end;
        CSTII_Forward:
          begin
            if (IsPointer in Options) or
              (IsMethod in Options) then
              RaiseError('Forward directive only applies to routines (' + OwnerClass +ProcName + ')', TokenRow, TokenCol);
            NextToken;
            Match(CSTI_Semicolon);
          end;
        CSTII_Override:
          begin
            if not (IsMethod in Options) then
              RaiseError('Override directive only applies to methods (' + OwnerClass +ProcName + ')', TokenRow, TokenCol);
            decl := '';
            NextToken;
            Match(CSTI_Semicolon);
          end;
        CSTII_Virtual:
          begin
            if not (IsMethod in Options) then
              RaiseError('Virtual directive only applies to methods (' + OwnerClass +ProcName + ')', TokenRow, TokenCol);
            NextToken;
            Match(CSTI_Semicolon);
            include(Result, IsVirtual);
            if Token = 'ABSTRACT' then
            begin
              NextToken;
              Match(CSTI_Semicolon);
              include(Result, IsAbstract);
            end;
          end;
        CSTI_Identifier:
          begin
    // check for calling conversion
            if Token = 'MESSAGE' then
            begin
              if not (IsMethod in Options) then
                RaiseError('Override directive only applies to methods (' + OwnerClass +ProcName + ')', TokenRow, TokenCol);
              NextToken;
              Match(CSTI_Identifier);
              Match(CSTI_Semicolon);
            end else
              if Token = 'DYNAMIC' then
              begin
                if not (IsMethod in Options) then
                  RaiseError('Method directive only applies to methods (' + OwnerClass + ProcName + ')', TokenRow, TokenCol);
                NextToken;
                Match(CSTI_Semicolon);
                include(Result, IsVirtual);
                if Token = 'ABSTRACT' then
                begin
                  NextToken;
                  Match(CSTI_Semicolon);
                  include(Result, IsAbstract);
                end;
              end else if Token = 'PASCAL' then
              begin
                CallingConvention := 'cdPascal';
                NextToken; ;
                Match(CSTI_Semicolon);
              end else if Token = 'REGISTER' then
              begin
                CallingConvention := 'cdRegister';
                NextToken;
                Match(CSTI_Semicolon);
              end else if Token = 'CDECL' then
              begin
                CallingConvention := 'CdCdecl';
                NextToken;
                Match(CSTI_Semicolon);
              end else if (Token = 'STDCALL') or
                (Token = 'SAFECALL') then
              begin
      // map a safecall to stdcall
      // (safecall cause special wrapper code to be implemented client side)
                CallingConvention := 'CdStdCall';
                NextToken;
                Match(CSTI_Semicolon);

              end else if not (Ispointer in Options) then
              begin
                if (token = 'OVERLOAD') then
                begin
//                  if (IsPointer in Options) then
//                    RaiseError('overload directive does not applies to function/method pointers', TokenRow, TokenCol);
                  Writeln('Overloading isnt supported. Remapping of name required '+OwnerClass +Decl);
                  OldProcName := ProcName;
                  Olddecl := decl;
                  s := '';
                  ProcName := OldProcName + InttoStr(FRenamingHelper);
                  Inc(FRenamingHelper);
                  repeat
                    if FAutoRenameOverloadedMethods then
                      Writeln('Auto-remapped')
                    else
                      Readln(ProcName, s+'Current declaration :' + '''' + OwnerClass +decl + '''', 'Enter new name.');
                      
                    if ProcName = '' then
                      ProcName := OldProcName;

                    // create a tmp procedure to handle the overload.
                    decl2 := decl;

                    If (IsMethod in Options) then
                      if (Pos('(',decl)=0)then
                        decl2 := StringReplace(decl, OldProcName, OldProcName+'(Self: '+Ownerclass+')', [rfIgnoreCase])
                      else
                        decl2 := StringReplace(decl, OldProcName+'(', OldProcName+'(Self: '+Ownerclass+'; ', [rfIgnoreCase]);

                    decl2 := StringReplace(decl2, OldProcName, OwnerClass+ProcName+'_P', [rfIgnoreCase]);
                    decl := StringReplace(decl, OldProcName, ProcName, [rfIgnoreCase])+';';
                    If (IsConstructor in Result) then begin
                      decl2 := StringReplace(decl2, 'Constructor', 'Function', [rfIgnoreCase]);
                      decl2 := StringReplace(decl2, ')', '):TObject', [rfIgnoreCase]);
                      decl2 := StringReplace(decl2, 'Self: '+Ownerclass, 'Self: TClass; CreateNewInstance: Boolean', [rfIgnoreCase]);
                    end;
                    If (IsDestructor in Result) then
                      decl2 := StringReplace(decl2, 'Destructor', 'Procedure', [rfIgnoreCase]);
                    decl2 := decl2 +';';
                    Proc := RegisterProc(decl2, RunTime, [IsHelper]);
                    if {not} (IsDone in Proc.ProcAttr) then
                    begin
                      If S = '' then
                        S := 'Procedure name has been used, enter a new one'^m;
                      ProcName := OldProcName;
                      decl := Olddecl;
                    end
                    else break;
                  until false;
                  Include(result,IsCallHelper);
                  Include(Proc.ProcAttr, IsDone);
                  Writeln('New Name :''' + ProcName + '''');
                  with Proc do
                  begin
                    ParamStr := '';
                    if ParamNames.count <> 0 then
                    begin
                      for Index := 0 to ParamNames.count - 1 do
                        ParamStr := ParamStr + ', ' + ParamNames[Index];
                    end;
                    system.Delete(ParamStr,1,2);
                    s := '';
                    If (IsFunction in Result) then s := 'Result := ';
                    If ParamStr <> '' then ParamStr := '('+ParamStr +')';
                    If (IsConstructor in Result) then
                      Add('Begin Result := '+OwnerClass+'.' + OldProcName+ParamStr+'; END;')
                    else
                    If (IsMethod in Options) then
                      Add('Begin '+S+'Self.' + OldProcName+ParamStr+'; END;')
                    else
                      Add('Begin '+s+UnitName + '.' + OldProcName +ParamStr+ '; END;');
                  end;
                end;
                NextToken;
                Match(CSTI_Semicolon);
              end
              else
                exit;
    // get the next token
          end;
      else FinishedProcDecl := true;
      end;
    until FinishedProcDecl;
  finally
    ParamNames.free;
  end;
end; {ParseProcDecl}

procedure TUnitParser.ParseRoutines;
var
  decl, ProcName, CallingConvention: string;
begin
  AddRequiredUnit('uPSRuntime', RunTime, true);
  include(RunTimeProcType, RoutineImporter);
  fCurrentRTProc := RegisterProc('procedure RIRegister_' + UnitName + '_Routines(S: TPSExec);', RunTime, [PublicProc]);
// build the function declaration
  ParseProcDecl(ProcName, Decl, CallingConvention, []);
  if decl <> '' then
  begin
    fCurrentDTProc.Add(' CL.AddDelphiFunction(''' + decl + ''');');  // teo -undeclared identifier RegisterDelphiFunctionC
    fCurrentRTProc.Add(' S.RegisterDelphiFunction(@' + ProcName + ', ''' +  ProcName + ''', ' + CallingConvention + ');');
  end;
end; {ParseRoutines}

procedure TUnitParser.ParseClassOrInterfaceDef(const aClassName: string; const isInterface: boolean); //Birb
var
  CurrPos: (cp_private, cp_Protected, cp_public, cp_published);
  aClassParent: string;

  procedure ProcessProc;
  var
    decl, ProcName, callingConvention, PProcname: string;
    ProcDeclInfo: TProcDeclInfo;
  begin
    ProcDeclInfo := ParseProcDecl(ProcName, decl, callingConvention, [IsMethod], aClassName);
    if (decl = '') or
      (CurrPos in [cp_private, cp_Protected]) or
      (IsDestructor in ProcDeclInfo) then
      Exit;

    if isInterface then //Birb
     fCurrentDTProc.Add('    RegisterMethod(''' + SplitIntoLines(decl) + ''', '+callingConvention+');')
    else
     fCurrentDTProc.Add('    RegisterMethod(''' + SplitIntoLines(decl) + ''');');

    if IsCallHelper in ProcDeclInfo then
      PProcName := aClassname + ProcName+'_P'
    else
      PProcName := aClassname + '.' + ProcName;

    if not isInterface then //Birb
      if IsVirtual in ProcDeclInfo then
      begin
        if IsConstructor in ProcDeclInfo then
          fCurrentRTProc.Add('    RegisterVirtualConstructor(@' +
            PProcName + ', ''' + ProcName + ''');')
        else
        begin
          if IsAbstract in ProcDeclInfo then
            fCurrentRTProc.Add('    RegisterVirtualAbstractMethod(@' + aClassname +
              ', @!.' + ProcName + ', ''' + ProcName + ''');')
          else
            fCurrentRTProc.Add('    RegisterVirtualMethod(@' + PProcName +
              ', ''' + ProcName + ''');')
        end;
      end
      else
      begin
        if IsConstructor in ProcDeclInfo then
          fCurrentRTProc.Add('    RegisterConstructor(@' + PProcName +
            ', ''' + ProcName + ''');')
        else
          fCurrentRTProc.Add('    RegisterMethod(@' + PProcName +
            ', ''' + ProcName + ''');')
      end;
  end; {ProcessProc}

  procedure ProcessVar;
  var
    VarType: string;

    procedure CreateFieldReadFunc(const VarName: string);
    begin
      with RegisterProc('procedure ' + aClassname + VarName + '_R(Self: ' + aClassname +
        '; var T: ' + VarType + ');', RunTime, [Ishelper]) do
      begin
        if IsDone in ProcAttr then RaiseError('Duplicate reader for field :' + aClassname + VarName, TokenRow, TokenCol);
        include(ProcAttr, IsDone);
        Add('Begin T := Self.' + VarName + '; end;');
      end;
    end; {CreateFieldReadFunc}

    procedure CreateFieldWriteFunc(const VarName: string);
    begin
      with RegisterProc('procedure ' + aClassname + VarName + '_W(Self: ' + aClassname +
        '; const T: ' + VarType + ');', RunTime, [Ishelper]) do
      begin
        if IsDone in ProcAttr then RaiseError('Duplicate writer for field :' + aClassname + VarName, TokenRow, TokenCol);
        include(ProcAttr, IsDone);
        Add('Begin Self.' + VarName + ' := T; end;');
      end;
    end; {CreateFieldWriteFunc}
  var
    VarNames: TStringList;
    Index: integer;
    CheckSemiColon: boolean;
  begin {ProcessVar}
    VarNames := TStringList.Create;
    try
      VarNames.Add(OrgToken);
      NextToken;
      while TokenId = CSTI_Comma do
      begin
        NextToken;
        Match(CSTI_Identifier);
        VarNames.Add(PrevorgToken);
      end;
      Match(CSTI_Colon);
      CheckSemiColon := true;
      ParseType(TokenID, '', VarType, CheckSemiColon);
      if CheckSemiColon then
        Match(CSTI_SemiColon);
      if CurrPos in [cp_public, cp_published] then
      begin
        for Index := 0 to Varnames.Count - 1 do
        begin
          CreateFieldReadFunc(Varnames[Index]);
          CreateFieldWriteFunc(Varnames[Index]);
          fCurrentDTProc.Add('    RegisterProperty(''' + varnames[Index] + ''', ''' +
            vartype + ''', iptrw);');
          if not isInterface then //Birb
            fCurrentRTProc.Add('    RegisterPropertyHelper(' +
              '@' + aClassname + varnames[Index] + '_R,' +
              '@' + aClassname + varnames[Index] + '_W,' +
              '''' + varnames[Index] + ''');');
        end;
      end;
    finally
      VarNames.Free;
    end;
  end; {ProcessVar}

  procedure ProcessProp;
  var
    ParamTypes: TStringList;
    PropertyName: string;
    read, write: Boolean;
    IsDefaultProp : Boolean; // teo

    function FindProperty: Boolean;
    var
      e, ReadString: string;
      SearchCount: integer;
    begin
      ReadString := aClassParent;
      Result := False;
      SearchCount := MaxSearchCount;
      while True do
      begin
        if SearchCount = 0 then RaiseError('While searching for property in property list, the maxium number of searchs allowed was reached', TokenRow, TokenCol);
        dec(SearchCount);
        e := Ini.ReadString(ReadString, PropertyName, '~');
        if e = '~' then
        begin
          ReadString := Ini.ReadString(ReadString, 'PARENT-CLASS', '');
      // check in the parent for the property
          if ReadString = '' then exit;
        end
        else
        begin
          if e = '' then
          begin
            PropertyName := '';
            Result := True;
            exit;
          end;
          if pos(' ', e) = 0 then exit;
          ReadString := copy(e, 1, pos(' ', e) - 1);
          Delete(e, 1, length(ReadString) + 1);
          ParamTypes.Text := Stringreplace(e, ' ', #13#10, [rfReplaceAll]);
          if ReadString = 'READ' then
            Read := True
          else if ReadString = 'WRITE' then
            Write := True
          else if ReadString = 'READWRITE' then
          begin
            Read := True;
            Write := True;
          end
          else exit;
          Result := True;
          exit;
        end;
      end;
    end; {FindProperty}

    procedure CreateReadFunc(Fake: Boolean);
    var
      decl: string;
      Index: Longint;
    begin
      decl := 'procedure ' + aClassname + PropertyName + '_R(Self: ' + aClassname +
        '; var T: ' + ParamTypes[0];
      for Index := 1 to ParamTypes.Count - 1 do
        decl := decl + '; const t' + inttostr(Index) + ': ' + ParamTypes[Index];
      decl := decl + ');';
      with RegisterProc(decl, RunTime, [Ishelper]) do
      begin
        if IsDone in ProcAttr then RaiseError('Duplicate property :' + aClassname + PropertyName + '_R', TokenRow, TokenCol);
        include(ProcAttr, IsDone);
        if Fake then Insert(1, '{');
        decl := 'begin T := Self.' + PropertyName;
        if ParamTypes.Count > 1 then
        begin
          decl := decl + '[t1';
          for Index := 2 to ParamTypes.Count - 1 do
            decl := decl + ', t' + inttostr(Index);
          decl := decl + ']';
        end;
        Add(decl + '; end;');
        if Fake then Add('}');
      end;
    end; {CreateReadFunc}

    procedure CreateWriteFunc(Fake: Boolean);
    var
      decl: string;
      Index: Longint;
    begin
      decl := 'procedure ' + aClassname + PropertyName + '_W(Self: ' + aClassname +
        '; const T: ' + ParamTypes[0];
      for Index := 1 to ParamTypes.Count - 1 do
        decl := decl + '; const t' + inttostr(Index) + ': ' + ParamTypes[Index];
      decl := decl + ');';
      with RegisterProc(decl, RunTime, [Ishelper]) do
      begin
        if IsDone in ProcAttr then RaiseError('Duplicate property :' + aClassname + PropertyName + '_W', TokenRow, TokenCol);
        include(ProcAttr, IsDone);
        if Fake then Insert(1, '{');
        decl := 'begin Self.' + PropertyName;
        if ParamTypes.Count > 1 then
        begin
          decl := decl + '[t1';
          for Index := 2 to ParamTypes.Count - 1 do
            decl := decl + ', t' + inttostr(Index);
          decl := decl + ']';
        end;
        Add(decl + ' := T; end;');
        if Fake then Add('}');
      end;
    end; {CreateWriteFunc}

  var
    Readstr, Writestr, decl: string;
    ParamCount: Longint;

  begin {ProcessProp}
    IsDefaultProp := False;
    ParamTypes := TStringList.Create;
    try
      NextToken;
      Match(CSTI_Identifier);
      PropertyName := PrevOrgToken;
      case TokenId of
        CSTI_Semicolon:
          begin // A property is being introduced that is present in the parent object
            NextToken;
            if FindProperty then
            begin
              if (PropertyName = '') or
                not (CurrPos in [cp_public, cp_published]) then Exit;
              decl := trim(StringReplace(ParamTypes.Text, NewLine, ' ', [rfreplaceAll]));
        // build the design time declaration
              decl := '    RegisterProperty(''' + PropertyName + ''', ''' + decl + ''', ipt';
              if Read then decl := decl + 'r';
              if Write then decl := decl + 'w';
              fCurrentDTProc.Add(decl + ');');
              if CurrPos <> cp_published then
              begin
          // write out the runtime version
                if Read then
                begin // create the helper function to read from the property
                  CreateReadFunc(False);
                  Readstr := '@' + aClassName + PropertyName + '_R';
                end
                else Readstr := 'nil';
                if Write then
                begin // create the helper function to write to the property
                  CreateWriteFunc(False);
                  Writestr := '@' + aClassName + PropertyName + '_W';
                end
                else Writestr := 'nil';
          // select which Property helper to use (relys on events following the syntax (ON...))
                if copy(PropertyName, 1, 2) <> 'ON' then
                  decl := '    RegisterPropertyHelper('
                else
                  decl := '    RegisterEventPropertyHelper(';
                if not isInterface then //Birb
                  fCurrentRTProc.Add(decl + Readstr + ',' + Writestr + ',''' + PropertyName + ''');')
              end;
            end
            else if PropertyName <> '' then
              Exit;
          end;
        CSTI_OpenBlock:
          begin // a pseudo array (indexed) property
            NextToken;
            while TokenID <> CSTI_CloseBlock do
            begin
              ParamCount := 0;
              repeat
                if (TokenID = CSTII_Const)
                   or (TokenID = CSTII_Var)
                   or (TokenID = CSTII_Out) //Birb
                then
                  NextToken;
                Match(CSTI_Identifier);
                inc(ParamCount);
                if TokenID = CSTI_Comma then
                  NextToken
                else Break;
              until False;
              Match(CSTI_Colon);
              Match(CSTI_Identifier);
              while ParamCount > 0 do
              begin
                ParamTypes.Add(PrevOrgToken);
                Dec(ParamCount);
              end;
              if TokenId = CSTI_Semicolon then
              begin
                NextToken;
                Continue;
              end;
            end;
            NextToken;
          end;
      end;

      //-- jgv reintroduce a property specifier
      if token = 'STORED' then begin
        If (CurrPos <> cp_published) then Exit;
        NextToken;
        Match(CSTI_Identifier);
        If TokenID = CSTI_SemiColon then begin
          Match (CSTI_SemiColon);
          Exit;
        end;
      end;

      if Token = 'DEFAULT' then
      begin
        NextToken;
        while TokenID <> CSTI_Semicolon do
          NextToken;
        NextToken;
        if FindProperty then
        begin
          if (PropertyName = '') or
            not (CurrPos in [cp_public, cp_published]) then Exit;
          decl := trim(StringReplace(ParamTypes.Text, NewLine, ' ', [rfreplaceAll]));
        // build the design time declaration
          decl := '    RegisterProperty(''' + PropertyName + ''', ''' + decl + ''', ipt';
          if Read then decl := decl + 'r';
          if Write then decl := decl + 'w';
          fCurrentDTProc.Add(decl + ');');
          if CurrPos <> cp_published then
          begin
          // write out the runtime version
            if Read then
            begin // create the helper function to read from the property
              CreateReadFunc(False);
              Readstr := '@' + aClassName + PropertyName + '_R';
            end
            else Readstr := 'nil';
            if Write then
            begin // create the helper function to write to the property
              CreateWriteFunc(False);
              Writestr := '@' + aClassName + PropertyName + '_W';
            end
            else Writestr := 'nil';
          // select which Property helper to use (relys on events following the syntax (ON...))
            if copy(PropertyName, 1, 2) <> 'ON' then
              decl := '    RegisterPropertyHelper('
            else
              decl := '    RegisterEventPropertyHelper(';
            if not isInterface then //Birb
              fCurrentRTProc.Add(decl + Readstr + ',' + Writestr + ',''' + PropertyName + ''');')
          end;
        end
        else if PropertyName <> '' then
          Exit;
      end;
      Match(CSTI_Colon);
      Match(CSTI_Identifier);
      ParamTypes.Insert(0, PrevOrgToken);
    // handle various property declarations
      read := false; write := false;

      //-- 20050707_jgv
      if Token = 'INDEX' then begin
        NextToken;
        Match (CSTI_Integer);
      end;
      //-- end jgv

      if Token = 'READ' then
      begin
        repeat
          NextToken; Match(CSTI_Identifier);
        until TokenID <> CSTI_Period;
        read := true;
      end;
      if Token = 'WRITE' then
      begin
        repeat
          NextToken; Match(CSTI_Identifier);
        until TokenID <> CSTI_Period;
        Write := true;
      end;
      if TokenID = CSTI_SemiColon then
        NextToken
      else
      begin
        if (Token = 'STORED') then
        begin
          NextToken;
          NextToken; // skip this
          if TokenId = CSTI_Semicolon then
            Match(CSTI_Semicolon);
        end;
        if (Token = 'DEFAULT') then
        begin
          NextToken;
          while TokenID <> CSTI_Semicolon do
            NextToken;
          Match(CSTI_SemiColon);
        end;
      end;
      if Token = 'DEFAULT' then
      begin
        IsDefaultProp := True;
        NextToken;
        Match(CSTI_Semicolon);
      end;
      if UseUnitAtDT and (CurrPos <> cp_public) or
        not (CurrPos in [cp_public, cp_published]) then
        exit;
      decl := trim(StringReplace(ParamTypes.Text, NewLine, ' ', [rfreplaceAll]));
    // build the design time declaration
      decl := '    RegisterProperty(''' + PropertyName + ''', ''' + decl + ''', ipt';
      if Read then decl := decl + 'r';
      if Write then decl := decl + 'w';
      fCurrentDTProc.Add(decl + ');');
    // write out the runtime version
      if Read then
      begin // create the helper function to read from the property
        CreateReadFunc(False);
        Readstr := '@' + aClassName + PropertyName + '_R';
      end
      else Readstr := 'nil';
      if Write then
      begin // create the helper function to write to the property
        CreateWriteFunc(False);
        Writestr := '@' + aClassName + PropertyName + '_W';
      end
      else Writestr := 'nil';
    // select which Property helper to use (relys on events following the syntax (ON...))
      if copy(PropertyName, 1, 2) <> 'ON' then
        decl := '    RegisterPropertyHelper('
      else
        decl := '    RegisterEventPropertyHelper(';
      if not isInterface then //Birb
        fCurrentRTProc.Add(decl + Readstr + ',' + Writestr + ',''' + PropertyName + ''');');

      if IsDefaultProp then   //teo
        fCurrentDTProc.Add('    SetDefaultPropery(''' + PropertyName + ''');');

    finally
      ParamTypes.Free;
    end;
  end; {ProcessProp}

var
  OldDTProc, OldRTProc: TProcList;
begin {ParseClassDef}
  if isInterface //Birb
   then Match(CSTII_interface) //Birb
   else Match(CSTII_class);
//CreateRegClasProc;
// check for forward declaration
  if TokenID = CSTI_Semicolon then
  begin
//  NextToken;  the semicolon is removed by the caller
    if UseUnitAtDT then
      if isInterface //Birb
        then fCurrentDTProc.Add('  CL.AddInterface(CL.FindInterface('''+STR_IINTERFACE+'''),' + aClassname + ', '''+aClassname+''');') //this is a forward declaration that will be overriden later on
        else fCurrentDTProc.Add('  CL.AddClass(CL.FindClass(''TOBJECT''),' + aClassname + ');')
    else
      if isInterface //Birb
        then fCurrentDTProc.Add('  CL.AddInterface(CL.FindInterface('''+STR_IINTERFACE+'''),' + aClassname + ', '''+aClassname+''');') //this is a forward declaration that will be overriden later on
        else fCurrentDTProc.Add('  CL.AddClassN(CL.FindClass(''TOBJECT''),''' + aClassname + ''');');
    if isInterface then //Birb
      Include(RuntimeProcType, InterfaceImporter) //Birb
    else //Birb
      begin //Birb
      if fCurrentRTProc = nil then
      begin
        Include(RunTimeProcType, ClassImporter);
        fCurrentRTProc := RegisterProc('procedure RIRegister_' + UnitName +
          '(CL: TPSRuntimeClassImporter);', RunTime, [PublicProc]);
      end;
      fCurrentRTProc.Add('  with CL.Add(' + aClassname + ') do');
      end; //Birb
    exit;
  end

  else if IfMatch(CSTII_of) then
  begin
    Match(CSTI_Identifier);
    //teo --compiler complains when it comes to register a TClass type
    fCurrentDTProc.Add('  //CL.AddTypeS(''' + aClassname + ''', ''class of ' + PrevOrgToken + ''');');
    exit;
  end

  else if IfMatch(CSTI_OpenRound) then
  begin
    Match(CSTI_Identifier);
    aClassParent := PrevOrgToken;

    if not isInterface then
     while IfMatch(CSTI_Comma) do
      Match(CSTI_Identifier); //Birb (ignore possible list of implemented interfaces after class ancestor)

    Match(CSTI_CloseRound);

    ///////////////////

    if TokenId = CSTI_Semicolon then //??? //Birb: I think this is an impossible case!
    begin
      if UseUnitAtDT then
        if isInterface //Birb
          then fCurrentDTProc.Add('  CL.AddInterface(CL.FindInterface(''IUNKNOWN''),' + aClassname + ', '''+aClassname+''');')
          else fCurrentDTProc.Add('  CL.AddClass(CL.FindClass(''TOBJECT''),' + aClassname + ');')
      else
        if isInterface //Birb
          then fCurrentDTProc.Add('  CL.AddInterface(CL.FindInterface(''IUNKNOWN''),' + aClassname + ', '''+aClassname+''');')
          else fCurrentDTProc.Add('  CL.AddClassN(CL.FindClass(''TOBJECT''),''' + aClassname + ''');');
      if isInterface then //Birb
        Include(RuntimeProcType, InterfaceImporter) //Birb
      else //Birb
        begin //Birb
          if fCurrentRTProc = nil then
          begin
            Include(RunTimeProcType, ClassImporter);
            fCurrentRTProc := RegisterProc('procedure RIRegister_' + UnitName +
              '(CL: TPSRuntimeClassImporter);', RunTime, [PublicProc]);
          end;
          fCurrentRTProc.Add('  with CL.Add(' + aClassname + ') do');
        end; //Birb
      exit;
    end;

   ///////////////////

  end

  else
    if isInterface //Birb
     then aClassParent := STR_IINTERFACE //Birb (Delphi interfaces descent from IInterface if no ancestor is specified)
     else aClassParent := 'TOBJECT';

  if isInterface then //Birb
    begin //Birb
    Include(RuntimeProcType, InterfaceImporter); //Birb
    OldRTProc := fCurrentRTProc; //Birb (using to avoid compiler warning later on - maybe can just use "nil" here)
    end //Birb
  else //Birb
    begin //Birb
    if fCurrentRTProc = nil then
    begin
      Include(RunTimeProcType, ClassImporter);
      fCurrentRTProc := RegisterProc('procedure RIRegister_' + UnitName +
        '(CL: TPSRuntimeClassImporter);', RunTime, [PublicProc]);
    end;
    OldRTProc := fCurrentRTProc;
    fCurrentRTProc := RegisterProc('procedure RIRegister_' + aClassname +
      '(CL: TPSRuntimeClassImporter);', RunTime, [PublicProc]);
    fCurrentRTProc.Add('  with CL.Add(' + aClassname + ') do');
    fCurrentRTProc.Add('  begin');
    end; //Birb

  OldDTProc := fCurrentDTProc;
  fCurrentDTProc := RegisterProc('procedure SIRegister_' + aClassname +
    '(CL: TPSPascalCompiler);', CompileTime, [PublicProc]);
  if UseUnitAtDT then
  begin
    AddRequiredUnit(UnitName, CompileTime, false);

    if isInterface //Birb
      then fCurrentDTProc.Add('  with CL.AddInterface(CL.FindInterface(''' + aClassParent + '''),' + aClassname + ', '''+aClassname+''') do')
      else fCurrentDTProc.Add('  with CL.AddClass(CL.FindClass(''' + aClassParent + '''),' + aClassname + ') do');
    fCurrentDTProc.Add('  begin');

    if not isInterface then //Birb (note that Delphi does support interface properties, but on only for Delphi objects, not external objects [!!!should fix uPSCompiler to support that too - with some RegisterProperties method, since there's no published section at interface declarations])
     fCurrentDTProc.Add('    RegisterPublishedProperties;');
  end
  else
  begin
    if isInterface then //Birb
     begin
     fCurrentDTProc.Add('  //with RegInterfaceS(CL,''' + aClassParent + ''', ''' + aClassname + ''') do'); //Birb
     fCurrentDTProc.Add('  with CL.AddInterface(CL.FindInterface(''' + aClassParent + '''),' + aClassname + ', '''+aClassname+''') do')
     end
    else
     begin
     fCurrentDTProc.Add('  //with RegClassS(CL,''' + aClassParent + ''', ''' + aClassname + ''') do');  // teo
     fCurrentDTProc.Add('  with CL.AddClassN(CL.FindClass(''' + aClassParent + '''),''' + aClassname + ''') do');
     end;
    fCurrentDTProc.Add('  begin');
  end;
  CurrPos := cp_public;

  if isInterface then //Birb
    if not IfMatch(CSTI_OpenBlock) then //Birb: GUID string needed at interface declarations cause "CL.AddInterface" has a TGUID parameter above (!!!should have a PGUID so that we could maybe pass nil to it - else maybe should see if '' is accepted for a TGUID and peek ahead to see if a GUID is available, else use '')
      RaiseError('Found ''' + GetTokenName(TokenID) + ''' instead of [''GUID-string'']', TokenRow, TokenCol)
    else
      begin //Birb: ignore ['GUID-string']
      Match(CSTI_String);
      Match(CSTI_CloseBlock);
      end;

  while not IfMatch(CSTII_End) do
    case TokenID of
      CSTII_Private:
        begin
          CurrPos := cp_private;
          NextToken;
        end;
      CSTII_Protected:
        begin
          CurrPos := cp_Protected;
          NextToken;
        end;
      CSTII_Public:
        begin
          CurrPos := cp_public;
          NextToken;
        end;
      CSTII_Published:
        begin
          CurrPos := cp_published;
          NextToken;
        end;
      CSTII_Procedure, CSTII_Function, CSTII_Constructor, CSTII_Destructor:
        ProcessProc;
      CSTI_Identifier:
        ProcessVar;
      CSTII_Property:
        if isInterface then //Birb
          begin
          skipToSemicolon; //Birb (note that Delphi does support interface properties, but on only for Delphi objects, not external objects [!!!should fix uPSCompiler to support that too])
          if Token='DEFAULT' then //Birb: ignore optional "default;" specifier that may follow indexed/array properties
           begin
           NextToken;
           Match(CSTI_SemiColon);
           end
          end
        else
          ProcessProp; //Birb: (!!!) do check if this works ok with "default;" specifier for indexed/array property declarations (since that one is after the property declaration's ending ";")

      CSTII_Class:
        begin
          // jgv: class procedure/function  
          NextToken;
          If Not (TokenID in [CSTII_Procedure, CSTII_Function]) then
            RaiseError ('class must be followed by "function" or "procedure"', TokenRow, TokenCol);
        end;

    else RaiseError('Unknown keyword ''' + GetTokenName(TokenID) + '''', TokenRow, TokenCol);

    end;
  if not isInterface then //Birb
    fCurrentRTProc.Add('  end;');
  fCurrentDTProc.Add('  end;');
  if OldDTProc <> nil then
    fCurrentDTProc := OldDTProc;
  fCurrentDTProc.Add('  SIRegister_' + aClassname + '(CL);');
  if not isInterface then //Birb
    begin
    if OldRTProc <> nil then
      fCurrentRTProc := OldRTProc;
    fCurrentRTProc.Add('  RIRegister_' + aClassname + '(CL);');
    end;
end; {ParseClassOrInterfaceDef} //Birb

procedure TUnitParser.ParseInterfaceDef(const aInterfaceName: string);
begin
{  Writeln('Interface Declaration not suported at position: ' + Inttostr(TokenRow) + ':' + Inttostr(TokenCol));
  while not (TokenId in [CSTI_EOF, CSTII_End]) do
    NextToken;
  NextToken; // skip the END
//todo 4 -cRequired : Allow parsing of interfaces
}
 ParseClassOrInterfaceDef(aInterfaceName,true); //Birb
end; {ParseInterfaceDef}

procedure TUnitParser.ParseClassDef(const aClassName: string); //Birb
begin
 ParseClassOrInterfaceDef(aClassName,false); //Birb
end; {ParseClassDef} //Birb

procedure TUnitParser.ParseType(aTokenID: TPSPasToken;
  const TypeName: string;
  var TypeDescriptor: string;
  var CheckSemiColon: boolean);
var
  S: string;
  b: boolean;
begin
  CheckSemiColon := True;
  case aTokenID of
    CSTI_Integer: // range
      begin
        TypeDescriptor := TypeDescriptor + 'Integer';
        while not (TokenId in [CSTI_EOF, CSTI_Semicolon]) do
        begin
          NextToken;
        end;
        Match(CSTI_Semicolon);
        CheckSemicolon := False;
      end;
    CSTI_Identifier: // simple type by name  (MyInt = Integer)
      begin
        Match(CSTI_Identifier);
        TypeDescriptor := TypeDescriptor + PrevOrgToken;
      end;
    CSTI_Dereference: // ie 'PInteger = ^Integer'
      begin { todo 3-cWishList : When pointers are supported by ROPPS, supported them or provide emulation }
        Match(CSTI_Dereference);
        TypeDescriptor := TypeDescriptor + ' ^';
        ParseType(CSTI_Identifier, TypeName, TypeDescriptor, CheckSemiColon);
        Writeln('Pointers are not supported, this declaration will fail. At position :' + inttostr(TokenRow) + ':' + inttostr(TokenCol));
        TypeDescriptor := TypeDescriptor + ' // will not work';
      end;
    CSTII_type: // type identity (MyInt = type Integer)
      begin
        Match(CSTII_type);
//    TypeDescriptor := TypeDescriptor + 'type';
        ParseType(CSTI_Identifier, TypeName, TypeDescriptor, CheckSemiColon);
      end;
    CSTII_procedure,
      CSTII_function: // parse a routine/method pointer
      begin
        ParseProcDecl(S, TypeDescriptor, S, [IsPointer]);
        CheckSemiColon := false;
      end;
    CSTI_OpenRound: // enums  (somename,somename2,..)
      begin
        Match(CSTI_OpenRound);
        TypeDescriptor := TypeDescriptor + '( ';
        b := false;
        repeat
          Match(CSTI_Identifier);
          if b then
            TypeDescriptor := TypeDescriptor + ', ' + PrevOrgToken
          else
          begin
            b := true;
            TypeDescriptor := TypeDescriptor + PrevOrgToken;
          end;
          if TokenID = CSTI_CloseRound then
          begin
            NextToken;
            TypeDescriptor := TypeDescriptor + ' ) ';
            break;
          end
          else
            Match(CSTI_Comma);
        until false;
      end;
    CSTII_record: // records (rec = record a : integer; end;)
      begin
        Match(CSTII_record);
        TypeDescriptor := TypeDescriptor + 'record ';
        b := false;
        while TokenID = CSTI_Identifier do
        begin
          TypeDescriptor := TypeDescriptor + OrgToken + ' : ';
          NextToken;
          Match(CSTI_Colon);
          ParseType(TokenId, TypeName, TypeDescriptor, CheckSemiColon);
          if TypeDescriptor = '' then
            b := true; // invalidat this type
          Match(CSTI_SemiColon);
          TypeDescriptor := TypeDescriptor + '; ';
        end;
        TypeDescriptor := TypeDescriptor + 'end ';
        if b then TypeDescriptor := '';
        Match(CSTII_end);
      end;
    CSTII_set: // sets    (set of (...))
      begin // parse a set declaration
        Match(CSTII_set);
        Match(CSTII_of);
        TypeDescriptor := TypeDescriptor + 'set of ';
        ParseType(TokenID, TypeName, TypeDescriptor, CheckSemiColon);

   { todo 1 -cWishList : When Sets are supported by ROPS, supported them }
//    RaiseError('Sets are not supported',TokenPos);
      end;
    CSTII_array: // arrays  (array [<const expression>..<const expression>] of ...)
      begin
        Match(CSTII_array);
        b := false;
        TypeDescriptor := TypeDescriptor + 'array ';
        if Ifmatch(CSTI_OpenBlock) then
        begin
          TypeDescriptor := TypeDescriptor + '[ ' + ParseConstantExpression(S);
          if IfMatch(CSTI_TwoDots) then
          begin
//            Match(CSTI_Period, '..');
            TypeDescriptor := TypeDescriptor + ' .. ' + ParseConstantExpression(S);
          end;
          TypeDescriptor := TypeDescriptor + '] ';
          Match(CSTI_CloseBlock);
      { TODO 1 -cWishList : When static arrays are supported by ROPS, supported them }
          b := true;
        end;
        Match(CSTII_of);
        TypeDescriptor := TypeDescriptor + 'of ';
        //-- jgv parse array of const
        If TokenID = CSTII_const then begin
          TypeDescriptor := TypeDescriptor + 'const';
          NextToken;
        end
        else
        //-- end jgv
          Parsetype(TokenID, TypeName, TypeDescriptor, CheckSemiColon);

        if b then TypeDescriptor := '';
      end;
    CSTII_Interface: // interfaces (  objectname = Interface ... end)
      begin
        TypeDescriptor := ''; // suppresses the default register action
//    Writeln('Interfaces are not supported. At position :'+inttostr(TokenPos));
        ParseInterfaceDef(TypeName);
      end;
    CSTII_class: // classes (  objectname = class ... end)
      begin
        TypeDescriptor := ''; // suppresses the default register action
        ParseClassDef(TypeName);
      end;
  else RaiseError('Expecting valid type, but found ''' + GetTokenName(TokenID) + '''', TokenRow, TokenCol);
  end;
end; {ParseType}
(*----------------------------------------------------------------------------*)
procedure TUnitParser.ParseTypes;
var
  TypeName            : string;
  TypeDescriptor, tmp : string;
  CheckSemiColon      : boolean;
  Len, Index          : integer;
begin {ParseTypes}
  Match(CSTII_type);
  repeat
    // get the type name
    Match(CSTI_Identifier);
    TypeName := PrevOrgToken;
    Match(CSTI_equal);
    
    // build the type discriptor
    TypeDescriptor := '';
    ParseType(TokenID, TypeName, TypeDescriptor, CheckSemiColon);
    if CheckSemiColon then
      Match(CSTI_SemiColon);
    if (TypeDescriptor <> '') then
    begin
      TypeDescriptor := trim(TypeDescriptor);
      // break up the TypeDescriptor to make it fit with in 80 characters per line
      tmp := '  CL.AddTypeS(''' + TypeName + ''', ''';
      Len := Length(tmp) + length(TypeDescriptor) + 3;
      if Len <= 80 then
        fCurrentDTProc.Add(tmp + TypeDescriptor + ''');')
      else
      begin
        Len := 79 - Length(tmp);
        fCurrentDTProc.Add(tmp);
        if Len > 0 then
        begin
          tmp := copy(TypeDescriptor, 1, Len);
          Delete(TypeDescriptor, 1, Len);
          Index := fCurrentDTProc.count - 1;
          fCurrentDTProc[Index] := fCurrentDTProc[Index] + tmp + '''';
        end
        else
        begin
          fCurrentDTProc.Add('   +''' + copy(TypeDescriptor, 1, 74) + '''');
          Delete(TypeDescriptor, 1, 74);
        end;
        while TypeDescriptor <> '' do
        begin
          fCurrentDTProc.Add('   +''' + copy(TypeDescriptor, 1, 74) + '''');
          Delete(TypeDescriptor, 1, 74);
        end;
        Index := fCurrentDTProc.count - 1;
        fCurrentDTProc[Index] := fCurrentDTProc[Index] + ');';
      end;
    end;
  until (TokenID <> CSTI_Identifier);
end; {ParseTypes}



procedure TUnitParser.ParserError(Parser: TObject;
  Kind: TPSParserErrorKind);
var
  S: string;
begin
  Writeln('Error parsing file');
  case Kind of
    iCommentError: S := 'Comment';
    iStringError: S := 'String';
    iCharError: S := 'Char';
    iSyntaxError: S := 'Syntax';
  end;
  Writeln(S + ' Error, Position :' + Inttostr(TPSPascalParser(Parser).Row) + ':' + IntToStr(TPSPascalParser(Parser).Col));
end;

end.
