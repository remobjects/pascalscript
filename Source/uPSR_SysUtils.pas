unit uPSR_SysUtils;
{$I PascalScript.inc}
interface

{$WARN UNSAFE_CODE OFF}

uses
  uPSRuntime;

procedure RegisterSysUtilsLibrary_R(S: TPSExec);

implementation

uses
  SysUtils;

procedure RegisterSysUtilsLibrary_R(S: TPSExec);
begin
//  s.RegisterDelphiFunction(@UpperCase, 'UpperCase', cdRegister );
  {$IF CompilerVersion >= 28}
  s.RegisterDelphiFunction(@UpperCase, 'UpperCaseS', cdRegister );
  {$IFEND}
//  s.RegisterDelphiFunction(@LowerCase, 'LowerCase', cdRegister );
  {$IF CompilerVersion >= 28}
  s.RegisterDelphiFunction(@LowerCase, 'LowerCaseS', cdRegister );
  {$IFEND}
  s.RegisterDelphiFunction(@CompareStr, 'CompareStr', cdRegister );
  {$IF CompilerVersion >= 28}
  s.RegisterDelphiFunction(@CompareStr, 'CompareStrS', cdRegister );
  {$IFEND}
  {$IF CompilerVersion >= 28}
  s.RegisterDelphiFunction(@SameStr, 'SameStr', cdRegister );
  s.RegisterDelphiFunction(@SameStr, 'SameStrS', cdRegister );
  {$IFEND}
  s.RegisterDelphiFunction(@CompareMem, 'CompareMem', cdRegister );
  s.RegisterDelphiFunction(@CompareText, 'CompareText', cdRegister );
  {$IF CompilerVersion >= 28}
  s.RegisterDelphiFunction(@CompareText, 'CompareTextS', cdRegister );
  {$IFEND}
  s.RegisterDelphiFunction(@SameText, 'SameText', cdRegister );
  {$IF CompilerVersion >= 28}
  s.RegisterDelphiFunction(@SameText, 'SameTextS', cdRegister );
  {$IFEND}
//  s.RegisterDelphiFunction(@AnsiUpperCase, 'AnsiUpperCase', cdRegister );
//  s.RegisterDelphiFunction(@AnsiLowerCase, 'AnsiLowerCase', cdRegister );
  s.RegisterDelphiFunction(@AnsiCompareStr, 'AnsiCompareStr', cdRegister );
  s.RegisterDelphiFunction(@AnsiSameStr, 'AnsiSameStr', cdRegister );
  s.RegisterDelphiFunction(@AnsiCompareText, 'AnsiCompareText', cdRegister );
  s.RegisterDelphiFunction(@AnsiSameText, 'AnsiSameText', cdRegister );
  s.RegisterDelphiFunction(@AnsiStrComp, 'AnsiStrComp', cdRegister );
  s.RegisterDelphiFunction(@AnsiStrIComp, 'AnsiStrIComp', cdRegister );
  s.RegisterDelphiFunction(@AnsiStrLComp, 'AnsiStrLComp', cdRegister );
  s.RegisterDelphiFunction(@AnsiStrLIComp, 'AnsiStrLIComp', cdRegister );
  s.RegisterDelphiFunction(@AnsiStrLower, 'AnsiStrLower', cdRegister );
  s.RegisterDelphiFunction(@AnsiStrUpper, 'AnsiStrUpper', cdRegister );
  s.RegisterDelphiFunction(@AnsiLastChar, 'AnsiLastChar', cdRegister );
  s.RegisterDelphiFunction(@AnsiStrLastChar, 'AnsiStrLastChar', cdRegister );
  s.RegisterDelphiFunction(@WideUpperCase, 'WideUpperCase', cdRegister );
  s.RegisterDelphiFunction(@WideLowerCase, 'WideLowerCase', cdRegister );
  s.RegisterDelphiFunction(@WideCompareStr, 'WideCompareStr', cdRegister );
  s.RegisterDelphiFunction(@WideSameStr, 'WideSameStr', cdRegister );
  s.RegisterDelphiFunction(@WideCompareText, 'WideCompareText', cdRegister );
  s.RegisterDelphiFunction(@WideSameText, 'WideSameText', cdRegister );
//  s.RegisterDelphiFunction(@Trim, 'Trim', cdRegister );
  s.RegisterDelphiFunction(@TrimLeft, 'TrimLeft', cdRegister );
  s.RegisterDelphiFunction(@TrimRight, 'TrimRight', cdRegister );
  s.RegisterDelphiFunction(@QuotedStr, 'QuotedStr', cdRegister );
  s.RegisterDelphiFunction(@AnsiQuotedStr, 'AnsiQuotedStr', cdRegister );
  s.RegisterDelphiFunction(@AnsiExtractQuotedStr, 'AnsiExtractQuotedStr', cdRegister );
  s.RegisterDelphiFunction(@AnsiDequotedStr, 'AnsiDequotedStr', cdRegister );

  s.RegisterDelphiFunction(@GetCurrentDir, 'GetCurrentDir', cdRegister );
  s.RegisterDelphiFunction(@SetCurrentDir, 'SetCurrentDir', cdRegister );
  s.RegisterDelphiFunction(@CreateDir, 'CreateDir', cdRegister );
  s.RegisterDelphiFunction(@RemoveDir, 'RemoveDir', cdRegister );
  s.RegisterDelphiFunction(@StrLen, 'StrLen', cdRegister );
  s.RegisterDelphiFunction(@StrEnd, 'StrEnd', cdRegister );
  s.RegisterDelphiFunction(@StrMove, 'StrMove', cdRegister );
  s.RegisterDelphiFunction(@StrCopy, 'StrCopy', cdRegister );
  s.RegisterDelphiFunction(@StrECopy, 'StrECopy', cdRegister );
  s.RegisterDelphiFunction(@StrLCopy, 'StrLCopy', cdRegister );
  s.RegisterDelphiFunction(@StrPCopy, 'StrPCopy', cdRegister );
  s.RegisterDelphiFunction(@StrPLCopy, 'StrPLCopy', cdRegister );
  s.RegisterDelphiFunction(@StrCat, 'StrCat', cdRegister );
  s.RegisterDelphiFunction(@StrLCat, 'StrLCat', cdRegister );
  s.RegisterDelphiFunction(@StrComp, 'StrComp', cdRegister );
  s.RegisterDelphiFunction(@StrIComp, 'StrIComp', cdRegister );
  s.RegisterDelphiFunction(@StrLComp, 'StrLComp', cdRegister );
  s.RegisterDelphiFunction(@StrLIComp, 'StrLIComp', cdRegister );
  s.RegisterDelphiFunction(@StrScan, 'StrScan', cdRegister );
  s.RegisterDelphiFunction(@StrRScan, 'StrRScan', cdRegister );
  s.RegisterDelphiFunction(@StrPos, 'StrPos', cdRegister );
  s.RegisterDelphiFunction(@StrUpper, 'StrUpper', cdRegister );
  s.RegisterDelphiFunction(@StrLower, 'StrLower', cdRegister );
  s.RegisterDelphiFunction(@StrPas, 'StrPas', cdRegister );
  s.RegisterDelphiFunction(@StrAlloc, 'StrAlloc', cdRegister );
  s.RegisterDelphiFunction(@StrBufSize, 'StrBufSize', cdRegister );
  s.RegisterDelphiFunction(@StrNew, 'StrNew', cdRegister );
  s.RegisterDelphiFunction(@StrDispose, 'StrDispose', cdRegister );
  s.RegisterDelphiFunction(@Format, 'Format', cdRegister );
  s.RegisterDelphiFunction(@Format, 'FormatS', cdRegister );
  s.RegisterDelphiFunction(@FmtStr, 'FmtStr', cdRegister );
  s.RegisterDelphiFunction(@FmtStr, 'FmtStrS', cdRegister );
  s.RegisterDelphiFunction(@StrFmt, 'StrFmt', cdRegister );
  s.RegisterDelphiFunction(@StrFmt, 'StrFmtS', cdRegister );
  s.RegisterDelphiFunction(@StrLFmt, 'StrLFmt', cdRegister );
  s.RegisterDelphiFunction(@StrLFmt, 'StrLFmtS', cdRegister );
//  s.RegisterDelphiFunction(@FormatBuf, 'FormatBuf', cdRegister );
//  s.RegisterDelphiFunction(@FormatBuf, 'FormatBufS', cdRegister );
  s.RegisterDelphiFunction(@WideFormat, 'WideFormat', cdRegister );
  s.RegisterDelphiFunction(@WideFormat, 'WideFormatS', cdRegister );
  s.RegisterDelphiFunction(@WideFmtStr, 'WideFmtStr', cdRegister );
  s.RegisterDelphiFunction(@WideFmtStr, 'WideFmtStrS', cdRegister );
//  s.RegisterDelphiFunction(@WideFormatBuf, 'WideFormatBuf', cdRegister );
//  s.RegisterDelphiFunction(@WideFormatBuf, 'WideFormatBufS', cdRegister );
end;

end.
