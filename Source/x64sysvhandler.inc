{ x86_64 System V: script procedure called as a Pascal method (GetProcAsMethod).
  RDI = Self (PScriptMethodInfo), then the hidden result pointer if any, then
  the parameters: integers in RSI RDX RCX R8 R9, floats in XMM0..7, the rest
  on the stack. Extended travels on the stack, 16 bytes aligned. }
type
  TSysVFrame = packed record
    Int: array[0..5] of IPointer;     //   0: RDI RSI RDX RCX R8 R9
    Xmm: array[0..7] of Double;       //  48: XMM0..7, raw bits
    Stack: Pointer;                   // 112
    ResRax, ResRdx: IPointer;         // 120, 128
    ResXmm0, ResXmm1: Double;         // 136, 144
    ResIsExt: IPointer;               // 152
    ResExt: array[0..1] of IPointer;  // 160
  end;
  PSysVFrame = ^TSysVFrame;

function SysVHiddenResult(t: TPSTypeRec): Boolean;
begin
  case t.BaseType of
    btString, btWideString, btUnicodeString, btInterface, btArray, btVariant,
    btStaticArray:
      Result := True;
    btRecord:
      Result := t.RealSize > 16;
    btSet:
      Result := t.RealSize > PointerSize;
  else
    Result := False;
  end;
end;

procedure SysVHandler(F: PSysVFrame);
var
  Self: PScriptMethodInfo;
  Decl, s, e: tbtString;
  I, C, ir, fr: Integer;
  Params: TPSList;
  Res, Tmp: PIFVariant;
  cpt: PIFTypeRec;
  fmod: tbtchar;
  sp: PByte;
  ex: TPSExceptionHandler;
  cl: TSysVClasses;
  buf: array[0..1] of IPointer;
  slot: Pointer;

  function NextInt: Pointer;
  begin
    if ir < 6 then
    begin
      Result := @F^.Int[ir];
      Inc(ir);
    end
    else
    begin
      Result := sp;
      Inc(sp, 8);
    end;
  end;

  function NextFloat: Pointer;
  begin
    if fr < 8 then
    begin
      Result := @F^.Xmm[fr];
      Inc(fr);
    end
    else
    begin
      Result := sp;
      Inc(sp, 8);
    end;
  end;

  function SmallRecord(t: TPSTypeRec): Boolean;
  var k, ni, nf, n: Integer;
  begin
    n := (t.RealSize + 7) div 8;
    cl[0] := scNone;
    cl[1] := scNone;
    SysVWalk(t, 0, cl);
    ni := 0;
    nf := 0;
    for k := 0 to n - 1 do
      if cl[k] = scSse then
        Inc(nf)
      else
        Inc(ni);
    Result := (ir + ni <= 6) and (fr + nf <= 8);
    if Result then
    begin
      buf[0] := 0;
      buf[1] := 0;
      for k := 0 to n - 1 do
        if cl[k] = scSse then
          buf[k] := IPointer(NextFloat^)
        else
          buf[k] := IPointer(NextInt^);
    end
    else
    begin
      Move(sp^, buf, n * 8);
      Inc(sp, n * 8);
    end;
  end;

begin
  Self := PScriptMethodInfo(F^.Int[0]);
  ir := 1;
  fr := 0;
  sp := F^.Stack;
  Res := nil;
  Decl := TPSInternalProcRec(Self^.Se.FProcs[Self^.ProcNo]).ExportDecl;
  Params := TPSList.Create;
  s := Decl;
  grfw(s);
  while s <> '' do
  begin
    Params.Add(nil);
    grfw(s);
  end;
  C := Params.Count;

  s := Decl;
  e := grfw(s);
  if e <> '-1' then
  begin
    cpt := Self^.Se.GetTypeNo(StrToInt(e));
    if SysVHiddenResult(cpt) then
    begin
      Res := CreateHeapVariant(Self^.Se.FindType2(btPointer));
      PPSVariantPointer(Res).DestType := cpt;
      PPSVariantPointer(Res).DataDest := Pointer(NextInt^);
      F^.ResRax := IPointer(PPSVariantPointer(Res).DataDest);
    end
    else
      Res := CreateHeapVariant(cpt);
    Params.Add(Res);
  end;

  for I := C - 1 downto 0 do
  begin
    e := grfw(s);
    fmod := e[1];
    Delete(e, 1, 1);
    cpt := Self^.Se.GetTypeNo(StrToInt(e));
    if (fmod in ['!', '%']) or (cpt.BaseType in [btVariant, btStaticArray]) or
       ((cpt.BaseType = btSet) and (cpt.RealSize > PointerSize)) or
       ((cpt.BaseType = btRecord) and (cpt.RealSize > 16) and (fmod = '&')) then
    begin
      Tmp := CreateHeapVariant(Self^.Se.FindType2(btPointer));
      PPSVariantPointer(Tmp).DestType := cpt;
      PPSVariantPointer(Tmp).DataDest := Pointer(NextInt^);
    end
    else
    begin
      Tmp := CreateHeapVariant(cpt);
      case cpt.BaseType of
        btSingle, btDouble:
          slot := NextFloat;
        btExtended:
          begin
            if (IPointer(sp) and 15) <> 0 then
              Inc(sp, 8);
            slot := sp;
            Inc(sp, 16);
          end;
        btRecord:
          if cpt.RealSize > 16 then
          begin
            slot := sp;
            Inc(sp, (cpt.RealSize + 7) and not 7);
          end
          else
          begin
            SmallRecord(cpt);
            slot := @buf;
          end;
      else
        slot := NextInt;
      end;
      CopyArrayContents(@PPSVariantData(Tmp)^.Data, slot, 1, cpt);
    end;
    Params[I] := Tmp;
  end;

  ex := TPSExceptionHandler.Create;
  ex.FinallyOffset := InvalidVal;
  ex.ExceptOffset := InvalidVal;
  ex.Finally2Offset := InvalidVal;
  ex.EndOfBlock := InvalidVal;
  ex.CurrProc := nil;
  ex.BasePtr := Self^.Se.FCurrStackBase;
  ex.StackSize := Self^.Se.FStack.Count;
  I := Self^.Se.FExceptionStack.Add(ex);
  Self^.Se.RunProc(Params, Self^.ProcNo);
  if Self^.Se.FExceptionStack[I] = ex then
  begin
    Self^.Se.FExceptionStack.Remove(ex);
    ex.Free;
  end;

  if Res <> nil then
  begin
    Params.DeleteLast;
    cpt := Res^.FType;
    if not ((cpt.BaseType = btPointer) and (PPSVariantPointer(Res).DataDest <> nil)
      and (Pointer(F^.ResRax) = PPSVariantPointer(Res).DataDest)) then
      case cpt.BaseType of
        btSingle:
          PSingle(@F^.ResXmm0)^ := PPSVariantSingle(Res).Data;
        btDouble:
          F^.ResXmm0 := PPSVariantDouble(Res).Data;
        btExtended:
          begin
            Move(PPSVariantExtended(Res).Data, F^.ResExt, SizeOf(tbtextended));
            F^.ResIsExt := 1;
          end;
        btCurrency: { scaled Int64, but returned in ST0 }
          begin
            Move(PPSVariantCurrency(Res).Data, F^.ResExt, 8);
            F^.ResIsExt := 2;
          end;
        btRecord:
          begin
            cl[0] := scNone;
            cl[1] := scNone;
            SysVWalk(cpt, 0, cl);
            buf[0] := 0;
            buf[1] := 0;
            CopyArrayContents(@buf, @PPSVariantData(Res)^.Data, 1, cpt);
            ir := 0;
            fr := 0;
            for I := 0 to (cpt.RealSize + 7) div 8 - 1 do
              if cl[I] = scSse then
              begin
                if fr = 0 then
                  Double(Pointer(@F^.ResXmm0)^) := Double(Pointer(@buf[I])^)
                else
                  Double(Pointer(@F^.ResXmm1)^) := Double(Pointer(@buf[I])^);
                Inc(fr);
              end
              else
              begin
                if ir = 0 then
                  F^.ResRax := buf[I]
                else
                  F^.ResRdx := buf[I];
                Inc(ir);
              end;
          end;
      else
        CopyArrayContents(@F^.ResRax, @PPSVariantData(Res)^.Data, 1, cpt);
      end;
    DestroyHeapVariant(Res);
  end;
  for I := 0 to Params.Count - 1 do
    DestroyHeapVariant(Params[I]);
  Params.Free;
  if Self^.Se.ExEx <> erNoError then
  begin
    if Self^.Se.ExObject <> nil then
    begin
      slot := Self^.Se.ExObject;
      Self^.Se.ExObject := nil;
      raise TObject(slot);
    end
    else
      raise EPSException.Create(PSErrorToString(Self^.Se.ExceptionCode,
        Self^.Se.ExceptionString), Self^.Se, Self^.Se.ExProc, Self^.Se.ExPos);
  end;
end;

procedure MyAllMethodsHandler; assembler; nostackframe;
asm
  push rbp
  mov rbp, rsp
  sub rsp, 176
  mov [rsp+0], rdi
  mov [rsp+8], rsi
  mov [rsp+16], rdx
  mov [rsp+24], rcx
  mov [rsp+32], r8
  mov [rsp+40], r9
  movq [rsp+48], xmm0
  movq [rsp+56], xmm1
  movq [rsp+64], xmm2
  movq [rsp+72], xmm3
  movq [rsp+80], xmm4
  movq [rsp+88], xmm5
  movq [rsp+96], xmm6
  movq [rsp+104], xmm7
  lea rax, [rbp+16]
  mov [rsp+112], rax
  xor eax, eax
  mov [rsp+120], rax
  mov [rsp+128], rax
  mov [rsp+136], rax
  mov [rsp+144], rax
  mov [rsp+152], rax
  mov rdi, rsp
  call SysVHandler
  mov rax, [rsp+120]
  mov rdx, [rsp+128]
  movq xmm0, [rsp+136]
  movq xmm1, [rsp+144]
  mov rcx, [rsp+152]
  cmp rcx, 1
  jne @nofld
  fld tbyte ptr [rsp+160]
@nofld:
  cmp rcx, 2
  jne @nofild
  fild qword ptr [rsp+160]
@nofild:
  leave
  ret
end;
