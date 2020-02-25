unit uDAPSScriptingProvider;
{----------------------------------------------------------------------------}
{ Data Abstract Library - Pascal Script                                      }
{                                                                            }
{ (c)opyright RemObjects Software. all rights reserved.                      }
{                                                                            }
{ Using this code requires a valid license of the Data Abstract              }
{ which can be obtained at http://www.remobjects.com.                        }
{----------------------------------------------------------------------------}

{$I DataAbstract.inc}

interface

uses
  Classes,
  uPSComponent, uPSComponent_DB, uPSComponent_Default, uPSUtils,
  uDAScriptingProvider, uDAInterfaces, uDABusinessProcessor, uDADataTable,
  uDAPascalScript, uDASchemaClasses;

type
  TDAPSScriptingProvider = class;
  TDAPSScript = class(TPSScript)
  private
    fProvider: TDAPSScriptingProvider;
  protected
    function  DoOnGetNotificationVariant (const Name: tbtstring): Variant; override;
    procedure DoOnSetNotificationVariant (const Name: tbtstring; V: Variant); override;
    procedure DoOnCompile; override;
  end;

  TDAPSScriptingProvider = class(TDAScriptingProvider, IDADataTableScriptingProvider, IDABusinessProcessorScriptingProvider)
  private
    fDataTablePlugin: TDAPSDataTableRulesPlugin;
    fBusinessProcessor: TDABusinessProcessor;
    fDataTable: TDADataTable;
    fScript: TPSScript;
    fPluginClasses: TPSImport_Classes;
    fPluginDB: TPSImport_DB;
    fPluginDateUtils: TPSImport_DateUtils;
    fIsFirstRun: boolean;

    procedure RunDataTableScript(aDataTable: TDADataTable; const aScript: string; const aMethod: string; aLanguage:TROSEScriptLanguage);
    procedure RunBusinessProcessorScript(aBusinessProcessor: TDABusinessProcessor; const aScript: string; const aMethod: string; aLanguage:TROSEScriptLanguage);

    procedure OnCompile(Sender: TPSScript);
    function OnGetNotificationVariant(Sender: TPSScript; const Name: tbtstring): Variant;
    procedure OnSetNotificationVariant(Sender: TPSScript; const Name: tbtstring; V: Variant);

    //procedure OnVerifyProc(Sender: TPSScript; Proc: TPSInternalProcedure; const Decl: string; var Error: Boolean);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure PrepareForDataTable(aDataTable: TDADataTable);
    procedure PrepareForBusinessProcessor(aBusinessProcessor: TDABusinessProcessor);

  published
    property ScriptEngine: TPSScript read fScript;
    property PluginClasses: TPSImport_Classes read fPluginClasses;
    property PluginDB: TPSImport_DB read fPluginDB;
    property PluginDateUtils: TPSImport_DateUtils read fPluginDateUtils;
  end deprecated;

implementation

uses
  SysUtils, uROClasses;

{ TDADataTableScripter }

procedure TDAPSScriptingProvider.Assign(Source: TPersistent);
var
  lSource: TDAPSScriptingProvider;
begin
  inherited;
  if Source is TDAPSScriptingProvider then begin
    lSource := TDAPSScriptingProvider(Source);

    PluginClasses.Assign(lSource.PluginClasses);
    PluginDateUtils.Assign(lSource.PluginDateUtils);
    PluginDB.Assign(lSource.PluginDB);
    ScriptEngine.Assign(lSource.ScriptEngine);
  end;
end;

constructor TDAPSScriptingProvider.Create(AOwner: TComponent);
begin
  inherited;
  fScript := TDAPSScript.Create(self);
  TDAPSScript(fScript).fProvider := Self;
  fScript.Name := 'ScriptEngine';
  fScript.SetSubComponent(true);
  //fScript.OnVerifyProc := OnVerifyProc;
  fScript.CompilerOptions := [icAllowNoBegin, icAllowNoEnd, icBooleanShortCircuit];
  fPluginClasses := TPSImport_Classes.Create(self);
  fPluginClasses.Name := 'PluginClasses';
  fPluginDB := TPSImport_DB.Create(self);
  fPluginDB.Name := 'PluginDB';
  fPluginDateUtils := TPSImport_DateUtils.Create(self);
  fPluginDateUtils.Name := 'PluginDateUtils';
  (fScript.Plugins.Add() as TPSPluginItem).Plugin := fPluginClasses;
  (fScript.Plugins.Add() as TPSPluginItem).Plugin := fPluginDB;
  (fScript.Plugins.Add() as TPSPluginItem).Plugin := fPluginDateUtils;
  fIsFirstRun := true;
end;

destructor TDAPSScriptingProvider.Destroy;
begin
  FreeAndNil(fScript);
  inherited;
end;

procedure TDAPSScriptingProvider.OnCompile(Sender: TPSScript);
var
  i: Integer;
begin
  if Assigned(fDataTable) then begin
    for i := 0 to fDataTable.Fields.Count-1 do begin
      fScript.AddRegisteredVariable(fDataTable.Fields[i].Name, '!NOTIFICATIONVARIANT');
    end; { for }
  end;

  if Assigned(fBusinessProcessor) then begin
    //ToDo:
  end;
end;

{procedure TDAPSScriptingProvider.OnVerifyProc(Sender: TPSScript; Proc: TPSInternalProcedure; const Decl: string; var Error: Boolean);
begin
  if Proc.Decl.ParamCount = 0 then
    Proc.aExport := etExportDecl;
end;}

function TDAPSScriptingProvider.OnGetNotificationVariant(Sender: TPSScript; const Name: tbtstring): Variant;
begin
  result := fDataTable.Fields.FieldByName(Name).Value;
end;

procedure TDAPSScriptingProvider.OnSetNotificationVariant(Sender: TPSScript; const Name: tbtstring; V: Variant);
begin
  fDataTable.Fields.FieldByName(Name).Value := V;
end;

procedure TDAPSScriptingProvider.PrepareForBusinessProcessor(aBusinessProcessor: TDABusinessProcessor);
begin

end;

procedure TDAPSScriptingProvider.PrepareForDataTable(aDataTable: TDADataTable);
begin
  fDataTable := aDataTable;
  fBusinessProcessor := nil;
  fScript.Defines.Text := 'DATA_ABSTRACT_SCRIPT'#13#10'DATA_ABSTRACT_SCRIPT_CLIENT';
  if not assigned(fDataTablePlugin) then begin
    fDataTablePlugin := TDAPSDataTableRulesPlugin.Create(self);
    fDataTablePlugin.DataTable := aDataTable;
    (fScript.Plugins.Add() as TPSPluginItem).Plugin := fDataTablePlugin;
  end;
end;


procedure TDAPSScriptingProvider.RunBusinessProcessorScript(
  aBusinessProcessor: TDABusinessProcessor; const aScript, aMethod: string;
  aLanguage: TROSEScriptLanguage);
begin
  fDataTable := nil;
  FreeAndNil(fDataTablePlugin);
  fBusinessProcessor := aBusinessProcessor;
  fScript.Defines.Text := 'DATA_ABSTRACT_SCRIPT'#13#10'DATA_ABSTRACT_SCRIPT_SERVER';
  //(fScript.Plugins.Add() as TPSPluginItem).Plugin := TDAPSDataTableRulesPlugin.Create(self);
end;

type
  TScriptMethod = procedure of object;

procedure TDAPSScriptingProvider.RunDataTableScript(aDataTable: TDADataTable; const aScript: string; const aMethod: string; aLanguage: TROSEScriptLanguage);
var
  lMessages: tbtstring;
  i: Integer;
  lMethod: TScriptMethod;
begin
  if aLanguage <> rslPascalScript then raise EDAScriptError.CreateFmt('Only rslPascalScript language is supported by %s',[Self.Name]);

  if fDataTable <> aDataTable then begin
    PrepareForDataTable(aDataTable);
  end;
  if fIsFirstRun then begin
    fScript.Script.Text := '';
    fIsFirstRun := false;
  end;
  if aScript <> fScript.Script.Text then begin
    fScript.Script.Text := aScript;
    if not fScript.Compile then begin
      lMessages := '';
      for i := 0 to fScript.CompilerMessageCount-1 do begin
        lMessages := lMessages+#13#10+fScript.CompilerMessages[i].MessageToString;
      end; { for }
      RaiseError('There were errors compiling the business rule script for %s.'#13'%s',[aDataTable.Name,lMessages], EDAScriptCompileError);
    end;
  end;

  fDataTablePlugin.DataTable := aDataTable;
  lMethod := TScriptMethod(fScript.GetProcMethod(aMethod));
  if assigned(@lMethod) then
    lMethod();
end;

{ TDAPSScript }

procedure TDAPSScript.DoOnCompile;
begin
  inherited;
  fProvider.OnCompile(Self);
end;

function TDAPSScript.DoOnGetNotificationVariant(
  const Name: tbtstring): Variant;
begin
  Result := fProvider.OnGetNotificationVariant(Self, Name);
end;

procedure TDAPSScript.DoOnSetNotificationVariant(const Name: tbtstring;
  V: Variant);
begin
  fProvider.OnSetNotificationVariant(Self, Name, V);
end;

end.
