{
@abstract(Component wrapper for IFPS3 compiler and executer)
A component wrapper for IFPS3, including debugging support.

}
{$I PascalScript.inc}

unit uPSComponentExt;

interface

uses
  {$IFNDEF LINUX} Windows, {$ENDIF} SysUtils, Classes, uPSRuntime, uPSDebugger, uPSUtils, uPSComponent,
  contnrs, uPSCompiler, uPSC_dll, uPSR_dll, uPSPreProcessor, typInfo;

const
  {alias to @link(ifps3.cdRegister)}
  cdRegister = uPSRuntime.cdRegister;
  {alias to @link(ifps3.cdPascal)}
  cdPascal = uPSRuntime.cdPascal;
  { alias to ifps3.cdCdecl }
  CdCdecl = uPSRuntime.CdCdecl;
  {alias to @link(ifps3.cdStdcall)}
  CdStdCall = uPSRuntime.CdStdCall;

type
  {Alias to @link(ifps3.TPSCallingConvention)}
  TDelphiCallingConvention = uPSRuntime.TPSCallingConvention;
  {Alias to @link(ifps3.TPSRuntimeClassImporter)}
  TPSRuntimeClassImporter = uPSRuntime.TPSRuntimeClassImporter;

  TPSScriptExtension = class;

  {Base class for all plugins for the component}
  TPSOnCompCleanup = Function (Sender: TObject; aComp: TPSPascalCompiler):Boolean of object;
  TPSOnInsertProcedure = Procedure (Sender: TObject; aProc: tbtstring; OnTop: Boolean) of object;
  TPSOnException = procedure (Sender: TPSExec; ExError: TPSError; const ExParam: tbtstring;
                              ExObject: TObject; ProcNo, Position: Cardinal) of object;

  TMethodList = class;
  TProcObj = Class
    private
      FName     : tbtstring;
      fOwner   : TMethodList;
    procedure SetName(const Value: tbtstring);
  public
    ProcType : TStringList;
    Method : TMethod;
    constructor create(aOwner: TMethodList);
    { clears every bound event holding Method, and forgets Method }
    procedure Retire;
    destructor Destroy; override;
    property Name: tbtstring read FName write SetName;
  end;

  TMethodObj = Class
    Instance  : TPersistent;
    PropName  : tbtstring;
    ProcName  : tbtstring;
    { the method FillMethods left in the event -- after a write that raised,
      the one filled before unless the event then holds the new one; nil
      when none }
    Filled    : TMethod;
  end;

  TMethodList = class
  private
    fOwner     : TPSScriptExtension;
    { the component whose own free notification is being handled: not written to }
    fGoing     : TObject;
    fProcList  : TObjectList;
    fEventList : TObjectList;
    { the loaded code's routines that bindings name and no compilation of the
      text lists, while the code SetCompiled loaded stands in for the script }
    fCodeProcs : TObjectList;
    function  GetObject(Index: Integer): TMethodObj; virtual;
    function  GetProcObj(Index: Integer): TProcObj;
    function  GetMethodName(Instance: TObject; PropName: tbtstring): tbtstring;
    procedure SetMethodName(Instance: TObject; PropName: tbtstring; const Value: tbtstring);
    procedure CreateProc(ProcName: tbtstring; aPropType: PTypeData);
    procedure RetireMethods;
    procedure DeleteMethod(Index: Integer);
    procedure ClearEventHolding(aBinding: TMethodObj; aMethod: TMethod);
    procedure ComponentGoes(aComponent: TComponent);
    function CodeProc(const aName: tbtstring): TProcObj;
  public
    constructor create(aOwner: TPSScriptExtension);
    destructor Destroy; override;
    function methodIndexOf(Instance: TObject; PropName: tbtstring):Integer;
    Function ProcIndexOf(Name: tbtstring): Integer;
    Procedure ListEventsName(EventType:tbtstring; List : TStrings);

    Procedure AddProcedure(ProcName, ProcType:tbtstring);
    procedure InsertMethod(NewProc: tbtstring; OnTop: Boolean = false);

    Procedure FillMethods;
    procedure ClearProcList;
    Procedure ClearAll;
    function ProcCount :Integer;
    Function MethodCount :Integer;
    property Procs[Index: Integer]: TProcObj read GetProcObj ;
    property Methods[Index: Integer]: TMethodObj read GetObject;
    property ProcName[Instance: TObject; PropName:tbtstring]: tbtstring read GetMethodName write SetMethodName;
  end;

  TPSScriptExtension = class(TPSScriptDebugger)
  private
    FOnBeforeCleanUp: TPSOnCompCleanup;
    FMethodList : TMethodList;
    FWatcher    : TComponent;
    FOnInsertMethod: TPSOnInsertProcedure;
    FNeedCompiling :Boolean;
    { the code SetCompiled loaded stands in for the script until its text
      changes or a Compile: Execute and CompileIfNeeded do not compile the
      text over it }
    FCompiledSet   :Boolean;
    FOnScriptChance: TNotifyEvent;
    FOnException: TPSOnException;

    fItems, fInserts: TStrings;
    fScriptPos : Cardinal;
    fObjectNest: tbtstring;

    Procedure GetCodeProps ;
    function GetProcName(Instance: TObject; PropName: tbtstring): tbtstring;
    procedure SetProcName(Instance: TObject; PropName: tbtstring; const Value: tbtstring);

  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    procedure DoVerifyProc(Sender: TPSScript; Proc: TPSInternalProcedure;
                           const Decl: tbtstring; var Error: Boolean); reintroduce;
    Function  DoBeforeCleanup(Sender: TObject; aComp: TPSPascalCompiler):Boolean;
    procedure DoScriptChance(sender:TObject);


  public
    {Create an instance of the CompExec component}
    constructor Create(AOwner: TComponent); override;
    {Destroy the CompExec component}
    destructor Destroy; override;

    function Compile: Boolean; Override;
    function Execute: Boolean; Override;
    { Create a list of all var's, const's, Type's and functions }
    Procedure GetValueDefs(aItems, aInserts: TStrings; Const aObjectNest: tbtstring=''; aScriptPos: Integer = 0);

    {Compile the source only when the source is modified}
    procedure CompileIfNeeded;
    {Whether the source is to be compiled: it changed, its last compilation
     failed, or a SetCompiled dropped it}
    Property NeedCompiling : Boolean read FNeedCompiling;

    {Fills all function in the script to there connected Events.
     This is called automatic after a succesfull Compilition}
    Procedure FillMethods;

    {Removes all events from the Objects Fills all function in the script to there connected Events.
     This function is automatic called before a Compilition}
    procedure ClearProcList;
    Procedure RemoveObjEvents(Obj: TObject);

    {This property helps you set the events that must becalled from within the script
     Instance is the object where the Propname must be set.
     You need te create the function yopur self in the script.
     When the new Procname dose not exists in the script, it is automatic created for you.}
    property ProcName[Instance: TObject; PropName:tbtstring]: tbtstring read GetProcName write SetProcName;
    property MethodList : TMethodList read FMethodList;
    { loads the compiled script: the bound events are emptied before the code
      they were filled from goes, and filled from the new; with nothing
      compiled, the code loaded stays and fills them }
    function LoadExec: Boolean; override;
    { loads compiled code: the bound events are emptied before the code they
      were filled from goes, and filled from the code loaded, which Execute
      runs until the script's text changes or a Compile }
    procedure SetCompiled(const Data: tbtstring); override;

  published

    property OnBeforeCleanUp: TPSOnCompCleanup read FOnBeforeCleanUp write FOnBeforeCleanUp; //<NVDS>
    property OnInsertMethod : TPSOnInsertProcedure read FOnInsertMethod write FOnInsertMethod;
    Property OnScriptChance : TNotifyEvent read FOnScriptChance write fOnScriptChance;
    property OnException    : TPSOnException read FOnException write FOnException;
  end;


implementation

resourcestring
  sMissingEndStatment = 'Missing some ''End'' statments';
  sScriptRunning = 'Script engine already running';
  sNotBindable = 'No event type the script declares takes the routine %s';
  sUntypedParameter = 'An event with an untyped parameter cannot be given a script routine';
  sNotInsertable = 'Putting the routine %s in leaves the script not compiling: %s';

type
  { told when a component the extension binds is freed: it has no owner, so
    TComponent registers it with each such component whoever owns either }
  TPSExtensionWatcher = class(TComponent)
  private
    fExtension : TPSScriptExtension;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  end;


function CompExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: tbtstring): Boolean;
begin
  TPSScriptExtension(Sender.ID).DoVerifyProc(Sender.Id, Proc, ProcDecl, Result);
  Result := not Result;
end;

Function BeforeCleanup(Sender: TPSPascalCompiler):Boolean;
begin
  result := TPSScriptExtension(Sender.ID).DoBeforeCleanUp(Sender.ID,Sender);
end;

procedure CEException(Sender: TPSExec; ExError: TIFError; const ExParam: tbtstring; ExObject: TObject; ProcNo, Position: Cardinal);
begin
  if @TPSScriptExtension(Sender.ID).FOnException <> nil then
    TPSScriptExtension(Sender.ID).FOnException(Sender, ExError, ExParam, ExObject, ProcNo, Position);
end;

{ TPSExtensionWatcher }

procedure TPSExtensionWatcher.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  If (Operation = opRemove) and (AComponent <> nil) and (fExtension <> nil) and
     (fExtension.MethodList <> nil) then
    fExtension.MethodList.ComponentGoes(AComponent);
end;

{ TPSScriptExtension }

function TPSScriptExtension.Compile: Boolean;
begin
  { a compilation replaces the loaded script: never under a run of it }
  if Running then
    raise Exception.Create(sScriptRunning);
  { needed until this compilation succeeds, also where it raises; it ends
    the code SetCompiled loaded }
  FNeedCompiling := True;
  FCompiledSet := False;
  ClearProcList;
  { the load fills the events -- where the compilation loads nothing, the
    one Execute makes }
  result := inherited Compile;
  FNeedCompiling := not result;
end;

function TPSScriptExtension.LoadExec: Boolean;
var
  lData : tbtstring;
begin
  { a compiled script is loaded only while none of it runs }
  if Running then
    raise Exception.Create(sScriptRunning);
  { nothing compiled: nothing is loaded, and the events are filled from the
    code loaded }
  if not Comp.GetOutput(lData) then begin
    MethodList.FillMethods;
    Result := False;
    Exit;
  end;
  { the load frees the code the events were filled from before anything
    else, also where it then fails or raises }
  MethodList.RetireMethods;
  Result := inherited LoadExec;
  if Result then
    MethodList.FillMethods;
end;

procedure TPSScriptExtension.SetCompiled(const Data: tbtstring);
begin
  { compiled code is loaded only while none of the script runs }
  if Running then
    raise Exception.Create(sScriptRunning);
  { the load frees the code the events were filled from first }
  MethodList.RetireMethods;
  { the code loaded before goes, also where this load fails, and the
    load drops what the text's compilation left: the text is compiled
    again once the code loaded here ends }
  FCompiledSet := False;
  FNeedCompiling := True;
  inherited SetCompiled(Data);
  FCompiledSet := True;
  MethodList.FillMethods;
end;

constructor TPSScriptExtension.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Comp.OnBeforeCleanup := BeforeCleanup;
  Comp.OnExportCheck   := CompExportCheck;
  Exec.OnException     := CEException;

  TStringList(script).OnChange := DoScriptChance;
  FMethodList := TMethodList.create(Self);
  FWatcher := TPSExtensionWatcher.Create(nil);
  TPSExtensionWatcher(FWatcher).fExtension := Self;
  FNeedCompiling := True;
end;

destructor TPSScriptExtension.Destroy;
begin
  FMethodList.Free;
  FMethodList := nil;
  FWatcher.Free;
  FWatcher := nil;
  inherited Destroy;
end;

procedure TPSScriptExtension.DoVerifyProc(Sender: TPSScript;
  Proc: TPSInternalProcedure; const Decl: tbtstring; var Error: Boolean);
var
  n{,m,p} : Integer;
  tstType : TPSProceduralType;
begin
  Error := False;
  if assigned(OnVerifyProc) then
  begin
    onVerifyProc(Sender, Proc, Decl, Error);
  end;
  { a routine the host refuses, and the compiler's own (a main block, named
    !...), are taken by no event }
  If Error or (Copy(Proc.Name, 1, 1) = '!') then
    Exit;
  for n := 0 to sender.comp.GetTypeCount -1 do begin
    If comp.GetType(n) is TPSProceduralType then begin
      tstType := comp.GetType(n) as TPSProceduralType;
      If tstType.ProcDef.Same(Proc.Decl) then begin
        MethodList.addprocedure(Proc.OriginalName, tstType.Name);
//        Proc. aExport := etExportDecl;
      end;
    end;
  end;
end;

type
  TMyPascalCompiler = class(TPSPascalCompiler);
const
  sIFPSParameterMode : array [pmIn..pmInOut] of tbtstring = ('','\style{+B}out\style{-B} ','\style{+B}Var\style{-B} ');

Procedure TPSScriptExtension.GetCodeProps;
var
  lInserts : TStringList;

  Function existsItem(aName:tbtstring):Boolean;
  Begin
    result := lInserts.indexof(aName)<> -1;
  end;

  Procedure addListItem(aType, aName:tbtstring; aDef:tbtstring='');
  var
    x : LongInt;
  begin
    If not ((aName ='') or (aName[1]='!')) then begin
      x := lInserts.Add(aName);
      fItems.Insert(x, format('%s \column{}\style{+B}%s\style{-B} %s',[aType, aName, aDef]));
    end;
  end;

  procedure Getdecl(decl : TPSParametersDecl; var T,v :tbtstring);
  var
    m : Integer;
  begin
    v := '';
    for m := 0 to Decl.ParamCount-1 do begin
      v := V +';'+sIFPSParameterMode[Decl.Params[m].Mode]+
              Decl.Params[m].OrgName;
      if Decl.Params[m].aType <> nil then
        v := v +':'+ Decl.Params[m].aType.OriginalName;
    end;
    delete(v,1,1);
    If v <> '' then v := '('+ v +')';
    if Decl.Result<>nil then begin
      v := v +':'+ Decl.Result.OriginalName;
      t := 'Function';
    end else t := 'Procedure';

  end;

  Function getTypeDef(xr: TPSType; aZoek:tbtstring = ''):Boolean; forward;

  Function getClassDef(xc: TPSCompileTimeClass; aZoek:tbtstring = ''):Boolean;
  var
    Show : Boolean;
    Zoek,bZoek : tbtstring;
    tci : TPSDelphiClassItem;
    n : Integer;
    T,v : tbtstring;

  begin
    Show := aZoek='';
    Zoek := aZoek;
    If Pos('.',aZoek)>0 then begin
      Zoek  := copy(aZoek, 1 ,Pos('.',aZoek)-1);
      bZoek := copy(aZoek, Pos('.',aZoek)+1, 999);
    end else bZoek := '';

    result := (xc <> nil) and Show;
    if XC<> nil then begin
      For n := 0 to xc.Count-1 do begin
        tci := xc.Items[n];
        If (tci = nil) or  existsItem(tci.OrgName) then continue;
        if tci is TPSDelphiClassItemConstructor then begin
          Getdecl(tci.decl, T, V);
          If Show then addListItem('constructor',tci.OrgName, v);
        end else
        if tci is TPSDelphiClassItemMethod then begin
          If Show then begin
            Getdecl(tci.decl, T, V);
            addListItem(T,tci.OrgName, v)
          end else
          If (tci.decl.Result <> nil) and (tci.Name = Zoek) then
            result := getTypeDef(tci.decl.Result, bZoek);
        end else
        if tci is TPSDelphiClassItemProperty then begin
          If Show then begin
            t := '';
            If tci.Decl.Result<> nil then t := ': '+ tci.Decl.Result.OriginalName;
            addListItem('Property',tci.OrgName, t);
          end else
          If (tci.decl.Result <> nil) and (tci.Name = Zoek) then
            result := getTypeDef(tci.decl.Result, bZoek);
        end;
        If result and not show then exit;
      end;
      result := getClassDef(XC.ClassInheritsFrom, aZoek) or result;
    end;
  end;

  Function getTypeDef(xr: TPSType; aZoek:tbtstring = ''):Boolean;
  var
    Show : Boolean;
    Zoek : tbtstring;
    xri : PIFPSRecordFieldTypeDef;
    n : Integer;
  begin
    Show := aZoek='';
    result := (xr <> nil) and Show;
    if xr <> nil then begin
      If xr is TPSRecordType then begin
        Zoek := aZoek;
        If Pos('.',aZoek)>0 then begin
          Zoek  := copy(aZoek, 1 ,Pos('.',aZoek)-1);
          aZoek := copy(aZoek, Pos('.',aZoek)+1, 999);
        end else aZoek := '';
        for n := 0 to (xr as TPSRecordType).RecValCount-1 do begin
          xri := (xr as TPSRecordType).RecVal(n);
          If Show then begin
            addListItem('var',xri.FieldOrgName,xri.aType.OriginalName)
          end else
          If (xri.aType <> nil) and (xri.FieldName = Zoek) then
            result := getTypeDef(xri.aType, aZoek);
        end;
      end else
      If (xr is TPSClassType) then begin
        result := getClassDef((xr as TPSClassType).Cl, aZoek)
      end else
        result := False;
    end;
  end;

  Function FindVarProc(aVarName:tbtstring; aZoek : tbtstring= ''):Boolean;
  var
//    cv   : tbtstring;
    hh, h, i : Longint;
    proc : TPSProcedure;
    ip   : TPSInternalProcedure;
    ipv  : PIFPSProcVar;
    ipp  : TPSParameterDecl;
//    t    : tbtstring;
  begin
    Hh := MakeHash(aVarName);
    result := False;
    If FScriptPos =0 then exit;
    for i := Comp.GetProcCount -1 downto 0 do begin
      Proc := Comp.GetProc(i);
      If (Proc.ClassType = TPSInternalProcedure) and
         ((Proc as TPSInternalProcedure).DeclarePos < FScriptPos) then begin
        ip := Proc as TPSInternalProcedure;
        for h := 0 to ip.ProcVars.Count-1 do begin
          ipv := PIFPSProcVar(ip.ProcVars[h]);
          If aVarName = '' then begin
            addListItem('var',ipv.OrgName, ': '+ipv.AType.OriginalName);
          end else
          If (ipv.NameHash = HH) and (ipv.Name = aVarName) then begin
            result := getTypeDef(ipv.aType, aZoek);
            exit;
          end;
        end;
        for h := 0 to ip.Decl.ParamCount-1 do begin
          ipp := TPSParameterDecl(ip.Decl.Params[h]);
          If aVarName = '' then begin
            addListItem('var',ipp.OrgName, ': '+ipp.aType.OriginalName);
          end else
          If {(ipp.Hash = HH) and} (ipp.Name = aVarName) then begin
            result := getTypeDef(ipp.aType, aZoek);
            exit;
          end;
        end;
      end;
    end;
  end;

  Function FindVarFunctType(aProcName:tbtstring): Boolean;
  var
    cv : tbtstring;
    h, i : Longint;
    proc : TPSProcedure;
    xr : TPSRegProc;
//    t  : tbtstring;
  begin
    cv := aProcName;
    If Pos('.',aProcName)>0 then begin
      cv := copy(aProcName, 1 ,Pos('.',aProcName)-1);
      aProcName := copy(aProcName, Pos('.',aProcName)+1, 999);
    end else aProcName := '';
    H := MakeHash(Cv);
//    Result := False;
    for i :=0 to Comp.GetVarCount -1 do begin
      if (Comp.GetVar(I).NameHash = H) and (Comp.GetVar(I).Name = CV) then begin
        Result := getTypeDef(Comp.GetVar(I).aType, aProcName);
        Exit;
      end;
    end;
   for i :=0 to Comp.GetTypeCount -1 do begin
    if (Comp.GetType(I).NameHash = H) and (Comp.GetType(I).Name = CV) then begin
      Result := getTypeDef(Comp.GetType(I), aProcName);
      Exit;
    end;
   end;
    result := FindVarProc(cv, aProcName);
    If result then exit;
    for i :=0 to Comp.GetProcCount -1 do begin
      Proc := Comp.GetProc(i);
      If Proc.ClassType = TPSInternalProcedure then begin
        if ((Proc as TPSInternalProcedure).NameHash = H) and
            ((Proc as TPSInternalProcedure).Name = CV) then begin
          Result := getTypeDef((Proc as TPSInternalProcedure).Decl.Result, aProcName);
          exit;
        end;
      end;
    end;
    with TMyPascalCompiler(Comp) do begin
      for i := 0 to FRegProcs.Count-1 do begin
        xr := FRegProcs[i];
        if (xr.NameHash = H) and  (xr.Name = CV) then begin
          result := getTypeDef(xr.Decl.Result, aProcName);
          exit;
        end;
      end;
    end;
  end;

  procedure AddEveryName;
  Var
    n : Integer;
    s, t, v : tbtstring;
    proc : TPSProcedure;
    xr : TPSRegProc;
  begin
    for n := 0 to Comp.GetTypeCount-1 do begin
      addListItem('Type',Comp.GetType(n).OriginalName);
    end;
    for n := 0 to Comp.GetVarCount-1 do begin
      addListItem('var',Comp.GetVar(n).OrgName, ': '+Comp.Getvar(n).aType.OriginalName);
    end;
    with TMyPascalCompiler(Comp) do begin
      for n := 0 to FConstants.Count-1 do begin
        addListItem('const', TPSConstant(FConstants[n]).OrgName );
      end;
      for n := 0 to FRegProcs.Count-1 do begin
        xr := FRegProcs[n];
        Getdecl(xr.decl, T, v);
        addListItem(t,xr.OrgName, v );
      end;
    end;
    FindVarProc('');
    for n := 0 to Comp.GetProcCount-1 do begin
      s := '';
      proc := Comp.GetProc(n);
      { the compiler's own routines (a main block, named !...) are no name of
        the script }
      If (Proc.ClassType = TPSInternalProcedure) and
         (Copy((Proc as TPSInternalProcedure).Name, 1, 1) <> '!') then begin
        s := (Proc as TPSInternalProcedure).OriginalName;
        Getdecl((Proc as TPSInternalProcedure).decl, T, v);
      end;
      If s <> '' then begin
        addListItem(t,s, v );
      end;
    end;
  end;

begin
  If (fItems = nil) or (fInserts = Nil) then exit;
  lInserts := TStringList.Create;
  try
    lInserts.Sorted := true;
    lInserts.Duplicates := dupAccept;
    fItems.BeginUpdate;
    try
      fInserts.BeginUpdate;
      try
        fInserts.Clear;
        fItems.Clear;
        If (FObjectNest <> '') then
          FindVarFunctType(FastUpperCase(FObjectNest))
        else
          AddEveryName;
        fInserts.AddStrings(lInserts);
      finally
        fInserts.EndUpdate;
      end;
    finally
      fItems.EndUpdate;
    end;
  finally
    lInserts.Free;
  end;
end;

procedure TPSScriptExtension.GetValueDefs(aItems, aInserts: TStrings; const aObjectNest: tbtstring; aScriptPos: Integer);
begin
  fItems      := aItems;
  fInserts    := aInserts;
  FScriptPos  := aScriptPos;
  fObjectNest := aObjectNest;
  Try
    compile;
  finally
    fItems      := Nil;
    fInserts    := Nil;
    FScriptPos  := 0;
    fObjectNest := '';
  end;
end;

function TPSScriptExtension.DoBeforeCleanup(Sender: TObject;
  aComp: TPSPascalCompiler): Boolean;
begin
  result := true;
  If fItems <> nil then GetCodeProps;
  If @FOnBeforeCleanUp<> nil then
    result := FOnBeforeCleanUp(Sender, aComp);
end;

function TPSScriptExtension.Execute: Boolean;
var
  lCompiles : Boolean;
begin
  { never under a run of the script: its events are not written either }
  if Running then
    raise Exception.Create(sScriptRunning);
  { a compilation's load fills them, and with SuppressLoadData the load
    Execute makes }
  lCompiles := FNeedCompiling and not FCompiledSet;
  CompileIfNeeded;
  if not (lCompiles or SuppressLoadData) then
    MethodList.FillMethods;
  result := inherited Execute;
end;


procedure TPSScriptExtension.DoScriptChance(sender: TObject);
begin
  FNeedCompiling := True;
  FCompiledSet := False;
  self.ClearProcList;
  If @FOnScriptChance <> NIL then
    FOnScriptChance(sender);
end;

procedure TPSScriptExtension.CompileIfNeeded;
begin
  { not over the code SetCompiled loaded, which stands until the text
    changes }
  if FNeedCompiling and not FCompiledSet then begin
    Compile;
  end;
end;

procedure TPSScriptExtension.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  { a component its owner removes -- also on the way to freeing it, before its
    destructor runs -- loses its bindings, its events cleared; its own free
    reaches the watcher first }
  If (Operation = opRemove) and (aComponent <> nil) and (MethodList <> nil) then
    MethodList.SetMethodName(aComponent,'','');
end;

function TPSScriptExtension.GetProcName(Instance: TObject; PropName: tbtstring): tbtstring;
begin
  Result := MethodList.ProcName[Instance, Propname];
end;

procedure TPSScriptExtension.SetProcName(Instance: TObject; PropName: tbtstring; const Value: tbtstring);
begin
  MethodList.ProcName[Instance, Propname] := Value;
end;

procedure TPSScriptExtension.ClearProcList;
begin
  MethodList.ClearProcList;
end;

procedure TPSScriptExtension.RemoveObjEvents(Obj: TObject);
begin
  MethodList.SetMethodName(Obj, '', '');
end;

procedure TPSScriptExtension.FillMethods;
begin
  MethodList.FillMethods;
end;

{ TMethodList }

procedure TMethodList.AddProcedure(ProcName, ProcType: tbtstring);
var
  po : TProcObj;
  x,y  : Integer;

begin
  ProcType := Uppercase(ProcType);
  x := ProcIndexOf(ProcName);
  if x <> -1 then begin
    y := Procs[x].ProcType.IndexOf(ProcType);
    If y = -1 then TProcObj(fProcList.Items[x]).ProcType.add(ProcType);
  end else begin
    po := TProcObj.create(self);
    po.Name := ProcName;
    po.ProcType.add(ProcType);
    fProcList.add(po);
  end
end;

procedure TMethodList.ClearProcList;
begin
  fProcList.Clear;
  fCodeProcs.Clear;
end;

constructor TMethodList.create(aOwner: TPSScriptExtension);
begin
  inherited create;
  fOwner     := aOwner;
  fProcList  := TObjectList.create(true);
  fEventList := TObjectList.create(true);
  fCodeProcs := TObjectList.create(true);
end;

procedure TMethodList.CreateProc(ProcName:tbtstring; aPropType: PTypeData);
var
  newProc: tbtstring;
  P: PByte;
  i: Integer;
  pf : TParamFlags;

  {$IFDEF FPC}
  // mh: TParamFlags(P^) doesn't compile in FPC, this function will "fix" it.
  // yes it's ugly, but I don't know an other way to fix it
  function GetParamFlags(P: Byte): TParamFlags;
  begin
	result := [];
	if (Ord(pfVar) and P <> 0) then Include(result, pfVar);
	if (Ord(pfConst) and P <> 0) then Include(result, pfConst);
	if (Ord(pfArray) and P <> 0) then Include(result, pfArray);
	if (Ord(pfAddress) and P <> 0) then Include(result, pfAddress);
	if (Ord(pfReference) and P <> 0) then Include(result, pfReference);
	if (Ord(pfOut) and P <> 0) then Include(result, pfOut);
  end;
  {$ENDIF}

begin
  WITH aPropType^ do begin
    if MethodKind=mkProcedure then NewProc:='procedure '
                              else NewProc:='function ';
    NewProc:=NewProc + ProcName+'(';
    P:=PByte(@ParamList);
    for i:=0 to ParamCount - 1 do
    begin
      {$IFDEF FPC}
      pf:=GetParamFlags(P^);
      {$ELSE}
      pf:=TParamFlags(P^);
      {$ENDIF}
      if pfVar in pf then NewProc:=NewProc+'var ';
      if pfConst in pf then NewProc:=NewProc+'const ';
      if pfOut in pf then NewProc:=NewProc+'out ';
      Inc(P);
      NewProc:=NewProc +PShortString(P)^ +' : ';
      Inc(P,P^ + 1);
      If PShortString(P)^ = '' then
        Raise exception.create(sUntypedParameter);
      if pfArray in pf then NewProc:=NewProc+'array of ';
      NewProc := NewProc + PShortString(P)^;
      Inc(P,P^ + 1);
      If i < ParamCount - 1 then NewProc := NewProc + '; ';
    end;
    NewProc := NewProc +')' ;
    if (MethodKind=mkFunction) then
      NewProc := NewProc +':'+ PShortString(P)^;
    NewProc:=NewProc+';'^m^j
                    +'Begin'^m^j^m^j
                    +'End;'^m^j;
    If @fowner.FOnInsertMethod <> nil then begin
      fowner.FOnInsertMethod(fOwner, NewProc, false);
    end else begin
      InsertMethod(NewProc);
    end;
    fowner.CompileIfNeeded;
  end;
end;

{ Puts NewProc into the script before its main begin -- in a unit, before its
  initialization, finalization or last end; at the end of a script that has
  none of them -- or at the top with OnTop, which reads nothing of the script.
  Otherwise nothing is put in where the script has a routine of NewProc's name
  with a body, or declares one external.  The script is read in tokens as it
  is written, the preprocessor's conditions not applied: a comment or a string
  is no code, and a record or an interface type closes with its own end,
  wherever it is declared }
procedure TMethodList.InsertMethod(NewProc: tbtstring; OnTop: Boolean = false);
var
  x        : Integer;
  lParser  : TPSPascalParser;
  lText    : tbtstring;
  lNew     : tbtstring;
  lHeader  : tbtstring;
  lBlocks  : tbtstring;
  lLast    : TPSPasToken;
  lCount   : Integer;
  lWord    : string;
  lLine    : string;

  { skips a routine's header from the parser's identifier on: its tokens up
    to the ; that ends it, where the parser is left }
  procedure _SkipHeader;
  var
    lRound : Integer;
    lTypes : Integer;
  begin
    lRound := 0;
    lTypes := 0;
    while lParser.CurrTokenId <> CSTI_EOF do begin
      case lParser.CurrTokenId of
        CSTI_OpenRound:
          Inc(lRound);
        CSTI_CloseRound:
          Dec(lRound);
        { a type declared in place -- a parameter's, the result's -- closes
          with its own end }
        CSTII_record, CSTII_Interface:
          Inc(lTypes);
        CSTII_end:
          Dec(lTypes);
        CSTI_SemiColon:
          If (lRound = 0) and (lTypes = 0) then
            Exit;
      end;
      lParser.Next;
    end;
  end;

begin
  x := 0;
  lCount := 0;
  lWord := '';
  lParser := TPSPascalParser.Create;
  try
    If Not Ontop Then begin
      lNew := '';
      lParser.SetText(NewProc);
      while not (lParser.CurrTokenId in [CSTI_EOF, CSTII_procedure, CSTII_function]) do
        lParser.Next;
      If lParser.CurrTokenId <> CSTI_EOF then begin
        lParser.Next;
        If lParser.CurrTokenId = CSTI_Identifier then
          lNew := lParser.GetToken;
      end;
      lText := tbtstring(fOwner.script.Text);
      lParser.SetText(lText);
      lHeader := '';
      lBlocks := '';
      lLast := CSTI_EOF;
      while lParser.CurrTokenId <> CSTI_EOF do begin
        case lParser.CurrTokenId of
          CSTII_procedure, CSTII_function:
            { a header names its routine; a procedural type -- a local
              variable of one too -- leaves the header open as it is }
            If lBlocks = '' then begin
              lParser.Next;
              If lParser.CurrTokenId = CSTI_Identifier then begin
                lHeader := lParser.GetToken;
                _SkipHeader;
              end;
            end;
          CSTII_Forward:
            If lBlocks = '' then
              lHeader := '';
          CSTII_External:
            If lBlocks = '' then begin
              If (lNew <> '') and (lHeader = lNew) then
                Exit;
              lHeader := '';
            end;
          CSTII_begin:
            If lBlocks <> '' then
              lBlocks := lBlocks + 'b'
            else if lHeader <> '' then begin
              If (lNew <> '') and (lHeader = lNew) then
                Exit;
              lHeader := '';
              lBlocks := 'b';
            end else begin
              lWord := 'begin';
              Break;
            end;
          CSTII_try:
            lBlocks := lBlocks + 'b';
          CSTII_case:
            { a record's variant part closes with the record }
            If Copy(lBlocks, Length(lBlocks), 1) <> 'r' then
              lBlocks := lBlocks + 'b';
          CSTII_record:
            lBlocks := lBlocks + 'r';
          CSTII_Interface:
            { a type's interface -- after =, : or of -- closes with its own end,
              a unit's section does not }
            If lLast in [CSTI_Equal, CSTI_Colon, CSTII_of] then
              lBlocks := lBlocks + 'b';
          CSTII_end:
            If lBlocks <> '' then
              Delete(lBlocks, Length(lBlocks), 1)
            else begin
              lWord := 'end';
              Break;
            end;
          CSTII_initialization, CSTII_finalization:
            If lBlocks = '' then begin
              If lParser.CurrTokenId = CSTII_initialization then
                lWord := 'initialization'
              else
                lWord := 'finalization';
              Break;
            end;
        end;
        lLast := lParser.CurrTokenId;
        lParser.Next;
      end;
      If lWord = '' then begin
        { the end of the script: an unterminated comment or string stops the
          parser before it }
        If (lBlocks <> '') or (lParser.CurrTokenPos < Cardinal(Length(lText))) then
          Raise exception.create(sMissingEndStatment);
        x := FOwner.script.Count;
      end else begin
        x := Integer(lParser.Row) - 1;
        { code or a comment's close before it on its line: the characters the
          line holds there }
        lLine := string(Copy(lText, lParser.CurrTokenPos - lParser.Col + 2, lParser.Col - 1));
        If Trim(lLine) <> '' then
          lCount := Length(lLine);
      end;
    end;
  finally
    lParser.Free;
  end;
  FOwner.script.BeginUpdate;
  Try
    If (lCount > 0) and (x < FOwner.script.Count) then begin
      lLine := FOwner.script[x];
      If SameText(Copy(lLine, lCount + 1, Length(lWord)), lWord) then begin
        FOwner.script[x] := Copy(lLine, 1, lCount);
        FOwner.script.Insert(x + 1, Copy(lLine, lCount + 1, MaxInt));
        inc(x);
      end;
    end;
    If (Not Ontop) and (x>0) and (Trim(FOwner.script[x-1])<>'') then begin
      FOwner.script.Insert(x,'');
      inc(x);
    end;
    FOwner.script.Insert(x,NewProc);
    FOwner.script.text := FOwner.script.text;
  finally
    FOwner.script.EndUpdate;
  end;
end;
 
destructor TMethodList.Destroy;
begin
  fProcList.Free;  {<< Needs Eventlist for removing Methods}
  fCodeProcs.Free;
  fEventList.Free;
  inherited;
end;

{ Writes each bound event, the bindings taken as they stand when it starts:
  a setter can change the list, and a binding it removes is skipped.  A write
  that raises leaves its binding recording the method filled before, unless
  the event then holds the new one.  A binding takes the routine the text's
  compilation lists; where none does, while the code SetCompiled loaded stands
  in for the script, that code's routine of the name }
procedure TMethodList.FillMethods;
var
  x, y      : Integer;
  m         : TMethod;
  lBindings : TList;
  lBinding  : TMethodObj;
  lInstance : TObject;
  lName     : tbtstring;
  lPrior    : TMethod;
  lPropInfo : PPropInfo;
  lHeld     : TMethod;
  lProc     : TProcObj;
begin
  lBindings := TList.Create;
  try
    for x := 0 to fEventList.Count-1 do
      lBindings.Add(fEventList.Items[x]);
    for x := 0 to lBindings.Count-1 do begin
      lBinding := TMethodObj(lBindings[x]);
      If fEventList.IndexOf(lBinding) < 0 then
        Continue;
      Y := ProcIndexOf(lBinding.ProcName);
      If Y >= 0 then
        lProc := Procs[Y]
      else if fOwner.FCompiledSet then
        lProc := CodeProc(lBinding.ProcName)
      else
        lProc := nil;
      If (lProc <> nil) and assigned(lBinding.Instance) then begin
        m := lProc.Method;
        if m.Data = nil then begin
          m := fOwner.Exec.GetProcAsMethodN(lProc.Name);
          lProc.Method := m;
        end;
        lInstance := lBinding.Instance;
        lName := lBinding.PropName;
        lPrior := lBinding.Filled;
        lBinding.Filled := m;
        try
          SetMethodProp(lInstance, lName, m );
        except
          If fEventList.IndexOf(lBinding) >= 0 then begin
            lPropInfo := GetPropInfo(lInstance, string(lName), [tkMethod]);
            If lPropInfo <> nil then begin
              lHeld := GetMethodProp(lInstance, lPropInfo);
              If ((lHeld.Code <> m.Code) or (lHeld.Data <> m.Data)) and
                 (fEventList.IndexOf(lBinding) >= 0) then
                lBinding.Filled := lPrior;
            end;
          end;
          raise;
        end;
      end;
    end;
  finally
    lBindings.Free;
  end;
end;

function TMethodList.GetMethodName(Instance: TObject; PropName: tbtstring): tbtstring;
var
  x : Integer;
begin
  fOwner.CompileIfNeeded;
  x := methodIndexOf(Instance,PropName);
  If x>=0 then result := Methods[x].ProcName
          else result := '';
end;

function TMethodList.GetObject(Index: Integer): TMethodObj;
begin
  result := TMethodObj(fEventList.items[Index]);
end;

function TMethodList.GetProcObj(Index: Integer): TProcObj;
begin
  result := TProcObj(fProcList.items[Index]);
end;

procedure TMethodList.ListEventsName(EventType: tbtstring; List: TStrings);
var
  x : Integer;
begin
  If List = nil then exit;
  EventType := Uppercase(EventType);
  List.Clear;
  fOwner.CompileIfNeeded;
  for x := 0 to fProcList.count-1 do begin
    If Procs[x].ProcType.indexof(EventType)<> -1 then
      List.add(Procs[x].name);
  end;
end;

function TMethodList.MethodCount: Integer;
begin
  result := fEventList.count;
end;

function TMethodList.methodIndexOf(Instance: TObject;
  PropName: tbtstring): Integer;
var x : integer;
begin
  Result := -1;
  { a property's name in any letter case, as RTTI finds it }
  PropName := Uppercase(PropName);
  for x := 0 to fEventList.count-1 do begin
    if (TMethodObj(fEventList.Items[x]).Instance = Instance) and
       ((propName='') or (Uppercase(TMethodObj(fEventList.Items[x]).PropName) = PropName)) then begin
      Result := x;
      exit;
    end;
  end;
end;

function TMethodList.ProcCount: Integer;
begin
  result := fProcList.count;
end;

function TMethodList.ProcIndexOf(Name: tbtstring): Integer;
var x : integer;
begin
  result := -1;
  Name := Uppercase(name);
  For x := 0 to fProcList.count-1 do begin
    If Uppercase(TProcObj(fProcList.Items[x]).name) = name then begin
       Result := x;
       exit;
    end;
  end;
end;

{ The routine of the loaded code that a binding names where no compilation of
  the text lists it -- one of the script's own, not a host routine the code
  calls -- kept until that code goes; nil where the code has none }
function TMethodList.CodeProc(const aName: tbtstring): TProcObj;
var
  x : Integer;
begin
  for x := 0 to fCodeProcs.Count - 1 do begin
    Result := TProcObj(fCodeProcs.Items[x]);
    If Uppercase(Result.Name) = Uppercase(aName) then
      Exit;
  end;
  Result := nil;
  { GetProcNo answers nil for the number of a name the code lacks }
  If not (fOwner.Exec.GetProcNo(fOwner.Exec.GetProc(aName)) is TPSInternalProcRec) then
    Exit;
  Result := TProcObj.create(Self);
  Result.Name := aName;
  fCodeProcs.Add(Result);
end;

procedure TMethodList.SetMethodName(Instance: TObject; PropName: tbtstring;
  const Value: tbtstring);
var
  x, y      : Integer;
  mo        : TMethodObj;
  lBindings : TList;
  lCompiled : Boolean;
  lText     : string;
  lError    : string;
  lMsgIdx   : Integer;
  function TypeData(Instance: TObject; const PropName: tbtstring):PTypeData;
  var
    PropInfo: PPropInfo;
  begin
    // assume failure
    Result := Nil;
    PropInfo := GetPropInfo(Instance, PropName);
    if PropInfo <> nil then
    begin
      Result:= GetTypeData(PropInfo^.PropType{$IFNDEF FPC}^{$ENDIF});
    end
  end;

begin
  If PropName = '' then begin
    { the bindings taken first: a setter that clearing runs can remove others }
    lBindings := TList.Create;
    try
      for x := 0 to MethodCount-1 do
        If (Methods[x].Instance = Instance) or (Instance = nil) then
          lBindings.Add(Methods[x]);
      for x := 0 to lBindings.Count-1 do begin
        y := fEventList.IndexOf(lBindings[x]);
        If y >= 0 then
          DeleteMethod(y);
      end;
    finally
      lBindings.Free;
    end;
  end else begin
    if value = '' then begin
      x := methodIndexOf(Instance, PropName);
      if x >= 0 then DeleteMethod(x);
    end else begin
      fOwner.CompileIfNeeded;
      y := ProcIndexOf(Value);
      If (Y = -1) then begin
        { a routine put in changes the script: never under a run of it }
        If fOwner.Running then
          Raise exception.create(sScriptRunning);
        { the routine changes the text, whose compilation then ends the code
          SetCompiled loaded: the text is compiled first, so that whether it
          compiled before the routine went in is known }
        If fOwner.FNeedCompiling and fOwner.FCompiledSet then
          fOwner.Compile;
        lCompiled := not fOwner.FNeedCompiling;
        lText := fOwner.Script.Text;
        CreateProc(Value, TypeData(Instance,propName));
        { a routine put in that a compiling script then refuses -- the name of
          something else the script, its units or its host declare -- is taken
          out again, the text as it was }
        If lCompiled and fOwner.FNeedCompiling then begin
          lError := '';
          for lMsgIdx := 0 to fOwner.CompilerMessageCount - 1 do
            If fOwner.CompilerMessages[lMsgIdx] is TPSPascalCompilerError then begin
              lError := string(fOwner.CompilerMessages[lMsgIdx].ShortMessageToString);
              Break;
            end;
          fOwner.Script.Text := lText;
          Raise exception.createFmt(sNotInsertable, [string(Value), lError]);
        end;
        { a routine of the compiled script that no event type takes is not
          bound; after a compilation that failed the binding waits for the next }
        If (ProcIndexOf(Value) = -1) and not fOwner.FNeedCompiling then
          Raise exception.createFmt(sNotBindable, [string(Value)]);
        y := 0;
      end;
      { taken after the compiles above, whose callbacks can change the list }
      x := methodIndexOf(Instance, PropName);
      If (x = -1) then begin
        If (Y <> -1) then begin
          mo := TMethodObj.create;
          mo.Instance := TPersistent(Instance);
          mo.ProPName := Propname;
          mo.procName := Value;
          { through the extension's watcher, which has no owner: registered with
            the component whoever owns either }
          If Instance is TComponent then
            TComponent(Instance).FreeNotification(fOwner.FWatcher);
          fEventList.add(mo);
        end;
      end else
      begin
        Methods[x].procname := Value;
      end;
    end;
  end;
end;

{ Removes binding Index: out of the list before its event is cleared, so that
  the accessors find it gone, and freed also when clearing raises }
procedure TMethodList.DeleteMethod(Index: Integer);
var
  lBinding : TMethodObj;
begin
  lBinding := Methods[Index];
  fEventList.Extract(lBinding);
  try
    ClearEventHolding(lBinding, lBinding.Filled);
  finally
    lBinding.Free;
  end;
end;

{ Clears aBinding's event where it still holds aMethod, a routine of the script; aBinding forgets aMethod as the
  one it was filled with.  The component whose own free notification is running is not written to.  aMethod is
  taken by value: DeleteMethod passes aBinding.Filled itself, which this clears first.  aBinding is not
  touched once the accessors, which can free it, have run }
procedure TMethodList.ClearEventHolding(aBinding: TMethodObj; aMethod: TMethod);
var
  lInstance : TObject;
  lPropInfo : PPropInfo;
  m         : TMethod;
begin
  If (aBinding.Filled.Code = aMethod.Code) and (aBinding.Filled.Data = aMethod.Data) then begin
    aBinding.Filled.Code := nil;
    aBinding.Filled.Data := nil;
  end;
  lInstance := aBinding.Instance;
  If ((aMethod.Code = nil) and (aMethod.Data = nil)) or (lInstance = fGoing) then exit;
  lPropInfo := GetPropInfo(lInstance, string(aBinding.PropName), [tkMethod]);
  If lPropInfo = nil then exit;
  m := GetMethodProp(lInstance, lPropInfo);
  If (m.Code = aMethod.Code) and (m.Data = aMethod.Data) then begin
    m.Code := nil;
    m.Data := nil;
    SetMethodProp(lInstance, lPropInfo, m);
  end;
end;

{ Removes the bindings of aComponent, whose own free has begun: nothing is
  written to it }
{ Retires every routine's method: the events holding one are cleared, and the
  routines fetch theirs again at the next fill -- the loaded code's routines
  go with that code, and the next code's are found by name }
procedure TMethodList.RetireMethods;
var
  x : Integer;
begin
  x := 0;
  while x < fProcList.Count do begin
    TProcObj(fProcList.Items[x]).Retire;
    Inc(x);
  end;
  fCodeProcs.Clear;
end;

procedure TMethodList.ComponentGoes(aComponent: TComponent);
var
  lGoing : TObject;
begin
  lGoing := fGoing;
  fGoing := aComponent;
  try
    SetMethodName(aComponent, '', '');
  finally
    fGoing := lGoing;
  end;
end;

procedure TMethodList.ClearAll;
begin
  fProclist.clear;
  fCodeProcs.Clear;
  fEventList.Clear;
end;

{ TProcObj }

constructor TProcObj.create(aOwner: TMethodList);
begin
  inherited create();
  fOwner := aOwner;
  ProcType := TStringList.Create;
end;

destructor TProcObj.Destroy;
begin
  Retire;
  ProcType.free;
  inherited;
end;

procedure TProcObj.Retire;
var x : Integer;
begin
  If ((Method.Data <> nil) or (method.Code<> nil)) and (fOwner<>nil) and assigned(fOwner) then begin
    { backwards, the bound clamped after each binding as
      TComponent.Notification does: an accessor can remove bindings }
    x := fOwner.MethodCount-1;
    while x >= 0 do begin
      Try
        fOwner.ClearEventHolding(fOwner.Methods[x], Method);
      except; end;
      Dec(x);
      If x >= fOwner.MethodCount then
        x := fOwner.MethodCount-1;
    end;
  end;
  Method.Code := nil;
  Method.Data := nil;
end;

procedure TProcObj.SetName(const Value: tbtstring);
var
  x : Integer;
begin
  If FName <> Value then begin
    If fName<>'' then begin
      for x := 0 to fOwner.MethodCount-1 do begin
        If Fname = fOwner.Methods[x].ProcName then begin
          fOwner.Methods[x].ProcName := Value;
        end;
      end;
    end;
    FName := Value;
  end;
end;


end.
