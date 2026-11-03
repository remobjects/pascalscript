
unit uPSPreProcessor;
{$I PascalScript.inc}

interface
uses
  Classes, SysUtils, uPSCompiler, uPSUtils;



type
  EPSPreProcessor = class(Exception); //- jgv
  TPSPreProcessor = class;
  TPSPascalPreProcessorParser = class;

  TPSOnNeedFile = function (Sender: TPSPreProcessor; const callingfilename: tbtstring; var FileName, Output: tbtstring): Boolean;
  TPSOnProcessDirective = procedure (
                            Sender: TPSPreProcessor;
                            Parser: TPSPascalPreProcessorParser;
                            const Active: Boolean;
                            const DirectiveName, DirectiveParam: tbtString;
                            Var Continue: Boolean); //- jgv - application set continue to false to stop the normal directive processing
  
  TPSLineInfo = class(TObject)
  private
    function GetLineOffset(I: Integer): Cardinal;
    function GetLineOffsetCount: Longint;
    { Pos, a place in the preprocessed text from the item's start, as an
      offset into the item's own file: the includes before it left out }
    function SourceOffset(Pos: Cardinal): Cardinal;
  protected
    FEndPos: Cardinal;
    FStartPos: Cardinal;
    FFileName: tbtstring;
    FModuleName: tbtstring;
    { a module's own text, not an include: it holds its end position too }
    FModuleText: Boolean;
    FLineOffsets: TIfList;
    { at each include the text holds: where the include's text ends, and the
      bytes the includes have added to the text by then }
    FIncludeEnds, FIncludeAdded: TIfList;
  public
    
    property FileName: tbtstring read FFileName;
    { the module the text is compiled as, in upper case: '' for the main
      script, the unit's name for a unit's text and its includes }
    property ModuleName: tbtstring read FModuleName;
    
    property StartPos: Cardinal read FStartPos;
    
    property EndPos: Cardinal read FEndPos;
    
    property LineOffsetCount: Longint read GetLineOffsetCount;
    
    property LineOffset[I: Longint]: Cardinal read GetLineOffset;

    
    constructor Create;
    
    destructor Destroy; override;
  end;
  
  TPSLineInfoResults = record
    
    Row,
    Col,
    Pos: Cardinal;
    
    Name: tbtstring;
  end;
  
  TPSLineInfoList = class(TObject)
  private
    FItems: TIfList;
    FCurrent: Longint;
    function GetCount: Longint;
    function GetItem(I: Integer): TPSLineInfo;
  protected

    function Add: TPSLineInfo;
  public
    
    property Count: Longint read GetCount;
    
    property Items[I: Longint]: TPSLineInfo read GetItem; default;

    procedure Clear;
    
    function GetLineInfo(const ModuleName: tbtstring; Pos: Cardinal; var Res: TPSLineInfoResults): Boolean;
    
    property Current: Longint read FCurrent write FCurrent;

    
    constructor Create;
    
    destructor Destroy; override;
  end;
  TPSDefineStates = class;
  
  TPSPreProcessor = class(TObject)
  private
    FID: Pointer;
    FCurrentDefines, FDefines: TStringList;
    FCurrentLineInfo: TPSLineInfoList;
    FOnNeedFile: TPSOnNeedFile;
    FAddedPosition: Cardinal;
    FDefineState: TPSDefineStates;
    FMaxLevel: Longint;
    FMainFileName: tbtstring;
    FMainFile: tbtstring;
    FOnProcessDirective: TPSOnProcessDirective;
    FOnProcessUnknowDirective: TPSOnProcessDirective;
    procedure ParserNewLine(Sender: TPSPascalPreProcessorParser; Row, Col, Pos: Cardinal);
    procedure SetDefines(const Value: TStringList);
    procedure IntPreProcess(Level: Integer; const OrgFileName: tbtstring; FileName: tbtstring;
      const ModuleName: tbtstring; Dest: TStream);
  protected
    procedure doAddStdPredefines; virtual; // jgv
  public
    {The maximum number of levels deep the parser will go, defaults to 20}
    property MaxLevel: Longint read FMaxLevel write FMaxLevel;
    property CurrentLineInfo: TPSLineInfoList read FCurrentLineInfo;

    property OnNeedFile: TPSOnNeedFile read FOnNeedFile write FOnNeedFile;

    property Defines: TStringList read FDefines write SetDefines;

    property MainFile: tbtstring read FMainFile write FMainFile;

    property MainFileName: tbtstring read FMainFileName write FMainFileName;

    property ID: Pointer read FID write FID;

    procedure AdjustMessages(Comp: TPSPascalCompiler);
    procedure AdjustMessage(Msg: TPSPascalCompilerMessage); //-jgv

    { ModuleName is the module the text is compiled as: '' for the main
      script, a unit's name for a unit's text }
    procedure PreProcess(const Filename: tbtstring; var Output: tbtstring; const ModuleName: tbtstring = '');

    procedure Clear;


    constructor Create;

    destructor Destroy; override;

    property OnProcessDirective: TPSOnProcessDirective read fOnProcessDirective write fOnProcessDirective;
    property OnProcessUnknowDirective: TPSOnProcessDirective read fOnProcessUnknowDirective write fOnProcessUnknowDirective;
  end;

  TPSPascalPreProcessorType = (ptEOF, ptOther, ptDefine);
  
  TPSOnNewLine = procedure (Sender: TPSPascalPreProcessorParser; Row, Col, Pos: Cardinal) of object;
  
  TPSPascalPreProcessorParser = class(TObject)
  private
    FData: tbtstring;
    FText: PAnsichar;
    FToken: tbtstring;
    FTokenId: TPSPascalPreProcessorType;
    FLastEnterPos, FLen, FRow, FTokenRow, FCol, FPos: Cardinal;
    FOnNewLine: TPSOnNewLine;
    { the text ends inside the current token: a string, a comment or a
      directive that has no end of its own }
    FEndsInside: Boolean;
  public
    
    procedure SetText(const dta: tbtstring);
    
    procedure Next;
    
    property Token: tbtstring read FToken;
    
    property TokenId: TPSPascalPreProcessorType read FTokenId;
    
    { where the current token starts }
    property Row: Cardinal read FTokenRow;
    
    property Col: Cardinal read FCol;
    
    property Pos: Cardinal read FPos;
    
    property OnNewLine: TPSOnNewLine read FOnNewLine write FOnNewLine;
  end;
  
  TPSDefineState = class(TObject)
  private
    FInElse: Boolean;
    FDoWrite: Boolean;
  public
    
    property InElse: Boolean read FInElse write FInElse;
    
    property DoWrite: Boolean read FDoWrite write FDoWrite;
  end;

  TPSDefineStates = class(TObject)
  private
    FItems: TIfList;
    function GetCount: Longint;
    function GetItem(I: Integer): TPSDefineState;
    function GetWrite: Boolean;
    function GetPrevWrite: Boolean; //JeromeWelsh - nesting fix
  public

    property Count: Longint read GetCount;

    property Item[I: Longint]: TPSDefineState read GetItem; default;
    
    function Add: TPSDefineState;
    
    procedure Delete(I: Longint);

    
    constructor Create;
    
    destructor Destroy; override;

    procedure Clear;
    
    property DoWrite: Boolean read GetWrite;
    property DoPrevWrite: Boolean read GetPrevWrite; //JeromeWelsh - nesting fix
  end;

implementation

{$IFDEF DELPHI3UP }
resourceString
{$ELSE }
const
{$ENDIF }

  RPS_TooManyNestedInclude = 'Too many nested include files while processing ''%s'' from ''%s''';
  RPS_IncludeNotFound = 'Unable to find file ''%s'' used from ''%s''';
  RPS_DefineTooManyParameters = 'Too many parameters in ''%s'' at %d:%d';
  RPS_NoIfdefForEndif = 'No IFDEF for ENDIF in ''%s'' at %d:%d';
  RPS_NoIfdefForElse = 'No IFDEF for ELSE in ''%s'' at %d:%d';
  RPS_ElseTwice = 'Can''t use ELSE twice in ''%s'' at %d:%d';
  RPS_UnknownCompilerDirective = 'Unknown compiler directives in ''%s'' at %d:%d';
  RPs_DefineNotClosed = 'Define not closed';
  RPS_MissingParameter = 'Missing parameter in ''%s'' at %d:%d';
  RPS_EndInsideAToken = 'Unexpected end of file inside a comment, string or directive in ''%s'' at %d:%d';

{ TPSLineInfoList }

function TPSLineInfoList.Add: TPSLineInfo;
begin
  Result := TPSLineInfo.Create;
  FItems.Add(Result);
end;

procedure TPSLineInfoList.Clear;
var
  i: Longint;
begin
  for i := FItems.count -1 downto 0 do
    TPSLineInfo(FItems[i]).Free;
  FItems.Clear;
end;

constructor TPSLineInfoList.Create;
begin
  inherited Create;
  FItems := TIfList.Create;
end;

destructor TPSLineInfoList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

function TPSLineInfoList.GetCount: Longint;
begin
  Result := FItems.Count;
end;

function TPSLineInfoList.GetItem(I: Integer): TPSLineInfo;
begin
  Result := TPSLineInfo(FItems[i]);
end;

function TPSLineInfoList.GetLineInfo(const ModuleName: tbtstring; Pos: Cardinal; var Res: TPSLineInfoResults): Boolean;
var
  i,j: Longint;
  linepos: Cardinal;
  Item: TPSLineInfo;
  lModuleName: tbtstring;
begin
  lModuleName := FastUpperCase(ModuleName);

  for i := FItems.Count -1 downto 0 do
  begin
    Item := FItems[i];
    { every preprocessed text's positions start at 0: a position is a place
      in a text of its own module; a module's own text also holds its end,
      where the compiler reports an unexpected end of file }
    if (Pos >= Item.StartPos) and
      ((Pos < Item.EndPos) or ((Pos = Item.EndPos) and Item.FModuleText)) and
      (lModuleName = Item.ModuleName) then
    begin
      Res.Name := Item.FileName;
      Pos := Pos - Item.StartPos;
      { offsets into the item's own file: its includes' text left out }
      Res.Pos := Item.SourceOffset(Pos);
      Res.Col := 1;
      Res.Row := 1;
      for j := 0 to Item.LineOffsetCount -1 do
      begin
        if Pos >= Item.LineOffset[j] then
        begin
          linepos := Item.LineOffset[j];
        end else
        begin
          Break;
        end;
        Res.Row := j + 1; // line counting starts at 1
        Res.Col := Res.Pos - Item.SourceOffset(linepos) + 1;
      end;
      Result := True;
      exit;
    end;
  end;
  Result := False;
end;

{ TPSLineInfo }

constructor TPSLineInfo.Create;
begin
  inherited Create;
  FLineOffsets := TIfList.Create;
  FIncludeEnds := TIfList.Create;
  FIncludeAdded := TIfList.Create;
end;

destructor TPSLineInfo.Destroy;
begin
  FIncludeAdded.Free;
  FIncludeEnds.Free;
  FLineOffsets.Free;
  inherited Destroy;
end;


function TPSLineInfo.GetLineOffset(I: Integer): Cardinal;
begin
  Result := Longint(FLineOffsets[I]);
end;

function TPSLineInfo.GetLineOffsetCount: Longint;
begin
  result := FLineOffsets.Count;
end;

function TPSLineInfo.SourceOffset(Pos: Cardinal): Cardinal;
var
  i: Longint;
  lEnd: Cardinal;
begin
  Result := Pos;
  for i := FIncludeEnds.Count -1 downto 0 do
  begin
    lEnd := Longint(FIncludeEnds[i]);
    if Pos >= lEnd then
    begin
      Result := Pos - Cardinal(Longint(FIncludeAdded[i]));
      Exit;
    end;
  end;
end;

{ TPSPascalPreProcessorParser }

procedure TPSPascalPreProcessorParser.Next;
var
  ci: Cardinal;

begin
  FPos := FPos + FLen;
  FEndsInside := False;
  { a token's place is where it starts: its scan below counts the line
    breaks inside it.  FLastEnterPos is the current row's first position }
  FTokenRow := FRow;
  FCol := FPos - FLastEnterPos + 1;
  case FText[FPos] of
    #0:
      begin
        FLen := 0;
        FTokenId := ptEof;
      end;
    '''':
      begin
        ci := FPos;
        while (FText[ci] <> #0) do
        begin
          Inc(ci);
          while FText[ci] = '''' do
          begin
            if FText[ci+1] <> '''' then Break;
            inc(ci);
            inc(ci);
          end;
          if FText[ci] = '''' then Break;
          if FText[ci] = #13 then
          begin
            inc(FRow);
            if FText[ci+1] = #10 then
              inc(ci);
            FLastEnterPos := ci +1;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
            break;
          end else if FText[ci] = #10 then
          begin
            inc(FRow);
            FLastEnterPos := ci +1;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
            break;
          end;
        end;
        { a string the text ends inside ends with the text }
        FEndsInside := FText[ci] = #0;
        if FText[ci] = #0 then
          FLen := ci - FPos
        else
          FLen := ci - FPos + 1;
        FTokenId := ptOther;
      end;
    '(':
      begin
        if FText[FPos + 1] = '*' then
        begin
          { past the opener: its '*' does not close it as '(*)' }
          ci := FPos + 2;
          while (FText[ci] <> #0) do begin
            if (FText[ci] = '*') and (FText[ci + 1] = ')') then
              Break;
            if FText[ci] = #13 then
            begin
              inc(FRow);
              if FText[ci+1] = #10 then
                inc(ci);
              FLastEnterPos := ci +1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
            end else if FText[ci] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := ci +1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
            end;
            Inc(ci);
          end;
          { (*$ opens a directive, as in Delphi }
          if FText[FPos + 2] = '$' then
            FTokenId := ptDefine
          else
            FTokenId := ptOther;
          FEndsInside := FText[ci] = #0;
          if (FText[ci] <> #0) then
            Inc(ci, 2);
          FLen := ci - FPos;
        end
        else
        begin
          FTokenId := ptOther;
          FLen := 1;
        end;
      end;
      '/':
        begin
          if FText[FPos + 1] = '/' then
          begin
            ci := FPos + 1;
            while (FText[ci] <> #0) and (FText[ci] <> #13) and
              (FText[ci] <> #10) do begin
              Inc(ci);
            end;
            FEndsInside := FText[ci] = #0;
            FTokenId := ptOther;
            FLen := ci - FPos;
          end else
          begin
            FTokenId := ptOther;
            FLen := 1;
          end;
        end;
      '{':
        begin
          ci := FPos + 1;
          while (FText[ci] <> #0) and (FText[ci] <> '}') do begin
            if FText[ci] = #13 then
            begin
              inc(FRow);
              if FText[ci+1] = #10 then
                inc(ci);
              FLastEnterPos := ci + 1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
            end else if FText[ci] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := ci + 1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
            end;
            Inc(ci);
          end;
          if FText[FPos + 1] = '$' then
            FTokenId := ptDefine
          else
            FTokenId := ptOther;

          { a comment the text ends inside ends with the text }
          FEndsInside := FText[ci] = #0;
          if FText[ci] = #0 then
            FLen := ci - FPos
          else
            FLen := ci - FPos + 1;
        end;
      else
      begin
        { from its first character: a token that starts with a line break
          follows a // comment }
        ci := FPos;
        while not (FText[ci] in [#0,'{', '(', '''', '/']) do
        begin
          if FText[ci] = #13 then
          begin
            inc(FRow);
            if FText[ci+1] = #10 then
              inc(ci);
            FLastEnterPos := ci + 1;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
          end else if FText[ci] = #10 then
          begin
            inc(FRow);
            FLastEnterPos := ci + 1;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, 1, ci+1);
          end;
          Inc(Ci);
        end;
        FTokenId := ptOther;
        FLen := ci - FPos;
      end;
  end;
  FToken := Copy(FData, FPos +1, FLen);
end;

procedure TPSPascalPreProcessorParser.SetText(const dta: tbtstring);
begin
  FData := dta;
  FText := pAnsichar(FData);
  FLen := 0;
  FPos := 0;
  FCol := 1;
  FLastEnterPos := 0;
  FRow := 1;
  if @FOnNewLine <> nil then FOnNewLine(Self, 1, 1, 0);
  Next;
end;

{ TPSPreProcessor }

procedure TPSPreProcessor.AdjustMessage(Msg: TPSPascalCompilerMessage);
var
  Res: TPSLineInfoResults;
begin
  { a placed message holds a place in its file, which the line information
    of a text -- its own or another's -- would read as a place in the
    preprocessed text }
  if Msg.Placed then
    exit;
  if CurrentLineInfo.GetLineInfo(Msg.ModuleName, Msg.Pos, Res) then
  begin
    Msg.SetCustomPos(res.Pos, Res.Row, Res.Col);
    Msg.ModuleName := Res.Name;
    Msg.Placed := True;
  end;
end;

procedure TPSPreProcessor.AdjustMessages(Comp: TPSPascalCompiler);
var
  i: Longint;
begin
  for i := 0 to Comp.MsgCount -1 do
    AdjustMessage (Comp.Msg[i]);
end;

procedure TPSPreProcessor.Clear;
begin
  FDefineState.Clear;
  FDefines.Clear;
  FCurrentDefines.Clear;
  FCurrentLineInfo.Clear;
  FMainFile := '';
end;

constructor TPSPreProcessor.Create;
begin
  inherited Create;
  FDefines := TStringList.Create;
  FCurrentLineInfo := TPSLineInfoList.Create;
  FCurrentDefines := TStringList.Create;
  FDefines.Duplicates := dupIgnore;
  FCurrentDefines.Duplicates := dupIgnore;
  FDefineState := TPSDefineStates.Create;
  FMaxLevel := 20;

  doAddStdPredefines;
end;

destructor TPSPreProcessor.Destroy;
begin
  FDefineState.Free;
  FCurrentDefines.Free;
  FDefines.Free;
  FCurrentLineInfo.Free;
  inherited Destroy;
end;

procedure TPSPreProcessor.SetDefines(const Value: TStringList);
begin
  if Value <> FDefines then
    FDefines.Assign(Value);
end;

procedure TPSPreProcessor.doAddStdPredefines;
begin
  //--- 20050708_jgv
  FCurrentDefines.Add (Format ('VER%d', [PSCurrentBuildNo]));
  {$IFDEF CPU386 }
  FCurrentDefines.Add ('CPU386');
  {$ENDIF }
  {$IFDEF MSWINDOWS }
    FCurrentDefines.Add ('MSWINDOWS');
    FCurrentDefines.Add ('WIN32');
  {$ENDIF }
  {$IFDEF LINUX }
    FCurrentDefines.Add ('LINUX');
  {$ENDIF }
end;

{ the place of the first blank in aText -- a space, a tab, a line break or
  any other character up to a space -- or 0 }
function _BlankPos(const aText: tbtstring): Longint;
var
  lIdx: Longint;
begin
  for lIdx := 1 to Length(aText) do
    if aText[lIdx] <= ' ' then
    begin
      Result := lIdx;
      Exit;
    end;
  Result := 0;
end;

procedure TPSPreProcessor.IntPreProcess(Level: Integer; const OrgFileName: tbtstring; FileName: tbtstring;
  const ModuleName: tbtstring; Dest: TStream);
var
  Parser: TPSPascalPreProcessorParser;
  dta: tbtstring;
  item: TPSLineInfo;
  s, name: tbtstring;
  current, i: Longint;
  ds: TPSDefineState;
  AppContinue: Boolean;
  ADoWrite: Boolean;
  lAdded: Cardinal;
  lOffsetIdx: Longint;
  lName: tbtstring;
  lIsMain: Boolean;
  lLineCommentEnds: Boolean;
begin
  if Level > MaxLevel then raise EPSPreProcessor.CreateFmt(RPS_TooManyNestedInclude, [FileName, OrgFileName]);
  Parser := TPSPascalPreProcessorParser.Create;
  try
    Parser.OnNewLine := ParserNewLine;
    { the main text is the top level's; an include is the finder's to supply,
      by its name and the file naming it -- the main text only where the
      finder supplies nothing for the main file's name }
    lName := FileName;
    lIsMain := FileName = MainFileName;
    if lIsMain and (Level = 0) then
      dta := MainFile
    else if (@OnNeedFile = nil) or (not OnNeedFile(Self, OrgFileName, FileName, dta)) then
    begin
      if not lIsMain then
        raise EPSPreProcessor.CreateFmt(RPS_IncludeNotFound, [FileName, OrgFileName]);
      FileName := lName;
      dta := MainFile;
    end;
    Item := FCurrentLineInfo.Add;
    current := FCurrentLineInfo.Count -1;
    FCurrentLineInfo.Current := current;
    Item.FStartPos := Dest.Position;
    Item.FFileName := FileName;
    Item.FModuleName := FastUpperCase(ModuleName);
    Item.FModuleText := Level = 0;
    Parser.SetText(dta);
    while Parser.TokenId <> ptEOF do
    begin
      s := Parser.Token;
      { a token the text ends inside: a directive is refused; at an include's
        end a string or a comment written out would run on into the including
        text -- refused, as in Delphi -- and a // comment ends with the include }
      lLineCommentEnds := False;
      if Parser.FEndsInside then
      begin
        if Parser.TokenId = ptDefine then
          raise EPSPreProcessor.CreateFmt(RPS_EndInsideAToken, [FileName, Parser.Row, Parser.Col])
        else if (Level > 0) and FDefineState.DoWrite then
        begin
          if s[1] = '/' then
            lLineCommentEnds := True
          else
            raise EPSPreProcessor.CreateFmt(RPS_EndInsideAToken, [FileName, Parser.Row, Parser.Col]);
        end;
      end;
      if Parser.TokenId = ptDefine then
      begin
        if s[1] = '(' then
        begin
          Delete(s, 1, 3);  // delete the (*$
          Delete(s, Length(s) - 1, 2); // delete the *)
        end else
        begin
          Delete(s,1,2);  // delete the {$
          Delete(s,length(s), 1); // delete the }
        end;

        //-- 20050707_jgv trim right: a blank is any character up to a space,
        //-- a tab or a line break as well
        i := length (s);
        while (i > 0) and (s[i] <= ' ') do begin
          Delete (s, i, 1);
          Dec (i);
        end;
        //-- end_jgv

        i := _BlankPos(s);
        if i = 0 then
        begin
          name := uppercase(s);
          s := '';
        end else
        begin
          Name := uppercase(copy(s, 1, i - 1));
          Delete(s, 1, i);
          // the operand starts past its blanks
          while (s <> '') and (s[1] <= ' ') do
            Delete(s, 1, 1);
        end;

        //-- 20050707_jgv - ask the application
        AppContinue := True;
        If @OnProcessDirective <> Nil then OnProcessDirective (Self, Parser, FDefineState.DoWrite, name, s, AppContinue);

        If AppContinue then
        //-- end jgv

          if (Name = 'I') or (Name = 'INCLUDE') then
          begin
            if FDefineState.DoWrite then
            begin
              if s = '' then raise EPSPreProcessor.CreateFmt(RPS_MissingParameter, [FileName, Parser.Row, Parser.Col]);
              { the bytes added before the directive: its line breaks were
                counted with them }
              lAdded := FAddedPosition;
              FAddedPosition := 0;
              IntPreProcess(Level +1, FileName, s, ModuleName, Dest);
              FCurrentLineInfo.Current := current;
              FAddedPosition := Cardinal(Dest.Position) - Item.StartPos - Parser.Pos;
              Item.FIncludeEnds.Add(Pointer(Cardinal(Dest.Position) - Item.StartPos));
              Item.FIncludeAdded.Add(Pointer(FAddedPosition));
              { the directive's blanks follow the include's text: a row that
                starts inside the directive starts past that text }
              lOffsetIdx := Item.FLineOffsets.Count -1;
              while (lOffsetIdx >= 0) and
                (Cardinal(Item.FLineOffsets[lOffsetIdx]) > Parser.Pos + lAdded) do
              begin
                Item.FLineOffsets[lOffsetIdx] :=
                  Pointer(Cardinal(Item.FLineOffsets[lOffsetIdx]) + FAddedPosition - lAdded);
                Dec(lOffsetIdx);
              end;
            end;
          end else if (Name = 'DEFINE') then
          begin
            if FDefineState.DoWrite then
            begin
              if _BlankPos(s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
              if s = '' then raise EPSPreProcessor.CreateFmt(RPS_MissingParameter, [FileName, Parser.Row, Parser.Col]);
              FCurrentDefines.Add(Uppercase(S));
            end;
          end else if (Name = 'UNDEF') then
          begin
            if FDefineState.DoWrite then
            begin
              if _BlankPos(s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
              if s = '' then raise EPSPreProcessor.CreateFmt(RPS_MissingParameter, [FileName, Parser.Row, Parser.Col]);
              { every entry: a symbol defined twice is listed twice }
              i := FCurrentDefines.IndexOf(Uppercase(s));
              while i <> -1 do
              begin
                FCurrentDefines.Delete(i);
                i := FCurrentDefines.IndexOf(Uppercase(s));
              end;
            end;
          end else if (Name = 'IFDEF') then
          begin
            if _BlankPos(s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
            if s = '' then raise EPSPreProcessor.CreateFmt(RPS_MissingParameter, [FileName, Parser.Row, Parser.Col]);
            //JeromeWelsh - nesting fix
            ADoWrite := (FCurrentDefines.IndexOf(Uppercase(s)) >= 0) and FDefineState.DoWrite;
            FDefineState.Add.DoWrite := ADoWrite;
          end else if (Name = 'IFNDEF') then
          begin
            if _BlankPos(s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
            if s = '' then raise EPSPreProcessor.CreateFmt(RPS_MissingParameter, [FileName, Parser.Row, Parser.Col]);
            //JeromeWelsh - nesting fix
            ADoWrite := (FCurrentDefines.IndexOf(Uppercase(s)) < 0) and FDefineState.DoWrite;
            FDefineState.Add.DoWrite := ADoWrite;
          end else if (Name = 'ENDIF') then
          begin
            //- jgv remove - borland use it (sysutils.pas)
            //- if s <> '' then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [Parser.Row, Parser.Col]);
            if FDefineState.Count = 0 then
              raise EPSPreProcessor.CreateFmt(RPS_NoIfdefForEndif, [FileName, Parser.Row, Parser.Col]);
            FDefineState.Delete(FDefineState.Count -1); // remove define from list
          end else if (Name = 'ELSE') then
          begin
            if s<> '' then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
            if FDefineState.Count = 0 then
              raise EPSPreProcessor.CreateFmt(RPS_NoIfdefForElse, [FileName, Parser.Row, Parser.Col]);
            ds := FDefineState[FDefineState.Count -1];
            if ds.InElse then
              raise EPSPreProcessor.CreateFmt(RPS_ElseTwice, [FileName, Parser.Row, Parser.Col]);
            ds.FInElse := True;
            //JeromeWelsh - nesting fix
            ds.DoWrite := not ds.DoWrite and FDefineState.DoPrevWrite;
          end

          //-- 20050710_jgv custom application error process
          else begin
            If @OnProcessUnknowDirective <> Nil then begin
              OnProcessUnknowDirective (Self, Parser, FDefineState.DoWrite, name, s, AppContinue);
            end;
            If AppContinue then
            //-- end jgv
          
              raise EPSPreProcessor.CreateFmt(RPS_UnknownCompilerDirective, [FileName, Parser.Row, Parser.Col]);
          end;
      end;

      if (not FDefineState.DoWrite) or (Parser.TokenId = ptDefine) or lLineCommentEnds then
      begin
        SetLength(s, Length(Parser.Token));
        for i := length(s) downto 1 do
          s[i] := #32; // space
      end;
      Dest.Write(s[1], length(s));
      Parser.Next;
    end;
    Item.FEndPos := Dest.Position;
  finally
    Parser.Free;
  end;
end;

procedure TPSPreProcessor.ParserNewLine(Sender: TPSPascalPreProcessorParser; Row, Col, Pos: Cardinal);
begin
  if FCurrentLineInfo.Current >= FCurrentLineInfo.Count then exit; //errr ???
  with FCurrentLineInfo.Items[FCurrentLineInfo.Current] do
  begin
    Pos := Pos + FAddedPosition;
    FLineOffsets.Add(Pointer(Pos));
  end;
end;

procedure TPSPreProcessor.PreProcess(const Filename: tbtstring; var Output: tbtstring;
  const ModuleName: tbtstring);
var
  Stream: TMemoryStream;
begin
  FAddedPosition := 0;
  { a call refused before its end left its conditions open }
  FDefineState.Clear;
  {$IFDEF FPC}
  FCurrentDefines.AddStrings(FDefines);
  {$ELSE}
  FCurrentDefines.Assign(FDefines);
  {$ENDIF}
  Stream := TMemoryStream.Create;
  try
    IntPreProcess(0, '', FileName, ModuleName, Stream);
    Stream.Position := 0;
    SetLength(Output, Stream.Size);
    Stream.Read(Output[1], Length(Output));
  finally
    Stream.Free;
  end;
  if FDefineState.Count <> 0 then
    raise EPSPreProcessor.Create(RPs_DefineNotClosed);
end;

{ TPSDefineStates }

function TPSDefineStates.Add: TPSDefineState;
begin
  Result := TPSDefineState.Create;
  FItems.Add(Result);
end;

procedure TPSDefineStates.Clear;
var
  i: Longint;
begin
  for i := Longint(FItems.Count) -1 downto 0 do
    TPSDefineState(FItems[i]).Free;
  FItems.Clear;
end;

constructor TPSDefineStates.Create;
begin
  inherited Create;
  FItems := TIfList.Create;
end;

procedure TPSDefineStates.Delete(I: Integer);
begin
  TPSDefineState(FItems[i]).Free;
  FItems.Delete(i);
end;

destructor TPSDefineStates.Destroy;
var
  i: Longint;
begin
  for i := Longint(FItems.Count) -1 downto 0 do
    TPSDefineState(FItems[i]).Free;
  FItems.Free;
  inherited Destroy;
end;

function TPSDefineStates.GetCount: Longint;
begin
  Result := FItems.Count;
end;

function TPSDefineStates.GetItem(I: Integer): TPSDefineState;
begin
  Result := FItems[i];
end;

function TPSDefineStates.GetWrite: Boolean;
begin
  if FItems.Count = 0 then
    result := true
  else Result := TPSDefineState(FItems[FItems.Count -1]).DoWrite;
end;

//JeromeWelsh - nesting fix
function TPSDefineStates.GetPrevWrite: Boolean;
begin
  if FItems.Count < 2 then
    result := true
  else Result := TPSDefineState(FItems[FItems.Count -2]).DoWrite;
end;

end.
