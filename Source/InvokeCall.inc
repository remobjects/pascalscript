//NEED FPC TESTS & FIXES!!!

type
  EInvocationError = class(Exception);
  TEmptyArr = array of Byte;


{$if not declared(btCharIsWide)}
const
  {$if not declared(btCharSize)}
  btCharSize = SizeOf(TbtString(nil^)[1]);
  {$ifend}
  {$IFNDEF FPC}{$warn comparison_true off}{$ENDIF}
  btCharIsWide = {$if btCharSize=2}True{$else}False{$ifend};
{$ifend}

const
  EmptyPChar: array[0..1] of Byte = (0, 0);



{$if not declared(BoolToTxt)}
function BoolToTxt(B: Boolean): string;
begin
  if B
  then Result := 'True'
  else Result := 'False';
end;
{$ifend}

{$if not declared(PSBaseTypeToStr)}
function PSBaseTypeToStr(Self: PIFTypeRec): string;
var i: Longint;
begin
  case Self.BaseType of
    btU8                  : Result := 'U8';
    btS8                  : Result := 'S8';
    btU16                 : Result := 'U16';
    btS16                 : Result := 'S16';
    btU32                 : Result := 'U32';
    btS32                 : Result := 'S32';
    btSingle              : Result := 'Single';
    btDouble              : Result := 'Double';
    btExtended            : Result := 'Extended';
    btString              : Result := {$if btCharIsWide}'UnicodeString'{$else}'AnsiString'{$ifend};
    btRecord              : begin
                              Result := 'Record';
                              i := TPSTypeRec_Record(Self).FieldTypes.Count;
                              if (i > 0) then begin
                                Result := Result+'('
                                  + PSBaseTypeToStr(PIFTypeRec(TPSTypeRec_Record(Self).FieldTypes[0]));
                                for i := 1 to i-1 do
                                  Result := Result+','
                                    + PSBaseTypeToStr(PIFTypeRec(TPSTypeRec_Record(Self).FieldTypes[i]));
                                Result := Result + ')';
                              end;
                            end;
    btArray               : Result := 'Array of '+PSBaseTypeToStr(TPSTypeRec_Array(Self).ArrayType);
    btPointer             : Result := 'Pointer';
    btPChar               : Result := {$if btCharIsWide}'PWideChar'{$else}'PAnsiChar'{$ifend};
    btResourcePointer     : Result := 'ResourcePointer';
    btVariant             : Result := 'Variant';
  {$IFNDEF PS_NOINT64}
    btS64                 : Result := 'S64';
    {+}
  //{$if declared(btU64)}
  //btU64                 : Result := 'U64';
  //{$ifend}
    {+.}
  {$ENDIF}
    btChar                : Result := {$if btCharIsWide}'WideChar'{$else}'AnsiChar'{$ifend};
  {$IFNDEF PS_NOWIDESTRING}
    btWideString          : Result := 'WideString';
    btWideChar            : Result := 'WideChar';
  {$ELSE}
    {$IFDEF UNICODE}
    btWideChar            : Result := 'WideChar';
    {$ENDIF}
  {$ENDIF}
    btProcPtr             : Result := 'ProcPtr';
    btStaticArray         : Result := 'StaticArray'
                              + '['+SysUtils.IntToStr(TPSTypeRec_StaticArray(Self).Size)
                              + '] of '+PSBaseTypeToStr(TPSTypeRec_Array(Self).ArrayType)
                              ;
    btSet                 : Result := 'Set';
    btCurrency            : Result := 'Currency';
    btClass               : Result := 'Class'
                              //+ ': '+string(TPSTypeRec_Class(Self).CN)
                              ;
    btInterface           : Result := 'Interface';
    btNotificationVariant : Result := 'NotificationVariant';
    btUnicodeString       : Result := 'UnicodeString';
    {$if declared(btPWideChar)}
    btPWideChar           : Result := 'PWideChar';
    {$ifend}
    btType                : Result := 'Type';
    btEnum                : Result := 'Enum';
    btExtClass            : Result := 'ExtClass';
    else                    Result := 'Unknown '+SysUtils.IntToStr(Self.BaseType);
  end; // case
end; // function PSBaseTypeToStr
{$ifend}

{$if not declared(PSParamTypeToStr)}
function PSParamTypeToStr(P: PPSVariantIFC): string;
begin
   Result := '';
   if P = nil then
     Exit;
  Result := 'type var: '+BoolToTxt(P.VarParam)+' "'
    + 'BT: '+SysUtils.IntToStr(Integer(P.aType.BaseType))
    + ', ' + PSBaseTypeToStr(P.aType)
  ;
  if P.aType.ExportName <> '' then
    Result := Result
    + '; EN: '+string(P.aType.ExportName);
  Result := Result
    + '; SZ: '+string(SysUtils.IntToStr(Integer(P.aType.RealSize)))
    + '"'
  ;
end;
{$ifend}

function DoInvoke(CodeAddress: Pointer; const Args: TArray<TValue>;
    CallingConvention: TCallConv; AResultType: PTypeInfo;
    IsStatic : Boolean = False; IsConstructor: Boolean = False): TValue;
begin
  Result := Invoke(CodeAddress,Args,CallingConvention,AResultType,IsStatic
      {$if defined(FPC) or defined(DELPHI23UP)}
      ,{IsConstructor:}IsConstructor
      {$ifend}
      );
end;

function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention;
  Params: TPSList; res: PPSVariantIFC): Boolean;
var
  ExtraSizeRes, ExtraSizeParam  : Integer;
  CustomTypeRes, CustomTypeParam : PTypeInfo;
  TypeData: PTypeData;

  function InvokeWithResTypeByKindSize(CodeAddress: Pointer; const Args: TArray<TValue>;
      CallingConvention: TCallConv; RTypeKind : TTypeKind = tkUnknown; RTypeSize: Longint = 0; IsStatic : Boolean = False): TValue;
  begin
    case RTypeKind of
      tkArray:      ExtraSizeRes := SizeOf(TArrayTypeData);
      tkRecord:     ExtraSizeRes := 2*SizeOf(Integer);
      tkDynArray:   ExtraSizeRes := (2*SizeOf(Integer)) + (2*SizeOf(PPTypeInfo))
                                    + SizeOf({$IFDEF FPC}ShortStringBase{$ELSE}TSymbolName{$ENDIF});
      tkSet :       ExtraSizeRes := SizeOf(UInt8) + SizeOf(PPTypeInfo);
      else raise EInvocationError.Create('Unknown TypeKind in InvokeWithResTypeByKindSize!');
    end;
    CustomTypeRes := AllocMem(SizeOf(TTypeInfo) + ExtraSizeRes);
    try
      CustomTypeRes.Kind := RTypeKind;
      TypeData := GetTypeData(CustomTypeRes);
      case CustomTypeRes.Kind of
        tkArray:
        begin
          TypeData^.ArrayData.Size   := RTypeSize;
          TypeData^.ArrayData.{$IFDEF FPC}ElTypeRef{$ELSE}ElType{$ENDIF} := AllocMem(SizeOf(Pointer));
          TypeData^.ArrayData.{$IFDEF FPC}ElTypeRef{$ELSE}ElType{$ENDIF}^:= TypeInfo(Byte);
        end;
        tkSet :
        begin
          {$IFDEF FPC}
          TypeData^.SetSize := RTypeSize;
          {$ELSE}
          TypeData^.SetTypeOrSize := $80 or RTypeSize;
          {$ENDIF}
        end;
        tkRecord:
        begin
          TypeData^.RecSize := RTypeSize;
        end;
        tkDynArray:
        begin
          TypeData^.elSize  := RTypeSize;
          TypeData^.{$IFDEF FPC}ElTypeRef{$ELSE}ElType{$ENDIF} := nil;
          TypeData^.{$IFDEF FPC}elType2Ref{$ELSE}ElType2{$ENDIF} := AllocMem(SizeOf(Pointer));
          TypeData^.{$IFDEF FPC}elType2Ref{$ELSE}ElType2{$ENDIF}^:= TypeInfo(Byte);
        end;
      end;
      Result := DoInvoke(CodeAddress,Args,CallingConvention,CustomTypeRes,IsStatic,False);
    except
      Result := nil;
    end;
  end;

  function InnerfuseCallReal(Exec : TPSExec;_Self, Address: Pointer; CallingConv: TPSCallingConvention;
    Params: TPSList; res: PPSVariantIFC): Boolean;

    function rp(p: PPSVariantIFC): PPSVariantIFC;
    begin
      if (p = nil) or (p.aType = nil) then begin
        Result := nil;
        Exit;
      end;
      if (p.aType.BaseType = btPointer) then begin
        p^.aType := Pointer(Pointer(IPointer(p^.Dta) + PointerSize)^);
        p^.Dta := Pointer(p^.Dta^);
      end;
      Result := p;
    end;

  var
    Args: TArray<TValue>;
    ArgIdx : Integer;

    procedure AddArg(Arg : TValue);
    begin
      Inc(ArgIdx);
      Args[ArgIdx] := Arg;
    end;

  var SysCalConv : TCallConv;
      Arg : TValue;
      i : Integer;
      fvar: PPSVariantIFC;
      IsConstr, IsStatic : Boolean;
      ResValue : TValue;
      S: string;
    {%H-}p: Pointer;
    {%H-}pp: ^Byte;
    {%H-}CallData : TPSList;
    {%H-}I64 : Int64;
  begin
    Result := False;
    case CallingConv of
      cdRegister : begin SysCalConv := ccReg;       end;
      cdPascal   : begin SysCalConv := ccPascal;    end;
      cdCdecl    : begin SysCalConv := ccCdecl;     end;
      cdStdCall  : begin SysCalConv := ccStdCall;   end;
      cdSafeCall : begin SysCalConv := ccSafeCall;  end;
      {$IFNDEF FPC}
      else         begin SysCalConv := ccReg;       end; // to prevent warning "W1036 Variable might not have been initialized"
      {$ENDIF}
    end;

    IsConstr := (Integer(CallingConv) and 64) <> 0;

    {$IFDEF FPC} // FPC: FIX FOR FPC constructor calls
      //x64.inc: {$if defined(FPC) and (fpc_version >= 3)}
      //x86.inc: {$ifdef FPC} + case CallingConv of cdRegister
      // dcc: Warning: W1023 Comparing signed and unsigned types - widened both operands
      //               => Integer(fpc_version)
    {$if defined(CPU32) or (declared(fpc_version) and (Integer(fpc_version) >= 3)) } // TODO: FPC: test and check other platforms
    {$IFDEF CPU32}
    if (CallingConv = cdRegister) then
    {$ENDIF }
    begin
      if IsConstr then begin
        fvar := Params[0];
        p := rp(fvar);
        if p = nil then
          Exit; // this goes first  // internal error
        case fVar.aType.BaseType of
          btArray,
          btVariant,
          btSet,
          btStaticArray,
          btRecord,
          btInterface,
          btClass,
          {$IFNDEF PS_NOWIDESTRING}
          btUnicodeString, btWideString, btWideChar,
          {$if declared(btPWideChar)}
          btPWideChar,
          {$ifend}
          {$ENDIF !PS_NOWIDESTRING}
          btU8, btS8, btU16,
          btS16, btU32, btS32, btSingle, btDouble, btExtended, btString, btPChar, btChar, btCurrency
          {$IFNDEF PS_NOINT64}
          ,bts64
          {$ENDIF}
          ,btProcPtr
          : { empty } ;
        else
          Exit; // this goes first  // internal error
        end; // case
        DisposePPSVariantIFC(p);
        Params.Delete(0);
      end;
    end;
    {$ifend}
    {$ENDIF FPC}

    ArgIdx := -1;
    SetLength(Args, 2*Params.Count+1); // maximum params

    IsStatic := not Assigned(_Self);
    if Assigned(_Self) then
      AddArg( TValue.From<Pointer>( _Self ) );

    CallData := nil;
    try
      for I := 0 to Params.Count - 1 do
      begin
        if Params[i] = nil then
          raise EInvocationError.Create('Internal: Unassigned parameter #"'
            + SysUtils.IntToStr(i) + '"!');

        fvar := Params[i];

        fvar := rp(PPSVariantIFC(fvar));

        if fvar = nil then
          raise EInvocationError.Create('Internal: Unassigned parameter ref #"'
            + SysUtils.IntToStr(i) + '"!');

        Arg := nil;
        if fvar.varparam then
        begin { var param }
          case fvar.aType.BaseType of
            btArray:
              begin
                if Copy(fVar.aType.ExportName, 1, 10) = '!OPENARRAY' then
                begin
                  p := CreateOpenArray(True, Exec, fVar);
                  if p = nil then
                    raise EInvocationError.Create('Internal: ' + 'CreateOpenArray call for var param failed!');

                  if CallData = nil then
                    CallData := TPSList.Create;
                  CallData.Add(p);


                  Arg := TValue.From<Pointer>( Pointer(POpenArray(p)^.Data) );
                  AddArg(Arg);
                  Arg := TValue.From<Longint>( Longint(POpenArray(p)^.ItemCount-1) ); //?? type IPointer

                end
                else
                  Arg := TValue.From<Pointer>( Pointer(fvar.Dta) );
              end;
            btVariant,
            btSet,
            btStaticArray,
            btRecord,
            btInterface,
            btClass,
            {$IFNDEF PS_NOWIDESTRING}
            btUnicodeString, btWideString, btWideChar,
            {$if declared(btPWideChar)}
            btPWideChar,
            {$ifend}
            {$ENDIF !PS_NOWIDESTRING}
            btU8, btS8, btU16,
            btS16, btU32, btS32, btSingle, btDouble, btExtended,
            btString, btPChar, btChar, btCurrency
            {$IFNDEF PS_NOINT64}
            ,bts64
            {$ENDIF}: begin
                Arg := TValue.From<Pointer>( Pointer(fvar.Dta) );
            end;

            else
              begin
                {$if declared(PSParamTypeToStr)}
                S := '@Var Param: '+PSParamTypeToStr(fvar)
                  + '" not implemented!';
                {$else}
                S := '@Var Paramtype '+ SysUtils.IntToStr(fvar.aType.BaseType)
                  + '" not implemented!';
                {$ifend} // "$if declared(PSParamTypeToStr)"
                raise EInvocationError.Create('Internal: ' + S); // optional
                Exit;
              end;
          end;
        end
        else
        begin  { not a var param }
          case fvar.aType.BaseType of { add normal params here }
            {$IFNDEF PS_NOWIDESTRING}
            btWidestring:                      Arg := TValue.From<WideString>( PWideString(fvar.Dta)^ );
            btUnicodeString:                   Arg := TValue.From<UnicodeString>( PUnicodeString(fvar.Dta)^ );
            {$ENDIF}
            {$if btCharIsWide}                 // unicode string
            btString:                          Arg := TValue.From<UnicodeString>( PUnicodeString(fvar.Dta)^ );
            {$else}                            // ansi string
            btString:                          Arg := TValue.From<AnsiString>( PAnsiString(fvar.Dta)^ );
            {$ifend}
            btU8, btS8:                        Arg := TValue.From<Byte>( PByte(fvar.Dta)^ );
            btU16, BtS16:                      Arg := TValue.From<Word>( PWord(fvar.Dta)^ );
            btU32, btS32:                      Arg := TValue.From<Cardinal>( PCardinal(fvar.Dta)^ );
            {$IFNDEF PS_NOINT64}
            btS64:                             Arg := TValue.From<Int64>( PInt64(fvar.Dta)^ );
            {$ENDIF}
            btSingle:                          Arg := TValue.From<Single>( PSingle(fvar.Dta)^ );
            btDouble:                          Arg := TValue.From<Double>( PDouble(fvar.Dta)^ );
            btExtended:                        Arg := TValue.From<Extended>( PExtended(fvar.Dta)^ );
            btCurrency:                        Arg := TValue.From<Currency>( PCurrency(fvar.Dta)^ );
            {$if btCharIsWide}                 // unicode
            btPChar:                        //-Arg := TValue.From<PWideChar>( PPWideChar(fvar.Dta)^ );
                                             if Pointer(fVar.Dta^) = nil then
                                               Arg := TValue.From<PWideChar>( PPWideChar(@EmptyPChar)^ )
                                             else
                                               Arg := TValue.From<PWideChar>( PPWideChar(fvar.Dta)^ );
            {$else}                            // ansi
            btPChar:                        //-Arg := TValue.From<PAnsiChar>( PPAnsiChar(fvar.Dta)^ );
                                             if Pointer(fVar.Dta^) = nil then
                                               Arg := TValue.From<PAnsiChar>( PPAnsiChar(@EmptyPChar)^ )
                                             else
                                               Arg := TValue.From<PAnsiChar>( PPAnsiChar(fvar.Dta)^ );
            {$ifend}
            {$IFNDEF PS_NOWIDESTRING}
            btWideChar:                        Arg := TValue.From<WideChar>( PWideChar(fvar.Dta)^ );
              {$if declared(btPWideChar)}
            btPWideChar:                    //-Arg := TValue.From<PWideChar>( PPWideChar(fvar.Dta)^ );
                                             if Pointer(fVar.Dta^) = nil then
                                               Arg := TValue.From<PWideChar>( PPWideChar(@EmptyPChar)^ )
                                             else
                                               Arg := TValue.From<PWideChar>( PPWideChar(fvar.Dta)^ );
              {$ifend}
            {$ENDIF !PS_NOWIDESTRING}
            {$if btCharIsWide}                 // unicode char
            btChar:                            Arg := TValue.From<WideChar>( PWideChar(fvar.Dta)^ );
            {$else}                            // ansi char
            btChar:                            Arg := TValue.From<AnsiChar>( PAnsiChar(fvar.Dta)^ );
            {$ifend}
            btClass:                           Arg := TValue.From<TObject>( TObject(fvar.Dta^) );
            btPointer:                         Arg := TValue.From<Pointer>( PPointer(fvar.Dta)^ );
            btProcPtr:
              begin
                Arg := TValue.From<TMethod>( MKMethod(Exec, Longint(fVar.Dta^)) );  // +x64, -x86
              end;
            btInterface:
              begin
                Arg := TValue.From<Pointer>( PPointer(fvar.Dta)^ );
              end;
            btRecord:
              begin
                //Arg := TValue.From<Pointer>(fvar.Dta);
                if fVar.aType.RealSize <= SizeOf(Pointer) then
                  Arg := TValue.From<IPointer>( IPointer(fvar.Dta^) )
                else
                  Arg := TValue.From<Pointer>( Pointer(fvar.Dta) );
              end;
            btStaticArray:                     Arg := TValue.From<Pointer>( Pointer(fvar.Dta) );
            btArray:
              begin
                if Copy(fvar.aType.ExportName, 1, 10) = '!OPENARRAY' then
                begin
                  p := CreateOpenArray(False, Exec, fVar);
                  if p = nil then
                    raise EInvocationError.Create('Internal: ' + 'CreateOpenArray call for param failed!');

                  if CallData = nil then
                    CallData := TPSList.Create;
                  CallData.Add(p);

                                 //in case of openarray we should provide TWO params: first is pointer to array,
                  Arg := TValue.From<Pointer>( Pointer(POpenArray(p)^.Data) );
                  AddArg(Arg);

                  //2nd - integer with arraylength - 1 (high)
                  Arg := TValue.From<Integer>( Integer (POpenArray(p)^.ItemCount-1) ); //?? type IPointer
                end
                else  //dynarray = just push pointer:
                  Arg := TValue.From<Pointer>( PPointer(fvar.Dta){$IFNDEF FPC}^{$ENDIF} );
              end;
            btVariant:   Arg := TValue.From<Pointer>( Pointer(fvar.Dta) );
            btSet:
              case TPSTypeRec_Set(fvar.aType).aByteSize  of
                1:       Arg := TValue.From<Byte>    (PByte    (fvar.Dta)^);
                2:       Arg := TValue.From<Word>    (PWord    (fvar.Dta)^);
                3,4:     Arg := TValue.From<Cardinal>(PCardinal(fvar.Dta)^);
                {$IFDEF FPC}
                5,6,7,8: Arg := TValue.From<Int64>   (PInt64   (fvar.Dta)^);
                {$ENDIF}
                else     Arg := TValue.From<Pointer> (Pointer  (fvar.Dta));
              end; // case

            else
              begin
                {$if declared(PSParamTypeToStr)}
                S := '@Param: '+PSParamTypeToStr(fvar)
                  + '" not implemented!';
                {$else}
                S := '@Paramtype '+ SysUtils.IntToStr(fvar.aType.BaseType)
                  + '" not implemented!';
                {$ifend} // "$if declared(PSParamTypeToStr)"
                raise EInvocationError.Create('Internal: ' + S); // optional
                Exit;
              end;
          end;  { case }
        end;  { if "not a var param" }

        if Arg.IsEmpty then
        begin
          {$if declared(PSParamTypeToStr)}
          S := '#Param '+PSParamTypeToStr(fvar)
            + '" not detected!';

          raise EInvocationError.Create('Internal: ' + S); // optional
          {$ifend} // "$if declared(PSParamTypeToStr)"
          //Exit;
        end;
        AddArg(Arg);
      end;
      SetLength(Args, ArgIdx+1); // truncate args

      res := rp(PPSVariantIFC(res));
      if Assigned(res) then
        res.VarParam := True;

      if not assigned(res) then
        DoInvoke(Address,Args,SysCalConv,nil,IsStatic,IsConstr)  { ignore return }
      else
      begin
        case res.aType.BaseType of { add result types here }
          {$if btCharIsWide}
          btString:              begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(UnicodeString),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   TbtString(res.Dta^) := TbtString( ResValue.AsUnicodeString );
                                   {$ELSE}
                                   TbtString(res.Dta^) := TbtString( ResValue.AsType<UnicodeString> );
                                   {$ENDIF}
                                 end;
          {$else}
          btString:              begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(AnsiString), IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   TbtString(res.Dta^) := TbtString( ResValue.AsAnsiString );
                                   {$ELSE}
                                   TbtString(res.Dta^) := TbtString( ResValue.AsType<AnsiString> );
                                   {$ENDIF}
                                 end;
          {$ifend}
          {$IFNDEF PS_NOWIDESTRING}
          btUnicodeString:       begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(UnicodeString),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {TbtUnicodeString}UnicodeString(res.Dta^) := ResValue.AsUnicodeString;
                                   {$ELSE}
                                   {TbtUnicodeString}UnicodeString(res.Dta^) := ResValue.AsType<UnicodeString>;
                                   {$ENDIF}
                                 end;
          btWideString:          begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(WideString),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {TbtWideString}WideString(res.Dta^) := ResValue.AsUnicodeString;
                                   {$ELSE}
                                   {TbtWideString}WideString(res.Dta^) := ResValue.AsType<WideString>;
                                   {$ENDIF}
                                 end;
          {$ENDIF}
          btU8, btS8:            begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Byte),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   PByte(res.Dta)^ := Byte(ResValue.AsOrdinal);
                                   {$ELSE}
                                   PByte(res.Dta)^ := ResValue.AsType<Byte>
                                   {$ENDIF}
                                 end;
          btU16, btS16:          begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Word),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   PWord(res.Dta)^ := Word(ResValue.AsOrdinal);
                                   {$ELSE}
                                   PWord(res.Dta)^ := ResValue.AsType<Word>;
                                   {$ENDIF}
                                 end;
          btU32, btS32:          begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Cardinal),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   PCardinal(res.Dta)^ := Cardinal(ResValue.AsOrdinal);
                                   {$ELSE}
                                   PCardinal(res.Dta)^ := ResValue.AsType<Cardinal>;
                                   {$ENDIF}
                                 end;
          {$IFNDEF PS_NOINT64}
          btS64:                 begin
                                   PInt64(res.Dta)^ := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Int64),IsStatic,IsConstr).AsInt64;
                                 end;
          {$ENDIF}
          btCurrency:            begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Currency),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   PCurrency(res.Dta)^ := ResValue.AsCurrency;
                                   {$ELSE}
                                   PCurrency(res.Dta)^ := ResValue.AsType<Currency>;
                                   {$ENDIF}
                                 end;
          btSingle:              begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Single),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   PSingle(res.Dta)^ := ResValue.AsExtended;
                                   {$ELSE}
                                   PSingle(res.Dta)^ := ResValue.AsType<Single>;
                                   {$ENDIF}
                                 end;
          btDouble:              begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Double),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   PDouble(res.Dta)^ := ResValue.AsExtended;
                                   {$ELSE}
                                   PDouble(res.Dta)^ := ResValue.AsType<Double>;
                                   {$ENDIF}
                                 end;
          btExtended:            begin
                                   PExtended(res.Dta)^ := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(Extended),IsStatic,IsConstr).AsExtended;
                                 end;
          {$if btCharIsWide}     // unicode
          btPChar:               begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(PWideChar),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {PTbtChar}PWideChar(res.Dta^) := PWideChar(ResValue.AsOrdinal);
                                   {$ELSE}
                                   {PTbtChar}PWideChar(res.Dta^) := ResValue.AsType<PWideChar>;
                                   {$ENDIF}
                                 end;
          {$else}                // ansi
          btPChar:               begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(PAnsiChar),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {PTbtChar}PAnsiChar(res.Dta^) := PAnsiChar(ResValue.AsOrdinal);
                                   {$ELSE}
                                   {PTbtChar}PAnsiChar(res.Dta^) := ResValue.AsType<PAnsiChar>;
                                   {$ENDIF}
                                 end;
          {$ifend}
          {$if btCharIsWide}     // unicode
          btChar:                begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(WideChar),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {TbtChar}WideChar(res.Dta^) := ResValue.AsWideChar;
                                   {$ELSE}
                                   {TbtChar}WideChar(res.Dta^) := ResValue.AsType<WideChar>;
                                   {$ENDIF}
                                 end;
          {$else}                // ansi
          btChar:                begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(AnsiChar),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {TbtChar}AnsiChar(res.Dta^) := ResValue.AsAnsiChar;
                                   {$ELSE}
                                   {TbtChar}AnsiChar(res.Dta^) := ResValue.AsType<AnsiChar>;
                                   {$ENDIF}
                                 end;
          {$ifend}
          {$IFNDEF PS_NOWIDESTRING}
          btWideChar:            begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(WideChar),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {TbtWideChar}PWideChar(res.Dta)^ := ResValue.AsWideChar;
                                   {$ELSE}
                                   {TbtWideChar}PWideChar(res.Dta)^ := ResValue.AsType<WideChar>;
                                   {$ENDIF}
                                 end;
            {$if declared(btPWideChar)}
          btPWideChar:           begin
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(PWideChar),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   {PTbtWideChar}PWideChar(res.Dta^) := PWideChar(ResValue.AsOrdinal);
                                   {$ELSE}
                                   {PTbtWideChar}PWideChar(res.Dta^) := ResValue.AsType<PWideChar>;
                                   {$ENDIF}
                                 end;
            {$ifend}
          {$ENDIF}
          btInterface:           begin  // TODO: pult: ... ?empty ; check RefCount  //
                                   ResValue := DoInvoke(Address,Args,SysCalConv,
                                     TypeInfo(IInterface),IsStatic,IsConstr);
                                   {$IFDEF FPC}
                                   IInterface(res.Dta^) := ResValue.AsInterface;
                                   {$ELSE}
                                   IInterface(res.Dta^) := ResValue.AsType<IInterface>;
                                   {$ENDIF}
                                 end;
          btSet:
            begin
              case TPSTypeRec_Set(res.aType).aByteSize of
                1: Byte(res.Dta^) := Byte(DoInvoke(Address,Args,SysCalConv,TypeInfo(Byte), IsStatic).AsInteger);
                2: Word(res.Dta^) := Word(DoInvoke(Address,Args,SysCalConv,TypeInfo(Word), IsStatic).AsInteger);
                3,
                4: Longint(res.Dta^) := Cardinal(DoInvoke(Address,Args,SysCalConv,TypeInfo(Cardinal),IsStatic,IsConstr).AsInteger);
                5,6,7,8:
                begin
                  {$IF DEFINED (FPC)}
                  Int64(res.Dta^) := Cardinal(DoInvoke(Address,Args,SysCalConv,TypeInfo(Int64),IsStatic,IsConstr).AsInt64);
                  {$ELSE}
                  ResValue := InvokeWithResTypeByKindSize(Address,Args,SysCalConv, tkSet,
                               TPSTypeRec_Set(res.aType).aByteSize, IsStatic);
                  p := ResValue.GetReferenceToRawData;
                  Move(p^, res.Dta^, TPSTypeRec_Set(res.aType).aByteSize);
                  {$ENDIF}
                end;
              end; // case
            end;
          btClass:
          begin
            ResValue := DoInvoke(Address,Args,SysCalConv,TypeInfo(TObject),IsStatic,IsConstr);
            TObject(res.Dta^) := ResValue.AsObject;
          end;
          btVariant:
          begin
            {$IFDEF FPC}
            ResValue := DoInvoke(Address,Args,SysCalConv,TypeInfo(TVarData), IsStatic);
            ResValue.ExtractRawData(res.Dta);
            {$ELSE}
            ResValue := DoInvoke(Address,Args,SysCalConv,TypeInfo(Variant), IsStatic);
            ResValue.ExtractRawData(res.Dta);
            {$ENDIF}
          end;
          btProcPtr:
          begin
            ResValue := DoInvoke(Address,Args,SysCalConv,TypeInfo(TMethod), IsStatic);
            {$IFDEF FPC}
            ResValue.ExtractRawData(res.Dta);
            {$ELSE}
            Pointer(Pointer(IPointer(res.Dta)+PointerSize)^)  := ResValue.AsType<TMethod>.Data;
            Pointer(Pointer(IPointer(res.Dta)+PointerSize2)^) := ResValue.AsType<TMethod>.Code;
            {$ENDIF}
          end;
          btStaticArray:
          begin
            {$IFDEF FPC}
            ResValue := Invoke(Address,Args,SysCalConv,TypeInfo(Pointer),IsStatic,IsConstr);
            PPointer(res.Dta)^ := Pointer(ResValue.AsOrdinal);
            {$ELSE !FPC}
            ResValue := InvokeWithResTypeByKindSize(Address,Args,SysCalConv, tkArray,
                                            TPSTypeRec_StaticArray(res.aType).Size * TPSTypeRec_StaticArray(res.aType).ArrayType.RealSize,
                                            IsStatic);
            CopyArrayContents(res.Dta, ResValue.GetReferenceToRawData,
                TPSTypeRec_StaticArray(res.aType).Size, TPSTypeRec_StaticArray(res.aType).ArrayType);
            {$ENDIF !FPC}
          end;
          btRecord:
          begin
            {$IFDEF FPC}
            ResValue := Invoke(Address,Args,SysCalConv,TypeInfo(Pointer),IsStatic,IsConstr);
            PPointer(res.Dta)^ := Pointer(ResValue.AsOrdinal);
            {$ELSE !FPC}
            ResValue := InvokeWithResTypeByKindSize(Address,Args,SysCalConv, tkRecord, res.aType.RealSize, IsStatic);
            CopyRecordContents(res.Dta, ResValue.GetReferenceToRawData, TPSTypeRec_Record(res.aType));
            {$ENDIF !FPC}
          end;
          btArray: //open arrays can't be returned. So, just DynArray here.
          begin
            {$IFDEF FPC}
            ResValue := Invoke(Address,Args,SysCalConv,TypeInfo(Pointer),IsStatic,IsConstr);
            PPointer(res.Dta)^ := Pointer(ResValue.AsOrdinal);
            {$ELSE !FPC}
            ResValue := InvokeWithResTypeByKindSize(Address,Args,SysCalConv, tkDynArray,
                                                    PSDynArrayGetLength(Pointer(res.Dta^), res.aType),IsStatic);
            CopyArrayContents(res.Dta, ResValue.GetReferenceToRawData, 1, res.aType)
            {$ENDIF !FPC}
          end;
          else
          begin
            {$if declared(PSParamTypeToStr)}
            S := '$Param '+PSParamTypeToStr(res)
              + '" not implemented!';

            raise EInvocationError.Create('Internal: ' + S); // optional
            {$ifend} // "$if declared(PSParamTypeToStr)"
            Exit;
          end;
        end;  { case }
      end; //assigned(res)

      Result := True;
    finally
      if Assigned(CallData) then begin
        for i := CallData.Count-1 downto 0 do begin
          pp := CallData[i];
          case pp^ of
            0: begin
              DestroyOpenArray(Exec, Pointer(pp));
            end;
            254: begin
              FreeMem(pp);
            end;
          end; // case
        end; // for
        CallData.Free;
      end; // if
    end; // finally
  end; //InnerfuseCall

begin
  CustomTypeRes  := nil;
  try
    Result := InnerfuseCallReal(Self, _Self,Address,CallingConv,Params, res);
  finally
    if Assigned(CustomTypeRes) then
    begin
      TypeData := GetTypeData(CustomTypeRes);
      case CustomTypeRes.Kind of
        tkArray:    FreeMem(TypeData^.ArrayData.ElType, SizeOf(Pointer));
        tkDynArray: FreeMem(TypeData^.elType2, SizeOf(Pointer));
      end;
      FreeMem(CustomTypeRes, SizeOf(TTypeInfo) + ExtraSizeRes);
    end;
  end;

end;


{$if defined (Delphi) and (not defined (MSWINDOWS)) and (not defined (MACOS32))}
procedure MyAllMethodsHandler3(P0, P1, P2, P3: Pointer); forward;

function MkMethod(FSE: TPSExec; No: Cardinal): TMethod;
begin
//No way to do this by available internal methods, because no access to register
// and type decl.
//When will have free time, will do this using TVirtualMethod from Tiny.Library
end;

procedure MyAllMethodsHandler3(P0, P1, P2, P3: Pointer);
begin
//here will be rewritten code from MyAllMethodsHandler2 with support
//of any params amount, any results, etc.
end;
{$ENDIF}

