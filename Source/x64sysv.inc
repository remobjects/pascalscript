{ x86_64 System V: classification of records up to 16 bytes, each eightbyte
  travels in a general purpose or in a SSE register. }
type
  TSysVClass = (scNone, scSse, scInt);
  TSysVClasses = array[0..1] of TSysVClass;


procedure SysVMark(var c: TSysVClasses; ofs, size: Integer; cl: TSysVClass);
var i: Integer;
begin
  for i := ofs div 8 to (ofs + size - 1) div 8 do
    if (i <= 1) and (c[i] <> scInt) then
      c[i] := cl;
end;

procedure SysVWalk(t: TPSTypeRec; ofs: Integer; var c: TSysVClasses);
var i, n: Integer; r: TPSTypeRec_Record; a: TPSTypeRec_StaticArray;
begin
  case t.BaseType of
    btRecord:
      begin
        r := TPSTypeRec_Record(t);
        for i := 0 to r.FieldTypes.Count - 1 do
          SysVWalk(TPSTypeRec(r.FieldTypes[i]),
            ofs + Integer(IPointer(r.RealFieldOffsets[i])), c);
      end;
    btStaticArray:
      begin
        a := TPSTypeRec_StaticArray(t);
        n := a.Size;
        for i := 0 to n - 1 do
          SysVWalk(a.ArrayType, ofs + i * Integer(a.ArrayType.RealSize), c);
      end;
    btSingle:
      SysVMark(c, ofs, 4, scSse);
    btDouble:
      SysVMark(c, ofs, 8, scSse);
  else
    SysVMark(c, ofs, t.RealSize, scInt);
  end;
end;

