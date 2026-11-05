unit uPSR_dll;

{$I PascalScript.inc}
interface
uses
  uPSRuntime, uPSUtils;

procedure RegisterDLLRuntime(Caller: TPSExec);
procedure RegisterDLLRuntimeEx(Caller: TPSExec; AddDllProcImport, RegisterUnloadDLL: Boolean);

function ProcessDllImport(Caller: TPSExec; P: TPSExternalProcRec): Boolean;
function ProcessDllImportEx(Caller: TPSExec; P: TPSExternalProcRec; ForceDelayLoad: Boolean): Boolean;
function ProcessDllImportEx2(Caller: TPSExec; P: TPSExternalProcRec; ForceDelayLoad: Boolean; var DelayLoad: Boolean; var ErrorCode: LongInt): Boolean;
procedure UnloadDLL(Caller: TPSExec; const sname: tbtstring);
function UnloadProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
function UnloadAll(Caller: TPSExec): Boolean;

implementation
uses
  {$IFDEF UNIX}
  {$IFDEF FPC}
  SysUtils, Unix, baseunix, dynlibs, termio, sockets;
  {$ELSE}
  Unix, baseunix, dynlibs, termio, sockets;
  {$ENDIF}
  {$ELSE}
  {$IFDEF MSWINDOWS}
  SysUtils, Windows;
  {$ELSE}
  SysUtils;
  {$ENDIF}
  {$ENDIF}

{
p^.Ext1 contains the pointer to the Proc function
p^.ExportDecl:
  'dll:'+DllName+#0+FunctionName+#0+chr(Cc)+Chr(DelayLoad)+Chr(AlternateSearchPath)+VarParams
}

type
  PLoadedDll = ^TLoadedDll;
  TLoadedDll = record
    dllnamehash: Longint;
    dllname: tbtstring;
    dllhandle: THandle;
  end;
  TMyExec = class(TPSExec);
  PInteger = ^Integer;

procedure LAstErrorFree(Sender: TPSExec; P: PInteger);
begin
  dispose(p);
end;

procedure DLLSetLastError(Sender: TPSExec; P: Integer);
var
  pz: PInteger;
begin
  pz := Sender.FindProcResource(@LastErrorFree);
  if pz = nil then
  begin
    new(pz);
    Sender.AddResource(@LastErrorFree, PZ);
  end;
  pz^ := p;
end;

function DLLGetLastError(Sender: TPSExec): Integer;
var
  pz: PInteger;
begin
  pz := Sender.FindProcResource(@LastErrorFree);
  if pz = nil then
    result := 0
  else
    result := pz^;
end;


procedure DllFree(Sender: TPSExec; P: PLoadedDll);
begin
  FreeLibrary(p^.dllhandle);
  Dispose(p);
end;

{ the bytes of a declaration after its library and routine names -- the
  convention, delay-load and search-path bytes, the result's and one per
  parameter -- or '' where it does not hold the first four; the names
  follow the four-byte prefix ('dll:'), as LoadDll and UnloadDLL take them }
function _DllDeclTail(const aDecl: tbtstring): tbtstring;
var
  lAt: Longint;
begin
  Result := Copy(aDecl, 5, MaxInt);
  Result := Copy(Result, Pos(tbtchar(#0), Result) + 1, MaxInt);
  lAt := Pos(tbtchar(#0), Result);
  if (lAt = 0) or (Length(Result) - lAt < 4) then
    Result := ''
  else
    Delete(Result, 1, lAt);
end;

function LoadDll(Caller: TPSExec; P: TPSExternalProcRec; var ErrorCode: LongInt): Boolean;
const
  ERROR_MOD_NOT_FOUND = 126;
var
  s, s2, s3: tbtstring;
  h, i: Longint;
  ph: PLoadedDll;
  dllhandle: THandle;
  loadwithalteredsearchpath: Boolean;
  {$IFNDEF UNIX}
  Filename: String;
  {$ENDIF}
begin
  s := p.Decl;
  Delete(s, 1, 4);
  s2 := copy(s, 1, pos(tbtchar(#0), s)-1);
  delete(s, 1, length(s2)+1);
  h := makehash(s2);
  s3 := copy(s, 1, pos(tbtchar(#0), s)-1);
  delete(s, 1, length(s3)+1);
  loadwithalteredsearchpath := bytebool(s[3]);
  i := 2147483647; // maxint
  dllhandle := 0;
  repeat
    ph := Caller.FindProcResource2(@dllFree, i);
    if (ph = nil) then
    begin
      if s2 = '' then
      begin
        // don't pass an empty filename to LoadLibrary, just treat it as uncallable
        p.Ext2 := Pointer(1);
        ErrorCode := ERROR_MOD_NOT_FOUND;
        Result := False;
        exit;
      end;

      {$IFDEF UNIX}
      {$DEFINE UNIX_OR_KYLIX}
      {$ENDIF}
      {$IFDEF KYLIX}
      {$DEFINE UNIX_OR_KYLIX}
      {$ENDIF}

      {$IFDEF UNIX_OR_KYLIX}
      dllhandle := LoadLibrary(PChar(s2));
      {$ELSE}
      {$IFDEF UNICODE}
      if Copy(s2, 1, 6) = '<utf8>' then
        Filename := {$IFDEF FPC}UTF8Decode{$ELSE}UTF8ToUnicodeString{$ENDIF}(Copy(s2, 7, Maxint))
      else
        Filename := String(s2);
      {$ELSE}
      if Copy(s2, 1, 6) = '<utf8>' then
        Filename := Utf8ToAnsi(Copy(s2, 7, Maxint))
      else
        Filename := s2;
      {$ENDIF}
      if loadwithalteredsearchpath then
        dllhandle := {$IFDEF FPC}LoadLibraryExW(PWideChar(UnicodeString(Filename)), 0, LOAD_WITH_ALTERED_SEARCH_PATH){$ELSE}LoadLibraryEx(PChar(Filename), 0, LOAD_WITH_ALTERED_SEARCH_PATH){$ENDIF}
      else
        dllhandle := {$IFDEF FPC}LoadLibraryW(PWideChar(UnicodeString(Filename))){$ELSE}LoadLibrary(PChar(Filename)){$ENDIF};
      {$ENDIF}
      if dllhandle = 0 then
      begin
        p.Ext2 := Pointer(1);
        ErrorCode := {$IFDEF MSWINDOWS}GetLastError{$ELSE}{$IFDEF FPC}GetLastOSError{$ELSE}ERROR_MOD_NOT_FOUND+1{$ENDIF}{$ENDIF};
        Result := False;
        exit;
      end;
      new(ph);
      ph^.dllnamehash := h;
      ph^.dllname := s2;
      ph^.dllhandle := dllhandle;
      Caller.AddResource(@DllFree, ph);
    end;
    if (ph^.dllnamehash = h) and (ph^.dllname = s2) then
    begin
      dllhandle := ph^.dllhandle;
    end;
  until dllhandle <> 0;
  p.Ext1 := GetProcAddress(dllhandle, pansichar(s3));
  if p.Ext1 = nil then
  begin
    p.Ext2 := Pointer(1);
    ErrorCode := {$IFDEF MSWINDOWS}GetLastError{$ELSE}{$IFDEF FPC}GetLastOSError{$ELSE}ERROR_MOD_NOT_FOUND+2{$ENDIF}{$ENDIF};
    Result := false;
    exit;
  end;
  Result := True;
end;


function DllProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;

var
  i: Longint;
  MyList: TIfList;
  n: PPSVariantIFC;
  CurrStack: Cardinal;
  cc: TPSCallingConvention;
  s: tbtstring;
  Dummy: LongInt;
begin
  if p.Ext2 <> nil then // error
  begin
    Result := false;
    exit;
  end;
  s := _DllDeclTail(p.Decl);
  if s = '' then
  begin
    Result := False;
    exit;
  end;
  if p.Ext1 = nil then
  begin
    if not LoadDll(Caller, P, Dummy) then
    begin
      DLLSetLastError(Caller, Dummy);
      Result := false;
      exit;
    end;
  end;
  cc := TPSCallingConvention(s[1]);
  delete(s, 1, 3); // cc + delayload + alternatesearchpath (delayload might also be forced!)
  CurrStack := Cardinal(Stack.Count) - Cardinal(length(s));
  if s[1] = #0 then inc(CurrStack);
  MyList := tIfList.Create;
  for i := 2 to length(s) do
  begin
    MyList.Add(nil);
  end;
  for i := length(s) downto 2 do
  begin
    MyList[i - 2] := NewPPSVariantIFC(Stack[CurrStack], s[i] <> #0);
    inc(CurrStack);
  end;
  if s[1] <> #0 then
  begin
    n := NewPPSVariantIFC(Stack[CurrStack], true);
  end else n := nil;
  try
    Result := TMYExec(Caller).InnerfuseCall(nil, p.Ext1, cc, MyList, n);
    {$IFNDEF UNIX}
    if Result then
      DLLSetLastError(Caller, GetLastError);
    {$ENDIF}
  finally
    DisposePPSvariantIFC(n);
    DisposePPSVariantIFCList(MyList);
  end;
end;

function ProcessDllImport(Caller: TPSExec; P: TPSExternalProcRec): Boolean;
begin
  Result := ProcessDllImportEx(Caller, P, False);
end;

function ProcessDllImportEx(Caller: TPSExec; P: TPSExternalProcRec; ForceDelayLoad: Boolean): Boolean;
var
  Dummy1: Boolean;
  Dummy2: LongInt;
begin
  Result := ProcessDllImportEx2(Caller, P, ForceDelayLoad, Dummy1, Dummy2);
end;

function ProcessDllImportEx2(Caller: TPSExec; P: TPSExternalProcRec; ForceDelayLoad: Boolean; var DelayLoad: Boolean; var ErrorCode: LongInt): Boolean;
const
  { ERROR_BAD_FORMAT }
  cErrorBadFormat = 11;
var
  s: tbtstring;
begin
  if not ForceDelayLoad then begin
    s := _DllDeclTail(p.Decl);
    if s = '' then
    begin
      p.Ext2 := Pointer(1);
      ErrorCode := cErrorBadFormat;
      Result := False;
      exit;
    end;
    DelayLoad := bytebool(s[2]);
  end else
    DelayLoad := True;

  if DelayLoad then begin
    p.ProcPtr := DllProc;
    Result := True;
  end else begin
    p.ProcPtr := DllProc;
    Result := LoadDll(Caller, p, ErrorCode);
  end;
end;


function GetLastErrorProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
begin
  Stack.SetInt(-1, DLLGetLastError(Caller));
  Result := true;
end;

{ the routines of the library aName -- of every library when aAll -- forget what
  they loaded, and that a load failed: the next call loads the library }
procedure _DllForget(Caller: TPSExec; const aName: tbtstring; aAll: Boolean);
var
  i: Longint;
  pv: TPSProcRec;
  s: tbtstring;
begin
  for i := Caller.GetProcCount -1 downto 0 do
  begin
    pv := Caller.GetProcNo(i);
    if not (pv is TPSExternalProcRec) then continue;
    if @TPSExternalProcRec(pv).ProcPtr <> @DllProc then continue;
    s := (TPSExternalProcRec(pv).Decl);
    delete(s,1,4);
    if aAll or (copy(s,1,pos(tbtchar(#0),s)-1) = aName) then
    begin
      TPSExternalProcRec(pv).Ext1 := nil;
      TPSExternalProcRec(pv).Ext2 := nil;
    end;
  end;
end;

procedure UnloadDLL(Caller: TPSExec; const sname: tbtstring);
var
  h, i: Longint;
  ph: PLoadedDll;
begin
  _DllForget(Caller, sname, False);
  h := MakeHash(sname);
  i := 2147483647; // maxint
  repeat
    ph := Caller.FindProcResource2(@dllFree, i);
    if (ph = nil) then break;
    if (ph.dllnamehash = h) and (ph.dllname = sname) then
    begin
      FreeLibrary(ph^.dllhandle);
      Caller.DeleteResource(ph);
      dispose(ph);
    end;
  until false;
end;

function UnloadProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
begin
  UnloadDLL(Caller, Stack.GetAnsiString(-1));
  result := true;
end;

function UnloadAll(Caller: TPSExec): Boolean;
var
  i: Longint;
  ph: PLoadedDll;
begin
  _DllForget(Caller, '', True);
  i := 2147483647; // maxint
  repeat
    ph := Caller.FindProcResource2(@dllFree, i);
    if (ph = nil) then break;
    FreeLibrary(ph^.dllhandle);
    Caller.DeleteResource(ph);
    dispose(ph);
  until false;
  result:=true;
end;

procedure RegisterDLLRuntime(Caller: TPSExec);
begin
  RegisterDLLRuntimeEx(Caller, True, True);
end;

procedure RegisterDLLRuntimeEx(Caller: TPSExec; AddDllProcImport, RegisterUnloadDLL: Boolean);
begin
  if AddDllProcImport then
    Caller.AddSpecialProcImport('dll', @ProcessDllImport, nil);
  if RegisterUnloadDLL then
    Caller.RegisterFunctionName('UnloadDll', UnloadProc, nil, nil);
  Caller.RegisterFunctionName('DllGetLastError', GetLastErrorProc, nil, nil);
end;

end.
