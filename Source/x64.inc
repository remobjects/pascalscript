{ implementation of x64 abi }
//procedure DebugBreak; external 'Kernel32.dll';
const
  EmptyPchar: array[0..0] of char = #0;
{$ASMMODE INTEL}

{$IFDEF WINDOWS}
procedure x64call(
  Address: Pointer;
  out _RAX: IPointer;
  _RCX, _RDX, _R8, _R9: IPointer;
  var _XMM0: Double;
  _XMM1, _XMM2, _XMM3: Double;
  aStack: Pointer; aItems: Integer); assembler; nostackframe;
asm
(* Registers:
    RCX: Address
    RDX: *_RAX
    R8: _RCX
    R9: _RDX

    fpc inserts an 20h emty space
*)
  push ebp
  mov ebp,esp
//  call debugbreak
  push rcx  // address
  push rdx  // _rax
  push r8   // _rcx
  push r9   // _rdx
  mov rcx, aItems
  mov rdx, aStack
  jmp @compareitems
@work:
  push [rdx]
  dec rcx
  sub rdx,8
@compareitems:
  or rcx, rcx
  jnz @work

  // copy registers
  movd xmm0,[_XMM0]
  movd xmm1,_XMM1
  movd xmm2,_XMM2
  movd xmm3,_XMM3
  mov RAX, [rbp-8]
  mov RCX, [rbp-24]
  mov RDX, [rbp-32]
  mov R8, _R8
  mov R9, _R9

  // weird thing on windows, it needs 32 bytes in the CALLEE side to do whatever in
  sub RSP, 32

  call RAX

  add RSP, 32 // undo the damage done earlier

  // copy result back
  mov RDX, [rbp-16]
  mov [RDX], RAX
  movd [_XMM0],xmm0

  pop r9
  pop r8
  pop rdx
  pop rcx
  leave
  ret
end;
{$ELSE}
procedure x64call(
  Address: Pointer;
  out _RAX: IPointer;
  _RDI, _RSI, _RDX, _RCX, _R8, _R9: IPointer;
  var _XMM0: Double;
  _XMM1, _XMM2, _XMM3, _XMM4, _XMM5, _XMM6, _XMM7: Double;
  aStack: Pointer; aItems: Integer); assembler; nostackframe;


asm
(* Registers:
    RDI: Address
    RSI: _RAX
    RDX: _RDI
    RCX: _RSI
    R8:  _RDX
    R9:  _RCX


*)
  push ebp
  mov ebp,esp
  push rdi  // address
  push rsi  // _rax
  push rdx  // _rdi
  push rcx  // _rsi
  push r8   // _rdx
  push r9   // _rcx
  mov rcx, aItems
  mov rdx, aStack
  jmp @compareitems
@work:
  push [rdx]
  dec rcx
  sub rdx,8
@compareitems:
  or rcx, rcx
  jnz @work

  // copy registers
  movd xmm0,[_XMM0]
  movd xmm1,_XMM1
  movd xmm2,_XMM2
  movd xmm3,_XMM3
  movd xmm4,_XMM4
  movd xmm5,_XMM5
  movd xmm6,_XMM6
  movd xmm7,_XMM7
  mov RAX, [rbp-8]
  mov RDI, [rbp-24]
  mov RSI, [rbp-32]
  mov RDX, [rbp-40]
  mov RCX, [rbp-48]
  mov R8, _R8
  mov R9, _R9

  // weird thing on windows, it needs 32 bytes in the CALLEE side to do whatever in; not sure about linux
  //sub RSP, 32

  call RAX

  // add RSP, 32 // undo the damage done earlier

  // copy result back
  mov RDX, [rbp-16]
  mov [RDX], RAX
  movd [_XMM0],xmm0

  pop r9
  pop r8
  pop rdx
  pop rcx
  pop rsi
  pop rdi
  leave
  ret
end;
{$ENDIF}

function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
var
  Stack: array of Byte;
  _RAX,
{$IFDEF WINDOWS}
  _RCX, _RDX, _R8, _R9: IPointer;
  _XMM0, _XMM1, _XMM2, _XMM3: Double;
{$ELSE}
  _RDI, _RSI, _RDX, _RCX, _R8, _R9: IPointer;
  _XMM0, _XMM1, _XMM2, _XMM3, _XMM4, _XMM5, _XMM6, _XMM7: Double;
  RegUsageFloat: Byte;
{$ENDIF}
  RegUsage: Byte;
  CallData: TPSList;
  I: Integer;
  pp: ^Byte;

  function rp(p: PPSVariantIFC): PPSVariantIFC;
  begin
    if p = nil then
    begin
      result := nil;
      exit;
    end;
    if p.aType.BaseType = btPointer then
    begin
      p^.aType := Pointer(Pointer(IPointer(p^.dta) + PointerSize)^);
      p^.Dta := Pointer(p^.dta^);
    end;
    Result := p;
  end;
{$IFDEF WINDOWS}
  procedure StoreReg(data: IPointer);   overload;
  var p: Pointer;
  begin
    case RegUsage of
      0: begin inc(RegUsage); _RCX:=Data; end;
      1: begin inc(RegUsage); _RDX:=Data; end;
      2: begin inc(RegUsage); _R8:=Data; end;
      3: begin inc(RegUsage); _R9:=Data; end;
    else begin
      SetLength(Stack, Length(Stack)+8);
      p := @Stack[LEngth(Stack)-8];
      IPointer(p^) := data;
    end;
    end;
  end;
  {$ELSE}
  procedure StoreReg(data: IPointer);   overload;
  var p: Pointer;
  begin
    case RegUsage of
      0: begin inc(RegUsage); _RDI:=Data; end;
      1: begin inc(RegUsage); _RSI:=Data; end;
      2: begin inc(RegUsage); _RDX:=Data; end;
      3: begin inc(RegUsage); _RCX:=Data; end;
      4: begin inc(RegUsage); _R8:=Data; end;
      5: begin inc(RegUsage); _R9:=Data; end;
    else begin
      SetLength(Stack, Length(Stack)+8);
      p := @Stack[LEngth(Stack)-8];
      IPointer(p^) := data;
    end;
    end;
  end;
{$ENDIF}

  procedure StoreStack(const aData; Len: Integer);
  var
    p: Pointer;
  begin
    if Len > 8 then
      if Length(Stack) mod 16 <> 0 then begin
        SetLength(Stack, Length(Stack)+ (16-(Length(Stack) mod 16)));
      end;
    SetLength(Stack, Length(Stack)+Len);
    p := @Stack[Length(Stack)-Len];
    Move(aData, p^, Len);
  end;

{$IFDEF WINDOWS}
  procedure StoreReg(data: Double); overload;
  var p: Pointer;
  begin
    case RegUsage of
      0: begin inc(RegUsage); _XMM0:=Data; end;
      1: begin inc(RegUsage); _XMM1:=Data; end;
      2: begin inc(RegUsage); _XMM2:=Data; end;
      3: begin inc(RegUsage); _XMM3:=Data; end;
    else begin
      SetLength(Stack, Length(Stack)+8);
      p := @Stack[LEngth(Stack)-8];
      Double(p^) := data;
    end;
    end;
  end;
  {$ELSE}
  procedure StoreReg(data: Double); overload;
  var p: Pointer;
  begin
    case RegUsageFloat of
      0: begin inc(RegUsageFloat); _XMM0:=Data; end;
      1: begin inc(RegUsageFloat); _XMM1:=Data; end;
      2: begin inc(RegUsageFloat); _XMM2:=Data; end;
      3: begin inc(RegUsageFloat); _XMM3:=Data; end;
      4: begin inc(RegUsageFloat); _XMM4:=Data; end;
      5: begin inc(RegUsageFloat); _XMM5:=Data; end;
      6: begin inc(RegUsageFloat); _XMM6:=Data; end;
      7: begin inc(RegUsageFloat); _XMM7:=Data; end;
    else begin
      SetLength(Stack, Length(Stack)+8);
      p := @Stack[LEngth(Stack)-8];
      Double(p^) := data;
    end;
    end;
  end;
  {$ENDIF}
  function GetPtr(fVar: PPSVariantIFC): Boolean;
  var
    varPtr: Pointer;
    //UseReg: Boolean;
    //tempstr: tbtstring;
    p: Pointer;
  begin
    Result := False;
    if FVar = nil then exit;
    if fVar.VarParam then
    begin
      case fvar.aType.BaseType of
        btArray:
          begin
            if Copy(fvar.aType.ExportName, 1, 10) = '!OPENARRAY' then
            begin
              p := CreateOpenArray(True, Self, FVar);
              if p = nil then exit;
              CallData.Add(p);
              StoreReg(IPointer(POpenArray(p)^.Data));
              StoreReg(IPointer(POpenArray(p)^.ItemCount -1));
              Result := True;
              Exit;
            end else begin
              varptr := fvar.Dta;
//              Exit;
            end;
          end;
        btVariant,
        btSet,
        btStaticArray,
        btRecord,
        btInterface,
        btClass,
        {$IFNDEF PS_NOWIDESTRING} btUnicodeString, btWideString, btWideChar, {$ENDIF} btU8, btS8, btU16,
        btS16, btU32, btS32, btSingle, btDouble, btExtended, btString, btPChar, btChar, btCurrency
        {$IFNDEF PS_NOINT64}, bts64{$ENDIF}:
          begin
            Varptr := fvar.Dta;
          end;
      else begin
          exit; //invalid type
        end;
      end; {case}

      StoreReg(IPointer(VarPtr));
    end else begin
//      UseReg := True;
      case fVar^.aType.BaseType of
        btSet:
          begin
            case TPSTypeRec_Set(fvar.aType).aByteSize of
              1: StoreReg(IPointer(byte(fvar.dta^)));
              2: StoreReg(IPointer(word(fvar.dta^)));
              3, 4: StoreReg(IPointer(cardinal(fvar.dta^)));
              5,6,7,8: StoreReg(IPointer(fVar.Dta^));
              else
                StoreReg(IPointer(fvar.Dta));
            end;
          end;
        btArray:
          begin
            if Copy(fvar^.aType.ExportName, 1, 10) = '!OPENARRAY' then
            begin
              p := CreateOpenArray(False, SElf, FVar);
              if p =nil then exit;
              CallData.Add(p);
              StoreReg(IPointer(POpenArray(p)^.Data));
              StoreReg(IPointer(POpenArray(p)^.ItemCount -1));
              Result := True;
              exit;
            end else begin
              StoreReg(IPointer(FVar.Dta^));
            end;
          end;
        btVariant
        , btStaticArray, btRecord:
          begin
            StoreReg(IPointer(fVar.Dta));
          end;
        btExtended, btDouble: {8 bytes} begin
            StoreReg(double(fvar.dta^));
          end;
        btCurrency: {8 bytes} begin
            StoreReg(IPointer(fvar.dta^));
          end;
        btSingle: {4 bytes} begin
            StoreReg(single(fvar.dta^));
          end;

        btChar,
        btU8,
        btS8: begin
            StoreReg(IPointer(byte(fVar^.dta^)));
          end;
        btWideChar,
        btu16, btS16: begin
            StoreReg(IPointer(word(fVar^.dta^)));
          end;
        btu32, bts32: begin
            StoreReg(IPointer(cardinal(fVar^.dta^)));
          end;
        btPchar:
          begin
            if pointer(fvar^.dta^) = nil then
              StoreReg(IPointer(@EmptyPchar))
            else
              StoreReg(IPointer(fvar^.dta^));
          end;
        btclass, btinterface, btString:
          begin
            StoreReg(IPointer(fvar^.dta^));
          end;
        btWideString: begin
            StoreReg(IPointer(fvar^.dta^));
          end;
        btUnicodeString: begin
            StoreReg(IPointer(fvar^.dta^));
          end;

        btProcPtr:
          begin
            GetMem(p, PointerSize2);
            TMethod(p^) := MKMethod(Self, Longint(FVar.Dta^));
            StoreStack(p^, Pointersize2);
            FreeMem(p);
          end;

        bts64:
          begin
            StoreReg(IPointer(int64(fvar^.dta^)));
        end;
      end; {case}
    end;
    Result := True;
  end;
begin
  InnerfuseCall := False;
  if Address = nil then
    exit; // need address
  SetLength(Stack, 0);
  CallData := TPSList.Create;
  res := rp(res);
  if res <> nil then
    res.VarParam := true;
  try
{$IFNDEF WINDOWS}
    _RSI := 0;
    _RDI := 0;
    _XMM4 := 0;
    _XMM5 := 0;
    _XMM6 := 0;
    _XMM7 := 0;
    RegUsageFloat := 0;
{$ENDIF}
    _RCX := 0;
    _RDX := 0;
    _R8 := 0;
    _R9 := 0;
    _XMM0 := 0;
    _XMM1 := 0;
    _XMM2 := 0;
    _XMM3 := 0;
    RegUsage := 0;
    if assigned(_Self) then begin
      RegUsage := 1;
      _RCX := IPointer(_Self);
    end;
    for I := 0 to Params.Count - 1 do
    begin
      if not GetPtr(rp(Params[I])) then Exit;
    end;

    if assigned(res) then begin
      case res^.aType.BaseType of
        {$IFDEF x64_string_result_as_varparameter}
        btstring, btWideString, btUnicodeString,
        {$ENDIF}
        btInterface, btArray, btrecord, btVariant, btStaticArray: GetPtr(res);
        btSet:
          begin
            if TPSTypeRec_Set(res.aType).aByteSize > PointerSize then GetPtr(res);
          end;
      end;
      if Stack = nil then pp := nil else pp := @Stack[Length(Stack) -8];
{$IFDEF WINDOWS}
      x64call(Address, _RAX, _RCX, _RDX, _R8, _R9, _XMM0, _XMM1, _XMM2, _XMM3, pp, Length(Stack) div 8);
{$ELSE}
      x64call(Address, _RAX, _RDI, _RSI, _RDX, _RCX, _R8, _R9,_XMM0,_XMM1, _XMM2, _XMM3, _XMM4, _XMM5, _XMM6, _XMM7, pp, Length(Stack) div 8);
{$ENDIF}
      case res^.aType.BaseType of
        btSet:
          begin
            case TPSTypeRec_Set(res.aType).aByteSize  of
              1: byte(res.Dta^) := _RAX;
              2: word(res.Dta^) := _RAX;
              3,
              4: Longint(res.Dta^) := _RAX;
              5,6,7,8: IPointer(res.dta^) := _RAX;
            end;
          end;
        btSingle:      tbtsingle(res.Dta^) := _XMM0;
        btDouble:      tbtdouble(res.Dta^) := _XMM0;
        btExtended:    tbtextended(res.Dta^) := _XMM0;
        btchar,btU8, btS8:    tbtu8(res.dta^) := _RAX;
        btWideChar, btu16, bts16:  tbtu16(res.dta^) := _RAX;
        btClass : IPointer(res.dta^) := _RAX;
        btu32,bts32:   tbtu32(res.dta^) := _RAX;
        btPChar:       pansichar(res.dta^) := Pansichar(_RAX);
        bts64: tbts64(res.dta^) := Int64(_RAX);
        btCurrency:    tbtCurrency(res.Dta^) := Int64(_RAX);
        btInterface,
        btVariant,
        {$IFDEF x64_string_result_as_varparameter}
        btWidestring,btUnicodestring, btstring ,
        {$ENDIF}
        btStaticArray, btArray, btrecord:;
        {$IFNDEF x64_string_result_as_varparameter}
        btUnicodeString, btWideString, btstring:  Int64(res.dta^) := _RAX;
        {$ENDIF}
      else
        exit;
      end;
    end else begin
      if Stack = nil then pp := nil else pp := @Stack[Length(Stack) -8];
{$IFDEF WINDOWS}
       x64call(Address, _RAX, _RCX, _RDX, _R8, _R9, _XMM0, _XMM1, _XMM2, _XMM3, pp, Length(Stack) div 8);
{$ELSE}
       x64call(Address, _RAX, _RDI, _RSI, _RDX, _RCX, _R8, _R9,_XMM0,_XMM1, _XMM2, _XMM3, _XMM4, _XMM5, _XMM6, _XMM7, pp, Length(Stack) div 8);
{$ENDIF}
    end;
    Result := True;
  finally
    for i := CallData.Count -1 downto 0 do
    begin
      pp := CallData[i];
      case pp^ of
        0: DestroyOpenArray(Self, Pointer(pp));
      end;
    end;
    CallData.Free;
  end;
end;


