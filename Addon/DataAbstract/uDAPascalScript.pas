unit uDAPascalScript;
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
  SysUtils, Classes, DB,
  uPSComponent, uPSCompiler, uPSRuntime, uPSUtils,
  uDADataTable;

type
  TDAPSDataTableRulesPlugin = class;
  TDAPSDataTableRules = class(TDADataTableRules)
  private
    FSE: TPSScript;
    procedure SetSE(const Value: TPSScript);
  protected
    procedure BeforeOpen(Sender: TDADataTable); override;
    procedure AfterOpen(Sender: TDADataTable); override;
    procedure BeforeClose(Sender: TDADataTable); override;
    procedure AfterClose(Sender: TDADataTable); override;
    procedure BeforeInsert(Sender: TDADataTable); override;
    procedure AfterInsert(Sender: TDADataTable); override;
    procedure BeforeEdit(Sender: TDADataTable); override;
    procedure AfterEdit(Sender: TDADataTable); override;
    procedure BeforePost(Sender: TDADataTable); override;
    procedure AfterPost(Sender: TDADataTable); override;
    procedure BeforeCancel(Sender: TDADataTable); override;
    procedure AfterCancel(Sender: TDADataTable); override;
    procedure BeforeDelete(Sender: TDADataTable); override;
    procedure AfterDelete(Sender: TDADataTable); override;
    procedure BeforeScroll(Sender: TDADataTable); override;
    procedure AfterScroll(Sender: TDADataTable); override;
    procedure BeforeRefresh(Sender: TDADataTable); override;
    procedure AfterRefresh(Sender: TDADataTable); override;
    procedure OnCalcFields(Sender: TDADataTable); override;
    procedure OnNewRecord(Sender: TDADataTable); override;

    procedure Setup(const Dataset: TDADataTable);
    procedure ExecuteProc(Dataset: TDADataTable; const Name: tbtstring);
  public
    property SE: TPSScript read FSE write SetSE;
  end;

  TDAPSDataTableRulesPlugin = class(TPSPlugin)
  private
    fDataTable: TDADataTable;
    fScriptEngine: TPSScript;
    procedure SetDataTable(const Value: TDADataTable);
  public
    procedure CompOnUses(CompExec: TPSScript); override;
    procedure CompileImport1(CompExec: TPSScript); override;
    procedure ExecImport2(CompExec: TPSScript; const ri: TPSRuntimeClassImporter); override;
    property DataTable: TDADataTable read fDataTable write SetDataTable;
  end;

implementation

uses
  Dialogs,
  uROClasses,
  uDACore, uDAScriptingProvider, uDAInterfaces, uDAFields;
//uses
//  uDADataTable;

procedure SIRegister_TDADataTable(CL: TIFPSPascalCompiler);
var
 lc: TPSCompileTimeClass;
begin
  lc := CL.AddClassN(CL.FindClass('TComponent'), 'TDADataTable');
  lc.RegisterProperty('Active', 'boolean', iptrw);
  lc.RegisterProperty('Fields', 'TDAFieldCollection', iptrw);
  lc.RegisterProperty('Params', 'TDAParamCollection', iptrw);
  lc.RegisterProperty('LogChanges', 'boolean', iptrw);
  lc.RegisterProperty('RemoteFetchEnabled', 'boolean', iptrw);
  lc.RegisterProperty('MasterFields', 'string', iptrw);
  lc.RegisterProperty('DetailFields', 'string', iptrw);
  lc.RegisterProperty('MasterRequestMappings', 'TStrings', iptrw);
  lc.RegisterProperty('DetailOptions', 'TDADetailOptions', iptrw);
  lc.RegisterProperty('MasterOptions', 'TDAMasterOptions', iptrw);
  lc.RegisterProperty('Filtered', 'boolean', iptrw);
  lc.RegisterProperty('Filter', 'string', iptrw);
  lc.RegisterProperty('LogicalName', 'string', iptrw);
  lc.RegisterProperty('BusinessRulesID', 'string', iptrw);
  lc.RegisterProperty('State','TDataSetState',iptR);
end;

procedure SIRegister_TDAParamCollection(CL: TIFPSPascalCompiler);
var
 lc: TPSCompileTimeClass;
begin
  lc := CL.AddClassN(CL.FindClass('TSearcheableInterfacedCollection'), 'TDAParamCollection');
  lc.RegisterMethod('Constructor Create( aOwner : TPersistent)');
  lc.RegisterMethod('Procedure WriteValues( OutputParams : TParams)');
  lc.RegisterMethod('Procedure ReadValues( InputParams : TParams)');
  lc.RegisterMethod('Function Add : TDAParam');
  lc.RegisterMethod('Function ParamByName( const aName : string) : TDAParam');
  lc.RegisterMethod('Function FindParam( const aParamName : string) : TDAParam');
  lc.RegisterMethod('Procedure AssignParamCollection( Source : TDAParamCollection)');
  lc.RegisterProperty('Params', 'TDAParam integer', iptrw);
  lc.SetDefaultPropery('Params');
  lc.RegisterProperty('HasInputParams', 'boolean', iptr);
end;

procedure SIRegister_TDAParam(CL: TIFPSPascalCompiler);
var
  lc: TPSCompileTimeClass;
begin
  lc := CL.AddClassN(CL.FindClass('TDABaseField'), 'TDAParam');
  lc.RegisterMethod('Procedure SaveToStream( const aStream : IROStream)');
  lc.RegisterMethod('Procedure LoadFromStream( const aStream : IROStream)');
  lc.RegisterMethod('Procedure SaveToFile( const aFileName : string)');
  lc.RegisterMethod('Procedure LoadFromFile( const aFileName : string)');
  lc.RegisterProperty('ParamType', 'TDAParamType', iptrw);
end;

procedure SIRegister_TDAFieldCollection(CL: TIFPSPascalCompiler);
var
  lc: TPSCompileTimeClass;
begin
  lc := CL.AddClassN(CL.FindClass('TDACustomFieldCollection'), 'TDAFieldCollection');
  lc.RegisterMethod('Constructor Create( aOwner : TPersistent)');
  lc.RegisterMethod('Function FieldByName( const aName : string) : TDAField');
  lc.RegisterMethod('Function FindField( const aName : string) : TDAField');
  lc.RegisterProperty('Fields', 'TDAField integer', iptrw);
  lc.SetDefaultPropery('Fields');
end;

procedure SIRegister_TDACustomFieldCollection(CL: TIFPSPascalCompiler);
var
  lc: TPSCompileTimeClass;
begin
  lc := CL.AddClassN(CL.FindClass('TSearcheableInterfacedCollection'), 'TDACustomFieldCollection');
  lc.RegisterMethod('Procedure Bind( aDataset : TDataset)');
  lc.RegisterMethod('Procedure Unbind');
  lc.RegisterProperty('FieldEventsDisabled', 'boolean', iptrw);
  lc.RegisterMethod('Procedure AssignFieldCollection( Source : TDACustomFieldCollection)');
  lc.RegisterMethod('Function FieldByName( const aName : string) : TDACustomField');
  lc.RegisterMethod('Function FindField( const aName : string) : TDACustomField');
  lc.RegisterMethod('Procedure MoveItem( iFromIndex, iToIndex : integer)');
  lc.RegisterProperty('DataDictionary', 'IDADataDictionary', iptrw);
  lc.RegisterProperty('Fields', 'TDACustomField integer', iptrw);
  lc.SetDefaultPropery('Fields');
end;

procedure SIRegister_TDADataDictionaryField(CL: TIFPSPascalCompiler);
begin
  CL.AddClassN(CL.FindClass('TDACustomField'), 'TDADataDictionaryField');
end;

procedure SIRegister_TDAField(CL: TIFPSPascalCompiler);
begin
  CL.AddClassN(CL.FindClass('TDACustomField'), 'TDAField');
end;

procedure SIRegister_TDACustomField(CL: TIFPSPascalCompiler);
var
  lc: TPSCompileTimeClass;
begin
  lc := CL.AddClassN(CL.FindClass('TDABaseField'), 'TDACustomField');
  lc.RegisterMethod('Procedure Bind( aField : TField)');
  lc.RegisterMethod('Procedure Unbind');
  lc.RegisterMethod('Procedure SaveToStream( const aStream : IROStream)');
  lc.RegisterMethod('Procedure LoadFromStream( const aStream : IROStream)');
  lc.RegisterMethod('Procedure SaveToFile( const aFileName : string)');
  lc.RegisterMethod('Procedure LoadFromFile( const aFileName : string)');
  lc.RegisterProperty('FieldCollection', 'TDACustomFieldCollection', iptr);
  lc.RegisterProperty('TableField', 'string', iptrw);
  lc.RegisterProperty('IsNull', 'boolean', iptr);
  lc.RegisterProperty('InPrimaryKey', 'boolean', iptrw);
  lc.RegisterProperty('Calculated', 'boolean', iptrw);
  lc.RegisterProperty('Lookup', 'boolean', iptrw);
  lc.RegisterProperty('LookupSource', 'TDataSource', iptrw);
  lc.RegisterProperty('LookupKeyFields', 'string', iptrw);
  lc.RegisterProperty('LookupResultField', 'string', iptrw);
  lc.RegisterProperty('KeyFields', 'string', iptrw);
  lc.RegisterProperty('LookupCache', 'boolean', iptrw);
  lc.RegisterProperty('LogChanges', 'boolean', iptrw);
  lc.RegisterProperty('RegExpression', 'string', iptrw);
  lc.RegisterProperty('DefaultValue', 'string', iptrw);
  lc.RegisterProperty('Required', 'boolean', iptrw);
  lc.RegisterProperty('DisplayWidth', 'integer', iptrw);
  lc.RegisterProperty('DisplayLabel', 'string', iptrw);
  lc.RegisterProperty('EditMask', 'string', iptrw);
  lc.RegisterProperty('Visible', 'boolean', iptrw);
  lc.RegisterProperty('ReadOnly', 'boolean', iptrw);
  lc.RegisterProperty('CustomAttributes', 'TStrings', iptrw);
  lc.RegisterProperty('DisplayFormat', 'string', iptrw);
  lc.RegisterProperty('BusinessRulesID', 'string', iptrw);
  lc.RegisterProperty('EditFormat', 'string', iptrw);
  lc.RegisterProperty('Alignment', 'TAlignment', iptrw);
end;

procedure SIRegister_TDABaseField(CL: TIFPSPascalCompiler);
var
  lc: TPSCompileTimeClass;
begin
  lc := CL.AddClassN(CL.FindClass('TCollectionItem'), 'TDABaseField');
  lc.RegisterProperty('Value', 'Variant', iptrw);
  lc.RegisterMethod('Procedure AssignField( Source : TDABaseField)');
  lc.RegisterMethod('Function HasValidDictionaryField : Boolean');
  lc.RegisterProperty('AsBoolean', 'boolean', iptrw);
  lc.RegisterProperty('AsCurrency', 'currency', iptrw);
  lc.RegisterProperty('AsDateTime', 'TDateTime', iptrw);
  lc.RegisterProperty('AsFloat', 'double', iptrw);
  lc.RegisterProperty('AsInteger', 'integer', iptrw);
  lc.RegisterProperty('AsString', 'string', iptrw);
  lc.RegisterProperty('AsVariant', 'variant', iptrw);
  lc.RegisterProperty('DictionaryEntry', 'string', iptrw);
  lc.RegisterProperty('Name', 'string', iptrw);
  lc.RegisterProperty('DataType', 'TDADataType', iptrw);
  lc.RegisterProperty('Size', 'integer', iptrw);
  lc.RegisterProperty('Description', 'string', iptrw);
  lc.RegisterProperty('BlobType', 'TDABlobType', iptrw);
end;

procedure SIRegister_uDA(CL: TIFPSPascalCompiler);
begin
  CL.AddTypeS('TDAPersistFormat', '( pfBinary, pfXML )');
  CL.AddTypeS('TDAParamType', '( daptUnknown, daptInput, daptOutput, daptInputO'
    + 'utput, daptResult )');
  CL.AddTypeS('TDADataType', '( datUnknown, datString, datDateTime, datFloat, d'
    + 'atCurrency, datAutoInc, datInteger, datLargeInt, datBoolean, datMemo, datB'
    + 'lob, datWideString, datWideMemo, datLargeAutoInc, datByte, datShortInt, '
    +  'datWord, datSmallInt, datCardinal, datLargeUInt, datGuid, datXml, datDecimal, datSingleFloat, datFixedChar, datFixedWideChar )');
  CL.AddTypeS('TDABlobType', '( dabtUnknown, dabtBlob, dabtMemo, dabtOraBlob, d'
    + 'abtOraClob, dabtGraphic,dabtTypedBinary)');
  SIRegister_TDABaseField(CL);
  CL.AddClassN(CL.FindClass('TOBJECT'), 'TDACustomFieldCollection');
  SIRegister_TDACustomField(CL);
  SIRegister_TDAField(CL);
  SIRegister_TDADataDictionaryField(CL);
  SIRegister_TDACustomFieldCollection(CL);
  SIRegister_TDAFieldCollection(CL);
  SIRegister_TDAParam(CL);
  SIRegister_TDAParamCollection(CL);
  SIRegister_TDADataTable(CL);
end;

(* === run-time registration functions === *)

procedure TDADataTableBusinessRulesID_W(Self: TDADataTable; const T: string);
begin
  Self.BusinessRulesID := T;
end;

procedure TDADataTableBusinessRulesID_R(Self: TDADataTable; var T: string);
begin
  T := Self.BusinessRulesID;
end;

procedure TDADataTableLogicalName_W(Self: TDADataTable; const T: string);
begin
  Self.LogicalName := T;
end;

procedure TDADataTableLogicalName_R(Self: TDADataTable; var T: string);
begin
  T := Self.LogicalName;
end;

procedure TDADataTableFilter_W(Self: TDADataTable; const T: string);
begin
  Self.Filter := T;
end;

procedure TDADataTableFilter_R(Self: TDADataTable; var T: string);
begin
  T := Self.Filter;
end;

procedure TDADataTableFiltered_W(Self: TDADataTable; const T: boolean);
begin
  Self.Filtered := T;
end;

procedure TDADataTableFiltered_R(Self: TDADataTable; var T: boolean);
begin
  T := Self.Filtered;
end;

procedure TDADataTableMasterOptions_W(Self: TDADataTable; const T: TDAMasterOptions);
begin
  Self.MasterOptions := T;
end;

procedure TDADataTableMasterOptions_R(Self: TDADataTable; var T: TDAMasterOptions);
begin
  T := Self.MasterOptions;
end;

procedure TDADataTableDetailOptions_W(Self: TDADataTable; const T: TDADetailOptions);
begin
  Self.DetailOptions := T;
end;

procedure TDADataTableDetailOptions_R(Self: TDADataTable; var T: TDADetailOptions);
begin
  T := Self.DetailOptions;
end;

procedure TDADataTableMasterRequestMappings_W(Self: TDADataTable; const T: TStrings);
begin
  Self.MasterRequestMappings := T;
end;

procedure TDADataTableMasterRequestMappings_R(Self: TDADataTable; var T: TStrings);
begin
  T := Self.MasterRequestMappings;
end;

procedure TDADataTableDetailFields_W(Self: TDADataTable; const T: string);
begin
  Self.DetailFields := T;
end;

procedure TDADataTableDetailFields_R(Self: TDADataTable; var T: string);
begin
  T := Self.DetailFields;
end;

procedure TDADataTableMasterFields_W(Self: TDADataTable; const T: string);
begin
  Self.MasterFields := T;
end;

procedure TDADataTableMasterFields_R(Self: TDADataTable; var T: string);
begin
  T := Self.MasterFields;
end;

procedure TDADataTableRemoteFetchEnabled_W(Self: TDADataTable; const T: boolean);
begin
  Self.RemoteFetchEnabled := T;
end;

procedure TDADataTableRemoteFetchEnabled_R(Self: TDADataTable; var T: boolean);
begin
  T := Self.RemoteFetchEnabled;
end;

procedure TDADataTableLogChanges_W(Self: TDADataTable; const T: boolean);
begin
  Self.LogChanges := T;
end;

procedure TDADataTableLogChanges_R(Self: TDADataTable; var T: boolean);
begin
  T := Self.LogChanges;
end;

procedure TDADataTableParams_W(Self: TDADataTable; const T: TDAParamCollection);
begin
  Self.Params := T;
end;

procedure TDADataTableParams_R(Self: TDADataTable; var T: TDAParamCollection);
begin
  T := Self.Params;
end;

procedure TDADataTableFields_W(Self: TDADataTable; const T: TDAFieldCollection);
begin
  Self.Fields := T;
end;

procedure TDADataTableFields_R(Self: TDADataTable; var T: TDAFieldCollection);
begin
  T := Self.Fields;
end;

procedure TDADataTableActive_W(Self: TDADataTable; const T: boolean);
begin
  Self.Active := T;
end;

procedure TDADataTableActive_R(Self: TDADataTable; var T: boolean);
begin
  T := Self.Active;
end;

procedure TDAParamCollectionHasInputParams_R(Self: TDAParamCollection; var T: boolean);
begin
  T := Self.HasInputParams;
end;

procedure TDAParamCollectionParams_W(Self: TDAParamCollection; const T: TDAParam; const t1: integer);
begin
  Self.Params[t1] := T;
end;

procedure TDAParamCollectionParams_R(Self: TDAParamCollection; var T: TDAParam; const t1: integer);
begin
  T := Self.Params[t1];
end;

procedure TDAParamParamType_W(Self: TDAParam; const T: TDAParamType);
begin
  Self.ParamType := T;
end;

procedure TDAParamParamType_R(Self: TDAParam; var T: TDAParamType);
begin
  T := Self.ParamType;
end;

procedure TDAFieldCollectionFields_W(Self: TDAFieldCollection; const T: TDAField; const t1: integer);
begin
  Self.Fields[t1] := T;
end;

procedure TDAFieldCollectionFields_R(Self: TDAFieldCollection; var T: TDAField; const t1: integer);
begin
  T := Self.Fields[t1];
end;

procedure TDACustomFieldCollectionFields_W(Self: TDACustomFieldCollection; const T: TDACustomField; const t1: integer);
begin
  Self.Fields[t1] := T;
end;

procedure TDACustomFieldCollectionFields_R(Self: TDACustomFieldCollection; var T: TDACustomField; const t1: integer);
begin
  T := Self.Fields[t1];
end;

procedure TDACustomFieldCollectionDataDictionary_W(Self: TDACustomFieldCollection; const T: IDADataDictionary);
begin
  Self.DataDictionary := T;
end;

procedure TDACustomFieldCollectionDataDictionary_R(Self: TDACustomFieldCollection; var T: IDADataDictionary);
begin
  T := Self.DataDictionary;
end;

procedure TDACustomFieldCollectionFieldEventsDisabled_W(Self: TDACustomFieldCollection; const T: boolean);
begin
  Self.FieldEventsDisabled := T;
end;

procedure TDACustomFieldCollectionFieldEventsDisabled_R(Self: TDACustomFieldCollection; var T: boolean);
begin
  T := Self.FieldEventsDisabled;
end;

procedure TDACustomFieldAlignment_W(Self: TDACustomField; const T: TAlignment);
begin
  Self.Alignment := T;
end;

procedure TDACustomFieldAlignment_R(Self: TDACustomField; var T: TAlignment);
begin
  T := Self.Alignment;
end;

procedure TDACustomFieldEditFormat_W(Self: TDACustomField; const T: string);
begin
  Self.EditFormat := T;
end;

procedure TDACustomFieldEditFormat_R(Self: TDACustomField; var T: string);
begin
  T := Self.EditFormat;
end;

procedure TDACustomFieldBusinessRulesID_W(Self: TDACustomField; const T: string);
begin
  Self.BusinessClassID := T;
end;

procedure TDACustomFieldBusinessRulesID_R(Self: TDACustomField; var T: string);
begin
  T := Self.BusinessClassID;
end;

procedure TDACustomFieldDisplayFormat_W(Self: TDACustomField; const T: string);
begin
  Self.DisplayFormat := T;
end;

procedure TDACustomFieldDisplayFormat_R(Self: TDACustomField; var T: string);
begin
  T := Self.DisplayFormat;
end;

procedure TDACustomFieldCustomAttributes_W(Self: TDACustomField; const T: TStrings);
begin
  Self.CustomAttributes := T;
end;

procedure TDACustomFieldCustomAttributes_R(Self: TDACustomField; var T: TStrings);
begin
  T := Self.CustomAttributes;
end;

procedure TDACustomFieldReadOnly_W(Self: TDACustomField; const T: boolean);
begin
  Self.ReadOnly := T;
end;

procedure TDACustomFieldReadOnly_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.ReadOnly;
end;

procedure TDACustomFieldVisible_W(Self: TDACustomField; const T: boolean);
begin
  Self.Visible := T;
end;

procedure TDACustomFieldVisible_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.Visible;
end;

procedure TDACustomFieldEditMask_W(Self: TDACustomField; const T: string);
begin
  Self.EditMask := T;
end;

procedure TDACustomFieldEditMask_R(Self: TDACustomField; var T: string);
begin
  T := Self.EditMask;
end;

procedure TDACustomFieldDisplayLabel_W(Self: TDACustomField; const T: string);
begin
  Self.DisplayLabel := T;
end;

procedure TDACustomFieldDisplayLabel_R(Self: TDACustomField; var T: string);
begin
  T := Self.DisplayLabel;
end;

procedure TDACustomFieldDisplayWidth_W(Self: TDACustomField; const T: integer);
begin
  Self.DisplayWidth := T;
end;

procedure TDACustomFieldDisplayWidth_R(Self: TDACustomField; var T: integer);
begin
  T := Self.DisplayWidth;
end;

procedure TDACustomFieldRequired_W(Self: TDACustomField; const T: boolean);
begin
  Self.Required := T;
end;

procedure TDACustomFieldRequired_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.Required;
end;

procedure TDACustomFieldDefaultValue_W(Self: TDACustomField; const T: string);
begin
  Self.DefaultValue := T;
end;

procedure TDACustomFieldDefaultValue_R(Self: TDACustomField; var T: string);
begin
  T := Self.DefaultValue;
end;

procedure TDACustomFieldRegExpression_W(Self: TDACustomField; const T: string);
begin
  Self.RegExpression := T;
end;

procedure TDACustomFieldRegExpression_R(Self: TDACustomField; var T: string);
begin
  T := Self.RegExpression;
end;

procedure TDACustomFieldLogChanges_W(Self: TDACustomField; const T: boolean);
begin
  Self.LogChanges := T;
end;

procedure TDACustomFieldLogChanges_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.LogChanges;
end;

procedure TDACustomFieldLookupCache_W(Self: TDACustomField; const T: boolean);
begin
  Self.LookupCache := T;
end;

procedure TDACustomFieldLookupCache_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.LookupCache;
end;

procedure TDACustomFieldKeyFields_W(Self: TDACustomField; const T: string);
begin
  Self.KeyFields := T;
end;

procedure TDACustomFieldKeyFields_R(Self: TDACustomField; var T: string);
begin
  T := Self.KeyFields;
end;

procedure TDACustomFieldLookupResultField_W(Self: TDACustomField; const T: string);
begin
  Self.LookupResultField := T;
end;

procedure TDACustomFieldLookupResultField_R(Self: TDACustomField; var T: string);
begin
  T := Self.LookupResultField;
end;

procedure TDACustomFieldLookupKeyFields_W(Self: TDACustomField; const T: string);
begin
  Self.LookupKeyFields := T;
end;

procedure TDACustomFieldLookupKeyFields_R(Self: TDACustomField; var T: string);
begin
  T := Self.LookupKeyFields;
end;

procedure TDACustomFieldLookupSource_W(Self: TDACustomField; const T: TDataSource);
begin
  Self.LookupSource := T;
end;

procedure TDACustomFieldLookupSource_R(Self: TDACustomField; var T: TDataSource);
begin
  T := Self.LookupSource;
end;

procedure TDACustomFieldLookup_W(Self: TDACustomField; const T: boolean);
begin
  Self.Lookup := T;
end;

procedure TDACustomFieldLookup_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.Lookup;
end;

procedure TDACustomFieldCalculated_W(Self: TDACustomField; const T: boolean);
begin
  Self.Calculated := T;
end;

procedure TDACustomFieldCalculated_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.Calculated;
end;

procedure TDACustomFieldInPrimaryKey_W(Self: TDACustomField; const T: boolean);
begin
  Self.InPrimaryKey := T;
end;

procedure TDACustomFieldInPrimaryKey_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.InPrimaryKey;
end;

procedure TDACustomFieldIsNull_R(Self: TDACustomField; var T: boolean);
begin
  T := Self.IsNull;
end;

procedure TDACustomFieldTableField_W(Self: TDACustomField; const T: string);
begin
  Self.TableField := T;
end;

procedure TDACustomFieldTableField_R(Self: TDACustomField; var T: string);
begin
  T := Self.TableField;
end;

procedure TDACustomFieldFieldCollection_R(Self: TDACustomField; var T: TDACustomFieldCollection);
begin
  T := Self.FieldCollection;
end;

procedure TDABaseFieldBlobType_W(Self: TDABaseField; const T: TDABlobType);
begin
  Self.BlobType := T;
end;

procedure TDABaseFieldBlobType_R(Self: TDABaseField; var T: TDABlobType);
begin
  T := Self.BlobType;
end;

procedure TDABaseFieldDescription_W(Self: TDABaseField; const T: string);
begin
  Self.Description := T;
end;

procedure TDABaseFieldDescription_R(Self: TDABaseField; var T: string);
begin
  T := Self.Description;
end;

procedure TDABaseFieldSize_W(Self: TDABaseField; const T: integer);
begin
  Self.Size := T;
end;

procedure TDABaseFieldSize_R(Self: TDABaseField; var T: integer);
begin
  T := Self.Size;
end;

procedure TDABaseFieldDataType_W(Self: TDABaseField; const T: TDADataType);
begin
  Self.DataType := T;
end;

procedure TDABaseFieldDataType_R(Self: TDABaseField; var T: TDADataType);
begin
  T := Self.DataType;
end;

procedure TDABaseFieldName_W(Self: TDABaseField; const T: string);
begin
  Self.Name := T;
end;

procedure TDABaseFieldName_R(Self: TDABaseField; var T: string);
begin
  T := Self.Name;
end;

procedure TDABaseFieldDictionaryEntry_W(Self: TDABaseField; const T: string);
begin
  Self.DictionaryEntry := T;
end;

procedure TDABaseFieldDictionaryEntry_R(Self: TDABaseField; var T: string);
begin
  T := Self.DictionaryEntry;
end;

procedure TDABaseFieldAsVariant_W(Self: TDABaseField; const T: variant);
begin
  Self.AsVariant := T;
end;

procedure TDABaseFieldAsVariant_R(Self: TDABaseField; var T: variant);
begin
  T := Self.AsVariant;
end;

procedure TDABaseFieldAsString_W(Self: TDABaseField; const T: string);
begin
  Self.AsString := T;
end;

procedure TDABaseFieldAsString_R(Self: TDABaseField; var T: string);
begin
  T := Self.AsString;
end;

procedure TDABaseFieldAsInteger_W(Self: TDABaseField; const T: integer);
begin
  Self.AsInteger := T;
end;

procedure TDABaseFieldAsInteger_R(Self: TDABaseField; var T: integer);
begin
  T := Self.AsInteger;
end;

procedure TDABaseFieldAsFloat_W(Self: TDABaseField; const T: double);
begin
  Self.AsFloat := T;
end;

procedure TDABaseFieldAsFloat_R(Self: TDABaseField; var T: double);
begin
  T := Self.AsFloat;
end;

procedure TDABaseFieldAsDateTime_W(Self: TDABaseField; const T: TDateTime);
begin
  Self.AsDateTime := T;
end;

procedure TDABaseFieldAsDateTime_R(Self: TDABaseField; var T: TDateTime);
begin
  T := Self.AsDateTime;
end;

procedure TDABaseFieldAsCurrency_W(Self: TDABaseField; const T: currency);
begin
  Self.AsCurrency := T;
end;

procedure TDABaseFieldAsCurrency_R(Self: TDABaseField; var T: currency);
begin
  T := Self.AsCurrency;
end;

procedure TDABaseFieldAsBoolean_W(Self: TDABaseField; const T: boolean);
begin
  Self.AsBoolean := T;
end;

procedure TDABaseFieldAsBoolean_R(Self: TDABaseField; var T: boolean);
begin
  T := Self.AsBoolean;
end;

procedure TDABaseFieldValue_W(Self: TDABaseField; const T: Variant);
begin
  Self.Value := T;
end;

procedure TDABaseFieldValue_R(Self: TDABaseField; var T: Variant);
begin
  T := Self.Value;
end;

procedure TDADataTableState_R(Self: TDADataTable; var T: TDataSetState);
begin
  T := Self.State;
end;

procedure RIRegister_TDADataTable(CL: TIFPSRuntimeClassImporter);
var
  lc:TPSRuntimeClass;
begin
  lc := CL.Add(TDADataTable);
  lc.RegisterPropertyHelper(@TDADataTableActive_R, @TDADataTableActive_W, 'Active');
  lc.RegisterPropertyHelper(@TDADataTableFields_R, @TDADataTableFields_W, 'Fields');
  lc.RegisterPropertyHelper(@TDADataTableParams_R, @TDADataTableParams_W, 'Params');
  lc.RegisterPropertyHelper(@TDADataTableLogChanges_R, @TDADataTableLogChanges_W, 'LogChanges');
  lc.RegisterPropertyHelper(@TDADataTableRemoteFetchEnabled_R, @TDADataTableRemoteFetchEnabled_W, 'RemoteFetchEnabled');
  lc.RegisterPropertyHelper(@TDADataTableMasterFields_R, @TDADataTableMasterFields_W, 'MasterFields');
  lc.RegisterPropertyHelper(@TDADataTableDetailFields_R, @TDADataTableDetailFields_W, 'DetailFields');
  lc.RegisterPropertyHelper(@TDADataTableMasterRequestMappings_R, @TDADataTableMasterRequestMappings_W, 'MasterRequestMappings');
  lc.RegisterPropertyHelper(@TDADataTableDetailOptions_R, @TDADataTableDetailOptions_W, 'DetailOptions');
  lc.RegisterPropertyHelper(@TDADataTableMasterOptions_R, @TDADataTableMasterOptions_W, 'MasterOptions');
  lc.RegisterPropertyHelper(@TDADataTableFiltered_R, @TDADataTableFiltered_W, 'Filtered');
  lc.RegisterPropertyHelper(@TDADataTableFilter_R, @TDADataTableFilter_W, 'Filter');
  lc.RegisterPropertyHelper(@TDADataTableLogicalName_R, @TDADataTableLogicalName_W, 'LogicalName');
  lc.RegisterPropertyHelper(@TDADataTableBusinessRulesID_R, @TDADataTableBusinessRulesID_W, 'BusinessRulesID');
  lc.RegisterPropertyHelper(@TDADataTableState_R, nil, 'State');
end;

procedure RIRegister_TDAParamCollection(CL: TIFPSRuntimeClassImporter);
var
  lc:TPSRuntimeClass;
begin
  lc := CL.Add(TDAParamCollection);
  lc.RegisterConstructor(@TDAParamCollection.Create, 'Create');
  lc.RegisterMethod(@TDAParamCollection.WriteValues, 'WriteValues');
  lc.RegisterMethod(@TDAParamCollection.ReadValues, 'ReadValues');
  lc.RegisterMethod(@TDAParamCollection.Add, 'Add');
  lc.RegisterMethod(@TDAParamCollection.ParamByName, 'ParamByName');
  lc.RegisterMethod(@TDAParamCollection.FindParam, 'FindParam');
  lc.RegisterMethod(@TDAParamCollection.AssignParamCollection, 'AssignParamCollection');
  lc.RegisterPropertyHelper(@TDAParamCollectionParams_R, @TDAParamCollectionParams_W, 'Params');
  lc.RegisterPropertyHelper(@TDAParamCollectionHasInputParams_R, nil, 'HasInputParams');
end;

procedure RIRegister_TDAParam(CL: TIFPSRuntimeClassImporter);
var
  lc:TPSRuntimeClass;
begin
  lc := CL.Add(TDAParam);
  lc.RegisterMethod(@TDAParam.SaveToStream, 'SaveToStream');
  lc.RegisterMethod(@TDAParam.LoadFromStream, 'LoadFromStream');
  lc.RegisterMethod(@TDAParam.SaveToFile, 'SaveToFile');
  lc.RegisterMethod(@TDAParam.LoadFromFile, 'LoadFromFile');
  lc.RegisterPropertyHelper(@TDAParamParamType_R, @TDAParamParamType_W, 'ParamType');
end;

procedure RIRegister_TDAFieldCollection(CL: TIFPSRuntimeClassImporter);
var
  lc:TPSRuntimeClass;
begin
  lc := CL.Add(TDAFieldCollection);
  lc.RegisterConstructor(@TDAFieldCollection.Create, 'Create');
  lc.RegisterMethod(@TDAFieldCollection.FieldByName, 'FieldByName');
  lc.RegisterMethod(@TDAFieldCollection.FindField, 'FindField');
  lc.RegisterPropertyHelper(@TDAFieldCollectionFields_R, @TDAFieldCollectionFields_W, 'Fields');
end;

procedure RIRegister_TDACustomFieldCollection(CL: TIFPSRuntimeClassImporter);
var
  lc:TPSRuntimeClass;
begin
  lc := CL.Add(TDACustomFieldCollection);
  lc.RegisterMethod(@TDACustomFieldCollection.Bind, 'Bind');
  lc.RegisterMethod(@TDACustomFieldCollection.Unbind, 'Unbind');
  lc.RegisterPropertyHelper(@TDACustomFieldCollectionFieldEventsDisabled_R, @TDACustomFieldCollectionFieldEventsDisabled_W, 'FieldEventsDisabled');
  lc.RegisterMethod(@TDACustomFieldCollection.AssignFieldCollection, 'AssignFieldCollection');
  lc.RegisterMethod(@TDACustomFieldCollection.FieldByName, 'FieldByName');
  lc.RegisterMethod(@TDACustomFieldCollection.FindField, 'FindField');
  lc.RegisterMethod(@TDACustomFieldCollection.MoveItem, 'MoveItem');
  lc.RegisterPropertyHelper(@TDACustomFieldCollectionDataDictionary_R, @TDACustomFieldCollectionDataDictionary_W, 'DataDictionary');
  lc.RegisterPropertyHelper(@TDACustomFieldCollectionFields_R, @TDACustomFieldCollectionFields_W, 'Fields');
end;

procedure RIRegister_TDADataDictionaryField(CL: TIFPSRuntimeClassImporter);
begin
  CL.Add(TDADataDictionaryField);
end;

procedure RIRegister_TDAField(CL: TIFPSRuntimeClassImporter);
begin
  CL.Add(TDAField);
end;

procedure RIRegister_TDACustomField(CL: TIFPSRuntimeClassImporter);
var
  lc:TPSRuntimeClass;
begin
  lc := CL.Add(TDACustomField);
  lc.RegisterMethod(@TDACustomField.Bind, 'Bind');
  lc.RegisterMethod(@TDACustomField.Unbind, 'Unbind');
  lc.RegisterMethod(@TDACustomField.SaveToStream, 'SaveToStream');
  lc.RegisterMethod(@TDACustomField.LoadFromStream, 'LoadFromStream');
  lc.RegisterMethod(@TDACustomField.SaveToFile, 'SaveToFile');
  lc.RegisterMethod(@TDACustomField.LoadFromFile, 'LoadFromFile');
  lc.RegisterPropertyHelper(@TDACustomFieldFieldCollection_R, nil, 'FieldCollection');
  lc.RegisterPropertyHelper(@TDACustomFieldTableField_R, @TDACustomFieldTableField_W, 'TableField');
  lc.RegisterPropertyHelper(@TDACustomFieldIsNull_R, nil, 'IsNull');
  lc.RegisterPropertyHelper(@TDACustomFieldInPrimaryKey_R, @TDACustomFieldInPrimaryKey_W, 'InPrimaryKey');
  lc.RegisterPropertyHelper(@TDACustomFieldCalculated_R, @TDACustomFieldCalculated_W, 'Calculated');
  lc.RegisterPropertyHelper(@TDACustomFieldLookup_R, @TDACustomFieldLookup_W, 'Lookup');
  lc.RegisterPropertyHelper(@TDACustomFieldLookupSource_R, @TDACustomFieldLookupSource_W, 'LookupSource');
  lc.RegisterPropertyHelper(@TDACustomFieldLookupKeyFields_R, @TDACustomFieldLookupKeyFields_W, 'LookupKeyFields');
  lc.RegisterPropertyHelper(@TDACustomFieldLookupResultField_R, @TDACustomFieldLookupResultField_W, 'LookupResultField');
  lc.RegisterPropertyHelper(@TDACustomFieldKeyFields_R, @TDACustomFieldKeyFields_W, 'KeyFields');
  lc.RegisterPropertyHelper(@TDACustomFieldLookupCache_R, @TDACustomFieldLookupCache_W, 'LookupCache');
  lc.RegisterPropertyHelper(@TDACustomFieldLogChanges_R, @TDACustomFieldLogChanges_W, 'LogChanges');
  lc.RegisterPropertyHelper(@TDACustomFieldRegExpression_R, @TDACustomFieldRegExpression_W, 'RegExpression');
  lc.RegisterPropertyHelper(@TDACustomFieldDefaultValue_R, @TDACustomFieldDefaultValue_W, 'DefaultValue');
  lc.RegisterPropertyHelper(@TDACustomFieldRequired_R, @TDACustomFieldRequired_W, 'Required');
  lc.RegisterPropertyHelper(@TDACustomFieldDisplayWidth_R, @TDACustomFieldDisplayWidth_W, 'DisplayWidth');
  lc.RegisterPropertyHelper(@TDACustomFieldDisplayLabel_R, @TDACustomFieldDisplayLabel_W, 'DisplayLabel');
  lc.RegisterPropertyHelper(@TDACustomFieldEditMask_R, @TDACustomFieldEditMask_W, 'EditMask');
  lc.RegisterPropertyHelper(@TDACustomFieldVisible_R, @TDACustomFieldVisible_W, 'Visible');
  lc.RegisterPropertyHelper(@TDACustomFieldReadOnly_R, @TDACustomFieldReadOnly_W, 'ReadOnly');
  lc.RegisterPropertyHelper(@TDACustomFieldCustomAttributes_R, @TDACustomFieldCustomAttributes_W, 'CustomAttributes');
  lc.RegisterPropertyHelper(@TDACustomFieldDisplayFormat_R, @TDACustomFieldDisplayFormat_W, 'DisplayFormat');
  lc.RegisterPropertyHelper(@TDACustomFieldBusinessRulesID_R, @TDACustomFieldBusinessRulesID_W, 'BusinessRulesID');
  lc.RegisterPropertyHelper(@TDACustomFieldEditFormat_R, @TDACustomFieldEditFormat_W, 'EditFormat');
  lc.RegisterPropertyHelper(@TDACustomFieldAlignment_R, @TDACustomFieldAlignment_W, 'Alignment');
end;

procedure RIRegister_TDABaseField(CL: TIFPSRuntimeClassImporter);
var
  lc:TPSRuntimeClass;
begin
  lc := CL.Add(TDABaseField);
  lc.RegisterPropertyHelper(@TDABaseFieldValue_R, @TDABaseFieldValue_W, 'Value');
  lc.RegisterVirtualMethod(@TDABaseField.AssignField, 'AssignField');
  lc.RegisterMethod(@TDABaseField.HasValidDictionaryField, 'HasValidDictionaryField');
  lc.RegisterPropertyHelper(@TDABaseFieldAsBoolean_R, @TDABaseFieldAsBoolean_W, 'AsBoolean');
  lc.RegisterPropertyHelper(@TDABaseFieldAsCurrency_R, @TDABaseFieldAsCurrency_W, 'AsCurrency');
  lc.RegisterPropertyHelper(@TDABaseFieldAsDateTime_R, @TDABaseFieldAsDateTime_W, 'AsDateTime');
  lc.RegisterPropertyHelper(@TDABaseFieldAsFloat_R, @TDABaseFieldAsFloat_W, 'AsFloat');
  lc.RegisterPropertyHelper(@TDABaseFieldAsInteger_R, @TDABaseFieldAsInteger_W, 'AsInteger');
  lc.RegisterPropertyHelper(@TDABaseFieldAsString_R, @TDABaseFieldAsString_W, 'AsString');
  lc.RegisterPropertyHelper(@TDABaseFieldAsVariant_R, @TDABaseFieldAsVariant_W, 'AsVariant');
  lc.RegisterPropertyHelper(@TDABaseFieldDictionaryEntry_R, @TDABaseFieldDictionaryEntry_W, 'DictionaryEntry');
  lc.RegisterPropertyHelper(@TDABaseFieldName_R, @TDABaseFieldName_W, 'Name');
  lc.RegisterPropertyHelper(@TDABaseFieldDataType_R, @TDABaseFieldDataType_W, 'DataType');
  lc.RegisterPropertyHelper(@TDABaseFieldSize_R, @TDABaseFieldSize_W, 'Size');
  lc.RegisterPropertyHelper(@TDABaseFieldDescription_R, @TDABaseFieldDescription_W, 'Description');
  lc.RegisterPropertyHelper(@TDABaseFieldBlobType_R, @TDABaseFieldBlobType_W, 'BlobType');
end;

procedure RIRegister_uDA(CL: TIFPSRuntimeClassImporter);
begin
  RIRegister_TDABaseField(CL);
  RIRegister_TDACustomField(CL);
  RIRegister_TDAField(CL);
  RIRegister_TDADataDictionaryField(CL);
  RIRegister_TDACustomFieldCollection(CL);
  RIRegister_TDAFieldCollection(CL);
  RIRegister_TDAParam(CL);
  RIRegister_TDAParamCollection(CL);
  RIRegister_TDADataTable(CL);
end;

{ TDAPSDataTableRulesPlugin }

function PSNewGuid: string;
begin
  result := NewGuidAsString();
end;

procedure PSRaiseError(const aMsg: string);
begin
  raise EDAScriptError.Create(aMsg);
end;

procedure PSAbort;
begin
  Abort;
end;

procedure TDAPSDataTableRulesPlugin.CompileImport1(CompExec: TPSScript);
begin
  fScriptEngine := CompExec;
  SIRegister_uDA(CompExec.Comp);
  CompExec.AddRegisteredVariable('Table', 'TDADataTable');
  CompExec.AddFunction(@ShowMessage,'procedure ShowMessage(const Msg: string);');
  CompExec.AddFunction(@PSRaiseError,'procedure RaiseError(const aMsg: string);');
  CompExec.AddFunction(@PSAbort,'procedure Abort;');
  CompExec.AddFunction(@PSNewGuid,'function NewGuid: string;');
end;

procedure TDAPSDataTableRulesPlugin.CompOnUses(CompExec: TPSScript);
begin
  fScriptEngine := CompExec;
end;

procedure TDAPSDataTableRulesPlugin.ExecImport2(CompExec: TPSScript;
  const ri: TPSRuntimeClassImporter);
begin
  fScriptEngine := CompExec;
  RIRegister_uDA(ri);
  CompExec.SetVarToInstance('Table', fDataTable);
end;

procedure TDAPSDataTableRulesPlugin.SetDataTable(
  const Value: TDADataTable);
begin
  fDataTable := Value;
  if (fScriptEngine <> nil) then
    fScriptEngine.SetVarToInstance('Table', fDataTable);
end;

{ TDAPSDataTableRules }

procedure TDAPSDataTableRules.AfterCancel(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterCancel');
end;

procedure TDAPSDataTableRules.AfterClose(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterClose');
end;

procedure TDAPSDataTableRules.AfterDelete(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterDelete');
end;

procedure TDAPSDataTableRules.AfterEdit(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterEdit');
end;

procedure TDAPSDataTableRules.AfterInsert(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterInsert');
end;

procedure TDAPSDataTableRules.AfterOpen(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterOpen');
end;

procedure TDAPSDataTableRules.AfterPost(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterPost');
end;

procedure TDAPSDataTableRules.AfterRefresh(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterRefresh');
end;

procedure TDAPSDataTableRules.AfterScroll(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'AfterScroll');
end;

procedure TDAPSDataTableRules.BeforeCancel(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeCancel');
end;

procedure TDAPSDataTableRules.BeforeClose(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeClose');
end;

procedure TDAPSDataTableRules.BeforeDelete(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeDelete');
end;

procedure TDAPSDataTableRules.BeforeEdit(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeEdit');
end;

procedure TDAPSDataTableRules.BeforeInsert(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeInsert');
end;

procedure TDAPSDataTableRules.BeforeOpen(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeOpen');
end;

procedure TDAPSDataTableRules.BeforePost(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforePost');
end;

procedure TDAPSDataTableRules.BeforeRefresh(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeRefresh');
end;

procedure TDAPSDataTableRules.BeforeScroll(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'BeforeScroll');
end;

procedure TDAPSDataTableRules.ExecuteProc(Dataset: TDADataTable;
  const Name: tbtstring);
var
  ProcNo: Cardinal;
begin
  if FSE = nil then raise Exception.Create('No script engine attached');
  Setup(Dataset);
  ProcNo := FSE.Exec.GetProc(Name);
  if ProcNo <> InvalidVal then {// Nothing to do} begin
    FSE.Exec.RunProc(nil, ProcNo);
    FSE.Exec.RaiseCurrentException;
  end;
end;

procedure TDAPSDataTableRules.OnCalcFields(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'OnCalcFields');
end;

procedure TDAPSDataTableRules.OnNewRecord(Sender: TDADataTable);
begin
  ExecuteProc(Sender, 'OnNewRecord');
end;

procedure TDAPSDataTableRules.SetSE(const Value: TPSScript);
var
  lPlugin: TPSPlugin;
  i: Integer;
begin
  if Value = nil then begin
    FSE := nil
  end
  else begin
    // ToDo: use GetPlugin() lateron.
    lPlugin := nil;
    for i := 0 to Value.Plugins.Count-1 do begin
      if Assigned(Value.Plugins.Items[i]) and ((Value.Plugins.Items[i] as TPSPluginItem).Plugin is TDAPSDataTableRulesPlugin) then
        lPlugin := (Value.Plugins.Items[i] as TPSPluginItem).Plugin;
    end; { for }
    if lPlugin = nil then begin
      FSE := nil;
      raise Exception.Create('No TDAPSDataTableRulesPlugin plugin attached to the script engine.');
    end;
    FSE := Value;
  end;
end;

procedure TDAPSDataTableRules.Setup(const Dataset: TDADataTable);
begin
  FSE.SetVarToInstance('Table', Dataset);
end;

end.

