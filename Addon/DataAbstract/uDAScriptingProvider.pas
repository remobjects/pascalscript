unit uDAScriptingProvider;

{----------------------------------------------------------------------------}
{ Data Abstract Library - Core Library                                       }
{                                                                            }
{ (c)opyright RemObjects Software. all rights reserved.                      }
{                                                                            }
{ Using this code requires a valid license of the Data Abstract              }
{ which can be obtained at http://www.remobjects.com.                        }
{----------------------------------------------------------------------------}

{$I DataAbstract.inc}

interface

uses
  Classes, SysUtils, Types,
  uROComponent, uROClasses,
  uDACore, uDADelta, uDAClientSchema, DataAbstract4_Intf;

type
  TScriptableComponent = class;
  TDABaseScriptingProvider = class(TROComponent)
  private
    fList: TList;
    fOneComponentPerProvider: Boolean;
    procedure RegisterScriptableComponent(AComponent: TScriptableComponent);
    procedure UnregisterScriptableComponent(AComponent: TScriptableComponent);
    procedure UnregisterAllScriptableComponents;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TDAScriptingProvider = class(TDABaseScriptingProvider)
  private
    function GetScriptableComponent: TScriptableComponent;
    procedure SetScriptableComponent(const Value: TScriptableComponent);
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
  published
    property ScriptableComponent: TScriptableComponent read GetScriptableComponent write SetScriptableComponent;
  end;

  IDAScriptingProvider = interface
  ['{6D19A2F9-233A-4EE6-95EC-CDFCD7410C15}']
  end;

  EDAScriptError = class(EDAException);
  EDAScriptCompileError = class(EDAScriptError);

  TScriptableComponent = class(TROComponent)
  private
    fScriptingProvider: TDABaseScriptingProvider;
    procedure SetScriptingProvider(const Value: TDABaseScriptingProvider);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property ScriptingProvider: TDABaseScriptingProvider read fScriptingProvider write SetScriptingProvider;
  end;

  IDAScriptSession = interface
    function GetID: string;
    function GetExpired: Boolean;
    function GetNew: Boolean;
    function GetTimeOut: integer;
    function GetItem(aKey: string): variant;
    procedure SetItem(aKey: string; Value: variant);
    function GetRoles: TStringArray;
    procedure SetRoles(Value:TStringArray);
    function GetCount: integer;
    function GetNames(Index: integer): string;
    property ID: String read GetID;
    property Expired: Boolean read GetExpired;
    property New: Boolean read GetNew;
    property Timeout: Integer read GetTimeOut;
    property Item[aKey: string]: variant read GetItem write SetItem; default;
    property Names[Index : integer] : string read GetNames;
    property NamesCount : integer read GetCount;
    property Roles: TStringArray read GetRoles write SetRoles;
    procedure AddRole(aName: String);
    procedure RemoveRole(aName: String);
    function HasRole(aName: String): Boolean;
  end;

  IDAScriptContext = interface
    function GetIsServer: Boolean;
    function GetSchema: TDAClientSchema;
    function GetSession: IDAScriptSession;
    property IsServer: Boolean read GetIsServer;
    property Session: IDAScriptSession read GetSession;
    property Schema: TDAClientSchema read GetSchema;
  end;

  IDAScriptProvider = interface
  ['{9179875D-1F1E-4CBD-B860-3A39DDD56A9F}']
    function GetHasAfterCommit: Boolean;
    function GetHasAfterExecuteCommand: Boolean;
    function GetHasAfterGetData: Boolean;
    function GetHasAfterProcessDelta: Boolean;
    function GetHasAfterProcessDeltaChange: Boolean;
    function GetHasAfterRollback: Boolean;
    function GetHasBeforeCommit: Boolean;
    function GetHasBeforeDelete(aTableName: String): Boolean;
    function GetHasBeforeExecuteCommand: Boolean;
    function GetHasBeforeGetData: Boolean;
    function GetHasBeforePost(aTableName: String): Boolean;
    function GetHasBeforeProcessDelta: Boolean;
    function GetHasBeforeProcessDeltaChange: Boolean;
    function GetHasBeforeRollback: Boolean;
    function GetHasCreateTransaction: Boolean;
    function GetHasOnNewRow(aTableName: String): Boolean;
    function GetHasProcessError: Boolean;
    function GetHasUnknownSqlMacroIdentifier: Boolean;
    function GetHasValidateCommandAccess: Boolean;
    function GetHasValidateDataTableAccess: boolean;
    function GetHasValidateDirectSQLAccess: boolean;
    function GetContext: IDAScriptContext;
    procedure SetContext(Value: IDAScriptContext);

    property Context: IDAScriptContext read GetContext write SetContext;

    procedure LoadScript(aScript: string);
    function SupportsLanguage(aName: String): Boolean;
    // Server:
    property HasBeforeExecuteCommand: Boolean read GetHasBeforeExecuteCommand;
    procedure BeforeExecuteCommand(aSQL, aCommandName: String; aParameters: DataParameterArray);
    property HasAfterExecuteCommand: Boolean read GetHasAfterExecuteCommand;
    procedure AfterExecuteCommand(aSQL, aCommandName: String; aParameters: DataParameterArray; aRowsAffected: Integer);

    property HasBeforeProcessDelta: Boolean read GetHasBeforeProcessDelta;
    procedure BeforeProcessDelta(aDelta: IDADelta);
    property HasAfterProcessDelta: Boolean read GetHasAfterProcessDelta;
    procedure AfterProcessDelta(aDelta: IDADelta);

    property HasBeforeProcessDeltaChange: Boolean read GetHasBeforeProcessDeltaChange;
    procedure BeforeProcessDeltaChange(aDelta: IDADelta; aChange: TDADeltaChange; aWasRefreshed: Boolean; var aCanRemove: Boolean);
    property HasAfterProcessDeltaChange: Boolean read GetHasAfterProcessDeltaChange;
    procedure AfterProcessDeltaChange(aDelta: IDADelta; aChange: TDADeltaChange; aWasRefreshed: Boolean);

    property HasProcessError: Boolean read GetHasProcessError;
    procedure ProcessError(aDelta: IDADelta; aChange: TDADeltaChange; var aCanContinue: Boolean; var aError: Exception);

    property HasValidateDataTableAccess: boolean read GetHasValidateDataTableAccess;
    procedure ValidateDataTableAccess(aName: String; aParameterNames: array of String; aParameterValues: array of variant; var aAllowed: Boolean);

    property HasValidateDirectSQLAccess: boolean read GetHasValidateDirectSQLAccess;
    procedure ValidateDirectSQLAccess(aSQL: String; aParameterNames: array of String; aParameterValues: array of variant; var aAllowed: Boolean);

    property HasValidateCommandAccess: Boolean read GetHasValidateCommandAccess;
    procedure ValidateCommandAccess(aName: String; aParameterNames: array of String; aParameterValues: array of variant; var aAllowed: Boolean);

    property HasUnknownSqlMacroIdentifier: Boolean read GetHasUnknownSqlMacroIdentifier;
    procedure UnknownSqlMacroIdentifier(aIdentifier: String;  var aValue: String);

    property HasCreateTransaction: Boolean read GetHasCreateTransaction;
    procedure CreateTransaction;

    property HasBeforeCommit: Boolean read GetHasBeforeCommit;
    procedure BeforeCommit;

    property HasAfterCommit: Boolean read GetHasAfterCommit;
    procedure AfterCommit;

    property HasBeforeRollback: Boolean read GetHasBeforeRollback;
    procedure BeforeRollback;

    property HasAfterRollback: Boolean read GetHasAfterRollback;
    procedure AfterRollback;

    property HasBeforeGetData: Boolean read GetHasBeforeGetData;
    procedure BeforeGetData(aTables: StringArray; aRequestInfo: TableRequestInfoArray);

    property HasAfterGetData: Boolean read GetHasAfterGetData;
    procedure AfterGetData(aTables: StringArray; aRequestInfo: TableRequestInfoArray);
    // Client and Server

    property HasOnNewRow[aTableName: String]: Boolean read GetHasOnNewRow;
    procedure OnNewRow(aRow: IDARowHelper);

    property HasBeforePost[aTableName: String]: Boolean read GetHasBeforePost;
    procedure BeforePost(aRow: IDARowHelper);

    property HasBeforeDelete[aTableName: String]: Boolean read GetHasBeforeDelete;
    procedure BeforeDelete(aRow: IDARowHelper);
  end;


implementation

{ TScriptableComponent }

procedure TScriptableComponent.Assign(Source: TPersistent);
var
  lSource: TScriptableComponent;
begin
  inherited;
  if Source is TScriptableComponent then begin
    lSource := TScriptableComponent(Source);

    ScriptingProvider := lSource.ScriptingProvider;
  end;
end;

destructor TScriptableComponent.Destroy;
begin
  ScriptingProvider := nil;
  inherited;
end;

procedure TScriptableComponent.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (Operation = opRemove) then begin
    if (AComponent = fScriptingProvider) then fScriptingProvider := nil;
  end;
  inherited;
end;

procedure TScriptableComponent.SetScriptingProvider(const Value: TDABaseScriptingProvider);
begin
  if fScriptingProvider <> Value then begin
    if fScriptingProvider <> nil then begin
      fScriptingProvider.RORemoveFreeNotification(self);
      fScriptingProvider.UnregisterScriptableComponent(Self);
    end;
    fScriptingProvider := Value;
    if Assigned(fScriptingProvider) then begin
      fScriptingProvider.RegisterScriptableComponent(Self);
      fScriptingProvider.ROFreeNotification(self);
    end;
  end;
end;

{ TDAScriptingProvider }

procedure TDAScriptingProvider.Assign(Source: TPersistent);
var
  lSource: TDAScriptingProvider;
begin
  inherited;
  if Source is TDAScriptingProvider then begin
    lSource := TDAScriptingProvider(Source);
    ScriptableComponent := lSource.ScriptableComponent;
  end;
end;

constructor TDAScriptingProvider.Create(AOwner: TComponent);
begin
  inherited;
  fOneComponentPerProvider := True;
end;

destructor TDAScriptingProvider.Destroy;
begin
  ScriptableComponent := nil;
  inherited;
end;

function TDAScriptingProvider.GetScriptableComponent: TScriptableComponent;
begin
  Result := nil;
  if fList.Count = 1 then Result := TScriptableComponent(fList.First);
end;

procedure TDAScriptingProvider.SetScriptableComponent(
  const Value: TScriptableComponent);
var
  lComponent:TScriptableComponent;
begin
  lComponent := GetScriptableComponent;
  if lComponent <> Value then begin
    if lComponent <> nil then UnregisterScriptableComponent(lComponent);
    if Assigned(Value) then RegisterScriptableComponent(Value);
  end;
end;

{ TDABaseScriptingProvider }

constructor TDABaseScriptingProvider.Create(AOwner: TComponent);
begin
  inherited;
  fList:= TList.Create;
end;

destructor TDABaseScriptingProvider.Destroy;
begin
  UnregisterAllScriptableComponents;
  fList.Free;
  inherited;
end;

procedure TDABaseScriptingProvider.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent is TScriptableComponent) then
    UnregisterScriptableComponent(TScriptableComponent(AComponent));
  inherited;
end;

procedure TDABaseScriptingProvider.RegisterScriptableComponent(
  AComponent: TScriptableComponent);
begin
  if fList.IndexOf(AComponent) = -1 then begin
    if fOneComponentPerProvider then UnregisterAllScriptableComponents;
    fList.Add(AComponent);
    AComponent.ROFreeNotification(Self);
    AComponent.fScriptingProvider := Self;
  end;
end;

procedure TDABaseScriptingProvider.UnregisterAllScriptableComponents;
var
  i: integer;
begin
  for i := fList.Count - 1 downto 0 do
    TScriptableComponent(fList[0]).ScriptingProvider := nil;
  fList.Clear;
end;

procedure TDABaseScriptingProvider.UnregisterScriptableComponent(
  AComponent: TScriptableComponent);
begin
  fList.Remove(AComponent);
  AComponent.RORemoveFreeNotification(Self);
  AComponent.fScriptingProvider := nil;
end;

end.
