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

  S.RegisterDelphiFunction( @Sleep, 'Sleep', cdRegister );
  S.RegisterDelphiFunction( @GetModuleName, 'GetModuleName', cdRegister );
  S.RegisterDelphiFunction( @ByteToCharLen, 'ByteToCharLen', cdRegister );
  S.RegisterDelphiFunction( @CharToByteLen, 'CharToByteLen', cdRegister );
  S.RegisterDelphiFunction( @ByteToCharIndex, 'ByteToCharIndex', cdRegister );
  S.RegisterDelphiFunction( @CharToByteIndex, 'CharToByteIndex', cdRegister );
  S.RegisterDelphiFunction( @StrCharLength, 'StrCharLength', cdRegister );
  S.RegisterDelphiFunction( @StrNextChar, 'StrNextChar', cdRegister );
  S.RegisterDelphiFunction( @CharLength, 'CharLength', cdRegister );
  S.RegisterDelphiFunction( @NextCharIndex, 'NextCharIndex', cdRegister );
  S.RegisterDelphiFunction( @IsPathDelimiter, 'IsPathDelimiter', cdRegister );
  S.RegisterDelphiFunction( @IsDelimiter, 'IsDelimiter', cdRegister );
  S.RegisterDelphiFunction( @IncludeTrailingPathDelimiter, 'IncludeTrailingPathDelimiter', cdRegister );
  S.RegisterDelphiFunction( @IncludeTrailingBackslash, 'IncludeTrailingBackslash', cdRegister );
  S.RegisterDelphiFunction( @ExcludeTrailingPathDelimiter, 'ExcludeTrailingPathDelimiter', cdRegister );
  S.RegisterDelphiFunction( @ExcludeTrailingBackslash, 'ExcludeTrailingBackslash', cdRegister );
  S.RegisterDelphiFunction( @LastDelimiter, 'LastDelimiter', cdRegister );
  S.RegisterDelphiFunction( @AnsiCompareFileName, 'AnsiCompareFileName', cdRegister );
  S.RegisterDelphiFunction( @SameFileName, 'SameFileName', cdRegister );
  S.RegisterDelphiFunction( @AnsiLowerCaseFileName, 'AnsiLowerCaseFileName', cdRegister );
  S.RegisterDelphiFunction( @AnsiUpperCaseFileName, 'AnsiUpperCaseFileName', cdRegister );
  S.RegisterDelphiFunction( @AnsiPos, 'AnsiPos', cdRegister );
  S.RegisterDelphiFunction( @AnsiStrPos, 'AnsiStrPos', cdRegister );
//  S.RegisterDelphiFunction( @AnsiStrRScan, 'AnsiStrRScan', cdRegister );
//  S.RegisterDelphiFunction( @AnsiStrScan, 'AnsiStrScan', cdRegister );
  S.RegisterDelphiFunction( @StringReplace, 'StringReplace', cdRegister );

  S.RegisterDelphiFunction( @CheckWin32Version, 'CheckWin32Version', cdRegister );
  S.RegisterDelphiFunction( @GetFileVersion, 'GetFileVersion', cdRegister );
  {$IF CompilerVersion >= 28}
  S.RegisterDelphiFunction( @GetProductVersion, 'GetProductVersion', cdRegister );
  {$IFEND}
  S.RegisterDelphiFunction( @GetLocaleFormatSettings, 'GetLocaleFormatSettings', cdRegister );

  S.RegisterDelphiFunction( @ForceDirectories, 'ForceDirectories', cdRegister );
  S.RegisterDelphiFunction( @FindFirst, 'FindFirst', cdRegister );
  S.RegisterDelphiFunction( @FindNext, 'FindNext', cdRegister );
  S.RegisterDelphiFunction( @FindClose, 'FindClose', cdRegister );
  S.RegisterDelphiFunction( @FileGetDate, 'FileGetDate', cdRegister );
  S.RegisterDelphiFunction( @FileSetDate, 'FileSetDate', cdRegister );
  S.RegisterDelphiFunction( @FileIsReadOnly, 'FileIsReadOnly', cdRegister );
  S.RegisterDelphiFunction( @FileSetReadOnly, 'FileSetReadOnly', cdRegister );
  S.RegisterDelphiFunction( @DeleteFile, 'DeleteFile', cdRegister );
  S.RegisterDelphiFunction( @RenameFile, 'RenameFile', cdRegister );
  S.RegisterDelphiFunction( @ChangeFileExt, 'ChangeFileExt', cdRegister );
  S.RegisterDelphiFunction( @ExtractFilePath, 'ExtractFilePath', cdRegister );
  S.RegisterDelphiFunction( @ExtractFileDir, 'ExtractFileDir', cdRegister );
  S.RegisterDelphiFunction( @ExtractFileDrive, 'ExtractFileDrive', cdRegister );
  S.RegisterDelphiFunction( @ExtractFileName, 'ExtractFileName', cdRegister );
  S.RegisterDelphiFunction( @ExtractFileExt, 'ExtractFileExt', cdRegister );
  S.RegisterDelphiFunction( @ExpandFileName, 'ExpandFileName', cdRegister );
  S.RegisterDelphiFunction( @ExpandFileNameCase, 'ExpandFileNameCase', cdRegister );
  S.RegisterDelphiFunction( @ExpandUNCFileName, 'ExpandUNCFileName', cdRegister );
  S.RegisterDelphiFunction( @ExtractRelativePath, 'ExtractRelativePath', cdRegister );

  {$IF CompilerVersion >= 28}
  S.RegisterDelphiFunction( @ChangeFilePath, 'ChangeFilePath', cdRegister );
  S.RegisterDelphiFunction( @GetHomePath, 'GetHomePath', cdRegister );
  {$IFEND}
  S.RegisterDelphiFunction( @FileAge, 'FileAge', cdRegister );
  S.RegisterDelphiFunction( @FileExists, 'FileExists', cdRegister );
  S.RegisterDelphiFunction( @DirectoryExists, 'DirectoryExists', cdRegister );
  S.RegisterDelphiFunction( @IsValidIdent, 'IsValidIdent', cdRegister );

  S.RegisterDelphiFunction( @StrToBool, 'StrToBool', cdRegister );
  S.RegisterDelphiFunction( @StrToBoolDef, 'StrToBoolDef', cdRegister );
  S.RegisterDelphiFunction( @TryStrToBool, 'TryStrToBool', cdRegister );
  S.RegisterDelphiFunction( @BoolToStr, 'BoolToStr', cdRegister );

  S.RegisterDelphiFunction( @ExtractShortPathName, 'ExtractShortPathName', cdRegister );
  S.RegisterDelphiFunction( @FileSearch, 'FileSearch', cdRegister );
  S.RegisterDelphiFunction( @DiskFree, 'DiskFree', cdRegister );
  S.RegisterDelphiFunction( @DiskSize, 'DiskSize', cdRegister );
  S.RegisterDelphiFunction( @GetCurrentDir, 'GetCurrentDir', cdRegister );
//  S.RegisterDelphiFunction( @FloatToStr, 'FloatToStr', cdRegister );
  S.RegisterDelphiFunction( @FloatToStr, 'FloatToStrS', cdRegister );
  S.RegisterDelphiFunction( @CurrToStr, 'CurrToStr', cdRegister );
  S.RegisterDelphiFunction( @CurrToStr, 'CurrToStrS', cdRegister );
  S.RegisterDelphiFunction( @FloatToCurr, 'FloatToCurr', cdRegister );
  S.RegisterDelphiFunction( @TryFloatToCurr, 'TryFloatToCurr', cdRegister );
  S.RegisterDelphiFunction( @FloatToStrF, 'FloatToStrF', cdRegister );
  S.RegisterDelphiFunction( @FloatToStrF, 'FloatToStrFS', cdRegister );
  S.RegisterDelphiFunction( @CurrToStrF, 'CurrToStrF', cdRegister );
  S.RegisterDelphiFunction( @CurrToStrF, 'CurrToStrFS', cdRegister );
//  S.RegisterDelphiFunction( @FloatToText, 'FloatToText', cdRegister );
//  S.RegisterDelphiFunction( @FloatToText, 'FloatToTextS', cdRegister );
  S.RegisterDelphiFunction( @FormatFloat, 'FormatFloat', cdRegister );
  S.RegisterDelphiFunction( @FormatFloat, 'FormatFloatS', cdRegister );
  S.RegisterDelphiFunction( @FormatCurr, 'FormatCurr', cdRegister );
  S.RegisterDelphiFunction( @FormatCurr, 'FormatCurrS', cdRegister );
//  S.RegisterDelphiFunction( @FloatToTextFmt, 'FloatToTextFmt', cdRegister );
//  S.RegisterDelphiFunction( @FloatToTextFmt, 'FloatToTextFmtS', cdRegister );
//  S.RegisterDelphiFunction( @StrToFloat, 'StrToFloat', cdRegister );
  S.RegisterDelphiFunction( @StrToFloat, 'StrToFloatS', cdRegister );
  S.RegisterDelphiFunction( @StrToFloatDef, 'StrToFloatDef', cdRegister );
  S.RegisterDelphiFunction( @StrToFloatDef, 'StrToFloatDefS', cdRegister );
  S.RegisterDelphiFunction( @TryStrToFloat, 'TryStrToFloat', cdRegister );
  S.RegisterDelphiFunction( @TryStrToFloat, 'TryStrToFloatS', cdRegister );
  S.RegisterDelphiFunction( @StrToCurr, 'StrToCurr', cdRegister );
  S.RegisterDelphiFunction( @StrToCurr, 'StrToCurrS', cdRegister );
  S.RegisterDelphiFunction( @StrToCurrDef, 'StrToCurrDef', cdRegister );
  S.RegisterDelphiFunction( @StrToCurrDef, 'StrToCurrDefS', cdRegister );
  S.RegisterDelphiFunction( @TryStrToCurr, 'TryStrToCurr', cdRegister );
  S.RegisterDelphiFunction( @TryStrToCurr, 'TryStrToCurrS', cdRegister );
//  S.RegisterDelphiFunction( @FloatToDecimal, 'FloatToDecimal', cdRegister );
//  S.RegisterDelphiFunction( @TextToFloat, 'TextToFloat', cdRegister );
//  S.RegisterDelphiFunction( @TextToFloat, 'TextToFloatS', cdRegister );

  {$IF CompilerVersion >= 28}
  S.RegisterDelphiFunction( @TextToFloat, 'TextToExtended', cdRegister );
  S.RegisterDelphiFunction( @TextToFloat, 'TextToExtendedS', cdRegister );
  S.RegisterDelphiFunction( @TextToFloat, 'TextToDouble', cdRegister );
  S.RegisterDelphiFunction( @TextToFloat, 'TextToDoubleS', cdRegister );
  S.RegisterDelphiFunction( @TextToFloat, 'TextToCurrency', cdRegister );
  S.RegisterDelphiFunction( @TextToFloat, 'TextToCurrencyS', cdRegister );
//  S.RegisterDelphiFunction( @HashName, 'HashName', cdRegister );
  {$IFEND}

  S.RegisterDelphiFunction( @IntToHex, 'IntToHexD', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'Int64ToHexD', cdRegister );
  S.RegisterDelphiFunction( @TryStrToInt, 'TryStrToInt', cdRegister );
  S.RegisterDelphiFunction( @TryStrToInt64, 'TryStrToInt64', cdRegister );

  S.RegisterDelphiFunction( @LoadStr, 'LoadStr', cdRegister );
  S.RegisterDelphiFunction( @FmtLoadStr, 'FmtLoadStr', cdRegister );
  S.RegisterDelphiFunction( @FileOpen, 'FileOpen', cdRegister );
  S.RegisterDelphiFunction( @FileCreate, 'FileCreate', cdRegister );
  S.RegisterDelphiFunction( @FileCreate, 'FileCreateA', cdRegister );
//  S.RegisterDelphiFunction( @FileRead, 'FileRead', cdRegister );
//  S.RegisterDelphiFunction( @FileWrite, 'FileWrite', cdRegister );

  {$IF CompilerVersion >= 28}
  S.RegisterDelphiFunction( @FileRead, 'FileReadB', cdRegister );
  S.RegisterDelphiFunction( @FileWrite, 'FileWriteB', cdRegister );
  {$IFEND}

  S.RegisterDelphiFunction( @FileSeek, 'FileSeek', cdRegister );
  S.RegisterDelphiFunction( @FileClose, 'FileClose', cdRegister );
  S.RegisterDelphiFunction( @FileSetDate, 'FileSetDate', cdRegister );
  S.RegisterDelphiFunction( @FileGetAttr, 'FileGetAttr', cdRegister );
  S.RegisterDelphiFunction( @FileSetAttr, 'FileSetAttr', cdRegister );

  {$IF CompilerVersion >= 28}
  S.RegisterDelphiFunction( @IntToHex, 'ShortIntToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'ByteToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'SmallIntToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'WordToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'IntToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'CardinalToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'Int64ToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'UInt64ToHex', cdRegister );
  S.RegisterDelphiFunction( @IntToHex, 'UInt64ToHexD', cdRegister );
  S.RegisterDelphiFunction( @StrToUInt, 'StrToUInt', cdRegister );
  S.RegisterDelphiFunction( @StrToUIntDef, 'StrToUIntDef', cdRegister );
  S.RegisterDelphiFunction( @TryStrToUInt, 'TryStrToUInt', cdRegister );
  S.RegisterDelphiFunction( @StrToUInt64Def, 'StrToUInt64Def', cdRegister );
  S.RegisterDelphiFunction( @TryStrToUInt64, 'TryStrToUInt64', cdRegister );
  S.RegisterDelphiFunction( @IsRelativePath, 'IsRelativePath', cdRegister );
  S.RegisterDelphiFunction( @IsAssembly, 'IsAssembly', cdRegister );
  S.RegisterDelphiFunction( @FileCreate, 'FileCreate', cdRegister );
  S.RegisterDelphiFunction( @FileCreateSymLink, 'FileCreateSymLink', cdRegister );
  S.RegisterDelphiFunction( @FileGetSymLinkTarget, 'FileGetSymLinkTarget', cdRegister );
  S.RegisterDelphiFunction( @FileSystemAttributes, 'FileSystemAttributes', cdRegister );
  S.RegisterDelphiFunction( @FileGetDateTimeInfo, 'FileGetDateTimeInfo', cdRegister );
  {$IFEND}
end;

end.
