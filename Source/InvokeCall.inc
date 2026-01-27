type
  ptbtChar = ^tbtchar;
  PtbtPChar = ^tbtPChar;
  ptbtWideChar = ^tbtwidechar;
  ptbtString = ^TbtString;
  ptbtWideString = ^tbtwidestring;
  ptbtUnicodeString = ^tbtunicodestring;
  PIInterface = ^IInterface;

type
  TOpenArrayData = record
    //Storage for typed open arrays - each can hold multiple contiguous arrays (one per open array parameter of that type)
    DataU8: TArray<TArray<Byte>>;
    DataU16: TArray<TArray<Word>>;
    DataU32: TArray<TArray<Cardinal>>;
    DataSingle: TArray<TArray<Single>>;
    DataDouble: TArray<TArray<Double>>;
    DataExtended: TArray<TArray<Extended>>;
    DataString: TArray<TArray<tbtString>>;
    DataPointer: TArray<TArray<Pointer>>;
    DataPChar: TArray<TArray<tbtPChar>>;
    DataVariant: TArray<TArray<Variant>>;
    {$IFNDEF PS_NOINT64}
    DataS64: TArray<TArray<Int64>>;
    DataU64: TArray<TArray<UInt64>>;
    {$ENDIF}
    DataChar: TArray<TArray<tbtChar>>;
    {$IFNDEF PS_NOWIDESTRING}
    DataWideString: TArray<TArray<tbtWideString>>;
    DataWideChar: TArray<TArray<tbtWideChar>>;
    DataUnicodeString: TArray<TArray<tbtUnicodeString>>;
    {$ENDIF}
    DataCurrency: TArray<TArray<Currency>>;
    DataClass: TArray<TArray<TObject>>;
    DataInterface: TArray<TArray<IInterface>>;
  end;
  POpenArrayData = ^TOpenArrayData;

function PSVariantIFCToTValue(aValue: PPSVariantIFC; var aValues: TArray<TValue>; var aValues1: TArray<TValue>; var aValues2: TArray<TVarRec>; aOpenArrayData: POpenArrayData; aSelf: TPSExec): Boolean;
//aValues1, aValues2 and aOpenArrayData are just used to keep references alive when this function exits, you can put anything in them
var
  l_high: Integer;
  i: Integer;
  arr: TArray<TValue>;
  arr_varrec: TArray<TVarRec>;
  procPtr: PPSVariantProcPtr;
  method: TMethod;
  ctx: TRttiContext;
  methodValue: TValue;
  rttiType: TRttiType;
  elemIFC: TPSVariantIFC;
begin
  Result := Assigned(aValue^.aType) and (IPointer(aValue^.aType) > $FFFF);
  if Result then
    case aValue^.aType.BaseType of
      //1,2
      btU8, btS8:                        aValues := aValues + [TValue.From<Byte>(PByte(aValue^.dta)^)];
      //3,4
      btU16, BtS16:                      aValues := aValues + [TValue.From<Word>(PWord(aValue^.dta)^)];
      //5,6
      btU32, btS32:                      aValues := aValues + [TValue.From<Cardinal>(PCardinal(aValue^.dta)^)];
      //7
      btSingle:                          aValues := aValues + [TValue.From<Single>(PSingle(aValue^.dta)^)];
      //8
      btDouble:                          aValues := aValues + [TValue.From<Double>(PDouble(aValue^.dta)^)];
      //9
      btExtended:                        aValues := aValues + [TValue.From<Extended>(PExtended(aValue^.dta)^)];
      //10
      btString:                          aValues := aValues + [TValue.From<TbtString>(pTbtString(aValue^.dta)^)];
      //11
      btRecord:                          aValues := aValues + [TValue.From<Pointer>(aValue^.dta)];
      //12
      btArray:
        begin
           if Copy(aValue^.aType.ExportName, 1, 10) = '!OPENARRAY' then begin
             l_high := PSDynArrayGetLength(Pointer(aValue^.Dta^), aValue^.aType) - 1;
             //For array of const (BaseType = btPointer), we must build a TVarRec/TValueArrayToArrayOfConst array.
             //For other arrays, we must build a contiguous array of the actual element type, taking special care of 'array of variant'.
             //For all arrays we should provide TWO params: first is pointer to array, and second array length - 1 (high)
             case TPSTypeRec_Array(aValue^.aType).ArrayType.BaseType of
               btU8, btS8: begin
                 aOpenArrayData^.DataU8 := aOpenArrayData^.DataU8 + [[]];
                 SetLength(aOpenArrayData^.DataU8[High(aOpenArrayData^.DataU8)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataU8[High(aOpenArrayData^.DataU8)][i] := PByte(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataU8[High(aOpenArrayData^.DataU8)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btU16, btS16: begin
                 aOpenArrayData^.DataU16 := aOpenArrayData^.DataU16 + [[]];
                 SetLength(aOpenArrayData^.DataU16[High(aOpenArrayData^.DataU16)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataU16[High(aOpenArrayData^.DataU16)][i] := PWord(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataU16[High(aOpenArrayData^.DataU16)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btU32, btS32: begin
                 aOpenArrayData^.DataU32 := aOpenArrayData^.DataU32 + [[]];
                 SetLength(aOpenArrayData^.DataU32[High(aOpenArrayData^.DataU32)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataU32[High(aOpenArrayData^.DataU32)][i] := PCardinal(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataU32[High(aOpenArrayData^.DataU32)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btSingle: begin
                 aOpenArrayData^.DataSingle := aOpenArrayData^.DataSingle + [[]];
                 SetLength(aOpenArrayData^.DataSingle[High(aOpenArrayData^.DataSingle)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataSingle[High(aOpenArrayData^.DataSingle)][i] := PSingle(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataSingle[High(aOpenArrayData^.DataSingle)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btDouble: begin
                 aOpenArrayData^.DataDouble := aOpenArrayData^.DataDouble + [[]];
                 SetLength(aOpenArrayData^.DataDouble[High(aOpenArrayData^.DataDouble)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataDouble[High(aOpenArrayData^.DataDouble)][i] := PDouble(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataDouble[High(aOpenArrayData^.DataDouble)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btExtended: begin
                 aOpenArrayData^.DataExtended := aOpenArrayData^.DataExtended + [[]];
                 SetLength(aOpenArrayData^.DataExtended[High(aOpenArrayData^.DataExtended)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataExtended[High(aOpenArrayData^.DataExtended)][i] := PExtended(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataExtended[High(aOpenArrayData^.DataExtended)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btString: begin
                 aOpenArrayData^.DataString := aOpenArrayData^.DataString + [[]];
                 SetLength(aOpenArrayData^.DataString[High(aOpenArrayData^.DataString)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataString[High(aOpenArrayData^.DataString)][i] := ptbtString(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataString[High(aOpenArrayData^.DataString)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btPChar: begin
                 aOpenArrayData^.DataPChar := aOpenArrayData^.DataPChar + [[]];
                 SetLength(aOpenArrayData^.DataPChar[High(aOpenArrayData^.DataPChar)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataPChar[High(aOpenArrayData^.DataPChar)][i] := PtbtPChar(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataPChar[High(aOpenArrayData^.DataPChar)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btVariant, btNotificationVariant: begin
                 //For array of variant we need IntPIFVariantToVariant to get actual Variant values
                 aOpenArrayData^.DataVariant := aOpenArrayData^.DataVariant + [[]];
                 SetLength(aOpenArrayData^.DataVariant[High(aOpenArrayData^.DataVariant)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   if not IntPIFVariantToVariant(elemIFC.Dta, elemIFC.aType, aOpenArrayData^.DataVariant[High(aOpenArrayData^.DataVariant)][i]) then begin
                     Result := False;
                     Exit;
                   end;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataVariant[High(aOpenArrayData^.DataVariant)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               {$IFNDEF PS_NOINT64}
               btS64: begin
                 aOpenArrayData^.DataS64 := aOpenArrayData^.DataS64 + [[]];
                 SetLength(aOpenArrayData^.DataS64[High(aOpenArrayData^.DataS64)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataS64[High(aOpenArrayData^.DataS64)][i] := PInt64(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataS64[High(aOpenArrayData^.DataS64)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btU64: begin
                 aOpenArrayData^.DataU64 := aOpenArrayData^.DataU64 + [[]];
                 SetLength(aOpenArrayData^.DataU64[High(aOpenArrayData^.DataU64)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataU64[High(aOpenArrayData^.DataU64)][i] := PUInt64(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataU64[High(aOpenArrayData^.DataU64)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               {$ENDIF}
               btChar: begin
                 aOpenArrayData^.DataChar := aOpenArrayData^.DataChar + [[]];
                 SetLength(aOpenArrayData^.DataChar[High(aOpenArrayData^.DataChar)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataChar[High(aOpenArrayData^.DataChar)][i] := ptbtChar(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataChar[High(aOpenArrayData^.DataChar)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               {$IFNDEF PS_NOWIDESTRING}
               btWideString: begin
                 aOpenArrayData^.DataWideString := aOpenArrayData^.DataWideString + [[]];
                 SetLength(aOpenArrayData^.DataWideString[High(aOpenArrayData^.DataWideString)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataWideString[High(aOpenArrayData^.DataWideString)][i] := ptbtWideString(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataWideString[High(aOpenArrayData^.DataWideString)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btWideChar: begin
                 aOpenArrayData^.DataWideChar := aOpenArrayData^.DataWideChar + [[]];
                 SetLength(aOpenArrayData^.DataWideChar[High(aOpenArrayData^.DataWideChar)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataWideChar[High(aOpenArrayData^.DataWideChar)][i] := ptbtWideChar(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataWideChar[High(aOpenArrayData^.DataWideChar)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btUnicodeString: begin
                 aOpenArrayData^.DataUnicodeString := aOpenArrayData^.DataUnicodeString + [[]];
                 SetLength(aOpenArrayData^.DataUnicodeString[High(aOpenArrayData^.DataUnicodeString)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataUnicodeString[High(aOpenArrayData^.DataUnicodeString)][i] := ptbtUnicodeString(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataUnicodeString[High(aOpenArrayData^.DataUnicodeString)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               {$ENDIF}
               btCurrency: begin
                 aOpenArrayData^.DataCurrency := aOpenArrayData^.DataCurrency + [[]];
                 SetLength(aOpenArrayData^.DataCurrency[High(aOpenArrayData^.DataCurrency)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataCurrency[High(aOpenArrayData^.DataCurrency)][i] := PCurrency(elemIFC.Dta)^;
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataCurrency[High(aOpenArrayData^.DataCurrency)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btClass: begin
                 aOpenArrayData^.DataClass := aOpenArrayData^.DataClass + [[]];
                 SetLength(aOpenArrayData^.DataClass[High(aOpenArrayData^.DataClass)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataClass[High(aOpenArrayData^.DataClass)][i] := TObject(elemIFC.Dta^);
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataClass[High(aOpenArrayData^.DataClass)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btInterface: begin
                 aOpenArrayData^.DataInterface := aOpenArrayData^.DataInterface + [[]];
                 SetLength(aOpenArrayData^.DataInterface[High(aOpenArrayData^.DataInterface)], l_high + 1);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   aOpenArrayData^.DataInterface[High(aOpenArrayData^.DataInterface)][i] := IInterface(elemIFC.Dta^);
                 end;
                 aValues := aValues + [TValue.From<Pointer>(@aOpenArrayData^.DataInterface[High(aOpenArrayData^.DataInterface)][0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
               btPointer: begin
                 //For array of const we need TValueArrayToArrayOfConst to get a TVarRec array
                 SetLength(arr, 0);
                 for i := 0 to l_high do begin
                   elemIFC := PSGetArrayField(aValue^, i);
                   if not PSVariantIFCToTValue(@elemIFC, arr, aValues1, aValues2, aOpenArrayData, aSelf) then begin
                     Result := False;
                     Exit;
                   end;
                 end;
                 aValues1 := aValues1 + arr;
                 arr_varrec := TValueArrayToArrayOfConst(arr);
                 aValues2 := aValues2 + arr_varrec;
                 aValues := aValues + [TValue.From<Pointer>(@arr_varrec[0])];
                 aValues := aValues + [TValue.From<NativeInt>(l_high)];
               end;
             else
              Result := False;
              exit;
             end;
           end
           else //dynarray = just push pointer
             aValues := aValues + [TValue.From<Pointer>(aValue^.dta)];
        end;
      //13
      btPointer:                        aValues := aValues + [TValue.From<Pointer>(aValue^.dta)];
      //14
      btPChar:                          aValues := aValues + [TValue.From<tbtPChar>(PtbtPChar(aValue^.dta)^)];
      //15
      //btResourcePointer
      //16
      btVariant:                        aValues := aValues + [TValue.From(Variant(aValue^.dta^))];
      {$IFNDEF PS_NOINT64}
      //17
      btS64:                            aValues := aValues + [TValue.From<Int64>(PInt64(aValue^.dta)^)];
      btU64:                            aValues := aValues + [TValue.From<UInt64>(PUInt64(aValue^.dta)^)];
      {$ENDIF}
      //18
      btChar:                            aValues := aValues + [TValue.From<tbtchar>(ptbtchar(aValue^.dta)^)];
      {$IFNDEF PS_NOWIDESTRING}
      //19
      btWideString:                      aValues := aValues + [TValue.From<tbtWideString>(ptbtWideString(aValue^.dta)^)];
      //20
      btWideChar:                        aValues := aValues + [TValue.From<tbtWideChar>(ptbtWideChar(aValue^.dta)^)];
      {$ENDIF}
      //21
      btProcPtr:
        begin
          procPtr := PPSVariantProcPtr(Pointer(IPointer(aValue^.dta) - SizeOf(TPSVariant)));
          if procPtr^.ProcNo <> 0 then
            method := MKMethod(aSelf, procPtr^.ProcNo)
          else begin
            method.Data := procPtr^.Self;
            method.Code := procPtr^.Ptr;
          end;

          Result := False;
          for rttiType in ctx.GetTypes do
            if (rttiType.TypeKind = tkMethod) and (rttiType.Name.ToUpper = String(aValue^.aType.ExportName)) then
            begin
              TValue.Make(@method, rttiType.Handle, methodValue);
              aValues := aValues + [methodValue];
              Result := True;
              Break;
            end;
        end;
      //22
      btStaticArray:                     aValues := aValues + [TValue.From<Pointer>(aValue^.dta)];
      //23
      btSet:
        begin
          case TPSTypeRec_Set(aValue^.aType).aByteSize  of
            1: aValues := aValues + [TValue.From<Byte>(pbyte(aValue^.dta)^)];
            2: aValues := aValues + [TValue.From<Word>(pWord(aValue^.dta)^)];
            3,
            4: aValues := aValues + [TValue.From<Cardinal>(pCardinal(aValue^.dta)^)];
          else
            aValues := aValues + [TValue.From<Pointer>(aValue^.dta)];
          end;
        end;
      //24
      btCurrency:                        aValues := aValues + [TValue.From<Currency>(PCurrency(aValue^.dta)^)];
      //25
      btClass:                           aValues := aValues + [TValue.From<TObject>(TObject(aValue^.dta^))];
      //26
      btInterface:                       aValues := aValues + [TValue.From<IInterface>(IInterface(aValue^.dta^))];
      //27, the same as btVariant
      btNotificationVariant:             aValues := aValues + [TValue.From(Variant(aValue^.dta^))];
      {$IFNDEF PS_NOWIDESTRING}
      //28
      btUnicodestring:                   aValues := aValues + [TValue.From<tbtUnicodeString>(ptbtUnicodeString(aValue^.dta)^)];
      {$ENDIF}
      //131
      //btExtClass
      //129
      //btEnum
      //130
      //btType
    else
      Result := False;
    end;  { case }
end;

function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
var SysCalConv : TCallConv;
    Args: TArray<TValue>;
    old_Args: TArray<TValue>;
    old_Args2: TArray<TVarRec>;
    OpenArrayData: TOpenArrayData;
    Arg : TValue;
    i : Integer;
    fvar: PPSVariantIFC;
    IsConstr : Boolean;
    IsStatic : Boolean;
    ctx: TRTTIContext;
    RttiType : TRttiType;
    ResValue : TValue;
begin
  Result := False;
  IsStatic := _Self = nil;
  case CallingConv of
    cdRegister : SysCalConv := ccReg;
    cdPascal : SysCalConv := ccPascal;
    cdCdecl : SysCalConv := ccCdecl;
    cdStdCall : SysCalConv := ccStdCall;
    cdSafeCall : SysCalConv := ccSafeCall;
  else
    SysCalConv := ccReg;//to prevent warning "W1036 Variable might not have been initialized"
  end;

  FillChar(OpenArrayData, SizeOf(OpenArrayData), 0);

  if not IsStatic then begin
    {$IFDEF CPUX86}
    if CallingConv <> cdPascal then
    {$ENDIF CPUX86}
      Args := Args + [TValue.From<Pointer>( _Self )];
  end;

  old_Args := [];
  for I := 0 to Params.Count - 1 do
  begin
    if Params[i] = nil
      then Exit;
    fvar := Params[i];

    if fvar.varparam then
    begin { var param }
      case fvar.aType.BaseType of
        btArray, btVariant, btSet, btStaticArray, btRecord, btInterface, btClass, {$IFNDEF PS_NOWIDESTRING} btWideString, btWideChar, {$ENDIF}
        btU8, btS8, btU16, btS16, btU32, btS32, btSingle, btDouble, btExtended, btString, btPChar, btChar, btCurrency,
        btUnicodeString
        {$IFNDEF PS_NOINT64}, bts64, btU64{$ENDIF}:
          Arg := TValue.From<Pointer>( Pointer(fvar.dta) );
        else
          begin
            Exit;
          end;
      end;
      Args := Args + [Arg];
    end
    else begin
      if not PSVariantIFCToTValue(fvar, Args, old_Args, old_Args2, @OpenArrayData, Self) then Exit;
    end;
  end;

  {$IFDEF CPUX86}
  if not IsStatic then begin
    if CallingConv = cdPascal then
      Args := Args + [TValue.From<Pointer>( _Self )];
  end;
  {$ENDIF CPUX86}

  IsConstr := (Integer(CallingConv) and 64) <> 0;
  if not assigned(res) then
  begin
    Invoke(Address, Args, SysCalConv, nil);  { ignore return }
  end
  else begin
    case res.atype.basetype of
      //1,2
      btU8, btS8:              PByte(res.dta)^ := Byte(Invoke(Address,Args,SysCalConv,TypeInfo(Byte),IsStatic).AsInteger);
      //3,4
      btU16, btS16:            PWord(res.dta)^ := Word(Invoke(Address,Args,SysCalConv,TypeInfo(Word),IsStatic).AsInteger);
      //5,6
      btU32, btS32:            PCardinal(res.dta)^ := Cardinal(Invoke(Address,Args,SysCalConv,TypeInfo(Cardinal),IsStatic).AsInteger);
      //7
      btSingle:                PSingle(res.dta)^ := Single(Invoke(Address,Args,SysCalConv,TypeInfo(Single),IsStatic).AsExtended);
      //8
      btDouble:                PDouble(res.dta)^ := Double(Invoke(Address,Args,SysCalConv,TypeInfo(Double),IsStatic).AsExtended);
      //9
      btExtended:              PExtended(res.dta)^ := Extended(Invoke(Address,Args,SysCalConv,TypeInfo(Extended),IsStatic).AsExtended);
      //10
      btString:                tbtString(res.dta^) := tbtString(Invoke(Address,Args,SysCalConv,TypeInfo(tbtString),IsStatic).AsString);
      {$IFNDEF FPC}
      //11
      btRecord:
      begin
        for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkRecord) then
          begin
            CopyArrayContents(res.dta, (Invoke(Address,Args,SysCalConv,RttiType.Handle,IsStatic).GetReferenceToRawData), 1, res.aType);
            Break;
          end;
      end;
      {$ENDIF}
      //12
      btArray: //need to check with open arrays
      begin
        for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkDynArray) then
          begin
            ResValue := Invoke(Address,Args,SysCalConv,RttiType.Handle,IsStatic);
            if ResValue.GetArrayLength > 0 then
              CopyArrayContents(res.dta, ResValue.GetReferenceToRawData, 1, res.aType)
            else
              res.dta := nil;
            Break;
          end;
      end;
      //13
      btPointer:               res.dta := Pointer(Invoke(Address,Args,SysCalConv,TypeInfo(Pointer),IsStatic).AsType<Pointer>);
      //14
      btPChar:
        {$IFDEF FPC}
          ptbtPChar(res.dta)^ := tbtPChar(Invoke(Address,Args,SysCalConv,TypeInfo(tbtPChar),IsStatic).AsOrdinal);
        {$ELSE}
          ptbtPChar(res.dta)^ := tbtPChar(Invoke(Address,Args,SysCalConv,TypeInfo(tbtPChar),IsStatic).AsType<tbtPChar>());
        {$ENDIF}
      //15
      //btResourcePointer
      //16
      btVariant:               PVariant(res.dta)^ := Invoke(Address, Args, SysCalConv, TypeInfo(Variant), IsStatic).AsVariant;
      {$IFNDEF PS_NOINT64}
      //17
      bts64:                   PInt64(res.dta)^ := Int64(Invoke(Address,Args,SysCalConv,TypeInfo(Int64),IsStatic).AsInt64);
      btU64:                   PUInt64(res.dta)^ := UInt64(Invoke(Address,Args,SysCalConv,TypeInfo(UInt64),IsStatic).AsUInt64);
      {$ENDIF}
      //18
      btChar:
        {$IFDEF FPC}
          ptbtchar(res.dta)^ := tbtchar(Invoke(Address,Args,SysCalConv,TypeInfo(tbtchar),IsStatic).AsChar);
        {$ELSE}
          ptbtchar(res.dta)^ := tbtchar(Invoke(Address,Args,SysCalConv,TypeInfo(tbtchar),IsStatic).AsType<tbtchar>());
        {$ENDIF}
      {$IFNDEF PS_NOWIDESTRING}
      //19
      btWideString:
        {$IFDEF FPC}
          tbtWideString(res.dta^) := Invoke(Address,Args,SysCalConv,TypeInfo(WideString),IsStatic).AsUnicodeString;
        {$ELSE}
          tbtWideString(res.dta^) := Invoke(Address,Args,SysCalConv,TypeInfo(WideString),IsStatic).AsString;
        {$ENDIF}
      //20
      btWideChar:
        {$IFDEF FPC}
          ptbtWideChar(res.dta)^ := tbtWideChar(Invoke(Address,Args,SysCalConv,TypeInfo(tbtWideChar),IsStatic).AsWideChar);
        {$ELSE}
          ptbtWideChar(res.dta)^ := tbtWideChar(Invoke(Address,Args,SysCalConv,TypeInfo(tbtWideChar),IsStatic).AsType<tbtWideChar>());
        {$ENDIF}
      {$ENDIF}
      //21
      btProcPtr:
        {$IFDEF FPC}
          TMethod(res.dta^) := TMethod(Invoke(Address,Args,SysCalConv,TypeInfo(TMethod),IsStatic).AsOrdinal);
        {$ELSE}
          TMethod(res.dta^) := Invoke(Address,Args,SysCalConv,TypeInfo(TMethod),IsStatic).AsType<TMethod>;
        {$ENDIF}
      //22
      {$IFNDEF FPC}
      btStaticArray:
      begin
        for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkArray) then
          begin
            CopyArrayContents(res.dta, Invoke(Address,Args,SysCalConv,RttiType.Handle,IsStatic).GetReferenceToRawData, TPSTypeRec_StaticArray(res.aType).Size, TPSTypeRec_StaticArray(res.aType).ArrayType);
            Break;
          end;
      end;
      {$ENDIF}
      //23
      btSet:
        begin
          case TPSTypeRec_Set(res.aType).aByteSize  of
            1: byte(res.Dta^) := Byte(Invoke(Address,Args,SysCalConv,TypeInfo(Byte),IsStatic).AsInteger);
            2: word(res.Dta^) := word(Invoke(Address,Args,SysCalConv,TypeInfo(Word),IsStatic).AsInteger);
            3,
            4: Longint(res.Dta^) := Cardinal(Invoke(Address,Args,SysCalConv,TypeInfo(Cardinal),IsStatic).AsInteger);
            {$IFNDEF FPC}
            else
            begin
              for RttiType in ctx.GetTypes do
                if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkSet)
                  and (RttiType.TypeSize = TPSTypeRec_Set(res.aType).aByteSize) then
                begin
                  Invoke(Address,Args,SysCalConv,RttiType.Handle,IsStatic).ExtractRawData(res.dta);
                  Break;
                end;
            end;
            {$ENDIF}
          end;
        end;
      //24
      btCurrency: PCurrency(res.dta)^ := Currency(Invoke(Address,Args,SysCalConv,TypeInfo(Currency),IsStatic).AsCurrency);
      //25
      btClass:
      begin
        {$IFNDEF FPC}for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkClass) then{$ENDIF}
          begin
            TObject(res.dta^) := Invoke(Address,Args,SysCalConv,{$IFDEF FPC}TypeInfo(TObject){$ELSE}RttiType.Handle{$ENDIF},IsStatic, IsConstr).AsObject;
            {$IFNDEF FPC}Break;{$ENDIF}
          end;
      end;
      //26
      btInterface: PIInterface(res.dta)^ := IInterface(Invoke(Address,Args,SysCalConv,TypeInfo(IInterface),IsStatic).AsInterface);
      //27, the same as btVariant
      btNotificationVariant:  PVariant(res.dta)^ := Invoke(Address, Args, SysCalConv, TypeInfo(Variant), IsStatic).AsVariant;
      {$IFNDEF PS_NOWIDESTRING}
      btUnicodeString:
        {$IFDEF FPC}
        tbtUnicodeString(res.dta^) := Invoke(Address,Args,SysCalConv,TypeInfo(UnicodeString),IsStatic).AsUnicodeString;
        {$ELSE}
        tbtUnicodeString(res.dta^) := Invoke(Address,Args,SysCalConv,TypeInfo(UnicodeString),IsStatic).AsString;
        {$ENDIF}
      {$ENDIF}
      //131
      //btExtClass
      //129
      //btEnum
      //130
      //btType
      else
//          writeln(stderr, 'Result type not implemented!');
        Exit;
    end;  { case }
  end; //assigned(res)
  SetLength(Args, 0);
  SetLength(old_Args, 0);
  SetLength(old_Args2, 0);
  //OpenArrayData arrays are cleaned up automatically when the record goes out of scope
  Result := True;
end;
