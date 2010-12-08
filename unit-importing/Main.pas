unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, SynEditHighlighter, SynHighlighterPas, SynEdit, Menus, ExtCtrls,
  StdCtrls, SynEditMiscClasses, inifiles, ComCtrls, ImgList, ToolWin,
  SynEditSearch, SynEditTypes;

type
  TfrmMain = class(TForm)
    OpenDialog1: TOpenDialog;
    pashighlighter: TSynPasSyn;
    mnuMain: TMainMenu;
    File1: TMenuItem;
    mnuOpen: TMenuItem;
    mnuSave: TMenuItem;
    N4: TMenuItem;
    mnuExit: TMenuItem;
    lboMessages: TListBox;
    Splitter1: TSplitter;
    Convert1: TMenuItem;
    mnuConvert: TMenuItem;
    N1: TMenuItem;
    mnuSettings: TMenuItem;
    TabControl1: TTabControl;
    Editor: TSynEdit;
    mnuSaveAll: TMenuItem;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton7: TToolButton;
    ImageList1: TImageList;
    DlgTextSearch: TFindDialog;
    Edit1: TMenuItem;
    ToolButton8: TToolButton;
    tlbFind: TToolButton;
    tlbFindNext: TToolButton;
    mnuFind: TMenuItem;
    mnuFindNext: TMenuItem;
    stbMain: TStatusBar;
    N2: TMenuItem;
    GoTo1: TMenuItem;
    mnuRecent: TMenuItem;
    N3: TMenuItem;
    ToolButton6: TToolButton;
    SynEditSearch1: TSynEditSearch;

    procedure EditorDropFiles(Sender: TObject; X, Y: Integer;   AFiles: TStrings);

    procedure FormCreate(Sender: TObject);
    procedure AnyCommand(Sender: TObject);
    procedure mnuSettingsClick(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure TabControl1Changing(Sender: TObject;
      var AllowChange: Boolean);
    procedure EditorChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DlgTextSearchFind(Sender: TObject);
    procedure mnuFindClick(Sender: TObject);
    procedure mnuFindNextClick(Sender: TObject);
    procedure lboMessagesDblClick(Sender: TObject);
    procedure GoTo1Click(Sender: TObject);
    procedure EditorScroll(Sender: TObject; ScrollBar: TScrollBarKind);
    procedure EditorClick(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EditorKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    fIniFile    : TIniFile;
    fLoading    : Boolean;
    FModified   : Boolean;
    FFile       : string;
    fOutputDir  : String;
    fPrifix     : String;
    FAfterInterfaceDeclaration: string;
    FAutoRenameOverloadedMethods: Boolean;        
    fLastUsed   : TStringList;
    FUseUnitAtDT: Boolean;
    FSingleUnit : Boolean;
    FSearchOptions   : TSynSearchOptions;
    FSearchText, FReplaceText : string;
    procedure Convert;
    procedure DoSearchReplaceText(AReplace: Boolean; ABackwards: boolean);
    function GetErrorXY(const inStr:string):TBufferCoord;
    procedure ReadLastUsedList;
    procedure SaveLastUsedList;
    procedure BuildLastUsedMenu(aMenuItem:TMenuItem);
    procedure mnuLastUsedClick(Sender: TObject);
    procedure WriteSetttingsToIni(const AIni: TIniFile);
  public
    constructor Create(aOwner:TComponent);override;
    destructor Destroy;override;
    procedure ClearTabs(FirstToo: boolean = true);
    function SaveCheck: Boolean;
    procedure LoadFile(aFileName:String);
    procedure SaveFiles(AllFiles:Boolean);
    procedure WriteLn(const s : string);
    procedure ReadLn(var s : string;const Promote,Caption : string);
    procedure ExecCmd(Cmd: Integer);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  ParserU, FormSettings, StrUtils, UFrmGotoLine;

const
  OPEN_CMD              = 100;
  SAVE_CMD              = 101;
  SAVE_ALL_CMD          = 102;
  EXIT_CMD              = 103;
  CONVERT_CMD           = 104;
  MAX_LAST_USED_COUNT   = 4; // Maximum number of last used files in the Menus.
  StatusLabel = 'Current Row: %D Col: %D'; // Used internally with the format
                        // function in order to follow the caret position.
{ globals }

function Minimum(int1,int2:Integer):Integer;
begin
  Result := int1;
  if int1 > int2 then Result := int2;
end;

function SearchToSynsearch(SO: TFindOptions): TSynSearchOptions;
begin
  Result := [];
  if frMatchCase in SO then Include(Result, ssoMatchCase);
  if frWholeWord in SO then Include(Result, ssoWholeWord);
  if frReplace	 in SO then Include(Result, ssoReplace);
  if not (frDown in SO) then Include(Result, ssoBackwards);
  if frReplaceAll in SO then Include(Result, ssoReplaceAll);
  if frMatchCase in SO then Include(Result, ssoMatchCase);
  if frFindNext in SO then Include(Result, ssoMatchCase);
end;

function SynSearchTosearch(SynO: TSynSearchOptions): TFindOptions;
begin
  Result := [];
  if ssoMatchCase in SynO then Include(Result, frMatchCase);
  if ssoWholeWord in SynO then Include(Result, frWholeWord );
  if ssoReplace in SynO then Include(Result,frReplace );
  if not (ssoBackwards in SynO) then Include(Result,frDown);
  if ssoReplaceAll in SynO then Include(Result, frReplaceAll);
  if ssoMatchCase in SynO then Include(Result, frMatchCase);
  if ssoMatchCase in SynO then Include(Result, frFindNext);
end;

(*----------------------------------------------------------------------------*)
function  DateTimeToFileName(const DT: TDateTime; UseMSecs: Boolean = False): string;
begin
  case UseMSecs of
    False : Result := FormatDateTime('yyyy-mm-dd_hh_nn_ss', DT);
    True  : Result := FormatDateTime('yyyy-mm-dd_hh_nn_ss_zzz', DT);
  end;
end;
(*----------------------------------------------------------------------------*)
function NormalizePath(const Path: string): string;
begin
  Result := Path;
  case Length(Result) of
    0 : {AppError('Path can not be an empty string')};
    1 : if (UpCase(Result[1]) in ['A'..'Z']) then
          Result := Result + ':\';
    2 : if (UpCase(Result[1]) in ['A'..'Z']) then
          if Result[2] = ':' then
            Result := Result + '\';
    else
        if not (Result[Length(Result)] = '\') then
           Result := Result + '\';
  end;
end;


{ methods }
(*----------------------------------------------------------------------------*)
function TfrmMain.SaveCheck: Boolean;
begin
  if FModified then
  begin
    case MessageDlg('File has not been saved, save now?', mtConfirmation, mbYesNoCancel, 0) of
      idYes:
        begin
          ExecCmd(SAVE_CMD);
          Result := FFile <> '';
        end;
      IDNO: Result := True;
      else
        Result := False;
    end;
  end else Result := True;
end;

(*----------------------------------------------------------------------------*)
procedure TfrmMain.Convert;
var
  Parser : TUnitParser;
  Path   : string;
  OldTab : Integer;
  List   : TStringList;
  AllowChange : Boolean;
begin
  OldTab := TabControl1.TabIndex;
  TabControl1Changing(Self, AllowChange);
  TabControl1.TabIndex := -1;
  lboMessages.Clear;

  Parser := TUnitParser.Create('conv.ini');
  try
    Parser.WriteLn     := WriteLn;
    Parser.ReadLn      := ReadLn;
    Parser.UseUnitAtDT := FUseUnitAtDT;
    Parser.SingleUnit  := FSingleUnit;
    Parser.UnitPrefix := fPrifix;
    Parser.AfterInterfaceDeclaration := FAfterInterfaceDeclaration;
    Parser.AutoRenameOverloadedMethods := FAutoRenameOverloadedMethods;

    try
      Parser.ParseUnit((Tabcontrol1.tabs.Objects[0] as tStringList).Text);
      WriteLn('Succesfully parsed');
    except
      on E: Exception do
      begin
        WriteLn('Exception: '+ E.Message);
        Exit;
      end;
    end;
    ClearTabs(false);
    Path := NormalizePath(Trim(FOutPutDir));

{    if not DirectoryExists(Path) then
    begin
      Path := NormalizePath(ExtractFilePath(Application.ExeName) + DateTimeToFileName(Now, False));
      FOutPutDir := Path;
    end;

    ForceDirectories(Path);
    Parser.SaveToPath(Path);}
    if FSingleUnit then
    begin
      list := TstringList.create;
      TabControl1.tabs.AddObject(parser.UnitNameCmp,list);
      List.Text := parser.OutUnitList.Text;
      List.SaveToFile(Path + parser.UnitNameCmp);
    end else begin
      List := TStringList.Create;
      List.Text := parser.OutputRT;
      List.SaveToFile(Path + parser.UnitnameRT);
      TabControl1.tabs.AddObject(parser.UnitnameRT,list);

      List := TStringList.Create;
      List.Text := parser.OutputDT;
      List.SaveToFile(Path + parser.UnitnameCT);
      TabControl1.tabs.AddObject(parser.UnitnameCT,list);
    end;
    WriteLn('Files saved');
  finally
    Parser.Free;
    TabControl1.TabIndex := OldTab;
    TabControl1Change(Self);
  end;

end;

(*----------------------------------------------------------------------------*)
procedure TfrmMain.ReadLn(var s: string; const Promote, Caption: string);
begin
  s := InputBox(Caption, Promote, s)
end;

(*----------------------------------------------------------------------------*)
procedure TfrmMain.WriteLn(const s: string);
begin
  lboMessages.Items.Add(s);
end;

{ events }

(*----------------------------------------------------------------------------*)
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  fLoading   := false;
  fIniFile   := TIniFile.create(ExtractFilePath(Application.ExeName)+'Default.ini');
  Try
    fOutPutDir   := fIniFile.ReadString('Main','OutputDir',
                                        ExtractFilePath(Application.ExeName) + 'Import\');
    FSingleUnit  := fIniFile.ReadBool('Main','SingleUnit',True);
    FUseUnitAtDT := fIniFile.ReadBool('Main','UseUnitAtDT',False);
    fPrifix      := fIniFile.ReadString('Main','FilePrefix', 'uPS');
    FAfterInterfaceDeclaration := fIniFile.ReadString('Main','AfterInterfaceDeclaration', '');
    FAutoRenameOverloadedMethods := fIniFile.ReadBool('Main','AutoRenameOverloadedMethods', False);
  finally
    fIniFile.Free;
  end;
  ForceDirectories(fOutPutDir);

  mnuOpen       .Tag := OPEN_CMD      ;
  mnuSave       .Tag := SAVE_CMD      ;
  mnuSaveAll    .Tag := SAVE_ALL_CMD   ;
  mnuExit       .Tag := EXIT_CMD      ;
  mnuConvert    .Tag := CONVERT_CMD   ;
  TabControl1.tabs.Text := '';
  TabControl1.tabs.AddObject('Main',TStringList.Create);

  If ParamCount>0 then
    LoadFile(Paramstr(1));
end;

(*----------------------------------------------------------------------------*)
procedure TfrmMain.EditorDropFiles(Sender: TObject; X, Y: Integer; AFiles: TStrings);
begin
  LoadFile(AFiles[0]);
end;

(*----------------------------------------------------------------------------*)
procedure TfrmMain.AnyCommand(Sender: TObject);
begin
  ExecCmd(TComponent(Sender).Tag);
end;

(*----------------------------------------------------------------------------*)
procedure TfrmMain.ExecCmd(Cmd: Integer);
begin
  case Cmd of
    OPEN_CMD       : begin
                       if SaveCheck then
                       begin
                         if OpenDialog1.Execute then
                         begin
                           Editor.ClearAll;
                           LoadFile(OpenDialog1.FileName);
                           Editor.Modified := False;
                           FFile := OpenDialog1.FileName;
                         end;
                       end;
                     end;
    SAVE_CMD       : begin
                       if FFile <> '' then
                       begin
                         SaveFiles(False);
                         Editor.Modified := False;
                       end;
                     end;
    SAVE_ALL_CMD    : begin
                       if FFile <> '' then
                       begin
                         SaveFiles(True);
                         Editor.Modified := False;
                       end;
                     end;
    EXIT_CMD       : Close;
    CONVERT_CMD    : Convert;
  end;
end;

(*----------------------------------------------------------------------------*)
procedure TfrmMain.mnuSettingsClick(Sender: TObject);
begin
  with TfrmSettings.create(self) do begin
    try
      cbCreateOneImportfile.Checked  := FSingleUnit;
      cbUseUnitAtCompileTime.Checked := FUseUnitAtDT;
      edtOutPutDir.Text              := fOutputDir;
      edtPrefix.Text                 := fPrifix;
      If ShowModal = mrOk then begin
        FSingleUnit  := cbCreateOneImportfile.Checked;
        FUseUnitAtDT := cbUseUnitAtCompileTime.Checked;
        fOutputDir   := edtOutPutDir.Text;
        fPrifix      := edtPrefix.Text;
        If default.Checked then begin
          fIniFile   := TIniFile.create(ExtractFilePath(Application.ExeName)+'Default.ini');
          Try
            WriteSetttingsToIni(fIniFile);
          finally
            fIniFile.Free;
          end;
        end;
        if ffile <> '' then begin
          fIniFile  := TIniFile.create(ChangeFileExt(FFile,'.iip'));
          Try
            WriteSetttingsToIni(fIniFile);
          finally
            fIniFile.Free;
          end;
        end;
        FModified := True;
      end;
    finally
      Free;
    end;
  end;
end;

procedure TfrmMain.LoadFile(aFileName: String);
var
  AllowChange : Boolean;

  Function getText(AFile:String):TStringList;
  begin
    Result := TStringList.Create;
    Result.LoadFromFile(aFile);
  end;
begin
  FFile := aFileName;
  ClearTabs;
  TabControl1Changing(Self, AllowChange);
  TabControl1.Tabs.AddObject(ExtractFileName(FFile), GetText(FFile));

  // if it allready exists in the list the please remove it we do not want any duplicates.
  if fLastUsed.IndexOf(FFile) > -1 then
    fLastUsed.Delete(fLastUsed.IndexOf(FFile));
  fLastUsed.Insert(0,FFile); // now add the new file in the first position on the list.
  BuildLastUsedMenu(mnuRecent);

  aFileName := fOutPutDir+ChangeFileExt(ExtractFileName(FFile),'.int');
  TabControl1.TabIndex := 1;
  TabControl1Change(Self);
end;

procedure TfrmMain.SaveFiles;
var
  oldTab, x : Integer;

  Procedure DoSave(TabId : Integer);
  begin
    If pos('*',Tabcontrol1.tabs[Tabid])<>0 then
      Tabcontrol1.tabs[Tabid] := StringReplace(Tabcontrol1.tabs[Tabid],' *','',[]);
    (Tabcontrol1.tabs.Objects[TabId] as tStringList).SaveToFile(fOutputDir+Tabcontrol1.tabs[Tabid]);
  end;

begin
  OldTab := TabControl1.TabIndex;
  TabControl1.TabIndex := -1;
  Try
    fIniFile  := TIniFile.create(ChangeFileExt(FFile,'.iip'));
    Try
      WriteSetttingsToIni(fIniFile);
    finally
      fIniFile.Free;
    end;
    FModified := False;
    If AllFiles then begin
      for x := 0 to Tabcontrol1.tabs.Count -1 do begin
        If pos('*',Tabcontrol1.tabs[x])<>0 then DoSave(x);
      end;
    end else begin
      DoSave(OldTab);
      for x := 0 to Tabcontrol1.tabs.Count -1 do begin
        If pos('*',Tabcontrol1.tabs[x])<>0 then FModified := True;
      end;
    end;
  finally
    TabControl1.TabIndex := OldTab;
  end;
end;

procedure TfrmMain.TabControl1Change(Sender: TObject);
begin
  fLoading := True;
  Try
    If Tabcontrol1.TabIndex = -1 then begin
      Editor.Lines.Text := '';
    end else begin
      Editor.Lines.Assign(Tabcontrol1.tabs.Objects[Tabcontrol1.TabIndex] as TStringList);
      Editor.ReadOnly := Tabcontrol1.TabIndex < 0;
      Editor.Modified := false;
    end;
  finally
    fLoading := False;
  end;
end;

procedure TfrmMain.TabControl1Changing(Sender: TObject;
  var AllowChange: Boolean);
begin
  AllowChange:= True;
  If Tabcontrol1.TabIndex = -1 then exit;
  (Tabcontrol1.tabs.Objects[Tabcontrol1.TabIndex]as TStringList).Assign(Editor.Lines);
end;

procedure TfrmMain.EditorChange(Sender: TObject);
begin
  If Not FLoading then begin
    FModified := True;
    If pos('*',Tabcontrol1.tabs[Tabcontrol1.TabIndex])=0 then
      Tabcontrol1.tabs[Tabcontrol1.TabIndex] := Tabcontrol1.tabs[Tabcontrol1.TabIndex]+' *';
  end;
end;

procedure TfrmMain.ClearTabs(FirstToo: boolean);
var
  l, i: Integer;
begin
  if firsttoo then l := 0 else l := 1;
  for i := TabControl1.Tabs.Count -1 downto l do
  begin
    TabControl1.Tabs.Objects[i].Free;
    TabControl1.Tabs.Delete(i);
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ClearTabs(true);
end;

procedure TfrmMain.DlgTextSearchFind(Sender: TObject);
begin
  DlgTextSearch.CloseDialog;
  FSearchText := DlgTextSearch.FindText;
  FSearchOptions := SearchToSynsearch(DlgTextSearch.Options);
  if (ssoReplace in FSearchOptions) or (ssoReplaceAll in FSearchOptions) then Include (FSearchOptions,ssoPrompt);
  DoSearchReplaceText(False,ssoBackwards in FSearchOptions);
end;

procedure TfrmMain.DoSearchReplaceText(AReplace, ABackwards: boolean);
begin
  if Editor.SearchReplace(FSearchText, FReplaceText, FSearchOptions) = 0 then
  begin
    MessageBeep(MB_ICONASTERISK);
    if ssoBackwards in FSearchOptions then
      Editor.BlockEnd := Editor.BlockBegin
    else
      Editor.BlockBegin := Editor.BlockEnd;
    Editor.CaretXY := Editor.BlockBegin;
  end;
end;

procedure TfrmMain.mnuFindClick(Sender: TObject);
begin
  DlgTextSearch.FindText := FSearchText;
  DlgTextSearch.Execute
end;

procedure TfrmMain.mnuFindNextClick(Sender: TObject);
begin
  DoSearchReplaceText(False, ssoBackwards in FSearchOptions);
end;

procedure TfrmMain.lboMessagesDblClick(Sender: TObject);
begin
  if LeftStr(lboMessages.Items[lboMessages.ItemIndex],10)= 'Exception:' then
  begin
    Editor.CaretXY := GetErrorXY(lboMessages.Items[lboMessages.ItemIndex]);
  end;
  Editor.SetFocus;
end;

function TfrmMain.GetErrorXY(const inStr: string): TBufferCoord;
var
  RowCol:string;
  Row:string;
  Col:string;
begin
  RowCol := ReverseString(inStr);
  Col := Copy(RowCol,1,Pos(':',RowCol) -1);
  RowCol := Copy(RowCol,Pos(':',RowCol)+ 1, MaxInt);
  Row := Copy(RowCol,1,Pos(':',RowCol)-1);
  Result.Char := StrToInt(Trim(ReverseString(Col)));
  Result.Line := StrToInt(Trim(ReverseString(Row)));
end;

procedure TfrmMain.GoTo1Click(Sender: TObject);
begin
  with TfrmGotoLine.Create(self) do
  try
    Char := Editor.CaretX;
    Line := Editor.CaretY;
    ShowModal;
    if ModalResult = mrOK then
      Editor.CaretXY := CaretXY;
  finally
    Free;
    Editor.SetFocus;
  end;
end;

constructor TfrmMain.Create(aOwner: TComponent);
begin
  inherited;
  fLastUsed := TStringList.Create;
  ReadLastUsedList;
  BuildLastUsedMenu(mnuRecent);
end;

destructor TfrmMain.Destroy;
begin
  SaveLastUsedList;
  fLastUsed.Free;
  inherited;
end;

procedure TfrmMain.ReadLastUsedList;
var
  fIni   : TIniFile;
  DumStr : string;
  Cntr   : Integer;
begin
  fIni := TIniFile.Create(ExtractFilePath(Application.ExeName)+'Default.ini');
  try
    for Cntr := 1 to MAX_LAST_USED_COUNT do
    begin
      DumStr := fIni.ReadString('LastUsed','File'+IntToStr(Cntr),'');
      if DumStr <> '' then fLastUsed.Add(DumStr);
    end;
  finally
    fIni.Free;
  end;
end;

procedure TfrmMain.SaveLastUsedList;
var
  fIni   : TIniFile;
  Max, Cntr   : Integer;
begin
  Max := fLastUsed.Count;
  if Max > MAX_LAST_USED_COUNT then Max := MAX_LAST_USED_COUNT;
  if Max > 0 then
  begin
    fIni := TIniFile.Create(ExtractFilePath(Application.ExeName)+'Default.ini');
    try
      for Cntr := 0 to Max -1  do
        fIni.WriteString('LastUsed','File'+IntToStr(Cntr+1),fLastUsed.Strings[Cntr]);
    finally
      fIni.Free;
    end;
  end;
end;

procedure TfrmMain.BuildLastUsedMenu(aMenuItem: TMenuItem);
var
  Cntr, Max : Integer;
  mnuDum : TMenuItem;
begin
  Max := fLastUsed.Count;
  if Max > MAX_LAST_USED_COUNT then Max := MAX_LAST_USED_COUNT; // max count
  aMenuItem.Clear;
  for Cntr := 0 to Max - 1 do
  begin
    mnuDum :=TMenuItem.Create(Self);
    mnuDum.Caption := fLastUsed.Strings[Cntr]; // only the filename
    mnuDum.Hint := fLastUsed.Strings[Cntr];
    mnuDum.Name := 'mnuLastUsed' + IntToStr(Cntr+1);
    mnuDum.Tag := 1000 + Cntr;
    mnuDum.OnClick := mnuLastUsedClick;
    aMenuItem.Add(mnuDum);
  end;
end;

procedure TfrmMain.mnuLastUsedClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    Self.LoadFile(fLastUsed.Strings[TMenuItem(Sender).Tag - 1000]);
end;

procedure TfrmMain.EditorScroll(Sender: TObject;
  ScrollBar: TScrollBarKind);
begin
  stbMain.Panels[0].Text := Format(StatusLabel,[Editor.CaretY, Editor.CaretX]);
end;

procedure TfrmMain.EditorClick(Sender: TObject);
begin
  stbMain.Panels[0].Text := Format(StatusLabel,[Editor.CaretY, Editor.CaretX]);
end;

procedure TfrmMain.EditorKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  stbMain.Panels[0].Text := Format(StatusLabel,[Editor.CaretY, Editor.CaretX]);
end;

procedure TfrmMain.EditorKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  stbMain.Panels[0].Text := Format(StatusLabel,[Editor.CaretY, Editor.CaretX]);
end;

procedure TfrmMain.WriteSetttingsToIni(const AIni: TIniFile);
begin
  AIni.WriteString('Main','OutputDir', fOutputDir);
  AIni.WriteBool('Main','SingleUnit' , FSingleUnit);
  AIni.WriteBool('Main','UseUnitAtDT', FUseUnitAtDT);
  AIni.WriteString('Main','FilePrefix', fPrifix);
  AIni.WriteString('Main','AfterInterfaceDeclaration', FAfterInterfaceDeclaration);
  AIni.WriteBool('Main','AutoRenameOverloadedMethods', FAutoRenameOverloadedMethods);
end;

end.
