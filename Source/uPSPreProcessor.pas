
unit uPSPreProcessor;
{$I PascalScript.inc}

interface

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}

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
  protected
    FEndPos: Cardinal;
    FStartPos: Cardinal;
    FFileName: tbtstring;
    FLineOffsets: TIfList;
  public
    
    property FileName: tbtstring read FFileName;
    
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
    fCompiler : TPSPascalCompiler;
    procedure ParserNewLine(Sender: TPSPascalPreProcessorParser; Row, Col, Pos: Cardinal);
    procedure IntPreProcess(Level: Integer; const OrgFileName: tbtstring; FileName: tbtstring; Dest: TStream);
  protected
    procedure doAddStdPredefines; virtual; // jgv
  public
    {The maximum number of levels deep the parser will go, defaults to 20}
    property MaxLevel: Longint read FMaxLevel write FMaxLevel;
    property CurrentLineInfo: TPSLineInfoList read FCurrentLineInfo;

    property OnNeedFile: TPSOnNeedFile read FOnNeedFile write FOnNeedFile;

    property Defines: TStringList read FDefines write FDefines;
    property Compiler : TPSPascalCompiler read fCompiler write fCompiler;

    property MainFile: tbtstring read FMainFile write FMainFile;

    property MainFileName: tbtstring read FMainFileName write FMainFileName;

    property ID: Pointer read FID write FID;

    procedure AdjustMessages(Comp: TPSPascalCompiler);
    procedure AdjustMessage(Msg: TPSPascalCompilerMessage); //-jgv

    procedure PreProcess(const Filename: tbtstring; var Output: tbtstring);

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
    FLastEnterPos, FLen, FRow, FCol, FPos: Cardinal;
    FOnNewLine: TPSOnNewLine;
  public
    
    procedure SetText(const dta: tbtstring);
    
    procedure Next;
    
    property Token: tbtstring read FToken;
    
    property TokenId: TPSPascalPreProcessorType read FTokenId;
    
    property Row: Cardinal read FRow;
    
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

uses
  StrUtils;

{$IFDEF DELPHI3UP }
resourceString
{$ELSE }
const
{$ENDIF }

  RPS_TooManyNestedInclude = 'Too many nested include files while processing ''%s'' from ''%s''';
  RPS_IncludeNotFound = 'Unable to find file ''%s'' used from ''%s''';
  RPS_DefineTooManyParameters = 'Too many parameters in ''%s'' at %d:%d';
  RPS_DefineTooLessParameters = 'Too less parameters in ''%s'' at %d:%d';
  RPS_DefineInvalidParameters = 'Invalid parameters in ''%s'' at %d:%d';
  RPS_NoIfdefForEndif = 'No IFDEF for ENDIF in ''%s'' at %d:%d';
  RPS_NoIfdefForElse = 'No IFDEF for ELSE in ''%s'' at %d:%d';
  RPS_ElseTwice = 'Can''t use ELSE twice in ''%s'' at %d:%d';
  RPS_UnknownCompilerDirective = 'Unknown compiler directives in ''%s'' at %d:%d';
  RPs_DefineNotClosed = 'Define not closed';

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
    if (Pos >= Item.StartPos) and (Pos < Item.EndPos) and
      (lModuleName = '') or (lModuleName = Item.FileName) then
    begin
      Res.Name := Item.FileName;
      Pos := Pos - Item.StartPos;
      Res.Pos := Pos;
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
        Res.Col := pos - linepos + 1;
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
end;

destructor TPSLineInfo.Destroy;
begin
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

{ TPSPascalPreProcessorParser }

procedure TPSPascalPreProcessorParser.Next;
var
  ci: Cardinal;

begin
  FPos := FPos + FLen;
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
            if FText[ci] = #10 then
              inc(ci);
            FLastEnterPos := ci -1;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            break;
          end else if FText[ci] = #10 then
          begin
            inc(FRow);
            FLastEnterPos := ci -1;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            break;
          end;
        end;
        FLen := ci - FPos + 1;
        FTokenId := ptOther;
      end;
    '(':
      begin
        if FText[FPos + 1] = '*' then
        begin
          ci := FPos + 1;
          while (FText[ci] <> #0) do begin
            if (FText[ci] = '*') and (FText[ci + 1] = ')') then
              Break;
            if FText[ci] = #13 then
            begin
              inc(FRow);
              if FText[ci+1] = #10 then
                inc(ci);
              FLastEnterPos := ci -1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            end else if FText[ci] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := ci -1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            end;
            Inc(ci);
          end;
          FTokenId := ptOther;
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
              FLastEnterPos := ci - 1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            end else if FText[ci] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := ci - 1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            end;
            Inc(ci);
          end;
          if FText[FPos + 1] = '$' then
            FTokenId := ptDefine
          else
            FTokenId := ptOther;

          FLen := ci - FPos + 1;
        end;
      else
      begin
        //vizit0r - added for correct handling of #10 (without #13) as linebreak
        ci := FPos;
        if FText[ci] in [#10,#13] then
          while (FText[ci] in [#10,#13]) do
          begin
            if FText[ci] = #13 then
            begin
              inc(FRow);
              if FText[ci+1] = #10 then
                inc(ci);
              FLastEnterPos := ci - 1;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            end else if FText[ci] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := ci -1 ;
              if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
            end;
            Inc(Ci);
          end
        else
        //end_vizit0r
        ci := FPos + 1;
        while not (FText[ci] in [#0,'{', '(', '''', '/']) do
        begin
          if FText[ci] = #13 then
          begin
            inc(FRow);
            if FText[ci+1] = #10 then
              inc(ci);
            FLastEnterPos := ci - 1;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
          end else if FText[ci] = #10 then
          begin
            inc(FRow);
            FLastEnterPos := ci -1 ;
            if @FOnNewLine <> nil then FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci+1);
          end;
          Inc(Ci);
        end;
        FTokenId := ptOther;
        FLen := ci - FPos;
      end;
  end;
  FCol := FPos - FLastEnterPos + 1;
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
  if CurrentLineInfo.GetLineInfo(Msg.ModuleName, Msg.Pos, Res) then
  begin
    Msg.SetCustomPos(res.Pos, Res.Row, Res.Col);
    Msg.ModuleName := Res.Name;
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
  FCompiler := nil;

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

procedure TPSPreProcessor.IntPreProcess(Level: Integer; const OrgFileName: tbtstring; FileName: tbtstring; Dest: TStream);
const
  sDEFINED = 'DEFINED(';
  sDECLARED= 'DECLARED(';
  sNOT     = 'NOT';
  sAND     = 'AND';
  sOR      = 'OR';
  sANDNOT  = 'ANDNOT';
  sORNOT   = 'ORNOT';
  sCompilerVersion = 'COMPILERVERSION';
var
  Parser: TPSPascalPreProcessorParser;
  dta: tbtstring;
  item: TPSLineInfo;
  s, ts, name: tbtstring;
  current, i, j : Longint;
  ds: TPSDefineState;
  AppContinue: Boolean;
  ADoWrite: Boolean;
begin
  if Level > MaxLevel then raise EPSPreProcessor.CreateFmt(RPS_TooManyNestedInclude, [FileName, OrgFileName]);
  Parser := TPSPascalPreProcessorParser.Create;
  try
    Parser.OnNewLine := ParserNewLine;
    if FileName = MainFileName then
    begin
      dta := MainFile;
    end else
    if (@OnNeedFile = nil) or (not OnNeedFile(Self, OrgFileName, FileName, dta)) then
      raise EPSPreProcessor.CreateFmt(RPS_IncludeNotFound, [FileName, OrgFileName]);
    Item := FCurrentLineInfo.Add;
    current := FCurrentLineInfo.Count -1;
    FCurrentLineInfo.Current := current;
    Item.FStartPos := Dest.Position;
    Item.FFileName := FileName;
    Parser.SetText(dta);
    while Parser.TokenId <> ptEOF do
    begin
      s := Parser.Token;
      if Parser.TokenId = ptDefine then
      begin
        Delete(s,1,2);  // delete the {$
        Delete(s,length(s), 1); // delete the }

        //-- 20050707_jgv trim right
        i := length (s);
        while (i > 0) and (s[i] = ' ') do begin
          Delete (s, i, 1);
          Dec (i);
        end;
        //-- end_jgv

        if pos(tbtChar(' '), s) = 0 then
        begin
          name := uppercase(s);
          s := '';
        end else
        begin
          Name := uppercase(copy(s,1,pos(' ', s)-1));
          Delete(s, 1, pos(' ', s));
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
              FAddedPosition := 0;
              IntPreProcess(Level +1, FileName, s, Dest);
              FCurrentLineInfo.Current := current;
              FAddedPosition := Cardinal(Dest.Position) - Item.StartPos - Parser.Pos;
            end;
          end else if (Name = 'DEFINE') then
          begin
            if FDefineState.DoWrite then
            begin
              if pos(' ', s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
              FCurrentDefines.Add(Uppercase(S));
            end;
          end else if (Name = 'UNDEF') then
          begin
            if FDefineState.DoWrite then
            begin
              if pos(' ', s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
              i := FCurrentDefines.IndexOf(Uppercase(s));
              if i <> -1 then
                FCurrentDefines.Delete(i);
            end;
          end else if (Name = 'IFDEF') then
          begin
            if pos(' ', s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
            //JeromeWelsh - nesting fix
            ADoWrite := (FCurrentDefines.IndexOf(Uppercase(s)) >= 0) and FDefineState.DoWrite;
            FDefineState.Add.DoWrite := ADoWrite;
          end else if (Name = 'IFNDEF') then
          begin
            if pos(' ', s) <> 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [FileName, Parser.Row, Parser.Col]);
            //JeromeWelsh - nesting fix
            ADoWrite := (FCurrentDefines.IndexOf(Uppercase(s)) < 0) and FDefineState.DoWrite;
            FDefineState.Add.DoWrite := ADoWrite;
          end else if (Name = 'ENDIF') OR (Name = 'IFEND') then
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
          end else if (Name = 'IF') then
          begin
            if pos(' ', s) = 0 then raise EPSPreProcessor.CreateFmt(RPS_DefineTooLessParameters, [FileName, Parser.Row, Parser.Col]);
            S := Trim( S );
            S := UpperCase( s );
            S := StringReplace( s, #32#32, #32, [ rfReplaceAll ] );
            S := StringReplace( s, ' (', '(', [ rfReplaceAll ] );
            S := StringReplace( s, '( ', '(', [ rfReplaceAll ] );
            S := StringReplace( s, ' )', ')', [ rfReplaceAll ] );
            S := StringReplace( s, ') ', ')', [ rfReplaceAll ] );

            if ( Copy( s, 1, Length( sDEFINED ) ) = sDEFINED ) OR
               ( Copy( s, 1, Length( sNOT ) + Length( sDEFINED ) ) = sNOT + sDEFINED ) OR
                ( Copy( s, 1, Length( sNOT ) + Length( sDEFINED ) + 1 ) = sNOT + ' ' + sDEFINED ) then
              begin
              S := StringReplace( s, ' NOT', 'NOT', [ rfReplaceAll ] );
              S := StringReplace( s, 'NOT ', 'NOT', [ rfReplaceAll ] );

              S := StringReplace( s, ' AND', 'AND', [ rfReplaceAll ] );
              S := StringReplace( s, 'AND ', 'AND', [ rfReplaceAll ] );
              S := StringReplace( s, ' OR', 'OR', [ rfReplaceAll ] );
              S := StringReplace( s, 'OR ', 'OR', [ rfReplaceAll ] );

              ADoWrite := FDefineState.DoWrite;
              ts := s;

              if ( Copy( ts, 1, Length( sNOT ) ) = sNOT ) then
                begin
                j := 2;
                ts := Copy( ts, Length( sNOT )+1, Length( ts )-Length( sNOT ) );
                end
              else
                j := 0; // AND

              while ( ts <> '' ) do
                begin
                i := PosEx( ')', ts, Length( sDEFINED )+1 );
                if ( i = 0 ) then
                  begin
                  raise EPSPreProcessor.CreateFmt(RPS_DefineInvalidParameters, [FileName, Parser.Row, Parser.Col]);
                  Break;
                  end;

                if ( j = 0 ) then // AND
                  ADoWrite := (FCurrentDefines.IndexOf( Copy( ts, Length( sDefined )+1, i-Length( sDefined )-1 ) ) >= 0) and ADoWrite
                else if ( j = 1 ) then // OR
                  ADoWrite := (FCurrentDefines.IndexOf( Copy( ts, Length( sDefined )+1, i-Length( sDefined )-1 ) ) >= 0) OR ADoWrite
                else if ( j = 2 ) then // (AND) NOT
                  ADoWrite := (FCurrentDefines.IndexOf( Copy( ts, Length( sDefined )+1, i-Length( sDefined )-1 ) ) < 0) AND ADoWrite
                else if ( j = 3 ) then // OR NOT
                  ADoWrite := (FCurrentDefines.IndexOf( Copy( ts, Length( sDefined )+1, i-Length( sDefined )-1 ) ) < 0) OR ADoWrite
                else
                  ADoWrite := (FCurrentDefines.IndexOf( Copy( ts, Length( sDefined )+1, i-Length( sDefined )-1 ) ) >= 0) OR ADoWrite;
                ts := Copy( ts, i+1, Length( ts )-i );

                if ( Copy( ts, 1, Length( sANDNOT ) ) = sANDNOT ) then
                  begin
                  j  := 2;
                  ts := Copy( ts, Length( sANDNOT )+1, Length( ts )-Length( sANDNOT ) );
                  end
                else if ( Copy( ts, 1, Length( sORNOT ) ) = sORNOT ) then
                  begin
                  j  := 3;
                  ts := Copy( ts, Length( sORNOT )+1, Length( ts )-Length( sORNOT ) );
                  end
                else if ( Copy( ts, 1, Length( sAND ) ) = sAND ) then
                  begin
                  j  := 0;
                  ts := Copy( ts, Length( sAND )+1, Length( ts )-Length( sAND ) );
                  end
                else if ( Copy( ts, 1, Length( sOR ) ) = sOR ) then
                  begin
                  j := 1;
                  ts := Copy( ts, Length( sOR )+1, Length( ts )-Length( sOR ) );
                  end;
                end;

              FDefineState.Add.DoWrite := ADoWrite;
              end

(*
            else if Assigned( fCompiler ) AND ( Copy( s, 1, Length( sDECLARED ) ) = sDECLARED ) OR
               ( Copy( s, 1, Length( sNOT ) + Length( sDECLARED ) ) = sNOT + sDECLARED ) OR
                ( Copy( s, 1, Length( sNOT ) + Length( sDECLARED ) + 1 ) = sNOT + ' ' + sDECLARED ) then
              begin
              S := StringReplace( s, ' NOT', 'NOT', [ rfReplaceAll ] );
              S := StringReplace( s, 'NOT ', 'NOT', [ rfReplaceAll ] );

              S := StringReplace( s, ' AND', 'AND', [ rfReplaceAll ] );
              S := StringReplace( s, 'AND ', 'AND', [ rfReplaceAll ] );
              S := StringReplace( s, ' OR', 'OR', [ rfReplaceAll ] );
              S := StringReplace( s, 'OR ', 'OR', [ rfReplaceAll ] );

              ADoWrite := FDefineState.DoWrite;
              ts := s;

              if ( Copy( ts, 1, Length( sNOT ) ) = sNOT ) then
                begin
                j := 2;
                ts := Copy( ts, Length( sNOT )+1, Length( ts )-Length( sNOT ) );
                end
              else
                j := 0; // AND

              while ( ts <> '' ) do
                begin
                i := PosEx( ')', ts, Length( sDECLARED )+1 );
                if ( i = 0 ) then
                  begin
                  raise EPSPreProcessor.CreateFmt(RPS_DefineInvalidParameters, [FileName, Parser.Row, Parser.Col]);
                  Break;
                  end;

//                if ( fCompiler.GetConstant( Copy( ts, Length( sDECLARED )+1, i-Length( sDECLARED )-1 ) ) <> nil ) then
//                  k := 0
//                else
                  k := -1;

//                if ( k < 0 ) then
//                  begin
//                  if ( fCompiler.GetVariable( Copy( ts, Length( sDECLARED )+1, i-Length( sDECLARED )-1 ) ) <> nil ) then
//                    k := 0
//                  end;

//                if ( k < 0 ) then
//                  k := fCompiler.FindProc( Copy( ts, Length( sDECLARED )+1, i-Length( sDECLARED )-1 ) );
//                if ( k < 0 ) then
//                  begin
//                  if ( fCompiler.FindType( Copy( ts, Length( sDECLARED )+1, i-Length( sDECLARED )-1 ) ) <> nil ) then
//                    k := 0
//                  end;
//                if ( k < 0 ) then
//                  begin
//                  if ( fCompiler.FindClass( Copy( ts, Length( sDECLARED )+1, i-Length( sDECLARED )-1 ) ) <> nil ) then
//                    k := 0
//                  end;

                if ( j = 0 ) then // AND
                  ADoWrite := (k >= 0) and ADoWrite
                else if ( j = 1 ) then // OR
                  ADoWrite := (k >= 0) OR ADoWrite
                else if ( j = 2 ) then // (AND) NOT
                  ADoWrite := (k < 0) AND ADoWrite
                else if ( j = 3 ) then // OR NOT
                  ADoWrite := (k < 0) OR ADoWrite
                else
                  ADoWrite := (k >= 0) OR ADoWrite;
                ts := Copy( ts, i+1, Length( ts )-i );

                if ( Copy( ts, 1, Length( sANDNOT ) ) = sANDNOT ) then
                  begin
                  j  := 2;
                  ts := Copy( ts, Length( sANDNOT )+1, Length( ts )-Length( sANDNOT ) );
                  end
                else if ( Copy( ts, 1, Length( sORNOT ) ) = sORNOT ) then
                  begin
                  j  := 3;
                  ts := Copy( ts, Length( sORNOT )+1, Length( ts )-Length( sORNOT ) );
                  end
                else if ( Copy( ts, 1, Length( sAND ) ) = sAND ) then
                  begin
                  j  := 0;
                  ts := Copy( ts, Length( sAND )+1, Length( ts )-Length( sAND ) );
                  end
                else if ( Copy( ts, 1, Length( sOR ) ) = sOR ) then
                  begin
                  j := 1;
                  ts := Copy( ts, Length( sOR )+1, Length( ts )-Length( sOR ) );
                  end;
                end;

              FDefineState.Add.DoWrite := ADoWrite;
              end
*)

            else if ( Copy( s, 1, Length( sCompilerVersion ) ) = sCompilerVersion ) then
              begin
              S := StringReplace( s, #32, '', [ rfReplaceAll ] );

              if ( Copy( S, 16, 2 ) = '>=' ) then
                FDefineState.Add.DoWrite := ( StrToIntDef( Copy( S, 18, Length( S )-17 ), -1 ) >= CompilerVersion )
              else if ( Copy( S, 16, 2 ) = '<=' ) then
                FDefineState.Add.DoWrite := ( StrToIntDef( Copy( S, 18, Length( S )-17 ), High( Integer ) ) <= CompilerVersion )
              else if ( Copy( S, 16, 1 ) = '<' ) then
                FDefineState.Add.DoWrite := ( StrToIntDef( Copy( S, 17, Length( S )-16 ), High( Integer ) ) < CompilerVersion )
              else if ( Copy( S, 16, 1 ) = '>' ) then
                FDefineState.Add.DoWrite := ( StrToIntDef( Copy( S, 17, Length( S )-16 ), -1 ) > CompilerVersion )
              else if ( Copy( S, 16, 1 ) = '=' ) then
                FDefineState.Add.DoWrite := ( StrToIntDef( Copy( S, 17, Length( S )-16 ), -1 ) = CompilerVersion )
              else
                raise EPSPreProcessor.CreateFmt(RPS_DefineInvalidParameters, [FileName, Parser.Row, Parser.Col]);
              end
            else
              begin
              If @OnProcessUnknowDirective <> Nil then begin
                OnProcessUnknowDirective (Self, Parser, FDefineState.DoWrite, name, s, AppContinue);
              end;
              If AppContinue then
              //-- end jgv
                raise EPSPreProcessor.CreateFmt(RPS_UnknownCompilerDirective, [FileName, Parser.Row, Parser.Col]);
              end;

          // Compatibility Dummys
          end else if (Name = 'UNSAFE_TYPE') OR (Name = 'UNSAFE_CODE') OR (Name = 'UNSAFE_CAST') OR (Name = 'SYMBOL_PLATFORM') OR
                      (Name = 'GARBAGE') OR (Name = 'WARN') OR (Name = 'RANGECHECKS') OR (Name = 'WEAKPACKAGEUNIT') OR
                      (Name = 'EXTERNALSYM') OR (Name = 'NODEFINE') then
            begin
            SetLength(s, Length(Parser.Token));
            for i := length(s) downto 1 do
              s[i] := #32; // space
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

      if (not FDefineState.DoWrite) or (Parser.TokenId = ptDefine) then
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

procedure TPSPreProcessor.PreProcess(const Filename: tbtstring; var Output: tbtstring);
var
  Stream: TMemoryStream;
begin
  FAddedPosition := 0;
  {$IFDEF FPC}
  FCurrentDefines.AddStrings(FDefines);
  {$ELSE}
  FCurrentDefines.Assign(FDefines);
  {$ENDIF}
  Stream := TMemoryStream.Create;
  try
    IntPreProcess(0, '', FileName, Stream);
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
