{ ARM64 runtime call bridge (FPC + Linux/macOS SysV only)

  This include contains the Pascal-side marshalling logic used by TPSExec.InnerfuseCall
  on AArch64 targets.  The low-level indirect call is delegated to arm64call in
  arm64sysv.S.

  High-level flow:
    1) Convert TPSVariant arguments to ABI-ready integer/float register values.
    2) Spill overflow arguments to an aligned stack buffer.
    3) Prepare hidden-result arguments/registers for managed/indirect result types.
    4) Call arm64call, which performs the actual register+stack setup and BLR.
    5) Copy return values back into Pascal Script result storage.
}

{$IFDEF CPUAARCH64}
  {$IFDEF DARWIN}
    {$L arm64sysv-macos.o}
  {$ELSE}
    {$L arm64sysv-linux.o}
  {$ENDIF}
{$ENDIF}


type
  TARM64Registers = packed record
    X1, X2, X3, X4, X5, X6, X7: IPointer;
    X8: IPointer; // indirect result register for AArch64 ABI
    D1, D2, D3, D4, D5, D6, D7: Double;
    FloatBits: Integer; // bits 0..7 = single args in D0..D7, bit 8 = single result
  end;

  EmptyPchar: array[0..0] of char = #0;

procedure arm64call(
  Address: Pointer;
  var _X0: IPointer;
  var _D0: Double;
  constref Registers: TARM64Registers;
  Stack: Pointer;
  Items: NativeInt); external {$IFDEF DARWIN}name '_arm64call'{$ENDIF};

function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
var
  Stack: array of Byte;
  _X0: IPointer;
  _D0: Double;
  Registers: TARM64Registers;
  IntRegUsage: Byte;
  FloatRegUsage: Byte;
  CallData: TPSList;
  I: Integer;
  pp: ^Byte;
{$IFDEF FPC}
  IsConstructor, IsVirtualCons: Boolean;
{$ENDIF}

  function rp(p: PPSVariantIFC): PPSVariantIFC;
  begin
    if p = nil then
      Exit(nil);
    if p.aType.BaseType = btPointer then
    begin
      p^.aType := Pointer(Pointer(IPointer(p^.dta) + PointerSize)^);
      p^.Dta := Pointer(p^.dta^);
    end;
    Result := p;
  end;

  procedure StoreIntReg(Data: IPointer);
  var
    p: Pointer;
  begin
    case IntRegUsage of
      0: begin Inc(IntRegUsage); _X0 := Data; end;
      1: begin Inc(IntRegUsage); Registers.X1 := Data; end;
      2: begin Inc(IntRegUsage); Registers.X2 := Data; end;
      3: begin Inc(IntRegUsage); Registers.X3 := Data; end;
      4: begin Inc(IntRegUsage); Registers.X4 := Data; end;
      5: begin Inc(IntRegUsage); Registers.X5 := Data; end;
      6: begin Inc(IntRegUsage); Registers.X6 := Data; end;
      7: begin Inc(IntRegUsage); Registers.X7 := Data; end;
    else
      begin
        SetLength(Stack, Length(Stack) + 8);
        p := @Stack[Length(Stack) - 8];
        IPointer(p^) := Data;
      end;
    end;
  end;

  procedure StoreFloatReg(const Data: Double; IsSingle: Boolean);
  var
    p: Pointer;
    Bit: Integer;
  begin
    if FloatRegUsage < 8 then
    begin
      Bit := 1 shl FloatRegUsage;
      if IsSingle then
        Registers.FloatBits := Registers.FloatBits or Bit;
      case FloatRegUsage of
        0: _D0 := Data;
        1: Registers.D1 := Data;
        2: Registers.D2 := Data;
        3: Registers.D3 := Data;
        4: Registers.D4 := Data;
        5: Registers.D5 := Data;
        6: Registers.D6 := Data;
        7: Registers.D7 := Data;
      end;
      Inc(FloatRegUsage);
    end else begin
      SetLength(Stack, Length(Stack) + 8);
      p := @Stack[Length(Stack) - 8];
      Double(p^) := Data;
    end;
  end;

  procedure StoreStack(const aData; Len: Integer);
  var
    p: Pointer;
  begin
    if (Len > 8) and ((Length(Stack) mod 16) <> 0) then
      SetLength(Stack, Length(Stack) + (16 - (Length(Stack) mod 16)));
    SetLength(Stack, Length(Stack) + Len);
    p := @Stack[Length(Stack) - Len];
    Move(aData, p^, Len);
  end;

  function GetPtr(fVar: PPSVariantIFC): Boolean;
  var
    VarPtr: Pointer;
    p: Pointer;
  begin
    Result := False;
    if FVar = nil then
      Exit;

    if fVar.VarParam then
    begin
      case fvar.aType.BaseType of
        btArray:
          begin
            if Copy(fvar.aType.ExportName, 1, 10) = '!OPENARRAY' then
            begin
              p := CreateOpenArray(True, Self, FVar);
              if p = nil then
                Exit;
              CallData.Add(p);
              StoreIntReg(IPointer(POpenArray(p)^.Data));
              StoreIntReg(IPointer(POpenArray(p)^.ItemCount - 1));
              Result := True;
              Exit;
            end;
            VarPtr := fvar.Dta;
          end;
        btVariant, btSet, btStaticArray, btRecord, btInterface, btClass,
        {$IFNDEF PS_NOWIDESTRING}btUnicodeString, btWideString, btWideChar,{$ENDIF}
        btU8, btS8, btU16, btS16, btU32, btS32, btSingle, btDouble,
        btExtended, btString, btPChar, btChar, btCurrency
        {$IFNDEF PS_NOINT64}, btS64, btU64{$ENDIF}:
          VarPtr := fvar.Dta;
      else
        Exit;
      end;
      StoreIntReg(IPointer(VarPtr));
    end else begin
      case fVar^.aType.BaseType of
        btSet:
          case TPSTypeRec_Set(fvar.aType).aByteSize of
            1: StoreIntReg(IPointer(Byte(fvar.dta^)));
            2: StoreIntReg(IPointer(Word(fvar.dta^)));
            3, 4: StoreIntReg(IPointer(Cardinal(fvar.dta^)));
            5, 6, 7, 8: StoreIntReg(IPointer(fVar.Dta^));
          else
            StoreIntReg(IPointer(fvar.Dta));
          end;
        btArray:
          begin
            if Copy(fvar^.aType.ExportName, 1, 10) = '!OPENARRAY' then
            begin
              p := CreateOpenArray(False, Self, FVar);
              if p = nil then
                Exit;
              CallData.Add(p);
              StoreIntReg(IPointer(POpenArray(p)^.Data));
              StoreIntReg(IPointer(POpenArray(p)^.ItemCount - 1));
              Result := True;
              Exit;
            end;
            {$IFDEF FPC}
            StoreIntReg(IPointer(FVar.Dta));
            {$ELSE}
            StoreIntReg(IPointer(FVar.Dta^));
            {$ENDIF}
          end;
        btRecord:
          begin
            if fvar^.aType.RealSize <= SizeOf(IPointer) then
              StoreIntReg(IPointer(fvar.dta^))
            else if fvar^.aType.RealSize <= 16 then
              StoreStack(fvar.Dta^, fvar^.aType.RealSize)
            else
              StoreIntReg(IPointer(fVar.Dta));
          end;
        btVariant, btStaticArray:
          StoreIntReg(IPointer(fVar.Dta));
        btExtended, btDouble:
          StoreFloatReg(Double(fvar.dta^), False);
        btCurrency:
          StoreIntReg(IPointer(fvar.dta^));
        btSingle:
          StoreFloatReg(Single(fvar.dta^), True);
        btChar, btU8, btS8:
          StoreIntReg(IPointer(Byte(fVar^.dta^)));
        {$IFNDEF PS_NOWIDESTRING}
        btWideChar,
        {$ENDIF}
        btU16, btS16:
          StoreIntReg(IPointer(Word(FVar^.dta^)));
        btU32, btS32:
          StoreIntReg(IPointer(Cardinal(FVar^.dta^)));
        btPChar:
          if Pointer(fvar^.dta^) = nil then
            StoreIntReg(IPointer(EmptyPChar))
          else
            StoreIntReg(IPointer(fvar^.dta^));
        btClass, btInterface, btString{$IFNDEF PS_NOWIDESTRING}, btWideString, btUnicodeString{$ENDIF}:
          StoreIntReg(IPointer(fvar^.dta^));
        btProcPtr:
          begin
            GetMem(p, PointerSize2);
            TMethod(p^) := MKMethod(Self, Longint(FVar.Dta^));
            StoreStack(p^, PointerSize2);
            FreeMem(p);
          end;
        {$IFNDEF PS_NOINT64}
        btS64:
          StoreIntReg(IPointer(Int64(fvar^.dta^)));
        btU64:
          StoreIntReg(IPointer(UInt64(fvar^.dta^)));
        {$ENDIF}
      else
        Exit;
      end;
    end;
    Result := True;
  end;
begin
{$IFDEF FPC}
  if (Integer(CallingConv) and 128) <> 0 then
  begin
    IsVirtualCons := True;
    CallingConv := TPSCallingConvention(Integer(CallingConv) and not 128);
  end else
    IsVirtualCons := False;
  if (Integer(CallingConv) and 64) <> 0 then
  begin
    IsConstructor := True;
    CallingConv := TPSCallingConvention(Integer(CallingConv) and not 64);
  end else
    IsConstructor := False;
{$ENDIF}

  InnerfuseCall := False;
  if Address = nil then
    Exit;

  SetLength(Stack, 0);
  CallData := TPSList.Create;
  res := rp(res);
  if res <> nil then
    res.VarParam := True;
  try
    FillChar(Registers, SizeOf(Registers), 0);
    _X0 := 0;
    _D0 := 0;
    IntRegUsage := 0;
    FloatRegUsage := 0;

    {$IF DEFINED(FPC) and (FPC_VERSION >= 3)}
    if IsConstructor then
    begin
      if not GetPtr(rp(Params[0])) then
        Exit;
      DisposePPSVariantIFC(Params[0]);
      Params.Delete(0);
    end;
    {$ENDIF}

    if Assigned(_Self) then
      StoreIntReg(IPointer(_Self));

    if Assigned(res) then
    begin
      case res^.aType.BaseType of
        btRecord, btSet:
          if res.aType.RealSize > 16 then
          begin
            Registers.X8 := IPointer(res.Dta);
            {$IFNDEF MSWINDOWS}
            // FPC AArch64 managed-result ABI uses a hidden first argument in x0.
            StoreIntReg(IPointer(res.Dta));
            {$ENDIF}
          end;
        btString, {$IFNDEF PS_NOWIDESTRING}btWideString, btUnicodeString,{$ENDIF}
        btInterface, btArray, btVariant, btStaticArray:
          begin
            Registers.X8 := IPointer(res.Dta);
            {$IFNDEF MSWINDOWS}
            // Keep x8 for C-style ABI while also passing hidden result in x0 for Pascal ABI.
            StoreIntReg(IPointer(res.Dta));
            {$ENDIF}
          end;
      end;
      if res^.aType.BaseType = btSingle then
        Registers.FloatBits := Registers.FloatBits or 256;
    end;

    for I := 0 to Params.Count - 1 do
      if not GetPtr(rp(Params[I])) then
        Exit;

    if (Length(Stack) mod 16) <> 0 then
      SetLength(Stack, Length(Stack) + (16 - (Length(Stack) mod 16)));

    if Length(Stack) = 0 then
      pp := nil
    else
      pp := @Stack[0];

    arm64call(Address, _X0, _D0, Registers, pp, Length(Stack) div 8);

    if Assigned(res) then
    begin
      case res^.aType.BaseType of
        btRecord, btSet:
          if res.aType.RealSize <= 8 then
            case res.aType.RealSize of
              1: Byte(res.Dta^) := _X0;
              2: Word(res.Dta^) := _X0;
              3, 4: Cardinal(res.Dta^) := _X0;
              5, 6, 7, 8: IPointer(res.Dta^) := _X0;
            end;
        btSingle: tbtsingle(res.Dta^) := _D0;
        btDouble: tbtdouble(res.Dta^) := _D0;
        btExtended: tbtextended(res.Dta^) := _D0;
        btChar, btU8, btS8: tbtu8(res.dta^) := _X0;
        {$IFNDEF PS_NOWIDESTRING}
        btWideChar,
        {$ENDIF}
        btU16, btS16: tbtu16(res.dta^) := _X0;
        btClass: IPointer(res.dta^) := _X0;
        btU32, btS32: tbtu32(res.dta^) := _X0;
        btPChar: pansichar(res.dta^) := Pansichar(_X0);
        {$IFNDEF PS_NOINT64}
        btS64: tbts64(res.dta^) := Int64(_X0);
        {$ENDIF}
        btCurrency: tbts64(res.Dta^) := Int64(_X0);
        btInterface, btVariant, btStaticArray, btArray,
        btString{$IFNDEF PS_NOWIDESTRING}, btWideString, btUnicodeString{$ENDIF}: ;
      else
        Exit;
      end;
    end;

    Result := True;
  finally
    for I := CallData.Count - 1 downto 0 do
    begin
      pp := CallData[I];
      case pp^ of
        0: DestroyOpenArray(Self, Pointer(pp));
      end;
    end;
    CallData.Free;
  end;
end;
