unit uROPSImports;

{$IFDEF MSWINDOWS}
{$I ..\..\Source\PascalScript.inc}
{$ELSE}
{$I ../../Source/PascalScript.inc}
{$ENDIF}

interface

uses
  uPSCompiler, uPSRuntime, uROBINMessage, uROIndyHTTPChannel,
  uROXMLSerializer, uROIndyTCPChannel, idTcpClient,
  uROPSServerLink, uROWinInetHttpChannel;


procedure SIRegisterTROBINMESSAGE(CL: TIFPSPascalCompiler);
procedure SIRegisterTROINDYHTTPCHANNEL(CL: TIFPSPascalCompiler);
procedure SIRegisterTROINDYTCPCHANNEL(CL: TIFPSPascalCompiler);
procedure SIRegisterTIDTCPCLIENT(CL: TIFPSPascalCompiler);
procedure SIRegisterRODLImports(Cl: TIFPSPascalCompiler);



procedure RIRegisterTROBINMESSAGE(Cl: TIFPSRuntimeClassImporter);
procedure RIRegisterTROINDYHTTPCHANNEL(Cl: TIFPSRuntimeClassImporter);
procedure RIRegisterTROINDYTCPCHANNEL(Cl: TIFPSRuntimeClassImporter);
procedure RIRegisterTIDTCPCLIENT(Cl: TIFPSRuntimeClassImporter);
procedure RIRegisterRODLImports(CL: TIFPSRuntimeClassImporter);
(*
Todo:
     TROWinInetHTTPChannel = class(TROTransportChannel, IROTransport, IROTCPTransport, IROHTTPTransport)
     published
       property UserAgent:string read GetUserAgent write SetUserAgent;
       property TargetURL : string read fTargetURL write SetTargetURL;
       property StoreConnected:boolean read fStoreConnected write fStoreConnected default false;
       property KeepConnection:boolean read fKeepConnection write fKeepConnection default false;
     end;
*)
type
  
  TPSROIndyTCPModule = class(TPSROModule)
  protected
    class procedure ExecImp(exec: TIFPSExec; ri: TIFPSRuntimeClassImporter); override;
    class procedure CompImp(comp: TIFPSPascalCompiler); override;
  end;
  
  TPSROIndyHTTPModule = class(TPSROModule)
  protected
    class procedure ExecImp(exec: TIFPSExec; ri: TIFPSRuntimeClassImporter); override;
    class procedure CompImp(comp: TIFPSPascalCompiler); override;
  end;
  
  TPSROBinModule = class(TPSROModule)
  protected
    class procedure ExecImp(exec: TIFPSExec; ri: TIFPSRuntimeClassImporter); override;
    class procedure CompImp(comp: TIFPSPascalCompiler); override;
  end;


implementation

{procedure TROSOAPMESSAGESERIALIZATIONOPTIONS_W(Self: TROSOAPMESSAGE;
  const T: TXMLSERIALIZATIONOPTIONS);
begin 
  Self.SERIALIZATIONOPTIONS := T; 
end;

procedure TROSOAPMESSAGESERIALIZATIONOPTIONS_R(Self: TROSOAPMESSAGE;
  var T: TXMLSERIALIZATIONOPTIONS);
begin 
  T := Self.SERIALIZATIONOPTIONS; 
end;

procedure TROSOAPMESSAGECUSTOMLOCATION_W(Self: TROSOAPMESSAGE; const T: string);
begin 
  Self.CUSTOMLOCATION := T; 
end;

procedure TROSOAPMESSAGECUSTOMLOCATION_R(Self: TROSOAPMESSAGE; var T: string);
begin 
  T := Self.CUSTOMLOCATION; 
end;

procedure TROSOAPMESSAGELIBRARYNAME_W(Self: TROSOAPMESSAGE; const T: string);
begin 
  Self.LIBRARYNAME := T; 
end;

procedure TROSOAPMESSAGELIBRARYNAME_R(Self: TROSOAPMESSAGE; var T: string);
begin 
  T := Self.LIBRARYNAME; 
end; }

{$IFDEF DELPHI10UP}{$REGION 'TROBinMessage'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TROBinMessage_PSHelper = class helper for TROBinMessage
  public
    procedure USECOMPRESSION_W(const T: boolean);
    procedure USECOMPRESSION_R(var T: boolean);
  end;

procedure TROBinMessage_PSHelper.USECOMPRESSION_W(const T: boolean);
begin
  Self.USECOMPRESSION := T;
end;

procedure TROBinMessage_PSHelper.USECOMPRESSION_R(var T: boolean);
begin
  T := Self.USECOMPRESSION;
end;

procedure RIRegisterTROBINMESSAGE(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TROBINMESSAGE) do
  begin
    RegisterPropertyHelper(@TROBINMESSAGE.USECOMPRESSION_R,
      @TROBINMESSAGE.USECOMPRESSION_W, 'USECOMPRESSION');
  end;
end;

{$ELSE}
procedure TROBINMESSAGEUSECOMPRESSION_W(Self: TROBinMessage; const T: boolean);
begin
  Self.USECOMPRESSION := T;
end;

procedure TROBINMESSAGEUSECOMPRESSION_R(Self: TROBINMESSAGE; var T: boolean);
begin
  T := Self.USECOMPRESSION;
end;

procedure RIRegisterTROBINMESSAGE(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TROBINMESSAGE) do
  begin
    RegisterPropertyHelper(@TROBINMESSAGEUSECOMPRESSION_R,
      @TROBINMESSAGEUSECOMPRESSION_W, 'USECOMPRESSION');
  end;
end;

{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TROIndyHTTPChannel'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TROIndyHTTPChannel_PSHelper = class helper for TROIndyHTTPChannel
  public
    procedure TARGETURL_W(const T: string);
    procedure TARGETURL_R(var T: string);
  end;

procedure TROIndyHTTPChannel_PSHelper.TARGETURL_W(const T: string);
begin
  Self.TARGETURL := T;
end;

procedure TROIndyHTTPChannel_PSHelper.TARGETURL_R(var T: string);
begin
  T := Self.TARGETURL;
end;

procedure RIRegisterTROINDYHTTPCHANNEL(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TROINDYHTTPCHANNEL) do
  begin
    RegisterPropertyHelper(@TROINDYHTTPCHANNEL.TARGETURL_R,
      @TROINDYHTTPCHANNEL.TARGETURL_W, 'TARGETURL');
  end;
end;

{$ELSE}
procedure TROINDYHTTPCHANNELTARGETURL_W(Self: TROIndyHTTPChannel; const T: string);
begin
  Self.TARGETURL := T;
end;

procedure TROINDYHTTPCHANNELTARGETURL_R(Self: TROINDYHTTPCHANNEL; var T: string);
begin
  T := Self.TARGETURL;
end;

procedure RIRegisterTROINDYHTTPCHANNEL(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TROINDYHTTPCHANNEL) do
  begin
    RegisterPropertyHelper(@TROINDYHTTPCHANNELTARGETURL_R,
      @TROINDYHTTPCHANNELTARGETURL_W, 'TARGETURL');
  end;
end;

{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TROIndyTCPChannel'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TROIndyTCPChannel_PSHelper = class helper for TROIndyTCPChannel
  public
    procedure INDYCLIENT_R(var T: TIdTCPClientBaseClass);
  end;

procedure TROIndyTCPChannel_PSHelper.INDYCLIENT_R(var T: TIdTCPClientBaseClass);
begin
  T := Self.INDYCLIENT;
end;

procedure RIRegisterTROINDYTCPCHANNEL(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TROINDYTCPCHANNEL) do
  begin
    RegisterPropertyHelper(@TROINDYTCPCHANNEL.INDYCLIENT_R, nil, 'INDYCLIENT');
  end;
end;

{$ELSE}
procedure TROINDYTCPCHANNELINDYCLIENT_R(Self: TROIndyTCPChannel; var T: TIdTCPClientBaseClass);
begin
  T := Self.INDYCLIENT;
end;

procedure RIRegisterTROINDYTCPCHANNEL(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TROINDYTCPCHANNEL) do
  begin
    RegisterPropertyHelper(@TROINDYTCPCHANNELINDYCLIENT_R, nil, 'INDYCLIENT');
  end;
end;

{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TIdTCPClientBaseClass'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TIdTCPClientBaseClass_PSHelper = class helper for TIdTCPClientBaseClass
  public
//    procedure BOUNDIP_R(var T: string);
//    procedure BOUNDIP_W(const T: string);
//    procedure BOUNDPORT_R(var T: integer);
//    procedure BOUNDPORT_W(const T: integer);
//    procedure BOUNDPORTMAX_R(var T: integer);
//    procedure BOUNDPORTMAX_W(const T: integer);
//    procedure BOUNDPORTMIN_R(var T: integer);
//    procedure BOUNDPORTMIN_W(const T: integer);
    procedure HOST_R(var T: string);
    procedure HOST_W(const T: string);
    procedure PORT_R(var T: integer);
    procedure PORT_W(const T: integer);
  end;

{procedure TIdTCPClientBaseClass_PSHelper.BOUNDPORT_W(const T: integer);
begin
  Self.BOUNDPORT := T;
end;

procedure TIdTCPClientBaseClass_PSHelper.BOUNDPORT_R(var T: integer);
begin
  T := Self.BOUNDPORT;
end;

procedure TIdTCPClientBaseClass_PSHelper.BOUNDIP_W(const T: string);
begin
  Self.BOUNDIP := T;
end;

procedure TIdTCPClientBaseClass_PSHelper.BOUNDIP_R(var T: string);
begin
  T := Self.BOUNDIP;
end;]

procedure TIdTCPClientBaseClass_PSHelper.BOUNDPORTMIN_W(const T: integer);
begin
  Self.BOUNDPORTMIN := T;
end;

procedure TIdTCPClientBaseClass_PSHelper.BOUNDPORTMIN_R(var T: integer);
begin
  T := Self.BOUNDPORTMIN;
end;

procedure TIdTCPClientBaseClass_PSHelper.BOUNDPORTMAX_W(const T: integer);
begin
  Self.BOUNDPORTMAX := T;
end;

procedure TIdTCPClientBaseClass_PSHelper.BOUNDPORTMAX_R(var T: integer);
begin
  T := Self.BOUNDPORTMAX;
end; }

procedure TIdTCPClientBaseClass_PSHelper.PORT_W(const T: integer);
begin
  Self.PORT := T;
end;

procedure TIdTCPClientBaseClass_PSHelper.PORT_R(var T: integer);
begin
  T := TIdIndy10HackClient(Self).PORT;
end;

procedure TIdTCPClientBaseClass_PSHelper.HOST_W(const T: string);
begin
  TIdIndy10HackClient(Self).HOST := T;
end;

procedure TIdTCPClientBaseClass_PSHelper.HOST_R(var T: string);
begin
  T := TIdIndy10HackClient(Self).HOST;
end;

procedure RIRegisterTIDTCPCLIENT(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TIdTCPClientBaseClass) do
  begin
    {RegisterPropertyHelper(@TIdTCPClientBaseClass.BOUNDPORTMAX_R, @TIdTCPClientBaseClass.BOUNDPORTMAX_W,
      'BOUNDPORTMAX');
    RegisterPropertyHelper(@TIdTCPClientBaseClass.BOUNDPORTMIN_R, @TIdTCPClientBaseClass.BOUNDPORTMIN_W,
      'BOUNDPORTMIN');
    RegisterPropertyHelper(@TIdTCPClientBaseClass.BOUNDIP_R, @TIdTCPClientBaseClass.BOUNDIP_W, 'BOUNDIP');
    RegisterPropertyHelper(@TIdTCPClientBaseClass.BOUNDPORT_R, @TIdTCPClientBaseClass.BOUNDPORT_W,
      'BOUNDPORT');}
    RegisterPropertyHelper(@TIdTCPClientBaseClass.HOST_R, @TIdTCPClientBaseClass.HOST_W, 'HOST');
    RegisterPropertyHelper(@TIdTCPClientBaseClass.PORT_R, @TIdTCPClientBaseClass.PORT_W, 'PORT');
  end;
end;
{$ELSE}

{procedure TIDTCPCLIENTBOUNDPORT_W(Self: TIdTCPClientBaseClass; const T: integer);
begin
  Self.BOUNDPORT := T;
end;

procedure TIDTCPCLIENTBOUNDPORT_R(Self: TIdTCPClientBaseClass; var T: integer);
begin
  T := Self.BOUNDPORT;
end;

procedure TIDTCPCLIENTBOUNDIP_W(Self: TIdTCPClientBaseClass; const T: string);
begin
  Self.BOUNDIP := T;
end;

procedure TIDTCPCLIENTBOUNDIP_R(Self: TIdTCPClientBaseClass; var T: string);
begin
  T := Self.BOUNDIP;
end;]

procedure TIDTCPCLIENTBOUNDPORTMIN_W(Self: TIdTCPClientBaseClass; const T: integer);
begin
  Self.BOUNDPORTMIN := T;
end;

procedure TIDTCPCLIENTBOUNDPORTMIN_R(Self: TIdTCPClientBaseClass; var T: integer);
begin
  T := Self.BOUNDPORTMIN;
end;

procedure TIDTCPCLIENTBOUNDPORTMAX_W(Self: TIdTCPClientBaseClass; const T: integer);
begin
  Self.BOUNDPORTMAX := T;
end;

procedure TIDTCPCLIENTBOUNDPORTMAX_R(Self: TIdTCPClientBaseClass; var T: integer);
begin
  T := Self.BOUNDPORTMAX;
end; }

procedure TIDTCPCLIENTPORT_W(Self: TIdTCPClient; const T: integer);
begin
  Self.PORT := T;
end;

procedure TIDTCPCLIENTPORT_R(Self: TIdTCPClientBaseClass; var T: integer);
begin
  T := TIdIndy10HackClient(Self).PORT;
end;

procedure TIDTCPCLIENTHOST_W(Self: TIdTCPClientBaseClass; const T: string);
begin
  TIdIndy10HackClient(Self).HOST := T;
end;

procedure TIDTCPCLIENTHOST_R(Self: TIdTCPClientBaseClass; var T: string);
begin
  T := TIdIndy10HackClient(Self).HOST;
end;

procedure RIRegisterTIDTCPCLIENT(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TIdTCPClientBaseClass) do
  begin
    {RegisterPropertyHelper(@TIDTCPCLIENTBOUNDPORTMAX_R, @TIDTCPCLIENTBOUNDPORTMAX_W,
      'BOUNDPORTMAX');
    RegisterPropertyHelper(@TIDTCPCLIENTBOUNDPORTMIN_R, @TIDTCPCLIENTBOUNDPORTMIN_W,
      'BOUNDPORTMIN');
    RegisterPropertyHelper(@TIDTCPCLIENTBOUNDIP_R, @TIDTCPCLIENTBOUNDIP_W, 'BOUNDIP');
    RegisterPropertyHelper(@TIDTCPCLIENTBOUNDPORT_R, @TIDTCPCLIENTBOUNDPORT_W,
      'BOUNDPORT');}
    RegisterPropertyHelper(@TIDTCPCLIENTHOST_R, @TIDTCPCLIENTHOST_W, 'HOST');
    RegisterPropertyHelper(@TIDTCPCLIENTPORT_R, @TIDTCPCLIENTPORT_W, 'PORT');
  end;
end;
{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}


{procedure RIRegisterTROSOAPMESSAGE(Cl: TIFPSRuntimeClassImporter);
begin
  with Cl.Add(TROSOAPMESSAGE) do
  begin
    RegisterPropertyHelper(@TROSOAPMESSAGELIBRARYNAME_R, @TROSOAPMESSAGELIBRARYNAME_W,
      'LIBRARYNAME');
    RegisterPropertyHelper(@TROSOAPMESSAGECUSTOMLOCATION_R,
      @TROSOAPMESSAGECUSTOMLOCATION_W, 'CUSTOMLOCATION');
    RegisterPropertyHelper(@TROSOAPMESSAGESERIALIZATIONOPTIONS_R,
      @TROSOAPMESSAGESERIALIZATIONOPTIONS_W, 'SERIALIZATIONOPTIONS');
  end;
end; }

procedure RIRegisterRODLImports(CL: TIFPSRuntimeClassImporter);
begin
  RIRegisterTIDTCPCLIENT(Cl);
  RIRegisterTROINDYTCPCHANNEL(Cl);
  RIRegisterTROINDYHTTPCHANNEL(Cl);
  RIRegisterTROBINMESSAGE(Cl);
  //RIRegisterTROSOAPMESSAGE(Cl);
end;

function RegClassS(cl: TIFPSPascalCompiler; const InheritsFrom,
  ClassName: string): TPSCompileTimeClass;
begin
  Result := cl.FindClass(ClassName);
  if Result = nil then
    Result := cl.AddClassN(cl.FindClass(InheritsFrom), ClassName)
  else
    Result.ClassInheritsFrom := cl.FindClass(InheritsFrom);
end;

{procedure SIRegisterTROSOAPMESSAGE(CL: TIFPSPascalCompiler);
begin
  Cl.addTypeS('TXMLSERIALIZATIONOPTIONS', 'BYTE');
  Cl.AddConstantN('XSOWRITEMULTIREFARRAY', 'BYTE').SetInt(1);
  Cl.AddConstantN('XSOWRITEMULTIREFOBJECT', 'BYTE').SetInt(2);
  Cl.AddConstantN('XSOSENDUNTYPED', 'BYTE').SetInt(4);
  with RegClassS(cl, 'TROMESSAGE', 'TROSOAPMESSAGE') do
  begin
    RegisterProperty('LIBRARYNAME', 'STRING', iptrw);
    RegisterProperty('CUSTOMLOCATION', 'STRING', iptrw);
    RegisterProperty('SERIALIZATIONOPTIONS', 'TXMLSERIALIZATIONOPTIONS', iptrw);
  end;
end;}

procedure SIRegisterTROBINMESSAGE(CL: TIFPSPascalCompiler);
begin
  with RegClassS(cl, 'TROMESSAGE', 'TROBINMESSAGE') do
  begin
    RegisterProperty('USECOMPRESSION', 'BOOLEAN', iptrw);
  end;
end;

procedure SIRegisterTROINDYHTTPCHANNEL(CL: TIFPSPascalCompiler);
begin
  with RegClassS(cl, 'TROINDYTCPCHANNEL', 'TROINDYHTTPCHANNEL') do
  begin
    RegisterProperty('TARGETURL', 'STRING', iptrw);
  end;
end;

procedure SIRegisterTROINDYTCPCHANNEL(CL: TIFPSPascalCompiler);
begin
  with RegClassS(cl, 'TROTRANSPORTCHANNEL', 'TROINDYTCPCHANNEL') do
  begin
    RegisterProperty('INDYCLIENT', 'TIdTCPClientBaseClass', iptr);
  end;
end;

procedure SIRegisterTIDTCPCLIENT(CL: TIFPSPascalCompiler);
begin
  with RegClassS(cl, 'TCOMPONENT', 'TIdTCPClientBaseClass') do
  begin
    RegisterProperty('BOUNDPORTMAX', 'INTEGER', iptrw);
    RegisterProperty('BOUNDPORTMIN', 'INTEGER', iptrw);
    RegisterProperty('BOUNDIP', 'STRING', iptrw);
    RegisterProperty('BOUNDPORT', 'INTEGER', iptrw);
    RegisterProperty('HOST', 'STRING', iptrw);
    RegisterProperty('PORT', 'INTEGER', iptrw);
  end;
end;

procedure SIRegisterRODLImports(Cl: TIFPSPascalCompiler);
begin
  SIRegisterTIDTCPCLIENT(Cl);
  SIRegisterTROINDYTCPCHANNEL(Cl);
  SIRegisterTROINDYHTTPCHANNEL(Cl);
  SIRegisterTROBINMESSAGE(Cl);
  //SIRegisterTROSOAPMESSAGE(Cl);
end;

{ TPSROIndyTCPModule }

class procedure TPSROIndyTCPModule.CompImp(comp: TIFPSPascalCompiler);
begin
  SIRegisterTIDTCPCLIENT(Comp);
  SIRegisterTROINDYTCPCHANNEL(Comp);
end;

class procedure TPSROIndyTCPModule.ExecImp(exec: TIFPSExec;
  ri: TIFPSRuntimeClassImporter);
begin
  RIRegisterTIDTCPCLIENT(ri);
  RIRegisterTROINDYTCPCHANNEL(ri);
end;

{ TPSROIndyHTTPModule }

class procedure TPSROIndyHTTPModule.CompImp(comp: TIFPSPascalCompiler);
begin
  if Comp.FindClass('TROINDYTCPCHANNEL') = nil then
    TPSROIndyTCPModule.CompImp(Comp);
  SIRegisterTROINDYHTTPCHANNEL(Comp);
end;

class procedure TPSROIndyHTTPModule.ExecImp(exec: TIFPSExec;
  ri: TIFPSRuntimeClassImporter);
begin
  if ri.FindClass('TROINDYTCPCHANNEL') = nil then
    TPSROIndyTCPModule.ExecImp(exec, ri);
  RIRegisterTROINDYHTTPCHANNEL(ri);
end;

{ TPSROSoapModule }

{class procedure TPSROSoapModule.CompImp(comp: TIFPSPascalCompiler);
begin
  SIRegisterTROSOAPMESSAGE(comp);
end;

class procedure TPSROSoapModule.ExecImp(exec: TIFPSExec;
  ri: TIFPSRuntimeClassImporter);
begin
  RIRegisterTROSOAPMESSAGE(ri);
end;}

{ TPSROBinModule }

class procedure TPSROBinModule.CompImp(comp: TIFPSPascalCompiler);
begin
  SIRegisterTROBINMESSAGE(Comp);
end;

class procedure TPSROBinModule.ExecImp(exec: TIFPSExec;
  ri: TIFPSRuntimeClassImporter);
begin
  RIRegisterTROBINMESSAGE(ri);
end;

end.
