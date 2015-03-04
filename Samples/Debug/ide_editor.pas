//Version: 31Jan2005

unit ide_editor;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, StdCtrls, ComCtrls,
  SynEdit, SynEditTypes, SynHighlighterPas,
  uPSComponent_COM, uPSComponent_StdCtrls, uPSComponent_Forms,
  uPSComponent_Default, uPSComponent_Controls,
  uPSRuntime, uPSDisassembly, uPSUtils,
  uPSComponent, uPSDebugger, SynEditRegexSearch, 
  SynEditSearch, SynEditMiscClasses, SynEditHighlighter;

type
  Teditor = class(TForm)
    ce: TPSScriptDebugger;
    IFPS3DllPlugin1: TPSDllPlugin;
    pashighlighter: TSynPasSyn;
    ed: TSynEdit;
    PopupMenu1: TPopupMenu;
    BreakPointMenu: TMenuItem;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Run1: TMenuItem;
    StepOver1: TMenuItem;
    StepInto1: TMenuItem;
    N1: TMenuItem;
    Reset1: TMenuItem;
    N2: TMenuItem;
    Run2: TMenuItem;
    Exit1: TMenuItem;
    messages: TListBox;
    Splitter1: TSplitter;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    N3: TMenuItem;
    N4: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    Save1: TMenuItem;
    Saveas1: TMenuItem;
    StatusBar: TStatusBar;
    Decompile1: TMenuItem;
    N5: TMenuItem;
    IFPS3CE_Controls1: TPSImport_Controls;
    IFPS3CE_DateUtils1: TPSImport_DateUtils;
    IFPS3CE_Std1: TPSImport_Classes;
    IFPS3CE_Forms1: TPSImport_Forms;
    IFPS3CE_StdCtrls1: TPSImport_StdCtrls;
    IFPS3CE_ComObj1: TPSImport_ComObj;
    Pause1: TMenuItem;
    SynEditSearch: TSynEditSearch;
    SynEditRegexSearch: TSynEditRegexSearch;
    Search1: TMenuItem;
    Find1: TMenuItem;
    Replace1: TMenuItem;
    Searchagain1: TMenuItem;
    N6: TMenuItem;
    Gotolinenumber1: TMenuItem;
    Syntaxcheck1: TMenuItem;
    procedure edSpecialLineColors(Sender: TObject; Line: Integer; var Special: Boolean; var FG, BG: TColor);
    procedure BreakPointMenuClick(Sender: TObject);
    procedure ceLineInfo(Sender: TObject; const FileName: String; Position, Row, Col: Cardinal);
    procedure Exit1Click(Sender: TObject);
    procedure StepOver1Click(Sender: TObject);
    procedure StepInto1Click(Sender: TObject);
    procedure Reset1Click(Sender: TObject);
    procedure ceIdle(Sender: TObject);
    procedure Run2Click(Sender: TObject);
    procedure ceExecute(Sender: TPSScript);
    procedure ceAfterExecute(Sender: TPSScript);
    procedure ceCompile(Sender: TPSScript);
    procedure New1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure Saveas1Click(Sender: TObject);
    procedure edStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure Decompile1Click(Sender: TObject);
    function ceNeedFile(Sender: TObject; const OrginFileName: String; var FileName, Output: String): Boolean;
    procedure ceBreakpoint(Sender: TObject; const FileName: String; Position, Row, Col: Cardinal);
    procedure Pause1Click(Sender: TObject);
    procedure messagesDblClick(Sender: TObject);
    procedure Gotolinenumber1Click(Sender: TObject);
    procedure Find1Click(Sender: TObject);
    procedure Searchagain1Click(Sender: TObject);
    procedure Replace1Click(Sender: TObject);
    procedure Syntaxcheck1Click(Sender: TObject);
    procedure edDropFiles(Sender: TObject; X, Y: Integer;
      AFiles: TStrings);
  private
    FSearchFromCaret: boolean;
    FActiveLine: Longint;
    FResume: Boolean;
    FActiveFile: string;
    function Compile: Boolean;
    function Execute: Boolean;

    procedure Writeln(const s: string);
    procedure Readln(var s: string);
    procedure SetActiveFile(const Value: string);

    procedure DoSearchReplaceText(AReplace: boolean; ABackwards: boolean);
    procedure ShowSearchReplaceDialog(AReplace: boolean);

    property aFile: string read FActiveFile write SetActiveFile;
  public
    function SaveCheck: Boolean;
  end;

var
  editor: Teditor;

implementation

uses
  ide_debugoutput,
  uFrmGotoLine,
  dlgSearchText, dlgReplaceText, dlgConfirmReplace;

{$R *.dfm}

const
  isRunningOrPaused = [isRunning, isPaused];

// options - to be saved to the registry
var
  gbSearchBackwards: boolean;
  gbSearchCaseSensitive: boolean;
  gbSearchFromCaret: boolean;
  gbSearchSelectionOnly: boolean;
  gbSearchTextAtCaret: boolean;
  gbSearchWholeWords: boolean;
  gbSearchRegex: boolean;
  gsSearchText: string;
  gsSearchTextHistory: string;
  gsReplaceText: string;
  gsReplaceTextHistory: string;

resourcestring
  STR_TEXT_NOTFOUND = 'Text not found';
  STR_UNNAMED = 'Unnamed';
  STR_SUCCESSFULLY_COMPILED = 'Successfully compiled';
  STR_SUCCESSFULLY_EXECUTED = 'Successfully executed';
  STR_RUNTIME_ERROR='[Runtime error] %s(%d:%d), bytecode(%d:%d): %s'; //Birb
  STR_FORM_TITLE = 'Editor';
  STR_FORM_TITLE_RUNNING = 'Editor - Running';
  STR_INPUTBOX_TITLE = 'Script';
  STR_DEFAULT_PROGRAM = 'Program test;'#13#10'begin'#13#10'end.';
  STR_NOTSAVED = 'File has not been saved, save now?';

procedure Teditor.DoSearchReplaceText(AReplace: boolean; ABackwards: boolean);
var
  Options: TSynSearchOptions;
begin
  Statusbar.SimpleText := '';
  if AReplace then
    Options := [ssoPrompt, ssoReplace, ssoReplaceAll]
  else
    Options := [];
  if ABackwards then
    Include(Options, ssoBackwards);
  if gbSearchCaseSensitive then
    Include(Options, ssoMatchCase);
  if not fSearchFromCaret then
    Include(Options, ssoEntireScope);
  if gbSearchSelectionOnly then
    Include(Options, ssoSelectedOnly);
  if gbSearchWholeWords then
    Include(Options, ssoWholeWord);
  if gbSearchRegex then
    ed.SearchEngine := SynEditRegexSearch
  else
    ed.SearchEngine := SynEditSearch;
  if ed.SearchReplace(gsSearchText, gsReplaceText, Options) = 0 then
  begin
    MessageBeep(MB_ICONASTERISK);
    Statusbar.SimpleText := STR_TEXT_NOTFOUND;
    if ssoBackwards in Options then
      ed.BlockEnd := ed.BlockBegin
    else
      ed.BlockBegin := ed.BlockEnd;
    ed.CaretXY := ed.BlockBegin;
  end;

  if ConfirmReplaceDialog <> nil then
    ConfirmReplaceDialog.Free;
end;

procedure Teditor.ShowSearchReplaceDialog(AReplace: boolean);
var
  dlg: TTextSearchDialog;
begin
  Statusbar.SimpleText := '';
  if AReplace then
    dlg := TTextReplaceDialog.Create(Self)
  else
    dlg := TTextSearchDialog.Create(Self);
  with dlg do try
    // assign search options
    SearchBackwards := gbSearchBackwards;
    SearchCaseSensitive := gbSearchCaseSensitive;
    SearchFromCursor := gbSearchFromCaret;
    SearchInSelectionOnly := gbSearchSelectionOnly;
    // start with last search text
    SearchText := gsSearchText;
    if gbSearchTextAtCaret then begin
      // if something is selected search for that text
      if ed.SelAvail and (ed.BlockBegin.Line = ed.BlockEnd.Line) //Birb (fix at SynEdit's SearchReplaceDemo)
      then
        SearchText := ed.SelText
      else
        SearchText := ed.GetWordAtRowCol(ed.CaretXY);
    end;
    SearchTextHistory := gsSearchTextHistory;
    if AReplace then with dlg as TTextReplaceDialog do begin
      ReplaceText := gsReplaceText;
      ReplaceTextHistory := gsReplaceTextHistory;
    end;
    SearchWholeWords := gbSearchWholeWords;
    if ShowModal = mrOK then begin
      gbSearchBackwards := SearchBackwards;
      gbSearchCaseSensitive := SearchCaseSensitive;
      gbSearchFromCaret := SearchFromCursor;
      gbSearchSelectionOnly := SearchInSelectionOnly;
      gbSearchWholeWords := SearchWholeWords;
      gbSearchRegex := SearchRegularExpression;
      gsSearchText := SearchText;
      gsSearchTextHistory := SearchTextHistory;
      if AReplace then with dlg as TTextReplaceDialog do begin
        gsReplaceText := ReplaceText;
        gsReplaceTextHistory := ReplaceTextHistory;
      end;
      fSearchFromCaret := gbSearchFromCaret;
      if gsSearchText <> '' then begin
        DoSearchReplaceText(AReplace, gbSearchBackwards);
        fSearchFromCaret := TRUE;
      end;
    end;
  finally
    dlg.Free;
  end;
end;

procedure Teditor.edSpecialLineColors(Sender: TObject; Line: Integer;
  var Special: Boolean; var FG, BG: TColor);
begin
  if ce.HasBreakPoint(ce.MainFileName, Line) then
  begin
    Special := True;
    if Line = FActiveLine then
    begin
      BG := clWhite;
      FG := clRed;
    end else
    begin
      FG := clWhite;
      BG := clRed;
    end;
  end else
  if Line = FActiveLine then
  begin
    Special := True;
    FG := clWhite;
    bg := clBlue;
  end else Special := False;
end;

procedure Teditor.BreakPointMenuClick(Sender: TObject);
var
  Line: Longint;
begin
  Line := Ed.CaretY;
  if ce.HasBreakPoint(ce.MainFileName, Line) then
    ce.ClearBreakPoint(ce.MainFileName, Line)
  else
    ce.SetBreakPoint(ce.MainFileName, Line);
  ed.Refresh;
end;

procedure Teditor.ceLineInfo(Sender: TObject; const FileName: String; Position, Row,
  Col: Cardinal);
begin
  if (ce.Exec.DebugMode <> dmRun) and (ce.Exec.DebugMode <> dmStepOver) then
  begin
    FActiveLine := Row;
    if (FActiveLine < ed.TopLine +2) or (FActiveLine > Ed.TopLine + Ed.LinesInWindow -2) then
    begin
      Ed.TopLine := FActiveLine - (Ed.LinesInWindow div 2);
    end;
    ed.CaretY := FActiveLine;
    ed.CaretX := 1;

    ed.Refresh;
  end
  else
    Application.ProcessMessages;
end;

procedure Teditor.Exit1Click(Sender: TObject);
begin
  Reset1Click(nil); //terminate any running script
  if SaveCheck then //check if script changed and not yet saved
    Close;
end;

procedure Teditor.StepOver1Click(Sender: TObject);
begin
  if ce.Exec.Status in isRunningOrPaused then
    ce.StepOver
  else
  begin
    if Compile then
    begin
      ce.StepInto;
      Execute;
    end;
  end;
end;

procedure Teditor.StepInto1Click(Sender: TObject);
begin
  if ce.Exec.Status in isRunningOrPaused then
    ce.StepInto
  else
  begin
    if Compile then
    begin
      ce.StepInto;
      Execute;
    end;
  end;
end;

procedure Teditor.Pause1Click(Sender: TObject);
begin
 if ce.Exec.Status = isRunning then
   begin
   ce.Pause;
   ce.StepInto;
   end;
end;

procedure Teditor.Reset1Click(Sender: TObject);
begin
  if ce.Exec.Status in isRunningOrPaused then
    ce.Stop;
end;

function Teditor.Compile: Boolean;
var
  i: Longint;
begin
  ce.Script.Assign(ed.Lines);
  Result := ce.Compile;
  messages.Clear;
  for i := 0 to ce.CompilerMessageCount -1 do
  begin
    Messages.Items.Add(ce.CompilerMessages[i].MessageToString);
  end;
  if Result then
    Messages.Items.Add(STR_SUCCESSFULLY_COMPILED);
end;

procedure Teditor.ceIdle(Sender: TObject);
begin
  Application.ProcessMessages; //Birb: don't use Application.HandleMessage here, else GUI will be unrensponsive if you have a tight loop and won't be able to use Run/Reset menu action
  if FResume then
  begin
    FResume := False;
    ce.Resume;
    FActiveLine := 0;
    ed.Refresh;
  end;
end;

procedure Teditor.Run2Click(Sender: TObject);
begin
  if CE.Running then
  begin
    FResume := True
  end else
  begin
    if Compile then
      Execute;
  end;
end;

procedure Teditor.ceExecute(Sender: TPSScript);
begin
  ce.SetVarToInstance('SELF', Self);
  ce.SetVarToInstance('APPLICATION', Application);
  Caption := STR_FORM_TITLE_RUNNING;
end;

procedure Teditor.ceAfterExecute(Sender: TPSScript);
begin
  Caption := STR_FORM_TITLE;
  FActiveLine := 0;
  ed.Refresh;
end;

function Teditor.Execute: Boolean;
begin
  debugoutput.Output.Clear;
  if CE.Execute then
  begin
    Messages.Items.Add(STR_SUCCESSFULLY_EXECUTED);
    Result := True; 
  end else
  begin
    messages.Items.Add(Format(STR_RUNTIME_ERROR, [extractFileName(aFile), ce.ExecErrorRow,ce.ExecErrorCol,ce.ExecErrorProcNo,ce.ExecErrorByteCodePosition,ce.ExecErrorToString])); //Birb
    Result := False;
  end;
end;

procedure Teditor.Writeln(const s: string);
begin
  debugoutput.output.Lines.Add(S);
  debugoutput.Visible := True;
end;

procedure Teditor.ceCompile(Sender: TPSScript);
begin
  Sender.AddMethod(Self, @TEditor.Writeln, 'procedure writeln(s: string)');
  Sender.AddMethod(Self, @TEditor.Readln, 'procedure readln(var s: string)');
  Sender.AddRegisteredVariable('Self', 'TForm');
  Sender.AddRegisteredVariable('Application', 'TApplication');
end;

procedure Teditor.Readln(var s: string);
begin
  s := InputBox(STR_INPUTBOX_TITLE, '', '');
end;

procedure Teditor.New1Click(Sender: TObject);
begin
  if SaveCheck then //check if script changed and not yet saved
  begin
    ed.ClearAll;
    ed.Lines.Text := STR_DEFAULT_PROGRAM;
    ed.Modified := False;
    aFile := '';
  end;
end;

procedure Teditor.Open1Click(Sender: TObject);
begin
  if SaveCheck then //check if script changed and not yet saved
  begin
    if OpenDialog1.Execute then
    begin
      ed.ClearAll;
      ed.Lines.LoadFromFile(OpenDialog1.FileName);
      ed.Modified := False;
      aFile := OpenDialog1.FileName;
    end;
  end;
end;

procedure Teditor.Save1Click(Sender: TObject);
begin
  if aFile <> '' then
  begin
    ed.Lines.SaveToFile(aFile);
    ed.Modified := False;
  end else
    SaveAs1Click(nil);
end;

procedure Teditor.Saveas1Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    aFile := SaveDialog1.FileName;
    ed.Lines.SaveToFile(aFile);
    ed.Modified := False;
  end;
end;

//check if script changed and not yet saved//
function Teditor.SaveCheck: Boolean;
begin
  if ed.Modified then
  begin
    case MessageDlg(STR_NOTSAVED, mtConfirmation, mbYesNoCancel, 0) of
      idYes:
        begin
          Save1Click(nil);
          Result := aFile <> '';
        end;
      IDNO: Result := True;
      else
        Result := False;
    end;
  end else Result := True;
end;

procedure Teditor.edStatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  StatusBar.Panels[0].Text := IntToStr(ed.CaretY)+':'+IntToStr(ed.CaretX)
end;

procedure Teditor.Decompile1Click(Sender: TObject);
var
  s: string;
begin
  if Compile then
  begin
    ce.GetCompiled(s);
    IFPS3DataToText(s, s);
    debugoutput.output.Lines.Text := s;
    debugoutput.visible := true;
  end;
end;

function Teditor.ceNeedFile(Sender: TObject; const OrginFileName: String;
  var FileName, Output: String): Boolean;
var
  path: string;
  f: TFileStream;
begin
  if aFile <> '' then
    Path := ExtractFilePath(aFile)
  else
    Path := ExtractFilePath(ParamStr(0));
  Path := Path + FileName;
  try
    F := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  except
    Result := false;
    exit;
  end;
  try
    SetLength(Output, f.Size);
    f.Read(Output[1], Length(Output));
  finally
    f.Free;
  end;
  Result := True;
end;

procedure Teditor.ceBreakpoint(Sender: TObject; const FileName: String; Position, Row,
  Col: Cardinal);
begin
  FActiveLine := Row;
  if (FActiveLine < ed.TopLine +2) or (FActiveLine > Ed.TopLine + Ed.LinesInWindow -2) then
  begin
    Ed.TopLine := FActiveLine - (Ed.LinesInWindow div 2);
  end;
  ed.CaretY := FActiveLine;
  ed.CaretX := 1;

  ed.Refresh;
end;

procedure Teditor.SetActiveFile(const Value: string);
begin
  FActiveFile := Value;
  ce.MainFileName := ExtractFileName(FActiveFile);
  if Ce.MainFileName = '' then
    Ce.MainFileName := STR_UNNAMED;
end;

function GetErrorRowCol(const inStr: string): TBufferCoord;
var
  Row:string;
  Col:string;
  p1,p2,p3:integer;
begin
  p1:=Pos('(',inStr);
  p2:=Pos(':',inStr);
  p3:=Pos(')',inStr);
  if (p1>0) and (p2>p1) and (p3>p2) then
  begin
    Row := Copy(inStr, p1+1,p2-p1-1);
    Col := Copy(inStr, p2+1,p3-p2-1);
    Result.Char := StrToInt(Trim(Col));
    Result.Line := StrToInt(Trim(Row));
  end
  else
  begin
    Result.Char := 1;
    Result.Line := 1;
  end
end;

procedure Teditor.messagesDblClick(Sender: TObject);
begin
  //if Copy(messages.Items[messages.ItemIndex],1,7)= '[Error]' then
  //begin
    ed.CaretXY := GetErrorRowCol(messages.Items[messages.ItemIndex]);
    ed.SetFocus;
  //end;
end;

procedure Teditor.Gotolinenumber1Click(Sender: TObject);
begin
  with TfrmGotoLine.Create(self) do
  try
    Char := ed.CaretX;
    Line := ed.CaretY;
    ShowModal;
    if ModalResult = mrOK then
      ed.CaretXY := CaretXY;
  finally
    Free;
    ed.SetFocus;
  end;
end;

procedure Teditor.Find1Click(Sender: TObject);
begin
  ShowSearchReplaceDialog(FALSE);
end;

procedure Teditor.Searchagain1Click(Sender: TObject);
begin
  DoSearchReplaceText(FALSE, FALSE);
end;

procedure Teditor.Replace1Click(Sender: TObject);
begin
  ShowSearchReplaceDialog(TRUE);
end;

procedure Teditor.Syntaxcheck1Click(Sender: TObject);
begin
 Compile;
end;

procedure Teditor.edDropFiles(Sender: TObject; X, Y: Integer;
  AFiles: TStrings);
begin
 if AFiles.Count>=1 then
  if SaveCheck then //check if script changed and not yet saved
  begin
    ed.ClearAll;
    ed.Lines.LoadFromFile(AFiles[0]);
    ed.Modified := False;
    aFile := AFiles[0];
  end;
end;

end.

