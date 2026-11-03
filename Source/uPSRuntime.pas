unit uPSRuntime;
{$I PascalScript.inc}
{

RemObjects Pascal Script III
Copyright (C) 2000-2009 by Carlo Kok (ck@carlo-kok.com)

}

interface
uses
  {$IFNDEF FPC} {$IFDEF DELPHIXE2UP} System.Rtti,{$ELSE}{$IFDEF DELPHI2010UP} Rtti,{$ENDIF}{$ENDIF} {$ENDIF}
  {$IFDEF FPC}{$IFDEF USEINVOKECALL}Rtti,{$ENDIF}{$ENDIF}
  SysUtils, uPSUtils{$IFDEF DELPHI6UP}, variants{$ENDIF}
  {$IFNDEF PS_NOIDISPATCH}{$IFDEF DELPHI3UP}, ActiveX, Windows{$ELSE}, Ole2{$ENDIF}{$ENDIF};


type
  TPSExec = class;
  TPSStack = class;
  TPSRuntimeAttributes = class;
  TPSRuntimeAttribute = class;

  TPSError = (ErNoError, erCannotImport, erInvalidType, ErInternalError,
    erInvalidHeader, erInvalidOpcode, erInvalidOpcodeParameter, erNoMainProc,
    erOutOfGlobalVarsRange, erOutOfProcRange, ErOutOfRange, erOutOfStackRange,
    ErTypeMismatch, erUnexpectedEof, erVersionError, ErDivideByZero, ErMathError,
    erCouldNotCallProc, erOutofRecordRange, erOutOfMemory, erException,
    erNullPointerException, erNullVariantError, erInterfaceNotSupported, erCustomError);

  TPSStatus = (isNotLoaded, isLoaded, isRunning, isPaused);

  PByteArray = ^TByteArray;

  TByteArray = array[0..1023] of Byte;

  PDWordArray = ^TDWordArray;

  TDWordArray = array[0..1023] of Cardinal;
  TPSProcRec = class;
  TPSExternalProcRec = class;
  PProcRec = ^TProcRec;

  TPSProcPtr = function(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;

  TPSFreeProc = procedure (Caller: TPSExec; p: PProcRec);

  TPSProcRec = class
  private
    FAttributes: TPSRuntimeAttributes;
  public

    constructor Create(Owner: TPSExec);

    destructor Destroy; override;


    property Attributes: TPSRuntimeAttributes read FAttributes;
  end;

  { The aliases follow the class bodies: XE3 and XE4 emit an alias declared before its class body into the C++
    header without its closing semicolon. }
  TIFProcRec = TPSProcRec;
{@link(TPSProcRec)
  PIFProcRec is a pointer to a TIProcRec record}
  PIFProcRec = TPSProcRec;

  TPSExternalProcRec = class(TPSProcRec)
  private
    FExt1: Pointer;
    FExt2: Pointer;
    FName: tbtstring;
    FProcPtr: TPSProcPtr;
    FDecl: tbtstring;
  public

    property Name: tbtstring read FName write FName;

    property Decl: tbtstring read FDecl write FDecl;

    property Ext1: Pointer read FExt1 write FExt1;

    property Ext2: Pointer read FExt2 write FExt2;

    property ProcPtr: TPSProcPtr read FProcPtr write FProcPtr;
  end;

  TIFPSExternalProcRec = TPSExternalProcRec;
  TIFExternalProcRec = TPSExternalProcRec;

  TPSInternalProcRec = class(TPSProcRec)
  private
    FData: PByteArray;
    FLength: Cardinal;
    FExportNameHash: Longint;
    FExportDecl: tbtstring;
    FExportName: tbtstring;
  public

    property Data: PByteArray read FData;

    property Length: Cardinal read FLength;

    property ExportNameHash: Longint read FExportNameHash;

    property ExportName: tbtstring read FExportName write FExportName;

    property ExportDecl: tbtstring read FExportDecl write FExportDecl;


    destructor Destroy; override;
  end;

  TProcRec = record

    Name: ShortString;

    Hash: Longint;

    ProcPtr: TPSProcPtr;

    FreeProc: TPSFreeProc;

    Ext1, Ext2: Pointer;
  end;

  PBTReturnAddress = ^TBTReturnAddress;

  TBTReturnAddress = packed record

    ProcNo: TPSInternalProcRec;

    Position, StackBase: Cardinal;
  end;

  TPSTypeRec = class
  private
    FExportNameHash: Longint;
    FExportName: tbtstring;
    FBaseType: TPSBaseType;
    FAttributes: TPSRuntimeAttributes;
  protected
    FRealSize: Cardinal;
  public

    property RealSize: Cardinal read FRealSize;

    property BaseType: TPSBaseType read FBaseType write FBaseType;

    property ExportName: tbtstring read FExportName write FExportName;

    property ExportNameHash: Longint read FExportNameHash write FExportNameHash;

    property Attributes: TPSRuntimeAttributes read FAttributes write FAttributes;

    procedure CalcSize; virtual;

    constructor Create(Owner: TPSExec);
    destructor Destroy; override;
  end;

  TPSTypeRec_ProcPtr = class(TPSTypeRec)
  private
    FParamInfo: tbtstring;
  public

    property ParamInfo: tbtstring read FParamInfo write FParamInfo;
    procedure CalcSize; override;
  end;
  PIFTypeRec = TPSTypeRec;

  TPSTypeRec_Class = class(TPSTypeRec)
  private
    FCN: tbtstring;
  public

    property CN: tbtstring read FCN write FCN;
  end;
{$IFNDEF PS_NOINTERFACES}

  TPSTypeRec_Interface = class(TPSTypeRec)
  private
    FGuid: TGUID;
  public

    property Guid: TGUID read FGuid write FGuid;
  end;
{$ENDIF}

  TPSTypeRec_Array = class(TPSTypeRec)
  private
    FArrayType: TPSTypeRec;
  public

    property ArrayType: TPSTypeRec read FArrayType write FArrayType;
    procedure CalcSize; override;
  end;

  TPSTypeRec_StaticArray = class(TPSTypeRec_Array)
  private
    FSize: Longint;
    FStartOffset: LongInt;
  public

    property Size: Longint read FSize write FSize;
    property StartOffset: LongInt read FStartOffset write FStartOffset;

    procedure CalcSize; override;
  end;

  TPSTypeRec_Set = class(TPSTypeRec)
  private
    FBitSize: Longint;
    FByteSize: Longint;
  public
    {The number of bytes this would require (same as realsize)}
    property aByteSize: Longint read FByteSize write FByteSize;
    property aBitSize: Longint read FBitSize write FBitSize;
    procedure CalcSize; override;
  end;

  TPSTypeRec_Record = class(TPSTypeRec)
  private
    FFieldTypes: TPSList;
    FRealFieldOffsets: TPSList;
  public

    property FieldTypes: TPSList read FFieldTypes;

    property RealFieldOffsets: TPSList read FRealFieldOffsets;

    procedure CalcSize; override;

    constructor Create(Owner: TPSExec);
    destructor Destroy; override;
  end;

  PPSVariant = ^TPSVariant;

  PIFVariant = PPSVariant;

  TPSVariant = packed record
    FType: TPSTypeRec;
  end;

  PPSVariantData = ^TPSVariantData;

  TPSVariantData = packed record
    VI: TPSVariant;
    Data: array[0..0] of Byte;
  end;

  PPSVariantU8 = ^TPSVariantU8;

  TPSVariantU8 = packed record
    VI: TPSVariant;
    Data: tbtU8;
  end;


  PPSVariantS8 = ^TPSVariantS8;

  TPSVariantS8 = packed record
    VI: TPSVariant;
    Data: tbts8;
  end;


  PPSVariantU16 = ^TPSVariantU16;

  TPSVariantU16 = packed record
    VI: TPSVariant;
    Data: tbtU16;
  end;


  PPSVariantS16 = ^TPSVariantS16;

  TPSVariantS16 = packed record
    VI: TPSVariant;
    Data: tbts16;
  end;


  PPSVariantU32 = ^TPSVariantU32;

  TPSVariantU32 = packed record
    VI: TPSVariant;
    Data: tbtU32;
  end;


  PPSVariantS32 = ^TPSVariantS32;

  TPSVariantS32 = packed record
    VI: TPSVariant;
    Data: tbts32;
  end;
{$IFNDEF PS_NOINT64}

  PPSVariantS64 = ^TPSVariantS64;

  TPSVariantS64 = packed record
    VI: TPSVariant;
    Data: tbts64;
  end;

  PPSVariantU64 = ^TPSVariantU64;

  TPSVariantU64 = packed record
    VI: TPSVariant;
    Data: tbtu64;
  end;
{$ENDIF}

  PPSVariantAChar = ^TPSVariantAChar;

  TPSVariantAChar = packed record
    VI: TPSVariant;
    Data: tbtChar;
  end;

{$IFNDEF PS_NOWIDESTRING}

  PPSVariantWChar = ^TPSVariantWChar;

  TPSVariantWChar = packed record
    VI: TPSVariant;
    Data: tbtWideChar;
  end;
{$ENDIF}

  PPSVariantAString = ^TPSVariantAString;

  TPSVariantAString = packed record
    VI: TPSVariant;
    Data: tbtString;
  end;

{$IFNDEF PS_NOWIDESTRING}

  PPSVariantWString = ^TPSVariantWString;

  TPSVariantWString = {$IFNDEF DELPHI2009UP}packed {$ENDIF}record
    VI: TPSVariant;
    Data: tbtWideString;
  end;

  PPSVariantUString = ^TPSVariantUString;

  TPSVariantUString = {$IFNDEF DELPHI2009UP}packed {$ENDIF}record
    VI: TPSVariant;
    Data: tbtunicodestring;
  end;

{$ENDIF}


  PPSVariantSingle = ^TPSVariantSingle;

  TPSVariantSingle = packed record
    VI: TPSVariant;
    Data: tbtsingle;
  end;


  PPSVariantDouble = ^TPSVariantDouble;

  TPSVariantDouble = packed record
    VI: TPSVariant;
    Data: tbtDouble;
  end;


  PPSVariantExtended = ^TPSVariantExtended;

  TPSVariantExtended = packed record
    VI: TPSVariant;
    Data: tbtExtended;
  end;


  PPSVariantCurrency = ^TPSVariantCurrency;

  TPSVariantCurrency = packed record
    VI: TPSVariant;
    Data: tbtCurrency;
  end;

  PPSVariantSet = ^TPSVariantSet;

  TPSVariantSet = packed record
    VI: TPSVariant;
    Data: array[0..0] of Byte;
  end;

{$IFNDEF PS_NOINTERFACES}

  PPSVariantInterface = ^TPSVariantInterface;

  TPSVariantInterface = packed record
    VI: TPSVariant;
    Data: IUnknown;
  end;
{$ENDIF}

  PPSVariantClass = ^TPSVariantClass;

  TPSVariantClass = packed record
    VI: TPSVariant;
    Data: TObject;
  end;


  PPSVariantRecord = ^TPSVariantRecord;

  TPSVariantRecord = packed record
    VI: TPSVariant;
    data: array[0..0] of byte;
  end;


  PPSVariantDynamicArray = ^TPSVariantDynamicArray;

  TPSVariantDynamicArray = packed record
    VI: TPSVariant;
    Data: Pointer;
  end;


  PPSVariantStaticArray = ^TPSVariantStaticArray;

  TPSVariantStaticArray = packed record
    VI: TPSVariant;
    data: array[0..0] of byte;
  end;


  PPSVariantPointer = ^TPSVariantPointer;

  TPSVariantPointer = packed record
    VI: TPSVariant;
    DataDest: Pointer;
    DestType: TPSTypeRec;
    FreeIt: LongBool;
  end;


  PPSVariantReturnAddress = ^TPSVariantReturnAddress;

  TPSVariantReturnAddress = packed record
    VI: TPSVariant;
    Addr: TBTReturnAddress;
  end;


  PPSVariantVariant = ^TPSVariantVariant;

  TPSVariantVariant = packed record
    VI: TPSVariant;
    Data: Variant;
  end;

  PPSVariantProcPtr = ^TPSVariantProcPtr;
  TPSVariantProcPtr = packed record
    VI: TPSVariant;
    ProcNo: Cardinal;
    Self: Pointer;
    Ptr: Pointer;
    {
      ProcNo = 0  means Self/Ptr become active (Ptr = nil means it's nil)
    }
  end;


  TPSVarFreeType = (
    vtNone,
    vtTempVar
    );

  TPSResultData = packed record
    P: Pointer;
    aType: TPSTypeRec;
    FreeType: TPSVarFreeType;
  end;


  PPSResource = ^TPSResource;

  TPSResource = record
    Proc: Pointer;
    P: Pointer;
  end;

  TPSAttributeUseProc = function (Sender: TPSExec; const AttribType: tbtstring; Attr: TPSRuntimeAttribute): Boolean;

  TPSAttributeType = class
  private
    FTypeName: tbtstring;
    FUseProc: TPSAttributeUseProc;
    FTypeNameHash: Longint;
  public

    property UseProc: TPSAttributeUseProc read FUseProc write FUseProc;

    property TypeName: tbtstring read FTypeName write FTypeName;

    property TypeNameHash: Longint read FTypeNameHash write FTypeNameHash;
  end;

  PClassItem = ^TClassItem;

  TClassItem = record

    FName: tbtstring;

    FNameHash: Longint;

    b: byte;
    case byte of
    0: (Ptr: Pointer);
    1: (PointerInList: Pointer);
    3: (FReadFunc, FWriteFunc: Pointer); {Property Helper}
    4: (Ptr2: Pointer);
    5: (PointerInList2: Pointer);
    6: (); {Property helper, like 3}
    7: (); {Property helper that will pass it's name}
  end;


  PPSVariantIFC = ^TPSVariantIFC;
  {Temporary variant into record}
  TPSVariantIFC = packed record
    Dta: Pointer;
    aType: TPSTypeRec;
    VarParam: Boolean;
  end;
  PIFPSVariantIFC = PPSVariantIFC;
  TIFPSVariantIFC = TPSVariantIFC;

  TPSRuntimeAttribute = class(TObject)
  private
    FValues: TPSStack;
    FAttribType: tbtstring;
    FOwner: TPSRuntimeAttributes;
    FAttribTypeHash: Longint;
    function GetValue(I: Longint): PIFVariant;
    function GetValueCount: Longint;
  public

    property Owner: TPSRuntimeAttributes read FOwner;

    property AttribType: tbtstring read FAttribType write FAttribType;

    property AttribTypeHash: Longint read FAttribTypeHash write FAttribTypeHash;

    property ValueCount: Longint read GetValueCount;

    property Value[I: Longint]: PIFVariant read GetValue;

    function AddValue(aType: TPSTypeRec): PPSVariant;

    procedure DeleteValue(i: Longint);

    procedure AdjustSize;


    constructor Create(Owner: TPSRuntimeAttributes);

    destructor Destroy; override;
  end;

  TPSRuntimeAttributes = class(TObject)
  private
    FAttributes: TPSList;
    FOwner: TPSExec;
    function GetCount: Longint;
    function GetItem(I: Longint): TPSRuntimeAttribute;
  public

    property Owner: TPSExec read FOwner;

    property Count: Longint read GetCount;

    property Items[I: Longint]: TPSRuntimeAttribute read GetItem; default;

    procedure Delete(I: Longint);

    function Add: TPSRuntimeAttribute;

    function FindAttribute(const Name: tbtstring): TPSRuntimeAttribute;


    constructor Create(AOwner: TPSExec);

    destructor Destroy; override;
  end;
  TPSOnGetNVariant = function (Sender: TPSExec; const Name: tbtstring): Variant;
  TPSOnSetNVariant = procedure (Sender: TPSExec; const Name: tbtstring; V: Variant);

  TPSOnLineEvent = procedure(Sender: TPSExec);

  TPSOnSpecialProcImport = function (Sender: TPSExec; p: TPSExternalProcRec; Tag: Pointer): Boolean;

  TPSOnException = procedure (Sender: TPSExec; ExError: TPSError; const ExParam: tbtstring; ExObject: TObject; ProcNo, Position: Cardinal);

  TPSExec = class(TObject)
  Private
    FOnGetNVariant: TPSOnGetNVariant;
    FOnSetNVariant: TPSOnSetNVariant;
    FId: Pointer;
    FJumpFlag: Boolean;
    FCallCleanup: Boolean;
    { the runs RunProc began, still going: a Stop in one of them leaves the
      stack below it to whatever began the run }
    FNestedRuns: Longint;
    FOnException: TPSOnException;
    function ReadData(var Data; Len: Cardinal): Boolean;
    function ReadLong(var b: Cardinal): Boolean;
    function DoCalc(var1, Var2: Pointer; var1Type, var2type: TPSTypeRec; CalcType: Cardinal): Boolean;
    function DoBooleanCalc(var1, Var2, into: Pointer; var1Type, var2type, intotype: TPSTypeRec; Cmd: Cardinal): Boolean;
    function SetVariantValue(dest, Src: Pointer; desttype, srctype: TPSTypeRec): Boolean;
    function ReadVariable(var Dest: TPSResultData; UsePointer: Boolean): Boolean;
    function DoBooleanNot(Dta: Pointer; aType: TPSTypeRec): Boolean;
    function DoMinus(Dta: Pointer; aType: TPSTypeRec): Boolean;
    function DoIntegerNot(Dta: Pointer; aType: TPSTypeRec): Boolean;
    procedure RegisterStandardProcs;
  Protected

    FReturnAddressType: TPSTypeRec;

    FVariantType: TPSTypeRec;

    FVariantArrayType: TPSTypeRec;

    FAttributeTypes: TPSList;

    FExceptionStack: TPSList;

    { the exceptions ExceptionProc has raised, wrapping: compared across a
      call, it tells whether the callee raised one }
    FRaisedCount: Cardinal;

    FResources: TPSList;

    FExportedVars: TPSList;

    FTypes: TPSList;

    FProcs: TPSList;

    FGlobalVars: TPSStack;

    FTempVars: TPSStack;

    FStack: TPSStack;

    FMainProc: Cardinal;

    FStatus: TPSStatus;

    FCurrProc: TPSInternalProcRec;

    FData: PByteArray;

    FDataLength: Cardinal;

    FCurrentPosition: Cardinal;

    FCurrStackBase: Cardinal;

    FOnRunLine: TPSOnLineEvent;

    FSpecialProcList: TPSList;
    FOwnedImporters: TPSList;

    FRegProcs: TPSList;

    ExObject: TObject;

    ExProc: Cardinal;

    ExPos: Cardinal;

    ExEx: TPSError;

    ExParam: tbtstring;

    function InvokeExternalMethod(At: TPSTypeRec_ProcPtr; Slf, Ptr: Pointer): Boolean;

    function PlatformInnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
    function InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;

    procedure RunLine; virtual;

    function ImportProc(const Name: ShortString; proc: TPSExternalProcRec): Boolean; Virtual;

    procedure ExceptionProc(proc, Position: Cardinal; Ex: TPSError; const s: tbtstring; NewObject: TObject); Virtual;
    { the exception the top exception frame holds goes on unwinding, without
      that frame }
    procedure ResumeUnwinding;

    function FindSpecialProcImport(P: TPSOnSpecialProcImport): pointer;
  Public
    function LastEx: TPSError;
    function LastExParam: tbtstring;
    function LastExProc: Integer;
    function LastExPos: Integer;
    function LastExObject: TObject;
    procedure CMD_Err(EC: TPSError);

    procedure CMD_Err2(EC: TPSError; const Param: tbtstring);

    procedure CMD_Err3(EC: TPSError; const Param: tbtstring; ExObject: TObject);

    property Id: Pointer read FID write FID;

    class function About: tbtstring;

    function RunProc(Params: TPSList; ProcNo: Cardinal): Boolean;

    function RunProcP(const Params: array of Variant; const Procno: Cardinal): Variant;
    function RunProcPVar(var Params: array of Variant; const Procno: Cardinal): Variant;

    function RunProcPN(const Params: array of Variant; const ProcName: tbtstring): Variant;

    function FindType(StartAt: Cardinal; BaseType: TPSBaseType; var l: Cardinal): PIFTypeRec;

    function FindType2(BaseType: TPSBaseType): PIFTypeRec;

    function GetTypeNo(l: Cardinal): PIFTypeRec;

    function GetType(const Name: tbtstring): Cardinal;

    function GetProc(const Name: tbtstring): Cardinal;

    function GetVar(const Name: tbtstring): Cardinal;

    function GetVar2(const Name: tbtstring): PIFVariant;

    function GetVarNo(C: Cardinal): PIFVariant;

    function GetProcNo(C: Cardinal): PIFProcRec;

    function GetProcCount: Cardinal;

    function GetVarCount: Longint;

    function GetTypeCount: Longint;


    constructor Create;

    destructor Destroy; Override;


    function RunScript: Boolean;


    function LoadData(const s: tbtstring): Boolean; virtual;

    procedure Clear; Virtual;

    procedure Cleanup; Virtual;

    procedure Stop; Virtual;

    procedure Pause; Virtual;

    property CallCleanup: Boolean read FCallCleanup write FCallCleanup;

    property Status: TPSStatus Read FStatus;

    property OnRunLine: TPSOnLineEvent Read FOnRunLine Write FOnRunLine;

    procedure ClearspecialProcImports;

    procedure AddSpecialProcImport(const FName: tbtstring; P: TPSOnSpecialProcImport; Tag: Pointer);

    function RegisterFunctionName(const Name: tbtstring; ProcPtr: TPSProcPtr;
      Ext1, Ext2: Pointer): PProcRec;

    procedure RegisterDelphiFunction(ProcPtr: Pointer; const Name: tbtstring; CC: TPSCallingConvention);

    procedure RegisterDelphiMethod(Slf, ProcPtr: Pointer; const Name: tbtstring; CC: TPSCallingConvention);

    function GetProcAsMethod(const ProcNo: Cardinal): TMethod;

    function GetProcAsMethodN(const ProcName: tbtstring): TMethod;

    procedure RegisterAttributeType(useproc: TPSAttributeUseProc; const TypeName: tbtstring);

    procedure ClearFunctionList;

    property ExceptionProcNo: Cardinal Read ExProc;

    property ExceptionPos: Cardinal Read ExPos;

    property ExceptionCode: TPSError Read ExEx;

    property ExceptionString: tbtstring read ExParam;

    property ExceptionObject: TObject read ExObject write ExObject;

    procedure AddResource(Proc, P: Pointer);

    function IsValidResource(Proc, P: Pointer): Boolean;

    procedure DeleteResource(P: Pointer);

    function FindProcResource(Proc: Pointer): Pointer;

    function FindProcResource2(Proc: Pointer; var StartAt: Longint): Pointer;

    procedure RaiseCurrentException;

    property OnException: TPSOnException read FOnException write FOnException;
    property OnGetNVariant: TPSOnGetNVariant read FOnGetNVariant write FOnGetNVariant;
    property OnSetNVariant: TPSOnSetNVariant read FOnSetNVariant write FOnSetNVariant;
  end;

  TPSStack = class(TPSList)
  private
    FDataPtr: Pointer;
    FCapacity,
    FLength: Longint;
    { after UseChunks the stack keeps its values in chunks (TPSStackChunk
      records) that never move -- FChunkCount of them, FChunkIdx the one in
      use; without it the data is one block, moved when it grows.  The lists
      are made long enough before anything changes, so that storing, moving
      and freeing a chunk never allocates }
    FChunked: Boolean;
    FChunks: array of Pointer;
    FChunkCount,
    FChunkIdx: Longint;
    { the native calls in progress, and the chunks a Clear released meanwhile:
      kept until the last of those calls ends }
    FNativeCalls: Longint;
    FRetired: array of Pointer;
    FRetiredCount: Longint;
    function GetItem(I: Longint): PPSVariant;
    procedure SetCapacity(const Value: Longint);
    procedure AdjustLength;
    procedure NextChunk(aSize: Longint);
    procedure NativeCallStarts;
    procedure NativeCallEnds;
  public

    property DataPtr: Pointer read FDataPtr;

    property Capacity: Longint read FCapacity write SetCapacity;

    property Length: Longint read FLength;


    constructor Create;

    destructor Destroy; override;

    procedure Clear; {$IFDEF DELPHI5UP} reintroduce;{$ELSE} override; {$ENDIF}

    { from now on the stack grows by adding a chunk, so its values never move: an
      address into it stays valid until its value is popped }
    procedure UseChunks;

    function Push(TotalSize: Longint): PPSVariant;

    function PushType(aType: TPSTypeRec): PPSVariant;

    procedure Pop;
    function GetInt(ItemNo: Longint): Longint;
    function GetUInt(ItemNo: Longint): Cardinal;
{$IFNDEF PS_NOINT64}
    function GetInt64(ItemNo: Longint): Int64;
    function GetUInt64(ItemNo: Longint): UInt64;
{$ENDIF}
    function GetString(ItemNo: Longint): string; // calls the native method
    function GetAnsiString(ItemNo: Longint): tbtstring;
{$IFNDEF PS_NOWIDESTRING}
    function GetWideString(ItemNo: Longint): tbtWideString;
    function GetUnicodeString(ItemNo: Longint): tbtunicodestring;
{$ENDIF}
    function GetReal(ItemNo: Longint): Extended;
    function GetCurrency(ItemNo: Longint): Currency;
    function GetBool(ItemNo: Longint): Boolean;
    function GetClass(ItemNo: Longint): TObject;

    procedure SetInt(ItemNo: Longint; const Data: Longint);
    procedure SetUInt(ItemNo: Longint; const Data: Cardinal);
{$IFNDEF PS_NOINT64}
    procedure SetInt64(ItemNo: Longint; const Data: Int64);
    procedure SetUInt64(ItemNo: Longint; const Data: UInt64);
{$ENDIF}
    procedure SetString(ItemNo: Longint; const Data: string);
    procedure SetAnsiString(ItemNo: Longint; const Data: tbtstring);
{$IFNDEF PS_NOWIDESTRING}
    procedure SetWideString(ItemNo: Longint; const Data: tbtWideString);
    procedure SetUnicodeString(ItemNo: Longint; const Data: tbtunicodestring);
{$ENDIF}
    procedure SetReal(ItemNo: Longint; const Data: Extended);
    procedure SetCurrency(ItemNo: Longint; const Data: Currency);
    procedure SetBool(ItemNo: Longint; const Data: Boolean);
    procedure SetClass(ItemNo: Longint; const Data: TObject);
{$WARNINGS OFF}
{ ^ TPSStack has *two* Items properties: one indexed with a Cardinal (defined by TPSList) and the
    one below indexed with a Longint. Delphi 12.3 or 12.2 introduced a warning about this. Disable
    this warning since fixing the issue breaks callers: the return types of the two properties are
    different (Pointer vs PPSVariant). There's a specific directive to turn off this warning as well
    ($WARN OVERLOADING_ARRAY_PROPERTY OFF) but Delphi 12.1 doesnt know about it, so using it is hard. }
    property Items[I: Longint]: PPSVariant read GetItem; default;
  end;
{$WARNINGS ON}

function PSErrorToString(x: TPSError; const Param: tbtstring): tbtstring;
function TIFErrorToString(x: TPSError; const Param: tbtstring): tbtstring;
function CreateHeapVariant(aType: TPSTypeRec): PPSVariant;
procedure DestroyHeapVariant(v: PPSVariant);

procedure FreePIFVariantList(l: TPSList);
procedure FreePSVariantList(l: TPSList);

const
  ENoError = ERNoError;


function PIFVariantToVariant(Src: PIFVariant; var Dest: Variant): Boolean;
function VariantToPIFVariant(Exec: TPSExec; const Src: Variant; Dest: PIFVariant): Boolean;
function ParamAsVariable(const Modifier: tbtchar; aType: TPSTypeRec): Boolean;

{ empty_methods_handler: the platforms where no native stub carries a call into a script
  method, so MyAllMethodsHandler is empty and ResultAsRegister, which only the stubs use,
  is not compiled.  Defined here so that this interface can test it. }
{$ifdef fpc}
  {$if defined(cpupowerpc) or defined(cpuarm) or defined(cpu64)}
    {$define empty_methods_handler}
  {$ifend}
{$else}
  {$if defined(cpuarm) or defined(cpuarm64)}
    {$define empty_methods_handler}
  {$ifend}
{$endif}
{$ifndef empty_methods_handler}
function ResultAsRegister(b: TPSTypeRec): Boolean;
{$endif}

function PSGetRecField(const avar: TPSVariantIFC; Fieldno: Longint): TPSVariantIFC;
function PSGetArrayField(const avar: TPSVariantIFC; Fieldno: Longint): TPSVariantIFC;
function NewTPSVariantRecordIFC(avar: PPSVariant; Fieldno: Longint): TPSVariantIFC;

function NewTPSVariantIFC(avar: PPSVariant; varparam: boolean): TPSVariantIFC;

function NewPPSVariantIFC(avar: PPSVariant; varparam: boolean): PPSVariantIFC;

procedure DisposePPSVariantIFC(aVar: PPSVariantIFC);

procedure DisposePPSVariantIFCList(list: TPSList);


function PSGetObject(Src: Pointer; aType: TPSTypeRec): TObject;
function PSGetUInt(Src: Pointer; aType: TPSTypeRec): Cardinal;
{$IFNDEF PS_NOINT64}
function PSGetInt64(Src: Pointer; aType: TPSTypeRec): Int64;
function PSGetUInt64(Src: Pointer; aType: TPSTypeRec): UInt64;
{$ENDIF}
function PSGetReal(Src: Pointer; aType: TPSTypeRec): Extended;
function PSGetCurrency(Src: Pointer; aType: TPSTypeRec): Currency;
function PSGetInt(Src: Pointer; aType: TPSTypeRec): Longint;
function PSGetString(Src: Pointer; aType: TPSTypeRec): string;
function PSGetAnsiString(Src: Pointer; aType: TPSTypeRec): tbtString;
{$IFNDEF PS_NOWIDESTRING}
function PSGetWideString(Src: Pointer; aType: TPSTypeRec): tbtWideString;
function PSGetUnicodeString(Src: Pointer; aType: TPSTypeRec): tbtunicodestring;
{$ENDIF}

procedure PSSetObject(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; Const val: TObject);
procedure PSSetUInt(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Cardinal);
{$IFNDEF PS_NOINT64}
procedure PSSetInt64(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Int64);
procedure PSSetUInt64(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: UInt64);
{$ENDIF}
procedure PSSetReal(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Extended);
procedure PSSetCurrency(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Currency);
procedure PSSetInt(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Longint);
procedure PSSetString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: String);
procedure PSSetAnsiString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: tbtString);
{$IFNDEF PS_NOWIDESTRING}
procedure PSSetWideString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: tbtWideString);
procedure PSSetUnicodeString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: tbtunicodestring);
{$ENDIF}

procedure VNSetPointerTo(const Src: TPSVariantIFC; Data: Pointer; aType: TPSTypeRec);

function VNGetObject(const Src: TPSVariantIFC): TObject;
function VNGetUInt(const Src: TPSVariantIFC): Cardinal;
{$IFNDEF PS_NOINT64}
function VNGetInt64(const Src: TPSVariantIFC): Int64;
{$ENDIF}
function VNGetReal(const Src: TPSVariantIFC): Extended;
function VNGetCurrency(const Src: TPSVariantIFC): Currency;
function VNGetInt(const Src: TPSVariantIFC): Longint;
function VNGetString(const Src: TPSVariantIFC): String;
function VNGetAnsiString(const Src: TPSVariantIFC): tbtString;
{$IFNDEF PS_NOWIDESTRING}
function VNGetWideString(const Src: TPSVariantIFC): tbtWideString;
function VNGetUnicodeString(const Src: TPSVariantIFC): tbtunicodestring;
{$ENDIF}

procedure VNSetObject(const Src: TPSVariantIFC; const Val: TObject);
procedure VNSetUInt(const Src: TPSVariantIFC; const Val: Cardinal);
{$IFNDEF PS_NOINT64}
procedure VNSetInt64(const Src: TPSVariantIFC; const Val: Int64);
procedure VNSetUInt64(const Src: TPSVariantIFC; const Val: UInt64);
{$ENDIF}
procedure VNSetReal(const Src: TPSVariantIFC; const Val: Extended);
procedure VNSetCurrency(const Src: TPSVariantIFC; const Val: Currency);
procedure VNSetInt(const Src: TPSVariantIFC; const Val: Longint);
procedure VNSetString(const Src: TPSVariantIFC; const Val: String);
procedure VNSetAnsiString(const Src: TPSVariantIFC; const Val: tbtString);
{$IFNDEF PS_NOWIDESTRING}
procedure VNSetWideString(const Src: TPSVariantIFC; const Val: tbtWideString);
procedure VNSetUnicodeString(const Src: TPSVariantIFC; const Val: tbtunicodestring);
{$ENDIF}

function VGetUInt(const Src: PIFVariant): Cardinal;
{$IFNDEF PS_NOINT64}
function VGetInt64(const Src: PIFVariant): Int64;
{$ENDIF}
function VGetReal(const Src: PIFVariant): Extended;
function VGetCurrency(const Src: PIFVariant): Currency;
function VGetInt(const Src: PIFVariant): Longint;
function VGetString(const Src: PIFVariant): String;
function VGetAnsiString(const Src: PIFVariant): tbtString;
{$IFNDEF PS_NOWIDESTRING}
function VGetWideString(const Src: PIFVariant): tbtWideString;
function VGetUnicodeString(const Src: PIFVariant): tbtunicodestring;
{$ENDIF}

procedure VSetPointerTo(const Src: PIFVariant; Data: Pointer; aType: TPSTypeRec);
procedure VSetUInt(const Src: PIFVariant; const Val: Cardinal);
{$IFNDEF PS_NOINT64}
procedure VSetInt64(const Src: PIFVariant; const Val: Int64);
{$ENDIF}
procedure VSetReal(const Src: PIFVariant; const Val: Extended);
procedure VSetCurrency(const Src: PIFVariant; const Val: Currency);
procedure VSetInt(const Src: PIFVariant; const Val: Longint);
procedure VSetString(const Src: PIFVariant; const Val: string);
procedure VSetAnsiString(const Src: PIFVariant; const Val: tbtString);
{$IFNDEF PS_NOWIDESTRING}
procedure VSetWideString(const Src: PIFVariant; const Val: tbtWideString);
procedure VSetUnicodeString(const Src: PIFVariant; const Val: tbtunicodestring);
{$ENDIF}

type

  EPSException = class(Exception)
  private
    FProcPos: Cardinal;
    FProcNo: Cardinal;
    FExec: TPSExec;
  public

    constructor Create(const Error: tbtstring; Exec: TPSExec; Procno, ProcPos: Cardinal);

    property ProcNo: Cardinal read FProcNo;

    property ProcPos: Cardinal read FProcPos;

    property Exec: TPSExec read FExec;
  end;

  TPSRuntimeClass = class
  protected
    FClassName: tbtstring;
    FClassNameHash: Longint;

    FClassItems: TPSList;
    FClass: TClass;

    FEndOfVmt: Longint;
  public

    procedure RegisterConstructor(ProcPtr: Pointer; const Name: tbtstring);

    procedure RegisterVirtualConstructor(ProcPtr: Pointer; const Name: tbtstring);

    procedure RegisterMethod(ProcPtr: Pointer; const Name: tbtstring);

    procedure RegisterVirtualMethod(ProcPtr: Pointer; const Name: tbtstring);

    procedure RegisterVirtualAbstractMethod(ClassDef: TClass; ProcPtr: Pointer; const Name: tbtstring);

    procedure RegisterPropertyHelper(ReadFunc, WriteFunc: Pointer; const Name: tbtstring);

    procedure RegisterPropertyHelperName(ReadFunc, WriteFunc: Pointer; const Name: tbtstring);

    procedure RegisterEventPropertyHelper(ReadFunc, WriteFunc: Pointer; const Name: tbtstring);

    constructor Create(aClass: TClass; const AName: tbtstring);

    destructor Destroy; override;
  end;

  TPSRuntimeClassImporter = class
  private
    FClasses: TPSList;
  public

    constructor Create;

    { AutoFree: Exec owns the importer, which goes when Exec does }
    constructor CreateAndRegister(Exec: TPSExec; AutoFree: Boolean);

    destructor Destroy; override;

    function Add(aClass: TClass): TPSRuntimeClass;

    function Add2(aClass: TClass; const Name: tbtstring): TPSRuntimeClass;

    procedure Clear;

    function FindClass(const Name: tbtstring): TPSRuntimeClass;
  end;
  TIFPSRuntimeClassImporter = TPSRuntimeClassImporter;
  TPSResourceFreeProc = procedure (Sender: TPSExec; P: TPSRuntimeClassImporter);


procedure RegisterClassLibraryRuntime(SE: TPSExec; Importer: TPSRuntimeClassImporter);

procedure SetVariantToClass(V: PIFVariant; Cl: TObject);
{$IFNDEF PS_NOINTERFACES}
procedure SetVariantToInterface(V: PIFVariant; Cl: IUnknown);
{$ENDIF}

procedure MyAllMethodsHandler;

function GetMethodInfoRec(SE: TPSExec; ProcNo: Cardinal): Pointer;

function MkMethod(FSE: TPSExec; No: Cardinal): TMethod;

type
  TIFInternalProcRec = TPSInternalProcRec;
  TIFError = TPSError;
  TIFStatus = TPSStatus;
  TIFPSExec = TPSExec;
  TIFPSStack = TPSStack;
  TIFTypeRec = TPSTypeRec;


  TPSCallingConvention = uPSUtils.TPSCallingConvention;
const

  cdRegister = uPSUtils.cdRegister;

  cdPascal = uPSUtils.cdPascal;

  cdCdecl = uPSUtils.cdCdecl;

  cdStdCall = uPSUtils.cdStdCall;

  InvalidVal = Cardinal(-1);

function  PSDynArrayGetLength(arr: Pointer; aType: TPSTypeRec): Longint;
procedure PSDynArraySetLength(var arr: Pointer; aType: TPSTypeRec; NewLength: Longint);

function  GetPSArrayLength(Arr: PIFVariant): Longint;
procedure SetPSArrayLength(Arr: PIFVariant; NewLength: Longint);

function PSVariantToString(const p: TPSVariantIFC; const ClassProperties: tbtstring): tbtstring;
function MakeString(const s: tbtstring): tbtstring;
{$IFNDEF PS_NOWIDESTRING}
function MakeWString(const s: tbtunicodestring): tbtstring;
{$ENDIF}

{$IFNDEF PS_NOIDISPATCH}
function IDispatchInvoke(Self: IDispatch; PropertySet: Boolean; const Name: tbtString; const Par: array of Variant): Variant;
{$ENDIF}


implementation
uses
  TypInfo {$IFDEF DELPHI3UP}
  {$IFNDEF FPC}{$IFDEF MSWINDOWS} , ComObj {$ENDIF}{$ENDIF}{$ENDIF}
  {$IFDEF PS_FPC_HAS_COM}, ComObj{$ENDIF}
  {$IF NOT DEFINED (NEXTGEN) AND NOT DEFINED (MACOS) AND  DEFINED (DELPHI_TOKYO_UP)}, AnsiStrings{$IFEND};

{$UNDEF LOG}
{$IFDEF uPSRuntime_DEBUG}{$DEFINE LOG}{$ENDIF}
{$IFDEF LOG}
procedure __Log(aMessage:string);
begin
  OutputDebugStringW(PWideChar(WideString(aMessage)));
end;

procedure ODS_stack(stack: TPSStack);forward;
{$ENDIF}
{$IFDEF DELPHI3UP }
resourceString
{$ELSE }
const
{$ENDIF }

  RPS_UnknownIdentifier = 'Unknown Identifier';
  RPS_Exception = 'Exception: %s';
  RPS_Invalid = '[Invalid]';

  //- PSErrorToString
  RPS_NoError = 'No Error';
  RPS_CannotImport = 'Cannot Import %s';
  RPS_InvalidType = 'Invalid Type';
  RPS_InternalError = 'Internal error';
  RPS_InvalidHeader = 'Invalid Header';
  RPS_InvalidOpcode = 'Invalid Opcode';
  RPS_InvalidOpcodeParameter = 'Invalid Opcode Parameter';
  RPS_NoMainProc = 'no Main Proc';
  RPS_OutOfGlobalVarsRange = 'Out of Global Vars range';
  RPS_OutOfProcRange = 'Out of Proc Range';
  RPS_OutOfRange = 'Out Of Range';
  RPS_OutOfStackRange = 'Out Of Stack Range';
  RPS_TypeMismatch = 'Type Mismatch';
  RPS_UnexpectedEof = 'Unexpected End Of File';
  RPS_VersionError = 'Version error';
  RPS_DivideByZero = 'divide by Zero';
  RPS_MathError = 'Math error';
  RPS_CouldNotCallProc = 'Could not call proc';
  RPS_OutofRecordRange = 'Out of Record Fields Range';
  RPS_NullPointerException = 'Null Pointer Exception';
  RPS_NullVariantError = 'Null variant error';
  RPS_OutOfMemory = 'Out Of Memory';
  RPS_InterfaceNotSupported = 'Interface not supported';
  RPS_UnknownError = 'Unknown error';
  RPS_HostRoutineAsMethod = 'A host routine cannot be called as a native event';
  RPS_EndedScriptMethod = 'A script routine cannot be called after its script has ended';


  RPS_InvalidVariable = 'Invalid variable';
  RPS_InvalidArray = 'Invalid array';
  RPS_OLEError = 'OLE error %.8x';
  RPS_UnknownProcedure = 'Unknown procedure';
{$IFDEF FPC}{$IFDEF empty_methods_handler}
  RPS_NoNativeMethodsHandler = 'A script method cannot be bound to a native event on this platform';
{$ENDIF}{$ENDIF}
  RPS_NotEnoughParameters = 'Not enough parameters';
  RPS_InvalidParameter = 'Invalid parameter';
  RPS_TooManyParameters = 'Too many parameters';
  RPS_OutOfStringRange = 'Out of string range';
  RPS_CannotCastInterface = 'Cannot cast an interface';
  RPS_CannotCastObject = 'Cannot cast an object';
  RPS_CapacityLength = 'Capacity < Length';
  RPS_CanOnlySendLastItem = 'Can only remove last item from stack';
  RPS_NILInterfaceException = 'Nil interface';
  RPS_UnknownMethod = 'Unknown method';



type
  PPSExportedVar = ^TPSExportedVar;
  TPSExportedVar = record
    FName: tbtstring;
    FNameHash: Longint;
    FVarNo: Cardinal;
  end;
  PRaiseFrame = ^TRaiseFrame;
  TRaiseFrame = record
    NextRaise: PRaiseFrame;
    ExceptAddr: Pointer;
    ExceptObject: TObject;
    ExceptionRecord: Pointer;
  end;
  TPSExceptionHandler = class
    CurrProc: TPSInternalProcRec;
    BasePtr, StackSize: Cardinal;
    FinallyOffset, ExceptOffset, Finally2Offset, EndOfBlock: Cardinal;
    ExitPoint: Cardinal;
    ExceptionData: TPSError;
    ExceptionObject: TObject;
    ExceptionParam: tbtString;
    { True while the frame's finally runs for the exception it holds in the
      fields above, from the finally's start to its end, where the exception
      goes on }
    Unwinding: Boolean;
    { where the exception the frame holds or handles was raised }
    ExceptionProcNo, ExceptionPos: Cardinal;
    procedure DropException;
    destructor Destroy; override;
  end;
  TPSHeader = packed record
    HDR: Cardinal;
    PSBuildNo: Cardinal;
    TypeCount: Cardinal;
    ProcCount: Cardinal;
    VarCount: Cardinal;
    MainProcNo: Cardinal;
    ImportTableSize: Cardinal;
  end;

  TPSExportItem = packed record
    ProcNo: Cardinal;
    NameLength: Cardinal;
    DeclLength: Cardinal;
  end;

  TPSType = packed record
    BaseType: TPSBaseType;
  end;
  TPSProc = packed record
    Flags: Byte;
  end;

  TPSVar = packed record
    TypeNo: Cardinal;
    Flags: Byte;
  end;
  PSpecialProc = ^TSpecialProc;
  TSpecialProc = record
    P: TPSOnSpecialProcImport;
    namehash: Longint;
    Name: tbtstring;
    tag: pointer;
  end;

destructor TPSExceptionHandler.Destroy;
begin
  ExceptionObject.Free;
  inherited;
end;

procedure TPSExceptionHandler.DropException;
begin
  ExceptionObject.Free;
  ExceptionObject := nil;
  ExceptionData := ENoError;
  ExceptionParam := '';
  Unwinding := False;
end;

{ The frame whose except handler runs, nearest the top of aStack; nil when
  none does.  Frames of statements nested in the handler are above it. }
function _HandlerFrame(aStack: TPSList): TPSExceptionHandler;
var
  lFrameIdx : Longint;
begin
  for lFrameIdx := aStack.Count - 1 downto 0 do
  begin
    Result := aStack[lFrameIdx];
    if Result.ExceptOffset = Cardinal(InvalidVal -1) then
      Exit;
  end;
  Result := nil;
end;

procedure P_CM_A; begin end;
procedure P_CM_CA; begin end;
procedure P_CM_P; begin end;
procedure P_CM_PV; begin end;
procedure P_CM_PO; begin end;
procedure P_CM_C; begin end;
procedure P_CM_G; begin end;
procedure P_CM_CG; begin end;
procedure P_CM_CNG; begin end;
procedure P_CM_R; begin end;
procedure P_CM_ST; begin end;
procedure P_CM_PT; begin end;
procedure P_CM_CO; begin end;
procedure P_CM_CV; begin end;
procedure P_CM_SP; begin end;
procedure P_CM_BN; begin end;
procedure P_CM_VM; begin end;
procedure P_CM_SF; begin end;
procedure P_CM_FG; begin end;
procedure P_CM_PUEXH; begin end;
procedure P_CM_POEXH; begin end;
procedure P_CM_IN; begin end;
procedure P_CM_SPB; begin end;
procedure P_CM_INC; begin end;
procedure P_CM_DEC; begin end;

function IntPIFVariantToVariant(Src: pointer; aType: TPSTypeRec; var Dest: Variant): Boolean; forward;


procedure Set_Union(Dest, Src: PByteArray; ByteSize: Integer);
var
  i: Longint;
begin
  for i := ByteSize -1 downto 0 do
    Dest^[i] := Dest^[i] or Src^[i];
end;

procedure Set_Diff(Dest, Src: PByteArray; ByteSize: Integer);
var
  i: Longint;
begin
  for i := ByteSize -1 downto 0 do
    Dest^[i] := Dest^[i] and not Src^[i];
end;

procedure Set_Intersect(Dest, Src: PByteArray; ByteSize: Integer);
var
  i: Longint;
begin
  for i := ByteSize -1 downto 0 do
    Dest^[i] := Dest^[i] and Src^[i];
end;

procedure Set_Subset(Dest, Src: PByteArray; ByteSize: Integer; var Val: Boolean);
var
  i: Integer;
begin
  for i := ByteSize -1 downto 0 do
  begin
    if not (Src^[i] and Dest^[i] = Dest^[i]) then
    begin
      Val := False;
      exit;
    end;
  end;
  Val := True;
end;

procedure Set_Equal(Dest, Src: PByteArray; ByteSize: Integer; var Val: Boolean);
var
  i: Longint;
begin
  for i := ByteSize -1 downto 0 do
  begin
    if Dest^[i] <> Src^[i] then
    begin
      Val := False;
      exit;
    end;
  end;
  val := True;
end;

procedure Set_membership(Item: Longint; Src: PByteArray; var Val: Boolean);
begin
  Val := (Src^[Item shr 3] and (1 shl (Item and 7))) <> 0;
end;


function Trim(const s: tbtstring): tbtstring;
begin
  Result := s;
  while (Length(result) > 0) and (Result[1] = #32) do Delete(Result, 1, 1);
  while (Length(result) > 0) and (Result[Length(Result)] = #32) do Delete(Result, Length(Result), 1);
end;
(*function FloatToStr(E: Extended): tbtstring;
begin
  Result := Sysutils.FloatToStr(e);
end;*)

//-------------------------------------------------------------------

function Padl(s: tbtstring; i: longInt): tbtstring;
begin
  result := StringOfChar(tbtchar(' '), i - length(s)) + s;
end;
//-------------------------------------------------------------------

function Padz(s: tbtString; i: longInt): tbtString;
begin
  result := StringOfChar(tbtchar('0'), i - length(s)) + s;
end;
//-------------------------------------------------------------------

function Padr(s: tbtString; i: longInt): tbtString;
begin
  result := s + StringOfChar(tbtchar(' '), i - Length(s));
end;
//-------------------------------------------------------------------

{$IFNDEF PS_NOWIDESTRING}
function wPadl(s: tbtwidestring; i: longInt): tbtwidestring;
begin
  result := StringOfChar(tbtwidechar(' '), i - length(s)) + s;
end;
//-------------------------------------------------------------------

function wPadz(s: tbtwidestring; i: longInt): tbtwidestring;
begin
  result := StringOfChar(tbtwidechar('0'), i - length(s)) + s;
end;
//-------------------------------------------------------------------

function wPadr(s: tbtwidestring; i: longInt): tbtwidestring;
begin
  result := s + StringOfChar(tbtwidechar(' '), i - Length(s));
end;

function uPadl(s: tbtunicodestring; i: longInt): tbtunicodestring;
begin
  result := StringOfChar(tbtwidechar(' '), i - length(s)) + s;
end;
//-------------------------------------------------------------------

function uPadz(s: tbtunicodestring; i: longInt): tbtunicodestring;
begin
  result := StringOfChar(tbtwidechar('0'), i - length(s)) + s;
end;
//-------------------------------------------------------------------

function uPadr(s: tbtunicodestring; i: longInt): tbtunicodestring;
begin
  result := s + StringOfChar(tbtwidechar(' '), i - Length(s));
end;

{$ENDIF}
{$IFNDEF PS_NOWIDESTRING}
function MakeWString(const s: tbtunicodestring): tbtString;
var
  i: Longint;
  e: tbtunicodestring;
  b: boolean;
  w: tbtunicodestring;
begin
  { the text is built on the wide string and narrowed last: a character past
    #255 is written by its number, and so is one from #128 that the host's
    ANSI code page cannot hold -- a narrowing first could lose either }
  w := s;
  i := 1;
  b := false;
  while i <= length(w) do
  begin
    if w[i] = '''' then
    begin
      if not b then
      begin
        b := true;
        Insert('''', w, i);
        inc(i);
      end;
      Insert('''', w, i);
      inc(i, 2);
    end else if (w[i] < #32) or (w[i] > #255) or
      ((w[i] > #127) and (tbtunicodestring(tbtString(w[i])) <> w[i])) then
    begin
      e := tbtunicodestring('#'+inttostr(ord(w[i])));
      Delete(w, i, 1);
      if b then
      begin
        b := false;
        Insert('''', w, i);
        inc(i);
      end;
      Insert(e, w, i);
      inc(i, length(e));
    end else begin
      if not b then
      begin
        b := true;
        Insert('''', w, i);
        inc(i, 2);
      end else
        inc(i);
    end;
  end;
  if b then
  begin
    w := w + '''';
  end;
  if w = '' then
    w := '''''';
  Result := tbtString(w);
end;
{$ENDIF}
function MakeString(const s: tbtString): tbtString;
var
  i: Longint;
  e: tbtString;
  b: boolean;
begin
  Result := s;
  i := 1;
  b := false;
  while i <= length(result) do
  begin
    if Result[i] = '''' then
    begin
      if not b then
      begin
        b := true;
        Insert('''', Result, i);
        inc(i);
      end;
      Insert('''', Result, i);
      inc(i, 2);
    end else if (Result[i] < #32) then
    begin
      e := '#'+inttostr(ord(Result[i]));
      Delete(Result, i, 1);
      if b then
      begin
        b := false;
        Insert('''', Result, i);
        inc(i);
      end;
      Insert(e, Result, i);
      inc(i, length(e));
    end else begin
      if not b then
      begin
        b := true;
        Insert('''', Result, i);
        inc(i, 2);
      end else
        inc(i);
    end;
  end;
  if b then
  begin
    Result := Result + '''';
  end;
  if Result = '' then
    Result := '''''';
end;

function SafeStr(const s: tbtString): tbtString;
var
 i : Longint;
begin
  Result := s;
  for i := 1 to length(s) do
  begin
    if s[i] in [#0..#31] then
    begin
      Result := Copy(s, 1, i-1);
      exit;
    end;
  end;

end;

{$IFNDEF DELPHI2009UP}
function UIntToStr(const Value: tbtu64): string; forward;
{$ENDIF}

function PropertyToString(Instance: TObject; PName: tbtString): tbtString;
var
  s: tbtString;
  i: Longint;
  PP: PPropInfo;
begin
  if PName = '' then
  begin
    Result := tbtString(Instance.ClassName);
    exit;
  end;
  while Length(PName) > 0 do
  begin
    i := pos(tbtChar('.'), pname);
    if i = 0 then
    begin
      s := Trim(PNAme);
      pname := '';
    end else begin
      s := trim(Copy(PName, 1, i-1));
      Delete(PName, 1, i);
    end;
    pp := GetPropInfo(PTypeInfo(Instance.ClassInfo), string(s));
    if pp = nil then begin Result := tbtstring(RPS_UnknownIdentifier); exit; end;
    { a name after one that is no object names nothing }
    if (PName <> '') and (pp^.PropType^.Kind <> tkClass) then
    begin
      Result := tbtstring(RPS_UnknownIdentifier);
      exit;
    end;


    case pp^.PropType^.Kind of
      tkInteger:
        begin
          { a Cardinal is read as the unsigned number it is }
          if GetTypeData(pp^.PropType{$IFNDEF FPC}{$IFDEF DELPHI3UP}^{$ENDIF}{$ENDIF})^.OrdType = otULong then
            Result := tbtString(SysUtils.IntToStr(Int64(Cardinal(GetOrdProp(Instance, pp)))))
          else
            Result := IntToStr(GetOrdProp(Instance, pp));
          exit;
        end;
      tkChar, tkWChar: begin Result := '#'+IntToStr(GetOrdProp(Instance, pp)); exit; end;
      tkEnumeration: begin Result := tbtstring(GetEnumName(pp^.PropType{$IFNDEF FPC}{$IFDEF DELPHI3UP}^{$ENDIF}{$ENDIF}, GetOrdProp(Instance, pp))); exit; end;
      {$IFDEF FPC}
      { Free Pascal gives Boolean a kind of its own; written as Delphi writes it, by name }
      tkBool: begin Result := tbtstring(GetEnumName(TypeInfo(Boolean), Ord(GetOrdProp(Instance, pp) <> 0))); exit; end;
      {$ENDIF}
      {$IFNDEF PS_NOINT64}
      tkInt64:
        begin
          { a UInt64 -- its type's least value past its greatest, as the RTL's own
            GetPropValue tells it -- is read as the unsigned number it is }
          if GetTypeData(pp^.PropType{$IFNDEF FPC}{$IFDEF DELPHI3UP}^{$ENDIF}{$ENDIF})^.MinInt64Value >
             GetTypeData(pp^.PropType{$IFNDEF FPC}{$IFDEF DELPHI3UP}^{$ENDIF}{$ENDIF})^.MaxInt64Value then
            Result := tbtString(UIntToStr(tbtu64(GetInt64Prop(Instance, pp))))
          else
            Result := tbtString(SysUtils.IntToStr(GetInt64Prop(Instance, pp)));
          exit;
        end;
      {$IFDEF FPC}
      { Free Pascal gives UInt64 a kind of its own: read as the unsigned number it is }
      tkQWord: begin Result := tbtString(UIntToStr(tbtu64(GetInt64Prop(Instance, pp)))); exit; end;
      {$ENDIF}
     {$ENDIF}
      tkFloat: begin Result := FloatToStr(GetFloatProp(Instance, PP)); exit; end;
      { a string as a string variable's is written }
      tkString, tkLString{$IFDEF FPC}, tkAString{$ENDIF}: begin Result := MakeString(tbtString(GetStrProp(Instance, PP))); exit; end;
      tkSet: begin Result := '[Set]'; exit; end;
      tkClass: begin Instance := TObject(GetOrdProp(Instance, pp)); end;
      tkMethod: begin Result := '[Method]'; exit; end;
      tkVariant: begin Result := '[Variant]'; exit; end;
	  {$IFDEF DELPHI6UP}
	  {$IFNDEF PS_NOWIDESTRING}
      tkWString: begin Result := MakeWString(GetWideStrProp(Instance, pp)); exit; end;
	  {$IFDEF DELPHI2009UP}
      tkUString: begin Result := MakeWString({$IFDEF DELPHI_TOKYO_UP}GetStrProp{$ELSE}GetUnicodeStrProp{$ENDIF}(Instance, pp)); exit; end;
	  {$ENDIF}
      {$ENDIF}
	  {$ENDIF}
      else begin Result := '[Unknown]'; exit; end;
    end;
    if Instance = nil then begin result := 'nil'; exit; end;
  end;
  Result := tbtstring(Instance.ClassName);
end;

function ClassVariantInfo(const pvar: TPSVariantIFC; const PropertyName: tbtString): tbtString;
begin
  if pvar.aType.BaseType = btClass then
  begin
    if TObject(pvar.Dta^) = nil then
      Result := 'nil'
    else
      Result := PropertyToString(TObject(pvar.Dta^), PropertyName);
  end else if pvar.atype.basetype = btInterface then
      Result := 'Interface'
  else Result := tbtstring(RPS_InvalidType);
end;

{$IFNDEF DELPHI2009UP}
{ The RTL has UIntToStr for a 64-bit value from Delphi 2009 on.  The value is divided by ten in two
  32-bit halves because unsigned 64-bit arithmetic is not dependable on the oldest compilers. }
function UIntToStr(const Value: tbtu64): string;
var
  Hi, Lo: Cardinal;
  Temp: Int64;
begin
  Hi := Int64Rec(Value).Hi;
  Lo := Int64Rec(Value).Lo;
  Result := '';
  repeat
    Temp := (Int64(Hi mod 10) shl 32) or Int64(Lo);
    Hi := Hi div 10;
    Lo := Cardinal(Temp div 10);
    Result := Chr(Ord('0') + Integer(Temp mod 10)) + Result;
  until (Hi = 0) and (Lo = 0);
end;
{$ENDIF}

{$IFNDEF DELPHI25UP}
{ The RTL has StrToUInt64 and StrToUInt64Def from Delphi XE6 on, and through 10.1 Berlin its
  StrToUInt64Def answers 0 for a number past the 64-bit range instead of the default.  So every
  compiler before 10.2 Tokyo gets these.  They read what Val reads for an unsigned value: leading
  blanks, an optional plus sign -- or a minus sign before a value of zero --, decimal digits, or
  hexadecimal digits after $, x or 0x.  The value is built in two 32-bit halves because unsigned
  64-bit arithmetic is not dependable on the oldest compilers. }
function PSTryStrToUInt64(const S: string; var Value: tbtu64): Boolean;
var
  Idx, Len, Digit, Base: Integer;
  Hi, Lo: Cardinal;
  Temp: Int64;
  Any, Minus: Boolean;
begin
  Result := False;
  Len := Length(S);
  Idx := 1;
  while (Idx <= Len) and (S[Idx] = ' ') do
    Inc(Idx);
  Minus := (Idx <= Len) and (S[Idx] = '-');
  if (Idx <= Len) and ((S[Idx] = '+') or Minus) then
    Inc(Idx);
  Base := 10;
  if (Idx <= Len) and ((S[Idx] = '$') or (S[Idx] = 'x') or (S[Idx] = 'X')) then
  begin
    Base := 16;
    Inc(Idx);
  end
  else if (Idx < Len) and (S[Idx] = '0') and ((S[Idx + 1] = 'x') or (S[Idx + 1] = 'X')) then
  begin
    Base := 16;
    Inc(Idx, 2);
  end;
  Hi := 0;
  Lo := 0;
  Any := False;
  while Idx <= Len do
  begin
    case S[Idx] of
      '0'..'9': Digit := Ord(S[Idx]) - Ord('0');
      'a'..'f': Digit := Ord(S[Idx]) - Ord('a') + 10;
      'A'..'F': Digit := Ord(S[Idx]) - Ord('A') + 10;
    else
      Exit;
    end;
    if Digit >= Base then
      Exit;
    Temp := Int64(Lo) * Base + Digit;
    Lo := Cardinal(Temp and $FFFFFFFF);
    Temp := Int64(Hi) * Base + (Temp shr 32);
    if (Temp shr 32) <> 0 then
      Exit;
    Hi := Cardinal(Temp and $FFFFFFFF);
    Any := True;
    Inc(Idx);
  end;
  if not Any or (Minus and ((Hi <> 0) or (Lo <> 0))) then
    Exit;
  Int64Rec(Value).Hi := Hi;
  Int64Rec(Value).Lo := Lo;
  Result := True;
end;

function StrToUInt64(const S: string): tbtu64;
begin
  if not PSTryStrToUInt64(S, Result) then
    raise EConvertError.CreateFmt('''%s'' is not a valid integer value', [S]);
end;

function StrToUInt64Def(const S: string; const Default: tbtu64): tbtu64;
begin
  if not PSTryStrToUInt64(S, Result) then
    Result := Default;
end;
{$ENDIF}

function PSVariantToString(const p: TPSVariantIFC; const ClassProperties: tbtString): tbtString;
var
  i, n: Longint;
  b: Boolean;
begin
  if p.Dta = nil then
  begin
    Result := 'nil';
    exit;
  end;
  if (p.aType.BaseType = btVariant) then
  begin
    try
      if TVarData(p.Dta^).VType = varDispatch then
        Result := 'Variant(IDispatch)'
      else if TVarData(p.Dta^).VType = varNull then
        REsult := 'Null'
      else if (TVarData(p.Dta^).VType = varOleStr){$IFDEF UNICODE} or (TVarData(p.Dta^).VType = varUString){$ENDIF} then
      {$IFDEF PS_NOWIDESTRING}
        Result := MakeString(Variant(p.Dta^))
      {$ELSE}
        Result := MakeWString(variant(p.dta^))
      {$ENDIF}
      else if TVarData(p.Dta^).VType = varString then
        Result := MakeString(tbtstring(variant(p.Dta^)))
      else
      Result := tbtstring(Variant(p.Dta^));
    except
      on e: Exception do
        Result := tbtstring(Format (RPS_Exception, [e.Message]));
    end;
    exit;
  end;
  case p.aType.BaseType of
    btProcptr: begin Result := 'Proc: '+inttostr(tbtu32(p.Dta^)); end;
    btU8: str(tbtu8(p.dta^), Result);
    btS8: str(tbts8(p.dta^), Result);
    btU16: str(tbtu16(p.dta^), Result);
    btS16: str(tbts16(p.dta^), Result);
    btU32: str(tbtu32(p.dta^), Result);
    btS32: str(tbts32(p.dta^), Result);
    btSingle: Result := FloatToStr(tbtsingle(p.dta^));
    btDouble: Result := FloatToStr(tbtdouble(p.dta^));
    btExtended: Result := FloatToStr(tbtextended(p.dta^));
    btCurrency: Result := CurrToStr(tbtcurrency(p.dta^));
    btString: Result := makestring(tbtString(p.dta^));
    btPChar:
      begin
        if PansiChar(p.dta^) = nil then
          Result := 'nil'
        else
          Result := MakeString(PAnsiChar(p.dta^));
      end;
    btchar: Result := MakeString(tbtchar(p.dta^));
    {$IFNDEF PS_NOWIDESTRING}
    btwidechar: Result := MakeWString(tbtwidechar(p.dta^));
    btWideString: Result := MakeWString(tbtwidestring(p.dta^));
    btUnicodeString: Result := MakeWString(tbtUnicodeString(p.dta^));
    {$ENDIF}
    {$IFNDEF PS_NOINT64}
    btS64: str(tbts64(p.dta^), Result);
    btU64: Result := tbtString(UIntToStr(tbtu64(p.dta^)));
    {$ENDIF}
    btStaticArray, btArray:
      begin
        Result := '';
        if p.aType.BaseType = btStaticArray then
          n := TPSTypeRec_StaticArray(p.aType).Size
        else
          n := PSDynArrayGetLength(Pointer(p.dta^), p.aType);
        for i := 0 to n-1 do begin
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + PSVariantToString(PSGetArrayField(p, i), '');
        end;
        Result := '[' + Result + ']';
      end;
    btSet:
      begin
        Result := '';
        n := TPSTypeRec_Set(p.aType).aBitSize;
        for i := 0 to n-1 do begin
          Set_membership(i, PByteArray(p.Dta), b);
          if b then begin
            if Result <> '' then
              Result := Result + ', ';
            { a member by its ordinal, as the in operator and Include number it }
            Result := Result + IntToStr(i);
          end;
        end;
        Result := '[' + Result + ']';
      end;
    btRecord:
      begin
        Result := '';
        n := TPSTypeRec_Record(p.aType).FFieldTypes.Count;
        for i := 0 to n-1 do begin
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + PSVariantToString(PSGetRecField(p, i), '');
        end;
        Result := '(' + Result + ')';
      end;
    btPointer: Result := 'Nil';
    btClass, btInterface:
      begin
        Result := ClassVariantInfo(p, ClassProperties)
      end;
  else
    Result := tbtString(RPS_Invalid);
  end;
end;



function TIFErrorToString(x: TPSError; const Param: tbtString): tbtString;
begin
  Result := PSErrorToString(x,param);
end;

function PSErrorToString(x: TPSError; const Param: tbtString): tbtString;
{$IFDEF FPC}
var
  lOrd: Integer;
{$ENDIF}
begin
  {$IFDEF FPC}
  { Free Pascal, optimising, jumps through an unbounded table for a case that
    names every value: a value past the enumeration is answered here, as the
    else below answers it on Delphi }
  lOrd := Ord(x);
  if (lOrd < Ord(Low(TPSError))) or (lOrd > Ord(High(TPSError))) then begin
    Result := tbtString(RPS_UnknownError);
    Exit;
  end;
  {$ENDIF}
  case x of
    ErNoError: Result := tbtString(RPS_NoError);
    erCannotImport: Result := tbtString(Format (RPS_CannotImport, [Safestr(Param)]));
    erInvalidType: Result := tbtString(RPS_InvalidType);
    ErInternalError: Result := tbtString(RPS_InternalError);
    erInvalidHeader: Result := tbtString(RPS_InvalidHeader);
    erInvalidOpcode: Result := tbtString(RPS_InvalidOpcode);
    erInvalidOpcodeParameter: Result := tbtString(RPS_InvalidOpcodeParameter);
    erNoMainProc: Result := tbtString(RPS_NoMainProc);
    erOutOfGlobalVarsRange: Result := tbtString(RPS_OutOfGlobalVarsRange);
    erOutOfProcRange: Result := tbtString(RPS_OutOfProcRange);
    ErOutOfRange: Result := tbtString(RPS_OutOfRange);
    erOutOfStackRange: Result := tbtString(RPS_OutOfStackRange);
    ErTypeMismatch: Result := tbtString(RPS_TypeMismatch);
    erUnexpectedEof: Result := tbtString(RPS_UnexpectedEof);
    erVersionError: Result := tbtString(RPS_VersionError);
    ErDivideByZero: Result := tbtString(RPS_DivideByZero);
    erMathError: Result := tbtString(RPS_MathError);
    erCouldNotCallProc: begin Result := tbtString(RPS_CouldNotCallProc); if (Param <> '') then Result := result +' ('+Param+')'; end;
    erOutofRecordRange: Result := tbtString(RPS_OutofRecordRange);
    erNullPointerException: Result := tbtString(RPS_NullPointerException);
    erNullVariantError: Result := tbtString(RPS_NullVariantError);
    erOutOfMemory: Result := tbtString(RPS_OutOfMemory);
    erException: Result := tbtString(Format (RPS_Exception, [Param]));
    erInterfaceNotSupported: Result := tbtString(RPS_InterfaceNotSupported);
    erCustomError: Result := Param;
      else
    Result := tbtString(RPS_UnknownError);
  end;
  //
end;


procedure TPSTypeRec.CalcSize;
begin
  case BaseType of
    btVariant: FRealSize := sizeof(Variant);
    btChar, bts8, btU8: FrealSize := 1 ;
    {$IFNDEF PS_NOWIDESTRING}btWideChar, {$ENDIF}bts16, btU16: FrealSize := 2;
    {$IFNDEF PS_NOWIDESTRING}btWideString,
    btUnicodeString,
    {$ENDIF}{$IFNDEF PS_NOINTERFACES}btInterface, {$ENDIF}
    btclass, btPChar, btString: FrealSize := PointerSize;
    btSingle, bts32, btU32: FRealSize := 4;
    btProcPtr: FRealSize := 3 * sizeof(Pointer);
    btCurrency: FrealSize := Sizeof(Currency);
    btPointer: FRealSize := 3 * sizeof(Pointer); // ptr, type, freewhendone
    btDouble{$IFNDEF PS_NOINT64}, bts64, btU64{$ENDIF}: FrealSize := 8;
    btExtended: FrealSize := SizeOf(Extended);
    btReturnAddress: FrealSize := Sizeof(TBTReturnAddress);
  else
    FrealSize := 0;
  end;
end;

constructor TPSTypeRec.Create(Owner: TPSExec);
begin
  inherited Create;
  FAttributes := TPSRuntimeAttributes.Create(Owner);
end;

destructor TPSTypeRec.Destroy;
begin
  FAttributes.Free;
  inherited destroy;
end;

{ TPSTypeRec_Record }

procedure TPSTypeRec_Record.CalcSize;
begin
  inherited;
  FrealSize := TPSTypeRec(FFieldTypes[FFieldTypes.Count-1]).RealSize +
    IPointer(RealFieldOffsets[RealFieldOffsets.Count -1]);
end;

constructor TPSTypeRec_Record.Create(Owner: TPSExec);
begin
  inherited Create(Owner);
  FRealFieldOffsets := TPSList.Create;
  FFieldTypes := TPSList.Create;
end;

destructor TPSTypeRec_Record.Destroy;
begin
  FFieldTypes.Free;
  FRealFieldOffsets.Free;
  inherited Destroy;
end;


const
  RTTISize = sizeof(TPSVariant);

procedure InitializeVariant(p: Pointer; aType: TPSTypeRec);
var
  t: TPSTypeRec;
  i: Longint;
begin
  case aType.BaseType of
    btChar, bts8, btU8: tbtu8(p^) := 0;
    {$IFNDEF PS_NOWIDESTRING}btWideChar, {$ENDIF}bts16, btU16: tbtu16(p^) := 0;
    btSingle: TbtSingle(P^) := 0;
    bts32, btU32: TbtU32(P^) := 0;
    btPChar, btString, {$IFNDEF PS_NOWIDESTRING}btUnicodeString, btWideString, {$ENDIF}btClass,
    btInterface, btArray: Pointer(P^) := nil;
    btPointer:
      begin
        Pointer(p^) := nil;
        Pointer(Pointer(IPointer(p)+PointerSize)^) := nil;
        Pointer(Pointer(IPointer(p)+(2*PointerSize))^) := nil;
      end;
    btProcPtr:
      begin
        tbtu32(p^) := 0;
        Pointer(Pointer(IPointer(p)+PointerSize)^) := nil;
        Pointer(Pointer(IPointer(p)+(2*PointerSize))^) := nil;
      end;
    btCurrency: tbtCurrency(P^) := 0;
    btDouble{$IFNDEF PS_NOINT64}, bts64, btU64{$ENDIF}: {$IFNDEF PS_NOINT64}tbtS64(P^) := 0{$ELSE}tbtdouble(p^) := 0 {$ENDIF};
    btExtended: tbtExtended(p^) := 0;
    btVariant: Initialize(Variant(p^));
    btReturnAddress:; // there is no point in initializing a return address
    btRecord:
      begin
        for i := 0 to TPSTypeRec_Record(aType).FFieldTypes.Count -1 do
        begin
          t := TPSTypeRec_Record(aType).FieldTypes[i];
          InitializeVariant(P, t);
          p := Pointer(IPointer(p) + t.FrealSize);
        end;
      end;
    btStaticArray:
      begin
        t := TPSTypeRec_Array(aType).ArrayType;
        for i := 0 to TPSTypeRec_StaticArray(aType).Size -1 do
        begin
          InitializeVariant(p, t);
          p := Pointer(IPointer(p) + t.RealSize);
        end;
      end;
    btSet:
      begin
        FillChar(p^, TPSTypeRec_Set(aType).RealSize, 0);
      end;
  end;
end;

procedure DestroyHeapVariant2(v: Pointer; aType: TPSTypeRec); forward;

const
  NeedFinalization = [btStaticArray, btRecord, btArray, btPointer, btVariant {$IFNDEF PS_NOINTERFACES}, btInterface{$ENDIF}, btString {$IFNDEF PS_NOWIDESTRING}, btUnicodestring,btWideString{$ENDIF}];

type
  TDynArrayRecHeader = packed record
    {$ifdef FPC}
    refCnt : ptrint;
    high : tdynarrayindex;
    {$else}
    {$ifdef CPUX64}
    _Padding: LongInt; // Delphi XE2+ expects 16 byte align
    {$endif}
    /// dynamic array reference count (basic garbage memory mechanism)
    refCnt: Longint;
    /// length in element count
    // - size in bytes = length*ElemSize
    length: IPointer;
    {$endif}
  end;
  TDynArrayRec = packed record
    header : TDynArrayRecHeader;
    datas : pointer;
  end;
  PDynArrayRec = ^TDynArrayRec;

{ True when the type is managed and needs reference counting or finalization,
  so cannot simply be copied. Unlike NeedFinalization this looks inside records
  and static arrays. Matches what Delphi/FPC considers managed, with btPointer as
  an exception. btPointer has no native counterpart but it can own and destroy
  the data it points to, see FinalizeVariant, so cannot simply be copied. }
function IsManagedType(aType: TPSTypeRec): Boolean;
var
  t: TPSTypeRec;
  i: Longint;
begin
  case aType.BaseType of
    btString, {$IFNDEF PS_NOWIDESTRING} btUnicodeString, btWideString, {$ENDIF}
    {$IFNDEF PS_NOINTERFACES} btInterface, {$ENDIF} btArray, btPointer, btVariant:
      Result := True;
    btRecord:
      begin
        for i := 0 to TPSTypeRec_Record(aType).FieldTypes.Count -1 do
        begin
          t := TPSTypeRec_Record(aType).FieldTypes[i];
          if IsManagedType(t) then
          begin
            Result := True;
            exit;
          end;
        end;
        Result := False;
      end;
    btStaticArray:
      Result := IsManagedType(TPSTypeRec_Array(aType).ArrayType);
  else
    Result := False;
  end;
end;

{$IFNDEF PS_NOINTERFACES}
{ stores an interface reference in Delphi's order (_IntfCopy, _IntfClear):
  the variable holds the new value before the old one is released, so what
  the release runs (a native destructor running a script event) does not
  find the old value there, nor copy it out when it moves the container.
  Free Pascal's own interface assignment releases first. }
procedure SetInterfaceVar(var Dest: Pointer; Source: Pointer);
var
  lOld: Pointer;
begin
  if Source <> nil then
    IUnknown(Source)._AddRef;
  lOld := Dest;
  Dest := Source;
  if lOld <> nil then
    IUnknown(lOld)._Release;
end;
{$ENDIF}

procedure FinalizeVariant(p: Pointer; aType: TPSTypeRec);
var
  t: TPSTypeRec;
  elsize: Cardinal;
  i, l: Longint;
  darr: PDynArrayRec;
  lBlock: Pointer;
begin
  case aType.BaseType of
    btString: tbtString(p^) := '';
    {$IFNDEF PS_NOWIDESTRING}
    btWideString: tbtwidestring(p^) := '';
    btUnicodeString: tbtunicodestring(p^) := '';
    {$ENDIF}
    {$IFNDEF PS_NOINTERFACES}btInterface:
      begin
        {$IFNDEF DELPHI3UP}
        if IUnknown(p^) <> nil then
          IUnknown(p^).Release;
        {$ENDIF}
        SetInterfaceVar(Pointer(p^), nil);
      end; {$ENDIF}
    btVariant:
    begin
      try
        Finalize(Variant(p^));
      except
      end;
    end;
    btPointer:
      if Pointer(Pointer(IPointer(p)+PointerSize2)^) <> nil then
      begin
        { taken out of the slot before it is destroyed, as an interface
          variable is cleared before its release: what the destruction runs
          (a native destructor running a script event) does not reach the
          value through the slot }
        lBlock := Pointer(p^);
        Pointer(p^) := nil;
        DestroyHeapVariant2(lBlock, Pointer(Pointer(IPointer(p)+PointerSize)^));
      end;
    btArray:
      begin
        if IPointer(P^) = 0 then exit;
        darr := PDynArrayRec(IPointer(p^) - sizeof(TDynArrayRecHeader));
        { emptied first, whoever else shares the block, as Delphi's
          _DynArrayClear empties the variable before it releases the block:
          what a finalization runs (a native destructor running a script
          event) does not reach the block through this variable }
        Pointer(P^) := nil;
        if darr^.header.refCnt < 0 then exit;// refcount < 0 means don't free
        Dec(darr^.header.refCnt);
        if darr^.header.refCnt <> 0 then exit;
        lBlock := darr;
        t := TPSTypeRec_Array(aType).ArrayType;
        elsize := t.RealSize;
        {$IFDEF FPC}
        l := darr^.header.high + 1;
        {$ELSE}
        l := darr^.header.length;
        {$ENDIF FPC}
        darr := @darr^.datas;
        case t.BaseType of
          btString, {$IFNDEF PS_NOWIDESTRING}
          btUnicodeString, btWideString, {$ENDIF}{$IFNDEF PS_NOINTERFACES}btInterface, {$ENDIF}btArray, btStaticArray,
          btRecord, btPointer, btVariant:
            begin
              for i := 0 to l -1 do
              begin
                FinalizeVariant(darr, t);
                darr := Pointer(IPointer(darr) + elsize);
              end;
            end;
        end;
        FreeMem(lBlock, IPointer(Cardinal(l) * elsize) + SizeOf(TDynArrayRecHeader));
      end;
    btRecord:
      begin
        for i := 0 to TPSTypeRec_Record(aType).FFieldTypes.Count -1 do
        begin
          t := TPSTypeRec_Record(aType).FieldTypes[i];
          case t.BaseType of
            btString, {$IFNDEF PS_NOWIDESTRING}btUnicodeString, btWideString, {$ENDIF}{$IFNDEF PS_NOINTERFACES}btInterface, {$ENDIF}btArray, btStaticArray,
            btRecord, btPointer, btVariant: FinalizeVariant(p, t);
          end;
          p := Pointer(IPointer(p) + t.FrealSize);
        end;
      end;
    btStaticArray:
      begin
        t := TPSTypeRec_Array(aType).ArrayType;
        case t.BaseType of
          btString, {$IFNDEF PS_NOWIDESTRING}btUnicodeString, btWideString, {$ENDIF}{$IFNDEF PS_NOINTERFACES}btInterface, {$ENDIF}btArray, btStaticArray,
          btRecord, btPointer, btVariant: ;
          else Exit;
        end;
        for i := 0 to TPSTypeRec_StaticArray(aType).Size -1 do
        begin
          FinalizeVariant(p, t);
          p := Pointer(IPointer(p) + t.RealSize);
        end;
      end;
  end;
end;

function CreateHeapVariant2(aType: TPSTypeRec): Pointer;
begin
  GetMem(Result, aType.RealSize);
  InitializeVariant(Result, aType);
end;

procedure DestroyHeapVariant2(v: Pointer; aType: TPSTypeRec);
begin
  if v = nil then exit;
  if atype.BaseType in NeedFinalization then
    FinalizeVariant(v, aType);
  FreeMem(v, aType.RealSize);
end;


function CreateHeapVariant(aType: TPSTypeRec): PPSVariant;
var
  aSize: Longint;
begin
  { a type the loaded script lacks gives no value, which the helpers refuse }
  if aType = nil then
  begin
    Result := nil;
    exit;
  end;
  aSize := aType.RealSize + RTTISize;
  GetMem(Result, aSize);
  Result.FType := aType;
  InitializeVariant(Pointer(IPointer(Result)+PointerSize), aType);
end;

procedure DestroyHeapVariant(v: PPSVariant);
begin
  if v = nil then exit;
  if v.FType.BaseType in NeedFinalization then
    FinalizeVariant(Pointer(IPointer(v)+PointerSize), v.FType);
  FreeMem(v, v.FType.RealSize + RTTISize);
end;

procedure FreePSVariantList(l: TPSList);
var
  i: Longint;
begin
  for i:= l.count -1 downto 0 do
    DestroyHeapVariant(l[i]);
  l.free;
end;

procedure FreePIFVariantList(l: TPSList);
begin
  FreePsVariantList(l);
end;

{ TPSExec }

procedure TPSExec.ClearFunctionList;
var
  x: PProcRec;
  l: Longint;
begin
  for l := FAttributeTypes.Count -1 downto 0 do
  begin
    TPSAttributeType(FAttributeTypes.Data^[l]).Free;
  end;
  FAttributeTypes.Clear;

  for l := 0 to FRegProcs.Count - 1 do
  begin
    x := FRegProcs.Data^[l];
    if @x^.FreeProc <> nil then x^.FreeProc(Self, x);
    Dispose(x);
  end;
  FRegProcs.Clear;
  RegisterStandardProcs;
end;

class function TPSExec.About: tbtString;
begin
  Result := 'RemObjects Pascal Script. Copyright (c) 2004-2010 by RemObjects Software';
end;

procedure TPSExec.Cleanup;
var
  I: Longint;
  p: Pointer;
begin
  if FStatus <> isLoaded then
    exit;
  FStack.Clear;
  FTempVars.Clear;
  for I := Longint(FGlobalVars.Count) - 1 downto 0 do
  begin
    p := FGlobalVars.Items[i];
    if PIFTypeRec(P^).BaseType in NeedFinalization then
      FinalizeVariant(Pointer(IPointer(p)+PointerSize), Pointer(P^));
    InitializeVariant(Pointer(IPointer(p)+PointerSize), Pointer(P^));
  end;
end;

procedure TPSExec.Clear;
var
  I: Longint;
  temp: PPSResource;
  Proc: TPSResourceFreeProc;
  pp: TPSExceptionHandler;
begin
  for i := Longint(FExceptionStack.Count) -1 downto 0 do
  begin
    pp := FExceptionStack.Data^[i];
    pp.Free;
  end;
  FExceptionStack.Clear;
  { the script's values are released while the script can still run: what a
    release runs (a native destructor running a script event) needs the
    method records among the resources, the procs and the types -- and the
    locals an unhandled error left on the stack go before the globals, which
    their events may use }
  FStack.Clear;
  FTempVars.Clear;
  FGlobalVars.Clear;
  { each resource is taken out of the list before its release runs: a host
    looking a resource up from a release sees only those not yet released,
    and one it adds is released here too }
  while FResources.Count > 0 do
  begin
    Temp := FResources.Data^[Pred(Longint(FResources.Count))];
    FResources.DeleteLast;
    try
      Proc := Temp^.Proc;
      Proc(Self, Temp^.P);
    finally
      Dispose(Temp);
    end;
  end;
  for i := Longint(FExportedVars.Count) -1 downto 0 do
    Dispose(PPSExportedVar(FExportedVars.Data^[I]));
  for I := Longint(FProcs.Count) - 1downto 0  do
    TPSProcRec(FProcs.Data^[i]).Destroy;
  FProcs.Clear;
  for I := Longint(FTypes.Count) - 1downto 0  do
    TPSTypeRec(FTypes.Data^[i]).Free;
  FTypes.Clear;
  { nothing refers to the destroyed procs }
  FCurrProc := nil;
  FData := nil;
  FDataLength := 0;
  FStatus := isNotLoaded;
  FResources.Clear;
  FExportedVars.Clear;
  FCurrStackBase := InvalidVal;
end;

constructor TPSExec.Create;
begin
  inherited Create;
  FAttributeTypes := TPSList.Create;
  FExceptionStack := TPSList.Create;
  FCallCleanup := False;
  FResources := TPSList.Create;
  FTypes := TPSList.Create;
  FProcs := TPSList.Create;
  FGlobalVars := TPSStack.Create;
  FTempVars := TPSStack.Create;
  FMainProc := 0;
  FStatus := isNotLoaded;
  FRegProcs := TPSList.Create;
  FExportedVars := TPSList.create;
  FSpecialProcList := TPSList.Create;
  FOwnedImporters := TPSList.Create;
  RegisterStandardProcs;
  FReturnAddressType := TPSTypeRec.Create(self);
  FReturnAddressType.BaseType := btReturnAddress;
  FReturnAddressType.CalcSize;
  FVariantType := TPSTypeRec.Create(self);
  FVariantType.BaseType := btVariant;
  FVariantType.CalcSize;
  FVariantArrayType := TPSTypeRec_Array.Create(self);
  FVariantArrayType.BaseType := btArray;
  FVariantArrayType.CalcSize;
  TPSTypeRec_Array(FVariantArrayType).ArrayType := FVariantType;
  FStack := TPSStack.Create;
  FStack.UseChunks;
end;

destructor TPSExec.Destroy;
var
  I: Longint;
  x: PProcRec;
  P: PSpecialProc;
begin
  Clear;
  FReturnAddressType.Free;
  FVariantType.Free;
  FVariantArrayType.Free;

  if ExObject <> nil then ExObject.Free;
  for I := FSpecialProcList.Count -1 downto 0 do
  begin
    P := FSpecialProcList.Data^[I];
    Dispose(p);
  end;
  for I := Pred(FOwnedImporters.Count) downto 0 do
    TObject(FOwnedImporters.Data^[I]).Free;
  FOwnedImporters.Free;
  FResources.Free;
  FExportedVars.Free;
  FTempVars.Free;
  FStack.Free;
  FGlobalVars.Free;
  FProcs.Free;
  FTypes.Free;
  FSpecialProcList.Free;
  for i := FRegProcs.Count - 1 downto 0 do
  begin
    x := FRegProcs.Data^[i];
    if @x^.FreeProc <> nil then x^.FreeProc(Self, x);
    Dispose(x);
  end;
  FRegProcs.Free;
  FExceptionStack.Free;
  for i := FAttributeTypes.Count -1 downto 0 do
  begin
    TPSAttributeType(FAttributeTypes[i]).Free;
  end;
  FAttributeTypes.Free;
  inherited Destroy;
end;

procedure TPSExec.ExceptionProc(proc, Position: Cardinal; Ex: TPSError; const s: tbtString; NewObject: TObject);
var
  d, l: Longint;
  pp: TPSExceptionHandler;

  { aFrame's finally runs for the exception: the frame holds it until the
    finally ends, so that what the finally does cannot take it }
  procedure HoldIn(aFrame: TPSExceptionHandler);
  begin
    aFrame.DropException;
    aFrame.Unwinding := True;
    aFrame.ExceptionProcNo := ExProc;
    aFrame.ExceptionPos := ExPos;
    aFrame.ExceptionData := ExEx;
    aFrame.ExceptionParam := ExParam;
    aFrame.ExceptionObject := ExObject;
    ExObject := nil;
    ExEx := ENoError;
  end;

begin
  ExProc := proc;
  ExPos := Position;
  ExEx := Ex;
  ExParam := s;
  if ExObject <> nil then
    ExObject.Free;
  ExObject := NewObject;
  if Ex = eNoError then Exit;
  if FRaisedCount = High(Cardinal) then
    FRaisedCount := 0
  else
    Inc(FRaisedCount);
  for d := FExceptionStack.Count -1 downto 0 do
  begin
    pp := FExceptionStack[d];
    { an exception escaping a finally replaces the one the finally ran for }
    if pp.Unwinding then
      pp.DropException;
    if Cardinal(FStack.Count) > pp.StackSize then
    begin
      for l := Longint(FStack.count) -1 downto Longint(pp.StackSize) do
        FStack.Pop;
    end;
    if pp.CurrProc = nil then // no point in continuing
    begin
      pp.Free;
      FExceptionStack.DeleteLast;

      FCurrStackBase := InvalidVal;
      { a Stop made before the exception stands }
      if FStatus = isRunning then
        FStatus := isPaused;
      exit;
    end;
    FCurrProc := pp.CurrProc;
    FData := FCurrProc.Data;
    FDataLength := FCurrProc.Length;

    FCurrStackBase := pp.BasePtr;
    if pp.FinallyOffset <> InvalidVal then
    begin
      FCurrentPosition := pp.FinallyOffset;
      pp.FinallyOffset := InvalidVal;
      HoldIn(pp);
      Exit;
    end else if (pp.ExceptOffset <> InvalidVal) and (pp.ExceptOffset <> Cardinal(InvalidVal -1)) then
    begin
        FCurrentPosition := pp.ExceptOffset;
      pp.ExceptOffset := Cardinal(InvalidVal -1);
      { the exception cancels the jump whose finally raised it }
      pp.ExitPoint := InvalidVal;
      pp.ExceptionProcNo := ExProc;
      pp.ExceptionPos := ExPos;
      pp.ExceptionObject := ExObject;
      pp.ExceptionData := ExEx;
      pp.ExceptionParam := ExParam;
      ExObject := nil;
      ExEx := ENoError;
      Exit;
    end else if pp.Finally2Offset <> InvalidVal then
    begin
      FCurrentPosition := pp.Finally2Offset;
      pp.Finally2Offset := InvalidVal;
      { the except before the second finally is over }
      pp.ExceptOffset := InvalidVal;
      HoldIn(pp);
      Exit;
    end;
    pp.Free;
    FExceptionStack.DeleteLast;
  end;
  { a Stop made before the exception stands }
  if FStatus = isRunning then
    FStatus := isPaused;
end;

procedure TPSExec.ResumeUnwinding;
var
  pp      : TPSExceptionHandler;
  lProcNo : Cardinal;
  lPos    : Cardinal;
  lData   : TPSError;
  lParam  : tbtString;
  lObject : TObject;
begin
  pp := FExceptionStack[FExceptionStack.Count -1];
  lProcNo := pp.ExceptionProcNo;
  lPos := pp.ExceptionPos;
  lData := pp.ExceptionData;
  lParam := pp.ExceptionParam;
  lObject := pp.ExceptionObject;
  pp.ExceptionObject := nil;
  pp.Free;
  FExceptionStack.DeleteLast;
  ExceptionProc(lProcNo, lPos, lData, lParam, lObject);
end;

function LookupProc(List: TPSList; const Name: ShortString): PProcRec;
var
  h, l: Longint;
  p: PProcRec;
begin
  h := MakeHash(Name);
  for l := List.Count - 1 downto 0 do
  begin
    p := List.Data^[l];
    if (p^.Hash = h) and (p^.Name = Name) then
    begin
      Result := List[l];
      exit;
    end;
  end;
  Result := nil;
end;

function TPSExec.ImportProc(const Name: ShortString; proc: TPSExternalProcRec): Boolean;
var
  u: PProcRec;
  fname: tbtString;
  I, fnh: Longint;
  P: PSpecialProc;

begin
  if name = '' then
  begin
    fname := proc.Decl;
    fname := copy(fname, 1, pos(tbtchar(':'), fname)-1);
    fnh := MakeHash(fname);
    for I := FSpecialProcList.Count -1 downto 0 do
    begin
      p := FSpecialProcList[I];
      IF (p^.name = '') or ((p^.namehash = fnh) and (p^.name = fname)) then
      begin
        if p^.P(Self, Proc, p^.tag) then
        begin
          Result := True;
          exit;
        end;
      end;
    end;
    Result := FAlse;
    exit;
  end;
  u := LookupProc(FRegProcs, Name);
  if u = nil then begin
    Result := False;
    exit;
  end;
{$IFDEF LOG}
  __Log('Name='+string(Name)+', ProcPtr='+intToStr(IPointer(@u^.ProcPtr))+', Ext1='+intToStr(IPointer(u^.Ext1)));
{$ENDIF}
  proc.ProcPtr := u^.ProcPtr;
  proc.Ext1 := u^.Ext1;
  proc.Ext2 := u^.Ext2;
  Result := True;
end;

function TPSExec.RegisterFunctionName(const Name: tbtString; ProcPtr: TPSProcPtr; Ext1, Ext2: Pointer): PProcRec;
var
  p: PProcRec;
  s: tbtString;
begin
  s := FastUppercase(Name);
  New(p);
  p^.Name := s;
  p^.Hash := MakeHash(s);
  p^.ProcPtr := ProcPtr;
  p^.FreeProc := nil;
  p^.Ext1 := Ext1;
  p^.Ext2 := Ext2;
  FRegProcs.Add(p);
  Result := P;
end;

function TPSExec.LoadData(const s: tbtString): Boolean;
var
  HDR: TPSHeader;
  Pos: Cardinal;

  function read(var Data; Len: Cardinal): Boolean;
  begin
    if Longint(Pos + Len) <= Length(s) then begin
      Move(s[Pos + 1], Data, Len);
      Pos := Pos + Len;
      read := True;
    end
    else
      read := False;
  end;
  function ReadAttributes(Dest: TPSRuntimeAttributes): Boolean;
  var
    Count: Cardinal;
    i: Integer;

    function ReadAttrib: Boolean;
    var
      NameLen: Longint;
      Name: tbtString;
      TypeNo: Cardinal;
      i, h, FieldCount: Longint;
      att: TPSRuntimeAttribute;
      varp: PIFVariant;

    begin
      if (not Read(NameLen, 4)) or (NameLen < 0) or (NameLen > Length(s) - Longint(Pos)) then
      begin
        CMD_Err(ErOutOfRange);
        Result := false;
        exit;
      end;
      SetLength(Name, NameLen);
      if not Read(Name[1], NameLen) then
      begin
        CMD_Err(ErOutOfRange);
        Result := false;
        exit;
      end;
      if not Read(FieldCount, 4) then
      begin
        CMD_Err(ErOutOfRange);
        Result := false;
        exit;
      end;
      att := Dest.Add;
      att.AttribType := Name;
      att.AttribTypeHash := MakeHash(att.AttribType);
      for i := 0 to FieldCount -1 do
      begin
        if (not Read(TypeNo, 4)) or (TypeNo >= Cardinal(FTypes.Count)) then
        begin
          CMD_Err(ErOutOfRange);
          Result := false;
          exit;
        end;

        varp := att.AddValue(FTypes[TypeNo]);
        case VarP^.FType.BaseType of
          btSet:
            begin
              if not read(PPSVariantSet(varp).Data, TPSTypeRec_Set(varp.FType).aByteSize) then
              begin
                CMD_Err(erOutOfRange);
                Result := False;
                exit;
              end;
            end;
          bts8, btchar, btU8: if not read(PPSVariantU8(VarP)^.data, SizeOf(tbtu8)) then
          begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          bts16, {$IFNDEF PS_NOWIDESTRING}btwidechar,{$ENDIF} btU16: if not read(PPSVariantU16(Varp)^.Data, SizeOf(TbtU16)) then begin
              CMD_Err(ErOutOfRange);
              Result := False;
              exit;
            end;
          bts32, btU32, btProcPtr: if not read(PPSVariantU32(VarP)^.Data, SizeOf(tbtu32)) then
            begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          {$IFNDEF PS_NOINT64}
          bts64: if not read(PPSVariantS64(VarP)^.Data, sizeof(tbts64)) then
            begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          btU64: if not read(PPSVariantU64(VarP)^.Data, sizeof(tbtu64)) then
            begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          {$ENDIF}
          btSingle: if not read(PPSVariantSingle(VarP)^.Data, SizeOf(TbtSingle))
            then begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          btDouble: if not read(PPSVariantDouble(varp)^.Data, SizeOf(TbtDouble))
            then begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          btExtended: if not read(PPSVariantExtended(varp)^.Data, SizeOf(TbtExtended))
            then begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          btCurrency: if not read(PPSVariantCurrency(varp)^.Data, SizeOf(tbtCurrency))
            then begin
              CMD_Err(erOutOfRange);
              Result := False;
              exit;
            end;
          btPchar, btString:
          begin
            if (not read(NameLen, 4)) or (NameLen < 0) or (NameLen > Length(s) - Longint(Pos)) then
            begin
                Cmd_Err(erOutOfRange);
                Result := False;
                exit;
              end;
              SetLength(PPSVariantAString(varp)^.Data, NameLen);
              if not read(PPSVariantAString(varp)^.Data[1], NameLen) then begin
                CMD_Err(erOutOfRange);
                Result := False;
                exit;
              end;
            end;
          {$IFNDEF PS_NOWIDESTRING}
          btWidestring:
            begin
              if (not read(NameLen, 4)) or (NameLen < 0) or (NameLen > (Length(s) - Longint(Pos)) div 2) then
              begin
                Cmd_Err(erOutOfRange);
                Result := False;
                exit;
              end;
              SetLength(PPSVariantWString(varp).Data, NameLen);
              if not read(PPSVariantWString(varp).Data[1], NameLen*2) then begin
                CMD_Err(erOutOfRange);
                Result := False;
                exit;
              end;
            end;
          btUnicodeString:
            begin
              if (not read(NameLen, 4)) or (NameLen < 0) or (NameLen > (Length(s) - Longint(Pos)) div 2) then
              begin
                Cmd_Err(erOutOfRange);
                Result := False;
                exit;
              end;
              SetLength(PPSVariantUString(varp).Data, NameLen);
              if not read(PPSVariantUString(varp).Data[1], NameLen*2) then begin
                CMD_Err(erOutOfRange);
                Result := False;
                exit;
              end;
            end;
          {$ENDIF}
        else begin
            CMD_Err(erInvalidType);
            Result := False;
            exit;
          end;
        end;
      end;
      h := MakeHash(att.AttribType);
      for i := FAttributeTypes.Count -1 downto 0 do
      begin
        if (TPSAttributeType(FAttributeTypes.Data^[i]).TypeNameHash = h) and
          (TPSAttributeType(FAttributeTypes.Data^[i]).TypeName = att.AttribType) then
        begin
          if not TPSAttributeType(FAttributeTypes.Data^[i]).UseProc(Self, att.AttribType, Att) then
          begin
            Result := False;
            exit;
          end;
        end;
      end;
      Result := True;
    end;


  begin
    if not Read(Count, 4) then
    begin
      CMD_Err(erOutofRange);
      Result := false;
      exit;
    end;
    for i := 0 to Count -1 do
    begin
      if not ReadAttrib then
      begin
        Result := false;
        exit;
      end;
    end;
    Result := True;
  end;

{$WARNINGS OFF}

  function LoadTypes: Boolean;
  var
    currf: TPSType;
    Curr: PIFTypeRec;
    fe: Boolean;
    l2, l: Longint;
    d: Cardinal;

    { the sum of a record's field sizes, which the Longint offsets below wrap }
    function RecordSize(Dta: TPSTypeRec_Record): Int64;
    var
      l: Longint;
    begin
      Result := 0;
      for l := 0 to Dta.FieldTypes.Count -1 do
        Result := Result + TPSTypeRec(Dta.FieldTypes[l]).RealSize;
    end;

    function resolve(Dta: TPSTypeRec_Record): Boolean;
    var
      offs, l: Longint;
    begin
      offs := 0;
      for l := 0 to Dta.FieldTypes.Count -1 do
      begin
        Dta.RealFieldOffsets.Add(Pointer(offs));
        offs := offs + TPSTypeRec(Dta.FieldTypes[l]).RealSize;
      end;
      Result := True;
    end;
  begin
    LoadTypes := True;
    for l := 0 to HDR.TypeCount - 1 do begin
      if not read(currf, SizeOf(currf)) then begin
        cmd_err(erUnexpectedEof);
        LoadTypes := False;
        exit;
      end;
      if (currf.BaseType and 128) <> 0 then begin
        fe := True;
        currf.BaseType := currf.BaseType - 128;
      end else
        fe := False;
      case currf.BaseType of
        {$IFNDEF PS_NOINT64}bts64, btU64, {$ENDIF}
        btU8, btS8, btU16, btS16, btU32, btS32, btSingle, btDouble, btCurrency,
        btExtended, btString, btPointer, btPChar,
        btVariant, btChar{$IFNDEF PS_NOWIDESTRING}, btUnicodeString, btWideString, btWideChar{$ENDIF}: begin
            curr := TPSTypeRec.Create(self);
            Curr.BaseType := currf.BaseType;
            FTypes.Add(Curr);
          end;
        btClass:
          begin
            Curr := TPSTypeRec_Class.Create(self);
            if (not Read(d, 4)) or (d > 255) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            setlength(TPSTypeRec_Class(Curr).FCN, d);
            if not Read(TPSTypeRec_Class(Curr).FCN[1], d) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            Curr.BaseType := currf.BaseType;
            FTypes.Add(Curr);
          end;
        btProcPtr:
          begin
            Curr := TPSTypeRec_ProcPtr.Create(self);
            if (not Read(d, 4)) or (d > 255) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            setlength(TPSTypeRec_ProcPtr(Curr).FParamInfo, d);
            if not Read(TPSTypeRec_ProcPtr(Curr).FParamInfo[1], d) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            Curr.BaseType := currf.BaseType;
            FTypes.Add(Curr);
          end;
{$IFNDEF PS_NOINTERFACES}
        btInterface:
          begin
            Curr := TPSTypeRec_Interface.Create(self);
            if not Read(TPSTypeRec_Interface(Curr).FGUID, Sizeof(TGuid)) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            Curr.BaseType := currf.BaseType;
            FTypes.Add(Curr);
          end;
{$ENDIF}
        btSet:
          begin
            Curr := TPSTypeRec_Set.Create(self);
            if not Read(d, 4) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            if (d > 256) then
            begin
              curr.Free;
              cmd_err(erTypeMismatch);
              LoadTypes := False;
              exit;
            end;

            TPSTypeRec_Set(curr).aBitSize := d;
            TPSTypeRec_Set(curr).aByteSize := TPSTypeRec_Set(curr).aBitSize shr 3;
            if (TPSTypeRec_Set(curr).aBitSize and 7) <> 0 then inc(TPSTypeRec_Set(curr).fbytesize);
            Curr.BaseType := currf.BaseType;
            FTypes.Add(Curr);
          end;
        btStaticArray:
          begin
            curr := TPSTypeRec_StaticArray.Create(self);
            if not Read(d, 4) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            if (d >= FTypes.Count) then
            begin
              curr.Free;
              cmd_err(erTypeMismatch);
              LoadTypes := False;
              exit;
            end;
            TPSTypeRec_StaticArray(curr).ArrayType := FTypes[d];
            if not Read(d, 4) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            if d > (MaxInt div 4) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            TPSTypeRec_StaticArray(curr).Size := d;
            if not Read(d,4) then                                             //<-additional StartOffset
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes:=false;
              Exit;
            end;
            TPSTypeRec_StaticArray(curr).StartOffset:=d;

            Curr.BaseType := currf.BaseType;
            FTypes.Add(Curr);
          end;
        btArray: begin
            Curr := TPSTypeRec_Array.Create(self);
            if not read(d, 4) then
            begin // Read type
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := False;
              exit;
            end;
            if (d >= FTypes.Count) then
            begin
              curr.Free;
              cmd_err(erTypeMismatch);
              LoadTypes := False;
              exit;
            end;
            Curr.BaseType := currf.BaseType;
            TPSTypeRec_Array(curr).ArrayType := FTypes[d];
            FTypes.Add(Curr);
          end;
        btRecord:
          begin
            curr := TPSTypeRec_Record.Create(self);
            if not read(d, 4) or (d = 0) then
            begin
              curr.Free;
              cmd_err(erUnexpectedEof);
              LoadTypes := false;
              exit;
            end;
            while d > 0 do
            begin
              if not Read(l2, 4) then
              begin
                curr.Free;
                cmd_err(erUnexpectedEof);
                LoadTypes := false;
                exit;
              end;
              if Cardinal(l2) >= FTypes.Count then
              begin
                curr.Free;
                cmd_err(ErOutOfRange);
                LoadTypes := false;
                exit;
              end;
              TPSTypeRec_Record(curR).FFieldTypes.Add(FTypes[l2]);
              Dec(D);
            end;
            if not resolve(TPSTypeRec_Record(curr)) then
            begin
              curr.Free;
              cmd_err(erInvalidType);
              LoadTypes := False;
              exit;
            end;
            Curr.BaseType := currf.BaseType;
            FTypes.Add(Curr);
          end;
      else begin
          LoadTypes := False;
          CMD_Err(erInvalidType);
          exit;
        end;
      end;
      if fe then begin
        if not read(d, 4) then begin
          cmd_err(erUnexpectedEof);
          LoadTypes := False;
          exit;
        end;
        if d > PSAddrNegativeStackStart then
        begin
          cmd_err(erInvalidType);
          LoadTypes := False;
          exit;
        end;
        SetLength(Curr.FExportName, d);
        if not read(Curr.fExportName[1], d) then
        begin
          cmd_err(erUnexpectedEof);
          LoadTypes := False;
          exit;
        end;
        Curr.ExportNameHash := MakeHash(Curr.ExportName);
      end;
      curr.CalcSize;
      { a static array whose size a Longint cannot hold got a wrapped size, which every allocation then trusted }
      if ((curr is TPSTypeRec_StaticArray) and (Int64(TPSTypeRec_StaticArray(curr).ArrayType.RealSize) *
        TPSTypeRec_StaticArray(curr).Size > High(Longint))) or
        { so did a record whose fields' sizes sum past it }
        ((curr is TPSTypeRec_Record) and (RecordSize(TPSTypeRec_Record(curr)) > High(Longint))) then
      begin
        cmd_err(erInvalidType);
        LoadTypes := False;
        exit;
      end;
      if HDR.PSBuildNo >= 21 then // since build 21 we support attributes
      begin
        if not ReadAttributes(Curr.Attributes) then
        begin
          LoadTypes := False;
          exit;
        end;
      end;
    end;
  end;

  function LoadProcs: Boolean;
  var
    Rec: TPSProc;
    n: tbtString;
    b: Byte;
    l, L2, L3: Longint;
    Curr: TPSProcRec;
  begin
    LoadProcs := True;
    for l := 0 to HDR.ProcCount - 1 do begin
      if not read(Rec, SizeOf(Rec)) then begin
        cmd_err(erUnexpectedEof);
        LoadProcs := False;
        exit;
      end;
      if (Rec.Flags and 1) <> 0 then
      begin
        Curr := TPSExternalProcRec.Create(Self);
        if not read(b, 1) then begin
          Curr.Free;
          cmd_err(erUnexpectedEof);
          LoadProcs := False;
          exit;
        end;
        SetLength(n, b);
        if not read(n[1], b) then begin
          Curr.Free;
          cmd_err(erUnexpectedEof);
          LoadProcs := False;
          exit;
        end;
        TPSExternalProcRec(Curr).Name := n;
        if (Rec.Flags and 3 = 3) then
        begin
          if (not Read(L2, 4)) or (L2 < 0) or (L2 > Length(s) - Pos) then
          begin
            Curr.Free;
            cmd_err(erUnexpectedEof);
            LoadProcs := False;
            exit;
          end;
          SetLength(n, L2);
          Read(n[1], L2); // no check is needed
          TPSExternalProcRec(Curr).FDecl := n;
        end;
        if not ImportProc(TPSExternalProcRec(Curr).Name, TPSExternalProcRec(Curr)) then begin
          if TPSExternalProcRec(Curr).Name <> '' then
            CMD_Err2(erCannotImport, TPSExternalProcRec(Curr).Name)
          else
            CMD_Err2(erCannotImport, TPSExternalProcRec(curr).Decl);
          Curr.Free;
          LoadProcs := False;
          exit;
        end;
      end else begin
        Curr := TPSInternalProcRec.Create(Self);
        if not read(L2, 4) then begin
          Curr.Free;
          cmd_err(erUnexpectedEof);
          LoadProcs := False;
          exit;
        end;
        if not read(L3, 4) then begin
          Curr.Free;
          cmd_err(erUnexpectedEof);
          LoadProcs := False;
          exit;
        end;
        if (L2 < 0) or (L3 <= 0) or (L2 >= Length(s)) or (Int64(L2) + L3 > Length(s)) then begin
          Curr.Free;
          cmd_err(erUnexpectedEof);
          LoadProcs := False;
          exit;
        end;

        GetMem(TPSInternalProcRec(Curr).FData, L3);
        Move(s[L2 + 1], TPSInternalProcRec(Curr).FData^, L3);
        TPSInternalProcRec(Curr).FLength := L3;
        if (Rec.Flags and 2) <> 0 then begin // exported
          if not read(L3, 4) then begin
            Curr.Free;
            cmd_err(erUnexpectedEof);
            LoadProcs := False;
            exit;
          end;
          if (L3 < 0) or (L3 > PSAddrNegativeStackStart) then begin
            Curr.Free;
            cmd_err(erUnexpectedEof);
            LoadProcs := False;
            exit;
          end;
          SetLength(TPSInternalProcRec(Curr).FExportName, L3);
          if not read(TPSInternalProcRec(Curr).FExportName[1], L3) then begin
            Curr.Free;
            cmd_err(erUnexpectedEof);
            LoadProcs := False;
            exit;
          end;
          if not read(L3, 4) then begin
            Curr.Free;
            cmd_err(erUnexpectedEof);
            LoadProcs := False;
            exit;
          end;
          if (L3 < 0) or (L3 > PSAddrNegativeStackStart) then begin
            Curr.Free;
            cmd_err(erUnexpectedEof);
            LoadProcs := False;
            exit;
          end;
          SetLength(TPSInternalProcRec(Curr).FExportDecl, L3);
          if not read(TPSInternalProcRec(Curr).FExportDecl[1], L3) then begin
            Curr.Free;
            cmd_err(erUnexpectedEof);
            LoadProcs := False;
            exit;
          end;
          TPSInternalProcRec(Curr).FExportNameHash := MakeHash(TPSInternalProcRec(Curr).ExportName);
        end;
      end;
      if (Rec.Flags and 4) <> 0 then
      begin
        if not ReadAttributes(Curr.Attributes) then
        begin
          Curr.Free;
          LoadProcs := False;
          exit;
        end;
      end;
      FProcs.Add(Curr);
    end;
  end;
{$WARNINGS ON}

  function LoadVars: Boolean;
  var
    l, n: Longint;
    e: PPSExportedVar;
    Rec: TPSVar;
    Curr: PIfVariant;
  begin
    LoadVars := True;
    for l := 0 to HDR.VarCount - 1 do begin
      if not read(Rec, SizeOf(Rec)) then begin
        cmd_err(erUnexpectedEof);
        LoadVars := False;
        exit;
      end;
      if Rec.TypeNo >= HDR.TypeCount then begin
        cmd_err(erInvalidType);
        LoadVars := False;
        exit;
      end;
      Curr := FGlobalVars.PushType(FTypes.Data^[Rec.TypeNo]);
      if Curr = nil then begin
        cmd_err(erInvalidType);
        LoadVars := False;
        exit;
      end;
      if (Rec.Flags and 1) <> 0 then
      begin
        if (not read(n, 4)) or (n < 0) or (n > Length(s) - Longint(Pos)) then begin
          cmd_err(erUnexpectedEof);
          LoadVars := False;
          exit;
        end;
        new(e);
        try
          SetLength(e^.FName, n);
          if not Read(e^.FName[1], n) then
          begin
            dispose(e);
            cmd_err(erUnexpectedEof);
            LoadVars := False;
            exit;
          end;
          e^.FNameHash := MakeHash(e^.FName);
          e^.FVarNo := FGlobalVars.Count;
          FExportedVars.Add(E);
        except
          dispose(e);
          cmd_err(erInvalidType);
          LoadVars := False;
        end;
        { left after the handler: Delphi XE3 to XE5 for Win64 keep the exception object of a handler left by a jump }
        if not Result then
          exit;
      end;
    end;
  end;

begin
  Clear;
  Pos := 0;
  LoadData := False;
  if not read(HDR, SizeOf(HDR)) then
  begin
    CMD_Err(erInvalidHeader);
    exit;
  end;
  if HDR.HDR <> PSValidHeader then
  begin
    CMD_Err(erInvalidHeader);
    exit;
  end;
  if (HDR.PSBuildNo > PSCurrentBuildNo) or (HDR.PSBuildNo < PSLowBuildSupport) then begin
    CMD_Err(erInvalidHeader);
    exit;
  end;
  if not LoadTypes then
  begin
    Clear;
    exit;
  end;
  if not LoadProcs then
  begin
    Clear;
    exit;
  end;
  if not LoadVars then
  begin
    Clear;
    exit;
  end;
  if (HDR.MainProcNo >= FProcs.Count) and (HDR.MainProcNo <> InvalidVal)then begin
    CMD_Err(erNoMainProc);
    Clear;
    exit;
  end;
  // Load Import Table
  FMainProc := HDR.MainProcNo;
  FStatus := isLoaded;
  Result := True;
end;


procedure TPSExec.Pause;
begin
  { a run RunProc began cannot be left part way to be resumed: its caller
    gets control back when it ends, so it runs on }
  if (FStatus = isRunning) and (FNestedRuns = 0) then
    FStatus := isPaused;
end;

function TPSExec.ReadData(var Data; Len: Cardinal): Boolean;
begin
  if FCurrentPosition + Len <= FDataLength then begin
    Move(FData^[FCurrentPosition], Data, Len);
    FCurrentPosition := FCurrentPosition + Len;
    Result := True;
  end
  else
    Result := False;
end;

procedure TPSExec.CMD_Err(EC: TPSError); // Error
begin
  CMD_Err3(ec, '', nil);
end;

procedure VNSetPointerTo(const Src: TPSVariantIFC; Data: Pointer; aType: TPSTypeRec);
begin
  if Src.aType.BaseType = btPointer then
  begin
    if atype.BaseType in NeedFinalization then
      FinalizeVariant(src.Dta, Src.aType);
    Pointer(Src.Dta^) := Data;
    Pointer(Pointer(IPointer(Src.Dta)+PointerSize)^) := aType;
    Pointer(Pointer(IPointer(Src.Dta)+(2*PointerSize))^) := nil;
  end;
end;

function VNGetObject(const Src: TPSVariantIFC): TObject;
begin
  Result := PSGetObject(Src.Dta, Src.aType);
end;

function VNGetUInt(const Src: TPSVariantIFC): Cardinal;
begin
  Result := PSGetUInt(Src.Dta, Src.aType);
end;

{$IFNDEF PS_NOINT64}
function VNGetInt64(const Src: TPSVariantIFC): Int64;
begin
  Result := PSGetInt64(Src.Dta, Src.aType);
end;
{$ENDIF}

function VNGetReal(const Src: TPSVariantIFC): Extended;
begin
  Result := PSGetReal(Src.Dta, Src.aType);
end;

function VNGetCurrency(const Src: TPSVariantIFC): Currency;
begin
  Result := PSGetCurrency(Src.Dta, Src.aType);
end;

function VNGetInt(const Src: TPSVariantIFC): Longint;
begin
  Result := PSGetInt(Src.Dta, Src.aType);
end;

function VNGetAnsiString(const Src: TPSVariantIFC): tbtString;
begin
  Result := PSGetAnsiString(Src.Dta, Src.aType);
end;

{$IFNDEF PS_NOWIDESTRING}
function VNGetWideString(const Src: TPSVariantIFC): tbtWideString;
begin
  Result := PSGetWideString(Src.Dta, Src.aType);
end;

function VNGetUnicodeString(const Src: TPSVariantIFC): tbtunicodestring;
begin
  Result := PSGetUnicodeString(Src.Dta, Src.aType);
end;
{$ENDIF}

procedure VNSetObject(const Src: TPSVariantIFC; const Val: TObject);
var
  Dummy: Boolean;
begin
  PSSetObject(Src.Dta, Src.aType, Dummy, Val);
end;

procedure VNSetUInt(const Src: TPSVariantIFC; const Val: Cardinal);
var
  Dummy: Boolean;
begin
  PSSetUInt(Src.Dta, Src.aType, Dummy, Val);
end;

{$IFNDEF PS_NOINT64}
procedure VNSetInt64(const Src: TPSVariantIFC; const Val: Int64);
var
  Dummy: Boolean;
begin
  PSSetInt64(Src.Dta, Src.aType, Dummy, Val);
end;

procedure VNSetUInt64(const Src: TPSVariantIFC; const Val: UInt64);
var
  Dummy: Boolean;
begin
  PSSetUInt64(Src.Dta, Src.aType, Dummy, Val);
end;
{$ENDIF}

procedure VNSetReal(const Src: TPSVariantIFC; const Val: Extended);
var
  Dummy: Boolean;
begin
  PSSetReal(Src.Dta, Src.aType, Dummy, Val);
end;

procedure VNSetCurrency(const Src: TPSVariantIFC; const Val: Currency);
var
  Dummy: Boolean;
begin
  PSSetCurrency(Src.Dta, Src.aType, Dummy, Val);
end;

procedure VNSetInt(const Src: TPSVariantIFC; const Val: Longint);
var
  Dummy: Boolean;
begin
  PSSetInt(Src.Dta, Src.aType, Dummy, Val);
end;

procedure VNSetAnsiString(const Src: TPSVariantIFC; const Val: tbtString);
var
  Dummy: Boolean;
begin
  PSSetAnsiString(Src.Dta, Src.aType, Dummy, Val);
end;

function VNGetString(const Src: TPSVariantIFC): String;
begin
  {$IFNDEF PS_NOWIDESTRING}
    {$IFDEF DELPHI2009UP}
    Result := VNGetUnicodeString(Src);
    {$ELSE}
    Result := VNGetAnsiString(Src);
    {$ENDIF}
  {$ELSE}
  Result := VNGetAnsiString(Src);
  {$ENDIF}
end;

procedure VNSetString(const Src: TPSVariantIFC; const Val: String);
begin
  {$IFNDEF PS_NOWIDESTRING}
    {$IFDEF DELPHI2009UP}
    VNSetUnicodeString(Src, Val);
    {$ELSE}
    VNSetAnsiString(Src, Val);
    {$ENDIF}
  {$ELSE}
  VNSetAnsiString(Src, Val);
  {$ENDIF}
end;

{$IFNDEF PS_NOWIDESTRING}
procedure VNSetWideString(const Src: TPSVariantIFC; const Val: tbtWideString);
var
  Dummy: Boolean;
begin
  PSSetWideString(Src.Dta, Src.aType, Dummy, Val);
end;

procedure VNSetUnicodeString(const Src: TPSVariantIFC; const Val: tbtunicodestring);
var
  Dummy: Boolean;
begin
  PSSetUnicodeString(Src.Dta, Src.aType, Dummy, Val);
end;

{$ENDIF}

function VGetUInt(const Src: PIFVariant): Cardinal;
begin
  Result := PSGetUInt(@PPSVariantData(src).Data, src.FType);
end;

{$IFNDEF PS_NOINT64}
function VGetInt64(const Src: PIFVariant): Int64;
begin
  Result := PSGetInt64(@PPSVariantData(src).Data, src.FType);
end;
{$ENDIF}

function VGetReal(const Src: PIFVariant): Extended;
begin
  Result := PSGetReal(@PPSVariantData(src).Data, src.FType);
end;

function VGetCurrency(const Src: PIFVariant): Currency;
begin
  Result := PSGetCurrency(@PPSVariantData(src).Data, src.FType);
end;

function VGetInt(const Src: PIFVariant): Longint;
begin
  Result := PSGetInt(@PPSVariantData(src).Data, src.FType);
end;

function VGetAnsiString(const Src: PIFVariant): tbtString;
begin
  Result := PSGetAnsiString(@PPSVariantData(src).Data, src.FType);
end;

{$IFNDEF PS_NOWIDESTRING}
function VGetWideString(const Src: PIFVariant): tbtWideString;
begin
  Result := PSGetWideString(@PPSVariantData(src).Data, src.FType);
end;

function VGetUnicodeString(const Src: PIFVariant): tbtunicodestring;
begin
  Result := PSGetUnicodeString(@PPSVariantData(src).Data, src.FType);
end;

{$ENDIF}


procedure VSetPointerTo(const Src: PIFVariant; Data: Pointer; aType: TPSTypeRec);
var
  temp: TPSVariantIFC;
begin
  if (Atype = nil) or (Data = nil) or (Src = nil) then raise Exception.Create(RPS_InvalidVariable);
  temp.Dta := @PPSVariantData(Src).Data;
  temp.aType := Src.FType;
  temp.VarParam := false;
  VNSetPointerTo(temp, Data, AType);
end;

procedure VSetUInt(const Src: PIFVariant; const Val: Cardinal);
var
  Dummy: Boolean;
begin
  PSSetUInt(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;

{$IFNDEF PS_NOINT64}
procedure VSetInt64(const Src: PIFVariant; const Val: Int64);
var
  Dummy: Boolean;
begin
  PSSetInt64(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;
{$ENDIF}

procedure VSetReal(const Src: PIFVariant; const Val: Extended);
var
  Dummy: Boolean;
begin
  PSSetReal(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;

procedure VSetCurrency(const Src: PIFVariant; const Val: Currency);
var
  Dummy: Boolean;
begin
  PSSetCurrency(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;

procedure VSetInt(const Src: PIFVariant; const Val: Longint);
var
  Dummy: Boolean;
begin
  PSSetInt(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;

procedure VSetAnsiString(const Src: PIFVariant; const Val: tbtString);
var
  Dummy: Boolean;
begin
  PSSetAnsiString(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;

function VGetString(const Src: PIFVariant): String;
begin
  {$IFNDEF PS_NOWIDESTRING}
    {$IFDEF DELPHI2009UP}
    Result := PSGetUnicodeString(@PPSVariantData(src).Data, src.FType);
    {$ELSE}
    Result := PSGetAnsiString(@PPSVariantData(src).Data, src.FType);
    {$ENDIF}
  {$ELSE}
  Result := PSGetAnsiString(@PPSVariantData(src).Data, src.FType);
  {$ENDIF}
end;

procedure VSetString(const Src: PIFVariant; const Val: string);
var
  Dummy: Boolean;
begin
  {$IFNDEF PS_NOWIDESTRING}
    {$IFDEF DELPHI2009UP}
    PSSetUnicodeString(@PPSVariantData(src).Data, src.FType, Dummy, Val);
    {$ELSE}
    PSSetAnsiString(@PPSVariantData(src).Data, src.FType, Dummy, Val);
    {$ENDIF}
  {$ELSE}
  PSSetAnsiString(@PPSVariantData(src).Data, src.FType, Dummy, Val);
  {$ENDIF}
end;


{$IFNDEF PS_NOWIDESTRING}
procedure VSetWideString(const Src: PIFVariant; const Val: tbtWideString);
var
  Dummy: Boolean;
begin
  PSSetWideString(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;

procedure VSetUnicodeString(const Src: PIFVariant; const Val: tbtunicodestring);
var
  Dummy: Boolean;
begin
  PSSetUnicodeString(@PPSVariantData(src).Data, src.FType, Dummy, Val);
end;


{$ENDIF}

{$IFNDEF PS_NOWIDESTRING}
function VarToWideStr(const Data: Variant): tbtunicodestring;
begin
  if not VarIsNull(Data) then
    Result := Data
  else
    Result := '';
end;
{$ENDIF}

function PSGetUInt(Src: Pointer; aType: TPSTypeRec): Cardinal;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := tbtu8(src^);
    btS8: Result := tbts8(src^);
    btU16: Result := tbtu16(src^);
    btS16: Result := tbts16(src^);
    btU32: Result := tbtu32(src^);
    btS32: Result := tbts32(src^);
  {$IFNDEF PS_NOINT64}
    btS64: Result := tbts64(src^);
    btU64: Result := tbtu64(src^);
{$ENDIF}
    btChar: Result := Ord(tbtchar(Src^));
{$IFNDEF PS_NOWIDESTRING}    btWideChar: Result := Ord(tbtwidechar(Src^));{$ENDIF}
    { a Variant converts as Delphi converts it, as PSGetInt does: text holding a number gives the number }
    btVariant: Result := Variant(src^);
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;

function PSGetObject(Src: Pointer; aType: TPSTypeRec): TObject;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btClass: Result := TObject(Src^);
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;

procedure PSSetObject(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; Const val: TObject);
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btClass: TObject(Src^) := Val;
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;


{$IFNDEF PS_NOINT64}
function PSGetInt64(Src: Pointer; aType: TPSTypeRec): Int64;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := tbtu8(src^);
    btS8: Result := tbts8(src^);
    btU16: Result := tbtu16(src^);
    btS16: Result := tbts16(src^);
    btU32: Result := tbtu32(src^);
    btS32: Result := tbts32(src^);
    btS64: Result := tbts64(src^);
    btU64: Result := tbtu64(src^);
    btChar: Result := Ord(tbtchar(Src^));
{$IFNDEF PS_NOWIDESTRING}
    btWideChar: Result := Ord(tbtwidechar(Src^));
{$ENDIF}
{$IFDEF DELPHI6UP}
    btVariant:   Result := Variant(src^);
{$ENDIF}
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;

{ the base type of a value, followed through a pointer: a division by a 64-bit divisor keeps its 64 bits }
function _DivisorBaseType(Src: Pointer; aType: TPSTypeRec): TPSBaseType;
begin
  if aType.BaseType = btPointer then
    aType := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
  if aType = nil then
    Result := btPointer
  else
    Result := aType.BaseType;
end;

function PSGetUInt64(Src: Pointer; aType: TPSTypeRec): UInt64;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := tbtu8(src^);
    btS8: Result := tbts8(src^);
    btU16: Result := tbtu16(src^);
    btS16: Result := tbts16(src^);
    btU32: Result := tbtu32(src^);
    btS32: Result := tbts32(src^);
    btS64: Result := tbts64(src^);
    btU64: Result := tbtu64(src^);
    btChar: Result := Ord(tbtchar(Src^));
{$IFNDEF PS_NOWIDESTRING}
    btWideChar: Result := Ord(tbtwidechar(Src^));
{$ENDIF}
{$IFDEF DELPHI6UP}
    btVariant:   Result := Variant(src^);
{$ENDIF}
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;
{$ENDIF}

function PSGetReal(Src: Pointer; aType: TPSTypeRec): Extended;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := tbtu8(src^);
    btS8: Result := tbts8(src^);
    btU16: Result := tbtu16(src^);
    btS16: Result := tbts16(src^);
    btU32: Result := tbtu32(src^);
    btS32: Result := tbts32(src^);
{$IFNDEF PS_NOINT64}
    btS64: Result := tbts64(src^);
    btU64: Result := tbtu64(src^);
{$ENDIF}
    btSingle: Result := tbtsingle(Src^);
    btDouble: Result := tbtdouble(Src^);
    btExtended: Result := tbtextended(Src^);
    btCurrency: Result := tbtcurrency(Src^);
    btVariant:  Result := Variant(src^);
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;

function PSGetCurrency(Src: Pointer; aType: TPSTypeRec): Currency;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := tbtu8(src^);
    btS8: Result := tbts8(src^);
    btU16: Result := tbtu16(src^);
    btS16: Result := tbts16(src^);
    btU32: Result := tbtu32(src^);
    btS32: Result := tbts32(src^);
  {$IFNDEF PS_NOINT64}
    btS64: Result := tbts64(src^);
    btU64: Result := tbtu64(src^);
  {$ENDIF}
    btSingle: Result := tbtsingle(Src^);
    btDouble: Result := tbtdouble(Src^);
    btExtended: Result := tbtextended(Src^);
    btCurrency: Result := tbtcurrency(Src^);
    btVariant:   Result := Variant(src^);
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;


function PSGetInt(Src: Pointer; aType: TPSTypeRec): Longint;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := tbtu8(src^);
    btS8: Result := tbts8(src^);
    btU16: Result := tbtu16(src^);
    btS16: Result := tbts16(src^);
    btU32: Result := tbtu32(src^);
    btS32: Result := tbts32(src^);
{$IFNDEF PS_NOINT64}
    btS64: Result := tbts64(src^);
    btU64: Result := tbtu64(src^);
{$ENDIF}
    btChar: Result := Ord(tbtchar(Src^));
{$IFNDEF PS_NOWIDESTRING}    btWideChar: Result := Ord(tbtwidechar(Src^));{$ENDIF}
    btVariant: Result := Variant(src^);
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;

function PSGetAnsiChar(Src: Pointer; aType: TPSTypeRec): tbtchar;
var Res : tbtString;
begin
  Res := PSGetAnsiString(Src,aType);
  if Length(Res) > 0 then
    Result := Res[{$IFDEF DELPHI17UP}Low(Res){$ELSE}1{$ENDIF}]
  else
    Result := #0;
end;

function PSGetAnsiString(Src: Pointer; aType: TPSTypeRec): tbtString;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := tbtchar(tbtu8(src^));
    btChar: Result := tbtchar(Src^);
    btPchar: Result := pansichar(src^);
{$IFNDEF PS_NOWIDESTRING}    btWideChar: Result := tbtString(tbtwidechar(Src^));{$ENDIF}
    btString: Result := tbtstring(src^);
{$IFNDEF PS_NOWIDESTRING}
    btUnicodeString: result := tbtString(tbtUnicodestring(src^));
    btWideString: Result := tbtString(tbtwidestring(src^));{$ENDIF}
    btVariant:  Result := tbtString(Variant(src^));
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;
{$IFNDEF PS_NOWIDESTRING}
function PSGetWideString(Src: Pointer; aType: TPSTypeRec): tbtWideString;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := chr(tbtu8(src^));
    btU16: Result := widechar(src^);
    btChar: Result := tbtwidestring(tbtchar(Src^));
    btPchar: Result := tbtwidestring(pansichar(src^));
    btWideChar: Result := tbtwidechar(Src^);
    btString: Result := tbtwidestring(tbtstring(src^));
    btWideString: Result := tbtwidestring(src^);
    btVariant:   Result := Variant(src^);
    btUnicodeString: result := tbtUnicodeString(src^);
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;

function PSGetUnicodeString(Src: Pointer; aType: TPSTypeRec): tbtunicodestring;
begin
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then raise Exception.Create(RPS_TypeMismatch);
  end;
  case aType.BaseType of
    btU8: Result := chr(tbtu8(src^));
    btU16: Result := widechar(src^);
    btChar: Result := tbtunicodestring(tbtchar(Src^));
    btPchar: Result := tbtunicodestring(pansichar(src^));
    btWideChar: Result := tbtwidechar(Src^);
    btString: Result := tbtunicodestring(tbtstring(src^));
    btWideString: Result := tbtwidestring(src^);
    btVariant:   Result := Variant(src^);
    btUnicodeString: result := tbtUnicodeString(src^);
    else raise Exception.Create(RPS_TypeMismatch);
  end;
end;
{$ENDIF}

procedure PSSetUInt(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Cardinal);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btU8: tbtu8(src^) := Val;
    btS8: tbts8(src^) := Val;
    btU16: tbtu16(src^) := Val;
    btS16: tbts16(src^) := Val;
    btProcPtr:
      begin
        tbtu32(src^) := Val;
        Pointer(Pointer(IPointer(Src)+PointerSize)^) := nil;
        Pointer(Pointer(IPointer(Src)+PointerSize2)^) := nil;
      end;
    btU32: tbtu32(src^) := Val;
    btS32: tbts32(src^) := Val;
{$IFNDEF PS_NOINT64}
    btS64: tbts64(src^) := Val;
    btU64: tbtu64(src^) := Val;
{$ENDIF}
    btChar: tbtchar(Src^) := tbtChar(Val);
{$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtwidechar(Src^) := tbtwidechar(Val);{$ENDIF}
    btSingle: tbtSingle(src^) := Val;
    btDouble: tbtDouble(src^) := Val;
    btCurrency: tbtCurrency(src^) := Val;
    btExtended: tbtExtended(src^) := Val;
    btVariant:
      begin
        try
          Variant(src^) := {$IFDEF DELPHI6UP}val{$ELSE}tbts32(val){$ENDIF};
        except
          Ok := false;
        end;
      end;
    else ok := false;
  end;
end;

{$IFNDEF PS_NOINT64}
procedure PSSetInt64(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Int64);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btU8: tbtu8(src^) := Val;
    btS8: tbts8(src^) := Val;
    btU16: tbtu16(src^) := Val;
    btS16: tbts16(src^) := Val;
    btU32: tbtu32(src^) := Val;
    btS32: tbts32(src^) := Val;
    btS64: tbts64(src^) := Val;
    btU64: tbtu64(src^) := Val;
    btChar: tbtchar(Src^) := tbtChar(Val);
{$IFNDEF PS_NOWIDESTRING}
    btWideChar: tbtwidechar(Src^) := tbtwidechar(Val);
{$ENDIF}
    btSingle: tbtSingle(src^) := Val;
    btDouble: tbtDouble(src^) := Val;
    btCurrency: tbtCurrency(src^) := Val;
    btExtended: tbtExtended(src^) := Val;
{$IFDEF DELPHI6UP}
    btVariant:
      begin
        try
          Variant(src^) := Val;
        except
          Ok := false;
        end;
      end;
{$ENDIF}
    else ok := false;
  end;
end;

procedure PSSetUInt64(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: UInt64);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    aType := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btU8: tbtu8(Src^) := Val;
    btS8: tbts8(Src^) := Val;
    btU16: tbtu16(Src^) := Val;
    btS16: tbts16(Src^) := Val;
    btU32: tbtu32(Src^) := Val;
    btS32: tbts32(Src^) := Val;
    btS64: tbts64(Src^) := Val;
    btU64: tbtu64(Src^) := Val;
    btChar: tbtchar(Src^) := tbtChar(Val);
{$IFNDEF PS_NOWIDESTRING}
    btWideChar: tbtwidechar(Src^) := tbtwidechar(Val);
{$ENDIF}
    btSingle: tbtSingle(Src^) := Val;
    btDouble: tbtDouble(Src^) := Val;
    btCurrency: tbtCurrency(Src^) := Val;
    btExtended: tbtExtended(Src^) := Val;
{$IFDEF DELPHI6UP}
    btVariant:
      begin
        try
          Variant(Src^) := Val;
        except
          Ok := false;
        end;
      end;
{$ENDIF}
    else Ok := false;
  end;
end;

{$ENDIF}

procedure PSSetReal(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Extended);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btSingle: tbtSingle(src^) := Val;
    btDouble: tbtDouble(src^) := Val;
    btCurrency: tbtCurrency(src^) := Val;
    btExtended: tbtExtended(src^) := Val;
    btVariant:
      begin
        try
          Variant(src^) := Val;
        except
          Ok := false;
        end;
      end;
    else ok := false;
  end;
end;

procedure PSSetCurrency(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Currency);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btSingle: tbtSingle(src^) := Val;
    btDouble: tbtDouble(src^) := Val;
    btCurrency: tbtCurrency(src^) := Val;
    btExtended: tbtExtended(src^) := Val;
    btVariant:
      begin
        try
          Variant(src^) := Val;
        except
          Ok := false;
        end;
      end;
    else ok := false;
  end;
end;

procedure PSSetInt(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: Longint);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btU8: tbtu8(src^) := Val;
    btS8: tbts8(src^) := Val;
    btU16: tbtu16(src^) := Val;
    btS16: tbts16(src^) := Val;
    btProcPtr:
      begin
        tbtu32(src^) := Val;
        Pointer(Pointer(IPointer(Src)+PointerSize)^) := nil;
        Pointer(Pointer(IPointer(Src)+PointerSize2)^) := nil;
      end;
    btU32: tbtu32(src^) := Val;
    btS32: tbts32(src^) := Val;
{$IFNDEF PS_NOINT64}
    btS64: tbts64(src^) := Val;
    btU64: tbtu64(src^) := Val;
{$ENDIF}
    btChar: tbtchar(Src^) := tbtChar(Val);
{$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtwidechar(Src^) := tbtwidechar(Val);{$ENDIF}
    btSingle: tbtSingle(src^) := Val;
    btDouble: tbtDouble(src^) := Val;
    btCurrency: tbtCurrency(src^) := Val;
    btExtended: tbtExtended(src^) := Val;
    btVariant:
      begin
        try
          Variant(src^) := Val;
        except
          Ok := false;
        end;
      end;
    else ok := false;
  end;
end;


procedure PSSetAnsiString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: tbtString);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btString: tbtstring(src^) := val;
    btChar: if AnsiString(val) <> '' then tbtchar(src^) := AnsiString(val)[1];
{$IFNDEF PS_NOWIDESTRING}
    btUnicodeString: tbtunicodestring(src^) := tbtUnicodeString(AnsiString(val));
    btWideString: tbtwidestring(src^) := tbtwidestring(AnsiString(val));
    btWideChar: if AnsiString(val) <> '' then tbtwidechar(src^) := tbtwidechar(AnsiString(val)[1]);
    {$ENDIF}
    btVariant:
      begin
        try
          Variant(src^) := Val;
        except
          Ok := false;
        end;
      end;
    else ok := false;
  end;
end;
{$IFNDEF PS_NOWIDESTRING}
procedure PSSetWideString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: tbtWideString);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btChar: if val <> '' then tbtchar(src^) := tbtChar(val[1]);
    btWideChar: if val <> '' then tbtwidechar(src^) := val[1];
    btString: tbtstring(src^) := tbtString(val);
    btWideString: tbtwidestring(src^) := val;
    btUnicodeString: tbtunicodestring(src^) := val;
    btVariant:
      begin
        try
          Variant(src^) := Val;
        except
          Ok := false;
        end;
      end;
    else ok := false;
  end;
end;

procedure PSSetUnicodeString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: tbtunicodestring);
begin
  if (Src = nil) or (aType = nil) then begin Ok := false; exit; end;
  if aType.BaseType = btPointer then
  begin
    atype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
    Src := Pointer(Src^);
    if (src = nil) or (aType = nil) then begin Ok := false; exit; end;
  end;
  case aType.BaseType of
    btChar: if val <> '' then tbtchar(src^) := tbtChar(val[1]);
    btWideChar: if val <> '' then tbtwidechar(src^) := val[1];
    btString: tbtstring(src^) := tbtString(val);
    btWideString: tbtwidestring(src^) := val;
    btUnicodeString: tbtunicodestring(src^) := val;
    btVariant:
      begin
        try
          Variant(src^) := Val;
        except
          Ok := false;
        end;
      end;
    else ok := false;
  end;
end;
{$ENDIF}

function PSGetString(Src: Pointer; aType: TPSTypeRec): string;
begin
  {$IFNDEF PS_NOWIDESTRING}
    {$IFDEF DELPHI2009UP}
    result := PSGetUnicodeString(Src, aType);
    {$ELSE}
    result := PSGetAnsiString(Src, aType);
    {$ENDIF}
  {$ELSE}
  result := PSGetAnsiString(Src, aType);
  {$ENDIF}
end;

procedure PSSetString(Src: Pointer; aType: TPSTypeRec; var Ok: Boolean; const Val: String);
begin
  {$IFNDEF PS_NOWIDESTRING}
    {$IFDEF DELPHI2009UP}
    PSSetUnicodeString(Src, aType, Ok, Val);
    {$ELSE}
    PSSetAnsiString(Src, aType, Ok, Val);
    {$ENDIF}
  {$ELSE}
  PSSetAnsiString(Src, aType, Ok, Val);
  {$ENDIF}
end;


function CopyArrayContents(dest, src: Pointer; Len: Longint; aType: TPSTypeRec): Boolean; forward;

function IsZeroBlock(p: Pointer; Size: Cardinal): Boolean;
var
  lIdx: Cardinal;
begin
  Result := False;
  lIdx := 0;
  while lIdx < Size do
  begin
    if PAnsiChar(IPointer(p) + lIdx)^ <> #0 then
      exit;
    Inc(lIdx);
  end;
  Result := True;
end;

{ whether releasing a value of the type can run code: an interface, or what
  may hold one (a string's release runs none) }
function ReleaseCanRunCode(aType: TPSTypeRec): Boolean;
var
  lIdx: Longint;
begin
  case aType.BaseType of
    btArray, btVariant, btPointer{$IFNDEF PS_NOINTERFACES}, btInterface{$ENDIF}:
      Result := True;
    btStaticArray:
      Result := ReleaseCanRunCode(TPSTypeRec_Array(aType).ArrayType);
    btRecord:
      begin
        Result := True;
        for lIdx := 0 to TPSTypeRec_Record(aType).FieldTypes.Count -1 do
          if ReleaseCanRunCode(TPSTypeRec_Record(aType).FieldTypes[lIdx]) then
            exit;
        Result := False;
      end;
  else
    Result := False;
  end;
end;

{ copies into a destination that holds a value: its old contents are moved
  out first and released only after the copy, as Delphi's _IntfCopy orders
  an interface, so what the release runs (a native destructor running a
  script event) finds the destination assigned, and may change or free
  the container it lies in }
function ReplaceArrayContents(dest, src: Pointer; Len: Longint; aType: TPSTypeRec): Boolean;
var
  lSize: Cardinal;
  lOld: Pointer;
  lBuf: array[0..255] of Byte;
  lIdx: Longint;
begin
  lSize := Cardinal(Len) * aType.RealSize;
  if lSize <= SizeOf(lBuf) then
    lOld := @lBuf
  else
    GetMem(lOld, lSize);
  try
    Move(dest^, lOld^, lSize);
    FillChar(dest^, lSize, 0);
    Result := CopyArrayContents(dest, src, Len, aType);
  finally
    try
      for lIdx := 0 to Len - 1 do
        FinalizeVariant(Pointer(IPointer(lOld) + Cardinal(lIdx) * aType.RealSize), aType);
    finally
      if lOld <> @lBuf then
        FreeMem(lOld);
    end;
  end;
end;

function CopyRecordContents(dest, src: Pointer; aType: TPSTypeRec_Record): Boolean;
var
  o, i: Longint;
begin
  for i := 0 to aType.FieldTypes.Count -1 do
  begin
    o := Longint(atype.RealFieldOffsets[i]);
    if not CopyArrayContents(Pointer(IPointer(Dest)+Cardinal(o)), Pointer(IPointer(Src)+Cardinal(o)), 1, aType.FieldTypes[i]) then begin result := false; exit; end;
  end;
  Result := true;
end;

{ src by value: converting an element can run host code (a custom variant
  type's cast, copy or clear) that runs a script event, which can free or
  replace the script variable the caller's Variant lives in -- the copy is
  what the conversion reads }
function CreateArrayFromVariant(Exec: TPSExec; dest: Pointer; src: Variant; DestType: TPSTypeRec): Boolean;
var
  i: Integer;
  r: Pointer;
  lVarType: TPSTypeRec;
  v: variant;
  lElType: TPSTypeRec;
  lNewArr: Pointer;
begin
  lVarType := Exec.FindType2(btVariant);
  if lVarType = nil then begin Exec.CMD_Err(ErTypeMismatch); result := false; exit; end;
  { built apart and then assigned: releasing the destination's old
    elements (a native destructor running a script event) comes after the
    destination holds the new array, and a failed conversion leaves it as
    it was }
  lNewArr := nil;
  PSDynArraySetLength(lNewArr, desttype, VarArrayHighBound(src, 1) - VarArrayLowBound(src, 1) + 1);
  try
    r := lNewArr;
    lElType := TPSTypeRec_Array(DestType).ArrayType;
    for i := 0 to VarArrayHighBound(src, 1) - VarArrayLowBound(src, 1) do begin
      v := src[i + VarArrayLowBound(src, 1)];
      if not Exec.SetVariantValue(r, @v, lElType, lVarType) then begin result := false; exit; end;
      r := Pointer(IPointer(r) + lElType.RealSize);
    end;
    CopyArrayContents(dest, @lNewArr, 1, DestType);
  finally
    FinalizeVariant(@lNewArr, DestType);
  end;
  Result := true;
end;

function CopyArrayContents(dest, src: Pointer; Len: Longint; aType: TPSTypeRec): Boolean;
var
  elsize: Cardinal;
  i: Longint;
  lSrcArr: Pointer;
begin
  { a copy onto itself changes nothing, as in Delphi: releasing the destination first would release the
    source }
  if dest = src then
  begin
    Result := True;
    exit;
  end;
  { a destination whose release can run code (an interface, and what may
    hold one) is replaced: see ReplaceArrayContents.  A source overlapping
    the destination is copied in place. }
  if (Len > 0) and ReleaseCanRunCode(aType) and
    not IsZeroBlock(dest, Cardinal(Len) * aType.RealSize) and
    ((IPointer(src) >= IPointer(dest) + Cardinal(Len) * aType.RealSize) or
     (IPointer(dest) >= IPointer(src) + Cardinal(Len) * aType.RealSize)) then
  begin
    Result := ReplaceArrayContents(dest, src, Len, aType);
    exit;
  end;
  try
    case aType.BaseType of
      btU8, btS8, btChar:
        for i := 0 to Len -1 do
        begin
          tbtU8(Dest^) := tbtU8(Src^);
          Dest := Pointer(IPointer(Dest) + 1);
          Src := Pointer(IPointer(Src) + 1);
        end;
      btU16, btS16{$IFNDEF PS_NOWIDESTRING}, btWideChar{$ENDIF}:
        for i := 0 to Len -1 do
        begin
          tbtU16(Dest^) := tbtU16(Src^);
          Dest := Pointer(IPointer(Dest) + 2);
          Src := Pointer(IPointer(Src) + 2);
        end;
      btProcPtr:
        for i := 0 to Len -1 do
        begin
          tbtU32(Dest^) := tbtU32(Src^);
          Dest := Pointer(IPointer(Dest) + PointerSize);
          Src := Pointer(IPointer(Src) + PointerSize);
          Pointer(Dest^) := Pointer(Src^);
          Dest := Pointer(IPointer(Dest) + PointerSize);
          Src := Pointer(IPointer(Src) + PointerSize);
          Pointer(Dest^) := Pointer(Src^);
          Dest := Pointer(IPointer(Dest) + PointerSize);
          Src := Pointer(IPointer(Src) + PointerSize);
        end;
      btClass, btpchar:
        for i := 0 to Len -1 do
        begin
          Pointer(Dest^) := Pointer(Src^);
          Dest := Pointer(IPointer(Dest) + PointerSize);
          Src := Pointer(IPointer(Src) + PointerSize);
        end;
      btU32, btS32, btSingle:
        for i := 0 to Len -1 do
        begin
          tbtU32(Dest^) := tbtU32(Src^);
          Dest := Pointer(IPointer(Dest) + 4);
          Src := Pointer(IPointer(Src) + 4);
        end;
      btDouble:
        for i := 0 to Len -1 do
        begin
          tbtDouble(Dest^) := tbtDouble(Src^);
          Dest := Pointer(IPointer(Dest) + 8);
          Src := Pointer(IPointer(Src) + 8);
        end;
      {$IFNDEF PS_NOINT64}bts64:
        for i := 0 to Len -1 do
        begin
          tbts64(Dest^) := tbts64(Src^);
          Dest := Pointer(IPointer(Dest) + 8);
          Src := Pointer(IPointer(Src) + 8);
        end;
      btU64:
        for i := 0 to Len -1 do
        begin
          tbtu64(Dest^) := tbtu64(Src^);
          Dest := Pointer(IPointer(Dest) + 8);
          Src := Pointer(IPointer(Src) + 8);
        end;
      {$ENDIF}
      btExtended:
        for i := 0 to Len -1 do
        begin
          tbtExtended(Dest^) := tbtExtended(Src^);
          Dest := Pointer(IPointer(Dest) + SizeOf(Extended));
          Src := Pointer(IPointer(Src) + SizeOf(Extended));
        end;
      btCurrency:
        for i := 0 to Len -1 do
        begin
          tbtCurrency(Dest^) := tbtCurrency(Src^);
          Dest := Pointer(IPointer(Dest) + SizeOf(Currency));
          Src := Pointer(IPointer(Src) + SizeOf(Currency));
        end;
      btVariant:
        for i := 0 to Len -1 do
        begin
          variant(Dest^) := variant(Src^);
          Dest := Pointer(IPointer(Dest) + Sizeof(Variant));
          Src := Pointer(IPointer(Src) + Sizeof(Variant));
        end;
      btString:
        for i := 0 to Len -1 do
        begin
          tbtString(Dest^) := tbtString(Src^);
          Dest := Pointer(IPointer(Dest) + PointerSize);
          Src := Pointer(IPointer(Src) + PointerSize);
        end;
      {$IFNDEF PS_NOWIDESTRING}
      btUnicodeString:
        for i := 0 to Len -1 do
        begin
          tbtunicodestring(Dest^) := tbtunicodestring(Src^);
          Dest := Pointer(IPointer(Dest) + PointerSize);
          Src := Pointer(IPointer(Src) + PointerSize);
        end;
      btWideString:
        for i := 0 to Len -1 do
        begin
          tbtWideString(Dest^) := tbtWideString(Src^);
          Dest := Pointer(IPointer(Dest) + PointerSize);
          Src := Pointer(IPointer(Src) + PointerSize);
        end;
    {$ENDIF}
      btStaticArray:
        begin
          elSize := aType.RealSize;
          for i := 0 to Len -1 do
          begin
            if not CopyArrayContents(Dest, Src, TPSTypeRec_StaticArray(aType).Size, TPSTypeRec_StaticArray(aType).ArrayType) then
            begin
              result := false;
              exit;
            end;
            Dest := Pointer(IPointer(Dest) + elsize);
            Src := Pointer(IPointer(Src) + elsize);
          end;
        end;
      btArray:
        begin
          for i := 0 to Len -1 do
          begin
            { the source is taken, with its reference, before the destination is
              released, as Delphi's _DynArrayAsg takes it: what the release runs
              (a native destructor running a script event) can empty the source }
            lSrcArr := Pointer(Src^);
            if lSrcArr <> nil then
              Inc(PDynArrayRec(PAnsiChar(lSrcArr) - SizeOf(TDynArrayRecHeader))^.header.refCnt);
            if Pointer(Dest^) <> nil then
              PSDynArraySetLength(Pointer(Dest^), aType, 0);
            Pointer(Dest^) := lSrcArr;
            Dest := Pointer(IPointer(Dest) + PointerSize);
            Src := Pointer(IPointer(Src) + PointerSize);
          end;
        end;
      btRecord:
        begin
          elSize := aType.RealSize;
          for i := 0 to Len -1 do
          begin
            if not CopyRecordContents(Dest, Src, TPSTypeRec_Record(aType)) then
            begin
              result := false;
              exit;
            end;
            Dest := Pointer(IPointer(Dest) + elsize);
            Src := Pointer(IPointer(Src) + elsize);
          end;
        end;
      btSet:
        begin
          elSize := aType.RealSize;
          for i := 0 to Len -1 do
          begin
            Move(Src^, Dest^, elSize);
            Dest := Pointer(IPointer(Dest) + elsize);
            Src := Pointer(IPointer(Src) + elsize);
          end;
        end;
{$IFNDEF PS_NOINTERFACES}
      btInterface:
        begin
          for i := 0 to Len -1 do
          begin
            {$IFNDEF DELPHI3UP}
            if IUnknown(Dest^) <> nil then
            begin
              IUnknown(Dest^).Release;
              IUnknown(Dest^) := nil;
            end;
            {$ENDIF}
            SetInterfaceVar(Pointer(Dest^), Pointer(Src^));
            {$IFNDEF DELPHI3UP}
            if IUnknown(Dest^) <> nil then
              IUnknown(Dest^).AddRef;
            {$ENDIF}
            Dest := Pointer(IPointer(Dest) + PointerSize);
            Src := Pointer(IPointer(Src) + PointerSize);
          end;
        end;
{$ENDIF}
      btPointer:
        begin
          { the borrowed copy for one element: of several, a later one may own
            its value, which the loop below copies }
          if (Len = 1) and (Pointer(Pointer(IPointer(Dest)+PointerSize2)^) = nil) and (Pointer(Pointer(IPointer(Src)+PointerSize2)^) = nil) then
          begin
            for i := 0 to Len -1 do
            begin
              Pointer(Dest^) := Pointer(Src^);
              Dest := Pointer(IPointer(Dest) + PointerSize);
              Src := Pointer(IPointer(Src) + PointerSize);
              Pointer(Dest^) := Pointer(Src^);
              Dest := Pointer(IPointer(Dest) + PointerSize);
              Src := Pointer(IPointer(Src) + PointerSize);
              Pointer(Dest^) := nil;
              Dest := Pointer(IPointer(Dest) + PointerSize);
              Src := Pointer(IPointer(Src) + PointerSize);
            end;
          end else begin
            for i := 0 to Len -1 do
            begin
              if Pointer(Pointer(IPointer(Dest)+PointerSize2)^) <> nil then
                DestroyHeapVariant2(Pointer(Dest^), Pointer(Pointer(IPointer(Dest)+PointerSize)^));
              if Pointer(Src^) <> nil then
              begin
                if not LongBool(Pointer(IPointer(Src) + PointerSize2)^) then
                begin
                  Pointer(Dest^) := Pointer(Src^);
                  Pointer(Pointer(IPointer(Dest) + PointerSize)^) := Pointer(Pointer(IPointer(Src) + PointerSize)^);
                  Pointer(Pointer(IPointer(Dest) + PointerSize2)^) := Pointer(Pointer(IPointer(Src) + PointerSize2)^);
                end else
                begin
                  Pointer(Dest^) := CreateHeapVariant2(Pointer(Pointer(IPointer(Src) + PointerSize)^));
                  Pointer(Pointer(IPointer(Dest) + PointerSize)^) := Pointer(Pointer(IPointer(Src) + PointerSize)^);
                  LongBool(Pointer(IPointer(Dest) + PointerSize2)^) := true;
                  if not CopyArrayContents(Pointer(Dest^), Pointer(Src^), 1, Pointer(Pointer(IPointer(Dest) + PointerSize)^)) then
                  begin
                    Result := false;
                    exit;
                  end;
                end;
              end else
              begin
                Pointer(Dest^) := nil;
                Pointer(Pointer(IPointer(Dest) + PointerSize)^) := nil;
                Pointer(Pointer(IPointer(Dest) + PointerSize2)^) := nil;
              end;
              Dest := Pointer(IPointer(Dest) + PointerSize*3);
              Src := Pointer(IPointer(Src) + PointerSize*3);
            end;
          end;
        end;
//      btResourcePointer = 15;
//      btVariant = 16;
    else
      Result := False;
      exit;
    end;
    Result := true;
  except
    { left after the handler: Delphi XE3 to XE5 for Win64 keep the exception object of a handler left by a jump }
    Result := False;
  end;
end;

function  GetPSArrayLength(Arr: PIFVariant): Longint;
begin
  result := PSDynArrayGetLength(PPSVariantDynamicArray(arr).Data, arr.FType);
end;

procedure SetPSArrayLength(Arr: PIFVariant; NewLength: Longint);
begin
  PSDynArraySetLength(PPSVariantDynamicArray(arr).Data, arr.FType, NewLength);
end;


function PSDynArrayGetLength(arr: Pointer; aType: TPSTypeRec): Longint;
begin
  if aType.BaseType <> btArray then raise Exception.Create(RPS_InvalidArray);
  if arr = nil then Result := 0 else result:=PDynArrayRec(PAnsiChar(arr) - SizeOf(TDynArrayRecHeader))^.header.{$IFDEF FPC}high + 1{$ELSE}length{$ENDIF FPC};
end;

procedure PSDynArraySetLength(var arr: Pointer; aType: TPSTypeRec; NewLength: Longint);
var
  elSize, i, OldLen: Longint;
  darr : PDynArrayRec;
  lRemoved: Pointer;
begin
  if aType.BaseType <> btArray then raise Exception.Create(RPS_InvalidArray);
  OldLen := PSDynArrayGetLength(arr, aType);
  elSize := TPSTypeRec_Array(aType).ArrayType.RealSize;
  if NewLength<0 then
     NewLength:=0;
  { the size below is a Longint: a length whose size it cannot hold allocated a few bytes and initialised
    the whole length past them }
  if (NewLength > 0) and (TPSTypeRec_Array(aType).ArrayType.RealSize > 0) and
    (NewLength > (High(Longint) - SizeOf(TDynArrayRecHeader)) div Longint(TPSTypeRec_Array(aType).ArrayType.RealSize)) then
    raise Exception.Create(RPS_OutOfRange);
  if (OldLen = 0) and (NewLength = 0) then exit; // already are both 0
  { at its length already: nothing to do unless another variable shares the array -- Delphi's SetLength
    makes it unique }
  if (OldLen = NewLength) and (PDynArrayRec(PAnsiChar(Arr) - SizeOf(TDynArrayRecHeader))^.header.refCnt = 1) then
    exit;
  darr := PDynArrayRec(PAnsiChar(Arr) - SizeOf(TDynArrayRecHeader));
  if (OldLen <> 0) and (darr^.header.refCnt = 1) then // unique copy of this dynamic array
  begin
    if NewLength <= 0 then
    begin
      { emptied before its elements are finalized, as Delphi's _DynArrayClear
        empties the variable first: what a finalization runs (a native
        destructor running a script event) does not reach the block freed here }
      arr := nil;
      if TPSTypeRec_Array(aType).ArrayType.BaseType in NeedFinalization then
        for i := 0 to OldLen -1 do
          FinalizeVariant(Pointer(IPointer(@darr^.datas) + Cardinal(elsize * i)), TPSTypeRec_Array(aType).ArrayType);
      FreeMem(darr);
      exit;
    end;
    { the elements a shrink removes are moved out and the array shortened
      before they are finalized, as an assignment stores its new value
      before it releases the old one: what a finalization runs (a native
      destructor running a script event) finds the array at its new length,
      and what it does to the array stands.  When the smaller block cannot
      be had, the array keeps its length, the removed elements emptied. }
    lRemoved := nil;
    if (NewLength < OldLen) and (TPSTypeRec_Array(aType).ArrayType.BaseType in NeedFinalization) then
    begin
      GetMem(lRemoved, (OldLen - NewLength) * elSize);
      Move(Pointer(IPointer(arr) + Cardinal(elsize * NewLength))^, lRemoved^, (OldLen - NewLength) * elSize);
      FillChar(Pointer(IPointer(arr) + Cardinal(elsize * NewLength))^, (OldLen - NewLength) * elSize, 0);
    end;
    try
      ReallocMem(darr, Longint(NewLength * elSize) + SizeOf(TDynArrayRecHeader));
      {$IFDEF FPC}
      darr^.header.high := NewLength  -1;
      {$ELSE}
      darr^.header.length := NewLength;
      {$ENDIF}
      arr := @darr^.datas;
      for i := OldLen to NewLength -1 do
      begin
        InitializeVariant(Pointer(IPointer(arr) + Cardinal(elsize * i)), TPSTypeRec_Array(aType).ArrayType);
      end;
    finally
      if lRemoved <> nil then
      try
        for i := 0 to OldLen - NewLength - 1 do
          FinalizeVariant(Pointer(IPointer(lRemoved) + Cardinal(elsize * i)), TPSTypeRec_Array(aType).ArrayType);
      finally
        FreeMem(lRemoved);
      end;
    end;
  end else
  begin
    if NewLength = 0 then
    begin
      FinalizeVariant(@arr, aType);
      arr := nil;
      exit;
    end;
    GetMem(darr, Longint(NewLength * elSize) + SizeOf(TDynArrayRecHeader));
    darr^.header.refCnt:=1;
    {$IFDEF FPC}
    darr^.header.high := NewLength - 1;
    {$ELSE}
    {$IFDEF CPUX64}
    darr^.header._Padding:=0;
    {$ENDIF CPUX64}
    darr^.header.length := NewLength;
    {$ENDIF FPC}
    for i := 0 to NewLength -1 do
    begin
      InitializeVariant(Pointer(IPointer(@darr^.datas) + Cardinal(elsize * i)), TPSTypeRec_Array(aType).ArrayType);
    end;
    if OldLen <> 0 then
    begin
      if OldLen > NewLength then
        CopyArrayContents(@darr^.datas, arr, NewLength, TPSTypeRec_Array(aType).ArrayType)
      else
        CopyArrayContents(@darr^.datas, arr, OldLen, TPSTypeRec_Array(aType).ArrayType);
      FinalizeVariant(@arr, aType);
    end;
    arr := @darr^.datas;
  end;
end;


{$IFDEF FPC}
{$DEFINE FPC_OR_KYLIX}
{$ENDIF}
{$IFDEF KYLIX}
{$DEFINE FPC_OR_KYLIX}
{$ENDIF}

{$IFDEF FPC_OR_KYLIX}
function OleErrorMessage(ErrorCode: HResult): tbtString;
begin
  Result := SysErrorMessage(ErrorCode);
  if Result = '' then
    Result := Format(RPS_OLEError, [ErrorCode]);
end;

procedure OleError(ErrorCode: HResult);
begin
  raise Exception.Create(OleErrorMessage(ErrorCode));
end;

procedure OleCheck(Result: HResult);
begin
  if Result < 0 then OleError(Result);
end;
{$ENDIF}


{$IFNDEF DELPHI3UP}
function OleErrorMessage(ErrorCode: HResult): tbtString;
begin
  Result := SysErrorMessage(ErrorCode);
  if Result = '' then
    Result := Format(RPS_OLEError, [ErrorCode]);
end;

procedure OleError(ErrorCode: HResult);
begin
  raise Exception.Create(OleErrorMessage(ErrorCode));
end;

procedure OleCheck(Result: HResult);
begin
  if Result < 0 then OleError(Result);
end;

procedure AssignInterface(var Dest: IUnknown; const Src: IUnknown);
var
  OldDest: IUnknown;
begin
  { Like Delphi 3+'s _IntfCopy, reference source before releasing old dest.
    so that self assignment (I := I) works right }
  OldDest := Dest;
  Dest := Src;
  if Src <> nil then
    Src.AddRef;
  if OldDest <> nil then
    OldDest.Release;
end;

procedure AssignVariantFromIDispatch(var Dest: Variant; const Src: IDispatch);
begin
  VarClear(Dest);
  TVarData(Dest).VDispatch := Src;
  TVarData(Dest).VType := varDispatch;
  if Src <> nil then
    Src.AddRef;
end;

procedure AssignIDispatchFromVariant(var Dest: IDispatch; const Src: Variant);
const
  RPS_InvalidVariantRef = 'Invalid variant ref';
var
  NewDest: IDispatch;
begin
  case TVarData(Src).VType of
    varEmpty: NewDest := nil;
    varDispatch: NewDest := TVarData(Src).VDispatch;
    varDispatch or varByRef: NewDest := Pointer(TVarData(Src).VPointer^);
  else
    raise Exception.Create(RPS_InvalidVariantRef);
  end;
  AssignInterface(IUnknown(Dest), NewDest);
end;
{$ENDIF}

{ moves aNew into the Variant at dest, leaving aNew empty, and only then
  releases the value dest held: Delphi's own Variant assignment releases
  first, and what a release runs (a native destructor running a script
  event) can move or free the container dest lies in }
procedure MoveIntoVariant(dest: Pointer; var aNew: Variant);
var
  lOld: Variant;
begin
  { the old value moves out and the new one in; lOld is released when
    this routine ends }
  Move(dest^, lOld, SizeOf(TVarData));
  Move(aNew, dest^, SizeOf(TVarData));
  FillChar(aNew, SizeOf(TVarData), 0);
end;

{ stores a copy of aNew into the Variant at dest by MoveIntoVariant }
procedure StoreVariant(dest: Pointer; const aNew: Variant);
var
  lNew: Variant;
begin
  lNew := aNew;
  MoveIntoVariant(dest, lNew);
end;

{ SetVariantValue's Variant destination: the new value is made apart and
  then moved in by MoveIntoVariant }
function SetVariantFromValue(Exec: TPSExec; dest, src: Pointer; srctype: TPSTypeRec): Boolean;
var
  lNew: Variant;
  tt: TPSVariantPointer;
begin
  Result := True;
{$IFNDEF PS_NOINTERFACES}
  if srctype.ExportName = 'IDISPATCH' then
  begin
    {$IFDEF DELPHI3UP}
    lNew := IDispatch(src^);
    {$ELSE}
    AssignVariantFromIDispatch(lNew, IDispatch(src^));
    {$ENDIF}
  end else
{$ENDIF}
  if srctype.BaseType = btVariant then
  begin
    { a Variant assigned to itself changes nothing, as in Delphi }
    if src = dest then
      exit;
    lNew := Variant(src^);
  end else
  begin
    tt.VI.FType := Exec.FindType2(btPointer);
    if tt.VI.FType = nil then
    begin
      Result := False;
      exit;
    end;
    tt.DestType := srctype;
    tt.DataDest := src;
    tt.FreeIt := False;
    Result := PIFVariantToVariant(@tt, lNew);
    if not Result then
      exit;
  end;
  MoveIntoVariant(dest, lNew);
end;

function TPSExec.SetVariantValue(dest, Src: Pointer; desttype, srctype: TPSTypeRec): Boolean;
var
  Tmp: TObject;
  lNewArr: Pointer;
begin
  Result := True;
  try
    case desttype.BaseType of
      btSet:
        begin
          if desttype = srctype then
            Move(Src^, Dest^, TPSTypeRec_Set(desttype).aByteSize)
          else
            Result := False;
        end;
      btU8: tbtu8(Dest^) := PSGetUInt(Src, srctype);
      btS8: tbts8(Dest^) := PSGetInt(Src, srctype);
      btU16: tbtu16(Dest^) := PSGetUInt(Src, srctype);
      btS16: tbts16(Dest^) := PSGetInt(Src, srctype);
      btProcPtr:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btu32:
              begin
                tbtu32(Dest^) := tbtu32(Src^);
                Pointer(Pointer(IPointer(Dest)+PointerSize)^) := nil;
                Pointer(Pointer(IPointer(Dest)+PointerSize2)^) := nil;
              end;
            btProcPtr:
              begin
                tbtu32(Dest^) := tbtu32(Src^);
                Pointer(Pointer(IPointer(Dest)+PointerSize)^) := Pointer(Pointer(IPointer(Src)+PointerSize)^);
                Pointer(Pointer(IPointer(Dest)+PointerSize2)^) := Pointer(Pointer(IPointer(Src)+PointerSize2)^);
              end;
            else raise Exception.Create(RPS_TypeMismatch);
          end;
        end;
      btU32:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btU8: tbtu32(Dest^) := tbtu8(src^);
            btS8: tbtu32(Dest^) := tbts8(src^);
            btU16: tbtu32(Dest^) := tbtu16(src^);
            btS16: tbtu32(Dest^) := tbts16(src^);
            btU32: tbtu32(Dest^) := tbtu32(src^);
            btS32: tbtu32(Dest^) := tbts32(src^);
          {$IFNDEF PS_NOINT64}
            btS64: tbtu32(Dest^) := tbts64(src^);
            btU64: tbtu32(Dest^) := tbtu64(src^);
          {$ENDIF}
            btChar: tbtu32(Dest^) := Ord(tbtchar(Src^));
        {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtu32(Dest^) := Ord(tbtwidechar(Src^));{$ENDIF}
            btVariant: tbtu32(Dest^) := Variant(src^);
            {$IFNDEF CPU64}
            // see below
            btClass: tbtu32(Dest^) := tbtu32(src^);
            {$ENDIF}
            else raise Exception.Create(RPS_TypeMismatch);
          end;
        end;
      btS32:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btU8: tbts32(Dest^) := tbtu8(src^);
            btS8: tbts32(Dest^) := tbts8(src^);
            btU16: tbts32(Dest^) := tbtu16(src^);
            btS16: tbts32(Dest^) := tbts16(src^);
            btU32: tbts32(Dest^) := tbtu32(src^);
            btS32: tbts32(Dest^) := tbts32(src^);
          {$IFNDEF PS_NOINT64}
            btS64: tbts32(Dest^) := tbts64(src^);
            btU64: tbts32(Dest^) := tbtu64(src^);
          {$ENDIF}
            btChar: tbts32(Dest^) := Ord(tbtchar(Src^));
        {$IFNDEF PS_NOWIDESTRING}  btWideChar: tbts32(Dest^) := Ord(tbtwidechar(Src^));{$ENDIF}
            btVariant: tbts32(Dest^) := Variant(src^);
            {$IFNDEF CPU64}
            // nx change start - allow assignment of class
            btClass: tbts32(Dest^) := tbts32(src^);
            // nx change end
            {$ENDIF}
            else raise Exception.Create(RPS_TypeMismatch);
          end;
        end;
      {$IFNDEF PS_NOINT64}
      btS64:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btU8: tbts64(Dest^) := tbtu8(src^);
            btS8: tbts64(Dest^) := tbts8(src^);
            btU16: tbts64(Dest^) := tbtu16(src^);
            btS16: tbts64(Dest^) := tbts16(src^);
            btU32: tbts64(Dest^) := tbtu32(src^);
            btS32: tbts64(Dest^) := tbts32(src^);
            btS64: tbts64(Dest^) := tbts64(src^);
            btU64: tbts64(Dest^) := tbtu64(src^);
            btChar: tbts64(Dest^) := Ord(tbtchar(Src^));
        {$IFNDEF PS_NOWIDESTRING}  btWideChar: tbts64(Dest^) := Ord(tbtwidechar(Src^));{$ENDIF}
            btVariant: tbts64(Dest^) := Variant(src^);
            {$IFDEF CPU64}
            // see above
            btClass: tbts64(Dest^) := tbtu64(src^);
            {$ENDIF}
            else raise Exception.Create(RPS_TypeMismatch);
          end;
        end;
      btU64:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btU8: tbtu64(Dest^) := tbtu8(src^);
            btS8: tbtu64(Dest^) := tbts8(src^);
            btU16: tbtu64(Dest^) := tbtu16(src^);
            btS16: tbtu64(Dest^) := tbts16(src^);
            btU32: tbtu64(Dest^) := tbtu32(src^);
            btS32: tbtu64(Dest^) := tbts32(src^);
            btS64: tbtu64(Dest^) := tbts64(src^);
            btU64: tbtu64(Dest^) := tbtu64(src^);
            btChar: tbtu64(Dest^) := Ord(tbtchar(Src^));
        {$IFNDEF PS_NOWIDESTRING}  btWideChar: tbtu64(Dest^) := Ord(tbtwidechar(Src^));{$ENDIF}
            btVariant: tbtu64(Dest^) := Variant(src^);
            {$IFDEF CPU64}
            // see above
            btClass: tbtu64(Dest^) := tbtu64(src^);
            {$ENDIF}
            else raise Exception.Create(RPS_TypeMismatch);
          end;
        end;
      {$ENDIF}
      btSingle:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btU8: tbtsingle(Dest^) := tbtu8(src^);
            btS8: tbtsingle(Dest^) := tbts8(src^);
            btU16: tbtsingle(Dest^) := tbtu16(src^);
            btS16: tbtsingle(Dest^) := tbts16(src^);
            btU32: tbtsingle(Dest^) := tbtu32(src^);
            btS32: tbtsingle(Dest^) := tbts32(src^);
          {$IFNDEF PS_NOINT64}
            btS64: tbtsingle(Dest^) := tbts64(src^);
            btU64: tbtsingle(Dest^) := tbtu64(src^);
          {$ENDIF}
            btSingle: tbtsingle(Dest^) := tbtsingle(Src^);
            btDouble: tbtsingle(Dest^) := tbtdouble(Src^);
            btExtended: tbtsingle(Dest^) := tbtextended(Src^);
            btCurrency: tbtsingle(Dest^) := tbtcurrency(Src^);
            btVariant:  tbtsingle(Dest^) := Variant(src^);
            else raise Exception.Create(RPS_TypeMismatch);
          end;
        end;
      btDouble:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btU8: tbtdouble(Dest^) := tbtu8(src^);
            btS8: tbtdouble(Dest^) := tbts8(src^);
            btU16: tbtdouble(Dest^) := tbtu16(src^);
            btS16: tbtdouble(Dest^) := tbts16(src^);
            btU32: tbtdouble(Dest^) := tbtu32(src^);
            btS32: tbtdouble(Dest^) := tbts32(src^);
          {$IFNDEF PS_NOINT64}
            btS64: tbtdouble(Dest^) := tbts64(src^);
            btU64: tbtdouble(Dest^) := tbtu64(src^);
          {$ENDIF}
            btSingle: tbtdouble(Dest^) := tbtsingle(Src^);
            btDouble: tbtdouble(Dest^) := tbtdouble(Src^);
            btExtended: tbtdouble(Dest^) := tbtextended(Src^);
            btCurrency: tbtdouble(Dest^) := tbtcurrency(Src^);
            btVariant:  tbtdouble(Dest^) := Variant(src^);
            else raise Exception.Create(RPS_TypeMismatch);
          end;

        end;
      btExtended:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          case srctype.BaseType of
            btU8: tbtextended(Dest^) := tbtu8(src^);
            btS8: tbtextended(Dest^) := tbts8(src^);
            btU16: tbtextended(Dest^) := tbtu16(src^);
            btS16: tbtextended(Dest^) := tbts16(src^);
            btU32: tbtextended(Dest^) := tbtu32(src^);
            btS32: tbtextended(Dest^) := tbts32(src^);
          {$IFNDEF PS_NOINT64}
            btS64: tbtextended(Dest^) := tbts64(src^);
            btU64: tbtextended(Dest^) := tbtu64(src^);
          {$ENDIF}
            btSingle: tbtextended(Dest^) := tbtsingle(Src^);
            btDouble: tbtextended(Dest^) := tbtdouble(Src^);
            btExtended: tbtextended(Dest^) := tbtextended(Src^);
            btCurrency: tbtextended(Dest^) := tbtcurrency(Src^);
            btVariant:  tbtextended(Dest^) := Variant(src^);
            else raise Exception.Create(RPS_TypeMismatch);
          end;
        end;
      btCurrency: tbtcurrency(Dest^) := PSGetCurrency(Src, srctype);
      btPChar:
        begin
          if srctype.BaseType = btPointer then
          begin
            srctype := PIFTypeRec(Pointer(IPointer(Src)+PointerSize)^);
            Src := Pointer(Src^);
            if (src = nil) or (srctype = nil) then raise Exception.Create(RPS_TypeMismatch);
          end;
          { a PChar takes the other's pointer, as in Delphi: a string made of its text would be freed here }
          if srctype.BaseType = btPChar then
            pansichar(dest^) := pansichar(src^)
          else
            pansichar(dest^) := pansichar(PSGetAnsiString(Src, srctype));
        end;
      btString:
        tbtstring(dest^) := PSGetAnsiString(Src, srctype);
      btChar: tbtchar(dest^) := PSGetAnsiChar(Src, srctype);
      {$IFNDEF PS_NOWIDESTRING}
      btWideString: tbtwidestring(dest^) := PSGetWideString(Src, srctype);
      btUnicodeString: tbtUnicodeString(dest^) := PSGetUnicodeString(Src, srctype);
      btWideChar: tbtwidechar(dest^) := widechar(PSGetUInt(Src, srctype));
      {$ENDIF}
      btStaticArray:
        begin
          { here, for a static array assigned to a dynamic one, and for a record:
            CopyArrayContents takes a failed copy's exception and answers False, and
            the assignment is refused, as Delphi raises, rather than going on with
            the destination partly copied }
          if desttype <> srctype then
            Result := False
          else if not CopyArrayContents(dest, Src, TPSTypeRec_StaticArray(desttype).Size, TPSTypeRec_StaticArray(desttype).ArrayType) then
            Result := False;
        end;
      btArray:
        begin
          if (srctype.BaseType = btStaticArray) and (TPSTypeRec_Array(desttype).ArrayType = TPSTypeRec_Array(srctype).ArrayType) then
          begin
            { built apart and then assigned: releasing the destination's old
              elements (a native destructor running a script event) comes
              after the destination holds the new array }
            lNewArr := nil;
            PSDynArraySetLength(lNewArr, desttype, TPSTypeRec_StaticArray(srctype).Size);
            try
              if CopyArrayContents(lNewArr, Src, TPSTypeRec_StaticArray(srctype).Size, TPSTypeRec_StaticArray(srctype).ArrayType) then
                CopyArrayContents(Dest, @lNewArr, 1, desttype)
              else
                Result := False;
            finally
              FinalizeVariant(@lNewArr, desttype);
            end;
          end else if (srctype.BaseType = btvariant) and VarIsArray(Variant(src^)) then
          begin
            { CreateArrayFromVariant has reported its failure: a second report would find the handler of the
              try that took the first used up, and go on to an outer handler or stop the script }
            if not CreateArrayFromVariant(Self, dest, Variant(src^), desttype) then
            begin
              Result := False;
              exit;
            end;
          end else if (desttype <> srctype) and not ((desttype.BaseType = btarray) and (srctype.BaseType = btArray)
            and (((TPSTypeRec_Array(desttype).ArrayType.BaseType = TPSTypeRec_Array(srctype).ArrayType.BaseType){$IFDEF WIDESTRING_EQUAL_UNICODESTRING}{$IFNDEF PS_NOWIDESTRING} or
                  ((TPSTypeRec_Array(desttype).ArrayType.BaseType in [btWideString, btUnicodeString]) and
                   (TPSTypeRec_Array(srctype).ArrayType.BaseType in [btWideString, btUnicodeString])){$ENDIF}{$ENDIF}) and
                 (not (TPSTypeRec_Array(desttype).ArrayType.BaseType in [btRecord, btSet, btStaticArray, btArray]) or
                  (TPSTypeRec_Array(desttype).ArrayType = TPSTypeRec_Array(srctype).ArrayType)))) then
            { ^ Comparing BaseType is needed because the compiler doesn't merge open array types
              and regular array types in ReadType (see the '!' check). Still it considers them
              compatible in IsCompatibleType, so we should check ArrayType.BaseType instead of
              only ArrayType. CopyArrayContents also doesn't require exact ArrayType match. }
            Result := False
          else
            CopyArrayContents(dest, src, 1, desttype);
        end;
      btRecord:
        begin
          if desttype <> srctype then
            Result := False
          else if not CopyArrayContents(dest, Src, 1, desttype) then
            Result := False;
        end;
      btVariant:
        Result := SetVariantFromValue(Self, Dest, Src, srctype);
      btClass:
        begin
          if srctype.BaseType = btClass then
            TObject(Dest^) := TObject(Src^)
          else
          if srctype.BaseType = btVariant then
            {$IFDEF CPU64} TbtU64(Dest^) := Variant(Src^) {$ELSE} TbtU32(Dest^) := Variant(Src^) {$ENDIF}
          else
          // nx change start
          if (srctype.BaseType in {$IFDEF CPU64} [btU64, btS64] {$ELSE} [btU32, btS32] {$ENDIF}) then
            {$IFDEF CPU64} TbtU64(Dest^) := TbtU64(Src^) {$ELSE} TbtU32(Dest^) := TbtU32(Src^) {$ENDIF}
          else
          // nx change end
            Result := False;
        end;
{$IFNDEF PS_NOINTERFACES}
      btInterface:
        begin
          if Srctype.BaseType = btVariant then
          begin
            if desttype.ExportName = 'IDISPATCH' then
            begin
              {$IFDEF Delphi3UP}
              IDispatch(Dest^) := IDispatch(Variant(Src^));
              {$ELSE}
              AssignIDispatchFromVariant(IDispatch(Dest^), Variant(Src^));
              {$ENDIF}
            end else
              Result := False;
{$IFDEF Delphi3UP}
          end else
          if srctype.BaseType = btClass then
          begin
            { a nil object is a nil interface, as in Delphi }
            if TObject(Src^) = nil then
              SetInterfaceVar(Pointer(Dest^), nil)
            else if not TObject(Src^).GetInterface(TPSTypeRec_Interface(desttype).Guid, IUnknown(Dest^)) then
            begin
              Result := false;
              Cmd_Err(erInterfaceNotSupported);
              exit;
            end;
{$ENDIF}
          end else if srctype.BaseType = btInterface then
          begin
            {$IFNDEF Delphi3UP}
            if IUnknown(Dest^) <> nil then
            begin
              IUnknown(Dest^).Release;
              IUnknown(Dest^) := nil;
            end;
            {$ENDIF}
            SetInterfaceVar(Pointer(Dest^), Pointer(Src^));
            {$IFNDEF Delphi3UP}
            if IUnknown(Dest^) <> nil then
              IUnknown(Dest^).AddRef;
            {$ENDIF}
          end else
            Result := False;
        end;
{$ENDIF}
    else begin
        Result := False;
      end;
    end;
    if Result = False then
      CMD_Err(ErTypeMismatch);
  except
    {$IFDEF DELPHI6UP}
    Tmp := AcquireExceptionObject;
    {$ELSE}
    if RaiseList <> nil then
    begin
      Tmp := Exception(PRaiseFrame(RaiseList)^.ExceptObject);
      PRaiseFrame(RaiseList)^.ExceptObject := nil;
    end else
      Tmp := nil;
    {$ENDIF}
    if Tmp <> nil then
    begin
      if Tmp is EPSException then
      begin
        Result := False;
        ExceptionProc(EPSException(tmp).ProcNo, EPSException(tmp).ProcPos, erCustomError, tbtString(EPSException(tmp).Message), nil);
        Tmp.Free;
        exit;
      end else
      if Tmp is EDivByZero then
      begin
        Result := False;
        CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
      if Tmp is EZeroDivide then
      begin
        Result := False;
        CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
      if Tmp is EMathError then
      begin
        Result := False;
        CMD_Err3(erMathError, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
    end;
    if (tmp <> nil) and (Tmp is Exception) then
      CMD_Err3(erException, tbtString(Exception(Tmp).Message), Tmp)
    else
      CMD_Err3(erException, '', Tmp);
    Result := False;
  end;
end;

function SpecImport(Sender: TPSExec; p: TPSExternalProcRec; Tag: Pointer): Boolean; forward;


function Class_IS(Self: TPSExec; Obj: TObject; var2type: TPSTypeRec): Boolean;
var
  R: TPSRuntimeClassImporter;
  cc: TPSRuntimeClass;
begin
  if Obj = nil then
  begin
    Result := false;
    exit;
  end;
  r := Self.FindSpecialProcImport(SpecImport);
  if R = nil then
  begin
    Result := false;
    exit;
  end;
  cc := r.FindClass(var2type.ExportName);
  if cc = nil then
  begin
    result := false;
    exit;
  end;
  try
    Result := Obj is cc.FClass;
  except
    Result := false;
  end;
end;

type
  TVariantArray = array of Variant;
  PVariantArray = ^TVariantArray;
function VariantInArray(var1: Pointer; var1Type: TPSTypeRec; var2: PVariantArray): Boolean;
var
  lDest: Variant;
  i: Integer;
begin
  IntPIFVariantToVariant(var1, var1Type, lDest);
  result := false;
  for i := 0 to Length(var2^) -1 do begin
    if var2^[i] = lDest then begin
      result := true;
      break;
    end;
  end;
end;


function TPSExec.DoBooleanCalc(var1, Var2, into: Pointer; var1Type, var2type, intotype: TPSTypeRec; Cmd: Cardinal): Boolean;
var
  b: Boolean;
  Tmp: TObject;
  tvar: Variant;
  lRight: Pointer;
  lRightType: TPSTypeRec;

  { an integer compared with an integer compares by value, with a Currency exactly and with a real as a real,
    and a Currency with a Single, Double or Extended as a real, as in Delphi: the cases below read the right
    operand in the left one's width and sign, or a real as a Currency }
  function NumericCompare(out aResult: Boolean): Boolean;
  const
    cInts = [btU8, btS8, btU16, btS16, btU32, btS32{$IFNDEF PS_NOINT64}, btS64, btU64{$ENDIF}];
    { the largest integer a Currency holds }
    cCurrencyIntMax = 922337203685477;
  var
    lP2: Pointer;
    lT2: TPSTypeRec;
    lI1, lI2: Int64;
    lHuge1, lHuge2: Boolean;
    lR1, lR2: Extended;
    lC: Integer;

    { the value, and whether it is a UInt64 past High(Int64) }
    function OrdOf(aP: Pointer; aT: TPSTypeRec; out aHuge: Boolean): Int64;
    begin
      aHuge := False;
      case aT.BaseType of
        btU8: Result := tbtu8(aP^);
        btS8: Result := tbts8(aP^);
        btU16: Result := tbtu16(aP^);
        btS16: Result := tbts16(aP^);
        btU32: Result := tbtu32(aP^);
        btS32: Result := tbts32(aP^);
      {$IFNDEF PS_NOINT64}
        btS64: Result := PInt64(aP)^;
        btU64:
          begin
            Result := PInt64(aP)^;
            aHuge := Result < 0;
          end;
      {$ENDIF}
      else
        Result := 0;
      end;
    end;

    { the order of an integer against a Currency's raw value, -1, 0 or 1: an integer past the range of
      Currency is greater or less than every Currency }
    function IntegerCurrencyOrder(aP: Pointer; aT: TPSTypeRec; aCurrency: Int64): Integer;
    var
      lValue: Int64;
      lHuge: Boolean;
    begin
      lValue := OrdOf(aP, aT, lHuge);
      if lHuge or (lValue > cCurrencyIntMax) then
        Result := 1
      else if lValue < -cCurrencyIntMax then
        Result := -1
      else
      begin
        lValue := lValue * 10000;
        if lValue < aCurrency then
          Result := -1
        else if lValue > aCurrency then
          Result := 1
        else
          Result := 0;
      end;
    end;

  begin
    Result := False;
    if (Cmd > 5) or not ((var1Type.BaseType in cInts) or (var1Type.BaseType = btCurrency)) then
      exit;
    lP2 := lRight;
    lT2 := lRightType;
    if (var1Type.BaseType in cInts) and (lT2.BaseType in cInts) then
    begin
      lI1 := OrdOf(var1, var1Type, lHuge1);
      lI2 := OrdOf(lP2, lT2, lHuge2);
      if lHuge1 <> lHuge2 then
      begin
        if lHuge1 then
          lC := 1
        else
          lC := -1;
      end else if lI1 < lI2 then
        lC := -1
      else if lI1 > lI2 then
        lC := 1
      else
        lC := 0;
      case Cmd of
        0: aResult := lC >= 0;
        1: aResult := lC <= 0;
        2: aResult := lC > 0;
        3: aResult := lC < 0;
        4: aResult := lC <> 0;
      else
        aResult := lC = 0;
      end;
    end else if ((var1Type.BaseType in cInts) and (lT2.BaseType = btCurrency)) or
      ((var1Type.BaseType = btCurrency) and (lT2.BaseType in cInts)) then
    begin
      { an integer compared with a Currency compares exactly, whichever is on the left: a real here would be a
        Double on Win64, which cannot hold every Currency, and converting the integer to a Currency wraps or
        raises past the range of Currency }
      if var1Type.BaseType = btCurrency then
        lC := -IntegerCurrencyOrder(lP2, lT2, PInt64(var1)^)
      else
        lC := IntegerCurrencyOrder(var1, var1Type, PInt64(lP2)^);
      case Cmd of
        0: aResult := lC >= 0;
        1: aResult := lC <= 0;
        2: aResult := lC > 0;
        3: aResult := lC < 0;
        4: aResult := lC <> 0;
      else
        aResult := lC = 0;
      end;
    end else if ((var1Type.BaseType in cInts) and (lT2.BaseType in [btSingle, btDouble, btExtended])) or
      ((var1Type.BaseType = btCurrency) and (lT2.BaseType in [btSingle, btDouble, btExtended])) then
    begin
      lR1 := PSGetReal(var1, var1Type);
      lR2 := PSGetReal(lP2, lT2);
      case Cmd of
        0: aResult := lR1 >= lR2;
        1: aResult := lR1 <= lR2;
        2: aResult := lR1 > lR2;
        3: aResult := lR1 < lR2;
        4: aResult := lR1 <> lR2;
      else
        aResult := lR1 = lR2;
      end;
    end else
      exit;
    Result := True;
  end;
{$IFNDEF PS_NOWIDESTRING}

  { an AnsiString, a PChar or a Char compared with a wide string or character compares as a UnicodeString,
    as in Delphi: the cases below read the wide operand through the ANSI code page }
  function WideCompare(out aResult: Boolean): Boolean;
  var
    lU1, lU2: tbtunicodestring;
  begin
    Result := False;
    if (Cmd > 5) or not (var1Type.BaseType in [btString, btPChar, btChar]) or
      not (lRightType.BaseType in [btWideChar, btWideString, btUnicodeString]) then
      exit;
    lU1 := PSGetUnicodeString(var1, var1Type);
    lU2 := PSGetUnicodeString(var2, var2type);
    case Cmd of
        0: aResult := lU1 >= lU2;
        1: aResult := lU1 <= lU2;
        2: aResult := lU1 > lU2;
        3: aResult := lU1 < lU2;
        4: aResult := lU1 <> lU2;
      else
        aResult := lU1 = lU2;
    end;
    Result := True;
  end;
{$ENDIF}


  procedure SetBoolean(b: Boolean; var Ok: Boolean);
  begin
    Ok := True;
    case IntoType.BaseType of
      btU8: tbtu8(Into^):= Cardinal(b);
      btS8: tbts8(Into^) := Longint(b);
      btU16: tbtu16(Into^) := Cardinal(b);
      btS16: tbts16(Into^) := Longint(b);
      btU32: tbtu32(Into^) := Cardinal(b);
      btS32: tbts32(Into^) := Longint(b);
      {$IFNDEF PS_NOINT64}
        btS64: tbts64(Into^) := Longint(b);
        btU64: tbtu64(Into^) := Cardinal(b);
      {$ENDIF}
      btVariant: StoreVariant(Into, b);
    else begin
        CMD_Err(ErTypeMismatch);
        Ok := False;
      end;
    end;
  end;
begin
  Result := true;
  try
    { a host's pointer to a pointer (TPSScript.SetPointerToData) reaches here as
      the pointer: the rules below read the value where it points, as the typed
      arms do; a cell of no value or no type is left to the arms }
    lRight := var2;
    lRightType := var2type;
    if (var2type.BaseType = btPointer) and (Pointer(var2^) <> nil) and
      (PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^) <> nil) then
    begin
      lRight := Pointer(var2^);
      lRightType := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
    end;
    if NumericCompare(b){$IFNDEF PS_NOWIDESTRING} or WideCompare(b){$ENDIF} then
    begin
      SetBoolean(b, Result);
      exit;
    end;
    { a value compared with a Variant compares as two Variants, as in Delphi: the
      cases below read the Variant in the other operand's type, which rounds a
      fraction away, reads a Boolean as a number and refuses a Null }
    if (Cmd <= 5) and (lRightType.BaseType = btVariant) and
      (var1Type.BaseType in [btU8, btS8, btU16, btS16, btU32, btS32{$IFNDEF PS_NOINT64}, btS64, btU64{$ENDIF},
        btSingle, btDouble, btExtended, btCurrency, btChar, btString{$IFNDEF PS_NOWIDESTRING}, btWideChar,
        btWideString, btUnicodeString{$ENDIF}]) and
      IntPIFVariantToVariant(var1, var1Type, tvar) then
    begin
      case Cmd of
        0: b := tvar >= Variant(lRight^);
        1: b := tvar <= Variant(lRight^);
        2: b := tvar > Variant(lRight^);
        3: b := tvar < Variant(lRight^);
        4: b := tvar <> Variant(lRight^);
      else
        b := tvar = Variant(lRight^);
      end;
      SetBoolean(b, Result);
      exit;
    end;
    case Cmd of
      0: begin { >= }
          case var1Type.BaseType of
            btU8:
            if (var2Type.BaseType = btString) or (Var2Type.BaseType = btPChar) then
              b := tbtchar(tbtu8(var1^)) >= PSGetAnsiString(Var2, var2type)
            else
              b := tbtu8(var1^) >= PSGetUInt(Var2, var2type);
            btS8: b := tbts8(var1^) >= PSGetInt(Var2, var2type);
            btU16: b := tbtu16(var1^) >= PSGetUInt(Var2, var2type);
            btS16: b := tbts16(var1^) >= PSGetInt(Var2, var2type);
            btU32: b := tbtu32(var1^) >= PSGetUInt(Var2, var2type);
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: b := tbts32(var1^) >= tbtu8(Var2^);
                  btS8: b := tbts32(var1^) >= tbts8(Var2^);
                  btU16: b := tbts32(var1^) >= tbtu16(Var2^);
                  btS16: b := tbts32(var1^) >= tbts16(Var2^);
                  btU32: b := tbts32(var1^) >= Longint(tbtu32(Var2^));
                  btS32: b := tbts32(var1^) >= tbts32(Var2^);
                  btDouble: b := PSGetReal(Var1, var1type) >= tbtdouble(var2^);
                  btSingle: B := psGetReal(Var1, var1Type) >= tbtsingle(var2^);
                  btExtended: B := psGetReal(Var1, var1Type) >= tbtExtended(var2^);
                  btCurrency: b := PSGetReal(Var1, var1type) >= tbtcurrency(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: b := tbts32(var1^) >= tbts64(Var2^);
                    btU64: b := tbts32(var1^) >= tbtu64(Var2^);
                  {$ENDIF}
                  btChar: b := tbts32(var1^) >= Ord(tbtchar(Var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: b := tbts32(var1^) >= Ord(tbtwidechar(Var2^));{$ENDIF}
                  btVariant: b := tbts32(var1^) >= Variant(Var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btSingle: b := tbtsingle(var1^) >= PSGetReal(Var2, var2type);
            btDouble: b := tbtdouble(var1^) >= PSGetReal(Var2, var2type);
            btCurrency: b := tbtcurrency(var1^) >= PSGetCurrency(Var2, var2type);
            btExtended: b := tbtextended(var1^) >= PSGetReal(Var2, var2type);
            {$IFNDEF PS_NOINT64}
            btS64: b := tbts64(var1^) >= PSGetInt64(Var2, var2type);
            btU64: b := tbtu64(var1^) >= PSGetUInt64(Var2, var2type);
            {$ENDIF}
            btPChar,btString: b := tbtstring(var1^) >= PSGetAnsiString(Var2, var2type);
            btChar: b := tbtchar(var1^) >= PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: b := tbtwidechar(var1^) >= PSGetWideString(Var2, var2type);
            btWideString: b := tbtwidestring(var1^) >= PSGetWideString(Var2, var2type);
            btUnicodeString: b := tbtUnicodestring(var1^) >= PSGetUnicodeString(Var2, var2type);
            {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  b := Variant(var1^) >= tvar;
              end;
            btSet:
              begin
                if var1Type = var2Type then
                begin
                  Set_Subset(var2, var1, TPSTypeRec_Set(var1Type).aByteSize, b);
                end else result := False;
              end;
          else begin
              CMD_Err(ErTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(ErTypeMismatch);
            exit;
          end;
          SetBoolean(b, Result);
        end;
      1: begin { <= }
          case var1Type.BaseType of
            btU8:
            if (var2Type.BaseType = btString) or (Var2Type.BaseType = btPChar) then
              b := tbtchar(tbtu8(var1^)) <= PSGetAnsiString(Var2, var2type)
            else
              b := tbtu8(var1^) <= PSGetUInt(Var2, var2type);
            btS8: b := tbts8(var1^) <= PSGetInt(Var2, var2type);
            btU16: b := tbtu16(var1^) <= PSGetUInt(Var2, var2type);
            btS16: b := tbts16(var1^) <= PSGetInt(Var2, var2type);
            btU32: b := tbtu32(var1^) <= PSGetUInt(Var2, var2type);
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: b := tbts32(var1^) <= tbtu8(Var2^);
                  btS8: b := tbts32(var1^) <= tbts8(Var2^);
                  btU16: b := tbts32(var1^) <= tbtu16(Var2^);
                  btS16: b := tbts32(var1^) <= tbts16(Var2^);
                  btU32: b := tbts32(var1^) <= Longint(tbtu32(Var2^));
                  btS32: b := tbts32(var1^) <= tbts32(Var2^);
                  btDouble: b := PSGetReal(Var1, var1type) <= tbtdouble(var2^);
                  btSingle: B := psGetReal(Var1, var1Type) <= tbtsingle(var2^);
                  btExtended: B := psGetReal(Var1, var1Type) <= tbtExtended(var2^);
                  btCurrency: b := PSGetReal(Var1, var1type) <= tbtcurrency(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: b := tbts32(var1^) <= tbts64(Var2^);
                    btU64: b := tbts32(var1^) <= tbtu64(Var2^);
                  {$ENDIF}
                  btChar: b := tbts32(var1^) <= Ord(tbtchar(Var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: b := tbts32(var1^) <= Ord(tbtwidechar(Var2^));{$ENDIF}
                  btVariant: b := tbts32(var1^) <= Variant(Var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;            btSingle: b := tbtsingle(var1^) <= PSGetReal(Var2, var2type);
            btCurrency: b := tbtcurrency(var1^) <= PSGetCurrency(Var2, var2type);
            btDouble: b := tbtdouble(var1^) <= PSGetReal(Var2, var2type);
            btExtended: b := tbtextended(var1^) <= PSGetReal(Var2, var2type);
            {$IFNDEF PS_NOINT64}
            btS64: b := tbts64(var1^) <= PSGetInt64(Var2, var2type);
            btU64: b := tbtu64(var1^) <= PSGetUInt64(Var2, var2type);
            {$ENDIF}
            btPChar,btString: b := tbtstring(var1^) <= PSGetAnsiString(Var2, var2type);
            btChar: b := tbtchar(var1^) <= PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: b := tbtwidechar(var1^) <= PSGetWideString(Var2, var2type);
            btWideString: b := tbtwidestring(var1^) <= PSGetWideString(Var2, var2type);
            btUnicodeString: b := tbtUnicodestring(var1^) <= PSGetUnicodeString(Var2, var2type);
            {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  b := Variant(var1^) <= tvar;
              end;
            btSet:
              begin
                if var1Type = var2Type then
                begin
                  Set_Subset(var1, var2, TPSTypeRec_Set(var1Type).aByteSize, b);
                end else result := False;
              end;
          else begin
              CMD_Err(ErTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
          SetBoolean(b, Result);
        end;
      2: begin { > }
          case var1Type.BaseType of
            btU8:
            if (var2Type.BaseType = btString) or (Var2Type.BaseType = btPChar) then
              b := tbtchar(tbtu8(var1^)) > PSGetAnsiString(Var2, var2type)
            else
              b := tbtu8(var1^) > PSGetUInt(Var2, var2type);
            btS8: b := tbts8(var1^) > PSGetInt(Var2, var2type);
            btU16: b := tbtu16(var1^) > PSGetUInt(Var2, var2type);
            btS16: b := tbts16(var1^) > PSGetInt(Var2, var2type);
            btU32: b := tbtu32(var1^) > PSGetUInt(Var2, var2type);
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: b := tbts32(var1^) > tbtu8(Var2^);
                  btS8: b := tbts32(var1^) > tbts8(Var2^);
                  btU16: b := tbts32(var1^) > tbtu16(Var2^);
                  btS16: b := tbts32(var1^) > tbts16(Var2^);
                  btU32: b := tbts32(var1^) > Longint(tbtu32(Var2^));
                  btS32: b := tbts32(var1^) > tbts32(Var2^);
                  btDouble: b := PSGetReal(Var1, var1type) > tbtdouble(var2^);
                  btSingle: B := psGetReal(Var1, var1Type) > tbtsingle(var2^);
                  btExtended: B := psGetReal(Var1, var1Type) > tbtExtended(var2^);
                  btCurrency: b := PSGetReal(Var1, var1type) > tbtcurrency(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: b := tbts32(var1^) > tbts64(Var2^);
                    btU64: b := tbts32(var1^) > tbtu64(Var2^);
                  {$ENDIF}
                  btChar: b := tbts32(var1^) > Ord(tbtchar(Var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: b := tbts32(var1^) > Ord(tbtwidechar(Var2^));{$ENDIF}
                  btVariant: b := tbts32(var1^) > Variant(Var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;            btSingle: b := tbtsingle(var1^) > PSGetReal(Var2, var2type);
            btDouble: b := tbtdouble(var1^) > PSGetReal(Var2, var2type);
            btExtended: b := tbtextended(var1^) > PSGetReal(Var2, var2type);
            btCurrency: b := tbtcurrency(var1^) > PSGetCurrency(Var2, var2type);
            {$IFNDEF PS_NOINT64}
            btS64: b := tbts64(var1^) > PSGetInt64(Var2, var2type);
            btU64: b := tbtu64(var1^) > PSGetUInt64(Var2, var2type);
            {$ENDIF}
            btPChar,btString: b := tbtstring(var1^) > PSGetAnsiString(Var2, var2type);
            btChar: b := tbtchar(var1^) > PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: b := tbtwidechar(var1^) > PSGetWideString(Var2, var2type);
            btWideString: b := tbtwidestring(var1^) > PSGetWideString(Var2, var2type);
            btUnicodeString: b := tbtUnicodestring(var1^) > PSGetUnicodeString(Var2, var2type);
            {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  b := Variant(var1^) > tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
          SetBoolean(b, Result);
        end;
      3: begin { < }
          case var1Type.BaseType of
            btU8:
            if (var2Type.BaseType = btString) or (Var2Type.BaseType = btPChar) then
              b := tbtchar(tbtu8(var1^)) < PSGetAnsiString(Var2, var2type)
            else
              b := tbtu8(var1^) < PSGetUInt(Var2, var2type);
            btS8: b := tbts8(var1^) < PSGetInt(Var2, var2type);
            btU16: b := tbtu16(var1^) < PSGetUInt(Var2, var2type);
            btS16: b := tbts16(var1^) < PSGetInt(Var2, var2type);
            btU32: b := tbtu32(var1^) < PSGetUInt(Var2, var2type);
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: b := tbts32(var1^) < tbtu8(Var2^);
                  btS8: b := tbts32(var1^) < tbts8(Var2^);
                  btU16: b := tbts32(var1^) < tbtu16(Var2^);
                  btS16: b := tbts32(var1^) < tbts16(Var2^);
                  btU32: b := tbts32(var1^) < Longint(tbtu32(Var2^));
                  btS32: b := tbts32(var1^) < tbts32(Var2^);
                  btDouble: b := PSGetReal(Var1, var1type) < tbtdouble(var2^);
                  btSingle: B := psGetReal(Var1, var1Type) < tbtsingle(var2^);
                  btExtended: B := psGetReal(Var1, var1Type) < tbtExtended(var2^);
                  btCurrency: b := PSGetReal(Var1, var1type) < tbtcurrency(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: b := tbts32(var1^) < tbts64(Var2^);
                    btU64: b := tbts32(var1^) < tbtu64(Var2^);
                  {$ENDIF}
                  btChar: b := tbts32(var1^) < Ord(tbtchar(Var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: b := tbts32(var1^) < Ord(tbtwidechar(Var2^));{$ENDIF}
                  btVariant: b := tbts32(var1^) < Variant(Var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;            btSingle: b := tbtsingle(var1^) < PSGetReal(Var2, var2type);
            btDouble: b := tbtdouble(var1^) < PSGetReal(Var2, var2type);
            btCurrency: b := tbtcurrency(var1^) < PSGetCurrency(Var2, var2type);
            btExtended: b := tbtextended(var1^) < PSGetReal(Var2, var2type);
            {$IFNDEF PS_NOINT64}
            btS64: b := tbts64(var1^) < PSGetInt64(Var2, var2type);
            btU64: b := tbtu64(var1^) < PSGetUInt64(Var2, var2type);
            {$ENDIF}
            btPChar,btString: b := tbtstring(var1^) < PSGetAnsiString(Var2, var2type);
            btChar: b := tbtchar(var1^) < PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: b := tbtwidechar(var1^) < PSGetWideString(Var2, var2type);
            btWideString: b := tbtwidestring(var1^) < PSGetWideString(Var2, var2type);
            btUnicodeString: b := tbtUnicodestring(var1^) < PSGetUnicodeString(Var2, var2type);
            {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  b := Variant(var1^) < tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
          SetBoolean(b, Result);
        end;
      4: begin { <> }
          case var1Type.BaseType of
            btInterface:
              begin
                if var2Type.BaseType = btInterface then
                  b := Pointer(var1^) <> Pointer(var2^) // no need to cast it to IUnknown
                else
                  Result := false;
              end;
            btClass:
              begin
                if var2Type.BaseType = btclass then
                  b := TObject(var1^) <> TObject(var2^)
                else
                  Result := false;
              end;
            btU8:
            if (var2Type.BaseType = btString) or (Var2Type.BaseType = btPChar) then
              b := tbtchar(tbtu8(var1^)) <> PSGetAnsiString(Var2, var2type)
            else
              b := tbtu8(var1^) <> PSGetUInt(Var2, var2type);
            btS8: b := tbts8(var1^) <> PSGetInt(Var2, var2type);
            btU16: b := tbtu16(var1^) <> PSGetUInt(Var2, var2type);
            btS16: b := tbts16(var1^) <> PSGetInt(Var2, var2type);
            btProcPtr:
              begin
                if tbtu32(Var1^) = tbtu32(Var2^) then
                begin
                  if tbtu32(Var1^) = 0 then { ProcNo is 0: external method ref, compare Self and Code }
                    b := ((Pointer(Pointer(IPointer(Var1)+PointerSize)^) <> Pointer(Pointer(IPointer(Var2)+PointerSize)^)) or
                   (Pointer(Pointer(IPointer(Var1)+PointerSize2)^) <> Pointer(Pointer(IPointer(Var2)+PointerSize2)^)))
                  else
                    b := False;
                end else b := True;
              end;
            btU32: b := tbtu32(var1^) <> PSGetUInt(Var2, var2type);
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: b := tbts32(var1^) <> tbtu8(Var2^);
                  btS8: b := tbts32(var1^) <> tbts8(Var2^);
                  btU16: b := tbts32(var1^) <> tbtu16(Var2^);
                  btS16: b := tbts32(var1^) <> tbts16(Var2^);
                  btProcPtr, btU32: b := tbts32(var1^)<> Longint(tbtu32(Var2^));
                  btS32: b := tbts32(var1^) <> tbts32(Var2^);
                  btDouble: b := PSGetReal(Var1, var1type) <> tbtdouble(var2^);
                  btSingle: B := psGetReal(Var1, var1Type) <> tbtsingle(var2^);
                  btExtended: B := psGetReal(Var1, var1Type) <> tbtExtended(var2^);
                  btCurrency: b := PSGetReal(Var1, var1type) <> tbtcurrency(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: b := tbts32(var1^) <> tbts64(Var2^);
                    btU64: b := tbts32(var1^) <> tbtu64(Var2^);
                  {$ENDIF}
                  btChar: b := tbts32(var1^) <> Ord(tbtchar(Var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: b := tbts32(var1^) <> Ord(tbtwidechar(Var2^));{$ENDIF}
                  btVariant: b := tbts32(var1^) <> Variant(Var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;            btSingle: b := tbtsingle(var1^) <> PSGetReal(Var2, var2type);
            btDouble: b := tbtdouble(var1^) <> PSGetReal(Var2, var2type);
            btExtended: b := tbtextended(var1^) <> PSGetReal(Var2, var2type);
            btCurrency: b := tbtcurrency(var1^) <> PSGetCurrency(Var2, var2type);
            btPChar,btString: b := tbtstring(var1^) <> PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOINT64}
            btS64: b := tbts64(var1^) <> PSGetInt64(Var2, var2type);
            btU64: b := tbtu64(var1^) <> PSGetUInt64(Var2, var2type);
            {$ENDIF}
            btChar: b := tbtchar(var1^) <> PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: b := tbtwidechar(var1^) <> PSGetWideString(Var2, var2type);
            btWideString: b := tbtwidestring(var1^) <> PSGetWideString(Var2, var2type);
            btUnicodeString: b := tbtUnicodeString(var1^) <> PSGetUnicodeString(Var2, var2type);
            {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  b := Variant(var1^) <> tvar;
              end;
            btSet:
              begin
                if var1Type = var2Type then
                begin
                  Set_Equal(var1, var2, TPSTypeRec_Set(var1Type).aByteSize, b);
                  b := not b;
                end else result := False;
              end;
            btRecord:
              begin
                if var1Type = var2Type then
                begin
                  Set_Equal(var1, var2, TPSTypeRec_Record(var1Type).RealSize, b);
                  b := not b;
                end else result := False;
              end

          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
          SetBoolean(b, Result);
        end;
      5: begin { = }
          case var1Type.BaseType of
            btInterface:
              begin
                if var2Type.BaseType = btInterface then
                  b := Pointer(var1^) = Pointer(var2^) // no need to cast it to IUnknown
                else
                  Result := false;
              end;
            btClass:
              begin
                if var2Type.BaseType = btclass then
                  b := TObject(var1^) = TObject(var2^)
                else
                  Result := false;
              end;
            btU8:
            if (var2Type.BaseType = btString) or (Var2Type.BaseType = btPChar) then
              b := tbtchar(tbtu8(var1^)) = PSGetAnsiString(Var2, var2type)
            else
              b := tbtu8(var1^) = PSGetUInt(Var2, var2type);
            btS8: b := tbts8(var1^) = PSGetInt(Var2, var2type);
            btU16: b := tbtu16(var1^) = PSGetUInt(Var2, var2type);
            btS16: b := tbts16(var1^) = PSGetInt(Var2, var2type);
            btU32: b := tbtu32(var1^) = PSGetUInt(Var2, var2type);
            btProcPtr:
              begin
                if tbtu32(Var1^) = tbtu32(Var2^) then
                begin
                  if tbtu32(Var1^) = 0 then { ProcNo is 0: external method ref, compare Self and Code }
                    b := ((Pointer(Pointer(IPointer(Var1)+PointerSize)^) = Pointer(Pointer(IPointer(Var2)+PointerSize)^)) and
                   (Pointer(Pointer(IPointer(Var1)+PointerSize2)^) = Pointer(Pointer(IPointer(Var2)+PointerSize2)^)))
                  else
                    b := True;
                end else b := False;
              end;
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: b := tbts32(var1^) = tbtu8(Var2^);
                  btS8: b := tbts32(var1^) = tbts8(Var2^);
                  btU16: b := tbts32(var1^) = tbtu16(Var2^);
                  btS16: b := tbts32(var1^) = tbts16(Var2^);
                  btProcPtr, btU32: b := tbts32(var1^) = Longint(tbtu32(Var2^));
                  btS32: b := tbts32(var1^) = tbts32(Var2^);
                  btDouble: b := PSGetReal(Var1, var1type) = tbtdouble(var2^);
                  btSingle: B := psGetReal(Var1, var1Type) = tbtsingle(var2^);
                  btExtended: B := psGetReal(Var1, var1Type) = tbtExtended(var2^);
                  btCurrency: b := PSGetReal(Var1, var1type) = tbtcurrency(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: b := tbts32(var1^) = tbts64(Var2^);
                    btU64: b := tbts32(var1^) = tbtu64(Var2^);
                  {$ENDIF}
                  btChar: b := tbts32(var1^) = Ord(tbtchar(Var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: b := tbts32(var1^) = Ord(tbtwidechar(Var2^));{$ENDIF}
                  btVariant: b := tbts32(var1^) = Variant(Var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;            btSingle: b := tbtsingle(var1^) = PSGetReal(Var2, var2type);
            btDouble: b := tbtdouble(var1^) = PSGetReal(Var2, var2type);
            btExtended: b := tbtextended(var1^) = PSGetReal(Var2, var2type);
            btCurrency: b := tbtcurrency(var1^) = PSGetCurrency(Var2, var2type);
            btPchar, btString: b := tbtstring(var1^) = PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOINT64}
            btS64: b := tbts64(var1^) = PSGetInt64(Var2, var2type);
            btU64: b := tbtu64(var1^) = PSGetUInt64(Var2, var2type);
            {$ENDIF}
            btChar: b := tbtchar(var1^) = PSGetAnsiString(Var2, var2type);
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: b := tbtwidechar(var1^) = PSGetWideString(Var2, var2type);
            btWideString: b := tbtwidestring(var1^) = PSGetWideString(Var2, var2type);
            btUnicodeString: b := tbtUnicodestring(var1^) = PSGetUnicodeString(Var2, var2type);
            {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  b := Variant(var1^) = tvar;
              end;
            btSet:
              begin
                if var1Type = var2Type then
                begin
                  Set_Equal(var1, var2, TPSTypeRec_Set(var1Type).aByteSize, b);
                end else result := False;
              end;
            btRecord:
              begin
                if var1Type = var2Type then
                begin
                  Set_Equal(var1, var2, TPSTypeRec_Record(var1Type).RealSize, b);
                end else result := False;
              end
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
          SetBoolean(b, Result);
        end;
      6: begin { in }
          if (var2Type.BaseType = btArray) and (TPSTypeRec_Array(var2type).ArrayType.BaseType = btVariant) then
          begin
            b := VariantInArray(var1, var1Type, var2);
            SetBoolean(b, Result);
          end else
          if var2Type.BaseType = btSet then
          begin
            Cmd := PSGetUInt(var1, var1type);
            if Cmd >= Cardinal(TPSTypeRec_Set(var2Type).aBitSize) then
            begin
              cmd_Err(erOutofRecordRange);
              Result := False;
              Exit;
            end;
            Set_membership(Cmd, var2, b);
            SetBoolean(b, Result);
          end else
          begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      7:
        begin // is
          case var1Type.BaseType of
            btClass:
              begin
                if var2type.BaseType <> btU32 then
                  Result := False
                else
                begin
                  var2type := FTypes[tbtu32(var2^)];
                  if (var2type = nil) or (var2type.BaseType <> btClass) then
                    Result := false
                  else
                  begin
                    Setboolean(Class_IS(Self, TObject(var1^), var2type), Result);
                  end;
                end;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
    else begin
        Result := False;
        CMD_Err(erInvalidOpcodeParameter);
        exit;
      end;
    end;
  except
    {$IFDEF DELPHI6UP}
    Tmp := AcquireExceptionObject;
    {$ELSE}
    if RaiseList <> nil then
    begin
      Tmp := Exception(PRaiseFrame(RaiseList)^.ExceptObject);
      PRaiseFrame(RaiseList)^.ExceptObject := nil;
    end else
      Tmp := nil;
    {$ENDIF}
    if Tmp <> nil then
    begin
      if Tmp is EPSException then
      begin
        Result := False;
        ExceptionProc(EPSException(tmp).ProcNo, EPSException(tmp).ProcPos, erCustomError, tbtString(EPSException(tmp).Message), nil);
        Tmp.Free;
        exit;
      end else
      if Tmp is EDivByZero then
      begin
        Result := False;
        CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
      if Tmp is EZeroDivide then
      begin
        Result := False;
        CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
      if Tmp is EMathError then
      begin
        Result := False;
        CMD_Err3(erMathError, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
    end;
    if (tmp <> nil) and (Tmp is Exception) then
      CMD_Err3(erException, tbtString(Exception(Tmp).Message), Tmp)
    else
      CMD_Err3(erException, '', Tmp);
    Result := False;
  end;
end;

function VarIsFloat(const V: Variant): Boolean;
begin
  Result := VarType(V) in [varSingle, varDouble, varCurrency];
end;

{$IFDEF FPC_CURRENCY_IS_INT64}
{ Free Pascal makes Currency op real (+ - *) a Currency operation, and where
  Currency is an Int64 (x86_64) that rounds the real operand alone first:
  1 + 0.00005 would give 1.  Taken into a real first, the operation is the
  real one, as Delphi computes it. }
function _CurrAsReal(const c: Currency): Extended;
begin
  Result := c;
end;
{$ENDIF}

function TPSExec.DoCalc(var1, Var2: Pointer; var1Type, var2type: TPSTypeRec; CalcType: Cardinal): Boolean;
    { var1=dest, var2=src }
var
  Tmp: TObject;
  tvar: Variant;
begin
  try
    Result := True;
    case CalcType of
      {$IFDEF DELPHI10UP}{$REGION '+'}{$ENDIF}
      0: begin { + }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) + PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) + PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) + PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) + PSGetInt(Var2, var2type);
            btU32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtU32(var1^) := tbtU32(var1^) + tbtu8(var2^);
                  btS8: tbtU32(var1^) := tbtU32(var1^) + cardinal(longint(tbts8(var2^)));
                  btU16: tbtU32(var1^) := tbtU32(var1^) + tbtu16(var2^);
                  btS16: tbtU32(var1^) := tbtU32(var1^) + cardinal(longint(tbts16(var2^)));
                  btU32: tbtU32(var1^) := tbtU32(var1^) + tbtu32(var2^);
                  btS32: tbtU32(var1^) := tbtU32(var1^) + cardinal(tbts32(var2^));
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtU32(var1^) := tbtU32(var1^) + tbts64(var2^);
                    btU64: tbtU32(var1^) := tbtU32(var1^) + tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbtU32(var1^) := tbtU32(var1^) +  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtU32(var1^) := tbtU32(var1^) + Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbtU32(var1^) := tbtU32(var1^) + Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbts32(var1^) := tbts32(var1^) + tbtu8(var2^);
                  btS8: tbts32(var1^) := tbts32(var1^) + tbts8(var2^);
                  btU16: tbts32(var1^) := tbts32(var1^) + tbtu16(var2^);
                  btS16: tbts32(var1^) := tbts32(var1^) + tbts16(var2^);
                  btU32: tbts32(var1^) := tbts32(var1^) + Longint(tbtu32(var2^));
                  btS32: tbts32(var1^) := tbts32(var1^) + tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbts32(var1^) := tbts32(var1^) + tbts64(var2^);
                    btU64: tbts32(var1^) := tbts32(var1^) + tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbts32(var1^) := tbts32(var1^) +  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbts32(var1^) := tbts32(var1^) + Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbts32(var1^) := tbts32(var1^) + Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
           {$IFNDEF PS_NOINT64}
            btS64:  tbts64(var1^) := tbts64(var1^) + PSGetInt64(var2, var2type);
            btU64:  tbtu64(var1^) := tbtu64(var1^) + PSGetUInt64(var2, var2type);
           {$ENDIF}
            btSingle:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtsingle(var1^) := tbtsingle(var1^) + tbtu8(var2^);
                  btS8: tbtsingle(var1^) := tbtsingle(var1^) + tbts8(var2^);
                  btU16: tbtsingle(var1^) := tbtsingle(var1^) + tbtu16(var2^);
                  btS16: tbtsingle(var1^) := tbtsingle(var1^) + tbts16(var2^);
                  btU32: tbtsingle(var1^) := tbtsingle(var1^) + tbtu32(var2^);
                  btS32: tbtsingle(var1^) := tbtsingle(var1^) + tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtsingle(var1^) := tbtsingle(var1^) + tbts64(var2^);
                    btU64: tbtsingle(var1^) := tbtsingle(var1^) + tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtsingle(var1^) := tbtsingle(var1^) + tbtsingle(var2^);
                  btDouble: tbtsingle(var1^) := tbtsingle(var1^) + tbtdouble(var2^);
                  btExtended: tbtsingle(var1^) := tbtsingle(var1^) + tbtextended(var2^);
                  btCurrency: tbtsingle(var1^) := tbtsingle(var1^) + {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtsingle(var1^) := tbtsingle(var1^) +  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btDouble:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtdouble(var1^) := tbtdouble(var1^) + tbtu8(var2^);
                  btS8: tbtdouble(var1^) := tbtdouble(var1^) + tbts8(var2^);
                  btU16: tbtdouble(var1^) := tbtdouble(var1^) + tbtu16(var2^);
                  btS16: tbtdouble(var1^) := tbtdouble(var1^) + tbts16(var2^);
                  btU32: tbtdouble(var1^) := tbtdouble(var1^) + tbtu32(var2^);
                  btS32: tbtdouble(var1^) := tbtdouble(var1^) + tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtdouble(var1^) := tbtdouble(var1^) + tbts64(var2^);
                    btU64: tbtdouble(var1^) := tbtdouble(var1^) + tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtdouble(var1^) := tbtdouble(var1^) + tbtsingle(var2^);
                  btDouble: tbtdouble(var1^) := tbtdouble(var1^) + tbtdouble(var2^);
                  btExtended: tbtdouble(var1^) := tbtdouble(var1^) + tbtextended(var2^);
                  btCurrency: tbtdouble(var1^) := tbtdouble(var1^) + {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtdouble(var1^) := tbtdouble(var1^) +  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btCurrency:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtcurrency(var1^) := tbtcurrency(var1^) + tbtu8(var2^);
                  btS8: tbtcurrency(var1^) := tbtcurrency(var1^) + tbts8(var2^);
                  btU16: tbtcurrency(var1^) := tbtcurrency(var1^) + tbtu16(var2^);
                  btS16: tbtcurrency(var1^) := tbtcurrency(var1^) + tbts16(var2^);
                  btU32: tbtcurrency(var1^) := tbtcurrency(var1^) + tbtu32(var2^);
                  btS32: tbtcurrency(var1^) := tbtcurrency(var1^) + tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtcurrency(var1^) := tbtcurrency(var1^) + tbts64(var2^);
                    btU64: tbtcurrency(var1^) := tbtcurrency(var1^) + tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} + tbtsingle(var2^);
                  btDouble: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} + tbtdouble(var2^);
                  btExtended: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} + tbtextended(var2^);
                  btCurrency: tbtcurrency(var1^) := tbtcurrency(var1^) + tbtcurrency(var2^);
                  btVariant:  tbtcurrency(var1^) := tbtcurrency(var1^) +  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btExtended:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtextended(var1^) := tbtextended(var1^) + tbtu8(var2^);
                  btS8: tbtextended(var1^) := tbtextended(var1^) + tbts8(var2^);
                  btU16: tbtextended(var1^) := tbtextended(var1^) + tbtu16(var2^);
                  btS16: tbtextended(var1^) := tbtextended(var1^) + tbts16(var2^);
                  btU32: tbtextended(var1^) := tbtextended(var1^) + tbtu32(var2^);
                  btS32: tbtextended(var1^) := tbtextended(var1^) + tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtextended(var1^) := tbtextended(var1^) + tbts64(var2^);
                    btU64: tbtextended(var1^) := tbtextended(var1^) + tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtextended(var1^) := tbtextended(var1^) + tbtsingle(var2^);
                  btDouble: tbtextended(var1^) := tbtextended(var1^) + tbtdouble(var2^);
                  btExtended: tbtextended(var1^) := tbtextended(var1^) + tbtextended(var2^);
                  btCurrency: tbtextended(var1^) := tbtextended(var1^) + {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtextended(var1^) := tbtextended(var1^) +  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btPchar, btString: tbtstring(var1^) := tbtstring(var1^) + PSGetAnsiString(Var2, var2type);
            btChar: tbtchar(var1^) := tbtchar(ord(tbtchar(var1^)) +  PSGetUInt(Var2, var2type));
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: tbtwidechar(var1^) := widechar(ord(tbtwidechar(var1^)) + PSGetUInt(Var2, var2type));
            btWideString: tbtwidestring(var1^) := tbtwidestring(var1^) + PSGetWideString(Var2, var2type);
            btUnicodeString: tbtUnicodestring(var1^) := tbtUnicodestring(var1^) + PSGetUnicodeString(Var2, var2type);
            {$ENDIF}
            btVariant:
              begin
                tvar := null;
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) + tvar;
              end;
            btSet:
              begin
                if var1Type = var2Type then
                begin
                  Set_Union(var1, var2, TPSTypeRec_Set(var1Type).aByteSize);
                end else result := False;
              end;

          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      {$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}
      {$IFDEF DELPHI10UP}{$REGION '-'}{$ENDIF}
      1: begin { - }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) - PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) - PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) - PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) - PSGetInt(Var2, var2type);
            btU32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtU32(var1^) := tbtU32(var1^) - tbtu8(var2^);
                  btS8: tbtU32(var1^) := tbtU32(var1^) - cardinal(longint(tbts8(var2^)));
                  btU16: tbtU32(var1^) := tbtU32(var1^) - tbtu16(var2^);
                  btS16: tbtU32(var1^) := tbtU32(var1^) - cardinal(longint(tbts16(var2^)));
                  btU32: tbtU32(var1^) := tbtU32(var1^) - tbtu32(var2^);
                  btS32: tbtU32(var1^) := tbtU32(var1^) - cardinal(tbts32(var2^));
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtU32(var1^) := tbtU32(var1^) - tbts64(var2^);
                    btU64: tbtU32(var1^) := tbtU32(var1^) - tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbtU32(var1^) := tbtU32(var1^) -  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtU32(var1^) := tbtU32(var1^) - Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbtU32(var1^) := tbtU32(var1^) - Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbts32(var1^) := tbts32(var1^) - tbtu8(var2^);
                  btS8: tbts32(var1^) := tbts32(var1^) - tbts8(var2^);
                  btU16: tbts32(var1^) := tbts32(var1^) - tbtu16(var2^);
                  btS16: tbts32(var1^) := tbts32(var1^) - tbts16(var2^);
                  btU32: tbts32(var1^) := tbts32(var1^) - Longint(tbtu32(var2^));
                  btS32: tbts32(var1^) := tbts32(var1^) - tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbts32(var1^) := tbts32(var1^) - tbts64(var2^);
                    btU64: tbts32(var1^) := tbts32(var1^) - tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbts32(var1^) := tbts32(var1^) -  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbts32(var1^) := tbts32(var1^) - Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbts32(var1^) := tbts32(var1^) - Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) - PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) - PSGetUInt64(var2, var2type);
           {$ENDIF}
            btSingle:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtsingle(var1^) := tbtsingle(var1^) - tbtu8(var2^);
                  btS8: tbtsingle(var1^) := tbtsingle(var1^) - tbts8(var2^);
                  btU16: tbtsingle(var1^) := tbtsingle(var1^) - tbtu16(var2^);
                  btS16: tbtsingle(var1^) := tbtsingle(var1^) - tbts16(var2^);
                  btU32: tbtsingle(var1^) := tbtsingle(var1^) - tbtu32(var2^);
                  btS32: tbtsingle(var1^) := tbtsingle(var1^) - tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtsingle(var1^) := tbtsingle(var1^) - tbts64(var2^);
                    btU64: tbtsingle(var1^) := tbtsingle(var1^) - tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtsingle(var1^) := tbtsingle(var1^) - tbtsingle(var2^);
                  btDouble: tbtsingle(var1^) := tbtsingle(var1^) - tbtdouble(var2^);
                  btExtended: tbtsingle(var1^) := tbtsingle(var1^) - tbtextended(var2^);
                  btCurrency: tbtsingle(var1^) := tbtsingle(var1^) - {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtsingle(var1^) := tbtsingle(var1^) - Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btCurrency:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtcurrency(var1^) := tbtcurrency(var1^) - tbtu8(var2^);
                  btS8: tbtcurrency(var1^) := tbtcurrency(var1^) - tbts8(var2^);
                  btU16: tbtcurrency(var1^) := tbtcurrency(var1^) - tbtu16(var2^);
                  btS16: tbtcurrency(var1^) := tbtcurrency(var1^) - tbts16(var2^);
                  btU32: tbtcurrency(var1^) := tbtcurrency(var1^) - tbtu32(var2^);
                  btS32: tbtcurrency(var1^) := tbtcurrency(var1^) - tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtcurrency(var1^) := tbtcurrency(var1^) - tbts64(var2^);
                    btU64: tbtcurrency(var1^) := tbtcurrency(var1^) - tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} - tbtsingle(var2^);
                  btDouble: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} - tbtdouble(var2^);
                  btExtended: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} - tbtextended(var2^);
                  btCurrency: tbtcurrency(var1^) := tbtcurrency(var1^) - tbtcurrency(var2^);
                  btVariant:  tbtcurrency(var1^) := tbtcurrency(var1^) -  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btDouble:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtdouble(var1^) := tbtdouble(var1^) - tbtu8(var2^);
                  btS8: tbtdouble(var1^) := tbtdouble(var1^) - tbts8(var2^);
                  btU16: tbtdouble(var1^) := tbtdouble(var1^) - tbtu16(var2^);
                  btS16: tbtdouble(var1^) := tbtdouble(var1^) - tbts16(var2^);
                  btU32: tbtdouble(var1^) := tbtdouble(var1^) - tbtu32(var2^);
                  btS32: tbtdouble(var1^) := tbtdouble(var1^) - tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtdouble(var1^) := tbtdouble(var1^) - tbts64(var2^);
                    btU64: tbtdouble(var1^) := tbtdouble(var1^) - tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtdouble(var1^) := tbtdouble(var1^) - tbtsingle(var2^);
                  btDouble: tbtdouble(var1^) := tbtdouble(var1^) - tbtdouble(var2^);
                  btExtended: tbtdouble(var1^) := tbtdouble(var1^) - tbtextended(var2^);
                  btCurrency: tbtdouble(var1^) := tbtdouble(var1^) - {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtdouble(var1^) := tbtdouble(var1^) -  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btExtended:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtextended(var1^) := tbtextended(var1^) - tbtu8(var2^);
                  btS8: tbtextended(var1^) := tbtextended(var1^) - tbts8(var2^);
                  btU16: tbtextended(var1^) := tbtextended(var1^) - tbtu16(var2^);
                  btS16: tbtextended(var1^) := tbtextended(var1^) - tbts16(var2^);
                  btU32: tbtextended(var1^) := tbtextended(var1^) - tbtu32(var2^);
                  btS32: tbtextended(var1^) := tbtextended(var1^) - tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtextended(var1^) := tbtextended(var1^) - tbts64(var2^);
                    btU64: tbtextended(var1^) := tbtextended(var1^) - tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtextended(var1^) := tbtextended(var1^) - tbtsingle(var2^);
                  btDouble: tbtextended(var1^) := tbtextended(var1^) - tbtdouble(var2^);
                  btExtended: tbtextended(var1^) := tbtextended(var1^) - tbtextended(var2^);
                  btCurrency: tbtextended(var1^) := tbtextended(var1^) - {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtextended(var1^) := tbtextended(var1^) -  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btChar: tbtchar(var1^):= tbtchar(ord(tbtchar(var1^)) - PSGetUInt(Var2, var2type));
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar: tbtwidechar(var1^) := widechar(ord(tbtwidechar(var1^)) - PSGetUInt(Var2, var2type));
            {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) - tvar;
              end;
            btSet:
              begin
                if var1Type = var2Type then
                begin
                  Set_Diff(var1, var2, TPSTypeRec_Set(var1Type).aByteSize);
                end else result := False;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      {$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}
      {$IFDEF DELPHI10UP}{$REGION '*'}{$ENDIF}
      2: begin { * }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) * PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) * PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) * PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) * PSGetInt(Var2, var2type);
            btU32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtU32(var1^) := tbtU32(var1^) * tbtu8(var2^);
                  btS8: tbtU32(var1^) := tbtU32(var1^) * cardinal(longint(tbts8(var2^)));
                  btU16: tbtU32(var1^) := tbtU32(var1^) * tbtu16(var2^);
                  btS16: tbtU32(var1^) := tbtU32(var1^) * cardinal(longint(tbts16(var2^)));
                  btU32: tbtU32(var1^) := tbtU32(var1^) * tbtu32(var2^);
                  btS32: tbtU32(var1^) := tbtU32(var1^) * cardinal(tbts32(var2^));
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtU32(var1^) := tbtU32(var1^) * tbts64(var2^);
                    btU64: tbtU32(var1^) := tbtU32(var1^) * tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbtU32(var1^) := tbtU32(var1^) *  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtU32(var1^) := tbtU32(var1^) * Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbtU32(var1^) := tbtU32(var1^) * Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbts32(var1^) := tbts32(var1^) * tbtu8(var2^);
                  btS8: tbts32(var1^) := tbts32(var1^) * tbts8(var2^);
                  btU16: tbts32(var1^) := tbts32(var1^) * tbtu16(var2^);
                  btS16: tbts32(var1^) := tbts32(var1^) * tbts16(var2^);
                  btU32: tbts32(var1^) := tbts32(var1^) * Longint(tbtu32(var2^));
                  btS32: tbts32(var1^) := tbts32(var1^) * tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbts32(var1^) := tbts32(var1^) * tbts64(var2^);
                    btU64: tbts32(var1^) := tbts32(var1^) * tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbts32(var1^) := tbts32(var1^) *  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbts32(var1^) := tbts32(var1^) * Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbts32(var1^) := tbts32(var1^) * Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) * PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) * PSGetUInt64(var2, var2type);
           {$ENDIF}
            btCurrency:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtcurrency(var1^) := tbtcurrency(var1^) * tbtu8(var2^);
                  btS8: tbtcurrency(var1^) := tbtcurrency(var1^) * tbts8(var2^);
                  btU16: tbtcurrency(var1^) := tbtcurrency(var1^) * tbtu16(var2^);
                  btS16: tbtcurrency(var1^) := tbtcurrency(var1^) * tbts16(var2^);
                  btU32: tbtcurrency(var1^) := tbtcurrency(var1^) * tbtu32(var2^);
                  btS32: tbtcurrency(var1^) := tbtcurrency(var1^) * tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtcurrency(var1^) := tbtcurrency(var1^) * tbts64(var2^);
                    btU64: tbtcurrency(var1^) := tbtcurrency(var1^) * tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} * tbtsingle(var2^);
                  btDouble: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} * tbtdouble(var2^);
                  btExtended: tbtcurrency(var1^) := {$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var1^)){$ELSE}tbtcurrency(var1^){$ENDIF} * tbtextended(var2^);
                  btCurrency: tbtcurrency(var1^) := tbtcurrency(var1^) * tbtcurrency(var2^);
                  btVariant:  tbtcurrency(var1^) := tbtcurrency(var1^) *  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btSingle:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtsingle(var1^) := tbtsingle(var1^) *tbtu8(var2^);
                  btS8: tbtsingle(var1^) := tbtsingle(var1^) *tbts8(var2^);
                  btU16: tbtsingle(var1^) := tbtsingle(var1^) *tbtu16(var2^);
                  btS16: tbtsingle(var1^) := tbtsingle(var1^) *tbts16(var2^);
                  btU32: tbtsingle(var1^) := tbtsingle(var1^) *tbtu32(var2^);
                  btS32: tbtsingle(var1^) := tbtsingle(var1^) *tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtsingle(var1^) := tbtsingle(var1^) *tbts64(var2^);
                    btU64: tbtsingle(var1^) := tbtsingle(var1^) *tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtsingle(var1^) := tbtsingle(var1^) *tbtsingle(var2^);
                  btDouble: tbtsingle(var1^) := tbtsingle(var1^) *tbtdouble(var2^);
                  btExtended: tbtsingle(var1^) := tbtsingle(var1^) *tbtextended(var2^);
                  btCurrency: tbtsingle(var1^) := tbtsingle(var1^) *{$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtsingle(var1^) := tbtsingle(var1^) * Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btDouble:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtdouble(var1^) := tbtdouble(var1^) *tbtu8(var2^);
                  btS8: tbtdouble(var1^) := tbtdouble(var1^) *tbts8(var2^);
                  btU16: tbtdouble(var1^) := tbtdouble(var1^) *tbtu16(var2^);
                  btS16: tbtdouble(var1^) := tbtdouble(var1^) *tbts16(var2^);
                  btU32: tbtdouble(var1^) := tbtdouble(var1^) *tbtu32(var2^);
                  btS32: tbtdouble(var1^) := tbtdouble(var1^) *tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtdouble(var1^) := tbtdouble(var1^) *tbts64(var2^);
                    btU64: tbtdouble(var1^) := tbtdouble(var1^) *tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtdouble(var1^) := tbtdouble(var1^) *tbtsingle(var2^);
                  btDouble: tbtdouble(var1^) := tbtdouble(var1^) *tbtdouble(var2^);
                  btExtended: tbtdouble(var1^) := tbtdouble(var1^) *tbtextended(var2^);
                  btCurrency: tbtdouble(var1^) := tbtdouble(var1^) *{$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtdouble(var1^) := tbtdouble(var1^) * Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btExtended:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtextended(var1^) := tbtextended(var1^) *tbtu8(var2^);
                  btS8: tbtextended(var1^) := tbtextended(var1^) *tbts8(var2^);
                  btU16: tbtextended(var1^) := tbtextended(var1^) *tbtu16(var2^);
                  btS16: tbtextended(var1^) := tbtextended(var1^) *tbts16(var2^);
                  btU32: tbtextended(var1^) := tbtextended(var1^) *tbtu32(var2^);
                  btS32: tbtextended(var1^) := tbtextended(var1^) *tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtextended(var1^) := tbtextended(var1^) *tbts64(var2^);
                    btU64: tbtextended(var1^) := tbtextended(var1^) *tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtextended(var1^) := tbtextended(var1^) *tbtsingle(var2^);
                  btDouble: tbtextended(var1^) := tbtextended(var1^) *tbtdouble(var2^);
                  btExtended: tbtextended(var1^) := tbtextended(var1^) *tbtextended(var2^);
                  btCurrency: tbtextended(var1^) := tbtextended(var1^) *{$IFDEF FPC_CURRENCY_IS_INT64}_CurrAsReal(tbtcurrency(var2^)){$ELSE}tbtcurrency(var2^){$ENDIF};
                  btVariant:  tbtextended(var1^) := tbtextended(var1^) * Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) * tvar;
              end;
            btSet:
              begin
                if var1Type = var2Type then
                begin
                  Set_Intersect(var1, var2, TPSTypeRec_Set(var1Type).aByteSize);
                end else result := False;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      {$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}
      {$IFDEF DELPHI10UP}{$REGION '/'}{$ENDIF}
      3: begin { / }
          case var1Type.BaseType of
            { a 64-bit divisor is not narrowed, as for a 32-bit dividend }
            btU8:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbtU8(var1^) := tbtU8(var1^) div PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbtU8(var1^) := tbtU8(var1^) div PSGetUInt64(Var2, var2type)
              { a signed divisor makes the division signed, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) in [btS8, btS16, btS32] then
                tbtU8(var1^) := Int64(tbtU8(var1^)) div PSGetInt(Var2, var2type)
              else
              {$ENDIF}
                tbtU8(var1^) := tbtU8(var1^) div PSGetUInt(Var2, var2type);
            btS8:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbts8(var1^) := tbts8(var1^) div PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbts8(var1^) := tbts8(var1^) div PSGetUInt64(Var2, var2type)
              { a Cardinal divisor makes the division 64-bit, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) = btU32 then
                tbts8(var1^) := Int64(tbts8(var1^)) div PSGetUInt(Var2, var2type)
              else
              {$ENDIF}
                tbts8(var1^) := tbts8(var1^) div PSGetInt(Var2, var2type);
            btU16:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbtU16(var1^) := tbtU16(var1^) div PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbtU16(var1^) := tbtU16(var1^) div PSGetUInt64(Var2, var2type)
              { a signed divisor makes the division signed, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) in [btS8, btS16, btS32] then
                tbtU16(var1^) := Int64(tbtU16(var1^)) div PSGetInt(Var2, var2type)
              else
              {$ENDIF}
                tbtU16(var1^) := tbtU16(var1^) div PSGetUInt(Var2, var2type);
            btS16:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbts16(var1^) := tbts16(var1^) div PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbts16(var1^) := tbts16(var1^) div PSGetUInt64(Var2, var2type)
              { a Cardinal divisor makes the division 64-bit, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) = btU32 then
                tbts16(var1^) := Int64(tbts16(var1^)) div PSGetUInt(Var2, var2type)
              else
              {$ENDIF}
                tbts16(var1^) := tbts16(var1^) div PSGetInt(Var2, var2type);
            btU32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtU32(var1^) := tbtU32(var1^) div tbtu8(var2^);
                  btS8: tbtU32(var1^) := Int64(tbtU32(var1^)) div tbts8(var2^);
                  btU16: tbtU32(var1^) := tbtU32(var1^) div tbtu16(var2^);
                  btS16: tbtU32(var1^) := Int64(tbtU32(var1^)) div tbts16(var2^);
                  btU32: tbtU32(var1^) := tbtU32(var1^) div tbtu32(var2^);
                  btS32: tbtU32(var1^) := Int64(tbtU32(var1^)) div tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtU32(var1^) := tbtU32(var1^) div tbts64(var2^);
                    btU64: tbtU32(var1^) := tbtU32(var1^) div tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbtU32(var1^) := tbtU32(var1^) div  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtU32(var1^) := tbtU32(var1^) div Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbtU32(var1^) := tbtU32(var1^) div Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbts32(var1^) := tbts32(var1^) div tbtu8(var2^);
                  btS8: tbts32(var1^) := tbts32(var1^) div tbts8(var2^);
                  btU16: tbts32(var1^) := tbts32(var1^) div tbtu16(var2^);
                  btS16: tbts32(var1^) := tbts32(var1^) div tbts16(var2^);
                  btU32: tbts32(var1^) := Int64(tbts32(var1^)) div tbtu32(var2^);
                  btS32: tbts32(var1^) := tbts32(var1^) div tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbts32(var1^) := tbts32(var1^) div tbts64(var2^);
                    btU64: tbts32(var1^) := tbts32(var1^) div tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbts32(var1^) := tbts32(var1^) div  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbts32(var1^) := tbts32(var1^) div Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbts32(var1^) := tbts32(var1^) div Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) div PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) div PSGetUInt64(var2, var2type);
           {$ENDIF}
            btSingle:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtsingle(var1^) := tbtsingle(var1^) / tbtu8(var2^);
                  btS8: tbtsingle(var1^) := tbtsingle(var1^) / tbts8(var2^);
                  btU16: tbtsingle(var1^) := tbtsingle(var1^) / tbtu16(var2^);
                  btS16: tbtsingle(var1^) := tbtsingle(var1^) / tbts16(var2^);
                  btU32: tbtsingle(var1^) := tbtsingle(var1^) / tbtu32(var2^);
                  btS32: tbtsingle(var1^) := tbtsingle(var1^) / tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtsingle(var1^) := tbtsingle(var1^) / tbts64(var2^);
                    btU64: tbtsingle(var1^) := tbtsingle(var1^) / tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtsingle(var1^) := tbtsingle(var1^) / tbtsingle(var2^);
                  btDouble: tbtsingle(var1^) := tbtsingle(var1^) / tbtdouble(var2^);
                  btExtended: tbtsingle(var1^) := tbtsingle(var1^) / tbtextended(var2^);
                  btCurrency: tbtsingle(var1^) := tbtsingle(var1^) / tbtcurrency(var2^);
                  btVariant:  tbtsingle(var1^) := tbtsingle(var1^) /  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btCurrency:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtu8(var2^);
                  btS8: tbtcurrency(var1^) := tbtcurrency(var1^) / tbts8(var2^);
                  btU16: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtu16(var2^);
                  btS16: tbtcurrency(var1^) := tbtcurrency(var1^) / tbts16(var2^);
                  btU32: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtu32(var2^);
                  btS32: tbtcurrency(var1^) := tbtcurrency(var1^) / tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtcurrency(var1^) := tbtcurrency(var1^) / tbts64(var2^);
                    btU64: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtsingle(var2^);
                  btDouble: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtdouble(var2^);
                  btExtended: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtextended(var2^);
                  btCurrency: tbtcurrency(var1^) := tbtcurrency(var1^) / tbtcurrency(var2^);
                  btVariant:  tbtcurrency(var1^) := tbtcurrency(var1^) /  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btDouble:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtdouble(var1^) := tbtdouble(var1^) / tbtu8(var2^);
                  btS8: tbtdouble(var1^) := tbtdouble(var1^) / tbts8(var2^);
                  btU16: tbtdouble(var1^) := tbtdouble(var1^) / tbtu16(var2^);
                  btS16: tbtdouble(var1^) := tbtdouble(var1^) / tbts16(var2^);
                  btU32: tbtdouble(var1^) := tbtdouble(var1^) / tbtu32(var2^);
                  btS32: tbtdouble(var1^) := tbtdouble(var1^) / tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtdouble(var1^) := tbtdouble(var1^) / tbts64(var2^);
                    btU64: tbtdouble(var1^) := tbtdouble(var1^) / tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtdouble(var1^) := tbtdouble(var1^) / tbtsingle(var2^);
                  btDouble: tbtdouble(var1^) := tbtdouble(var1^) / tbtdouble(var2^);
                  btExtended: tbtdouble(var1^) := tbtdouble(var1^) / tbtextended(var2^);
                  btCurrency: tbtdouble(var1^) := tbtdouble(var1^) / tbtcurrency(var2^);
                  btVariant:  tbtdouble(var1^) := tbtdouble(var1^) /  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btExtended:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtextended(var1^) := tbtextended(var1^) / tbtu8(var2^);
                  btS8: tbtextended(var1^) := tbtextended(var1^) / tbts8(var2^);
                  btU16: tbtextended(var1^) := tbtextended(var1^) / tbtu16(var2^);
                  btS16: tbtextended(var1^) := tbtextended(var1^) / tbts16(var2^);
                  btU32: tbtextended(var1^) := tbtextended(var1^) / tbtu32(var2^);
                  btS32: tbtextended(var1^) := tbtextended(var1^) / tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtextended(var1^) := tbtextended(var1^) / tbts64(var2^);
                    btU64: tbtextended(var1^) := tbtextended(var1^) / tbtu64(var2^);
                  {$ENDIF}
                  btSingle: tbtextended(var1^) := tbtextended(var1^) / tbtsingle(var2^);
                  btDouble: tbtextended(var1^) := tbtextended(var1^) / tbtdouble(var2^);
                  btExtended: tbtextended(var1^) := tbtextended(var1^) / tbtextended(var2^);
                  btCurrency: tbtextended(var1^) := tbtextended(var1^) / tbtcurrency(var2^);
                  btVariant:  tbtextended(var1^) := tbtextended(var1^) /  Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                begin
                  if VarIsFloat(variant(var1^)) then
                    Variant(var1^) := Variant(var1^) / tvar
                  else
                    Variant(var1^) := Variant(var1^) div tvar;
                end;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      {$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}
      {$IFDEF DELPHI10UP}{$REGION 'MOD'}{$ENDIF}
      4: begin { MOD }
          case var1Type.BaseType of
            { a 64-bit divisor is not narrowed, as for a 32-bit dividend }
            btU8:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbtU8(var1^) := tbtU8(var1^) mod PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbtU8(var1^) := tbtU8(var1^) mod PSGetUInt64(Var2, var2type)
              { a signed divisor makes the division signed, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) in [btS8, btS16, btS32] then
                tbtU8(var1^) := Int64(tbtU8(var1^)) mod PSGetInt(Var2, var2type)
              else
              {$ENDIF}
                tbtU8(var1^) := tbtU8(var1^) mod PSGetUInt(Var2, var2type);
            btS8:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbts8(var1^) := tbts8(var1^) mod PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbts8(var1^) := tbts8(var1^) mod PSGetUInt64(Var2, var2type)
              { a Cardinal divisor makes the division 64-bit, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) = btU32 then
                tbts8(var1^) := Int64(tbts8(var1^)) mod PSGetUInt(Var2, var2type)
              else
              {$ENDIF}
                tbts8(var1^) := tbts8(var1^) mod PSGetInt(Var2, var2type);
            btU16:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbtU16(var1^) := tbtU16(var1^) mod PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbtU16(var1^) := tbtU16(var1^) mod PSGetUInt64(Var2, var2type)
              { a signed divisor makes the division signed, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) in [btS8, btS16, btS32] then
                tbtU16(var1^) := Int64(tbtU16(var1^)) mod PSGetInt(Var2, var2type)
              else
              {$ENDIF}
                tbtU16(var1^) := tbtU16(var1^) mod PSGetUInt(Var2, var2type);
            btS16:
              {$IFNDEF PS_NOINT64}
              if _DivisorBaseType(Var2, var2type) = btS64 then
                tbts16(var1^) := tbts16(var1^) mod PSGetInt64(Var2, var2type)
              else if _DivisorBaseType(Var2, var2type) = btU64 then
                tbts16(var1^) := tbts16(var1^) mod PSGetUInt64(Var2, var2type)
              { a Cardinal divisor makes the division 64-bit, as in Delphi }
              else if _DivisorBaseType(Var2, var2type) = btU32 then
                tbts16(var1^) := Int64(tbts16(var1^)) mod PSGetUInt(Var2, var2type)
              else
              {$ENDIF}
                tbts16(var1^) := tbts16(var1^) mod PSGetInt(Var2, var2type);
            btU32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbtU32(var1^) := tbtU32(var1^) mod tbtu8(var2^);
                  btS8: tbtU32(var1^) := Int64(tbtU32(var1^)) mod tbts8(var2^);
                  btU16: tbtU32(var1^) := tbtU32(var1^) mod tbtu16(var2^);
                  btS16: tbtU32(var1^) := Int64(tbtU32(var1^)) mod tbts16(var2^);
                  btU32: tbtU32(var1^) := tbtU32(var1^) mod tbtu32(var2^);
                  btS32: tbtU32(var1^) := Int64(tbtU32(var1^)) mod tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbtU32(var1^) := tbtU32(var1^) mod tbts64(var2^);
                    btU64: tbtU32(var1^) := tbtU32(var1^) mod tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbtU32(var1^) := tbtU32(var1^) mod  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbtU32(var1^) := tbtU32(var1^) mod Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbtU32(var1^) := tbtU32(var1^) mod Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
            btS32:
              begin
                if var2type.BaseType = btPointer then
                begin
                  var2type := PIFTypeRec(Pointer(IPointer(var2)+PointerSize)^);
                  var2 := Pointer(var2^);
                  if (var2 = nil) or (var2type = nil) then raise Exception.Create(RPS_TypeMismatch);
                end;
                case var2type.BaseType of
                  btU8: tbts32(var1^) := tbts32(var1^) mod tbtu8(var2^);
                  btS8: tbts32(var1^) := tbts32(var1^) mod tbts8(var2^);
                  btU16: tbts32(var1^) := tbts32(var1^) mod tbtu16(var2^);
                  btS16: tbts32(var1^) := tbts32(var1^) mod tbts16(var2^);
                  btU32: tbts32(var1^) := Int64(tbts32(var1^)) mod tbtu32(var2^);
                  btS32: tbts32(var1^) := tbts32(var1^) mod tbts32(var2^);
                  {$IFNDEF PS_NOINT64}
                    btS64: tbts32(var1^) := tbts32(var1^) mod tbts64(var2^);
                    btU64: tbts32(var1^) := tbts32(var1^) mod tbtu64(var2^);
                  {$ENDIF}
                  btChar: tbts32(var1^) := tbts32(var1^) mod  Ord(tbtchar(var2^));
              {$IFNDEF PS_NOWIDESTRING}    btWideChar: tbts32(var1^) := tbts32(var1^) mod Ord(tbtwidechar(var2^));{$ENDIF}
                  btVariant: tbts32(var1^) := tbts32(var1^) mod Variant(var2^);
                  else raise Exception.Create(RPS_TypeMismatch);
                end;
              end;
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) mod PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) mod PSGetUInt64(var2, var2type);
           {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) mod tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      5: begin { SHL }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) shl PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) shl PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) shl PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) shl PSGetInt(Var2, var2type);
            btU32: tbtU32(var1^) := tbtU32(var1^) shl PSGetUInt(Var2, var2type);
            btS32: tbts32(var1^) := tbts32(var1^) shl PSGetInt(Var2, var2type);
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) shl PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) shl PSGetUInt64(var2, var2type);
           {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) shl tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      6: begin { SHR }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) shr PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) shr PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) shr PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) shr PSGetInt(Var2, var2type);
            btU32: tbtU32(var1^) := tbtU32(var1^) shr PSGetUInt(Var2, var2type);
            btS32: tbts32(var1^) := tbts32(var1^) shr PSGetInt(Var2, var2type);
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) shr PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) shr PSGetUInt64(var2, var2type);
           {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) shr tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      7: begin { AND }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) and PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) and PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) and PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) and PSGetInt(Var2, var2type);
            btU32: tbtU32(var1^) := tbtU32(var1^) and PSGetUInt(Var2, var2type);
            btS32: tbts32(var1^) := tbts32(var1^) and PSGetInt(Var2, var2type);
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) and PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) and PSGetUInt64(var2, var2type);
           {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) and tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      8: begin { OR }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) or PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) or PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) or PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) or PSGetInt(Var2, var2type);
            btU32: tbtU32(var1^) := tbtU32(var1^) or PSGetUInt(Var2, var2type);
            btS32: tbts32(var1^) := tbts32(var1^) or PSGetInt(Var2, var2type);
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) or PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) or PSGetUInt64(var2, var2type);
           {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) or tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      9: begin { XOR }
          case var1Type.BaseType of
            btU8: tbtU8(var1^) := tbtU8(var1^) xor PSGetUInt(Var2, var2type);
            btS8: tbts8(var1^) := tbts8(var1^) xor PSGetInt(Var2, var2type);
            btU16: tbtU16(var1^) := tbtU16(var1^) xor PSGetUInt(Var2, var2type);
            btS16: tbts16(var1^) := tbts16(var1^) xor PSGetInt(Var2, var2type);
            btU32: tbtU32(var1^) := tbtU32(var1^) xor PSGetUInt(Var2, var2type);
            btS32: tbts32(var1^) := tbts32(var1^) xor PSGetInt(Var2, var2type);
           {$IFNDEF PS_NOINT64}
            btS64: tbts64(var1^) := tbts64(var1^) xor PSGetInt64(var2, var2type);
            btU64: tbtu64(var1^) := tbtu64(var1^) xor PSGetUInt64(var2, var2type);
           {$ENDIF}
            btVariant:
              begin
                if not IntPIFVariantToVariant(var2, var2type, tvar) then
                begin
                  Result := false;
                end else
                  Variant(var1^) := Variant(var1^) xor tvar;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      10:
        begin // as
          case var1Type.BaseType of
            btClass:
              begin
                if var2type.BaseType <> btU32 then
                  Result := False
                else
                begin
                  var2type := FTypes[tbtu32(var2^)];
                  if (var2type = nil) or (var2type.BaseType <> btClass) then
                    Result := false
                  else
                  begin
                    if (TObject(var1^) <> nil) and not Class_IS(Self, TObject(var1^), var2type) then
                      Result := false
                  end;
                end;
              end;
          else begin
              CMD_Err(erTypeMismatch);
              exit;
            end;
          end;
          if not Result then begin
            CMD_Err(erTypeMismatch);
            exit;
          end;
        end;
      {$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}
    else begin
        Result := False;
        CMD_Err(erInvalidOpcodeParameter);
        exit;
      end;
    end;
  except
    {$IFDEF DELPHI6UP}
    Tmp := AcquireExceptionObject;
    {$ELSE}
    if RaiseList <> nil then
    begin
      Tmp := Exception(PRaiseFrame(RaiseList)^.ExceptObject);
      PRaiseFrame(RaiseList)^.ExceptObject := nil;
    end else
      Tmp := nil;
    {$ENDIF}
    if Tmp <> nil then
    begin
      if Tmp is EPSException then
      begin
        Result := False;
        ExceptionProc(EPSException(tmp).ProcNo, EPSException(tmp).ProcPos, erCustomError, tbtString(EPSException(tmp).Message), nil);
        Tmp.Free;
        exit;
      end else
      if Tmp is EDivByZero then
      begin
        Result := False;
        CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
      if Tmp is EZeroDivide then
      begin
        Result := False;
        CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
      if Tmp is EMathError then
      begin
        Result := False;
        CMD_Err3(erMathError,tbtString(Exception(Tmp).Message), Tmp);
        Exit;
      end;
    end;
    if (tmp <> nil) and (Tmp is Exception) then
      CMD_Err3(erException, tbtString(Exception(Tmp).Message), Tmp)
    else
      CMD_Err3(erException, '', Tmp);
    Result := False;
  end;
end;

function TPSExec.ReadVariable(var Dest: TPSResultData; UsePointer: Boolean): Boolean;
const
  { the types the constant case below reads: a constant of any other type is
    refused before its place is made, since a static array or a record can be
    larger than the temporaries can hold }
  ConstantTypes = [btSet, bts8, btchar, btU8, bts16{$IFNDEF PS_NOWIDESTRING}, btwidechar{$ENDIF}, btU16, bts32, btU32,
    btProcPtr{$IFNDEF PS_NOINT64}, bts64, btU64{$ENDIF}, btSingle, btDouble, btExtended, btCurrency, btPchar, btString
    {$IFNDEF PS_NOWIDESTRING}, btWidestring, btUnicodeString{$ENDIF}];
var
  VarType: Cardinal;
  Param: Cardinal;
  Tmp: PIfVariant;
  at: TPSTypeRec;

{$IFNDEF PS_NOINT64}
  { a 64-bit index as the Cardinal the bounds checks below compare: one outside a Cardinal becomes
    High(Cardinal), which fails every check, as a negative 32-bit index does }
  function Index64(const aValue: Int64): Cardinal;
  begin
    if (aValue < 0) or (aValue > High(Cardinal)) then
      Result := High(Cardinal)
    else
      Result := Cardinal(aValue);
  end;
{$ENDIF}

begin
  if FCurrentPosition + 4 >= FDataLength then
  begin
    CMD_Err(erOutOfRange); // Error
    Result := False;
    exit;
  end;
  VarType := FData^[FCurrentPosition];
  Inc(FCurrentPosition);
  {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
  Param := unaligned(Cardinal((@FData^[FCurrentPosition])^));
  {$else}
  Param := Cardinal((@FData^[FCurrentPosition])^);
  {$endif}
  Inc(FCurrentPosition, 4);
  case VarType of
    0:
      begin
        Dest.FreeType := vtNone;
        if Param < PSAddrNegativeStackStart then
        begin
          if Param >= Cardinal(FGlobalVars.Count) then
          begin
            CMD_Err(erOutOfGlobalVarsRange);
            Result := False;
            exit;
          end;
          Tmp := FGlobalVars.Data[param];
        end else
        begin
          Param := Cardinal(Longint(-PSAddrStackStart) +
            Longint(FCurrStackBase) + Longint(Param));
          if Param >= Cardinal(FStack.Count) then
          begin
            CMD_Err(erOutOfStackRange);
            Result := False;
            exit;
          end;
          Tmp := FStack.Data[param];
        end;
        if (UsePointer) and (Tmp.FType.BaseType = btPointer) then
        begin
          Dest.aType := PPSVariantPointer(Tmp).DestType;
          Dest.P := PPSVariantPointer(Tmp).DataDest;
          if Dest.P = nil then
          begin
            Cmd_Err(erNullPointerException);
            Result := False;
            exit;
          end;
        end else
        begin
          Dest.aType := PPSVariantData(Tmp).vi.FType;
          Dest.P := @PPSVariantData(Tmp).Data;
        end;
      end;
    1: begin
        if Param >= FTypes.Count then
        begin
          CMD_Err(erInvalidType);
          Result := False;
          exit;
        end;
        at := FTypes.Data^[Param];
        if not (at.BaseType in ConstantTypes) then
        begin
          CMD_Err(erInvalidType);
          Result := False;
          exit;
        end;
        Param := FTempVars.FLength;
        FTempVars.FLength := Cardinal(Longint(Param) + Longint(at.RealSize) + Longint(RTTISize + 3)) and not 3;
        if FTempVars.FLength > FTempVars.FCapacity then FtempVars.AdjustLength;
        Tmp := Pointer(IPointer(FtempVars.FDataPtr) + IPointer(Param));

        { TPSList.Add: TPSStack's own FCapacity is the size of its data in bytes, not of its item list }
        FTempVars.Add(Tmp);


        Tmp.FType := at;
        Dest.P := @PPSVariantData(Tmp).Data;
        Dest.aType := tmp.FType;
        dest.FreeType := vtTempVar;
        { a value refused below is popped, which finalizes one of a managed
          type: its place holds nothing until its value is read }
        if at.BaseType in NeedFinalization then
          FillChar(Dest.P^, at.RealSize, 0);
        case Dest.aType.BaseType of
          btSet:
            begin
              if not ReadData(Dest.P^, TPSTypeRec_Set(Dest.aType).aByteSize) then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
            end;
          bts8, btchar, btU8:
            begin
              if FCurrentPosition >= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
              tbtu8(dest.p^) := FData^[FCurrentPosition];
              Inc(FCurrentPosition);
            end;
          bts16, {$IFNDEF PS_NOWIDESTRING}btwidechar,{$ENDIF} btU16:
            begin
              if FCurrentPosition + 1>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtu16(dest.p^) := unaligned(tbtu16((@FData^[FCurrentPosition])^));
	      {$else}
              tbtu16(dest.p^) := tbtu16((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 2);
            end;
          bts32, btU32:
            begin
              if FCurrentPosition + 3>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtu32(dest.p^) := unaligned(tbtu32((@FData^[FCurrentPosition])^));
	      {$else}
              tbtu32(dest.p^) := tbtu32((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
            end;
          btProcPtr:
            begin
              if FCurrentPosition + 3>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtu32(dest.p^) := unaligned(tbtu32((@FData^[FCurrentPosition])^));
	      {$else}
              tbtu32(dest.p^) := tbtu32((@FData^[FCurrentPosition])^);
	      {$endif}
              Pointer(Pointer(IPointer(dest.p)+PointerSize)^) := nil;
              Pointer(Pointer(IPointer(dest.p)+PointerSize2)^) := nil;
              Inc(FCurrentPosition, 4);
            end;
          {$IFNDEF PS_NOINT64}
          bts64:
            begin
              if FCurrentPosition + 7>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbts64(dest.p^) := unaligned(tbts64((@FData^[FCurrentPosition])^));
	      {$else}
              tbts64(dest.p^) := tbts64((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 8);
            end;
          btU64:
            begin
              if FCurrentPosition + 7>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtu64(dest.p^) := unaligned(tbtu64((@FData^[FCurrentPosition])^));
	      {$else}
              tbtu64(dest.p^) := tbtu64((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 8);
            end;
          {$ENDIF}
          btSingle:
            begin
              if FCurrentPosition + (Sizeof(Single)-1)>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtsingle(dest.p^) := unaligned(tbtsingle((@FData^[FCurrentPosition])^));
	      {$else}
              tbtsingle(dest.p^) := tbtsingle((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, Sizeof(Single));
            end;
          btDouble:
            begin
              if FCurrentPosition + (Sizeof(Double)-1)>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtdouble(dest.p^) := unaligned(tbtdouble((@FData^[FCurrentPosition])^));
	      {$else}
              tbtdouble(dest.p^) := tbtdouble((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, Sizeof(double));
            end;

          btExtended:
            begin
              if FCurrentPosition + (sizeof(Extended)-1)>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtextended(dest.p^) := unaligned(tbtextended((@FData^[FCurrentPosition])^));
	      {$else}
              tbtextended(dest.p^) := tbtextended((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, sizeof(Extended));
            end;
          btCurrency:
            begin
              if FCurrentPosition + (SizeOf(Currency)-1)>= FDataLength then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              tbtcurrency(dest.p^) := unaligned(tbtcurrency((@FData^[FCurrentPosition])^));
	      {$else}
              tbtcurrency(dest.p^) := tbtcurrency((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, SizeOf(Currency));
            end;
          btPchar, btString:
          begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              Param := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              Param := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              Pointer(Dest.P^) := nil;
              SetLength(tbtstring(Dest.P^), Param);
              if Param <> 0 then begin
              if not ReadData(tbtstring(Dest.P^)[1], Param) then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
                pansichar(dest.p^)[Param] := #0;
              end;
            end;
          {$IFNDEF PS_NOWIDESTRING}
          btWidestring:
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              Param := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              Param := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              Pointer(Dest.P^) := nil;
              SetLength(tbtwidestring(Dest.P^), Param);
              if (Param <> 0) and not ReadData(tbtwidestring(Dest.P^)[1], Param*2) then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
            end;
          btUnicodeString:
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              Param := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              Param := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              Pointer(Dest.P^) := nil;
              SetLength(tbtUnicodestring(Dest.P^), Param);
              if (Param <> 0) and not ReadData(tbtUnicodestring(Dest.P^)[1], Param*2) then
              begin
                CMD_Err(erOutOfRange);
                FTempVars.Pop;
                Result := False;
                exit;
              end;
            end;
          {$ENDIF}
        else begin
            CMD_Err(erInvalidType);
            FTempVars.Pop;
            Result := False;
            exit;
          end;
        end;
      end;
    2:
      begin
        Dest.FreeType := vtNone;
        if Param < PSAddrNegativeStackStart then begin
          if Param >= Cardinal(FGlobalVars.Count) then
          begin
            CMD_Err(erOutOfGlobalVarsRange);
            Result := False;
            exit;
          end;
          Tmp := FGlobalVars.Data[param];
        end
        else begin
          Param := Cardinal(Longint(-PSAddrStackStart) + Longint(FCurrStackBase) + Longint(Param));
          if Param >= Cardinal(FStack.Count) then
          begin
            CMD_Err(erOutOfStackRange);
            Result := False;
            exit;
          end;
          Tmp := FStack.Data[param];
        end;
        if Tmp.FType.BaseType = btPointer then
        begin
          Dest.aType := PPSVariantPointer(Tmp).DestType;
          Dest.P := PPSVariantPointer(Tmp).DataDest;
          if Dest.P = nil then
          begin
            Cmd_Err(erNullPointerException);
            Result := False;
            exit;
          end;
        end else
        begin
          Dest.aType := PPSVariantData(Tmp).vi.FType;
          Dest.P := @PPSVariantData(Tmp).Data;
        end;
        if FCurrentPosition + 3 >= FDataLength then
        begin
          CMD_Err(erOutOfRange);
          Result := False;
          exit;
        end;
	{$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
        Param := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	{$else}
        Param := Cardinal((@FData^[FCurrentPosition])^);
	{$endif}
        Inc(FCurrentPosition, 4);
        case Dest.aType.BaseType of
          btRecord:
            begin
              if Param >= Cardinal(TPSTypeRec_Record(Dest.aType).FFieldTypes.Count) then
              begin
                CMD_Err(erOutOfRange);
                Result := False;
                exit;
              end;
              Dest.P := Pointer(IPointer(Dest.P) + IPointer(TPSTypeRec_Record(Dest.aType).RealFieldOffsets[Param]));
              Dest.aType := TPSTypeRec_Record(Dest.aType).FieldTypes[Param];
            end;
          btArray:
            begin
              if Param >= Cardinal(PSDynArrayGetLength(Pointer(Dest.P^), dest.aType)) then
              begin
                CMD_Err2(erCustomError,
                         tbtstring(Format('Array index out of bounds (%d). Length is %d.',
                                [Param, Cardinal(PSDynArrayGetLength(Pointer(Dest.P^), dest.aType))])));
                Result := False;
                exit;
              end;
              Dest.P := Pointer(IPointer(Dest.P^) + (Param * TPSTypeRec_Array(Dest.aType).FArrayType.RealSize));
              Dest.aType := TPSTypeRec_Array(dest.aType).ArrayType;
            end;
          btStaticArray:
            begin
              if Param >= Cardinal(TPSTypeRec_StaticArray(Dest.aType).Size) then
              begin
                CMD_Err2(erCustomError,
                         tbtstring(Format('Static array index out of bounds (%d). Length is %d.',
                                [Param, Cardinal(TPSTypeRec_StaticArray(Dest.aType).Size)])));
                Result := False;
                exit;
              end;
              Dest.P := Pointer(IPointer(Dest.P) + (Param * TPSTypeRec_Array(Dest.aType).FArrayType.RealSize));
              Dest.aType := TPSTypeRec_Array(dest.aType).ArrayType;
            end;
        else
          CMD_Err(erInvalidType);
          Result := False;
          exit;
        end;

        if UsePointer and (Dest.aType.BaseType = btPointer) then
        begin
          Dest.aType := TPSTypeRec(Pointer(IPointer(Dest.p)+PointerSize)^);
          Dest.P := Pointer(Dest.p^);
          if Dest.P = nil then
          begin
            Cmd_Err(erNullPointerException);
            Result := False;
            exit;
          end;
        end;
      end;
    3:
      begin
        Dest.FreeType := vtNone;
        if Param < PSAddrNegativeStackStart then begin
          if Param >= Cardinal(FGlobalVars.Count) then
          begin
            CMD_Err(erOutOfGlobalVarsRange);
            Result := False;
            exit;
          end;
          Tmp := FGlobalVars.Data[param];
        end
        else begin
          Param := Cardinal(Longint(-PSAddrStackStart) + Longint(FCurrStackBase) + Longint(Param));
          if Param >= Cardinal(FStack.Count) then
          begin
            CMD_Err(erOutOfStackRange);
            Result := False;
            exit;
          end;
          Tmp := FStack.Data[param];
        end;
        if (Tmp.FType.BaseType = btPointer) then
        begin
          Dest.aType := PPSVariantPointer(Tmp).DestType;
          Dest.P := PPSVariantPointer(Tmp).DataDest;
          if Dest.P = nil then
          begin
            Cmd_Err(erNullPointerException);
            Result := False;
            exit;
          end;
        end else
        begin
          Dest.aType := PPSVariantData(Tmp).vi.FType;
          Dest.P := @PPSVariantData(Tmp).Data;
        end;
        if FCurrentPosition + 3 >= FDataLength then
        begin
          CMD_Err(erOutOfRange);
          Result := False;
          exit;
        end;
	{$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
        Param := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	{$else}
        Param := Cardinal((@FData^[FCurrentPosition])^);
	{$endif}
        Inc(FCurrentPosition, 4);
        if Param < PSAddrNegativeStackStart then
        begin
          if Param >= Cardinal(FGlobalVars.Count) then
          begin
            CMD_Err(erOutOfGlobalVarsRange);
            Result := false;
            exit;
          end;
          Tmp := FGlobalVars[Param];
        end
        else begin
          Param := Cardinal(Longint(-PSAddrStackStart) + Longint(FCurrStackBase) + Longint(Param));
          if Cardinal(Param) >= Cardinal(FStack.Count) then
          begin
            CMD_Err(erOutOfStackRange);
            Result := false;
            exit;
          end;
          Tmp := FStack[Param];
        end;
        case Tmp.FType.BaseType of
          btu8: Param := PPSVariantU8(Tmp).Data;
          bts8: Param := PPSVariants8(Tmp).Data;
          btu16: Param := PPSVariantU16(Tmp).Data;
          bts16: Param := PPSVariants16(Tmp).Data;
          btu32: Param := PPSVariantU32(Tmp).Data;
          bts32: Param := PPSVariants32(Tmp).Data;
          {$IFNDEF PS_NOINT64}
          bts64: Param := Index64(PPSVariantS64(Tmp).Data);
          btu64: Param := Index64(PInt64(@PPSVariantU64(Tmp).Data)^);
          {$ENDIF}
          btPointer:
            begin
              if PPSVariantPointer(tmp).DestType <> nil then
              begin
                case PPSVariantPointer(tmp).DestType.BaseType of
                  btu8: Param := tbtu8(PPSVariantPointer(tmp).DataDest^);
                  bts8: Param := tbts8(PPSVariantPointer(tmp).DataDest^);
                  btu16: Param := tbtu16(PPSVariantPointer(tmp).DataDest^);
                  bts16: Param := tbts16(PPSVariantPointer(tmp).DataDest^);
                  btu32, btProcPtr: Param := tbtu32(PPSVariantPointer(tmp).DataDest^);
                  bts32: Param := tbts32(PPSVariantPointer(tmp).DataDest^);
                  {$IFNDEF PS_NOINT64}
                  bts64, btu64: Param := Index64(PInt64(PPSVariantPointer(tmp).DataDest)^);
                  {$ENDIF}
                  else
                    begin
                      CMD_Err(ErTypeMismatch);
                      Result := false;
                      exit;
                    end;
                end;
              end else
              begin
                CMD_Err(ErTypeMismatch);
                Result := false;
                exit;
              end;
            end;
        else
          CMD_Err(ErTypeMismatch);
          Result := false;
          exit;
        end;
        case Dest.aType.BaseType of
          btRecord:
            begin
              if Param >= Cardinal(TPSTypeRec_Record(Dest.aType).FFieldTypes.Count) then
              begin
                CMD_Err(erOutOfRange);
                Result := False;
                exit;
              end;
              Dest.P := Pointer(IPointer(Dest.P) + IPointer(TPSTypeRec_Record(Dest.aType).RealFieldOffsets[Param]));
              Dest.aType := TPSTypeRec_Record(Dest.aType).FieldTypes[Param];
            end;
          btArray:
            begin
              if Cardinal(Param) >= Cardinal(PSDynArrayGetLength(Pointer(Dest.P^), dest.aType)) then
              begin
                CMD_Err2(erCustomError,
                         tbtstring(Format('Array index out of bounds (%d). Length is %d.',
                                [Param, Cardinal(PSDynArrayGetLength(Pointer(Dest.P^), dest.aType))])));
                Result := False;
                exit;
              end;
              Dest.P := Pointer(IPointer(Dest.P^) + (Param * TPSTypeRec_Array(Dest.aType).FArrayType.RealSize));
              Dest.aType := TPSTypeRec_Array(dest.aType).ArrayType;
            end;
          btStaticArray:
            begin
              if Param >= Cardinal(TPSTypeRec_StaticArray(Dest.aType).Size) then
              begin
                CMD_Err2(erCustomError,
                         tbtstring(Format('Static array index out of bounds (%d). Length is %d.',
                                [Param, Cardinal(TPSTypeRec_StaticArray(Dest.aType).Size)])));
                Result := False;
                exit;
              end;
              Dest.P := Pointer(IPointer(Dest.P) + (Param * TPSTypeRec_Array(Dest.aType).FArrayType.RealSize));
              Dest.aType := TPSTypeRec_Array(dest.aType).ArrayType;
            end;
        else
          CMD_Err(erInvalidType);
          Result := False;
          exit;
        end;
        if UsePointer and (Dest.aType.BaseType = btPointer) then
        begin
          Dest.aType := TPSTypeRec(Pointer(IPointer(Dest.p)+PointerSize)^);
          Dest.P := Pointer(Dest.p^);
          if Dest.P = nil then
          begin
            Cmd_Err(erNullPointerException);
            Result := False;
            exit;
          end;
        end;
      end;
  else
    begin
      CMD_Err(erInvalidOpcodeParameter);
      Result := False;
      exit;
    end;
  end;
  Result := true;
end;

function TPSExec.DoMinus(Dta: Pointer; aType: TPSTypeRec): Boolean;
begin
  case atype.BaseType of
    btU8: tbtu8(dta^) := -tbtu8(dta^);
    btU16: tbtu16(dta^) := -tbtu16(dta^);
    btU32: tbtu32(dta^) := -tbtu32(dta^);
    btS8: tbts8(dta^) := -tbts8(dta^);
    btS16: tbts16(dta^) := -tbts16(dta^);
    btS32: tbts32(dta^) := -tbts32(dta^);
    {$IFNDEF PS_NOINT64}
    bts64: tbts64(dta^) := -tbts64(dta^);
    btU64: tbtu64(dta^) := -tbtu64(dta^);
    {$ENDIF}
    btSingle: tbtsingle(dta^) := -tbtsingle(dta^);
    btDouble: tbtdouble(dta^) := -tbtdouble(dta^);
    btExtended: tbtextended(dta^) := -tbtextended(dta^);
    btCurrency: tbtcurrency(dta^) := -tbtcurrency(dta^);
    btVariant:
      begin
        Result := True;
        try
          Variant(dta^) := - Variant(dta^);
        except
          CMD_Err(erTypeMismatch);
          Result := False;
        end;
        { left after the handler: Delphi XE3 to XE5 for Win64 keep the exception object of a handler left by a jump }
        exit;
      end;
  else
    begin
      CMD_Err(erTypeMismatch);
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;

function TPSExec.DoBooleanNot(Dta: Pointer; aType: TPSTypeRec): Boolean;
begin
  case aType.BaseType of
    btU8: tbtu8(dta^) := tbtu8(tbtu8(dta^) = 0);
    btU16: tbtu16(dta^) := tbtu16(tbtu16(dta^) = 0);
    btU32: tbtu32(dta^) := tbtu32(tbtu32(dta^) = 0);
    btS8: tbts8(dta^) := tbts8(tbts8(dta^) = 0);
    btS16: tbts16(dta^) := tbts16(tbts16(dta^) = 0);
    btS32: tbts32(dta^) := tbts32(tbts32(dta^) = 0);
    {$IFNDEF PS_NOINT64}
    bts64: tbts64(dta^) := tbts64(tbts64(dta^) = 0);
    btU64: tbtu64(dta^) := tbtu64(tbtu64(dta^) = 0);
    {$ENDIF}
    btVariant:
      begin
        Result := True;
        try
          Variant(dta^) := Variant(dta^) = 0;
        except
          CMD_Err(erTypeMismatch);
          Result := False;
        end;
        { left after the handler: Delphi XE3 to XE5 for Win64 keep the exception object of a handler left by a jump }
        exit;
      end;
  else
    begin
      CMD_Err(erTypeMismatch);
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;


procedure TPSExec.Stop;
begin
  if FStatus = isRunning then
    FStatus := isLoaded
  else if FStatus = isPaused then begin
    FStatus := isLoaded;
    FStack.Clear;
    FTempVars.Clear;
  end;
end;


function TPSExec.ReadLong(var b: Cardinal): Boolean;
begin
  if FCurrentPosition + 3 < FDataLength then begin
    {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
    b := unaligned(Cardinal((@FData^[FCurrentPosition])^));
    {$else}
    b := Cardinal((@FData^[FCurrentPosition])^);
    {$endif}
    Inc(FCurrentPosition, 4);
    Result := True;
  end
  else
    Result := False;
end;

{ Runs aProcNo for native code -- RunProcP and RunProcPVar, a host's call into
  the script -- as the method handlers run a script method: behind a frame of
  its own, so that the routine's exception ends the call there and never
  reaches a try statement of a script that is running.  If a script was
  running when the call began, the exception goes to the native code that made
  the call -- also when the routine stopped that script -- which may handle it
  and go on: the script holds it no longer, and counts it again only if the
  native code lets it come back.  With no script running the executor keeps
  it, for RaiseCurrentException and the host to read. }
procedure _RunProcForNative(aExec: TPSExec; aParams: TPSList; aProcNo: Cardinal);
var
  lFrame     : TPSExceptionHandler;
  lIdx       : Integer;
  lPosition  : Cardinal;
  lStackBase : Cardinal;
  lRaised    : Cardinal;
  lObject    : TObject;
  lRunning   : Boolean;
begin
  lFrame := TPSExceptionHandler.Create;
  lFrame.FinallyOffset := InvalidVal;
  lFrame.ExceptOffset := InvalidVal;
  lFrame.Finally2Offset := InvalidVal;
  lFrame.EndOfBlock := InvalidVal;
  lFrame.CurrProc := nil;
  lFrame.BasePtr := aExec.FCurrStackBase;
  lFrame.StackSize := aExec.FStack.Count;
  lIdx := aExec.FExceptionStack.Add(lFrame);
  { where the interpreter stands while the native code runs the routine }
  lPosition := aExec.FCurrentPosition;
  lStackBase := aExec.FCurrStackBase;
  lRaised := aExec.FRaisedCount;
  lRunning := aExec.FStatus = isRunning;
  aExec.RunProc(aParams, aProcNo);
  if aExec.FExceptionStack[lIdx] = lFrame then
  begin
    aExec.FExceptionStack.Remove(lFrame);
    lFrame.Free;
  end else
  begin
    { the routine's exception ended the call at this frame, below the return
      address: the interpreter is back where the native code called it }
    aExec.FCurrentPosition := lPosition;
    aExec.FCurrStackBase := lStackBase;
  end;
  if (aExec.ExEx <> erNoError) and lRunning then
  begin
    lObject := aExec.ExObject;
    aExec.ExObject := nil;
    if lObject = nil then
      lObject := EPSException.Create(PSErrorToString(aExec.ExceptionCode, aExec.ExceptionString), aExec,
        aExec.ExProc, aExec.ExPos);
    aExec.ExceptionProc(InvalidVal, InvalidVal, erNoError, '', nil);
    aExec.FRaisedCount := lRaised;
    raise lObject;
  end;
end;

function TPSExec.RunProcP(const Params: array of Variant; const Procno: Cardinal): Variant;
var
  ParamList: TPSList;
  ct: PIFTypeRec;
  pvar: PPSVariant;
  res, s: tbtString;
  Proc: TPSInternalProcRec;
  i: Longint;
begin
  if ProcNo >= FProcs.Count then raise Exception.Create(RPS_UnknownProcedure);
  Proc := GetProcNo(ProcNo) as TPSInternalProcRec;
  ParamList := TPSList.Create;
  try
    s := Proc.ExportDecl;
    res := grfw(s);
    i := High(Params);
    while s <> '' do
    begin
      if i < 0 then raise Exception.Create(RPS_NotEnoughParameters);
      ct := FTypes[StrToInt(copy(GRLW(s), 2, MaxInt))];
      if ct = nil then raise Exception.Create(RPS_InvalidParameter);
      pvar := CreateHeapVariant(ct);
      ParamList.Add(pvar);

      if not VariantToPIFVariant(Self, Params[i], pvar) then raise Exception.Create(RPS_InvalidParameter);

      Dec(i);
    end;
    if I > -1 then raise Exception.Create(RPS_TooManyParameters);
    if res <> '-1' then
    begin
      ct := FTypes[StrToInt(res)];
      if ct = nil then raise Exception.Create(RPS_InvalidParameter);
      pvar := CreateHeapVariant(ct);
      ParamList.Add(pvar);
    end else
      pvar := nil;

    _RunProcForNative(Self, ParamList, ProcNo);

    RaiseCurrentException;

    if pvar <> nil then
    begin
      { what no Variant can hold answers no value: Result can arrive holding a
        value of the caller's }
      if not PIFVariantToVariant(PVar, Result) then
        Result := Null;
    end else
      Result := Null;
  finally
    FreePIFVariantList(ParamList);
  end;
end;
function TPSExec.RunProcPVar(var Params: array of Variant; const Procno: Cardinal): Variant;
var
  ParamList: TPSList;
  ct: PIFTypeRec;
  pvar: PPSVariant;
  res, s: tbtString;
  Proc: TPSInternalProcRec;
  i: Longint;
begin
  if ProcNo >= FProcs.Count then raise Exception.Create(RPS_UnknownProcedure);
  Proc := GetProcNo(ProcNo) as TPSInternalProcRec;
  ParamList := TPSList.Create;
  try
    s := Proc.ExportDecl;
    res := grfw(s);
    i := High(Params);
    while s <> '' do
    begin
      if i < 0 then raise Exception.Create(RPS_NotEnoughParameters);
      ct := FTypes[StrToInt(copy(GRLW(s), 2, MaxInt))];
      if ct = nil then raise Exception.Create(RPS_InvalidParameter);
      pvar := CreateHeapVariant(ct);
      ParamList.Add(pvar);

      if not VariantToPIFVariant(Self, Params[i], pvar) then raise Exception.Create(RPS_InvalidParameter);

      Dec(i);
    end;
    if I > -1 then raise Exception.Create(RPS_TooManyParameters);
    if res <> '-1' then
    begin
      ct := FTypes[StrToInt(res)];
      if ct = nil then raise Exception.Create(RPS_InvalidParameter);
      pvar := CreateHeapVariant(ct);
      ParamList.Add(pvar);
    end else
      pvar := nil;

    _RunProcForNative(Self, ParamList, ProcNo);

    RaiseCurrentException;

    for i := 0 to Length(Params) - 1 do
    PIFVariantToVariant(ParamList[i],
                        Params[(Length(Params) - 1) - i]);

    if pvar <> nil then
    begin
      { what no Variant can hold answers no value: Result can arrive holding a
        value of the caller's }
      if not PIFVariantToVariant(PVar, Result) then
        Result := Null;
    end else
      Result := Null;
  finally
    FreePIFVariantList(ParamList);
  end;
end;

function TPSExec.RunProcPN(const Params: array of Variant; const ProcName: tbtString): Variant;
var
  ProcNo: Cardinal;
begin
  ProcNo := GetProc(ProcName);
  if ProcNo = InvalidVal then
    raise Exception.Create(RPS_UnknownProcedure);
  Result := RunProcP(Params, ProcNo);
end;


function TPSExec.RunProc(Params: TPSList; ProcNo: Cardinal): Boolean;
var
  I, I2: Integer;
  vnew, Vd: PIfVariant;
  Cp: TPSInternalProcRec;
  oldStatus: TPSStatus;
  tmp: TObject;
  lBase: Longint;
  lRaised: Cardinal;
  lReported: Boolean;
begin
  lBase := FStack.Count;
{$IFDEF LOG}
  ODS_stack(FStack);
  __Log(string('==== RunProc, paramcnt='+IntToStr(Params.Count)+', procNo='+IntToStr(ProcNo)));
{$ENDIF}
  if FStatus <> isNotLoaded then begin
    if ProcNo >= FProcs.Count then begin
      CMD_Err(erOutOfProcRange);
      Result := False;
      exit;
    end;
    if Params <> nil then
    begin
      for I := 0 to Params.Count - 1 do
      begin
        vd := Params[I];
        if vd = nil then
        begin
          while Longint(FStack.Count) > lBase do
            FStack.Pop;
          Result := False;
          exit;
        end;
        vnew := FStack.PushType(FindType2(btPointer));
        if vd.FType.BaseType = btPointer then
        begin
          PPSVariantPointer(vnew).DestType := PPSVariantPointer(vd).DestType;
          PPSVariantPointer(vnew).DataDest := PPSVariantPointer(vd).DataDest;
        end else begin
          PPSVariantPointer(vnew).DestType := vd.FType;
          PPSVariantPointer(vnew).DataDest := @PPSVariantData(vd).Data;
        end;
      end;
    end;
    I := FStack.Count;
    Cp := FCurrProc;
    oldStatus := FStatus;
    lReported := False;
{$IFDEF LOG}
    ODS_stack(FStack);
{$ENDIF}
    if TPSProcRec(FProcs.Data^[ProcNo]).ClassType <> TPSExternalProcRec then
    begin
      vd := FStack.PushType(FReturnAddressType);
      PPSVariantReturnAddress(vd).Addr.ProcNo := nil;
      PPSVariantReturnAddress(vd).Addr.Position := FCurrentPosition;
      PPSVariantReturnAddress(vd).Addr.StackBase := FCurrStackBase;
      FCurrStackBase := FStack.Count - 1;
      FCurrProc := FProcs.Data^[ProcNo];
      FData := FCurrProc.Data;
      FDataLength := FCurrProc.Length;
      FCurrentPosition := 0;
      FStatus := isPaused;
      lRaised := FRaisedCount;
      Inc(FNestedRuns);
      try
        Result := RunScript;
      finally
        Dec(FNestedRuns);
      end;
      { what the routine raised and handled itself never reached the native
        routine that ran it: that routine's call is judged as if nothing was }
      if ExEx = erNoError then
        FRaisedCount := lRaised;
    end else
    begin
      try
        lRaised := FRaisedCount;
        Result := TPSExternalProcRec(FProcs.Data^[ProcNo]).ProcPtr(Self, TPSExternalProcRec(FProcs.Data^[ProcNo]), FGlobalVars, FStack);
        if not Result then
        begin
          { False with nothing raised: the call failed without saying why }
          if FRaisedCount = lRaised then
            CMD_Err(erCouldNotCallProc);
        end;
        { a routine that reported an error failed, whatever it answered }
        lReported := FRaisedCount <> lRaised;
        if lReported then
          Result := False;
      except
        {$IFDEF DELPHI6UP}
        Tmp := AcquireExceptionObject;
        {$ELSE}
        if RaiseList <> nil then
        begin
          Tmp := Exception(PRaiseFrame(RaiseList)^.ExceptObject);
          PRaiseFrame(RaiseList)^.ExceptObject := nil;
        end else
          Tmp := nil;
        {$ENDIF}
        { the arms below leave RunProc at once: the values pushed for the call
          go first }
        while Longint(FStack.Count) > lBase do
          FStack.Pop;
        if Tmp <> nil then
        begin
          if Tmp is EPSException then
          begin
            Result := False;
            ExceptionProc(EPSException(tmp).ProcNo, EPSException(tmp).ProcPos, erCustomError, tbtString(EPSException(tmp).Message), nil);
            Tmp.Free;
            exit;
          end else
          if Tmp is EDivByZero then
          begin
            Result := False;
            CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
            Exit;
          end;
          if Tmp is EZeroDivide then
          begin
            Result := False;
            CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
            Exit;
          end;
          if Tmp is EMathError then
          begin
            Result := False;
            CMD_Err3(erMathError, tbtString(Exception(Tmp).Message), Tmp);
            Exit;
          end;
        end;
        if (Tmp <> nil) and (Tmp is Exception) then
          CMD_Err3(erException, tbtString(Exception(Tmp).Message), Tmp) else
          CMD_Err3(erException, '', Tmp);
        Result := false;
        exit;
      end;
    end;
    if Cardinal(FStack.Count) > Cardinal(I) then
    begin
      vd := FStack[I];
      if (vd <> nil) and (vd.FType = FReturnAddressType) then
      begin
        for i2 := FStack.Count - 1 downto I + 1 do
          FStack.Pop;
        FCurrentPosition := PPSVariantReturnAddress(vd).Addr.Position;
        FCurrStackBase := PPSVariantReturnAddress(vd).Addr.StackBase;
        FStack.Pop;
      end;
    end;
    { down to where the stack stood: an exception the routine raised has already unwound it to there, and
      popping the parameters again removed the caller's values }
    while Longint(FStack.Count) > lBase do
      FStack.Pop;
    { an imported routine's report moved the run -- to the handler that took
      it, or paused it where no handler was left -- as it does when the script
      calls the routine itself: the status and the routine are the report's }
    if not lReported then
    begin
      { a Stop in a run begun while the script was running stops the script:
        the run it interrupted ends when control comes back to it }
      if (FStatus <> isLoaded) or (oldStatus <> isRunning) then
        FStatus := oldStatus;
      FCurrProc := Cp;
    end;
    if FCurrProc <> nil then
    begin
      FData := FCurrProc.Data;
      FDataLength := FCurrProc.Length;
    end;
  end else begin
    Result := False;
  end;
end;


function TPSExec.FindType2(BaseType: TPSBaseType): PIFTypeRec;
var
  l: Cardinal;
begin
  FindType2 := FindType(0, BaseType, l);

end;

function TPSExec.FindType(StartAt: Cardinal; BaseType: TPSBaseType; var l: Cardinal): PIFTypeRec;
var
  I: Integer;
  n: PIFTypeRec;
begin
  for I := StartAt to FTypes.Count - 1 do begin
    n := FTypes[I];
    if n.BaseType = BaseType then begin
      l := I;
      Result := n;
      exit;
    end;
  end;
  Result := nil;
end;

function TPSExec.GetTypeNo(l: Cardinal): PIFTypeRec;
begin
  Result := FTypes[l];
end;

function TPSExec.GetProc(const Name: tbtString): Cardinal;
var
  MM,
    I: Longint;
  n: PIFProcRec;
  s: tbtString;
  lExternal: Cardinal;
begin
  { a script's routine comes before an external one of its name, which the
    compiler's own code may have added }
  lExternal := InvalidVal;
  s := FastUpperCase(name);
  MM := MakeHash(s);
  for I := FProcs.Count - 1 downto 0 do begin
    n := FProcs.Data^[I];
    if (n.ClassType = TPSInternalProcRec) and (TPSInternalProcRec(n).ExportNameHash = MM) and (TPSInternalProcRec(n).ExportName = s) then begin
      Result := I;
      exit;
    end else if (n.ClassType = TPSExternalProcRec) and (TPSExternalProcRec(n).Name = s) and (lExternal = InvalidVal) then
      lExternal := I;
  end;
  Result := lExternal;
end;

function TPSExec.GetType(const Name: tbtString): Cardinal;
var
  MM,
    I: Longint;
  n: PIFTypeRec;
  s: tbtString;
begin
  s := FastUpperCase(name);
  MM := MakeHash(s);
  for I := 0 to FTypes.Count - 1 do begin
    n := FTypes.Data^[I];
    if (Length(n.ExportName) <> 0) and (n.ExportNameHash = MM) and (n.ExportName = s) then begin
      Result := I;
      exit;
    end;
  end;
  Result := InvalidVal;
end;


procedure TPSExec.AddResource(Proc, P: Pointer);
var
  Temp: PPSResource;
begin
  New(Temp);
  Temp^.Proc := Proc;
  Temp^.P := p;
  FResources.Add(temp);
end;

procedure TPSExec.DeleteResource(P: Pointer);
var
  i: Longint;
begin
  for i := Longint(FResources.Count) -1 downto 0 do
  begin
    if PPSResource(FResources[I])^.P = P then
    begin
      Dispose(PPSResource(FResources[I]));
      FResources.Delete(I);
      exit;
    end;
  end;
end;

function TPSExec.FindProcResource(Proc: Pointer): Pointer;
var
  I: Longint;
  temp: PPSResource;
begin
  for i := Longint(FResources.Count) -1 downto 0 do
  begin
    temp := FResources[I];
    if temp^.Proc = proc then
    begin
      Result := Temp^.P;
      exit;
    end;
  end;
  Result := nil;
end;

function TPSExec.IsValidResource(Proc, P: Pointer): Boolean;
var
  i: Longint;
  temp: PPSResource;
begin
  for i := 0 to Longint(FResources.Count) -1 do
  begin
    temp := FResources[i];
    if (temp^.p = p) and (temp^.Proc = Proc) then begin
      result := True;
      exit;
    end;
  end;
  result := false;
end;

function TPSExec.FindProcResource2(Proc: Pointer;
  var StartAt: Longint): Pointer;
var
  I: Longint;
  temp: PPSResource;
begin
  if StartAt > longint(FResources.Count) -1 then
    StartAt := longint(FResources.Count) -1;
  for i := StartAt downto 0 do
  begin
    temp := FResources[I];
    if temp^.Proc = proc then
    begin
      Result := Temp^.P;
      StartAt := i -1;
      exit;
    end;
  end;
  StartAt := -1;
  Result := nil;
end;

procedure TPSExec.RunLine;
begin
  if @FOnRunLine <> nil then
    FOnRunLine(Self);
end;

procedure TPSExec.CMD_Err3(EC: TPSError; const Param: tbtString; ExObject: TObject);
var
  l: Longint;
  C: Cardinal;
  lOnException: TPSOnException;
begin
  C := InvalidVal;
  for l := FProcs.Count - 1 downto 0 do begin
    if FProcs.Data^[l] = FCurrProc then begin
      C := l;
      break;
    end;
  end;
  { the handler is called from a local: for the field, Delphi 10 Seattle's Win64
    compiler reads Self from a stack slot it never writes }
  lOnException := FOnException;
  if @lOnException <> nil then
    lOnException(Self, Ec, Param, ExObject, C, FCurrentPosition);
  ExceptionProc(C, FCurrentPosition, EC, Param, ExObject);
end;

procedure TPSExec.AddSpecialProcImport(const FName: tbtString;
  P: TPSOnSpecialProcImport; Tag: Pointer);
var
  N: PSpecialProc;
begin
  New(n);
  n^.P := P;
  N^.Name := FName;
  n^.namehash := MakeHash(N^.Name);
  n^.Tag := Tag;
  FSpecialProcList.Add(n);
end;

function TPSExec.GetVar(const Name: tbtString): Cardinal;
var
  l: Longint;
  h: longint;
  s: tbtString;
  p: PPSExportedVar;
begin
  s := FastUpperCase(name);
  h := MakeHash(s);
  for l := FExportedVars.Count - 1 downto 0 do
  begin
    p := FexportedVars.Data^[L];
    if (p^.FNameHash = h) and(p^.FName=s) then
    begin
      Result := L;
      exit;
    end;
  end;
  Result := InvalidVal;
end;

function TPSExec.GetVarNo(C: Cardinal): PIFVariant;
begin
  Result := FGlobalVars[c];
end;

function TPSExec.GetVar2(const Name: tbtString): PIFVariant;
begin
  Result := GetVarNo(GetVar(Name));
end;

function TPSExec.GetProcNo(C: Cardinal): PIFProcRec;
begin
  Result := FProcs[c];
end;

function TPSExec.DoIntegerNot(Dta: Pointer; aType: TPSTypeRec): Boolean;
begin
  case aType.BaseType of
    btU8: tbtu8(dta^) := not tbtu8(dta^);
    btU16: tbtu16(dta^) := not tbtu16(dta^);
    btU32: tbtu32(dta^) := not tbtu32(dta^);
    btS8: tbts8(dta^) := not tbts8(dta^);
    btS16: tbts16(dta^) := not tbts16(dta^);
    btS32: tbts32(dta^) := not tbts32(dta^);
    {$IFNDEF PS_NOINT64}
    bts64: tbts64(dta^) := not tbts64(dta^);
    btU64: tbtu64(dta^) := not tbtu64(dta^);
    {$ENDIF}
    btVariant:
      begin
        Result := True;
        try
          Variant(dta^) := not Variant(dta^);
        except
          CMD_Err(erTypeMismatch);
          Result := False;
        end;
        { left after the handler: Delphi XE3 to XE5 for Win64 keep the exception object of a handler left by a jump }
        exit;
      end;
  else
    begin
      CMD_Err(erTypeMismatch);
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;

type
  TMyRunLine = procedure(Self: TPSExec);
  TPSRunLine = procedure of object;

function GetRunLine(FOnRunLine: TPSOnLineEvent; meth: TPSRunLine): TMyRunLine;
begin
  if (TMethod(Meth).Code = @TPSExec.RunLine) and (@FOnRunLine = nil) then
    Result := nil
  else
    Result := TMethod(Meth).Code;
end;
{$IFDEF LOG}
function NilProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean; forward;

procedure ODSvar(name: string; data: TPSResultData);
begin
  __Log(name + '= $'+IntToHex(IPointer(data.P))+', '+
                                     string(data.aType.ExportName)+', '+
                                    'type='+IntToStr(data.aType.FBaseType)+', '+
                                    'obj = $'+ IntToHex(IPointer(TObject(data.P^))));

end;

procedure ODS_TPSExternalProcRec(name: string; data: TPSExternalProcRec);
var
  s: string;
begin
  s := string(data.Name);
  if s = '' then begin
    if @data.ProcPtr = @NilProc then
      s := 'NilProc';
  end;
  __Log(name + ': name='+s+', '+
                                   'ext1=$'+ IntToHex(IPointer(TObject(data.ext1)))+', '+
                                   'ext2=$'+ IntToHex(IPointer(TObject(data.ext2))));
end;

procedure ODS_TPSInternalProcRec(name: string; data: TPSInternalProcRec);
begin
  __Log(name + ': name='+string(data.ExportName));
end;

procedure ODS_stack(stack: TPSStack);
var
  i: integer;
  k: PPSVariantData;
  t: Pointer;
  s: string;
begin
  __Log('** stack **');
  for i := 0 to stack.Count-1 do begin
    k := PPSVariantData(stack[i]);
    if k = nil then begin
      __Log('['+Inttostr(i)+'] = nil');
    end
    else begin
      t := @PPSVariantData(k).Data;
      s :='['+Inttostr(i)+'] = dta='+IntToHex(IPointer(t));
      t := Pointer(t^);

      s := s+', obj='+IntToHex(IPointer(t));

      if (PPSVariant(stack[i]).FType.BaseType = btPointer) and ( IPointer(t) > $FFFF) then begin
        t := Pointer(t^);
        s := s+ ', obj^='+ IntToHex(IPointer(t));
      end;
      __Log(s);
    end;
  end;
end;
{$ENDIF}

function TPSExec.RunScript: Boolean;
var
  CalcType: Cardinal;
  vd, vs, v3: TPSResultData;
  VdSlf, VdPtr: Pointer;
  vtemp: PIFVariant;
  p: Cardinal;
  P2: Longint;
  u: PIFProcRec;
  Cmd: Cardinal;
  I: Longint;
  pp: TPSExceptionHandler;
  FOldStatus: TPSStatus;
  Tmp: TObject;
  btemp: Boolean;
  CallRunline: TMyRunLine;
  lRaised: Cardinal;
  lFrames: Longint;
  lCalled: Boolean;
begin
{$IFDEF LOG}
  ODS_stack(Fstack);
{$ENDIF}
  if FStatus = isLoaded then
  begin
    for i := FExceptionStack.Count -1 downto 0 do
    begin
      pp := FExceptionStack.Data[i];
      pp.Free;
    end;
    FExceptionStack.Clear;
  end;
  lFrames := FExceptionStack.Count;
  ExceptionProc(InvalidVal, InvalidVal, erNoError, '', nil);
  RunScript := True;
  FOldStatus := FStatus;
  case FStatus of
    isLoaded: begin
        if FMainProc = InvalidVal then
        begin
          RunScript := False;
          exit;
        end;
        FStatus := isRunning;
        FCurrProc := FProcs.Data^[FMainProc];
        if FCurrProc.ClassType = TPSExternalProcRec then begin
          CMD_Err(erNoMainProc);
          FStatus := isLoaded;
          RunScript := False;
          exit;
        end;
        FData := FCurrProc.Data;
        FDataLength := FCurrProc.Length;
        FCurrStackBase := InvalidVal;
        FCurrentPosition := 0;
      end;
    isPaused: begin
        { a run resumed at the top ends as one begun from the start does }
        if FNestedRuns = 0 then
          FOldStatus := isLoaded;
        FStatus := isRunning;
      end;
  else begin
      RunScript := False;
      exit;
    end;
  end;
  CallRunLine := GetRunLine(FOnRunLine, Self.RunLine);
  repeat
    FStatus := isRunning;
//    Cmd := InvalidVal;
    while FStatus = isRunning do
    begin
      if @CallRunLine <> nil then CallRunLine(Self);
      { a line hook that stopped or paused the script: the next instruction
        does not run }
      if FStatus <> isRunning then
        break;
      if FCurrentPosition >= FDataLength then
      begin
        CMD_Err(erOutOfRange); // Error
        break;
      end;
//      if cmd <> invalidval then ProfilerExitProc(Cmd+1);
      cmd := FData^[FCurrentPosition];
//      ProfilerEnterProc(Cmd+1);
      Inc(FCurrentPosition);
        case Cmd of
          CM_A:
              { Script internal command: Assign command<br>
                  Command: TPSCommand;<br>
                  VarDest, // no data<br>
                  VarSrc: TPSVariable;<br>
              }
            begin
              {$IFDEF LOG}
              __Log(#13#10'* CM_A (Assign command)');
              {$ENDIF}
              if not ReadVariable(vd, True) then
                break;
              {$IFDEF LOG}
              ODSvar('  * dest', vd);
              {$ENDIF}
              if vd.FreeType <> vtNone then
              begin
                if vd.aType.BaseType in NeedFinalization then
                  FinalizeVariant(vd.P, vd.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;

                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if not ReadVariable(vs, True) then
                Break;
              {$IFDEF LOG}
              ODSvar('  * src', vs);
              {$ENDIF}
              // nx change start
{              if (vd.aType.BaseType = btClass) and (vs.aType.BaseType in [btS32]) then
                DWord(vd.P^):=Dword(vs.P^)
              else
              if (vd.aType.BaseType in [btS32]) and (vs.aType.BaseType = btClass) then
                DWord(vd.P^):=Dword(vs.P^)
              else}
              // nx change end
              if not SetVariantValue(vd.P, vs.P, vd.aType, vs.aType) then
              begin
                if vs.FreeType <> vtNone then
                begin
                  if vs.aType.BaseType in NeedFinalization then
                  FinalizeVariant(vs.P, vs.aType);
                  p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                  Dec(FTempVars.FCount);
                  {$IFNDEF PS_NOSMARTLIST}
                  Inc(FTempVars.FCheckCount);
                  if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                  {$ENDIF}
                  FTempVars.FLength := P;
                end;
                Break;
              end;
              if vs.FreeType <> vtNone then
              begin
                if vs.aType.BaseType in NeedFinalization then
                FinalizeVariant(vs.P, vs.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;
              end;
              {$IFDEF LOG}
              ODSvar('  = dest', vd);
              {$ENDIF}
            end;
          CM_CA:
            { Script internal command: Calculate Command<br>
                Command: TPSCommand; <br>
                CalcType: Byte;<br>
                <i><br>
                  0 = +<br>
                  1 = -<br>
                  2 = *<br>
                  3 = /<br>
                  4 = MOD<br>
                  5 = SHL<br>
                  6 = SHR<br>
                  7 = AND<br>
                  8 = OR<br>
                  9 = XOR<br>
                  10 = AS<br>
                </i><br>
                VarDest, // no data<br>
                VarSrc: TPSVariable;<br>
            <br>
            }
            begin
              if FCurrentPosition >= FDataLength then
              begin
                CMD_Err(erOutOfRange); // Error
                break;
              end;
              calctype := FData^[FCurrentPosition];
              Inc(FCurrentPosition);
              if not ReadVariable(vd, True) then
                break;
              if vd.FreeType <> vtNone then
              begin
                if vd.aType.BaseType in NeedFinalization then
                FinalizeVariant(vd.P, vd.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if not ReadVariable(vs, True) then
                Break;
              if not DoCalc(vd.P, vs.p, vd.aType, vs.aType, CalcType) then
              begin
                if vs.FreeType <> vtNone then
                begin
                  if vs.aType.BaseType in NeedFinalization then
                  FinalizeVariant(vs.P, vs.aType);
                  p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                  Dec(FTempVars.FCount);
                  {$IFNDEF PS_NOSMARTLIST}
                  Inc(FTempVars.FCheckCount);
                  if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                  {$ENDIF}
                  FTempVars.FLength := P;
                end;
                Break;
              end;
              if vs.FreeType <> vtNone then
              begin
                if vs.aType.BaseType in NeedFinalization then
                FinalizeVariant(vs.P, vs.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;
              end;
            end;
          CM_P:
                { Script internal command: Push<br>
                    Command: TPSCommand; <br>
                    Var: TPSVariable;<br>
                }
            begin
              if not ReadVariable(vs, True) then
                Break;
              vtemp := FStack.PushType(vs.aType);
              vd.P := Pointer(IPointer(vtemp)+PointerSize);
              vd.aType := Pointer(vtemp^);
              vd.FreeType := vtNone;
              if not SetVariantValue(Vd.P, vs.P, vd.aType, vs.aType) then
              begin
                if vs.FreeType <> vtnone then
                begin
                  if vs.aType.BaseType in NeedFinalization then
                    FinalizeVariant(vs.P, vs.aType);
                  p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                  Dec(FTempVars.FCount);
                  {$IFNDEF PS_NOSMARTLIST}
                  Inc(FTempVars.FCheckCount);
                  if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                  {$ENDIF}
                  FTempVars.FLength := P;
                end;
                break;
              end;
              if vs.FreeType <> vtnone then
              begin
                if vs.aType.BaseType in NeedFinalization then
                  FinalizeVariant(vs.P, vs.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;
              end;
            end;
          CM_PV:
              { Script internal command: Push Var<br>
                  Command: TPSCommand; <br>
                  Var: TPSVariable;<br>
              }
            begin
              {$IFDEF LOG}
              __Log(#13#10'* CM_PV (Push Var)');
              {$ENDIF}
              if not ReadVariable(vs, True) then
                Break;
              {$IFDEF LOG}
              ODSvar('  * var', vs);
              {$ENDIF}
              if vs.FreeType <> vtnone then
              begin
                FTempVars.Pop;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              vtemp := FStack.PushType(FindType2(btPointer));
              if vs.aType.BaseType = btPointer then
              begin
                PPSVariantPointer(vtemp).DataDest := Pointer(vs.p^);
                PPSVariantPointer(vtemp).DestType := Pointer(Pointer(IPointer(vs.P)+PointerSize)^);
                PPSVariantPointer(vtemp).FreeIt := False;
              end
              else
              begin
                PPSVariantPointer(vtemp).DataDest := vs.p;
                PPSVariantPointer(vtemp).DestType := vs.aType;
                PPSVariantPointer(vtemp).FreeIt := False;
              end;
            end;
          CM_PO: begin
              { Script internal command: Pop<br>
                  Command: TPSCommand; <br>
              }
              {$IFDEF LOG}
              __Log(#13#10'* CM_PO (Pop)');
              {$ENDIF}
              if FStack.Count = 0 then
              begin
                CMD_Err(erOutOfStackRange);
                break;
              end;
              vtemp := FStack.Data^[FStack.Count -1];
              if (vtemp = nil) or (vtemp.FType.BaseType = btReturnAddress) then
              begin
                CMD_Err(erOutOfStackRange);
                break;
              end;
              FStack.Pop;
(*              Dec(FStack.FCount);
              {$IFNDEF PS_NOSMARTLIST}
              Inc(FStack.FCheckCount);
              if FStack.FCheckCount > FMaxCheckCount then FStack.Recreate;
              {$ENDIF}
              FStack.FLength := Longint(IPointer(vtemp) - IPointer(FStack.DataPtr));
              if TPSTypeRec(vtemp^).BaseType in NeedFinalization then
                FinalizeVariant(Pointer(IPointer(vtemp)+PointerSize), Pointer(vtemp^));
              if ((FStack.FCapacity - FStack.FLength) shr 12) > 2 then FStack.AdjustLength;*)
              {$IFDEF LOG}
              ODS_stack(FStack);
              {$ENDIF}
            end;
          Cm_C: begin
              { Script internal command: Call<br>
                  Command: TPSCommand; <br>
                  ProcNo: Longword;<br>
              }
              {$IFDEF LOG}
              ODS_stack(FStack);
              __Log(#13#10'* CM_C (Call)');
              {$ENDIF}
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
              {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
              {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
              {$endif}
              Inc(FCurrentPosition, 4);
              if p >= FProcs.Count then begin
                CMD_Err(erOutOfProcRange);
                break;
              end;
              u := FProcs.Data^[p];
              if u.ClassType = TPSExternalProcRec then begin
                {$IFDEF LOG}
                ODS_TPSExternalProcRec('proc', TPSExternalProcRec(u));
                {$ENDIF}
                lRaised := FRaisedCount;
                try
                  if not TPSExternalProcRec(u).ProcPtr(Self, TPSExternalProcRec(u), FGlobalVars, FStack) then begin
                    { False with nothing raised: the call failed without saying why }
                    if FRaisedCount = lRaised then
                      CMD_Err(erCouldNotCallProc);
                    Break;
                  end;
                except
                  {$IFDEF DELPHI6UP}
                  Tmp := AcquireExceptionObject;
                  {$ELSE}
                  if RaiseList <> nil then
                  begin
                    Tmp := Exception(PRaiseFrame(RaiseList)^.ExceptObject);
                    PRaiseFrame(RaiseList)^.ExceptObject := nil;
                  end else
                    Tmp := nil;
                  {$ENDIF}
                  if Tmp <> nil then
                  begin
                    if Tmp is EPSException then
                    begin
                      ExceptionProc(EPSException(tmp).ProcNo, EPSException(tmp).ProcPos, erCustomError, tbtString(EPSException(tmp).Message), nil);
                      Tmp.Free;
                      Break;
                    end else
                    if Tmp is EDivByZero then
                    begin
                      CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
                      Break;
                    end;
                    if Tmp is EZeroDivide then
                    begin
                      CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
                      Break;
                    end;
                    if Tmp is EMathError then
                    begin
                      CMD_Err3(erMathError, tbtString(Exception(Tmp).Message), Tmp);
                      Break;
                    end;
                  end;
                  if (Tmp <> nil) and (Tmp is Exception) then
                    CMD_Err3(erException, tbtString(Exception(Tmp).Message), Tmp) else
                    CMD_Err3(erException, '', Tmp);
                  Break;
                end;
                {$IFDEF LOG}
                ODS_stack(FStack);
                {$ENDIF}
              end
              else begin
                {$IFDEF LOG}
                if u.ClassType = TPSInternalProcRec then
                  ODS_TPSInternalProcRec('proc', TPSInternalProcRec(u));
                {$ENDIF}
                Vtemp := Fstack.PushType(FReturnAddressType);
                vd.P := Pointer(IPointer(VTemp)+PointerSize);
                vd.aType := pointer(vtemp^);
                vd.FreeType := vtNone;
                PPSVariantReturnAddress(vtemp).Addr.ProcNo := FCurrProc;
                PPSVariantReturnAddress(vtemp).Addr.Position := FCurrentPosition;
                PPSVariantReturnAddress(vtemp).Addr.StackBase := FCurrStackBase;

                FCurrStackBase := FStack.Count - 1;
                FCurrProc := TPSInternalProcRec(u);
                FData := FCurrProc.Data;
                FDataLength := FCurrProc.Length;
                FCurrentPosition := 0;
              end;
            end;
          CM_PG:
            { Script internal command: Pop and Goto<br>
                Command: TPSCommand; <br>
                NewPosition: Longint; //relative to end of this instruction<br>
            }
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
              { as CM_PO: a value to pop, and not a routine's return address }
              if (FStack.Count = 0)
                or (PIFVariant(FStack.Data^[FStack.Count -1]).FType.BaseType = btReturnAddress) then
              begin
                CMD_Err(erOutOfStackRange);
                break;
              end;
              FStack.Pop;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              FCurrentPosition := FCurrentPosition + p;
            end;
          CM_P2G:
            { Script internal command: Pop*2 and Goto<br>
                Command: TPSCommand; <br>
                NewPosition: Longint; //relative to end of this instruction<br>
            }
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
              { as CM_PO, for each of the two values }
              if (FStack.Count < 2)
                or (PIFVariant(FStack.Data^[FStack.Count -1]).FType.BaseType = btReturnAddress)
                or (PIFVariant(FStack.Data^[FStack.Count -2]).FType.BaseType = btReturnAddress) then
              begin
                CMD_Err(erOutOfStackRange);
                break;
              end;
              FStack.Pop;
              FStack.Pop;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              FCurrentPosition := FCurrentPosition + p;
            end;
          Cm_G:
            { Script internal command: Goto<br>
                Command: TPSCommand; <br>
                NewPosition: Longint; //relative to end of this instruction<br>
            }
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              FCurrentPosition := FCurrentPosition + p;
            end;
          Cm_CG:
            { Script internal command: Conditional Goto<br>
                Command: TPSCommand; <br>
                NewPosition: LongWord; //relative to end of this instruction<br>
                Var: TPSVariable; // no data<br>
            }
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              btemp := true;
              if not ReadVariable(vs, btemp) then
                Break;
              { The compiler writes Cm_CG for the boundary check of a for
                loop (ProcessFor), on a Boolean register, and for the
                short-circuit 'or' in DoBinCalc, on its result: a Boolean
                (btU8) -- two ByteBool, WordBool or LongBool operands are
                combined by their truth into one first -- except that a
                Variant right operand keeps the left one's type, a ByteBool
                (btU8), WordBool (btU16) or LongBool (btU32).  The signed
                arms are for compiled code this compiler did not write. }
              case Vs.aType.BaseType of
                btU8: btemp := tbtu8(vs.p^) <> 0;
                btS8: btemp := tbts8(vs.p^) <> 0;
                btU16: btemp := tbtu16(vs.p^) <> 0;
                btS16: btemp := tbts16(vs.p^) <> 0;
                btU32: btemp := tbtu32(vs.p^) <> 0;
                btS32: btemp := tbts32(vs.p^) <> 0;
              else begin
                  CMD_Err(erInvalidType);
                  if vs.FreeType <> vtNone then
                    FTempVars.Pop;
                  break;
                end;
              end;
              if vs.FreeType <> vtNone then
                FTempVars.Pop;
              if btemp then
                FCurrentPosition := FCurrentPosition + p;
            end;
          Cm_CNG:
            { Script internal command: Conditional NOT Goto<br>
                Command: TPSCommand; <br>
                NewPosition: LongWord; // relative to end of this instruction<br>
                Var: TPSVariable; // no data<br>
            }
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              btemp := true;
              if not ReadVariable(vs, BTemp) then
                Break;
              { As at Cm_CG: the compiler writes Cm_CNG for the
                short-circuit 'and' in DoBinCalc, on the types of the 'or'
                there, and for the conditions of while, repeat, for and
                case statements, each a Boolean (btU8). }
              case Vs.aType.BaseType of
                btU8: btemp := tbtu8(vs.p^) = 0;
                btS8: btemp := tbts8(vs.p^) = 0;
                btU16: btemp := tbtu16(vs.p^) = 0;
                btS16: btemp := tbts16(vs.p^) = 0;
                btU32: btemp := tbtu32(vs.p^) = 0;
                btS32: btemp := tbts32(vs.p^) = 0;
              else begin
                  CMD_Err(erInvalidType);
                  if vs.FreeType <> vtNone then
                    FTempVars.Pop;
                  break;
                end;
              end;
              if vs.FreeType <> vtNone then
                FTempVars.Pop;
              if btemp then
                FCurrentPosition := FCurrentPosition + p;
            end;
          Cm_R: begin
              { Script internal command: Ret<br>
                  Command: TPSCommand; <br>
              }
              {$IFDEF LOG}
              __Log(#13#10'* CM_R (Ret)');
              {$ENDIF}
              P2 := 0;
              if FExceptionStack.Count > 0 then
              begin
                pp := FExceptionStack.Data[FExceptionStack.Count -1];
                while (pp.BasePtr = FCurrStackBase) or ((pp.BasePtr > FCurrStackBase) and (pp.BasePtr <> InvalidVal)) do
                begin
                  { an Exit out of a finally an exception runs ends that exception }
                  if pp.Unwinding then
                    pp.DropException;
                  if pp.StackSize < Cardinal(FStack.Count) then
                  begin
                    for p := Longint(FStack.count) -1 downto Longint(pp.StackSize) do
                      FStack.Pop
                  end;
                  FCurrStackBase := pp.BasePtr;
                  if pp.FinallyOffset <> InvalidVal then
                  begin
                    pp.ExitPoint := FCurrentPosition -1;
                    FCurrentPosition := pp.FinallyOffset;
                    pp.FinallyOffset := InvalidVal;
                    p2 := 1;
                    break;
                  end else if pp.Finally2Offset <> InvalidVal then
                  begin
                    pp.ExitPoint := FCurrentPosition -1;
                    FCurrentPosition := pp.Finally2Offset;
                    pp.Finally2Offset := InvalidVal;
                    pp.ExceptOffset := InvalidVal;
                    pp.DropException;
                    p2 := 1;
                    break;
                  end else
                  begin
                    pp.Free;
                    FExceptionStack.DeleteLast;
                    if FExceptionStack.Count = 0 then break;
                    pp := FExceptionStack.Data[FExceptionStack.Count -1];
                  end;
                end;
              end;
              if p2 = 0 then
              begin
                if FCurrStackBase = InvalidVal then
                begin
                  FStatus := FOldStatus;
                  break;
                end;
                for P2 := FStack.Count - 1 downto FCurrStackBase + 1 do
                  FStack.Pop;
                if FCurrStackBase >= FStack.Count  then
                begin
                  FStatus := FOldStatus;
                  break;
                end;
                vtemp := FStack.Data[FCurrStackBase];
                FCurrProc := PPSVariantReturnAddress(vtemp).Addr.ProcNo;
                FCurrentPosition := PPSVariantReturnAddress(vtemp).Addr.Position;
                FCurrStackBase := PPSVariantReturnAddress(vtemp).Addr.StackBase;
                FStack.Pop;
                if FCurrProc = nil then begin
                  { the end of a run RunProc began: a Stop that the release of the
                    routine's locals above made (a destructor running a script
                    event) stands }
                  if FStatus = isRunning then
                    FStatus := FOldStatus;
                  break;
                end;
                FData := FCurrProc.Data;
                FDataLength := FCurrProc.Length;
              end;
            end;
          Cm_Pt: begin
              { Script internal command: Push Type<br>
                  Command: TPSCommand; <br>
                  FType: LongWord;<br>
              }
              {$IFDEF LOG}
              __Log(#13#10'* Cm_Pt (Push Type)');
              ODS_stack(FStack);
              {$ENDIF}
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              if p >= FTypes.Count then
              begin
                CMD_Err(erInvalidType);
                break;
              end;
              {$IFDEF LOG}
              __Log(' * Type = $'+IntToHex(IPointer(FTypes.Data^[p]))+', '+
                                                 string(TPSTypeRec(FTypes.Data^[p]).ExportName)+', '+
                                                 IntToStr(TPSTypeRec(FTypes.Data^[p]).BaseType));
              {$ENDIF}
              FStack.PushType(FTypes.Data^[p]);
              {$IFDEF LOG}
              ODS_stack(FStack);
              {$ENDIF}
            end;
          cm_bn:
            { Script internal command: Boolean NOT<br>
                Command: TPSCommand; <br>
                Var: TPSVariable;<br>
            }
            begin
              if not ReadVariable(vd, True) then
                Break;
              if vd.FreeType <> vtNone then
                FTempVars.Pop;
              if not DoBooleanNot(Vd.P, vd.aType) then
                break;
            end;
          cm_in:
            { Script internal command: Integer NOT<br>
                Command: TPSCommand; <br>
                Var: TPSVariable;<br>
            }
            begin
              if not ReadVariable(vd, True) then
                Break;
              if vd.FreeType <> vtNone then
                FTempVars.Pop;
              if not DoIntegerNot(Vd.P, vd.aType) then
                break;
            end;
          cm_vm:
            { Script internal command: Var Minus<br>
                Command: TPSCommand; <br>
                Var: TPSVariable;
            }
            begin
              if not ReadVariable(vd, True) then
                Break;
              if vd.FreeType <> vtNone then
                FTempVars.Pop;
              if not DoMinus(Vd.P, vd.aType) then
                break;
            end;
          cm_sf:
            { Script internal command: Set Flag<br>
                Command: TPSCommand; <br>
                Var: TPSVariable;<br>
                DoNot: Boolean;<br>
            }
            begin
              if not ReadVariable(vd, True) then
                Break;
              if FCurrentPosition >= FDataLength then
              begin
                CMD_Err(erOutOfRange); // Error
                if vd.FreeType <> vtNone then
                  FTempVars.Pop;
                break;
              end;
              p := FData^[FCurrentPosition];
              Inc(FCurrentPosition);
              { See Cm_CG comment: only btU8 is reachable here since
                ProcessIf always uses FDefaultBoolType for the
                condition register. }
              case Vd.aType.BaseType of
                btU8: FJumpFlag := tbtu8(Vd.p^) <> 0;
                btS8: FJumpFlag := tbts8(Vd.p^) <> 0;
                btU16: FJumpFlag := tbtu16(Vd.p^) <> 0;
                btS16: FJumpFlag := tbts16(Vd.p^) <> 0;
                btU32: FJumpFlag := tbtu32(Vd.p^) <> 0;
                btS32: FJumpFlag := tbts32(Vd.p^) <> 0;
              else begin
                  CMD_Err(erInvalidType);
                  if vd.FreeType <> vtNone then
                    FTempVars.Pop;
                  break;
                end;
              end;
              if p <> 0 then
                FJumpFlag := not FJumpFlag;
              if vd.FreeType <> vtNone then
                FTempVars.Pop;
            end;
          cm_fg:
            { Script internal command: Flag Goto<br>
                Command: TPSCommand; <br>
                Where: Cardinal;<br>
            }
            begin
              if FCurrentPosition + 3 >= FDataLength then
              begin
                Cmd_Err(erOutOfRange);
                Break;
              end;
	      {$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
              p := unaligned(Cardinal((@FData^[FCurrentPosition])^));
	      {$else}
              p := Cardinal((@FData^[FCurrentPosition])^);
	      {$endif}
              Inc(FCurrentPosition, 4);
              if FJumpFlag then
                FCurrentPosition := FCurrentPosition + p;
            end;
          cm_puexh:
              { Script internal command: Push Exception Handler<br>
                  Command:TPSCommand; <br>
                  FinallyOffset,<br>
                  ExceptionOffset, // FinallyOffset or ExceptionOffset need to be set.<br>
                  Finally2Offset,<br>
                  EndOfBlock: Cardinal;<br>
              }
            begin
              pp := TPSExceptionHandler.Create;
              pp.CurrProc := FCurrProc;
              pp.BasePtr :=FCurrStackBase;
              pp.StackSize := FStack.Count;
              pp.ExitPoint := InvalidVal;
              if not ReadLong(pp.FinallyOffset) then begin
                CMD_Err(erOutOfRange);
                pp.Free;
                Break;
              end;
              if not ReadLong(pp.ExceptOffset) then begin
                CMD_Err(erOutOfRange);
                pp.Free;
                Break;
              end;
              if not ReadLong(pp.Finally2Offset) then begin
                CMD_Err(erOutOfRange);
                pp.Free;
                Break;
              end;
              if not ReadLong(pp.EndOfBlock) then begin
                CMD_Err(erOutOfRange);
                pp.Free;
                Break;
              end;
              if pp.FinallyOffset <> InvalidVal then
                pp.FinallyOffset := pp.FinallyOffset + FCurrentPosition;
              if pp.ExceptOffset <> InvalidVal then
                pp.ExceptOffset := pp.ExceptOffset + FCurrentPosition;
              if pp.Finally2Offset <> InvalidVal then
                pp.Finally2Offset := pp.Finally2Offset + FCurrentPosition;
              if pp.EndOfBlock <> InvalidVal then
                pp.EndOfBlock := pp.EndOfBlock + FCurrentPosition;
              if ((pp.FinallyOffset <> InvalidVal) and (pp.FinallyOffset >= FDataLength)) or
                ((pp.ExceptOffset <> InvalidVal) and (pp.ExceptOffset >= FDataLength)) or
                ((pp.Finally2Offset <> InvalidVal) and (pp.Finally2Offset >= FDataLength)) or
                ((pp.EndOfBlock <> InvalidVal) and (pp.EndOfBlock >= FDataLength)) then
                begin
                  CMD_Err(ErOutOfRange);
                  pp.Free;
                  Break;
                end;
                FExceptionStack.Add(pp);
            end;
          cm_poexh:
            { Script internal command: Pop Exception Handler<br>
                Command:TPSCommand; <br>
                Position: Byte;<br>
                <i> 0 = end of try/finally/exception block;<br>
                  1 = end of first finally<br>
                  2 = end of except<br>
                  3 = end of second finally<br>
                  4 = a jump leaving the frame (Break, Continue)<br>
                </i><br>
            }
            begin
              if FCurrentPosition >= FDataLength then
              begin
                CMD_Err(erOutOfRange); // Error
                break;
              end;
              p := FData^[FCurrentPosition];
              Inc(FCurrentPosition);
              case p of
                2:
                  begin
                    if (FExceptionStack.Count = 0) then
                    begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    pp := FExceptionStack.Data^[FExceptionStack.Count -1];
                    if pp = nil then begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    pp.ExceptOffset := InvalidVal;
                    { the handler is over, and so is its exception }
                    pp.DropException;
                    if pp.Finally2Offset <> InvalidVal then
                    begin
                      FCurrentPosition := pp.Finally2Offset;
                      pp.Finally2Offset := InvalidVal;
                    end else begin
                      if pp.ExitPoint <> InvalidVal then
                        p := pp.ExitPoint
                      else
                        p := pp.EndOfBlock;
                      pp.Free;
                      FExceptionStack.DeleteLast;
                      FCurrentPosition := p;
                    end;
                  end;
                0:
                  begin
                    if (FExceptionStack.Count = 0) then
                    begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    pp := FExceptionStack.Data^[FExceptionStack.Count -1];
                    if pp = nil then begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    if pp.FinallyOffset <> InvalidVal then
                    begin
                      FCurrentPosition := pp.FinallyOffset;
                      pp.FinallyOffset := InvalidVal;
                    end else if pp.Finally2Offset <> InvalidVal then
                    begin
                       FCurrentPosition := pp.Finally2Offset;
                       pp.Finally2Offset := InvalidVal;
                       { the except before it, not entered, is over }
                       pp.ExceptOffset := InvalidVal;
                    end else begin
                      if pp.ExitPoint <> InvalidVal then
                        p := pp.ExitPoint
                      else
                        p := pp.EndOfBlock;
                      pp.Free;
                      FExceptionStack.DeleteLast;
                      if ExEx <> eNoError then
                      begin
                        Tmp := ExObject;
                        ExObject := nil;
                        ExceptionProc(ExProc, ExPos, ExEx, ExParam, Tmp);
                      end else
                        FCurrentPosition := p;
                    end;
                  end;
                1:
                  begin
                    if (FExceptionStack.Count = 0) then
                    begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    pp := FExceptionStack.Data^[FExceptionStack.Count -1];
                    if pp = nil then begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    if pp.Unwinding then
                    begin
                      { the end of a finally an exception ran: the except of the same
                        statement takes it, a second finally runs for it, or it goes on }
                      if (pp.ExceptOffset <> InvalidVal) and (pp.ExceptOffset <> Cardinal(InvalidVal -1)) then
                      begin
                        pp.Unwinding := False;
                        FCurrentPosition := pp.ExceptOffset;
                        pp.ExceptOffset := Cardinal(InvalidVal -1);
                      end else if pp.Finally2Offset <> InvalidVal then
                      begin
                        FCurrentPosition := pp.Finally2Offset;
                        pp.Finally2Offset := InvalidVal;
                      end else
                        ResumeUnwinding;
                    end else
                    if (ExEx <> ENoError) and (pp.ExceptOffset <> InvalidVal) and (pp.ExceptOffset <> InvalidVal -1) then
                    begin
                      FCurrentPosition := pp.ExceptOffset;
                      pp.ExceptOffset := Cardinal(InvalidVal -1);
                      pp.ExceptionData := ExEx;
                      pp.ExceptionObject := ExObject;
                      pp.ExceptionParam := ExParam;
                      ExEx := ErNoError;
                      ExObject := nil;
                    end else if (pp.Finally2Offset <> InvalidVal) then
                    begin
                      FCurrentPosition := pp.Finally2Offset;
                      pp.Finally2Offset := InvalidVal;
                      pp.ExceptOffset := InvalidVal;
                    end else begin
                      if pp.ExitPoint <> InvalidVal then
                        p := pp.ExitPoint
                      else
                        p := pp.EndOfBlock;
                      pp.Free;
                      FExceptionStack.DeleteLast;
                      if (ExEx <> eNoError) and (p <> InvalidVal) then
                      begin
                        Tmp := ExObject;
                        ExObject := nil;
                        ExceptionProc(ExProc, ExPos, ExEx, ExParam, Tmp);
                      end else
                        FCurrentPosition := p;
                    end;
                  end;
                3:
                  begin
                    if (FExceptionStack.Count = 0) then
                    begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    pp := FExceptionStack.Data^[FExceptionStack.Count -1];
                    if pp = nil then begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    if pp.Unwinding then
                      { the end of a second finally an exception ran: it goes on }
                      ResumeUnwinding
                    else
                    begin
                      if pp.ExitPoint <> InvalidVal then
                        p := pp.ExitPoint
                      else
                        p := pp.EndOfBlock;
                      pp.Free;
                      FExceptionStack.DeleteLast;
                      if ExEx <> eNoError then
                      begin
                        Tmp := ExObject;
                        ExObject := nil;
                        ExceptionProc(ExProc, ExPos, ExEx, ExParam, Tmp);
                      end else
                        FCurrentPosition := p;
                    end;
                 end;
                4:
                  { leave the frame for a jump (Break, Continue): run its pending finally, which comes back to
                    the next command, or remove the frame and go on }
                  begin
                    if (FExceptionStack.Count = 0) then
                    begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    pp := FExceptionStack.Data^[FExceptionStack.Count -1];
                    if pp = nil then begin
                      cmd_err(ErOutOfRange);
                      Break;
                    end;
                    { a jump out of a finally an exception runs ends that exception }
                    if pp.Unwinding then
                      pp.DropException;
                    { the values pushed inside the frame's statement go first, as for Exit and an exception:
                      its finally was compiled without them }
                    if pp.StackSize < Cardinal(FStack.Count) then
                      for p := Longint(FStack.Count) -1 downto Longint(pp.StackSize) do
                        FStack.Pop;
                    if pp.FinallyOffset <> InvalidVal then
                    begin
                      pp.ExitPoint := FCurrentPosition;
                      FCurrentPosition := pp.FinallyOffset;
                      pp.FinallyOffset := InvalidVal;
                    end else if pp.Finally2Offset <> InvalidVal then
                    begin
                      pp.ExitPoint := FCurrentPosition;
                      FCurrentPosition := pp.Finally2Offset;
                      pp.Finally2Offset := InvalidVal;
                      pp.ExceptOffset := InvalidVal;
                      pp.DropException;
                    end else
                    begin
                      pp.Free;
                      FExceptionStack.DeleteLast;
                      if ExEx <> eNoError then
                      begin
                        Tmp := ExObject;
                        ExObject := nil;
                        ExceptionProc(ExProc, ExPos, ExEx, ExParam, Tmp);
                      end;
                    end;
                  end;
              end;
            end;
          cm_spc:
            {Script internal command: Set Stack Pointer To Copy<br>
                Command: TPSCommand; <br>
              VarDest, VarSrc: TPSVariable;<br>
            }
            begin
              if not ReadVariable(vd, False) then
                Break;
              if vd.FreeType <> vtNone then
              begin
                FTempVars.Pop;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if (Vd.aType.BaseType <> btPointer) then
              begin
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if not ReadVariable(vs, False) then
                Break;
              if Pointer(Pointer(IPointer(vD.P)+PointerSize2)^) <> nil then
                DestroyHeapVariant2(Pointer(vD.P^), Pointer(Pointer(IPointer(vd.P)+PointerSize)^));
              if vs.aType.BaseType = btPointer then
              begin
                if Pointer(vs.P^) <> nil then
                begin
                  Pointer(vd.P^) := CreateHeapVariant2(Pointer(Pointer(IPointer(vs.P) + PointerSize)^));
                  Pointer(Pointer(IPointer(vd.P) + PointerSize)^) := Pointer(Pointer(IPointer(vs.P) + PointerSize)^);
                  Pointer(Pointer(IPointer(vd.P) + PointerSize2)^) := Pointer(1);
                  if not CopyArrayContents(Pointer(vd.P^), Pointer(vs.P^), 1, Pointer(Pointer(IPointer(vd.P) + PointerSize)^)) then
                  begin
                    if vs.FreeType <> vtNone then
                      FTempVars.Pop;
                    CMD_Err(ErTypeMismatch);
                    break;
                  end;
                end else
                begin
                  Pointer(vd.P^) := nil;
                  Pointer(Pointer(IPointer(vd.P) + PointerSize)^) := nil;
                  Pointer(Pointer(IPointer(vd.P) + PointerSize2)^) := nil;
                end;
              end else begin
                Pointer(vd.P^) := CreateHeapVariant2(vs.aType);
                Pointer(Pointer(IPointer(vd.P) + PointerSize)^) := vs.aType;
                LongBool(Pointer(IPointer(vd.P) + PointerSize2)^) := true;
                if not CopyArrayContents(Pointer(vd.P^), vs.P, 1, vs.aType) then
                begin
                  if vs.FreeType <> vtNone then
                    FTempVars.Pop;
                  CMD_Err(ErTypeMismatch);
                  break;
                end;
              end;
              if vs.FreeType <> vtNone then
                FTempVars.Pop;

            end;
          cm_nop:  {Script internal command: nop<br>
                      Command: TPSCommand; <br>};
          cm_dec:
            {Script internal command: Dec<br>
                Command: TPSCommand; <br>
              Var: TPSVariable;<br>
            }
            begin
              if not ReadVariable(vd, True) then
                Break;
              if vd.FreeType <> vtNone then
              begin
                FTempVars.Pop;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              case vd.aType.BaseType of
                btu8: dec(tbtu8(vd.P^));
                bts8: dec(tbts8(vd.P^));
                btu16: dec(tbtu16(vd.P^));
                bts16: dec(tbts16(vd.P^));
                btu32: dec(tbtu32(vd.P^));
                bts32: dec(tbts32(vd.P^));
{$IFNDEF PS_NOINT64}
                bts64: dec(tbts64(vd.P^));
                btU64: dec(tbtu64(vd.P^));
{$ENDIF}
                btVariant: {$IFDEF FPC}Variant(vd.P^) := Variant(vd.P^) - 1{$ELSE}dec(Variant(vd.P^)){$ENDIF};
              else
                begin
                  CMD_Err(ErTypeMismatch);
                  Break;
                end;
              end;
            end;
          cm_inc:
            {Script internal command: Inc<br>
              Command: TPSCommand; <br>
              Var: TPSVariable;<br>
            }
            begin
              if not ReadVariable(vd, True) then
                Break;
              if vd.FreeType <> vtNone then
              begin
                FTempVars.Pop;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              case vd.aType.BaseType of
                btu8: Inc(tbtu8(vd.P^));
                bts8: Inc(tbts8(vd.P^));
                btu16: Inc(tbtu16(vd.P^));
                bts16: Inc(tbts16(vd.P^));
                btu32: Inc(tbtu32(vd.P^));
                bts32: Inc(tbts32(vd.P^));
{$IFNDEF PS_NOINT64}
                bts64: Inc(tbts64(vd.P^));
                btU64: Inc(tbtu64(vd.P^));
{$ENDIF}
                btVariant: {$IFDEF FPC}Variant(vd.P^) := Variant(vd.P^) + 1{$ELSE}Inc(Variant(vd.P^)){$ENDIF};
              else
                begin
                  CMD_Err(ErTypeMismatch);
                  Break;
                end;
              end;
            end;
          cm_sp:
            { Script internal command: Set Pointer<br>
                Command: TPSCommand; <br>
                VarDest: TPSVariable;<br>
                VarSrc: TPSVariable;<br>
            }
            begin
              if not ReadVariable(vd, False) then
                Break;
              if vd.FreeType <> vtNone then
              begin
                FTempVars.Pop;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if (Vd.aType.BaseType <> btPointer) then
              begin
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if not ReadVariable(vs, False) then
                Break;
              if vs.FreeType <> vtNone then
              begin
                FTempVars.Pop;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if vs.aType.BaseType = btPointer then
              begin
                Pointer(vd.P^) := Pointer(vs.p^);
                Pointer(Pointer(IPointer(vd.P)+PointerSize)^) := Pointer(Pointer(IPointer(vs.P)+PointerSize)^);
              end
              else
              begin
                Pointer(vd.P^) := vs.P;
                Pointer(Pointer(IPointer(vd.P)+PointerSize)^) := vs.aType;
              end;
            end;
          Cm_cv:
            { Script internal command: Call Var<br>
                Command: TPSCommand; <br>
                Var: TPSVariable;<br>
            }
            begin
              if not ReadVariable(vd, True) then
                Break;
              if vd.aType.BaseType <> btProcPtr then
              begin
                if vd.FreeType <> vtNone then
                  FTempVars.Pop;
                CMD_Err(ErTypeMismatch);
                break;
              end;
              p := tbtu32(vd.P^);
              VdSlf := Pointer(Pointer(IPointer(vd.p)+PointerSize)^);
              VdPtr := Pointer(Pointer(IPointer(vd.p)+PointerSize2)^);
              if vd.FreeType <> vtNone then
                FTempVars.Pop; { This makes vd invalid }
              { a native method: routine 0 with the method beside it, called as a
                host's routine is, so that its exception and a refused call are
                the script's error }
              if (p = 0) and (VdPtr <> nil) then
                u := nil
              else begin
                { a nil procedural value: proc 0 with no method -- proc 0 is the
                  script's main block, which no script can name }
                if p = 0 then begin
                  CMD_Err(erNullPointerException);
                  break;
                end;
                if (p >= FProcs.Count) or (p = FMainProc) then begin
                  CMD_Err(erOutOfProcRange);
                  break;
                end;
                u := FProcs.Data^[p];
              end;
              if (u = nil) or (u.ClassType = TPSExternalProcRec) then begin
                lRaised := FRaisedCount;
                try
                  if u = nil then
                    lCalled := InvokeExternalMethod(TPSTypeRec_ProcPtr(vd.aType), VdSlf, VdPtr)
                  else
                    lCalled := TPSExternalProcRec(u).ProcPtr(Self, TPSExternalProcRec(u), FGlobalVars, FStack);
                  if not lCalled then begin
                    { False with nothing raised: the call failed without saying why }
                    if FRaisedCount = lRaised then
                      CMD_Err(erCouldNotCallProc);
                    Break;
                  end;
                except
                  {$IFDEF DELPHI6UP}
                  Tmp := AcquireExceptionObject;
                  {$ELSE}
                  if RaiseList <> nil then
                  begin
                    Tmp := Exception(PRaiseFrame(RaiseList)^.ExceptObject);
                    PRaiseFrame(RaiseList)^.ExceptObject := nil;
                  end else
                    Tmp := nil;
                  {$ENDIF}
                  if Tmp <> nil then
                  begin
                    if Tmp is EPSException then
                    begin
                      ExceptionProc(EPSException(tmp).ProcNo, EPSException(tmp).ProcPos, erCustomError, tbtString(EPSException(tmp).Message), nil);
                      Tmp.Free;
                      break;
                    end else
                    if Tmp is EDivByZero then
                    begin
                      CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
                      break;
                    end;
                    if Tmp is EZeroDivide then
                    begin
                      CMD_Err3(erDivideByZero, tbtString(Exception(Tmp).Message), Tmp);
                      break;
                    end;
                    if Tmp is EMathError then
                    begin
                      CMD_Err3(erMathError, tbtString(Exception(Tmp).Message), Tmp);
                      break;
                    end;
                  end;
                  if (Tmp <> nil) and (Tmp is Exception) then
                    CMD_Err3(erException, tbtString(Exception(Tmp).Message), Tmp) else
                    CMD_Err3(erException, '', Tmp);
                  Break;
                end;
              end
              else begin
                vtemp := FStack.PushType(FReturnAddressType);
                PPSVariantReturnAddress(vtemp).Addr.ProcNo := FCurrProc;
                PPSVariantReturnAddress(vtemp).Addr.Position := FCurrentPosition;
                PPSVariantReturnAddress(vtemp).Addr.StackBase := FCurrStackBase;
                FCurrStackBase := FStack.Count - 1;
                FCurrProc := TPSInternalProcRec(u);
                FData := FCurrProc.Data;
                FDataLength := FCurrProc.Length;
                FCurrentPosition := 0;
              end;
            end;
          CM_CO:
            { Script internal command: Compare<br>
                Command: TPSCommand; <br>
                CompareType: Byte;<br>
                <i><br>
                 0 = &gt;=<br>
                 1 = &lt;=<br>
                 2 = &gt;<br>
                 3 = &lt;<br>
                 4 = &lt;&gt<br>
                 5 = =<br>
                 6 = IN<br>
                 7 = IS<br>
                <i><br>
                IntoVar: TPSAssignment;<br>
                Compare1, Compare2: TPSAssigment;<br>
            }
            begin
              if FCurrentPosition >= FDataLength then
              begin
                CMD_Err(erOutOfRange); // Error
                break;
              end;
              calctype := FData^[FCurrentPosition];
              Inc(FCurrentPosition);
              if not ReadVariable(v3, True) then
                Break;
              if v3.FreeType <> vtNone then
              begin
                if v3.aType.BaseType in NeedFinalization then
                  FinalizeVariant(v3.P, v3.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;
                CMD_Err(erInvalidOpcodeParameter);
                break;
              end;
              if not ReadVariable(vs, True) then
                Break;
              if not ReadVariable(vd, True) then
              begin
                if vs.FreeType <> vtNone then
                begin
                  if vs.aType.BaseType in NeedFinalization then
                    FinalizeVariant(vs.P, vs.aType);
                  p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                  Dec(FTempVars.FCount);
                  {$IFNDEF PS_NOSMARTLIST}
                  Inc(FTempVars.FCheckCount);
                  if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                  {$ENDIF}
                  FTempVars.FLength := P;
                end;
                Break;
              end;
              DoBooleanCalc(Vs.P, Vd.P, v3.P, vs.aType, vd.aType, v3.aType, CalcType);
              if vd.FreeType <> vtNone then
              begin
                if vd.aType.BaseType in NeedFinalization then
                  FinalizeVariant(vd.P, vd.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;
              end;
              if vs.FreeType <> vtNone then
              begin
                if vs.aType.BaseType in NeedFinalization then
                  FinalizeVariant(vs.P, vs.aType);
                p := IPointer(FTempVars.Data^[FtempVars.Count-1]) - IPointer(FtempVars.DataPtr);
                Dec(FTempVars.FCount);
                {$IFNDEF PS_NOSMARTLIST}
                Inc(FTempVars.FCheckCount);
                if FTempVars.FCheckCount > FMaxCheckCount then FTempVars.Recreate;
                {$ENDIF}
                FTempVars.FLength := P;
              end;
            end;

        else
          CMD_Err(erInvalidOpcode); // Error
        end;
    end;
//    if cmd <> invalidval then ProfilerExitProc(Cmd+1);
//    if ExEx <> erNoError then FStatus := FOldStatus;
  until (FExceptionStack.Count = 0) or (Fstatus <> IsRunning);
  { a Stop skips the code that retires the frames of the try statements it
    leaves: they go with this run, before another run can meet them }
  if FStatus = isLoaded then
    while Longint(FExceptionStack.Count) > lFrames do
    begin
      pp := FExceptionStack.Data[FExceptionStack.Count - 1];
      FExceptionStack.DeleteLast;
      { the exception a finally of the run was running for, which the run
        did not handle, ends the run with it }
      if pp.Unwinding and (ExEx = erNoError) then
      begin
        ExProc := pp.ExceptionProcNo;
        ExPos := pp.ExceptionPos;
        ExEx := pp.ExceptionData;
        ExParam := pp.ExceptionParam;
        if ExObject <> nil then
          ExObject.Free;
        ExObject := pp.ExceptionObject;
        pp.ExceptionObject := nil;
      end;
      pp.Free;
    end;
  { a run RunProc began leaves the stack below it to whatever began it -- a
    running script, a host, or a release while the stack is being popped or
    cleared: RunProc pops this run's own values }
  if (FStatus = isLoaded) and (FNestedRuns = 0) then begin
    for I := Longint(FStack.Count) - 1 downto 0 do
      FStack.Pop;
    FStack.Clear;
    if FCallCleanup then Cleanup;
  end;
  Result := ExEx = erNoError;
end;

function NVarProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  tmp: TPSVariantIFC;
begin
   case Longint(p.Ext1) of
    0:
      begin
        if @Caller.FOnSetNVariant = nil then begin Result := False; exit; end;
        tmp := NewTPSVariantIFC(Stack.Items[Stack.Count - 2], True);
        if (Tmp.Dta = nil) or (tmp.aType.BaseType <> btVariant) then begin Result := False; exit; end;
        Caller.FOnSetNVariant(Caller, Stack.GetAnsiString(-1), Variant(tmp.Dta^));
        Result := true;
      end;
    1:
      begin
        if @Caller.FOnGetNVariant = nil then begin Result := False; exit; end;
        tmp := NewTPSVariantIFC(Stack.Items[Stack.Count - 1], False);
        if (Tmp.Dta = nil) or (tmp.aType.BaseType <> btVariant) then begin Result := False; exit; end;
        Variant(tmp.Dta^) := Caller.FOnGetNVariant(Caller, Stack.GetAnsiString(-2));
        Result := true;
      end;
  else
    Result := False;
  end;
end;

function DefProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  temp: TPSVariantIFC;
  I: Longint;
  b: Boolean;
  S: string;
  pex: TPSExceptionHandler;
  Tmp: TObject;
  lStrIdx: {$IFNDEF PS_NOINT64}Int64{$ELSE}Longint{$ENDIF};
{$IFNDEF PS_NOWIDESTRING}

  { WStrSet's character: a WideChar or Char, or the first character of a string, which is how a character
    argument of its AnyString parameter arrives }
  function WStrSetChar: WideChar;
  var
    lText: tbtunicodestring;
  begin
    if Stack.GetItem(Stack.Count - 1)^.FType.BaseType in [btString, btWideString, btUnicodeString] then
    begin
      lText := Stack.GetUnicodeString(-1);
      if lText = '' then
        raise Exception.Create(RPS_TypeMismatch);
      Result := lText[1];
    end else
      Result := WideChar(Stack.GetInt(-1));
  end;
{$ENDIF}

begin
  { The following needs to be in synch in these 3 functions:
    -UPSCompiler.TPSPascalCompiler.DefineStandardProcedures
    -UPSRuntime.DefProc
    -UPSRuntime.TPSExec.RegisterStandardProcs
  }
  case Longint(p.Ext1) of
    0: Stack.SetAnsiString(-1, tbtstring(SysUtils.IntToStr(Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-2)))); // inttostr
    1: Stack.SetInt(-1, StrToInt(Stack.GetAnsiString(-2))); // strtoint
    2: Stack.SetInt(-1, StrToIntDef(Stack.GetAnsiString(-2), Stack.GetInt(-3))); // strtointdef
    3:
{$IFNDEF PS_NOWIDESTRING}
      { a wide string on either side makes the search wide, as in Delphi: by the substring's type alone, a Char
        or AnsiString substring read a wide S through the ANSI code page }
      if (Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString) or
        (Stack.GetItem(Stack.Count -3)^.FType.BaseType = btUnicodeString) then
        Stack.SetInt(-1, Pos(Stack.GetUnicodeString(-2), Stack.GetUnicodeString(-3)))// pos
      else
      if (Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString) or
        (Stack.GetItem(Stack.Count -3)^.FType.BaseType = btWideString) then
        Stack.SetInt(-1, Pos(Stack.GetWideString(-2), Stack.GetWideString(-3)))// pos
      else{$ENDIF}
        Stack.SetInt(-1, Pos(Stack.GetAnsiString(-2), Stack.GetAnsiString(-3)));// pos
    4:
{$IFNDEF PS_NOWIDESTRING}      if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString then
        Stack.SetWideString(-1, Copy(Stack.GetWideString(-2), Stack.GetInt(-3), Stack.GetInt(-4))) // copy
      else
      if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString then
        Stack.SetUnicodeString(-1, Copy(Stack.GetUnicodeString(-2), Stack.GetInt(-3), Stack.GetInt(-4))) // copy
      else{$ENDIF}
        Stack.SetAnsiString(-1, Copy(Stack.GetAnsiString(-2), Stack.GetInt(-3), Stack.GetInt(-4))); // copy
    5: //delete
      begin
        temp := NewTPSVariantIFC(Stack[Stack.Count -1], True);
{$IFNDEF PS_NOWIDESTRING}
        if (temp.Dta <> nil) and (temp.aType.BaseType = btUnicodeString) then
        begin
          Delete(tbtUnicodeString(temp.Dta^), Stack.GetInt(-2), Stack.GetInt(-3));
        end else
        if (temp.Dta <> nil) and (temp.aType.BaseType = btWideString) then
        begin
          Delete(tbtwidestring(temp.Dta^), Stack.GetInt(-2), Stack.GetInt(-3));
        end else {$ENDIF} begin
          if (temp.Dta = nil) or (temp.aType.BaseType <> btString) then
          begin
            Result := False;
            exit;
          end;
          Delete(tbtstring(temp.Dta^), Stack.GetInt(-2), Stack.GetInt(-3));
        end;
      end;
    6: // insert
      begin
        temp := NewTPSVariantIFC(Stack[Stack.Count -2], True);
{$IFNDEF PS_NOWIDESTRING}
        if (temp.Dta <> nil) and (temp.aType.BaseType = btUnicodeString) then begin
          Insert(Stack.GetUnicodeString(-1), tbtUnicodeString(temp.Dta^), Stack.GetInt(-3));
        end else if (temp.Dta <> nil) and (temp.aType.BaseType = btWideString) then begin
          Insert(Stack.GetWideString(-1), tbtwidestring(temp.Dta^), Stack.GetInt(-3));
        end else {$ENDIF} begin
          if (temp.Dta = nil) or (temp.aType.BaseType <> btString) then
          begin
            Result := False;
            exit;
          end;
          Insert(Stack.GetAnsiString(-1), tbtstring(temp.Dta^), Stack.GetInt(-3));
        end;
      end;
    7: // StrGet
      begin
        temp :=  NewTPSVariantIFC(Stack[Stack.Count -2], True);
        if temp.Dta = nil then begin
          Result := False;
          exit;
        end;
        case temp.aType.BaseType of
          btString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-3);
              if (lStrIdx<1) or (lStrIdx>length(tbtstring(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              Stack.SetInt(-1,Ord(tbtstring(temp.Dta^)[i]));
            end;
          btUnicodeString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-3);
              if (lStrIdx<1) or (lStrIdx>length(tbtUnicodeString(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              Stack.SetInt(-1,Ord(tbtUnicodeString(temp.Dta^)[i]));
            end;

        else
          begin
            Result := False;
            exit;
          end;
        end;
      end;
    8: // StrSet
      begin
        temp := NewTPSVariantIFC(Stack[Stack.Count -3], True);
        if (temp.Dta = nil) then
        begin
          Result := False;
          exit;
        end;
        case temp.aType.BaseType of
          btString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-2);
              if (lStrIdx<1) or (lStrIdx>length(tbtstring(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              tbtstring(temp.Dta^)[i] := tbtchar(Stack.GetInt(-1));
            end;
          btUnicodeString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-2);
              if (lStrIdx<1) or (lStrIdx>length(tbtUnicodeString(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              tbtUnicodeString(temp.Dta^)[i] := WideChar(Stack.GetInt(-1));
            end;

        else
          begin
            Result := False;
            exit;
          end;
        end;
      end;
    10:
{$IFNDEF PS_NOWIDESTRING}
{$IFDEF DELPHI2009UP}
      if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString then
        Stack.SetUnicodeString(-1, UpperCase(Stack.GetUnicodeString(-2))) // Uppercase
      else
{$ENDIF}
      if (Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString) or
        (Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString) then
        Stack.SetWideString(-1, WideUpperCase(Stack.GetWideString(-2))) // Uppercase
      else
{$ENDIF}
        Stack.SetAnsiString(-1, FastUppercase(Stack.GetAnsiString(-2))); // Uppercase
    11:
{$IFNDEF PS_NOWIDESTRING}
{$IFDEF DELPHI2009UP}
      if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString then
        Stack.SetUnicodeString(-1, LowerCase(Stack.GetUnicodeString(-2))) // Uppercase
      else
{$ENDIF}
      if (Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString) or
        (Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString) then
        Stack.SetWideString(-1, WideLowerCase(Stack.GetWideString(-2))) // Uppercase
      else
{$ENDIF}
        Stack.SetAnsiString(-1, FastLowercase(Stack.GetAnsiString(-2)));// LowerCase
    12:
{$IFNDEF PS_NOWIDESTRING}
      if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString then
        Stack.SetUnicodeString(-1, SysUtils.Trim(Stack.GetUnicodestring(-2))) // Trim
      else if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString then
        Stack.SetWideString(-1, SysUtils.Trim(Stack.GetWideString(-2))) // Trim
      else
{$ENDIF}
        Stack.SetAnsiString(-1, AnsiString(SysUtils.Trim(String(Stack.GetAnsiString(-2)))));// Trim
    13: Stack.SetInt(-1, Length(Stack.GetAnsiString(-2))); // Length
    14: // SetLength
      begin
        temp := NewTPSVariantIFC(Stack[Stack.Count -1], True);
        if (temp.Dta = nil) or (temp.aType.BaseType <> btString) then
        begin
          Result := False;
          exit;
        end;
        SetLength(tbtstring(temp.Dta^), STack.GetInt(-2));
      end;
    15: Stack.SetReal(-1, Sin(Stack.GetReal(-2))); // Sin
    16: Stack.SetReal(-1, Cos(Stack.GetReal(-2)));  // Cos
    17: Stack.SetReal(-1, SQRT(Stack.GetReal(-2))); // Sqrt
    {$IFNDEF PS_NOINT64}
    { the whole Int64, which the compiler now declares; a script compiled with the LongInt declaration gets
      the low half, as before }
    18: Stack.SetInt64(-1, Round(Stack.GetReal(-2))); // Round
    19: Stack.SetInt64(-1, Trunc(Stack.GetReal(-2))); // Trunc
    {$ELSE}
    18: Stack.SetInt(-1, Round(Stack.GetReal(-2))); // Round
    19: Stack.SetInt(-1, Trunc(Stack.GetReal(-2))); // Trunc
    {$ENDIF}
    20: Stack.SetReal(-1, Int(Stack.GetReal(-2))); // Int
    21: Stack.SetReal(-1, Pi); // Pi
    22: Stack.SetReal(-1, Abs(Stack.GetReal(-2))); // Abs
    23: Stack.SetReal(-1, StrToFloat(Stack.GetAnsiString(-2))); // StrToFloat
    24: Stack.SetAnsiString(-1, FloatToStr(Stack.GetReal(-2)));// FloatToStr
    25:
{$IFNDEF PS_NOWIDESTRING}
    if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString then
      Stack.SetUnicodeString(-1, upadL(Stack.GetUnicodeString(-2), Stack.GetInt(-3))) //  PadL
    else
    if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString then
      Stack.SetWideString(-1, wPadL(Stack.GetWideString(-2), Stack.GetInt(-3))) //  PadL
    else{$ENDIF}
      Stack.SetAnsiString(-1, PadL(Stack.GetAnsiString(-2), Stack.GetInt(-3))); //  PadL
    26:
{$IFNDEF PS_NOWIDESTRING}
    if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString then
      Stack.SetUnicodeString(-1, uPadR(Stack.GetUnicodeString(-2), Stack.GetInt(-3))) // PadR
    else
    if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString then
      Stack.SetWideString(-1, wPadR(Stack.GetWideString(-2), Stack.GetInt(-3))) // PadR
    else{$ENDIF}
      Stack.SetAnsiString(-1, PadR(Stack.GetAnsiString(-2), Stack.GetInt(-3))); // PadR
    27:
{$IFNDEF PS_NOWIDESTRING}
    if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btUnicodeString then
      Stack.SetUnicodeString(-1, uPadZ(Stack.GetUnicodeString(-2), Stack.GetInt(-3)))// PadZ
    else
    if Stack.GetItem(Stack.Count -2)^.FType.BaseType = btWideString then
      Stack.SetWideString(-1, wPadZ(Stack.GetWideString(-2), Stack.GetInt(-3)))// PadZ
    else{$ENDIF}
      Stack.SetAnsiString(-1, PadZ(Stack.GetAnsiString(-2), Stack.GetInt(-3)));// PadZ
    28: // Replicate/StringOfChar
      begin
        S := Stack.GetString(-2);
        if S <> '' then
{$IF Defined(FPC_FULLVERSION) and (FPC_FULLVERSION < 30204)}
        begin
          { Free Pascal before 3.2.4 declares StringOfChar for an AnsiChar alone, which would narrow a
            wide character through the code page: the string is built from the character here }
          I := Stack.GetInt(-3);
          S := Copy(S, 1, 1);
          while (I > 0) and (Length(S) < I) do
            S := S + S;
          Stack.SetString(-1, Copy(S, 1, I));
        end
{$ELSE}
          Stack.SetString(-1, StringOfChar(S[1], Stack.GetInt(-3)))
{$IFEND}
        else
          Stack.SetString(-1, StringOfChar(#0, Stack.GetInt(-3)));
      end;
    29: // Assigned
      begin
        temp := NewTPSVariantIFC(Stack[Stack.Count -2], True);
        if Temp.dta = nil then
        begin
          Result := False;
          exit;
        end;
        case temp.aType.BaseType of
          btU8, btS8: b := tbtu8(temp.dta^) <> 0;
          btU16, btS16: b := tbtu16(temp.dta^) <> 0;
          btU32, btS32: b := tbtu32(temp.dta^) <> 0;
          btString, btPChar: b := tbtstring(temp.dta^) <> '';
{$IFNDEF PS_NOWIDESTRING}
          btWideString: b := tbtwidestring(temp.dta^)<> '';
          btUnicodeString: b := tbtUnicodeString(temp.dta^)<> '';
{$ENDIF}
          btArray, btClass{$IFNDEF PS_NOINTERFACES}, btInterface{$ENDIF}: b := Pointer(temp.dta^) <> nil;
          { a script routine has a routine number, a Delphi method a code address }
          btProcPtr: b := (tbtu32(temp.dta^) <> 0) or (Pointer(Pointer(IPointer(temp.dta)+PointerSize2)^) <> nil);
        else
          Result := False;
          Exit;
        end;
        if b then
          Stack.SetInt(-1, 1)
        else
          Stack.SetInt(-1, 0);
      end;
    30:
      begin {RaiseLastException}
        { the exception of the nearest except handler running, raised again
          where it was raised first }
        pex := _HandlerFrame(Caller.FExceptionStack);
        if pex <> nil then begin
          Tmp := pex.ExceptionObject;
          pex.ExceptionObject := nil;
          Caller.ExceptionProc(pex.ExceptionProcNo, pex.ExceptionPos, pex.ExceptionData, pex.ExceptionParam, tmp);
        end;
      end;
    31: Caller.CMD_Err2(TPSError(Stack.GetInt(-1)), Stack.GetAnsiString(-2)); {RaiseExeption}
    32: Stack.SetInt(-1, Ord(Caller.LastEx)); {ExceptionType}
    33: Stack.SetAnsiString(-1, Caller.LastExParam); {ExceptionParam}
    34: Stack.SetInt(-1, Caller.LastExProc); {ExceptionProc}
    35: Stack.SetInt(-1, Caller.LastExPos); {ExceptionPos}
    36: Stack.SetAnsiString(-1, PSErrorToString(TPSError(Stack.GetInt(-2)), Stack.GetAnsiString(-3))); {ExceptionToString}
    37: Stack.SetAnsiString(-1, tbtString(AnsiUpperCase(string(Stack.GetAnsiString(-2))))); // AnsiUppercase
    38: Stack.SetAnsiString(-1, tbtString(AnsiLowercase(string(Stack.GetAnsiString(-2))))); // AnsiLowerCase
{$IFNDEF PS_NOINT64}
    39: Stack.SetInt64(-1, StrToInt64(string(Stack.GetAnsiString(-2))));  // StrToInt64
    40: Stack.SetAnsiString(-1, tbtstring(SysUtils.IntToStr(Stack.GetInt64(-2))));// Int64ToStr
    41: Stack.SetInt64(-1, StrToInt64Def(string(Stack.GetAnsiString(-2)), Stack.GetInt64(-3))); // StrToInt64Def
    45: Stack.SetUInt64(-1, StrToUInt64(string(Stack.GetAnsiString(-2))));  // StrToUInt64
    46: Stack.SetAnsiString(-1, tbtstring(UIntToStr(Stack.GetUInt64(-2))));// UInt64ToStr
    47: Stack.SetUInt64(-1, StrToUInt64Def(string(Stack.GetAnsiString(-2)), Stack.GetUInt64(-3))); // StrToUInt64Def
{$ENDIF}
    48: Stack.SetAnsiString(-1, tbtstring(UIntToStr({$IFNDEF PS_NOINT64}Stack.GetUInt64(-2){$ELSE}Stack.GetUInt(-2){$ENDIF}))); // UIntToStr
    42:  // sizeof
      begin
        temp := NewTPSVariantIFC(Stack[Stack.Count -2], False);
        if Temp.aType = nil then
          Stack.SetInt(-1, 0)
        else
          Stack.SetInt(-1, Temp.aType.RealSize)
      end;
{$IFNDEF PS_NOWIDESTRING}
    43: // WStrGet
      begin
        temp :=  NewTPSVariantIFC(Stack[Stack.Count -2], True);
        if temp.dta = nil then begin
          result := false;
          exit;
        end;
        case temp.aType.BaseType of
          btWideString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-3);
              if (lStrIdx<1) or (lStrIdx>length(tbtwidestring(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              Stack.SetInt(-1,Ord(tbtwidestring(temp.Dta^)[i]));
            end;
          btUnicodeString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-3);
              if (lStrIdx<1) or (lStrIdx>length(tbtUnicodeString(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              Stack.SetInt(-1,Ord(tbtUnicodeString(temp.Dta^)[i]));
            end;

        else
          begin
            Result := False;
            exit;
          end;
        end;
      end;
    44: // WStrSet
      begin
        temp := NewTPSVariantIFC(Stack[Stack.Count -3], True);
        if (temp.Dta = nil)  then
        begin
          Result := False;
          exit;
        end;
        case temp.aType.BaseType of
          btWideString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-2);
              if (lStrIdx<1) or (lStrIdx>length(tbtWidestring(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              tbtWidestring(temp.Dta^)[i] := WStrSetChar;
            end;

          btUnicodeString:
            begin
              { the whole index: narrowed to 32 bits first, 4294967297 selected the first character }
              lStrIdx := Stack.{$IFNDEF PS_NOINT64}GetInt64{$ELSE}GetInt{$ENDIF}(-2);
              if (lStrIdx<1) or (lStrIdx>length(tbtunicodestring(temp.Dta^))) then
              begin
                Caller.CMD_Err2(erCustomError, tbtString(RPS_OutOfStringRange));
                Result := True;
                exit;
              end;
              I := lStrIdx;
              tbtunicodestring(temp.Dta^)[i] := WStrSetChar;
            end;
        else
          begin
            Result := False;
            exit;
          end;
        end;
      end;
{$ENDIF}
    //45-48: see above
    else
    begin
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;
function GetArrayLength(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  Arr := NewTPSVariantIFC(Stack[Stack.Count-2], True);
  if (arr.aType.BaseType <> btStaticArray) and ((arr.Dta = nil) or (arr.aType.BaseType <> btArray)) then
  begin
    Result := false;
    exit;
  end;
  if arr.aType.BaseType = btStaticArray then
    Stack.SetInt(-1, TPSTypeRec_StaticArray(arr.aType).Size)
  else
    Stack.SetInt(-1, PSDynArrayGetLength(Pointer(arr.Dta^), arr.aType));
  Result := True;
end;

function SetArrayLength(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  Arr := NewTPSVariantIFC(Stack[Stack.Count-1], True);
  if (arr.Dta = nil) or (arr.aType.BaseType <> btArray) then
  begin
    Result := false;
    exit;
  end;
  PSDynArraySetLength(Pointer(arr.Dta^), arr.aType, Stack.GetInt(-2));
  Result := True;
end;


function InterfaceProc(Sender: TPSExec; p: TPSExternalProcRec; Tag: Pointer): Boolean; forward;

procedure RegisterInterfaceLibraryRuntime(Se: TPSExec);
begin
  SE.AddSpecialProcImport('intf', InterfaceProc, nil);
end;

{$IFNDEF DELPHI6UP}
function Null: Variant;
begin
  Result := System.Null;
end;

function Unassigned: Variant;
begin
  Result := System.Unassigned;
end;
{$ENDIF}
function Length_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  arr:=NewTPSVariantIFC(Stack[Stack.Count-2],false);
  case arr.aType.BaseType of
    btArray:
      begin
        Stack.SetInt(-1,PSDynArrayGetLength(Pointer(arr.Dta^),arr.aType));
        Result:=true;
      end;
    btStaticArray:
      begin
        Stack.SetInt(-1,TPSTypeRec_StaticArray(arr.aType).Size);
        Result:=true;
      end;
    btString:
      begin
        Stack.SetInt(-1,length(tbtstring(arr.Dta^)));
        Result:=true;
      end;
    btChar:
      begin
        Stack.SetInt(-1, 1);
        Result:=true;
      end;
    {$IFNDEF PS_NOWIDESTRING}
    btWideString:
      begin
        Stack.SetInt(-1,length(tbtWidestring(arr.Dta^)));
        Result:=true;
      end;
    btUnicodeString:
      begin
        Stack.SetInt(-1,length(tbtUnicodeString(arr.Dta^)));
        Result:=true;
      end;
    {$ENDIF}
    btvariant:
      begin
        Stack.SetInt(-1,length(Variant(arr.Dta^)));
        Result:=true;
      end;
  else
    begin
      Caller.CMD_Err(ErTypeMismatch);
      result := true;
    end;
  end;
end;


function SetLength_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  Result:=false;
  arr:=NewTPSVariantIFC(Stack[Stack.Count-1],true);
  if arr.aType.BaseType=btArray then
  begin
    { a negative length is an error for an array, as in Delphi (a string takes it as 0) }
    if Stack.GetInt(-2) < 0 then
      raise Exception.Create(RPS_OutOfRange);
    PSDynArraySetLength(Pointer(arr.Dta^),arr.aType,Stack.GetInt(-2));
    Result:=true;
  end else
  if arr.aType.BaseType=btString then
  begin
    SetLength(tbtstring(arr.Dta^),STack.GetInt(-2));
    Result:=true;
{$IFNDEF PS_NOWIDESTRING}
  end else
  if arr.aType.BaseType=btWideString then
  begin
    SetLength(tbtwidestring(arr.Dta^),STack.GetInt(-2));
    Result:=true;
  end else
  if arr.aType.BaseType=btUnicodeString then
  begin
    SetLength(tbtUnicodeString(arr.Dta^),STack.GetInt(-2));
    Result:=true;
{$ENDIF}
  end;
end;

function Low_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  Result:=true;
  arr:=NewTPSVariantIFC(Stack[Stack.Count-2],false);
  case arr.aType.BaseType of
    btArray      : Stack.SetInt(-1,0);
    btStaticArray: Stack.SetInt(-1,TPSTypeRec_StaticArray(arr.aType).StartOffset);
    btString     : Stack.SetInt(-1,1);
{$IFNDEF PS_NOWIDESTRING}
    btWideString,
    btUnicodeString: Stack.SetInt(-1,1);
{$ENDIF}
    btChar,
    btU8         : Stack.SetInt(-1,Low(Byte));        //Byte: 0
    btS8         : Stack.SetInt(-1,Low(ShortInt));    //ShortInt: -128
{$IFNDEF PS_NOWIDESTRING}
    btWideChar,
{$ENDIF}
    btU16        : Stack.SetInt(-1,Low(Word));        //Word: 0
    btS16        : Stack.SetInt(-1,Low(SmallInt));    //SmallInt: -32768
    btU32        : Stack.SetInt(-1,Low(Cardinal));    //Cardinal/LongWord: 0
    btS32        : Stack.SetInt(-1,Low(Integer));     //Integer/LongInt: -2147483648
{$IFNDEF PS_NOINT64}
    btS64        : Stack.SetInt64(-1,Low(Int64));     //Int64: -9223372036854775808
    btU64        : Stack.SetUInt64(-1,Low(UInt64));   //UInt64: 0
{$ENDIF}
    else Result:=false;
  end;
end;

function High_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  Result:=true;
  arr:=NewTPSVariantIFC(Stack[Stack.Count-2],false);
  case arr.aType.BaseType of
    btArray      : Stack.SetInt(-1,PSDynArrayGetLength(Pointer(arr.Dta^),arr.aType)-1);
    btStaticArray: Stack.SetInt(-1,TPSTypeRec_StaticArray(arr.aType).StartOffset+TPSTypeRec_StaticArray(arr.aType).Size-1);
    btString     : Stack.SetInt(-1,Length(tbtstring(arr.Dta^)));
{$IFNDEF PS_NOWIDESTRING}
    btWideString : Stack.SetInt(-1,Length(tbtWidestring(arr.Dta^)));
    btUnicodeString: Stack.SetInt(-1,Length(tbtUnicodeString(arr.Dta^)));
{$ENDIF}
    btChar,
    btU8         : Stack.SetInt(-1,High(Byte));       //Byte: 255
    btS8         : Stack.SetInt(-1,High(ShortInt));   //ShortInt: 127
{$IFNDEF PS_NOWIDESTRING}
    btWideChar,
{$ENDIF}
    btU16        : Stack.SetInt(-1,High(Word));       //Word: 65535
    btS16        : Stack.SetInt(-1,High(SmallInt));   //SmallInt: 32767
    btU32        : Stack.SetUInt(-1,High(Cardinal));  //Cardinal/LongWord: 4294967295
    btS32        : Stack.SetInt(-1,High(Integer));    //Integer/LongInt: 2147483647
{$IFNDEF PS_NOINT64}
    btS64        : Stack.SetInt64(-1,High(Int64));    //Int64: 9223372036854775807
    btU64        : Stack.SetUInt64(-1,High(UInt64));  //UInt64: 18446744073709551615
{$ENDIF}
    else Result:=false;
  end;
end;

function Dec_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  Result:=true;
  arr:=NewTPSVariantIFC(Stack[Stack.Count-1],true);
  case arr.aType.BaseType of
    btU8         : Stack.SetInt(-1,Tbtu8(arr.dta^)-1);     //Byte
    btS8         : Stack.SetInt(-1,Tbts8(arr.dta^)-1);     //ShortInt
    btU16        : Stack.SetInt(-1,Tbtu16(arr.dta^)-1);    //Word
    btS16        : Stack.SetInt(-1,Tbts16(arr.dta^)-1);    //SmallInt
    btU32        : Stack.SetInt(-1,Tbtu32(arr.dta^)-1);    //Cardinal/LongWord
    btS32        : Stack.SetInt(-1,Tbts32(arr.dta^)-1);    //Integer/LongInt
{$IFNDEF PS_NOINT64}
    btS64        : Stack.SetInt64(-1,Tbts64(arr.dta^)-1);
    btU64        : Stack.SetUInt64(-1,Tbtu64(arr.dta^)-1);
{$ENDIF}
    else Result:=false;
  end;
end;

function Inc_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  arr: TPSVariantIFC;
begin
  Result:=true;
  arr:=NewTPSVariantIFC(Stack[Stack.Count-1],true);
  case arr.aType.BaseType of
    btU8         : Stack.SetInt(-1,Tbtu8(arr.dta^)+1);     //Byte
    btS8         : Stack.SetInt(-1,Tbts8(arr.dta^)+1);     //ShortInt
    btU16        : Stack.SetInt(-1,Tbtu16(arr.dta^)+1);    //Word
    btS16        : Stack.SetInt(-1,Tbts16(arr.dta^)+1);    //SmallInt
    btU32        : Stack.SetInt(-1,Tbtu32(arr.dta^)+1);    //Cardinal/LongWord
    btS32        : Stack.SetInt(-1,Tbts32(arr.dta^)+1);    //Integer/LongInt
{$IFNDEF PS_NOINT64}
    btS64        : Stack.SetInt64(-1,Tbts64(arr.dta^)+1);
    btU64        : Stack.SetUInt64(-1,Tbtu64(arr.dta^)+1);
{$ENDIF}
    else Result:=false;
  end;
end;

function Include_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  TheSet, NewMember: TPSVariantIFC;
  SetData: PByteArray;
  Val: Tbtu8;
begin
  TheSet:=NewTPSVariantIFC(Stack[Stack.Count-1],true);
  NewMember:=NewTPSVariantIFC(Stack[Stack.Count-2],false);
  { a Char is one byte, as the set's members are -- of a set of 256 members, a set of Char: a Char into an
    enumeration's set is refused, as before }
  Result := (TheSet.aType.BaseType = btSet) and
    ((NewMember.aType.BaseType = btU8) or
    ((NewMember.aType.BaseType = btChar) and (TPSTypeRec_Set(TheSet.aType).aBitSize = 256)));
  if not Result then Exit;
  SetData := TheSet.Dta;
  Val := Tbtu8(NewMember.dta^);
  { a member past the set's size would change the memory after the set }
  if Val >= TPSTypeRec_Set(TheSet.aType).aBitSize then
    raise Exception.Create(RPS_OutOfRange);
  SetData^[Val shr 3] := SetData^[Val shr 3] or (1 shl (Val and 7));
end;

function Exclude_(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  TheSet, NewMember: TPSVariantIFC;
  SetData: PByteArray;
  Val: Tbtu8;
begin
  TheSet:=NewTPSVariantIFC(Stack[Stack.Count-1],true);
  NewMember:=NewTPSVariantIFC(Stack[Stack.Count-2],false);
  { a Char is one byte, as the set's members are -- of a set of 256 members, a set of Char: a Char into an
    enumeration's set is refused, as before }
  Result := (TheSet.aType.BaseType = btSet) and
    ((NewMember.aType.BaseType = btU8) or
    ((NewMember.aType.BaseType = btChar) and (TPSTypeRec_Set(TheSet.aType).aBitSize = 256)));
  if not Result then Exit;
  SetData := TheSet.Dta;
  Val := Tbtu8(NewMember.dta^);
  { a member past the set's size would change the memory after the set }
  if Val >= TPSTypeRec_Set(TheSet.aType).aBitSize then
    raise Exception.Create(RPS_OutOfRange);
  SetData^[Val shr 3] := SetData^[Val shr 3] and not (1 shl (Val and 7));
end;


{$IFDEF DELPHI6UP}
function _VarArrayGet(var S : Variant; I : Integer) : Variant;
begin
  result := VarArrayGet(S, [I]);
end;

procedure _VarArraySet(const c : Variant; I : Integer; var s : Variant);
begin
  VarArrayPut(s, c, [i]);
end;
{$ENDIF}

procedure TPSExec.RegisterStandardProcs;
begin
  { The following needs to be in synch in these 3 functions:
    -UPSCompiler.TPSPascalCompiler.DefineStandardProcedures
    -UPSRuntime.DefProc
    -UPSRuntime.TPSExec.RegisterStandardProcs
  }
  RegisterFunctionName('!NOTIFICATIONVARIANTSET', NVarProc, Pointer(0), nil);
  RegisterFunctionName('!NOTIFICATIONVARIANTGET', NVarProc, Pointer(1), nil);

  RegisterFunctionName('IntToStr', DefProc, Pointer(0), nil);
  RegisterFunctionName('UIntToStr', DefProc, Pointer(48), nil);
  RegisterFunctionName('StrToInt', DefProc, Pointer(1), nil);
  RegisterFunctionName('StrToIntDef', DefProc, Pointer(2), nil);
  RegisterFunctionName('Pos', DefProc, Pointer(3), nil);
  RegisterFunctionName('Copy', DefProc, Pointer(4), nil);
  RegisterFunctionName('Delete', DefProc, Pointer(5), nil);
  RegisterFunctionName('Insert', DefProc, Pointer(6), nil);

  RegisterFunctionName('StrGet', DefProc, Pointer(7), nil);
  RegisterFunctionName('StrGet2', DefProc, Pointer(7), nil);
  RegisterFunctionName('StrSet', DefProc, Pointer(8), nil);
  RegisterFunctionName('UpperCase', DefProc, Pointer(10), nil);
  RegisterFunctionName('LowerCase', DefProc, Pointer(11), nil);
  RegisterFunctionName('Trim', DefProc, Pointer(12), nil);

  RegisterFunctionName('Length',Length_,nil,nil);
  RegisterFunctionName('SetLength',SetLength_,nil,nil);
  RegisterFunctionName('Low',Low_,nil,nil);
  RegisterFunctionName('High',High_,nil,nil);
  RegisterFunctionName('Dec',Dec_,nil,nil);
  RegisterFunctionName('Inc',Inc_,nil,nil);
  RegisterFunctionName('Include',Include_,nil,nil);
  RegisterFunctionName('Exclude',Exclude_,nil,nil);

  RegisterFunctionName('Sin', DefProc, Pointer(15), nil);
  RegisterFunctionName('Cos', DefProc, Pointer(16), nil);
  RegisterFunctionName('Sqrt', DefProc, Pointer(17), nil);
  RegisterFunctionName('Round', DefProc, Pointer(18), nil);
  RegisterFunctionName('Trunc', DefProc, Pointer(19), nil);
  RegisterFunctionName('Int', DefProc, Pointer(20), nil);
  RegisterFunctionName('Pi', DefProc, Pointer(21), nil);
  RegisterFunctionName('Abs', DefProc, Pointer(22), nil);
  RegisterFunctionName('StrToFloat', DefProc, Pointer(23), nil);
  RegisterFunctionName('FloatToStr', DefProc, Pointer(24), nil);
  RegisterFunctionName('PadL', DefProc, Pointer(25), nil);
  RegisterFunctionName('PadR', DefProc, Pointer(26), nil);
  RegisterFunctionName('PadZ', DefProc, Pointer(27), nil);
  RegisterFunctionName('Replicate', DefProc, Pointer(28), nil);
  RegisterFunctionName('StringOfChar', DefProc, Pointer(28), nil);
  RegisterFunctionName('!ASSIGNED', DefProc, Pointer(29), nil);

  RegisterDelphiFunction(@Unassigned, 'Unassigned', cdRegister);
  RegisterDelphiFunction(@VarIsEmpty, 'VarIsEmpty', cdRegister);
  {$IFDEF DELPHI7UP}
  RegisterDelphiFunction(@VarIsClear, 'VarIsClear', cdRegister);
  {$ENDIF}
  RegisterDelphiFunction(@Null, 'Null', cdRegister);
  RegisterDelphiFunction(@VarIsNull, 'VarIsNull', cdRegister);
  RegisterDelphiFunction(@{$IFDEF FPC}variants.{$ENDIF}VarType, 'VarType', cdRegister);
  {$IFNDEF PS_NOIDISPATCH}
  RegisterDelphiFunction(@IDispatchInvoke, 'IdispatchInvoke', cdregister);
  {$ENDIF}


  RegisterFunctionName('GetArrayLength', GetArrayLength, nil, nil);
  RegisterFunctionName('SetArrayLength', SetArrayLength, nil, nil);

  RegisterFunctionName('RaiseLastException', DefPRoc, Pointer(30), nil);
  RegisterFunctionName('RaiseException', DefPRoc, Pointer(31), nil);
  RegisterFunctionName('ExceptionType', DefPRoc, Pointer(32), nil);
  RegisterFunctionName('ExceptionParam', DefPRoc, Pointer(33), nil);
  RegisterFunctionName('ExceptionProc', DefPRoc, Pointer(34), nil);
  RegisterFunctionName('ExceptionPos', DefPRoc, Pointer(35), nil);
  RegisterFunctionName('ExceptionToString', DefProc, Pointer(36), nil);
  RegisterFunctionName('AnsiUpperCase', DefProc, Pointer(37), nil);
  RegisterFunctionName('AnsiLowerCase', DefProc, Pointer(38), nil);

  {$IFNDEF PS_NOINT64}
  RegisterFunctionName('StrToInt64', DefProc, Pointer(39), nil);
  RegisterFunctionName('Int64ToStr', DefProc, Pointer(40), nil);
  RegisterFunctionName('StrToInt64Def', DefProc, Pointer(41), nil);
  RegisterFunctionName('StrToUInt64', DefProc, Pointer(45), nil);
  RegisterFunctionName('UInt64ToStr', DefProc, Pointer(46), nil);
  RegisterFunctionName('StrToUInt64Def', DefProc, Pointer(47), nil);
  {$ENDIF}
  RegisterFunctionName('SizeOf', DefProc, Pointer(42), nil);

  {$IFNDEF PS_NOWIDESTRING}
  RegisterFunctionName('WStrGet', DefProc, Pointer(43), nil);
  RegisterFunctionName('WStrSet', DefProc, Pointer(44), nil);

  {$ENDIF}
  {$IFDEF DELPHI6UP}
  RegisterDelphiFunction(@_VarArrayGet, 'VarArrayGet', cdRegister);
  RegisterDelphiFunction(@_VarArraySet, 'VarArraySet', cdRegister);
  {$ENDIF}
  RegisterInterfaceLibraryRuntime(Self);
end;


function ToString(p: PansiChar): tbtString;
begin
  SetString(Result, p,
  {$IF NOT DEFINED (NEXTGEN) AND NOT DEFINED (MACOS) AND DEFINED (DELPHI_TOKYO_UP)}AnsiStrings.StrLen(p){$ELSE}Length(p){$IFEND});
end;

function IntPIFVariantToVariant(Src: pointer; aType: TPSTypeRec; var Dest: Variant): Boolean;
  function BuildArray(P: Pointer; aType: TPSTypeRec; Len: Longint): Boolean;
  var
    i, elsize: Longint;
    v: variant;
  begin
    elsize := aType.RealSize;
    Dest := VarArrayCreate([0, Len-1], varVariant);
    for i := 0 to Len -1 do
    begin
      if not IntPIFVariantToVariant(p, aType, v) then
      begin
        result := false;
        exit;
      end;
      Dest[i] := v;
      p := Pointer(IPointer(p) + Cardinal(elSize));
    end;
    result := true;
  end;
begin
  if aType = nil then
  begin
    Dest := null;
    Result := True;
    exit;
  end;
  if aType.BaseType = btPointer then
  begin
    aType := TPSTypeRec(Pointer(IPointer(src)+PointerSize)^);
    Src := Pointer(Pointer(Src)^);
    if (aType = nil) or (Src = nil) then
    begin
      Dest := null;
      Result := True;
      exit;
    end;
  end;

  case aType.BaseType of
    btVariant: Dest := variant(src^);
    btArray: if not BuildArray(Pointer(Src^), TPSTypeRec_Array(aType).ArrayType, PSDynArrayGetLength(Pointer(src^), aType)) then begin result := false; exit; end;
    btStaticArray: if not BuildArray(Pointer(Src), TPSTypeRec_StaticArray(aType).ArrayType, TPSTypeRec_StaticArray(aType).Size) then begin result := false; exit; end;
    btU8:
      if aType.ExportName = 'BOOLEAN' then
        Dest := boolean(tbtu8(Src^) <> 0)
      else
        Dest := tbtu8(Src^);
    btS8: Dest := tbts8(Src^);
    btU16: Dest := tbtu16(Src^);
    btS16: Dest := tbts16(Src^);
    btU32: Dest := {$IFDEF DELPHI6UP}tbtu32{$ELSE}tbts32{$ENDIF}(Src^);
    btS32: Dest := tbts32(Src^);
    btSingle: Dest := tbtsingle(Src^);
    btCurrency: Dest:=tbtCurrency(Src^);
    btDouble:
      begin
        if aType.ExportName = 'TDATETIME' then
          Dest := TDateTime(tbtDouble(Src^))
        else
          Dest := tbtDouble(Src^);
      end;
    btExtended: Dest := tbtExtended(Src^);
    btString: Dest := tbtString(Src^);
    btPChar: Dest := ToString(PansiChar(Src^));
  {$IFNDEF PS_NOINT64}
  {$IFDEF DELPHI6UP}
    btS64: Dest := tbts64(Src^);
    btU64: Dest := tbtu64(Src^);
  {$ELSE}
    btS64, btU64: begin Result := False; exit; end;
  {$ENDIF}
  {$ENDIF}
    btChar: Dest := tbtString(tbtchar(src^));
  {$IFNDEF PS_NOWIDESTRING}
    btWideString: Dest := tbtWideString(src^);
    btWideChar: Dest := tbtwidestring(tbtwidechar(src^));
    btUnicodeString: Dest := tbtUnicodeString(src^);
  {$ENDIF}
  else
    begin
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;

function PIFVariantToVariant(Src: PIFVariant; var Dest: Variant): Boolean;
begin
  Result := IntPIFVariantToVariant(@PPSVariantData(src).Data, Src.FType, Dest);
end;

function VariantToPIFVariant(Exec: TPSExec; const Src: Variant; Dest: PIFVariant): Boolean;
var
  TT: PIFTypeRec;
begin
  if Dest = nil then begin Result := false; exit; end;
  tt := Exec.FindType2(btVariant);
  if tt = nil then begin Result := false; exit; end;
  if Dest.FType.BaseType = btPointer then
    Result := Exec.SetVariantValue(PPSVariantPointer(Dest).DataDest, @Src, PPSVariantPointer(Dest).DestType, tt)
  else
    Result := Exec.SetVariantValue(@PPSVariantData(Dest).Data, @Src, Dest.FType, tt);
end;

type
  POpenArray = ^TOpenArray;
  TOpenArray = record
    AType: Byte; {0} { Must be first field, matching x64.inc's TMethodCallData }
    OrgVar: PPSVariantIFC;
    FreeIt: Boolean;
    ElementSize,
    ItemCount: Longint;
    Data: Pointer;
    VarParam: Boolean;
    { the script array's elements: an argument naming the same array shares
      the earlier one's Data }
    Source: Pointer;
  end;

{ An open array argument of a native call.  An array of const goes as a buffer
  of TVarRec made from the script's elements, written back by DestroyOpenArray
  for a var argument.  An argument naming the same script array as an earlier
  one of the call (in aCallData) shares that one's buffer, as two arguments of
  one array share its elements in Delphi -- a const one sees what a var one
  writes, a value one the routine copies on entry -- and a var one makes the
  shared buffer written back, once }
function CreateOpenArray(VarParam: Boolean; Sender: TPSExec; val: PPSVariantIFC; aCallData: TPSList): POpenArray;
var
  datap, p: Pointer;
  ctype: TPSTypeRec;
  cp: Pointer;
  i: Longint;
  lIdx: Longint;
  lEarlier: POpenArray;
begin
  if (Val.aType.BaseType <> btArray) and (val.aType.BaseType <> btStaticArray) then
  begin
    Result := nil;
    exit;
  end;
  New(Result);
  Result.AType := 0;
  Result.OrgVar := Val;
  Result.VarParam := VarParam;

  if val.aType.BaseType = btStaticArray then
  begin
    Result^.ItemCount := TPSTypeRec_StaticArray(val.aType).Size;
    datap := Val.Dta;
  end else
  begin
    Result^.ItemCount := PSDynArrayGetLength(Pointer(Val.Dta^), val.aType);
    datap := Pointer(Val.Dta^);
  end;
  Result.Source := datap;
  if TPSTypeRec_Array(Val.aType).ArrayType.BaseType <> btPointer then
  begin
    Result.FreeIt := False;
    result.ElementSize := 0;
    Result.Data := datap;
    exit;
  end;

  { BaseType is btPointer, which means array of const }

  if aCallData <> nil then
    for lIdx := 0 to aCallData.Count - 1 do
    begin
      lEarlier := aCallData[lIdx];
      if (lEarlier^.AType = 0) and (lEarlier^.Source = datap) then
      begin
        Result.FreeIt := False;
        Result.Data := lEarlier^.Data;
        if VarParam then
          lEarlier^.VarParam := True;
        exit;
      end;
    end;

  Result.FreeIt := True;
  Result.ElementSize := sizeof(TVarRec);
  GetMem(Result.Data, Result.ItemCount * Result.ElementSize);
  P := Result.Data;
  FillChar(p^, Result^.ItemCount * Result^.ElementSize, 0);
  for i := 0 to Result^.ItemCount -1 do
  begin
    ctype := Pointer(Pointer(IPointer(datap)+PointerSize)^);
    cp := Pointer(Datap^);
    if cp = nil then
    begin
      tvarrec(p^).VType := vtPointer;
      tvarrec(p^).VPointer := nil;
    end else begin
       case ctype.BaseType of
        btVariant: begin
          tvarrec(p^).VType := vtVariant;
          tvarrec(p^).VVariant := cp;
        end;
        btchar: begin
            tvarrec(p^).VType := vtChar;
            tvarrec(p^).VChar := tbtChar(tbtchar(cp^));
          end;
        btSingle:
          begin
            tvarrec(p^).VType := vtExtended;
            New(tvarrec(p^).VExtended);
            tvarrec(p^).VExtended^ := tbtsingle(cp^);
          end;
        btExtended:
          begin
            tvarrec(p^).VType := vtExtended;
            New(tvarrec(p^).VExtended);
            tvarrec(p^).VExtended^ := tbtextended(cp^);;
          end;
        btDouble:
          begin
            tvarrec(p^).VType := vtExtended;
            New(tvarrec(p^).VExtended);
            tvarrec(p^).VExtended^ := tbtdouble(cp^);
          end;
        btCurrency:
          begin
            tvarrec(p^).VType := vtCurrency;
            New(tvarrec(p^).VCurrency);
            tvarrec(p^).VCurrency^ := tbtcurrency(cp^);
          end;
        {$IFNDEF PS_NOWIDESTRING}
        btwidechar: begin
            tvarrec(p^).VType := vtWideChar;
            tvarrec(p^).VWideChar := tbtwidechar(cp^);
          end;
        {$IFNDEF WIDESTRING_EQUAL_UNICODESTRING}
        btUnicodeString: begin
          tvarrec(p^).VType := vtUnicodeString;
          tbtunicodestring(TVarRec(p^).VUnicodeString) := tbtunicodestring(cp^);
        end;
        {$ELSE}
        btUnicodeString,
        {$ENDIF}
        btwideString: begin
          tvarrec(p^).VType := vtWideString;
          tbtwidestring(TVarRec(p^).VWideString) := tbtwidestring(cp^);
        end;
        {$ENDIF}
        btU8: begin
            tvarrec(p^).VType := vtInteger;
            tvarrec(p^).VInteger := tbtu8(cp^);
          end;
        btS8: begin
            tvarrec(p^).VType := vtInteger;
            tvarrec(p^).VInteger := tbts8(cp^);
          end;
        btU16: begin
            tvarrec(p^).VType := vtInteger;
            tvarrec(p^).VInteger := tbtu16(cp^);
          end;
        btS16: begin
            tvarrec(p^).VType := vtInteger;
            tvarrec(p^).VInteger := tbts16(cp^);
          end;
        btU32: begin
            tvarrec(p^).VType := vtInteger;
            tvarrec(p^).VInteger := tbtu32(cp^);
          end;
        btS32: begin
            tvarrec(p^).VType := vtInteger;
            tvarrec(p^).VInteger := tbts32(cp^);
          end;
        {$IFNDEF PS_NOINT64}
        btS64: begin
            tvarrec(p^).VType := vtInt64;
            New(tvarrec(p^).VInt64);
            tvarrec(p^).VInt64^ := tbts64(cp^);
          end;
        btU64: begin
            tvarrec(p^).VType := vtInt64;
            New(tvarrec(p^).VInt64);
            tvarrec(p^).VInt64^ := tbtu64(cp^);
          end;
        {$ENDIF}
        btString: begin
          tvarrec(p^).VType := vtAnsiString;
          tbtString(TVarRec(p^).VAnsiString) := tbtstring(cp^);
        end;
        btPChar:
        begin
          tvarrec(p^).VType := vtPchar;
          TVarRec(p^).VPChar := pointer(cp^);
        end;
        btClass:
        begin
          tvarrec(p^).VType := vtObject;
          tvarrec(p^).VObject := Pointer(cp^);
        end;
{$IFNDEF PS_NOINTERFACES}
{$IFDEF Delphi3UP}
        btInterface:
        begin
          tvarrec(p^).VType := vtInterface;
          IUnknown(tvarrec(p^).VInterface) := IUnknown(cp^);
        end;

{$ENDIF}
{$ENDIF}
      end;
    end;
    datap := Pointer(IPointer(datap)+ (3*sizeof(Pointer)));
    p := PansiChar(p) + Result^.ElementSize;
  end;
end;

procedure DestroyOpenArray(Sender: TPSExec; V: POpenArray);
var
  cp, datap: pointer;
  ctype: TPSTypeRec;
  p: PVarRec;
  i: Longint;
begin
  if v.FreeIt then // basetype = btPointer
  begin
    p := v^.Data;
    if v.OrgVar.aType.BaseType = btStaticArray then
      datap := v.OrgVar.Dta
    else
      datap := Pointer(v.OrgVar.Dta^);
    for i := 0 to v^.ItemCount -1 do
    begin
      ctype := Pointer(Pointer(IPointer(datap)+PointerSize)^);
      cp := Pointer(Datap^);
      { an element without data went as a nil pointer (CreateOpenArray): nothing to free or write back }
      if cp <> nil then
      case ctype.BaseType of
        btU8:
          begin
            if v^.varParam then
              tbtu8(cp^) := tvarrec(p^).VInteger
          end;
        btS8: begin
            if v^.varParam then
              tbts8(cp^) := tvarrec(p^).VInteger
          end;
        btU16: begin
            if v^.varParam then
              tbtu16(cp^) := tvarrec(p^).VInteger
          end;
        btS16: begin
            if v^.varParam then
              tbts16(cp^) := tvarrec(p^).VInteger
          end;
        btU32: begin
            if v^.varParam then
              tbtu32(cp^) := tvarrec(p^).VInteger
          end;
        btS32: begin
            if v^.varParam then
              tbts32(cp^) := tvarrec(p^).VInteger
          end;
        btChar: begin
            if v^.VarParam then
              tbtchar(cp^) := tbtChar(tvarrec(p^).VChar)
          end;
        btSingle: begin
          if v^.VarParam then
            tbtsingle(cp^) := tvarrec(p^).vextended^;
          dispose(tvarrec(p^).vextended);
        end;
        btDouble: begin
          if v^.VarParam then
            tbtdouble(cp^) := tvarrec(p^).vextended^;
          dispose(tvarrec(p^).vextended);
        end;
        btExtended: begin
          if v^.VarParam then
            tbtextended(cp^) := tvarrec(p^).vextended^;
          dispose(tvarrec(p^).vextended);
        end;
        btCurrency: begin
          if v^.VarParam then
            tbtcurrency(cp^) := tvarrec(p^).VCurrency^;
          dispose(tvarrec(p^).VCurrency);
        end;
        {$IFNDEF PS_NOINT64}
        btS64: begin
            if v^.VarParam then
              tbts64(cp^) := tvarrec(p^).vInt64^;
            dispose(tvarrec(p^).VInt64);
          end;
        btU64: begin
            if v^.VarParam then
              tbtu64(cp^) := tvarrec(p^).vInt64^;
            dispose(tvarrec(p^).VInt64);
          end;
        {$ENDIF}
        {$IFNDEF PS_NOWIDESTRING}
        btWideChar: begin
            if v^.varParam then
              tbtwidechar(cp^) := tvarrec(p^).VWideChar;
          end;
        {$IFNDEF WIDESTRING_EQUAL_UNICODESTRING}
        btUnicodeString:
          begin
          if v^.VarParam then
            tbtunicodestring(cp^) := tbtunicodestring(TVarRec(p^).VUnicodeString);
          finalize(tbtunicodestring(TVarRec(p^).VUnicodeString));
          end;
        {$ELSE}
        btUnicodeString,
        {$ENDIF}
        btWideString:
          begin
          if v^.VarParam then
            tbtwidestring(cp^) := tbtwidestring(TVarRec(p^).VWideString);
          finalize(widestring(TVarRec(p^).VWideString));
          end;
        {$ENDIF}
        btString: begin
          if v^.VarParam then
            tbtstring(cp^) := tbtstring(TVarRec(p^).VString);
          finalize(tbtString(TVarRec(p^).VAnsiString));
        end;
        btPChar: begin
          if v^.VarParam then
            Pointer(cp^) := TVarRec(p^).VPChar;
        end;
        btClass: begin
          if v^.VarParam then
            Pointer(cp^) := TVarRec(p^).VObject;
        end;
{$IFNDEF PS_NOINTERFACES}
{$IFDEF Delphi3UP}
        btInterface: begin
          if v^.VarParam then
            SetInterfaceVar(Pointer(cp^), TVarRec(p^).VInterface);
          IUnknown(TVarRec(p^).VInterface) := nil;
        end;
{$ENDIF}
{$ENDIF}
      end;
      datap := Pointer(IPointer(datap)+ (3*sizeof(Pointer)));
      p := Pointer(IPointer(p) + Cardinal(v^.ElementSize));
    end;
    FreeMem(v.Data, v.ElementSize * v.ItemCount);
  end;
  Dispose(V);
end;


{ The method a procedure-pointer value stands for: the script procedure whose number it holds,
  otherwise the method stored beside the number -- a handler the script read from an event
  Delphi had assigned -- and nil when there is none. }
function ProcPtrToMethod(Se: TPSExec; ProcPtr: Pointer): TMethod;
begin
  if tbtu32(ProcPtr^) <> 0 then
    Result := MkMethod(Se, tbtu32(ProcPtr^))
  else begin
    Result.Data := Pointer(Pointer(IPointer(ProcPtr)+PointerSize)^);
    Result.Code := Pointer(Pointer(IPointer(ProcPtr)+PointerSize2)^);
  end;
end;

{$IFNDEF FPC}
  {$UNDEF _INVOKECALL_INC_}
  {$UNDEF USEINVOKECALL}

  {$IFDEF DELPHI23UP}
  {$IFNDEF AUTOREFCOUNT}
  {$IFNDEF PS_USECLASSICINVOKE}
    {$DEFINE USEINVOKECALL}
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}

  {$IFDEF USEINVOKECALL}
    {$include InvokeCall.inc}
    {$DEFINE _INVOKECALL_INC_}
  {$ELSE}
    {$IFDEF Delphi6UP}
      {$IFDEF CPUX64}
        {$include x64.inc}
      {$ELSE}
        {$include x86.inc}
      {$ENDIF}
    {$ELSE}
      {$include x86.inc}
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  
  {$IFDEF USEINVOKECALL}
    {$include InvokeCall.inc}
    {$DEFINE _INVOKECALL_INC_}
  {$ELSE}
  {$IFDEF Delphi6UP}
    {$if defined(cpu86)}
      {$include x86.inc}
    {$elseif defined(cpupowerpc)}
      {$include powerpc.inc}
    {$elseif defined(cpuaarch64)}
      {$include arm64.inc}
    {$elseif defined(cpuarm)}
      {$include arm.inc}
    {$elseif defined(CPUX86_64)}
      {$include x64.inc}
    {$else}
      {$fatal Pascal Script is not supported for your architecture at the moment!}
    {$ifend}
  {$ELSE}
    {$include x86.inc}
  {$ENDIF}
  {$ENDIF}
{$ENDIF}

{ A native routine can call a script routine back, which can grow the script's
  stack -- its data does not move (UseChunks) -- or clear it, while the
  native routine holds addresses into it: chunks a Clear releases meanwhile are
  kept until the call ends }
function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
begin
  FStack.NativeCallStarts;
  try
    Result := PlatformInnerfuseCall(_Self, Address, CallingConv, Params, res);
  finally
    FStack.NativeCallEnds;
  end;
end;

type
  PScriptMethodInfo = ^TScriptMethodInfo;
  TScriptMethodInfo = record
    { nil once the script has ended }
    Se: TPSExec;
    ProcNo: Cardinal;
  end;


function MkMethod(FSE: TPSExec; No: Cardinal): TMethod;
begin
  if (no = 0) or (no = InvalidVal) then
  begin
    Result.Code := nil;
    Result.Data := nil;
  end else begin
    {$IFDEF FPC}{$IFDEF empty_methods_handler}
    raise Exception.Create(RPS_NoNativeMethodsHandler);
    {$ENDIF}{$ENDIF}
    Result.Code := @MyAllMethodsHandler;
    Result.Data := GetMethodInfoRec(FSE, No);
  end;
end;


procedure PFree(Sender: TPSExec; P: PScriptMethodInfo);
begin
  { the script has ended, but native code can still hold a method made from
    this record -- an event of an object that outlives the script -- so the
    record is never freed: a call through it finds no executor and is
    refused.  Where the RTL has the entry, the memory manager is asked to
    leave it out of a leak report at exit; whether it does is the manager's }
  P^.Se := nil;
  {$IF Defined(DELPHI2006UP) and not Defined(FPC)}
  System.RegisterExpectedMemoryLeak(P);
  {$IFEND}
end;

function GetMethodInfoRec(SE: TPSExec; ProcNo: Cardinal): Pointer;
var
  I: Longint;
  pp: PScriptMethodInfo;
begin
  if (ProcNo = 0) or (ProcNo = InvalidVal) then
  begin
    Result := nil;
    exit;
  end;
  I := 2147483647;
  repeat
    pp := Se.FindProcResource2(@PFree, I);
    { a record at the list's first place too: the search leaves i at -1 there }
    if (pp <> nil) and (pp^.ProcNo = ProcNo) then
    begin
      Result := Pp;
      exit;
    end;
  until i = -1;
  New(pp);
  pp^.Se := TPSExec(Se);
  pp^.ProcNo := Procno;
  Se.AddResource(@PFree, pp);
  Result := pp;
end;





type
  TPtrArr = array[0..1000] of Pointer;
  PPtrArr = ^TPtrArr;
  TByteArr = array[0..1000] of byte;
  PByteArr = ^TByteArr;
  PPointer = ^Pointer;


function VirtualMethodPtrToPtr(Ptr, FSelf: Pointer): Pointer;
{$IFDEF FPC}
var
 x : PPtrArr;
{$ENDIF}
begin
 {$IFDEF FPC}
 x := Pointer(TObject(FSelf).ClassType) + vmtMethodStart;
 Result := x^[Longint(Ptr)];
 {$ELSE}
 Result := PPtrArr(PPointer(FSelf)^)^[Longint(Ptr)];
 {$ENDIF}
end;

function VirtualClassMethodPtrToPtr(Ptr, FSelf: Pointer): Pointer;
{$IFDEF FPC}
var
 x : PPtrArr;
{$ENDIF}
begin
  {$IFDEF FPC}
  x := Pointer(FSelf) + vmtMethodStart;
  Result := x^[Longint(Ptr)];
  {$ELSE}
  Result := PPtrArr(FSelf)^[Longint(Ptr)];
  {$ENDIF}
end;


procedure CheckPackagePtr(var P: PByteArr);
begin
  {$ifdef Win32}
  if (word((@p[0])^) = $25FF) and (word((@p[6])^)=$C08B)then
  begin
    p := PPointer((@p[2])^)^;
  end;
  {$endif}
  {$ifdef Win64}
  if (word((@p[0])^) = $25FF) {and (word((@p[6])^)=$C08B)}then
  begin
    p := PPointer(NativeInt(@P[0]) + Integer((@p[2])^) + 6{Instruction Size})^
  end;
  {$endif}
end;

{$IFDEF VER90}{$DEFINE NO_vmtSelfPtr}{$ENDIF}
{$IFDEF FPC}{$DEFINE NO_vmtSelfPtr}{$ENDIF}

{$IFNDEF FPC}

function FindVirtualMethodPtr(Ret: TPSRuntimeClass; FClass: TClass; Ptr: Pointer): Pointer;
// Idea of getting the number of VMT items from GExperts
var
  p: PPtrArr;
  I: Longint;
begin
  p := Pointer(FClass);
  CheckPackagePtr(PByteArr(Ptr));
  if Ret.FEndOfVMT = MaxInt then
  begin
    I := {$IFDEF NO_vmtSelfPtr}-48{$ELSE}vmtSelfPtr{$ENDIF} div SizeOf(Pointer) + 1;
    while I < 0 do
    begin
      if I < 0 then
      begin
        if I <> ({$IFDEF VER90}-44{$ELSE}vmtTypeInfo{$ENDIF} div SizeOf(Pointer)) then
        begin // from GExperts code
          if (IPointer(p^[I]) > IPointer(p)) and ((IPointer(p^[I]) - IPointer(p))
            div
            //PointerSize < Ret.FEndOfVMT) then
            PointerSize < Cardinal(Ret.FEndOfVMT)) then
          begin
            Ret.FEndOfVMT := (IPointer(p^[I]) - IPointer(p)) div SizeOf(Pointer);
          end;
        end;
      end;
      Inc(I);
    end;
    if Ret.FEndOfVMT = MaxInt then
    begin
      Ret.FEndOfVMT := 0; // cound not find EndOfVMT
      Result := nil;
      exit;
    end;
  end;
  I := 0;
  while I < Ret.FEndOfVMT do
  begin
    if p^[I] = Ptr then
    begin
      Result := Pointer(I);
      exit;
    end;
    I := I + 1;
  end;
  Result := nil;
end;

{$ELSE}

function FindVirtualMethodPtr(Ret: TPSRuntimeClass; FClass: TClass; Ptr: Pointer): Pointer;
var
  x,p: PPtrArr;
  I: Longint;
  t : Pointer;
begin
  p := Pointer(FClass) + vmtMethodStart;
  I := 0;
  while (p^[I]<>nil) and (I < 10000) do
  begin
    if p^[I] = Ptr then
    begin
      Result := Pointer(I);
      x := Pointer(FClass) + vmtMethodStart;
      t := x^[I];
      Assert(t=Ptr,'Computation of virtual method pointer fail : t<>Ptr');
      exit;
    end;
    I := I + 1;
  end;
  Result := nil;
end;

{$ENDIF}


function NewTPSVariantIFC(avar: PPSVariant; varparam: boolean): TPSVariantIFC;
begin
  Result.VarParam := varparam;
  if avar = nil then
  begin
    Result.aType := nil;
    result.Dta := nil;
  end else
  begin
    Result.aType := avar.FType;
    result.Dta := @PPSVariantData(avar).Data;
    if Result.aType.BaseType = btPointer then
    begin
      Result.aType := Pointer(Pointer(IPointer(result.dta)+ PointerSize)^);
      Result.Dta := Pointer(Result.dta^);
    end;
  end;
end;

function NewTPSVariantRecordIFC(avar: PPSVariant; Fieldno: Longint): TPSVariantIFC;
var
  offs: Cardinal;
begin
  Result := NewTPSVariantIFC(avar, false);
  if Result.aType.BaseType = btRecord then
  begin
    Offs := Cardinal(TPSTypeRec_Record(Result.aType).RealFieldOffsets[FieldNo]);
    Result.Dta := Pointer(IPointer(Result.dta) + Offs);
    Result.aType := TPSTypeRec_Record(Result.aType).FieldTypes[FieldNo];
  end else
  begin
    Result.Dta := nil;
    Result.aType := nil;
  end;
end;

function PSGetArrayField(const avar: TPSVariantIFC; Fieldno: Longint): TPSVariantIFC;
var
  offs: Cardinal;
  n: Longint;
begin
  Result := aVar;
  case Result.aType.BaseType of
    btStaticArray, btArray:
  begin
        if Result.aType.BaseType = btStaticArray then
          n := TPSTypeRec_StaticArray(Result.aType).Size
        else
          n := PSDynArrayGetLength(Pointer(Result.Dta^), Result.aType);
        if (FieldNo <0) or (FieldNo >= n) then
    begin
      Result.Dta := nil;
      Result.aType := nil;
      exit;
    end;

    if TPSTypeRec_Array(Result.aType).ArrayType.BaseType = btPointer then begin
      { See CreateOpenArray }
      if Result.aType.BaseType = btStaticArray then
        Result := PPSVariantIFC(IPointer(Result.Dta) + IPointer(Fieldno) * 3 * SizeOf(Pointer))^
      else
        Result := PPSVariantIFC(IPointer(Result.Dta^) + IPointer(Fieldno) * 3 * SizeOf(Pointer))^;
      exit;
    end;

    Offs := TPSTypeRec_Array(Result.aType).ArrayType.RealSize * Cardinal(FieldNo);
        if Result.aType.BaseType = btStaticArray then
          Result.Dta := Pointer(IPointer(Result.dta) + Offs)
        else
          Result.Dta := Pointer(IPointer(Result.dta^) + Offs);
    Result.aType := TPSTypeRec_Array(Result.aType).ArrayType;
      end
  else
    Result.Dta := nil;
    Result.aType := nil;
  end;
end;

function PSGetRecField(const avar: TPSVariantIFC; Fieldno: Longint): TPSVariantIFC;
var
  offs: Cardinal;
begin
  Result := aVar;
  if Result.aType.BaseType = btRecord then
  begin
    Offs := Cardinal(TPSTypeRec_Record(Result.aType).RealFieldOffsets[FieldNo]);
    Result.aType := TPSTypeRec_Record(Result.aType).FieldTypes[FieldNo];
    Result.Dta := Pointer(IPointer(Result.dta) + Offs);
  end else
  begin
    Result.Dta := nil;
    Result.aType := nil;
  end;
end;

function NewPPSVariantIFC(avar: PPSVariant; varparam: boolean): PPSVariantIFC;
begin
  New(Result);
  Result^ := NewTPSVariantIFC(avar, varparam);
end;


procedure DisposePPSVariantIFC(aVar: PPSVariantIFC);
begin
  if avar <> nil then
    Dispose(avar);
end;

procedure DisposePPSVariantIFCList(list: TPSList);
var
  i: Longint;
begin
  for i := list.Count -1 downto 0 do
    DisposePPSVariantIFC(list[i]);
  list.free;
end;

function ClassCallProcMethod(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  i: Integer;
  MyList: TPSList;
  n: PIFVariant;
  v: PPSVariantIFC;
  FSelf: Pointer;
  CurrStack: Cardinal;
  cc: TPSCallingConvention;
  s: tbtString;
begin
  s := p.Decl;
  if length(S) < 2 then
  begin
    Result := False;
    exit;
  end;
  cc := TPSCallingConvention(s[1]);
  Delete(s, 1, 1);
  if s[1] = #0 then
    n := Stack[Stack.Count -1]
  else
    n := Stack[Stack.Count -2];
  { Free on nil does nothing, as Delphi's TObject.Free does; any other method on nil is refused below }
  if (n <> nil) and (n^.FType.BaseType = btClass) and (PPSVariantClass(n).Data = nil) and (p.Ext2 = nil) and
    (p.Ext1 = @TObject.Free) then
  begin
    Result := True;
    exit;
  end;
  if (n = nil) or (n^.FType.BaseType <> btClass)or (PPSVariantClass(n).Data = nil) then
  begin
    Caller.CMD_Err(erNullPointerException);
    result := false;
    exit;
  end;
  FSelf := PPSVariantClass(n).Data;
  CurrStack := Cardinal(Stack.Count) - Cardinal(length(s)) -1;
  if s[1] = #0 then inc(CurrStack);
  MyList := TPSList.Create;
  for i := 2 to length(s) do
  begin
    MyList.Add(nil);
  end;
  for i := length(s) downto 2 do
  begin
    n := Stack[CurrStack];
    MyList[i - 2] := NewPPSVariantIFC(n, s[i] <> #0);
    inc(CurrStack);
  end;
  if s[1] <> #0 then
  begin
    v := NewPPSVariantIFC(Stack[CurrStack + 1], True);
  end else v := nil;
  try
    if p.Ext2 = nil then
      Result := Caller.InnerfuseCall(FSelf, p.Ext1, cc, MyList, v)
    else
      Result := Caller.InnerfuseCall(FSelf, VirtualMethodPtrToPtr(p.Ext1, FSelf), cc, MyList, v);
  finally
    DisposePPSVariantIFC(v);
    DisposePPSVariantIFCList(mylist);
  end;
end;

function ClassCallProcConstructor(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  i, h: Longint;
  v: PPSVariantIFC;
  MyList: TPSList;
  n: PIFVariant;
  FSelf: Pointer;
  CurrStack: Cardinal;
  cc: TPSCallingConvention;
  s: tbtString;
  FType: PIFTypeRec;
  x: TPSRuntimeClass;
  IntVal: PIFVariant;
begin
  n := Stack[Stack.Count -2];
  if (n = nil) or (n^.FType.BaseType <> btU32)  then
  begin
    result := false;
    exit;
  end;
  FType := Caller.GetTypeNo(PPSVariantU32(N).Data);
  if (FType = nil)  then
  begin
    Result := False;
    exit;
  end;
  h := MakeHash(FType.ExportName);
  FSelf := nil;
  for i := 0 to TPSRuntimeClassImporter(p.Ext2).FClasses.Count -1 do
  begin
    x:= TPSRuntimeClassImporter(p.Ext2).FClasses[i];
    if (x.FClassNameHash = h) and (x.FClassName = FType.ExportName) then
    begin
      FSelf := x.FClass;
    end;
  end;
  if FSelf = nil then begin
    Result := False;
    exit;
  end;
  s := p.Decl;
  if length(S) < 2 then
  begin
    Result := False;
    exit;
  end;
  cc := TPSCallingConvention(s[1]);
  Delete(s, 1, 1);
  CurrStack := Cardinal(Stack.Count) - Cardinal(length(s)) -1;
  if s[1] = #0 then inc(CurrStack);
  {$IFDEF CPU64}
  IntVal := CreateHeapVariant(Caller.FindType2(btS64));
  {$ELSE}
  IntVal := CreateHeapVariant(Caller.FindType2(btU32));
  {$ENDIF}
  if IntVal = nil then
  begin
    Result := False;
    exit;
  end;
  {$IFDEF FPC}
  // Free Pascal 3 calls a constructor as Delphi does, with the class in the
  // first register and 1 in the second.  Here the class travels as the first
  // parameter and Self is 1; the stubs' constructor arm (x86.inc, x64.inc)
  // loads the first parameter first, so the two arrive in that order.
  {$IFDEF CPU64}
  PPSVariantS64(IntVal).Data := Int64(FSelf);
  {$ELSE}
  PPSVariantU32(IntVal).Data := Cardinal(FSelf);
  {$ENDIF}
  FSelf := pointer(1);
  {$ELSE}
  PPSVariantU32(IntVal).Data := 1;
  {$ENDIF}
  MyList := TPSList.Create;
  MyList.Add(NewPPSVariantIFC(intval, false));
  for i := 2 to length(s) do
  begin
    MyList.Add(nil);
  end;
  for i := length(s) downto 2 do
  begin
    n :=Stack[CurrStack];
//    if s[i] <> #0 then
//    begin
//      MyList[i - 2] := NewPPSVariantIFC(n, s[i] <> #0);
//    end;
    MyList[i - 1] := NewPPSVariantIFC(n, s[i] <> #0);
    inc(CurrStack);
  end;
  if s[1] <> #0 then
  begin
    v := NewPPSVariantIFC(Stack[CurrStack + 1], True);
  end else v := nil;
  try
    {$IFDEF _INVOKECALL_INC_}
    Result := Caller.InnerfuseCall(FSelf, p.Ext1, TPSCallingConvention(Integer(cc) or 64), MyList, v);
    {$ELSE}
    Result := Caller.InnerfuseCall(FSelf, p.Ext1, {$IFDEF FPC}TPSCallingConvention(Integer(cc) or 64){$ELSE}cc{$ENDIF}, MyList, v);
    {$ENDIF}
  finally
    DisposePPSVariantIFC(v);
    DisposePPSVariantIFCList(mylist);
    DestroyHeapVariant(intval);
  end;
end;


function ClassCallProcVirtualConstructor(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  i, h: Longint;
  v: PPSVariantIFC;
  MyList: TPSList;
  n: PIFVariant;
  FSelf: Pointer;
  CurrStack: Cardinal;
  cc: TPSCallingConvention;
  s: tbtString;
  FType: PIFTypeRec;
  x: TPSRuntimeClass;
  IntVal: PIFVariant;
begin
  n := Stack[Stack.Count -2];
  if (n = nil) or (n^.FType.BaseType <> btU32)  then
  begin
    Caller.CMD_Err(erNullPointerException);
    result := false;
    exit;
  end;
  FType := Caller.GetTypeNo(PPSVariantU32(N).Data);
  if (FType = nil)  then
  begin
    Caller.CMD_Err(erNullPointerException);
    Result := False;
    exit;
  end;
  h := MakeHash(FType.ExportName);
  FSelf := nil;
  for i := 0 to TPSRuntimeClassImporter(p.Ext2).FClasses.Count -1 do
  begin
    x:= TPSRuntimeClassImporter(p.Ext2).FClasses[i];
    if (x.FClassNameHash = h) and (x.FClassName = FType.ExportName) then
    begin
      FSelf := x.FClass;
    end;
  end;
  if FSelf = nil then begin
    Result := False;
    exit;
  end;
  s := p.Decl;
  if length(S) < 2 then
  begin
    Result := False;
    exit;
  end;
  cc := TPSCallingConvention(s[1]);
  delete(s, 1, 1);
  CurrStack := Cardinal(Stack.Count) - Cardinal(length(s)) -1;
  if s[1] = #0 then inc(CurrStack);
  IntVal := CreateHeapVariant(Caller.FindType2(btU32));
  if IntVal = nil then
  begin
    Result := False;
    exit;
  end;
  PPSVariantU32(IntVal).Data := 1;
  MyList := TPSList.Create;
  MyList.Add(NewPPSVariantIFC(intval, false));
  for i := 2 to length(s) do
  begin
    MyList.Add(nil);
  end;
  for i := length(s) downto 2 do
  begin
    n :=Stack[CurrStack];
    MyList[i - 1] := NewPPSVariantIFC(n, s[i] <> #0);
    inc(CurrStack);
  end;
  if s[1] <> #0 then
  begin
    v := NewPPSVariantIFC(Stack[CurrStack + 1], True);
  end else v := nil;
  try
    {$IFDEF _INVOKECALL_INC_}
    Result := Caller.InnerfuseCall(FSelf, VirtualClassMethodPtrToPtr(p.Ext1, FSelf), TPSCallingConvention(Integer(cc) or 128), MyList, v);
    {$ELSE}
    Result := Caller.InnerfuseCall(FSelf, VirtualClassMethodPtrToPtr(p.Ext1, FSelf), {$IFDEF FPC}TPSCallingConvention(Integer(cc) or 128){$ELSE}cc{$ENDIF}, MyList, v);
    {$ENDIF}
  finally
    DisposePPSVariantIFC(v);
    DisposePPSVariantIFCList(mylist);
    DestroyHeapVariant(intval);
  end;
end;

function CastProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  TypeNo, InVar, ResVar: TPSVariantIFC;
  FSelf: TClass;
  FType: PIFTypeRec;
  H, I: Longint;
  x: TPSRuntimeClass;
begin
  TypeNo := NewTPSVariantIFC(Stack[Stack.Count-3], false);
  InVar := NewTPSVariantIFC(Stack[Stack.Count-2], false);
  ResVar := NewTPSVariantIFC(Stack[Stack.Count-1], true);
  if (TypeNo.Dta = nil) or (InVar.Dta = nil) or (ResVar.Dta = nil) or
  (TypeNo.aType.BaseType <> btu32) or (resvar.aType <> Caller.FTypes[tbtu32(Typeno.dta^)])
  then
  begin
    Result := False;
    Exit;
  end;
{$IFNDEF PS_NOINTERFACES}
  if (invar.atype.BaseType = btInterface) and (resvar.aType.BaseType = btInterface) then
  begin
{$IFNDEF Delphi3UP}
    if IUnknown(resvar.Dta^) <> nil then
      IUnknown(resvar.Dta^).Release;
{$ENDIF}
    SetInterfaceVar(Pointer(resvar.Dta^), nil);
    { a nil interface casts to nil, as in Delphi }
    if (IUnknown(invar.Dta^) <> nil) and (IUnknown(invar.Dta^).QueryInterface(TPSTypeRec_Interface(ResVar.aType).Guid, IUnknown(resvar.Dta^)) <> 0) then
    begin
      Caller.CMD_Err2(erCustomError, tbtString(RPS_CannotCastInterface));
      Result := False;
      exit;
    end;
{$IFDEF Delphi3UP}
  end else if (Invar.aType.BaseType = btclass) and (resvar.aType.BaseType = btInterface) then
  begin
{$IFNDEF Delphi3UP}
    if IUnknown(resvar.Dta^) <> nil then
      IUnknown(resvar.Dta^).Release;
{$ENDIF}
    SetInterfaceVar(Pointer(resvar.Dta^), nil);
    { a nil object casts to nil, as in Delphi }
    if (TObject(invar.Dta^) <> nil) and not TObject(invar.dta^).GetInterface(TPSTypeRec_Interface(ResVar.aType).Guid, IUnknown(resvar.Dta^)) then
    begin
      Caller.CMD_Err2(erCustomError, tbtString(RPS_CannotCastInterface));
      Result := False;
      exit;
    end;
{$ENDIF}
  end else {$ENDIF}if (invar.aType.BaseType = btclass) and (resvar.aType.BaseType = btclass ) then
  begin
    FType := Caller.GetTypeNo(tbtu32(TypeNo.Dta^));
    if (FType = nil)  then
    begin
      Result := False;
      exit;
    end;
    h := MakeHash(FType.ExportName);
    FSelf := nil;
    for i := 0 to TPSRuntimeClassImporter(p.Ext2).FClasses.Count -1 do
    begin
      x:= TPSRuntimeClassImporter(p.Ext2).FClasses[i];
      if (x.FClassNameHash = h) and (x.FClassName = FType.ExportName) then
      begin
        FSelf := x.FClass;
      end;
    end;
    if FSelf = nil then begin
      Result := False;
      exit;
    end;

    Result := True;
    try
      TObject(ResVar.Dta^) := TObject(InVar.Dta^) as FSelf;
    except
      Result := False;
      Caller.CMD_Err2(erCustomError, tbtString(RPS_CannotCastObject));
    end;
    { left after the handler: Delphi XE3 to XE5 for Win64 keep the exception object of a handler left by a jump }
    if not Result then
      exit;
  end else
  begin
    Result := False;
    exit;
  end;
  result := True;
end;


function NilProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  n: TPSVariantIFC;
begin
  n := NewTPSVariantIFC(Stack[Stack.Count-1], True);
  if (n.Dta = nil) or ((n.aType.BaseType <> btClass) and (n.aType.BaseType <> btInterface)) then
  begin
    Result := False;
    Caller.CMD_Err(erNullPointerException);
    Exit;
  end;
{$IFNDEF PS_NOINTERFACES}
  if n.aType.BaseType = btInterface then
  begin
    {$IFNDEF Delphi3UP}
    if IUnknown(n.Dta^) <> nil then
      IUnknown(n.Dta^).Release;
    {$ENDIF}
    SetInterfaceVar(Pointer(n.Dta^), nil);
  end else
  {$ENDIF}
    Pointer(n.Dta^) := nil;
  result := True;
end;
function IntfCallProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  i: Integer;
  MyList: TPSList;
  n: TPSVariantIFC;
  n2: PPSVariantIFC;
  FSelf: Pointer;
  CurrStack: Cardinal;
  cc: TPSCallingConvention;
  s: tbtString;
begin
  s := p.Decl;
  if length(S) < 2 then
  begin
    Result := False;
    exit;
  end;
  cc := TPSCallingConvention(s[1]);
  Delete(s, 1, 1);
  if s[1] = #0 then
    n := NewTPSVariantIFC(Stack[Stack.Count -1], false)
  else
    n := NewTPSVariantIFC(Stack[Stack.Count -2], false);
  if (n.dta = nil) or (n.atype.BaseType <> btInterface) or (Pointer(n.Dta^) = nil) then
  begin
    Caller.CMD_Err(erNullPointerException);
    result := false;
    exit;
  end;
  FSelf := Pointer(n.dta^);
  CurrStack := Cardinal(Stack.Count) - Cardinal(length(s)) -1;
  if s[1] = #0 then inc(CurrStack);
  MyList := TPSList.Create;
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
    n2 := NewPPSVariantIFC(Stack[CurrStack + 1], True);
  end else n2 := nil;
  try
    Caller.InnerfuseCall(FSelf, Pointer(Pointer(IPointer(FSelf^) + (Cardinal(p.Ext1) * Sizeof(Pointer)))^), cc, MyList, n2);
    result := true;
  finally
    DisposePPSVariantIFC(n2);
    DisposePPSVariantIFCList(MyList);
  end;
end;


function InterfaceProc(Sender: TPSExec; p: TPSExternalProcRec; Tag: Pointer): Boolean;
var
  s: tbtString;
begin
  s := p.Decl;
  delete(s,1,5); // delete 'intf:'
  if s = '' then
  begin
    Result := False;
    exit;
  end;
  if s[1] = '.'then
  begin
    Delete(s,1,1);
    if length(S) < 6 then
    begin
      Result := False;
      exit;
    end;
    p.ProcPtr := IntfCallProc;
    p.Ext1 := Pointer((@s[1])^); // Proc Offset
    Delete(s,1,4);
    P.Decl := s;
    Result := True;
  end else Result := False;
end;


{ Whether aValue lies in the range of the Delphi type of aProp, a published
  property, where that type is an enumeration; True for any other kind.  A
  script enumeration can have more members than the Delphi type of its name
  (TBorderStyle, a subrange in Delphi), and SetOrdProp stores whatever it is
  given. }
function _InPropertyRange(aProp: PPropInfo; aValue: Longint): Boolean;
var
  lType : PTypeInfo;
  lData : PTypeData;
begin
  lType := aProp^.PropType{$IFNDEF FPC}^{$ENDIF};
  Result := True;
  if lType^.Kind = tkEnumeration then begin
    lData := GetTypeData(lType);
    Result := (aValue >= lData^.MinValue) and (aValue <= lData^.MaxValue);
  end;
end;

function getMethodNo(P: TMethod; SE: TPSExec): Cardinal;
begin
  if (p.Code <> @MyAllMethodsHandler) or (p.Data = nil)or (PScriptMethodInfo(p.Data)^.Se <> se)  then
    Result := 0
  else
  begin
    Result := PScriptMethodInfo(p.Data)^.ProcNo;
  end;
end;

function ClassCallProcProperty(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  n: TPSVariantIFC;
  ltemp: Longint;
  FSelf: Pointer;
  m: TMethod;
begin
  try
    {$IFDEF DELPHI10UP}{$REGION 'p.Ext2 = Pointer(0)'}{$ENDIF}
    if p.Ext2 = Pointer(0) then
    begin
      n := NewTPSVariantIFC(Stack[Stack.Count -1], False);
      if (n.Dta = nil) or (n.aType.BaseType <> btclass)  then
      begin
        result := false;
        Caller.CMD_Err(erNullPointerException);
        exit;
      end;
      FSelf := Pointer(n.dta^);
      if FSelf = nil then
      begin
        Caller.CMD_Err(erCouldNotCallProc);
        Result := False;
        exit;
      end;
      n := NewTPSVariantIFC(Stack[Stack.Count -2], false);
      if (PPropInfo(p.Ext1)^.PropType^.Kind = tkMethod) and ((n.aType.BaseType = btu32) or (n.aType.BaseType = btProcPtr))then
      begin
        if n.aType.BaseType = btProcPtr then
          SetMethodProp(TObject(FSelf), PPropInfo(p.Ext1), ProcPtrToMethod(Caller, n.dta))
        else begin
          { a number names a script routine, as a procedural value's does: a method made of any other number
            read past the routine list when native code called it }
          if (tbtu32(n.dta^) <> 0) and (tbtu32(n.dta^) <> InvalidVal) and
            ((tbtu32(n.dta^) >= Cardinal(Caller.FProcs.Count)) or (tbtu32(n.dta^) = Caller.FMainProc)) then
          begin
            Caller.CMD_Err(erOutOfProcRange);
            Result := False;
            Exit;
          end;
          SetMethodProp(TObject(FSelf), PPropInfo(p.Ext1), MkMethod(Caller, tbtu32(n.dta^)));
        end;
      end else
      case n.aType.BaseType of
        btSet:
          begin
            if TPSTypeRec_Set(n.aType).aByteSize > SizeOf(ltemp) then begin
              Caller.CMD_Err(erOutOfRange);
              Result := False;
              Exit;
            end;
            ltemp := 0;
            move(Byte(n.Dta^), ltemp, TPSTypeRec_Set(n.aType).aByteSize);
            SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), ltemp);
          end;
        btChar, btU8:
          if (n.aType.BaseType = btChar) and (PPropInfo(p.Ext1)^.PropType^.Kind = tkWChar) then
            SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), Ord(PSAnsiCharToWideChar(tbtchar(n.Dta^))))
          else if not _InPropertyRange(PPropInfo(p.Ext1), tbtu8(n.Dta^)) then begin
            Caller.CMD_Err(erOutOfRange);
            Result := False;
            Exit;
          end else
            SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), tbtu8(n.Dta^));
        btS8: SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), tbts8(n.Dta^));
        {$IFNDEF PS_NOWIDESTRING}btwidechar, {$ENDIF}btU16:
          if not _InPropertyRange(PPropInfo(p.Ext1), tbtu16(n.Dta^)) then begin
            Caller.CMD_Err(erOutOfRange);
            Result := False;
            Exit;
          end else
            SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), tbtu16(n.Dta^));
        btS16: SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), tbts16(n.Dta^));
        btU32:
          if not _InPropertyRange(PPropInfo(p.Ext1), Longint(tbtu32(n.Dta^))) then begin
            Caller.CMD_Err(erOutOfRange);
            Result := False;
            Exit;
          end else
            SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), tbtu32(n.Dta^));
        btS32: SetOrdProp(TObject(FSelf), PPropInfo(p.Ext1), tbts32(n.Dta^));
        {$IFNDEF PS_NOINT64}
        btS64: SetInt64Prop(TObject(FSelf), PPropInfo(p.Ext1), tbts64(n.Dta^));
        btU64: SetInt64Prop(TObject(FSelf), PPropInfo(p.Ext1), tbtu64(n.Dta^));
        {$ENDIF}
        btSingle: SetFloatProp(TObject(FSelf), p.Ext1, tbtsingle(n.Dta^));
        btDouble: SetFloatProp(TObject(FSelf), p.Ext1, tbtdouble(n.Dta^));
        btExtended: SetFloatProp(TObject(FSelf), p.Ext1, tbtextended(n.Dta^));
        btString: SetStrProp(TObject(FSelf), p.Ext1, string(tbtString(n.Dta^)));
        btPChar: SetStrProp(TObject(FSelf), p.Ext1, string(pansichar(n.Dta^)));
        btClass: SetOrdProp(TObject(FSelf), P.Ext1, IPointer(n.Dta^));
	  {$IFDEF DELPHI6UP}
{$IFNDEF PS_NOWIDESTRING}
{$IFDEF WIDESTRING_EQUAL_UNICODESTRING}btUnicodeString,{$ENDIF}
  btWideString: SetWideStrProp(TObject(FSelf), P.Ext1, tbtWidestring(n.dta^));
{$IFNDEF WIDESTRING_EQUAL_UNICODESTRING}
  btUnicodeString: {$IFDEF DELPHI_TOKYO_UP}SetStrProp{$ELSE}SetUnicodeStrProp{$ENDIF}(TObject(FSelf), P.Ext1, tbtUnicodestring(n.dta^));
{$ENDIF}
  {$ENDIF}
{$ENDIF}
        else
        begin
          Result := False;
          exit;
        end;
      end;
      Result := true;
    end
    {$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}
    {$IFDEF DELPHI10UP}{$REGION 'p.Ext2 <> Pointer(0)'}{$ENDIF}
    else begin
      n := NewTPSVariantIFC(Stack[Stack.Count -2], False);
      if (n.dta = nil) or (n.aType.BaseType <> btClass)then
      begin
        result := false;
        Caller.CMD_Err(erNullPointerException);
        exit;
      end;
      FSelf := Pointer(n.dta^);
      if FSelf = nil then
      begin
        Caller.CMD_Err(erCouldNotCallProc);
        Result := False;
        exit;
      end;
      n := NewTPSVariantIFC(Stack[Stack.Count -1], false);
      if (PPropInfo(p.Ext1)^.PropType^.Kind = tkMethod) and ((n.aType.BaseType = btu32) or (n.aType.BaseType = btprocptr)) then
      begin
        m := GetMethodProp(TObject(FSelf), PPropInfo(p.Ext1));
        Cardinal(n.Dta^) := GetMethodNo(m, Caller);
        { only a procedural value holds the method beside its number: a number is four bytes }
        if (Cardinal(n.dta^) = 0) and (n.aType.BaseType = btProcPtr) then
        begin
          Pointer(Pointer((IPointer(n.dta)+PointerSize))^) := m.Data;
          Pointer(Pointer((IPointer(n.dta)+PointerSize2))^) := m.Code;
        end;
      end else
      case n.aType.BaseType of
        btSet:
          begin
            if TPSTypeRec_Set(n.aType).aByteSize > SizeOf(ltemp) then begin
              Caller.CMD_Err(erOutOfRange);
              Result := False;
              Exit;
            end;
            ltemp := GetOrdProp(TObject(FSelf), PPropInfo(p.Ext1));
            move(ltemp, Byte(n.Dta^), TPSTypeRec_Set(n.aType).aByteSize);
          end;
        btChar, btU8:
          if (n.aType.BaseType = btChar) and (PPropInfo(p.Ext1)^.PropType^.Kind = tkWChar) then
            tbtchar(n.Dta^) := PSWideCharToAnsiChar(WideChar(Word(GetOrdProp(TObject(FSelf), p.Ext1))))
          else
            tbtu8(n.Dta^) := GetOrdProp(TObject(FSelf), p.Ext1);
        btS8: tbts8(n.Dta^) := GetOrdProp(TObject(FSelf), p.Ext1);
        {$IFNDEF PS_NOWIDESTRING}btwidechar, {$ENDIF}btU16: tbtu16(n.Dta^) := GetOrdProp(TObject(FSelf), p.Ext1);
        btS16: tbts16(n.Dta^) := GetOrdProp(TObject(FSelf), p.Ext1);
        btU32: tbtu32(n.Dta^) := GetOrdProp(TObject(FSelf), p.Ext1);
        btS32: tbts32(n.Dta^) := GetOrdProp(TObject(FSelf), p.Ext1);
        {$IFNDEF PS_NOINT64}
        btS64: tbts64(n.Dta^) := GetInt64Prop(TObject(FSelf), p.Ext1);
        btU64: tbtu64(n.Dta^) := GetInt64Prop(TObject(FSelf), p.Ext1);
        {$ENDIF}
        btSingle: tbtsingle(n.Dta^) := GetFloatProp(TObject(FSelf), p.Ext1);
        btDouble: tbtdouble(n.Dta^) := GetFloatProp(TObject(FSelf), p.Ext1);
        btExtended: tbtextended(n.Dta^) := GetFloatProp(TObject(FSelf), p.Ext1);
        btString: tbtString(n.Dta^) := tbtString(GetStrProp(TObject(FSelf), p.Ext1));
        btClass: IPointer(n.dta^) := GetOrdProp(TObject(FSelf), p.Ext1);
	  {$IFDEF DELPHI6UP}
{$IFNDEF PS_NOWIDESTRING}
        {$IFNDEF WIDESTRING_EQUAL_UNICODESTRING}
        btUnicodeString: tbtUnicodeString(n.dta^) := {$IFDEF DELPHI_TOKYO_UP}GetStrProp{$ELSE}GetUnicodeStrProp{$ENDIF}(TObject(FSelf), P.Ext1);
        {$ELSE}
        btUnicodeString,
        {$ENDIF}
        btWideString: tbtWidestring(n.dta^) := GetWideStrProp(TObject(FSelf), P.Ext1);
{$ENDIF}
{$ENDIF}
      else
        begin
          Result := False;
          exit;
        end;
      end;
      Result := True;
    end;
    {$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}
  finally
  end;
end;

function ClassCallProcPropertyHelper(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  I, ParamCount: Longint;
  Params: TPSList;
  n: TPSVariantIFC;
  FSelf: Pointer;
begin
  if Length(P.Decl) < 4 then begin
    Result := False;
    exit;
  end;
  ParamCount := Longint((@P.Decl[1])^);
  if Longint(Stack.Count) < ParamCount +1 then begin
    Result := False;
    exit;
  end;
  Dec(ParamCount);
  if p.Ext1 <> nil then // read
  begin
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - 2], False);
    if (n.Dta = nil) or (n.aType.BaseType <> btClass) then
    begin
      result := false;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    FSelf := pointer(n.Dta^);
    if FSelf = nil then
    begin
      Caller.CMD_Err(erCouldNotCallProc);
      Result := False;
      exit;
    end;
    Params := TPSList.Create;
    Params.Add(NewPPSVariantIFC(Stack[Longint(Stack.Count) - 1], True));
    for i := Stack.Count -3 downto Longint(Stack.Count) - ParamCount -2 do
    begin
      Params.Add(NewPPSVariantIFC(Stack[I], False));
    end;
    try
      Result := Caller.InnerfuseCall(FSelf, p.Ext1, cdRegister, Params, nil);
    finally
      DisposePPSVariantIFCList(Params);
    end;
  end else begin
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - 1], False);
    if (n.Dta = nil) or (n.aType.BaseType <> btClass) then
    begin
      result := false;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    FSelf := pointer(n.Dta^);
    if FSelf = nil then
    begin
      Caller.CMD_Err(erCouldNotCallProc);
      Result := False;
      exit;
    end;
    Params := TPSList.Create;
    Params.Add(NewPPSVariantIFC(Stack[Longint(Stack.Count) - ParamCount - 2], False));

    for i := Stack.Count -2 downto Longint(Stack.Count) - ParamCount -1 do
    begin
      Params.Add(NewPPSVariantIFC(Stack[I], False));
    end;
    try
      Result := Caller.InnerfuseCall(FSelf, p.Ext2, cdregister, Params, nil);
    finally
      DisposePPSVariantIFCList(Params);
    end;
  end;
end;

function ClassCallProcPropertyHelperName(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  I, ParamCount: Longint;
  Params: TPSList;
  tt: PIFVariant;
  n: TPSVariantIFC;
  FSelf: Pointer;
begin
  if Length(P.Decl) < 4 then begin
    Result := False;
    exit;
  end;
  ParamCount := Longint((@P.Decl[1])^);
  if Longint(Stack.Count) < ParamCount +1 then begin
    Result := False;
    exit;
  end;
  Dec(ParamCount);
  if p.Ext1 <> nil then // read
  begin
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - 2], false);
    if (n.Dta = nil) or (n.aType.BaseType <> btClass) then
    begin
      result := false;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    FSelf := Tobject(n.dta^);
    if FSelf = nil then
    begin
      Caller.CMD_Err(erCouldNotCallProc);
      Result := False;
      exit;
    end;
    Params := TPSList.Create;
    Params.Add(NewPPSVariantIFC(Stack[Longint(Stack.Count) - 1], True));
    for i := Stack.Count -3 downto Longint(Stack.Count) - ParamCount -2 do
      Params.Add(NewPPSVariantIFC(Stack[I], False));
    tt := CreateHeapVariant(Caller.FindType2(btString));
    if tt = nil then
    begin
      DisposePPSVariantIFCList(Params);
      Result := False;
      exit;
    end;
    PPSVariantAString(tt).Data := p.Name;
    Params.Add(NewPPSVariantIFC(tt, false));
    try
      Result := Caller.InnerfuseCall(FSelf, p.Ext1, cdRegister, Params, nil);
    finally
      DestroyHeapVariant(tt);
      DisposePPSVariantIFCList(Params);
    end;
  end else begin
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - 1], false);
    if (n.Dta = nil) or (n.aType.BaseType <> btClass) then
    begin
      result := false;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    FSelf := Tobject(n.dta^);
    if FSelf = nil then
    begin
      Caller.CMD_Err(erCouldNotCallProc);
      Result := False;
      exit;
    end;
    Params := TPSList.Create;
    Params.Add(NewPPSVariantIFC(Stack[Longint(Stack.Count) - ParamCount - 2], False));

    for i := Stack.Count -2 downto Longint(Stack.Count) - ParamCount -1 do
    begin
      Params.Add(NewPPSVariantIFC(Stack[I], false));
    end;
    tt := CreateHeapVariant(Caller.FindType2(btString));
    if tt = nil then
    begin
      DisposePPSVariantIFCList(Params);
      Result := False;
      exit;
    end;
    PPSVariantAString(tt).Data := p.Name;
    Params.Add(NewPPSVariantIFC(tt, false));
    try
      Result := Caller.InnerfuseCall(FSelf, p.Ext2, cdregister, Params, nil);
    finally
      DestroyHeapVariant(tt);
      DisposePPSVariantIFCList(Params);
    end;
  end;
end;



function ClassCallProcEventPropertyHelper(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
{Event property helper}
var
  I, ParamCount: Longint;
  Params: TPSList;
  n: TPSVariantIFC;
  data: TMethod;
  n2: PIFVariant;
  FSelf: Pointer;
begin
  if Length(P.Decl) < 4 then begin
    Result := False;
    exit;
  end;
  ParamCount := Longint((@P.Decl[1])^);
  if Longint(Stack.Count) < ParamCount +1 then begin
    Result := False;
    exit;
  end;
  Dec(ParamCount);
  if p.Ext1 <> nil then // read
  begin
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - 2], false);
    if (n.Dta = nil) or (n.aType.BaseType <> btClass) then
    begin
      result := false;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    FSelf := Tobject(n.dta^);
    if FSelf = nil then
    begin
      Caller.CMD_Err(erCouldNotCallProc);
      Result := False;
      exit;
    end;
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - 1], True); // Result
    if (n.aType.BaseType <> btU32) and (n.aType.BaseType <> btProcPtr) then
    begin
      Result := False;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    n2 := CreateHeapVariant(Caller.FindType2(btPChar));
    if n2 = nil then
    begin
      Result := False;
      exit;
    end;
    Params := TPSList.Create;
//{$IFDEF CPU64}
//{$ELSE}
    data.Code := nil;
    data.Data := nil;
//{$ENDIF}
    PPSVariantDynamicArray(n2)^.Data:= @data;
    Params.Add(NewPPSVariantIFC(n2, false));
    for i := Stack.Count -3 downto Longint(Stack.Count) - ParamCount -2 do
      Params.Add(NewPPSVariantIFC(Stack[i], False));
    try
      Result := Caller.InnerfuseCall(FSelf, p.Ext1, cdRegister, Params, nil);
      { the event is stored only when the read helper returned: Delphi leaves a destination as it was when
        a getter raises }
      if Result then
      begin
        Cardinal(n.Dta^) := getMethodNo(data, Caller);
        { only a procedural value holds the method beside its number: a number is four bytes }
        if (Cardinal(n.Dta^) = 0) and (n.aType.BaseType = btProcPtr) then
        begin
          Pointer(Pointer((IPointer(n.dta)+PointerSize))^) := data.Data;
          Pointer(Pointer((IPointer(n.dta)+PointerSize2))^) := data.Code;
        end;
      end;
    finally
      DestroyHeapVariant(n2);
      DisposePPSVariantIFCList(Params);
    end;
  end else begin
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - 1], false);
    if (n.Dta = nil) or (n.aType.BaseType <> btClass) then
    begin
      result := false;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    FSelf := Tobject(n.dta^);
    if FSelf = nil then
    begin
      Caller.CMD_Err(erCouldNotCallProc);
      Result := False;
      exit;
    end;
    { the value lies below an indexed property's indices }
    n := NewTPSVariantIFC(Stack[Longint(Stack.Count) - ParamCount - 2], false);
    if (n.Dta = nil) or ((n.aType.BaseType <> btu32) and (n.aType.BaseType <> btProcPtr)) then
    begin
      result := false;
      Caller.CMD_Err(erNullPointerException);
      exit;
    end;
    { the write helper takes a method, and a number would reach it as one }
    if n.aType.BaseType = btU32 then
    begin
      Result := False;
      Caller.CMD_Err(erTypeMismatch);
      exit;
    end;
    (*n2 := CreateHeapVariant(Caller.FindType2(btPchar));
    if n2 = nil then
    begin
      Result := False;
      exit;
    end; *)

    //if (n.aType.BaseType = btProcPtr) and (cardinal(n.dta^) = 0) then
    //  data := TMethod(Pointer(IPointer(n.dta^)+4)^)
    //else
    //  data := MkMethod(Caller, cardinal(n.dta^));

    Params := TPSList.Create;
    Params.Add(@n);

    for i := Stack.Count -2 downto Longint(Stack.Count) - ParamCount -1 do
      Params.Add(NewPPSVariantIFC(Stack[I], False));
    try
      Result := Caller.InnerfuseCall(FSelf, p.Ext2, cdregister, Params, nil);
    finally
      { the value is n itself, which the list does not own }
      Params.Delete(0);
      //DestroyHeapVariant(n2);
      DisposePPSVariantIFCList(Params);
    end;
  end;
end;


{'class:'+CLASSNAME+'|'+FUNCNAME+'|'+chr(CallingConv)+chr(hasresult)+params

For property write functions there is an '@' after the funcname.
}
function SpecImport(Sender: TPSExec; p: TPSExternalProcRec; Tag: Pointer): Boolean;
var
  H, I: Longint;
  S, s2: tbtString;
  CL: TPSRuntimeClass;
  Px: PClassItem;
  pp: PPropInfo;
  IsRead: Boolean;
begin
  s := p.Decl;
  delete(s, 1, 6);
  if s = '-' then {nil function}
  begin
    p.ProcPtr := NilProc;
    Result := True;
    exit;
  end;
  if s = '+' then {cast function}
  begin
    p.ProcPtr := CastProc;
    p.Ext2 := Tag;
    Result := True;
    exit;
  end;
  s2 := copy(S, 1, pos(tbtchar('|'), s)-1);
  delete(s, 1, length(s2) + 1);
  H := MakeHash(s2);
  ISRead := False;
  cl := nil;
  for I := TPSRuntimeClassImporter(Tag).FClasses.Count -1 downto 0 do
  begin
    Cl := TPSRuntimeClassImporter(Tag).FClasses[I];
    if (Cl.FClassNameHash = h) and (cl.FClassName = s2) then
    begin
      IsRead := True;
      break;
    end;
  end;
  if not isRead then begin
    Result := False;
    exit;
  end;
  s2 := copy(S, 1, pos(tbtchar('|'), s)-1);
  delete(s, 1, length(s2) + 1);
  if (s2 <> '') and (s2[length(s2)] = '@') then
  begin
    IsRead := False;
    Delete(S2, length(s2), 1);
  end else
    isRead := True;
  p.Name := s2;
  H := MakeHash(s2);
  for i := cl.FClassItems.Count -1 downto 0 do
  begin
    px := cl.FClassItems[I];
    if (px^.FNameHash = h) and (px^.FName = s2) then
    begin
      p.Decl := s;
      case px^.b of
  {0: ext1=ptr}
  {1: ext1=pointerinlist}
  {2: ext1=propertyinfo}
  {3: ext1=readfunc; ext2=writefunc}
        4:
          begin
            p.ProcPtr := ClassCallProcConstructor;
            p.Ext1 := px^.Ptr;
            if p.Ext1 = nil then begin result := false; exit; end;
            p.Ext2 := Tag;
          end;
        5:
          begin
            p.ProcPtr := ClassCallProcVirtualConstructor;
            p.Ext1 := px^.Ptr;
           if p.Ext1 = nil then begin result := false; exit; end;
            p.Ext2 := Tag;
          end;
        6:
          begin
            p.ProcPtr := ClassCallProcEventPropertyHelper;
            if IsRead then
            begin
              p.Ext1 := px^.FReadFunc;
              if p.Ext1 = nil then begin result := false; exit; end;
              p.Ext2 := nil;
            end else
            begin
              p.Ext1 := nil;
              p.Ext2 := px^.FWriteFunc;
              if p.Ext2 = nil then begin result := false; exit; end;
            end;
          end;
        0:
          begin
            p.ProcPtr := ClassCallProcMethod;
            p.Ext1 := px^.Ptr;
            if p.Ext1 = nil then begin result := false; exit; end;
            p.Ext2 := nil;
          end;
        1:
          begin
            p.ProcPtr := ClassCallProcMethod;
            p.Ext1 := px^.PointerInList;
            //if p.Ext1 = nil then begin result := false; exit; end;
            p.ext2 := pointer(1);
          end;
        3:
          begin
            p.ProcPtr := ClassCallProcPropertyHelper;
            if IsRead then
            begin
              p.Ext1 := px^.FReadFunc;
              if p.Ext1 = nil then begin result := false; exit; end;
              p.Ext2 := nil;
            end else
            begin
              p.Ext1 := nil;
              p.Ext2 := px^.FWriteFunc;
              if p.Ext2 = nil then begin result := false; exit; end;
            end;
          end;
        7:
          begin
            p.ProcPtr := ClassCallProcPropertyHelperName;
            if IsRead then
            begin
              p.Ext1 := px^.FReadFunc;
              if p.Ext1 = nil then begin result := false; exit; end;
              p.Ext2 := nil;
            end else
            begin
              p.Ext1 := nil;
              p.Ext2 := px^.FWriteFunc;
              if p.Ext2 = nil then begin result := false; exit; end;
            end;
          end;
        else
         begin
           result := false;
           exit;
         end;
      end;
      Result := true;
      exit;
    end;
  end;
  if cl.FClass.ClassInfo <> nil then
  begin
    pp := GetPropInfo(cl.FClass.ClassInfo, string(s2));
    if pp <> nil then
    begin
       p.ProcPtr := ClassCallProcProperty;
       {$IFDEF LOG}
       __Log(string(cl.FClassName) + ' | '+string(s2)+ ' | $'+ IntToHex(IPointer(pp)));
       {$ENDIF}
       p.Ext1 := pp;
       if IsRead then
         p.Ext2 := Pointer(1)
       else
         p.Ext2 := Pointer(0);
       Result := True;
    end else
      result := false;
  end else
    Result := False;
end;

procedure RegisterClassLibraryRuntime(SE: TPSExec; Importer: TPSRuntimeClassImporter);
begin
  SE.AddSpecialProcImport('class', SpecImport, Importer);
end;


procedure TPSExec.ClearspecialProcImports;
var
  I: Longint;
  P: PSpecialProc;
begin
  for I := FSpecialProcList.Count -1 downto 0 do
  begin
    P := FSpecialProcList[I];
    Dispose(p);
  end;
  FSpecialProcList.Clear;
end;

procedure TPSExec.RaiseCurrentException;
var
  ExObj: TObject;
begin
  if ExEx = erNoError then exit; // do nothing
  ExObj := Self.ExObject;
  if ExObj <> nil then
  begin
    Self.ExObject := nil;
    raise ExObj;
  end;
  raise EPSException.Create(PSErrorToString(ExceptionCode, ExceptionString), Self, ExProc, ExPos);
end;

procedure TPSExec.CMD_Err2(EC: TPSError; const Param: tbtString);
begin
  CMD_Err3(EC, Param, Nil);
end;

function TPSExec.GetProcAsMethod(const ProcNo: Cardinal): TMethod;
begin
  Result := MkMethod(Self, ProcNo);
end;

function TPSExec.GetProcAsMethodN(const ProcName: tbtString): TMethod;
var
  procno: Cardinal;
begin
  Procno := GetProc(ProcName);
  if Procno = InvalidVal then
  begin
    Result.Code := nil;
    Result.Data := nil;
  end
  else
    Result := MkMethod(Self, procno)
end;


procedure TPSExec.RegisterAttributeType(useproc: TPSAttributeUseProc;
  const TypeName: tbtString);
var
  att: TPSAttributeType;
begin
  att := TPSAttributeType.Create;
  att.TypeName := TypeName;
  att.TypeNameHash := MakeHash(TypeName);
  att.UseProc := UseProc;
  FAttributeTypes.Add(att);
end;

function TPSExec.GetProcCount: Cardinal;
begin
  Result := FProcs.Count;
end;

function TPSExec.GetTypeCount: Longint;
begin
  Result := FTypes.Count;
end;

function TPSExec.GetVarCount: Longint;
begin
  Result := FGlobalVars.Count;
end;

function TPSExec.FindSpecialProcImport(
  P: TPSOnSpecialProcImport): pointer;
var
  i: Longint;
  pr: PSpecialProc;
begin
  for i := FSpecialProcList.Count -1 downto 0 do
  begin
    pr := FSpecialProcList[i];
    if @pr.P = @p then
    begin
      Result := pr.tag;
      exit;
    end;
  end;
  result := nil;
end;

function TPSExec.InvokeExternalMethod(At: TPSTypeRec_ProcPtr; Slf,
  Ptr: Pointer): Boolean;
var
  res: PPSVariantIFC;
  s: tbtString;
  CurrStack, i: Longint;
  n: PPSVariant;
  MyList: TPSList;
begin
  s := TPSTypeRec_ProcPtr(at).ParamInfo;
  CurrStack := Cardinal(FStack.Count) - Cardinal(length(s));
  if s[1] = #0 then inc(CurrStack);
  MyList := TPSList.Create;
  for i := 2 to length(s) do
  begin
    MyList.Add(nil);
  end;
  for i := length(s) downto 2 do
  begin
    n := FStack[CurrStack];
    MyList[i - 2] := NewPPSVariantIFC(n, s[i] <> #0);
    inc(CurrStack);
  end;
  if s[1] <> #0 then
  begin
    res := NewPPSVariantIFC(FStack[CurrStack], True);
  end else res := nil;
  try
    Result := InnerfuseCall(Slf, Ptr, cdRegister, MyList, Res);
  finally
    DisposePPSVariantIFC(res);
    DisposePPSVariantIFCList(mylist);
  end;
end;

{ The Last* functions: with exception frames, the exception of the nearest
  except handler running (none outside one); with none, the last exception. }
function TPSExec.LastEx: TPSError;
var
  pp: TPSExceptionHandler;
begin
  if FExceptionStack.Count = 0 then begin
    result := ExEx;
    exit;
  end;
  pp := _HandlerFrame(FExceptionStack);
  if pp = nil then
    result := ENoError
  else
    result := pp.ExceptionData;
end;

function TPSExec.LastExParam: tbtString;
var
  pp: TPSExceptionHandler;
begin
  if FExceptionStack.Count = 0 then begin
    result := ExParam;
    exit;
  end;
  pp := _HandlerFrame(FExceptionStack);
  if pp = nil then
    result := ''
  else
    result := pp.ExceptionParam;
end;

function TPSExec.LastExPos: Integer;
var
  pp: TPSExceptionHandler;
begin
  if FExceptionStack.Count = 0 then begin
    result := ExPos;
    exit;
  end;
  pp := _HandlerFrame(FExceptionStack);
  if pp = nil then
    result := Integer(InvalidVal)
  else
    result := Integer(pp.ExceptionPos);
end;

function TPSExec.LastExProc: Integer;
var
  pp: TPSExceptionHandler;
begin
  if FExceptionStack.Count = 0 then begin
    result := ExProc;
    exit;
  end;
  pp := _HandlerFrame(FExceptionStack);
  if pp = nil then
    result := Integer(InvalidVal)
  else
    result := Integer(pp.ExceptionProcNo);
end;

function TPSExec.LastExObject: TObject;
var
 pp: TPSExceptionHandler;
begin
 if FExceptionStack.Count = 0 then begin
   result := ExObject;
   exit;
 end;
 pp := _HandlerFrame(FExceptionStack);
 if pp = nil then
   result := nil
 else
   result := pp.ExceptionObject;
end;

{ TPSRuntimeClass }

constructor TPSRuntimeClass.Create(aClass: TClass; const AName: tbtString);
begin
  inherited Create;
  FClass := AClass;
  if AName = '' then
  begin
    FClassName := FastUpperCase(tbtString(aClass.ClassName));
    FClassNameHash := MakeHash(FClassName);
  end else begin
    FClassName := FastUppercase(AName);
    FClassNameHash := MakeHash(FClassName);
  end;
  FClassItems:= TPSList.Create;
  FEndOfVmt := MaxInt;
end;

destructor TPSRuntimeClass.Destroy;
var
  I: Longint;
  P: PClassItem;
begin
  for i:= FClassItems.Count -1 downto 0 do
  begin
    P := FClassItems[I];
    Dispose(p);
  end;
  FClassItems.Free;
  inherited Destroy;
end;

procedure TPSRuntimeClass.RegisterVirtualAbstractMethod(ClassDef: TClass;
  ProcPtr: Pointer; const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 1;
  p^.PointerInList := FindVirtualMethodPtr(Self, ClassDef, ProcPtr);
  FClassItems.Add(p);
end;

procedure TPSRuntimeClass.RegisterConstructor(ProcPtr: Pointer;
  const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 4;
  p^.Ptr := ProcPtr;
  FClassItems.Add(p);
end;

procedure TPSRuntimeClass.RegisterMethod(ProcPtr: Pointer; const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 0;
  p^.Ptr := ProcPtr;
  FClassItems.Add(p);
end;


procedure TPSRuntimeClass.RegisterPropertyHelper(ReadFunc,
  WriteFunc: Pointer; const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 3;
  p^.FReadFunc := ReadFunc;
  p^.FWriteFunc := WriteFunc;
  FClassItems.Add(p);
end;

procedure TPSRuntimeClass.RegisterVirtualConstructor(ProcPtr: Pointer;
  const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 5;
  p^.PointerInList := FindVirtualMethodPtr(Self, FClass, ProcPtr);
  FClassItems.Add(p);
end;

procedure TPSRuntimeClass.RegisterVirtualMethod(ProcPtr: Pointer; const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 1;
  p^.PointerInList := FindVirtualMethodPtr(Self, FClass, ProcPtr);
  FClassItems.Add(p);
end;

procedure TPSRuntimeClass.RegisterEventPropertyHelper(ReadFunc,
  WriteFunc: Pointer; const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 6;
  p^.FReadFunc := ReadFunc;
  p^.FWriteFunc := WriteFunc;
  FClassItems.Add(p);
end;


procedure TPSRuntimeClass.RegisterPropertyHelperName(ReadFunc,
  WriteFunc: Pointer; const Name: tbtString);
var
  P: PClassItem;
begin
  New(P);
  p^.FName := FastUppercase(Name);
  p^.FNameHash := MakeHash(p^.FName);
  p^.b := 7;
  p^.FReadFunc := ReadFunc;
  p^.FWriteFunc := WriteFunc;
  FClassItems.Add(p);
end;

{ TPSRuntimeClassImporter }

function TPSRuntimeClassImporter.Add(aClass: TClass): TPSRuntimeClass;
begin
  Result := FindClass(tbtstring(aClass.ClassName));
  if Result <> nil then exit;
  Result := TPSRuntimeClass.Create(aClass, '');
  FClasses.Add(Result);
end;

function TPSRuntimeClassImporter.Add2(aClass: TClass;
  const Name: tbtString): TPSRuntimeClass;
begin
  Result := FindClass(Name);
  if Result <> nil then exit;
  Result := TPSRuntimeClass.Create(aClass, Name);
  FClasses.Add(Result);
end;

procedure TPSRuntimeClassImporter.Clear;
var
  I: Longint;
begin
  for i := 0 to FClasses.Count -1 do
  begin
    TPSRuntimeClass(FClasses[I]).Free;
  end;
  FClasses.Clear;
end;

constructor TPSRuntimeClassImporter.Create;
begin
  inherited Create;
  FClasses := TPSList.Create;

end;

constructor TPSRuntimeClassImporter.CreateAndRegister(Exec: TPSExec;
  AutoFree: Boolean);
begin
  inherited Create;
  FClasses := TPSList.Create;
  RegisterClassLibraryRuntime(Exec, Self);
  { not a resource: Clear releases those, and loading a script begins with a
    Clear, where the importer is needed next }
  if AutoFree then
    Exec.FOwnedImporters.Add(Self);
end;

destructor TPSRuntimeClassImporter.Destroy;
begin
  Clear;
  FClasses.Free;
  inherited Destroy;
end;

{$IFNDEF PS_NOINTERFACES}
procedure SetVariantToInterface(V: PIFVariant; Cl: IUnknown);
begin
  if (v <> nil) and (v.FType.BaseType = btInterface) then
  begin
    PPSVariantinterface(v).Data := cl;
    {$IFNDEF Delphi3UP}
    if PPSVariantinterface(v).Data <> nil then
      PPSVariantinterface(v).Data.AddRef;
    {$ENDIF}
  end;
end;
{$ENDIF}

procedure SetVariantToClass(V: PIFVariant; Cl: TObject);
begin
  if (v <> nil) and (v.FType.BaseType = btClass) then
  begin
    PPSVariantclass(v).Data := cl;
  end;
end;

function BGRFW(var s: tbtString): tbtString;
var
  l: Longint;
begin
  l := Length(s);
  while l >0 do
  begin
    if s[l] = ' ' then
    begin
      Result := copy(s, l + 1, Length(s) - l);
      Delete(s, l, Length(s) - l + 1);
      exit;
    end;
    Dec(l);
  end;
  Result := s;
  s := '';
end;

function AlwaysAsVariable(aType: TPSTypeRec): Boolean;
begin
  case atype.BaseType of
    btVariant: Result := true;
{$IFDEF CPU64}
    { See the btSet/btRecord/btStaticArray comment in x64.inc }
    btSet: Result := not (atype.RealSize in [1, 2, 3, 4{$IFDEF DELPHI}{$IFNDEF DELPHI_RIO_UP}, 5, 6, 7, 8{$ENDIF}{$ENDIF}]);
{$IF defined(FPC) and defined(MSWINDOWS)}
    { Every record and static array by reference, as the FPC arm of the
      btSet/btRecord/btStaticArray case in x64.inc passes them.  Free Pascal x86_64
      compiles no method handler (empty_methods_handler), so no call reaches this
      arm there. }
    btRecord, btStaticArray: Result := True;
{$ELSE}
    btRecord, btStaticArray: Result := not (atype.RealSize in [1, 2, 4{$IFDEF DELPHI}{$IFNDEF DELPHI_RIO_UP}, 8{$ENDIF}{$ENDIF}]);
{$IFEND}
{$ELSE}
    btSet, btRecord, btStaticArray: Result := atype.RealSize > PointerSize;
{$ENDIF}
  else
    Result := false;
  end;
end;

function ParamAsVariable(const Modifier: tbtchar; aType: TPSTypeRec): Boolean;
begin
  Result := (Modifier = '%') or (Modifier = '!') or AlwaysAsVariable(aType);
end;

{$ifdef empty_methods_handler}
procedure MyAllMethodsHandler;
begin
end;
{$else}


{ Copies a value parameter native code hands a script procedure it calls as a
  method; aCopied turns False when the copy fails (CopyArrayContents takes the
  exception) }
procedure CopyNativeParameter(aDest, aSrc: Pointer; aType: TPSTypeRec; var aCopied: Boolean);
begin
  if not CopyArrayContents(aDest, aSrc, 1, aType) then
    aCopied := False;
end;

{ Refuses a call into a script procedure one of whose parameters could not be
  copied, after freeing the parameters made for it, as a Delphi routine's
  failed copy of a parameter raises to its caller before the routine runs.
  The copy's own exception is gone, so the caller gets Invalid parameter }
procedure RefuseNativeParameters(aParams: TPSList);
begin
  FreePIFVariantList(aParams);
  raise Exception.Create(RPS_InvalidParameter);
end;

{ A parameter the native caller passes by reference (ParamAsVariable): a var
  parameter is the caller's variable; a value or const one -- a Variant, a
  large set, record or static array -- is the routine's own copy of it, as a
  Delphi routine copies such a value before it writes to it; aCopied turns
  False when that copy fails }
function NativeReferenceParameter(Se: TPSExec; const Modifier: tbtchar; aType: TPSTypeRec;
  aData: Pointer; var aCopied: Boolean): PPSVariant;
begin
  if (Modifier = '%') or (Modifier = '!') then
  begin
    Result := CreateHeapVariant(Se.FindType2(btPointer));
    PPSVariantPointer(Result).DestType := aType;
    PPSVariantPointer(Result).DataDest := aData;
  end else
  begin
    Result := CreateHeapVariant(aType);
    CopyNativeParameter(@PPSVariantData(Result)^.Data, aData, aType, aCopied);
  end;
end;

{ The procedural value a method stands for, written at aProcPtr: the number of
  the script procedure when the method is one of Se's procedures made a method,
  otherwise number 0 with the method beside it -- as a script holds an event
  Delphi had assigned }
procedure MethodToProcPtr(Se: TPSExec; const aMethod: TMethod; aProcPtr: Pointer);
begin
  tbtu32(aProcPtr^) := getMethodNo(aMethod, Se);
  if tbtu32(aProcPtr^) = 0 then
  begin
    Pointer(Pointer(IPointer(aProcPtr)+PointerSize)^) := aMethod.Data;
    Pointer(Pointer(IPointer(aProcPtr)+PointerSize2)^) := aMethod.Code;
  end;
end;

{ The procedural-type parameter aIdx of a script procedure that native code
  calls as a method: a value of its own made from the method the caller passed
  at aNative.  A var or out parameter sets aWriteBacks[aIdx] to aNative, where
  StoreMethodParameters puts it back as a method after the call -- unless an
  earlier one names the same variable: then it points at that one's value, as
  two var parameters of one variable share it }
function MethodParameter(Se: TPSExec; const aModifier: tbtchar; aType: TPSTypeRec; aNative: Pointer;
  Params: TPSList; var aWriteBacks: array of Pointer; aIdx: Integer): PPSVariant;
var
  lIdx: Integer;
begin
  if (aModifier = '%') or (aModifier = '!') then
  begin
    for lIdx := 0 to High(aWriteBacks) do
      if aWriteBacks[lIdx] = aNative then
      begin
        Result := CreateHeapVariant(Se.FindType2(btPointer));
        PPSVariantPointer(Result).DestType := aType;
        PPSVariantPointer(Result).DataDest := @PPSVariantData(Params[lIdx])^.Data;
        Exit;
      end;
    aWriteBacks[aIdx] := aNative;
  end;
  Result := CreateHeapVariant(aType);
  MethodToProcPtr(Se, TMethod(aNative^), @PPSVariantData(Result)^.Data);
end;

procedure StoreMethodParameters(Se: TPSExec; Params: TPSList; const aWriteBacks: array of Pointer);
var
  lIdx: Integer;
begin
  for lIdx := 0 to High(aWriteBacks) do
    if aWriteBacks[lIdx] <> nil then
      TMethod(aWriteBacks[lIdx]^) := ProcPtrToMethod(Se, @PPSVariantData(Params[lIdx])^.Data);
end;

{$IFNDEF CPU64}
{ Whether a 32-bit native caller passes a method parameter by reference: a var
  or out one always, one by value on Free Pascal; Delphi pushes a method by
  value as its two slots }
function MethodByReference(const aModifier: tbtchar): Boolean;
begin
  {$IFDEF FPC}
  Result := True;
  {$ELSE}
  Result := (aModifier = '%') or (aModifier = '!');
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF CPU64}
function MyAllMethodsHandler64(Self: PScriptMethodInfo; _RDX, _R8, _R9:Pointer; Stack: PPointer;  _XMM1, _XMM2, _XMM3: Pointer; {$IFDEF DELPHI} ResPtr: Pointer {$ENDIF}): Integer; forward;
{$ELSE}
function MyAllMethodsHandler32(Self: PScriptMethodInfo; const Stack: PPointer; _EDX, _ECX: Pointer{$IF defined(DELPHI) or (defined(FPC) and defined(CPUI386))}; ResPtr: Pointer{$IFEND}): Integer; forward;
{$ENDIF}

procedure MyAllMethodsHandler;
{$ifdef CPU64}
//  On entry:
//  RCX = Self pointer
//  - function:
//    * RDX - result
//    * R8, R9 = param1 .. param2
//    * STACK = param3... paramcount
//  - procedure
//    * RDX, R8, R9 - param1 - param3
//    * STACK = param4... paramcount
{$IFDEF DELPHI}
asm
  // SEH-compatible frame: .params 4 = 32 bytes local storage
  // Layout: ResPtr(8) + 3*unused(8) = 32 bytes
  // Stack: [rbp+0..31]=local, [rbp+32]=saved RBP, [rbp+40]=ret addr,
  //        [rbp+48..79]=shadow, [rbp+80+]=caller's 5th+ params
  .params 4
  // Note: Delphi x64 .params test results:
  // .params 1..4: stack starts at [rbp+80]
  // .params 5..6: stack starts at [rbp+96]
  // .params 7..8: stack starts at [rbp+112]

  xor     rax, rax              // Clear ResPtr (same as push 0 by 32-bit code)
  mov     [rbp+0], rax

  // MyAllMethodsHandler64 has 9 parameters: 4 via registers, 5 via stack
  // shadow space for callee(32) + 5 stack params(40) + alignment to 16 bytes(8) = 72+8 = 80 bytes
  sub     rsp, 80

  // Call MyAllMethodsHandler64(Self, _RDX, _R8, _R9, Stack, _XMM1, _XMM2, _XMM3, ResPtr)
  // RCX (Self), RDX, R8, R9 already contain the values we need
  lea     rax, [rbp+80]         // Stack ptr
  mov     [rsp+32], rax
  movsd   qword ptr [rsp+40], xmm1   // XMM1 raw value
  movsd   qword ptr [rsp+48], xmm2   // XMM2 raw value
  movsd   qword ptr [rsp+56], xmm3   // XMM3 raw value
  lea     rax, [rbp+0]          // ResPtr
  mov     [rsp+64], rax         // 64+8 = 72

  call    MyAllMethodsHandler64

  add     rsp, 80

  // Return ResPtr in both XMM0 and RAX, allowing the caller to choose correct one
  movsd   xmm0, qword ptr [rbp+0]
  mov     rax, [rbp+0]
end;
{$ELSE}
asm
  PUSH RBP
  MOVQ RAX, XMM3
  PUSH RAX
  MOVQ RAX, XMM2
  PUSH RAX
  MOVQ RAX, XMM1
  PUSH RAX
  MOV RAX, RSP
  ADD RAX, 20h+28h   //48h
  PUSH RAX  // stack
  // R9 - 3rd param
  // R8 - 2nd param
  // Rdx -1st param
  // Rcx - Self
  SUB RSP, 20h
  CALL MyAllMethodsHandler64
  ADD   RSP, 20h  //Restore stack
  ADD   RSP, 40h
  POP RAX
  SUB RSP, 40h
  ADD RSP, 4*8
end;
{$ENDIF}
{$else}
//  On entry:
//     EAX = Self pointer
//     EDX, ECX = param1 and param2
//     STACK = param3... paramcount
{$IF defined(DELPHI) or (defined(FPC) and defined(CPUI386))}
asm
  // Like the Win64 stub: the stub owns an 8-byte result slot and passes its
  // address to MyAllMethodsHandler32 as ResPtr, so that an Int64/UInt64
  // result also fits; the slot is loaded into EDX:EAX below
  push 0                // result slot, high dword
  push 0                // result slot, low dword
  push ecx              // _ECX stack arg
  mov ecx, edx          // _EDX register arg
  lea edx, [esp+4]
  push edx              // ResPtr stack arg
  lea edx, [esp+20]     // Stack register arg: the caller's stack params
  call MyAllMethodsHandler32
  // EAX = byte count of the caller's stack params, popped callee-style below
  // Stack now: result slot (2 dwords), return address, caller's stack params
  mov edx, [esp+8]
  mov [esp+eax+8], edx  // park the return address just below the params' end
  mov ecx, [esp]
  mov edx, [esp+4]
  lea esp, [esp+eax+8]  // pop the slot, old return address and params
  mov eax, ecx
end;
{$ELSE}
asm
  push 0
  push ecx
  push edx
  mov edx, esp
  add edx, 16 // was 12
  pop ecx
  call MyAllMethodsHandler32
  pop ecx
  mov edx, [esp]
  add esp, eax
  mov [esp], edx
  mov eax, ecx
end;
{$IFEND}
{$endif CPU64}

function ResultAsRegister(b: TPSTypeRec): Boolean;
begin
  case b.BaseType of
    btSingle,
    btDouble,
    btExtended,
    btCurrency,
    btU8,
    bts8,
    bts16,
    btu16,
    bts32,
    btu32,
{$IFDEF PS_FPCSTRINGWORKAROUND}
    btString,
{$ENDIF}
{$IFNDEF PS_NOINT64}
    bts64,
    btU64,
{$ENDIF}
    btPChar,
{$IFNDEF PS_NOWIDESTRING}
    btWideChar,
{$ENDIF}
    btChar,
    btclass,
    btEnum: Result := true;
{$IFDEF DELPHI}
    { The Delphi x64 ABI returns a record of 1, 2, or 4 bytes in RAX, and
      the x86 ABI a record of 1 or 2 bytes in AL/AX (see System.Rtti's
      UseResultPointer). Records of these sizes never contain a managed
      field, so no managed check is needed. A record of pointer size is
      also returned in RAX/EAX, but only when it contains no managed
      field. Static arrays follow the same rule: UseResultPointer treats
      tkArray like tkRecord. }
    btRecord, btStaticArray: Result := (b.RealSize in [1, 2{$IFDEF CPU64}, 4{$ENDIF}]) or
      ((b.RealSize = PointerSize) and not IsManagedType(b));
{$ENDIF}
    btSet: Result := b.RealSize <= PointerSize;
{$IFNDEF DELPHI}
    { Free Pascal i386 returns every static array through the hidden result
      pointer, and on Windows a record of 1, 2 or 4 bytes with no managed
      field in EAX }
{$IFDEF MSWINDOWS}
    btRecord: Result := (b.RealSize in [1, 2, 4]) and not IsManagedType(b);
{$ENDIF}
{$ENDIF}
  else
    Result := false;
  end;
end;

function SupportsRegister(b: TPSTypeRec): Boolean;
begin
  case b.BaseType of
    btU8,
    bts8,
    bts16,
    btu16,
    bts32,
    btu32,
{$IFDEF CPU64} 
{$IFNDEF PS_NOINT64}
    bts64,
    btU64,
{$ENDIF}
{$ENDIF}
    btstring,
    btclass,
{$IFNDEF PS_NOINTERFACES}
    btinterface,
{$ENDIF}
    btPChar,
{$IFNDEF PS_NOWIDESTRING}
    btwidestring,
    btUnicodeString,
    btWideChar,
{$ENDIF}
    btChar,
    btArray,
    btEnum: Result := true;
{$IFDEF DELPHI}
    { See the btSet/btRecord/btStaticArray comment in x64.inc. Delphi's set
      storage rounding needs a case here only when it crosses the by-value/
      by-reference boundary: 3 (by reference) rounds to 4 (by value), while
      the rounding of 5-7 to 8 does not (all by reference) }
    btSet: Result := b.RealSize in [1, 2, 3, 4{$IFDEF CPU64}{$IFNDEF DELPHI_RIO_UP}, 5, 6, 7, 8{$ENDIF}{$ENDIF}];
    btRecord, btStaticArray: Result := b.RealSize in [1, 2, 4{$IFDEF CPU64}{$IFNDEF DELPHI_RIO_UP}, 8{$ENDIF}{$ENDIF}];
{$ELSE}
    { Free Pascal i386 passes a set of up to 4 bytes in a register, and a
      value static array of up to 4 bytes on the stack }
    btSet: Result := b.RealSize <= PointerSize;
{$ENDIF}
{$IFDEF CPU64}
    btSingle,
    btDouble,
    btExtended,
    btCurrency: Result := True;
{$ENDIF}
  else
    Result := false;
  end;
end;

procedure PutOnFPUStackExtended(ft: extended);
asm
//  fstp tbyte ptr [ft]
  fld tbyte ptr [ft]

end;

procedure PutOnFPUStackCurrency(cu: currency);
asm
  fild qword ptr [cu]
end;

{$IFDEF CPU64}
function MyAllMethodsHandler64(Self: PScriptMethodInfo; _RDX, _R8, _R9:Pointer; Stack: PPointer;  _XMM1, _XMM2, _XMM3: Pointer; {$IFDEF DELPHI} ResPtr: Pointer {$ENDIF}): Integer;
var
  Decl: tbtString;
  I, C, regno: Integer;
  Params: TPSList;
  Res, Tmp: PIFVariant;
  cpt: PIFTypeRec;
  fmod: tbtchar;
  s,e: tbtString;
  FStack: pointer;
  ex: TPSExceptionHandler;
  lPosition, lStackBase, lRaised: Cardinal;
  lNative, lResultDest: Pointer;
  lWriteBacks: array of Pointer;
  lCopied: Boolean;
begin
  {$IFDEF LOG}
  __Log('RDX=$'+ IntToHex(IPointer(_RDX)));
  __Log('R8=$'+ IntToHex(IPointer(_R8)));
  __Log('R9=$'+ IntToHex(IPointer(_R9)));
  __Log('stack=$'+ IntToHex(IPointer(Stack)));
  __Log('XMM1=$'+ FloatToStr(Double(_XMM1)));
  __Log('XMM2=$'+ FloatToStr(Double(_XMM2)));
  __Log('XMM3=$'+ FloatToStr(Double(_XMM3)));
  {$ENDIF}
  { a method kept by native code after its script ended }
  if not Assigned(Self^.Se) then
    raise Exception.Create(RPS_EndedScriptMethod);
  { a host routine's declaration in the script holds the modes of its parameters, not their types: its
    arguments cannot be read }
  if TObject(Self^.Se.FProcs[Self^.ProcNo]) is TPSExternalProcRec then
    raise Exception.Create(RPS_HostRoutineAsMethod);
  Decl := TPSInternalProcRec(Self^.Se.FProcs[Self^.ProcNo]).ExportDecl;

  FStack := Stack;
  Params := TPSList.Create;
  s := decl;
  grfw(s);
  while s <> '' do begin
    Params.Add(nil);
    grfw(s);
  end;
  c := Params.Count;
  SetLength(lWriteBacks, c);
  lResultDest := nil;
  regno := 0;
  Result := 0;
  lCopied := True;

  s := decl;
  e := grfw(s);

  if e <> '-1' then begin
    cpt := Self.Se.GetTypeNo(StrToInt(e));
    if not ResultAsRegister(cpt) then begin
      lResultDest := Pointer(_RDX);
      if cpt.BaseType = btProcPtr then
        { the caller's result is a method: the script's procedural value is
          made apart and stored as a method after the call }
        Res := CreateHeapVariant(cpt)
      else begin
        Res := CreateHeapVariant(Self.Se.FindType2(btPointer));
        PPSVariantPointer(Res).DestType := cpt;
        PPSVariantPointer(Res).DataDest := lResultDest;
      end;
      Params.Add(Res);
      inc(regno);
    end
    else begin
      Res := CreateHeapVariant(cpt);
      Params.Add(Res);
    end;
  end
  else
    Res := nil;


  s := decl;
  grfw(s);

  for i := c-1 downto 0 do
  begin
    e := grfw(s);
    fmod := e[1];
    delete(e, 1, 1);
    cpt := Self.Se.GetTypeNo(StrToInt(e));
    if (cpt.BaseType = btProcPtr) and (RegNo < 3) then
    begin
      { a method is passed by reference, by value or not }
      case regno of
        0: lNative := _RDX;
        1: lNative := _R8;
      else
        lNative := _R9;
      end;
      inc(regno);
      Params[i] := MethodParameter(Self.Se, fmod, cpt, lNative, Params, lWriteBacks, i);
    end
    else if ParamAsVariable(fmod, cpt) and (RegNo < 3) then
    begin
      case regno of
        0: lNative := Pointer(_RDX);
        1: lNative := Pointer(_R8);
      else
        lNative := Pointer(_R9);
      end;
      inc(regno);
      Params[i] := NativeReferenceParameter(Self.Se, fmod, cpt, lNative, lCopied);
    end
    else if SupportsRegister(cpt) and (RegNo < 3) then
    begin
      tmp := CreateHeapVariant(cpt);
      Params[i] := tmp;
      case regno of
        0: begin
            if cpt.BaseType in [btSingle, btDouble, btExtended] then
              CopyArrayContents(@PPSVariantData(tmp)^.Data, @_XMM1, 1, cpt)
            else
              CopyNativeParameter(@PPSVariantData(tmp)^.Data, @_RDX, cpt, lCopied);
            inc(regno);
          end;
        1: begin
            if cpt.BaseType in [btSingle, btDouble, btExtended] then
              CopyArrayContents(@PPSVariantData(tmp)^.Data, @_XMM2, 1, cpt)
            else
              CopyNativeParameter(@PPSVariantData(tmp)^.Data, @_R8, cpt, lCopied);
            inc(regno);
          end;
        2: begin
            if cpt.BaseType in [btSingle, btDouble, btExtended] then
              CopyArrayContents(@PPSVariantData(tmp)^.Data, @_XMM3, 1, cpt)
            else
              CopyNativeParameter(@PPSVariantData(tmp)^.Data, @_R9, cpt, lCopied);
            inc(regno);
          end;
      end;
    end;
  end;

  s := decl;
  grfw(s);
  for i := c-1 downto 0 do begin
    e := grfw(s);
    fmod := e[1];
    delete(e, 1, 1);
    if Params[i] <> nil then Continue;
    cpt := Self.Se.GetTypeNo(StrToInt(e));
    if cpt.BaseType = btProcPtr then
      Params[i] := MethodParameter(Self.Se, fmod, cpt, Pointer(FStack^), Params, lWriteBacks, i)
    else if ParamAsVariable(fmod, cpt) then begin
      Params[i] := NativeReferenceParameter(Self.Se, fmod, cpt, Pointer(FStack^), lCopied);
    end
    else begin
      tmp := CreateHeapVariant(cpt);
      Params[i] := tmp;
      CopyNativeParameter(@PPSVariantData(tmp)^.Data, Pointer(FStack), cpt, lCopied);
    end;
    FStack := Pointer(IPointer(FStack) + PointerSize);
    Inc(Result, PointerSize);
  end;
  if not lCopied then
    RefuseNativeParameters(Params);
  ex := TPSExceptionHandler.Create;
  ex.FinallyOffset := InvalidVal;
  ex.ExceptOffset := InvalidVal;
  ex.Finally2Offset := InvalidVal;
  ex.EndOfBlock := InvalidVal;
  ex.CurrProc := nil;
  ex.BasePtr := Self.Se.FCurrStackBase;
  Ex.StackSize := Self.Se.FStack.Count;
  i :=  Self.Se.FExceptionStack.Add(ex);
  { where the interpreter stands while the native code runs the script }
  lPosition := Self.Se.FCurrentPosition;
  lStackBase := Self.Se.FCurrStackBase;
  lRaised := Self.Se.FRaisedCount;
  Self.Se.RunProc(Params, Self.ProcNo);
  if Self.Se.FExceptionStack[i] = ex then begin
    Self.Se.FExceptionStack.Remove(ex);
    ex.Free;
  end else begin
    { the script's exception ended the call at this frame, below the return
      address: the interpreter is back where the native code called it }
    Self.Se.FCurrentPosition := lPosition;
    Self.Se.FCurrStackBase := lStackBase;
  end;

  StoreMethodParameters(Self.Se, Params, lWriteBacks);
  if (Res <> nil) then begin
    Params.DeleteLast;
    if (ResultAsRegister(Res.FType)) then begin
{$IFDEF DELPHI}
      CopyArrayContents(ResPtr, @PPSVariantData(res)^.Data, 1, Res^.FType);
{$ELSE}
      if (res^.FType.BaseType = btSingle) or (res^.FType.BaseType = btDouble) or
      (res^.FType.BaseType = btCurrency) or (res^.Ftype.BaseType = btExtended) then begin
        case Res^.FType.BaseType of
          btSingle: PutOnFPUStackExtended(PPSVariantSingle(res).Data);
          btDouble: PutOnFPUStackExtended(PPSVariantDouble(res).Data);
          btExtended: PutOnFPUStackExtended(PPSVariantExtended(res).Data);
          btCurrency: PutOnFPUStackExtended(PPSVariantCurrency(res).Data);
        end;
        DestroyHeapVariant(Res);
        Res := nil;
      end
      else begin
        CopyArrayContents(Pointer(IPointer(Stack)-IPointer(PointerSize2)), @PPSVariantData(res)^.Data, 1, Res^.FType);
      end;
{$ENDIF}
    end{$IFDEF DELPHI} else begin
      if (Res^.FType.BaseType = btProcPtr) and (Self.Se.ExEx = erNoError) then
        TMethod(lResultDest^) := ProcPtrToMethod(Self.Se, @PPSVariantData(Res)^.Data);
      { The Win64 ABI requires returning the hidden result pointer in RAX }
      PPointer(ResPtr)^ := lResultDest;
    end{$ENDIF};
    DestroyHeapVariant(res);
  end;
  for i := 0 to Params.Count - 1 do
    DestroyHeapVariant(Params[i]);
  Params.Free;
  if Self.Se.ExEx <> erNoError then begin
    { the exception goes to the native code, which may handle it and go on:
      the executor holds it no longer, and counts it again only if the
      native code lets it come back }
    if Self.Se.ExObject <> nil then begin
      FStack := Self.Se.ExObject;
      Self.Se.ExObject := nil;
    end
    else
      FStack := EPSException.Create(PSErrorToString(Self.SE.ExceptionCode, Self.Se.ExceptionString), Self.Se, Self.Se.ExProc, Self.Se.ExPos);
    Self.Se.ExceptionProc(InvalidVal, InvalidVal, erNoError, '', nil);
    Self.Se.FRaisedCount := lRaised;
    raise TObject(FStack);
  end;
end;
{$ELSE}
type
  { a real result of a script routine that native code called through a method
    pointer, as the script held it: MyAllMethodsHandler32 puts it on the x87
    stack.  No field precedes the variants, so each starts at the record's
    first byte }
  TPSMethodRealResult = record
    case Byte of
      0: (VSingle: tbtSingle);
      1: (VDouble: tbtDouble);
      2: (VExtended: tbtExtended);
      3: (VCurrency: tbtCurrency);
  end;

{ MyAllMethodsHandler32's work but for putting a real result on the x87 stack:
  a call that returns one sets aKind to its type -- btSingle, btDouble,
  btExtended or btCurrency -- and aResult to its bytes }
function _MethodsHandler32Call(Self: PScriptMethodInfo; const Stack: PPointer; _EDX, _ECX: Pointer{$IF defined(DELPHI) or (defined(FPC) and defined(CPUI386))}; ResPtr: Pointer{$IFEND};
  var aKind: TPSBaseType; var aResult: TPSMethodRealResult): Integer;
var
  Decl: tbtString;
  I, C, regno: Integer;
  Params: TPSList;
  Res, Tmp: PIFVariant;
  cpt: PIFTypeRec;
  fmod: tbtchar;
  s,e: tbtString;
  FStack: pointer;
  ex: TPSExceptionHandler;
  lPosition, lStackBase, lRaised: Cardinal;
  lNative, lResultDest: Pointer;
  lWriteBacks: array of Pointer;
  lCopied: Boolean;


begin
  { a method kept by native code after its script ended }
  if not Assigned(Self^.Se) then
    raise Exception.Create(RPS_EndedScriptMethod);
  { a host routine's declaration in the script holds the modes of its parameters, not their types: its
    arguments cannot be read }
  if TObject(Self^.Se.FProcs[Self^.ProcNo]) is TPSExternalProcRec then
    raise Exception.Create(RPS_HostRoutineAsMethod);
  Decl := TPSInternalProcRec(Self^.Se.FProcs[Self^.ProcNo]).ExportDecl;

  FStack := Stack;
  Params := TPSList.Create;
  s := decl;
  grfw(s);
  while s <> '' do
  begin
    Params.Add(nil);
    grfw(s);
  end;
  c := Params.Count;
  SetLength(lWriteBacks, c);
  lResultDest := nil;
  regno := 0;
  Result := 0;
  lCopied := True;
  s := decl;
  grfw(s);
  for i := c-1 downto 0 do
  begin
    e := grfw(s);
    fmod := e[1];
    delete(e, 1, 1);
    cpt := Self.Se.GetTypeNo(StrToInt(e));
    if (cpt.BaseType = btProcPtr) and (RegNo < 2) and MethodByReference(fmod) then
    begin
      if regno = 0 then
        lNative := _EDX
      else
        lNative := _ECX;
      inc(regno);
      Params[i] := MethodParameter(Self.Se, fmod, cpt, lNative, Params, lWriteBacks, i);
    end
    else if ParamAsVariable(fmod, cpt) and (RegNo < 2) then
    begin
      if regno = 0 then
        lNative := Pointer(_EDX)
      else
        lNative := Pointer(_ECX);
      inc(regno);
      Params[i] := NativeReferenceParameter(Self.Se, fmod, cpt, lNative, lCopied);
    end
    else if SupportsRegister(cpt) and (RegNo < 2) then
    begin
      tmp := CreateHeapVariant(cpt);
      Params[i] := tmp;
      case regno of
        0: begin
            CopyNativeParameter(@PPSVariantData(tmp)^.Data, @_EDX, cpt, lCopied);
            inc(regno);
          end;
        1: begin
            CopyNativeParameter(@PPSVariantData(tmp)^.Data, @_ECX, cpt, lCopied);
            inc(regno);
          end;
      end;
    end;
  end;
  s := decl;
  e := grfw(s);

  if e <> '-1' then
  begin
    cpt := Self.Se.GetTypeNo(StrToInt(e));
    if not ResultAsRegister(cpt) then
    begin
      case regno of
        0: lResultDest := Pointer(_EDX);
        1: lResultDest := Pointer(_ECX);
      else
        lResultDest := Pointer(FStack^);
        Inc(Result, PointerSize);
        FStack := Pointer(IPointer(FStack) + PointerSize);
      end;
      if cpt.BaseType = btProcPtr then
        { the caller's result is a method: the script's procedural value is
          made apart and stored as a method after the call }
        Res := CreateHeapVariant(cpt)
      else
      begin
        Res := CreateHeapVariant(Self.Se.FindType2(btPointer));
        PPSVariantPointer(Res).DestType := cpt;
        PPSVariantPointer(Res).DataDest := lResultDest;
      end;
      Params.Add(Res);
    end else
    begin
      Res := CreateHeapVariant(cpt);
      Params.Add(Res);
    end;
  end else Res := nil;
  s := decl;
  grfw(s);
  for i := 0 to c -1 do
  begin
    e := grlw(s);
    fmod := e[1];
    delete(e, 1, 1);
    if Params[i] <> nil then Continue;
    cpt := Self.Se.GetTypeNo(StrToInt(e));
    if cpt.BaseType = btProcPtr then
    begin
      if MethodByReference(fmod) then
      begin
        Params[i] := MethodParameter(Self.Se, fmod, cpt, Pointer(FStack^), Params, lWriteBacks, i);
        FStack := Pointer(IPointer(FStack) + PointerSize);
        Inc(Result, PointerSize);
      end else
      begin
        { the method's two slots, on the stack }
        Params[i] := MethodParameter(Self.Se, fmod, cpt, FStack, Params, lWriteBacks, i);
        FStack := Pointer(IPointer(FStack) + SizeOf(TMethod));
        Inc(Result, SizeOf(TMethod));
      end;
    end
    else if ParamAsVariable(fmod, cpt) then
    begin
      Params[i] := NativeReferenceParameter(Self.Se, fmod, cpt, Pointer(FStack^), lCopied);
      FStack := Pointer(IPointer(FStack) + PointerSize);
      Inc(Result, PointerSize);
    end
(*    else if SupportsRegister(cpt) then
    begin
      tmp := CreateHeapVariant(cpt);
      Params[i] := tmp;
      CopyArrayContents(@PPSVariantData(tmp)^.Data, Pointer(FStack), 1, cpt);
      FStack := Pointer(IPointer(FStack) + 4);
      end;
    end *)else
    begin
      tmp := CreateHeapVariant(cpt);
      Params[i] := tmp;
      CopyNativeParameter(@PPSVariantData(tmp)^.Data, Pointer(FStack), cpt, lCopied);
      FStack := Pointer((IPointer(FStack) + cpt.RealSize + 3) and not 3);
      Inc(Result, (cpt.RealSize + 3) and not 3);
    end;
  end;
  if not lCopied then
    RefuseNativeParameters(Params);
  ex := TPSExceptionHandler.Create;
  ex.FinallyOffset := InvalidVal;
  ex.ExceptOffset := InvalidVal;
  ex.Finally2Offset := InvalidVal;
  ex.EndOfBlock := InvalidVal;
  ex.CurrProc := nil;
  ex.BasePtr := Self.Se.FCurrStackBase;
  Ex.StackSize := Self.Se.FStack.Count;
  i :=  Self.Se.FExceptionStack.Add(ex);
  { where the interpreter stands while the native code runs the script }
  lPosition := Self.Se.FCurrentPosition;
  lStackBase := Self.Se.FCurrStackBase;
  lRaised := Self.Se.FRaisedCount;
  Self.Se.RunProc(Params, Self.ProcNo);
  if Self.Se.FExceptionStack[i] = ex then
  begin
    Self.Se.FExceptionStack.Remove(ex);
    ex.Free;
  end else
  begin
    { the script's exception ended the call at this frame, below the return
      address: the interpreter is back where the native code called it }
    Self.Se.FCurrentPosition := lPosition;
    Self.Se.FCurrStackBase := lStackBase;
  end;

  StoreMethodParameters(Self.Se, Params, lWriteBacks);
  if (Res <> nil) then
  begin
    Params.DeleteLast;
    if (ResultAsRegister(Res.FType)) then
    begin
      if (res^.FType.BaseType = btSingle) or (res^.FType.BaseType = btDouble) or
      (res^.FType.BaseType = btCurrency) or (res^.Ftype.BaseType = btExtended) then
      begin
        { kept for MyAllMethodsHandler32, which puts it on the x87 stack once
          this routine has returned, after every release here.  As its bytes:
          a failed call raises below and its result goes nowhere, so nothing
          may load what the script left there -- a signalling NaN would raise
          in place of the script's exception }
        aKind := Res^.FType.BaseType;
        Move(PPSVariantData(Res)^.Data, aResult, Res^.FType.RealSize);
        DestroyHeapVariant(Res);
        Res := nil;
      end else
      begin
{$IF defined(DELPHI) or (defined(FPC) and defined(CPUI386))}
        CopyArrayContents(ResPtr, @PPSVariantData(res)^.Data, 1, Res^.FType);
{$ELSE}
{$IFNDEF PS_NOINT64}
  if (res^.FType.BaseType <> btS64) and (res^.FType.BaseType <> btU64) then
{$ENDIF}
          CopyArrayContents(Pointer(IPointer(Stack)-PointerSize2), @PPSVariantData(res)^.Data, 1, Res^.FType);
{$IFEND}
      end;
    end else if (Res^.FType.BaseType = btProcPtr) and (Self.Se.ExEx = erNoError) then
      TMethod(lResultDest^) := ProcPtrToMethod(Self.Se, @PPSVariantData(Res)^.Data);
    DestroyHeapVariant(res);
  end;
  for i := 0 to Params.Count -1 do
    DestroyHeapVariant(Params[i]);
  Params.Free;
  if Self.Se.ExEx <> erNoError then
  begin
    { the exception goes to the native code, which may handle it and go on:
      the executor holds it no longer, and counts it again only if the
      native code lets it come back }
    if Self.Se.ExObject <> nil then
    begin
      FStack := Self.Se.ExObject;
      Self.Se.ExObject := nil;
    end else
      FStack := EPSException.Create(PSErrorToString(Self.SE.ExceptionCode, Self.Se.ExceptionString), Self.Se, Self.Se.ExProc, Self.Se.ExPos);
    Self.Se.ExceptionProc(InvalidVal, InvalidVal, erNoError, '', nil);
    Self.Se.FRaisedCount := lRaised;
    raise TObject(FStack);
  end;
end;

{ Native code calling a script routine through a method pointer, from the stub
  MyAllMethodsHandler.  A real result goes on the x87 stack as the last act:
  this routine holds nothing to release after it, so code a release reaches --
  a memory manager -- does not meet the result on the x87 stack }
function MyAllMethodsHandler32(Self: PScriptMethodInfo; const Stack: PPointer; _EDX, _ECX: Pointer{$IF defined(DELPHI) or (defined(FPC) and defined(CPUI386))}; ResPtr: Pointer{$IFEND}): Integer;
var
  lKind: TPSBaseType;
  lResult: TPSMethodRealResult;
begin
  { btReturnAddress, the type of no result: none to put there }
  lKind := btReturnAddress;
  Result := _MethodsHandler32Call(Self, Stack, _EDX, _ECX{$IF defined(DELPHI) or (defined(FPC) and defined(CPUI386))}, ResPtr{$IFEND}, lKind, lResult);
  { Currency is returned on the FPU stack as its scaled integer backing (FILD), not its logical value }
  case lKind of
    btSingle: PutOnFPUStackExtended(lResult.VSingle);
    btDouble: PutOnFPUStackExtended(lResult.VDouble);
    btExtended: PutOnFPUStackExtended(lResult.VExtended);
    btCurrency: PutOnFPUStackCurrency(lResult.VCurrency);
  end;
end;
{$ENDIF CPU64}
{$endif empty_methods_handler}

function TPSRuntimeClassImporter.FindClass(const Name: tbtString): TPSRuntimeClass;
var
  h, i: Longint;
  lName: tbtstring;
  p: TPSRuntimeClass;
begin
  lName := FastUpperCase(Name);
  h := MakeHash(lName);
  for i := FClasses.Count -1 downto 0 do
  begin
    p := FClasses[i];
    if (p.FClassNameHash = h) and (p.FClassName = lName) then
    begin
      Result := P;
      exit;
    end;
  end;
  Result := nil;
end;

function DelphiFunctionProc(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack; CC: TPSCallingConvention): Boolean;
var
  i: Integer;
  MyList: TPSList;
  n: PPSVariantIFC;
  CurrStack: Cardinal;
  s: tbtString;
begin
  s := P.Decl;
  if length(s) = 0 then begin Result := False; exit; end;
  CurrStack := Cardinal(Stack.Count) - Cardinal(length(s));
  if s[1] = #0 then inc(CurrStack);
  MyList := TPSList.Create;

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
    n := NewPPSVariantIFC(Stack[CurrStack], True);
  end else n := nil;
  try
    result := Caller.InnerfuseCall(p.Ext2, p.Ext1, cc, MyList, n);
  finally
    DisposePPSVariantIFC(n);
    DisposePPSVariantIFCList(mylist);
  end;
end;

function DelphiFunctionProc_CDECL(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
begin
  Result := DelphiFunctionProc(Caller, p, Global, Stack, cdCdecl);
end;
function DelphiFunctionProc_Register(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
begin
  Result := DelphiFunctionProc(Caller, p, Global, Stack, cdRegister);
end;
function DelphiFunctionProc_Pascal(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
begin
  Result := DelphiFunctionProc(Caller, p, Global, Stack, cdPascal);
end;
function DelphiFunctionProc_Stdcall(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
begin
  Result := DelphiFunctionProc(Caller, p, Global, Stack, cdStdCall);
end;
function DelphiFunctionProc_Safecall(Caller: TPSExec; p: TPSExternalProcRec; Global, Stack: TPSStack): Boolean;
begin
  Result := DelphiFunctionProc(Caller, p, Global, Stack, cdSafeCall);
end;

procedure TPSExec.RegisterDelphiFunction(ProcPtr: Pointer;
  const Name: tbtString; CC: TPSCallingConvention);
begin
  RegisterDelphiMethod(nil, ProcPtr, FastUppercase(Name), CC);
end;

procedure TPSExec.RegisterDelphiMethod(Slf, ProcPtr: Pointer;
  const Name: tbtString; CC: TPSCallingConvention);
begin
  case cc of
    cdRegister: RegisterFunctionName(FastUppercase(Name), DelphiFunctionProc_Register, ProcPtr, Slf);
    cdPascal: RegisterFunctionName(FastUppercase(Name), DelphiFunctionProc_Pascal, ProcPtr, Slf);
    cdStdCall: RegisterFunctionName(FastUppercase(Name), DelphiFunctionProc_Stdcall, ProcPtr, Slf);
    cdSafeCall: RegisterFunctionName(FastUppercase(Name), DelphiFunctionProc_Safecall, ProcPtr, Slf);
    cdCdecl: RegisterFunctionName(FastUppercase(Name), DelphiFunctionProc_CDECL, ProcPtr, Slf);
  end;
end;

{ EPSException }

constructor EPSException.Create(const Error: tbtString; Exec: TPSExec;
  Procno, ProcPos: Cardinal);
begin
 inherited Create(string(Error));
 FExec := Exec;
 FProcNo := Procno;
 FProcPos := ProcPos;
end;

{ TPSRuntimeAttribute }

function TPSRuntimeAttribute.AddValue(aType: TPSTypeRec): PPSVariant;
begin
  Result := FValues.PushType(aType);
end;

procedure TPSRuntimeAttribute.AdjustSize;
begin
  FValues.Capacity := FValues.Length;
end;

constructor TPSRuntimeAttribute.Create(Owner: TPSRuntimeAttributes);
begin
  inherited Create;
  FOwner := Owner;
  FValues := TPSStack.Create;
end;

procedure TPSRuntimeAttribute.DeleteValue(i: Longint);
begin
  if Cardinal(i) <> Cardinal(FValues.Count -1) then
    raise Exception.Create(RPS_CanOnlySendLastItem);
  FValues.Pop;
end;

destructor TPSRuntimeAttribute.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

function TPSRuntimeAttribute.GetValue(I: Longint): PIFVariant;
begin
  Result := FValues[i];
end;

function TPSRuntimeAttribute.GetValueCount: Longint;
begin
  Result := FValues.Count;
end;

{ TPSRuntimeAttributes }

function TPSRuntimeAttributes.Add: TPSRuntimeAttribute;
begin
  Result := TPSRuntimeAttribute.Create(Self);
  FAttributes.Add(Result);
end;

constructor TPSRuntimeAttributes.Create(AOwner: TPSExec);
begin
  inherited Create;
  FAttributes := TPSList.Create;
  FOwner := AOwner;
end;

procedure TPSRuntimeAttributes.Delete(I: Longint);
begin
  TPSRuntimeAttribute(FAttributes[i]).Free;
  FAttributes.Delete(i);
end;

destructor TPSRuntimeAttributes.Destroy;
var
  i: Longint;
begin
  for i := FAttributes.Count -1 downto 0 do
    TPSRuntimeAttribute(FAttributes[i]).Free;
  FAttributes.Free;
  inherited Destroy;
end;

function TPSRuntimeAttributes.FindAttribute(
  const Name: tbtString): TPSRuntimeAttribute;
var
  n: tbtString;
  i, h: Longint;
begin
  n := FastUpperCase(Name);
  h := MakeHash(n);
  for i := 0 to FAttributes.Count -1 do
  begin
    Result := FAttributes[i];
    if (Result.AttribTypeHash = h) and (Result.AttribType = n) then
      exit;
  end;
  Result := nil;
end;

function TPSRuntimeAttributes.GetCount: Longint;
begin
   Result := FAttributes.Count;
end;

function TPSRuntimeAttributes.GetItem(I: Longint): TPSRuntimeAttribute;
begin
  Result := FAttributes[i];
end;

{ TPSInternalProcRec }

destructor TPSInternalProcRec.Destroy;
begin
  if FData <> nil then
    Freemem(Fdata, FLength);
  inherited Destroy;
end;

{ TPsProcRec }

constructor TPSProcRec.Create(Owner: TPSExec);
begin
  inherited Create;
  FAttributes := TPSRuntimeAttributes.Create(Owner);
end;

destructor TPSProcRec.Destroy;
begin
  FAttributes.Free;
  inherited Destroy;
end;

{ TPSTypeRec_Array }

procedure TPSTypeRec_Array.CalcSize;
begin
  FrealSize := PointerSize;
end;

{ TPSTypeRec_StaticArray }

procedure TPSTypeRec_StaticArray.CalcSize;
begin
  FrealSize := Cardinal(FArrayType.RealSize) * Cardinal(Size);
end;

{ TPSTypeRec_Set }

procedure TPSTypeRec_Set.CalcSize;
begin
  FrealSize := FByteSize;
end;

const
  MemDelta = 4096;

type
  PPSStackChunk = ^TPSStackChunk;
  TPSStackChunk = record
    Data: Pointer;
    Capacity: Longint;
    Length: Longint; { the length in use when the next chunk was begun }
  end;

{ The chunks from aFrom on, freed }
procedure _FreeStackChunks(var aChunks: array of Pointer; var aCount: Longint; aFrom: Longint);
var
  lChunk: PPSStackChunk;
begin
  while aCount > aFrom do
  begin
    Dec(aCount);
    lChunk := aChunks[aCount];
    aChunks[aCount] := nil;
    FreeMem(lChunk.Data);
    Dispose(lChunk);
  end;
end;

{ TPSStack }

procedure TPSStack.AdjustLength;
{ Only grows, never shrinks }
var
  MyLen: Longint;
begin
  MyLen := ((FLength shr 12) + 1) shl 12;
  if fCapacity < MyLen then
    SetCapacity(((MyLen + MemDelta) div MemDelta) * MemDelta);
end;

procedure TPSStack.Clear;
var
  v: Pointer;
  i: Longint;
begin
  for i := Count -1 downto 0 do
  begin
    v := Data[i];
    if TPSTypeRec(v^).BaseType in NeedFinalization then
      FinalizeVariant(Pointer(IPointer(v)+PointerSize), TPSTypeRec(v^));
  end;
  inherited Clear;
  FLength := 0;
  SetCapacity(0);
end;

constructor TPSStack.Create;
begin
  inherited Create;
  GetMem(FDataPtr, MemDelta);
  FCapacity := MemDelta;
  FLength := 0;
end;

destructor TPSStack.Destroy;
var
  v: Pointer;
  i: Longint;
begin
  for i := Count -1 downto 0 do
  begin
    v := Data[i];
    if TPSTypeRec(v^).BaseType in NeedFinalization then
    FinalizeVariant(Pointer(IPointer(v)+PointerSize), Pointer(v^));
  end;
  if FChunked then
    _FreeStackChunks(FChunks, FChunkCount, 0)
  else
    FreeMem(FDataPtr, FCapacity);
  _FreeStackChunks(FRetired, FRetiredCount, 0);
  inherited Destroy;
end;

function TPSStack.GetBool(ItemNo: Longint): Boolean;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := Items[Longint(ItemNo) + Longint(Count)]
  else
    val := Items[ItemNo];
  Result := PSGetUInt(@PPSVariantData(val).Data, val.FType) <> 0;
end;

function TPSStack.GetClass(ItemNo: Longint): TObject;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := Items[Longint(ItemNo) + Longint(Count)]
  else
    val := Items[ItemNo];
  Result := PSGetObject(@PPSVariantData(val).Data, val.FType);
end;

function TPSStack.GetCurrency(ItemNo: Longint): Currency;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := Items[Longint(ItemNo) + Longint(Count)]
  else
    val := Items[ItemNo];
  Result := PSGetCurrency(@PPSVariantData(val).Data, val.FType);
end;

function TPSStack.GetInt(ItemNo: Longint): Longint;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetInt(@PPSVariantData(val).Data, val.FType);
end;

{$IFNDEF PS_NOINT64}
function TPSStack.GetInt64(ItemNo: Longint): Int64;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetInt64(@PPSVariantData(val).Data, val.FType);
end;

function TPSStack.GetUInt64(ItemNo: Longint): UInt64;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetUInt64(@PPSVariantData(val).Data, val.FType);
end;
{$ENDIF}

function TPSStack.GetItem(I: Longint): PPSVariant;
begin
  if Cardinal(I) >= Cardinal(Count) then
    Result := nil
  else
    Result := Data[i];
end;

function TPSStack.GetReal(ItemNo: Longint): Extended;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetreal(@PPSVariantData(val).Data, val.FType);
end;

function TPSStack.GetAnsiString(ItemNo: Longint): tbtString;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetAnsiString(@PPSVariantData(val).Data, val.FType);
end;

function TPSStack.GetString(ItemNo: Longint): string; // calls the native method
begin
  result := {$IFNDEF PS_NOWIDESTRING}{$IFDEF DELPHI2009UP}GetUnicodeString(ItemNo){$ELSE}GetAnsiString(ItemNo){$ENDIF}{$ELSE}GetAnsiString(ItemNo){$ENDIF};
end;

function TPSStack.GetUInt(ItemNo: Longint): Cardinal;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetUInt(@PPSVariantData(val).Data, val.FType);
end;

{$IFNDEF PS_NOWIDESTRING}
function TPSStack.GetUnicodeString(ItemNo: Integer): tbtunicodestring;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetUnicodeString(@PPSVariantData(val).Data, val.FType);
end;

function TPSStack.GetWideString(ItemNo: Longint): tbtWideString;
var
  val: PPSVariant;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  Result := PSGetWideString(@PPSVariantData(val).Data, val.FType);
end;
{$ENDIF}

procedure TPSStack.Pop;
var
  p1: Pointer;
  c: Longint;
begin
  c := count -1;
  p1 := Data[c];
  DeleteLast;
  { finalized while its storage is still the stack's: what the finalization
    runs (a native destructor running a script event) pushes above it }
  try
    if TPSTypeRec(p1^).BaseType in NeedFinalization then
      FinalizeVariant(Pointer(IPointer(p1)+PointerSize), Pointer(p1^));
  finally
    if FChunked and (p1 = FDataPtr) and (FChunkIdx > 0) then
    begin
      { the chunk's first value: the stack goes on in the chunk before it, where
        it stood when this one was begun }
      Dec(FChunkIdx);
      FDataPtr := PPSStackChunk(FChunks[FChunkIdx]).Data;
      FCapacity := PPSStackChunk(FChunks[FChunkIdx]).Capacity;
      FLength := PPSStackChunk(FChunks[FChunkIdx]).Length;
    end
    else
      FLength := IPointer(p1) - IPointer(FDataPtr);
  end;
end;

function TPSStack.Push(TotalSize: Longint): PPSVariant;
var
  o: Cardinal;
  p: Pointer;
  lSize: Longint;
begin
  { the stack's length and capacity are Longints: a size that would carry them past it allocated nothing,
    and the value was then initialised past the stack }
  if (TotalSize < 0) or (Int64(FLength) + TotalSize > High(Longint) - 3 * MemDelta) then
    raise Exception.Create(RPS_OutOfMemory);
  { the value's slot in the list first: when the list cannot grow, nothing has
    changed, and when the data cannot, the slot is given back }
  Add(nil);
  o := FLength;
  try
    FLength := (FLength + TotalSize);
    if FLength mod Longint(PointerSize) <> 0 then
      FLength := FLength + (Longint(PointerSize) - Longint((FLength mod Longint(PointerSize))));
    if FLength > FCapacity then
    begin
      if FChunked then
      begin
        { the value goes at the start of the next chunk: the data on the stack
          does not move }
        lSize := FLength - Longint(o);
        FLength := Longint(o);
        NextChunk(lSize);
        o := 0;
        FLength := lSize;
      end
      else
        AdjustLength;
    end;
  except
    FLength := Longint(o);
    DeleteLast;
    raise;
  end;
  p := Pointer(IPointer(FDataPtr) + IPointer(o));
  Data^[Count - 1] := p;
  Result := P;
end;

function TPSStack.PushType(aType: TPSTypeRec): PPSVariant;
begin
  if Int64(aType.RealSize) + SizeOf(Pointer) > High(Longint) then
    raise Exception.Create(RPS_OutOfMemory);
  Result := Push(aType.RealSize + Sizeof(Pointer));
  Result.FType := aType;
  InitializeVariant(Pointer(IPointer(Result)+PointerSize), aType);
end;

procedure TPSStack.SetBool(ItemNo: Longint; const Data: Boolean);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  if Data then
    PSSetUInt(@PPSVariantData(val).Data, val.FType, ok, 1)
  else
    PSSetUInt(@PPSVariantData(val).Data, val.FType, ok, 0);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

procedure TPSStack.SetCapacity(const Value: Longint);
var
  p: Pointer;
  OOFS: IPointer;
  I: Longint;
begin
  if Value < FLength then raise Exception.Create(RPS_CapacityLength);
  if FChunked then
  begin
    { the chunks hold the data, and Push adds them: clearing the stack releases
      them -- kept while a native call runs, which may still write where its
      arguments were }
    if Value = 0 then
    begin
      if FNativeCalls > 0 then
      begin
        if FRetiredCount + FChunkCount > High(FRetired) + 1 then
          SetLength(FRetired, FRetiredCount + FChunkCount);
        for I := 0 to FChunkCount - 1 do
        begin
          FRetired[FRetiredCount] := FChunks[I];
          Inc(FRetiredCount);
          FChunks[I] := nil;
        end;
        FChunkCount := 0;
      end
      else
        _FreeStackChunks(FChunks, FChunkCount, 0);
      FChunkIdx := -1;
      FDataPtr := nil;
      FCapacity := 0;
    end;
    Exit;
  end;
  if Value = 0 then
  begin
    if FDataPtr <> nil then
    begin
      FreeMem(FDataPtr, FCapacity);
      FDataPtr := nil;
    end;
    FCapacity := 0;
    Exit;
  end;
  GetMem(p, Value);
  if FDataPtr <> nil then
  begin
    if FLength > FCapacity then
      OOFS := FCapacity
    else
      OOFS := FLength;
    Move(FDataPtr^, p^, OOFS);
    OOFS := IPointer(P) - IPointer(FDataPtr);

    for i := Count -1 downto 0 do begin
      { the slot a push has taken holds nil until its value's address is known }
      if Data[i] = nil then
        Continue;
      Data[i] := Pointer(IPointer(Data[i]) + OOFS);
      if Items[i].FType.FBaseType = btPointer then begin // check if pointer points to moved stack data
        if (IPointer(PPSVariantPointer(Data[i]).DataDest) >= IPointer(FDataPtr)) and
           (IPointer(PPSVariantPointer(Data[i]).DataDest) <  IPointer(FDataPtr)+IPointer(FCapacity)) then
          PPSVariantPointer(Data[i]).DataDest := Pointer(IPointer(PPSVariantPointer(Data[i]).DataDest) + OOFS);
      end;
    end;

    FreeMem(FDataPtr, FCapacity);
  end;
  FDataPtr := p;
  FCapacity := Value;
end;

procedure TPSStack.UseChunks;
var
  lChunk: PPSStackChunk;
begin
  if FChunked then
    Exit;
  SetLength(FChunks, 4);
  FChunkCount := 0;
  FChunkIdx := -1;
  if FDataPtr <> nil then
  begin
    New(lChunk);
    lChunk.Data := FDataPtr;
    lChunk.Capacity := FCapacity;
    lChunk.Length := 0;
    FChunks[0] := lChunk;
    FChunkCount := 1;
    FChunkIdx := 0;
  end;
  { last: until here the block is still the stack's own, and Destroy frees it }
  FChunked := True;
end;

{ A value of aSize bytes does not fit in the chunk in use: it goes at the start
  of the next one -- a spare one kept from before when it is large enough -- and
  the values already on the stack stay where they are }
procedure TPSStack.NextChunk(aSize: Longint);
var
  lChunk: PPSStackChunk;
  lCapacity: Longint;
begin
  if (FChunkIdx + 1 < FChunkCount) and
    (PPSStackChunk(FChunks[FChunkIdx + 1]).Capacity < aSize) then
    _FreeStackChunks(FChunks, FChunkCount, FChunkIdx + 1);
  if FChunkIdx + 1 >= FChunkCount then
  begin
    if FChunkCount = 0 then
      lCapacity := MemDelta
    else if PPSStackChunk(FChunks[FChunkCount - 1]).Capacity > 128 * MemDelta then
      lCapacity := 256 * MemDelta
    else
      lCapacity := 2 * PPSStackChunk(FChunks[FChunkCount - 1]).Capacity;
    if lCapacity < aSize then
      lCapacity := ((aSize + MemDelta - 1) div MemDelta) * MemDelta;
    if FChunkCount > High(FChunks) then
      SetLength(FChunks, 2 * FChunkCount + 4);
    New(lChunk);
    try
      GetMem(lChunk.Data, lCapacity);
    except
      Dispose(lChunk);
      raise;
    end;
    lChunk.Capacity := lCapacity;
    lChunk.Length := 0;
    FChunks[FChunkCount] := lChunk;
    Inc(FChunkCount);
  end;
  if FChunkIdx >= 0 then
    PPSStackChunk(FChunks[FChunkIdx]).Length := FLength;
  Inc(FChunkIdx);
  lChunk := FChunks[FChunkIdx];
  FDataPtr := lChunk.Data;
  FCapacity := lChunk.Capacity;
  Assert(aSize <= FCapacity);
end;

procedure TPSStack.NativeCallStarts;
begin
  Inc(FNativeCalls);
end;

procedure TPSStack.NativeCallEnds;
begin
  Dec(FNativeCalls);
  if FNativeCalls = 0 then
    _FreeStackChunks(FRetired, FRetiredCount, 0);
end;

procedure TPSStack.SetClass(ItemNo: Longint; const Data: TObject);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetObject(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

procedure TPSStack.SetCurrency(ItemNo: Longint; const Data: Currency);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetCurrency(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

procedure TPSStack.SetInt(ItemNo: Longint; const Data: Longint);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetInt(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

{$IFNDEF PS_NOINT64}
procedure TPSStack.SetInt64(ItemNo: Longint; const Data: Int64);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetInt64(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

procedure TPSStack.SetUInt64(ItemNo: Longint; const Data: UInt64);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetUInt64(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;
{$ENDIF}

procedure TPSStack.SetReal(ItemNo: Longint; const Data: Extended);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetReal(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

procedure TPSStack.SetAnsiString(ItemNo: Longint; const Data: tbtString);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetAnsiString(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

procedure TPSStack.SetString(ItemNo: Longint; const Data: string);
begin
  {$IFNDEF PS_NOWIDESTRING}
    {$IFDEF DELPHI2009UP}
    SetUnicodeString(ItemNo, Data);
    {$ELSE}
    SetAnsiString(ItemNo, Data);
    {$ENDIF}
  {$ELSE}
  SetAnsiString(ItemNo, Data);
  {$ENDIF}
end;


procedure TPSStack.SetUInt(ItemNo: Longint; const Data: Cardinal);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetUInt(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;


{$IFNDEF PS_NOWIDESTRING}
procedure TPSStack.SetUnicodeString(ItemNo: Integer;
  const Data: tbtunicodestring);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetUnicodeString(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;

procedure TPSStack.SetWideString(ItemNo: Longint;
  const Data: tbtWideString);
var
  val: PPSVariant;
  ok: Boolean;
begin
  if ItemNo < 0 then
    val := items[Longint(ItemNo) + Longint(Count)]
  else
    val := items[ItemNo];
  ok := true;
  PSSetWideString(@PPSVariantData(val).Data, val.FType, ok, Data);
  if not ok then raise Exception.Create(RPS_TypeMismatch);
end;
{$ENDIF}


{$IFNDEF PS_NOIDISPATCH}
var
  DispPropertyPut: Integer = DISPID_PROPERTYPUT;
const
  LOCALE_SYSTEM_DEFAULT = 2 shl 10; // Delphi 2 doesn't define this

{ the work of IDispatchInvoke, into aResult, which it is handed empty }
procedure _IDispatchInvokeInto(const Self: IDispatch; PropertySet: Boolean; const Name: tbtString;
  const Par: array of Variant; var aResult: Variant);
var
  Param: Word;
  i, ArgErr: Longint;
  DispatchId: Longint;
  DispParam: TDispParams;
  ExceptInfo: TExcepInfo;
  aName: PWideChar;
  WSFreeList: TPSList;
begin
  if Self = nil then begin
    raise EPSException.Create('Variant is null, cannot invoke', nil, 0, 0);
  end;
  FillChar(ExceptInfo, SizeOf(ExceptInfo), 0);
  if Name='' then begin
   DispatchId:=0;
  end else begin
   aName := StringToOleStr(Name);
   try
     if Self = nil then
      raise Exception.Create(RPS_NILInterfaceException);
     if Self.GetIDsOfNames(GUID_NULL, @aName, 1, LOCALE_SYSTEM_DEFAULT, @DispatchId) <> S_OK then
      raise Exception.Create(RPS_UnknownMethod);
   finally
     SysFreeString(aName);
   end;
  end;
  DispParam.cNamedArgs := 0;
  DispParam.rgdispidNamedArgs := nil;
  DispParam.cArgs := (High(Par) + 1);

  if PropertySet then
  begin
    if High(Par) < 0 then
      raise Exception.Create(RPS_InvalidParameter);
    Param := DISPATCH_PROPERTYPUT;
    DispParam.cNamedArgs := 1;
    DispParam.rgdispidNamedArgs := @DispPropertyPut;
  end else
    Param := DISPATCH_METHOD or DISPATCH_PROPERTYGET;

  WSFreeList := TPSList.Create;
  try
    GetMem(DispParam.rgvarg, sizeof(TVariantArg) * (High(Par) + 1));
    FillCHar(DispParam.rgvarg^, sizeof(TVariantArg) * (High(Par) + 1), 0);
    try
      for i := 0 to High(Par)  do
      begin
        if PVarData(@Par[High(Par)-i]).VType = varString then
        begin
          DispParam.rgvarg[i].vt := VT_BSTR;
          DispParam.rgvarg[i].bstrVal := StringToOleStr(AnsiString(Par[High(Par)-i]));
          WSFreeList.Add(DispParam.rgvarg[i].bstrVal);
        {$IFDEF UNICODE}
        end else if (PVarData(@Par[High(Par)-i]).VType = varOleStr) or (PVarData(@Par[High(Par)-i]).VType = varUString) then
        begin
          DispParam.rgvarg[i].vt := VT_BSTR;
          DispParam.rgvarg[i].bstrVal := StringToOleStr(UnicodeString(Par[High(Par)-i]));
          WSFreeList.Add(DispParam.rgvarg[i].bstrVal);
        {$ENDIF}
        end else
        begin
          DispParam.rgvarg[i].vt := VT_VARIANT or VT_BYREF;
          New(
          {$IFDEF DELPHI4UP}
          POleVariant
          {$ELSE}
          PVariant{$ENDIF}
           (DispParam.rgvarg[i].pvarVal));

          { Must be an owned copy because the Dispose below releases it.
            PVariant does not convert the type, unlike POleVariant. }
          PVariant(DispParam.rgvarg[i].pvarVal)^ := Par[High(Par)-i];
        end;
      end;
      i :=Self.Invoke(DispatchId, GUID_NULL, LOCALE_SYSTEM_DEFAULT, Param, DispParam, @aResult, @ExceptInfo, @ArgErr);
      {$IFNDEF Delphi3UP}
      try
       if not Succeeded(i) then
       begin
         if i = DISP_E_EXCEPTION then
           raise Exception.Create(OleStrToString(ExceptInfo.bstrSource)+': '+OleStrToString(ExceptInfo.bstrDescription))
         else
           raise Exception.Create(SysErrorMessage(i));
       end;
      finally
        SysFreeString(ExceptInfo.bstrSource);
        SysFreeString(ExceptInfo.bstrDescription);
        SysFreeString(ExceptInfo.bstrHelpFile);
      end;
      {$ELSE}
       if not Succeeded(i) then
       begin
         if i = DISP_E_EXCEPTION then
           {$IFDEF FPC}
           raise Exception.Create(ExceptInfo.Source+': '+ExceptInfo.Description)
           {$ELSE}
           raise Exception.Create(ExceptInfo.bstrSource+': '+ExceptInfo.bstrDescription)
           {$ENDIF}
         else
           raise Exception.Create(SysErrorMessage(i));
       end;
      {$ENDIF}
    finally
      for i := 0 to High(Par)  do
      begin
        if DispParam.rgvarg[i].vt = (VT_VARIANT or VT_BYREF) then
        begin
          if{$IFDEF DELPHI4UP}POleVariant{$ELSE}PVariant{$ENDIF}
            (DispParam.rgvarg[i].pvarVal) <> nil then
            Dispose(
            {$IFDEF DELPHI4UP}
             POleVariant
            {$ELSE}
             PVariant
            {$ENDIF}
             (DispParam.rgvarg[i].pvarVal));
        end;
      end;
      FreeMem(DispParam.rgvarg, sizeof(TVariantArg) * (High(Par) + 1));
    end;
  finally
    for i := WSFreeList.Count -1 downto 0 do
      SysFreeString(WSFreeList[i]);
    WSFreeList.Free;
  end;
end;

function IDispatchInvoke(Self: IDispatch; PropertySet: Boolean; const Name: tbtString; const Par: array of Variant): Variant;
var
  lResult: Variant;
begin
  try
    _IDispatchInvokeInto(Self, PropertySet, Name, Par, lResult);
  finally
    { written only now, and on every road out -- a raise included, as Delphi's
      late binding does: releasing what the destination holds can run a script
      event, which can free the container it lies in }
    MoveIntoVariant(@Result, lResult);
  end;
end;
{$ENDIF}


{ TPSTypeRec_ProcPtr }

procedure TPSTypeRec_ProcPtr.CalcSize;
begin
  FRealSize := 3 * sizeof(Pointer);
end;

end.

