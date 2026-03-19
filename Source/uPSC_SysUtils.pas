unit uPSC_SysUtils;

interface

{$WARN SYMBOL_PLATFORM OFF}

uses
  uPSCompiler, uPSUtils;

procedure RegisterSysUtilsLibrary_C(S: TPSPascalCompiler);

implementation

uses
  SysUtils;

procedure RegisterSysUtilsLibrary_C(S: TPSPascalCompiler);
var
  T : String;
begin
  {$IF CompilerVersion >= 28}
  S.AddConstant('INVALID_HANDLE_VALUE', INVALID_HANDLE_VALUE);
  {$IFEND}

  S.AddConstant('fmOpenRead', fmOpenRead);
  S.AddConstant('fmOpenWrite', fmOpenWrite);
  S.AddConstant('fmOpenReadWrite', fmOpenReadWrite);
  {$IF Declared( fmExclusive )}
  S.AddConstant('fmExclusive', fmExclusive);
  {$IFEND}
  S.AddConstant('fmShareCompat', fmShareCompat);
  S.AddConstant('fmShareExclusive', fmShareExclusive);
  S.AddConstant('fmShareDenyWrite', fmShareDenyWrite);
  S.AddConstant('fmShareDenyRead', fmShareDenyRead);
  S.AddConstant('fmShareDenyNone', fmShareDenyNone);

  {$IF Declared( faInvalid )}
  S.AddConstant('faInvalid', faInvalid);
  {$IFEND}
  S.AddConstant('faReadOnly', faReadOnly);
  S.AddConstant('faHidden', faHidden);
  S.AddConstant('faSysFile', faSysFile);
  S.AddConstant('faVolumeID', faVolumeID);
  S.AddConstant('faDirectory', faDirectory);
  S.AddConstant('faArchive', faArchive);
  {$IF Declared( faNormal )}
  S.AddConstant('faNormal', faNormal);
  S.AddConstant('faTemporary', faTemporary);
  {$IFEND}
  S.AddConstant('faSymLink', faSymLink);
  {$IF Declared( faCompressed )}
  S.AddConstant('faCompressed', faCompressed);
  S.AddConstant('faEncrypted', faEncrypted);
  S.AddConstant('faVirtual', faVirtual );
  {$IFEND}
  S.AddConstant('faAnyFile', faAnyFile);

  S.AddConstant('PathDelim', tbtChar( PathDelim ) );
  S.AddConstant('DriveDelim', tbtChar( DriveDelim ) );
  S.AddConstant('PathSep', tbtChar( PathSep ) );

  S.AddConstant('DefaultTrueBoolStr', DefaultTrueBoolStr);
  S.AddConstant('DefaultFalseBoolStr', DefaultFalseBoolStr);

  S.AddConstant('MinCurrency', MinCurrency);
  S.AddConstant('MaxCurrency', MaxCurrency);

  S.AddTypeS( 'TSysCharSet', 'set of AnsiChar' );
//  S.AddTypeS( 'TIntegerSet', 'set of 0..31{SizeOf(Integer) * 8 - 1}' );
  S.AddTypeS( 'TByteArray', 'array[0..32767] of Byte;' );
  S.AddTypeS( 'TWordArray', 'array[0..16383] of Word;' );
  S.AddTypeCopyN( 'TFileName', 'string' );

  S.AddTypeS( 'TFloatValue', '(fvExtended, fvCurrency)' );
  S.AddTypeS( 'TFloatFormat', '(ffGeneral, ffExponent, ffFixed, ffNumber, ffCurrency)' );
  S.AddTypeS( 'TFloatRec', 'record Exponent: Smallint; Negative: Boolean; Digits: array[0..20] of Byte; end;' );
  S.AddTypeS( 'TTimeStamp', 'record Time: Integer; Date: Integer; end;' );
  S.AddTypeS( 'TMbcsByteType', '(mbSingleByte, mbLeadByte, mbTrailByte)' );
  S.AddTypeS( 'TBytes', 'Array of Byte' );

  {$IF CompilerVersion >= 28}
  S.AddTypeS( 'TLocaleOptions', '(loInvariantLocale, loUserLocale)' );
  {$IFEND}

  S.AddTypeCopyN( 'HMODULE', 'THandle' );

  t := '{packed }record dwFileAttributes: Integer; ftCreationTime: Int64; ftLastAccessTime: Int64; ftLastWriteTime: Int64; nFileSizeHigh: Integer; nFileSizeLow: Integer; dwReserved0: Integer; dwReserved1: Integer; cFileName: array[0..259] of Char; ' + 'cAlternateFileName: array[0..13] of Char; end;';
  S.AddTypeS( 'TWin32FindData', t );

  {$IF CompilerVersion >= 28}
  S.AddTypeS( 'TSearchRec', 'record Time: Integer; Size: Int64; Attr: Integer; Name: TFileName; ExcludeAttr: Integer; FindHandle: THandle; FindData: TWin32FindData; end;' );
  {$ELSE}
  S.AddTypeS( 'TSearchRec', 'record Time: Integer; Size: Integer; Attr: Integer; Name: TFileName; ExcludeAttr: Integer; FindHandle: THandle; FindData: TWin32FindData; end;' );
  {$IFEND}

  {$IF CompilerVersion >= 28}
  S.AddTypeS( 'TEraInfo', 'record EraName: string; EraOffset: Integer; EraStart: TDate; EraEnd: TDate; end;' );
  t := 'record CurrencyString: string; CurrencyFormat: Byte; CurrencyDecimals: Byte; DateSeparator: Char; TimeSeparator: Char; ListSeparator: Char; ShortDateFormat: string; LongDateFormat: string; TimeAMString: string; TimePMString: string; ShortTimeFormat:' +
       ' string; LongTimeFormat: string; ShortMonthNames: array[1..12] of string; LongMonthNames: array[1..12] of string; ShortDayNames: array[1..7] of string; LongDayNames: array[1..7] of string; EraInfo: array of TEraInfo; ThousandSeparator: Char; ' +
       'DecimalSeparator: Char; TwoDigitYearCenturyWindow: Word; NegCurrFormat: Byte; NormalizedLocaleName: string; end;';
  S.AddTypeS( 'TFormatSettings', t );
  {$ELSE}
  t := 'CurrencyFormat: Byte; NegCurrFormat: Byte; ThousandSeparator: Char; DecimalSeparator: Char; CurrencyDecimals: Byte; DateSeparator: Char; TimeSeparator: Char; ListSeparator: Char; CurrencyString: string; ShortDateFormat: string; LongDateFormat: string; ' +
       'TimeAMString: string; TimePMString: string; ShortTimeFormat: string; LongTimeFormat: string; ShortMonthNames: array[1..12] of string; LongMonthNames: array[1..12] of string; ShortDayNames: array[1..7] of string; LongDayNames: array[1..7] of string;' +
       ' TwoDigitYearCenturyWindow: Word; end;';
  S.AddTypeS( 'TFormatSettings', t );
  {$IFEND}

//  s.AddDelphiFunction('function UpperCase(const S: string): string;' );
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function UpperCaseS(const S: string; LocaleOptions: TLocaleOptions): string;' );
  {$IFEND}
//  s.AddDelphiFunction('function LowerCase(const S: string): string;' );
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function LowerCaseS(const S: string; LocaleOptions: TLocaleOptions): string;' );
  {$IFEND}
  s.AddDelphiFunction('function CompareStr(const S1, S2: string): Integer;' );
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function CompareStrS(const S1, S2: string; LocaleOptions: TLocaleOptions): Integer;' );
  {$IFEND}
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function SameStr(const S1, S2: string): Boolean;' );
  s.AddDelphiFunction('function SameStrS(const S1, S2: string; LocaleOptions: TLocaleOptions): Boolean;' );
  {$IFEND}
  s.AddDelphiFunction('function CompareMem(P1, P2: Pointer; Length: Integer): Boolean;' );
  s.AddDelphiFunction('function CompareText(const S1, S2: string): Integer;' );
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function CompareTextS(const S1, S2: string; LocaleOptions: TLocaleOptions): Integer;' );
  {$IFEND}
  s.AddDelphiFunction('function SameText(const S1, S2: string): Boolean;' );
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function SameTextS(const S1, S2: string; LocaleOptions: TLocaleOptions): Boolean;' );
  {$IFEND}
//  s.AddDelphiFunction('function AnsiUpperCase(const S: string): string;' );
//  s.AddDelphiFunction('function AnsiLowerCase(const S: string): string;' );
  s.AddDelphiFunction('function AnsiCompareStr(const S1, S2: string): Integer;' );
  s.AddDelphiFunction('function AnsiSameStr(const S1, S2: string): Boolean;' );
  s.AddDelphiFunction('function AnsiCompareText(const S1, S2: string): Integer;' );
  s.AddDelphiFunction('function AnsiSameText(const S1, S2: string): Boolean;' );
  s.AddDelphiFunction('function AnsiStrComp(S1, S2: PChar): Integer;' );
  s.AddDelphiFunction('function AnsiStrIComp(S1, S2: PChar): Integer;' );
  s.AddDelphiFunction('function AnsiStrLComp(S1, S2: PChar; MaxLen: Cardinal): Integer;' );
  s.AddDelphiFunction('function AnsiStrLIComp(S1, S2: PChar; MaxLen: Cardinal): Integer;' );
  s.AddDelphiFunction('function AnsiStrLower(Str: PChar): PChar;' );
  s.AddDelphiFunction('function AnsiStrUpper(Str: PChar): PChar;' );
  s.AddDelphiFunction('function AnsiLastChar(const S: string): PChar;' );
  s.AddDelphiFunction('function AnsiStrLastChar(P: PChar): PChar;' );
  s.AddDelphiFunction('function WideUpperCase(const S: WideString): WideString;' );
  s.AddDelphiFunction('function WideLowerCase(const S: WideString): WideString;' );
  s.AddDelphiFunction('function WideCompareStr(const S1, S2: WideString): Integer;' );
  s.AddDelphiFunction('function WideSameStr(const S1, S2: WideString): Boolean;' );
  s.AddDelphiFunction('function WideCompareText(const S1, S2: WideString): Integer;' );
  s.AddDelphiFunction('function WideSameText(const S1, S2: WideString): Boolean;' );
//  s.AddDelphiFunction('function Trim(const S: string): string;' );
  s.AddDelphiFunction('function TrimLeft(const S: string): string;' );
  s.AddDelphiFunction('function TrimRight(const S: string): string;' );
  s.AddDelphiFunction('function QuotedStr(const S: string): string;' );
  s.AddDelphiFunction('function AnsiQuotedStr(const S: string; Quote: Char): string;' );
  s.AddDelphiFunction('function AnsiExtractQuotedStr(var Src: PChar; Quote: Char): string;' );
  s.AddDelphiFunction('function AnsiDequotedStr(const S: string; AQuote: Char): string;' );

  s.AddDelphiFunction('function GetCurrentDir: string;' );
  s.AddDelphiFunction('function SetCurrentDir(const Dir: string): Boolean;' );
  s.AddDelphiFunction('function CreateDir(const Dir: string): Boolean;' );
  s.AddDelphiFunction('function RemoveDir(const Dir: string): Boolean;' );
  s.AddDelphiFunction('function StrLen(const Str: PChar): Cardinal;' );
  s.AddDelphiFunction('function StrEnd(const Str: PChar): PChar;' );
  s.AddDelphiFunction('function StrMove(Dest: PChar; const Source: PChar; Count: Cardinal): PChar;' );
  s.AddDelphiFunction('function StrCopy(Dest: PChar; const Source: PChar): PChar;' );
  s.AddDelphiFunction('function StrECopy(Dest:PChar; const Source: PChar): PChar;' );
  s.AddDelphiFunction('function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar;' );
  s.AddDelphiFunction('function StrPCopy(Dest: PChar; const Source: string): PChar;' );
  s.AddDelphiFunction('function StrPLCopy(Dest: PChar; const Source: string; MaxLen: Cardinal): PChar;' );
  s.AddDelphiFunction('function StrCat(Dest: PChar; const Source: PChar): PChar;' );
  s.AddDelphiFunction('function StrLCat(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar;' );
  s.AddDelphiFunction('function StrComp(const Str1, Str2: PChar): Integer;' );
  s.AddDelphiFunction('function StrIComp(const Str1, Str2: PChar): Integer;' );
  s.AddDelphiFunction('function StrLComp(const Str1, Str2: PChar; MaxLen: Cardinal): Integer;' );
  s.AddDelphiFunction('function StrLIComp(const Str1, Str2: PChar; MaxLen: Cardinal): Integer;' );
  s.AddDelphiFunction('function StrScan(const Str: PChar; AChr: Char): PChar;' );
  s.AddDelphiFunction('function StrRScan(const Str: PChar; AChr: Char): PChar;' );
  s.AddDelphiFunction('function StrPos(const Str1, Str2: PChar): PChar;' );
  s.AddDelphiFunction('function StrUpper(Str: PChar): PChar;' );
  s.AddDelphiFunction('function StrLower(Str: PChar): PChar;' );
  s.AddDelphiFunction('function StrPas(const Str: PChar): string;' );
  s.AddDelphiFunction('function StrAlloc(Size: Cardinal): PChar;' );
  s.AddDelphiFunction('function StrBufSize(const Str: PChar): Cardinal;' );
  s.AddDelphiFunction('function StrNew(const Str: PChar): PChar;' );
  s.AddDelphiFunction('procedure StrDispose(Str: PChar);' );
  s.AddDelphiFunction('function Format(const Format: string; const Args: array of const): string;' );
  s.AddDelphiFunction('function FormatS(const Format: string; const Args: array of const; const AFormatSettings: TFormatSettings): string;' );
  s.AddDelphiFunction('procedure FmtStr(var Result: string; const Format: string; const Args: array of const);' );
  s.AddDelphiFunction('procedure FmtStrS(var Result: string; const Format: string; const Args: array of const; const AFormatSettings: TFormatSettings);' );
  s.AddDelphiFunction('function StrFmt(Buffer, Format: PChar;  const Args: array of const): PChar;' );
  s.AddDelphiFunction('function StrFmtS(Buffer, Format: PChar; const Args: array of const; const FormatSettings: TFormatSettings): PChar;' );
  s.AddDelphiFunction('function StrLFmt(Buffer: PChar; MaxBufLen: Cardinal; Format: PChar; const Args: array of const): PChar;' );
  s.AddDelphiFunction('function StrLFmtS(Buffer: PChar; MaxBufLen: Cardinal; Format: PChar; const Args: array of const;  const FormatSettings: TFormatSettings): PChar;' );
//  s.AddDelphiFunction('function FormatBuf(var Buffer; BufLen: Cardinal; const Format; FmtLen: Cardinal; const Args: array of const): Cardinal;' );
//  s.AddDelphiFunction('function FormatBufS(var Buffer; BufLen: Cardinal; const Format; FmtLen: Cardinal; const Args: array of const; const FormatSettings: TFormatSettings): Cardinal;' );
  s.AddDelphiFunction('function WideFormat(const Format: WideString; const Args: array of const): WideString;' );
  s.AddDelphiFunction('function WideFormatS(const Format: WideString; const Args: array of const; const AFormatSettings: TFormatSettings): WideString;' );
  s.AddDelphiFunction('procedure WideFmtStr(var Result: WideString; const Format: WideString; const Args: array of const);' );
  s.AddDelphiFunction('procedure WideFmtStrS(var Result: WideString; const Format: WideString; const Args: array of const; const AFormatSettings: TFormatSettings);' );
//  s.AddDelphiFunction('function WideFormatBuf(var Buffer; BufLen: Cardinal; const Format; FmtLen: Cardinal; const Args: array of const): Cardinal;' );
//  s.AddDelphiFunction('function WideFormatBufS(var Buffer; BufLen: Cardinal; const Format; FmtLen: Cardinal; const Args: array of const; const AFormatSettings: TFormatSettings): Cardinal;' );

  s.AddDelphiFunction('procedure Sleep(milliseconds: Cardinal);');
  s.AddDelphiFunction('function GetModuleName(Module: HMODULE): string;');
  s.AddDelphiFunction('function ByteToCharLen(const S: string; MaxLen: Integer): Integer;');
  s.AddDelphiFunction('function CharToByteLen(const S: string; MaxLen: Integer): Integer;');
  s.AddDelphiFunction('function ByteToCharIndex(const S: string; Index: Integer): Integer;');
  s.AddDelphiFunction('function CharToByteIndex(const S: string; Index: Integer): Integer;');
  s.AddDelphiFunction('function StrCharLength(const Str: PChar): Integer;');
  s.AddDelphiFunction('function StrNextChar(const Str: PChar): PChar;');
  s.AddDelphiFunction('function CharLength(const S: String; Index: Integer): Integer;');
  s.AddDelphiFunction('function NextCharIndex(const S: String; Index: Integer): Integer;');
  s.AddDelphiFunction('function IsPathDelimiter(const S: string; Index: Integer): Boolean;');
  s.AddDelphiFunction('function IsDelimiter(const Delimiters, S: string; Index: Integer): Boolean;');
  s.AddDelphiFunction('function IncludeTrailingPathDelimiter(const S: string): string;');
  s.AddDelphiFunction('function IncludeTrailingBackslash(const S: string): string; platform;');
  s.AddDelphiFunction('function ExcludeTrailingPathDelimiter(const S: string): string;');
  s.AddDelphiFunction('function ExcludeTrailingBackslash(const S: string): string; platform;');
  s.AddDelphiFunction('function LastDelimiter(const Delimiters, S: string): Integer;');
  s.AddDelphiFunction('function AnsiCompareFileName(const S1, S2: string): Integer;');
  s.AddDelphiFunction('function SameFileName(const S1, S2: string): Boolean;');
  s.AddDelphiFunction('function AnsiLowerCaseFileName(const S: string): string;');
  s.AddDelphiFunction('function AnsiUpperCaseFileName(const S: string): string;');
  s.AddDelphiFunction('function AnsiPos(const Substr, S: string): Integer;');
  s.AddDelphiFunction('function AnsiStrPos(Str, SubStr: PChar): PChar;');
//  s.AddDelphiFunction('function AnsiStrRScan(Str: PChar; Chr: Char): PChar;');
//  s.AddDelphiFunction('function AnsiStrScan(Str: PChar; Chr: Char): PChar;');
  S.AddTypeS( 'TReplaceFlag', '(rfReplaceAll, rfIgnoreCase)' );
  S.AddTypeS( 'TReplaceFlags', 'set of TReplaceFlag' );
  s.AddDelphiFunction('function StringReplace(const S, OldPattern, NewPattern: string; Flags: TReplaceFlags): string;');

  s.AddDelphiFunction('function CheckWin32Version(AMajor: Integer; AMinor: Integer{ = 0}): Boolean;');
  s.AddDelphiFunction('function GetFileVersion(const AFileName: string): Cardinal;');
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function GetProductVersion(const AFileName: string; var AMajor, AMinor, ABuild: Cardinal): Boolean;');
  {$IFEND}
  s.AddDelphiFunction('procedure GetLocaleFormatSettings(LCID: Integer; var FormatSettings: TFormatSettings);');

  s.AddDelphiFunction('function ForceDirectories(Dir: string): Boolean;');
  s.AddDelphiFunction('function FindFirst(const Path: string; Attr: Integer; var F: TSearchRec): Integer;');
  s.AddDelphiFunction('function FindNext(var F: TSearchRec): Integer;');
  s.AddDelphiFunction('procedure FindClose(var F: TSearchRec);');
  s.AddDelphiFunction('function FileGetDate(Handle: Integer): Integer;');
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function FileSetDate(const FileName: string; Age: Integer): Integer;');
  {$ELSE}
  s.AddDelphiFunction('function FileSetDate(Handle: THandle; Age: Integer): Integer;');
  {$IFEND}

  s.AddDelphiFunction('function FileIsReadOnly(const FileName: string): Boolean;');
  s.AddDelphiFunction('function FileSetReadOnly(const FileName: string; ReadOnly: Boolean): Boolean;');
  s.AddDelphiFunction('function DeleteFile(const FileName: string): Boolean;');
  s.AddDelphiFunction('function RenameFile(const OldName, NewName: string): Boolean;');
  s.AddDelphiFunction('function ChangeFileExt(const FileName, Extension: string): string;');
  s.AddDelphiFunction('function ExtractFilePath(const FileName: string): string;');
  s.AddDelphiFunction('function ExtractFileDir(const FileName: string): string;');
  s.AddDelphiFunction('function ExtractFileDrive(const FileName: string): string;');
  s.AddDelphiFunction('function ExtractFileName(const FileName: string): string;');
  s.AddDelphiFunction('function ExtractFileExt(const FileName: string): string;');
  s.AddDelphiFunction('function ExpandFileName(const FileName: string): string;');

  S.AddTypeS( 'TFilenameCaseMatch', '(mkNone, mkExactMatch, mkSingleMatch, mkAmbiguous)' );
  s.AddDelphiFunction('function ExpandFileNameCase(const FileName: string; out MatchFound: TFilenameCaseMatch): string;');
  s.AddDelphiFunction('function ExpandUNCFileName(const FileName: string): string;');
  s.AddDelphiFunction('function ExtractRelativePath(const BaseName, DestName: string): string;');

  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function ChangeFilePath(const FileName : String; Path: string): string;');
  s.AddDelphiFunction('function GetHomePath: string;');
  {$IFEND}

  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function FileAge(const FileName: string): LongInt;');
  s.AddDelphiFunction('function FileExists(const FileName: string; FollowLink: Boolean{ = True}): Boolean;');
  s.AddDelphiFunction('function DirectoryExists(const Directory: string; FollowLink: Boolean{ = True}): Boolean;');
  {$ELSE}
  s.AddDelphiFunction('function FileAge(const FileName: string): Integer;');
  s.AddDelphiFunction('function FileExists(const FileName: string): Boolean;');
  s.AddDelphiFunction('function DirectoryExists(const Directory: string{; FollowLink: Boolean = True}): Boolean;');
  {$IFEND}

  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function IsValidIdent(const Ident: string; AllowDots: Boolean{ = False}): Boolean;');
  {$ELSE}
  s.AddDelphiFunction('function IsValidIdent(const Ident: string): Boolean;');
  {$IFEND}

  s.AddDelphiFunction('function StrToBool(const S: string): Boolean;');
  s.AddDelphiFunction('function StrToBoolDef(const S: string; const Default: Boolean): Boolean;');
  s.AddDelphiFunction('function TryStrToBool(const S: string; out Value: Boolean): Boolean;');
  s.AddDelphiFunction('function BoolToStr(B: Boolean; UseBoolStrs: Boolean{ = False}): string;');

  s.AddDelphiFunction('function ExtractShortPathName(const FileName: string): string;');
  s.AddDelphiFunction('function FileSearch(const Name, DirList: string): string;');
  s.AddDelphiFunction('function DiskFree(Drive: Byte): Int64;');
  s.AddDelphiFunction('function DiskSize(Drive: Byte): Int64;');
  s.AddDelphiFunction('function GetCurrentDir: string;');
//  s.AddDelphiFunction('function FloatToStr(Value: Extended): string;');
  s.AddDelphiFunction('function FloatToStrS(Value: Extended; const FormatSettings: TFormatSettings): string;');
  s.AddDelphiFunction('function CurrToStr(Value: Currency): string;');
  s.AddDelphiFunction('function CurrToStrS(Value: Currency; const FormatSettings: TFormatSettings): string;');
  s.AddDelphiFunction('function FloatToCurr(const Value: Extended): Currency;');
  s.AddDelphiFunction('function TryFloatToCurr(const Value: Extended; out AResult: Currency): Boolean;');
  s.AddDelphiFunction('function FloatToStrF(Value: Extended; Format: TFloatFormat; Precision: Integer; Digits: Integer): string;');
  s.AddDelphiFunction('function FloatToStrFS(Value: Extended; Format: TFloatFormat; Precision: Integer; Digits: Integer; const FormatSettings: TFormatSettings): string;');
  s.AddDelphiFunction('function CurrToStrF(Value: Currency; Format: TFloatFormat; Digits: Integer): string;');
  s.AddDelphiFunction('function CurrToStrFS(Value: Currency; Format: TFloatFormat; Digits: Integer; const FormatSettings: TFormatSettings): string;');
//  s.AddDelphiFunction('function FloatToText(BufferArg: PChar; const Value; ValueType: TFloatValue; Format: TFloatFormat; Precision: Integer; Digits: Integer): Integer;');
//  s.AddDelphiFunction('function FloatToTextS(BufferArg: PChar; const Value; ValueType: TFloatValue; Format: TFloatFormat; Precision: Integer; Digits: Integer; const FormatSettings: TFormatSettings): Integer;');
  s.AddDelphiFunction('function FormatFloat(const Format: string; Value: Extended): string;');
  s.AddDelphiFunction('function FormatFloatS(const Format: string; Value: Extended; const FormatSettings: TFormatSettings): string;');
  s.AddDelphiFunction('function FormatCurr(const Format: string; Value: Currency): string;');
  s.AddDelphiFunction('function FormatCurrS(const Format: string; Value: Currency; const FormatSettings: TFormatSettings): string;');
//  s.AddDelphiFunction('function FloatToTextFmt(Buf: PChar; const Value; ValueType: TFloatValue; Format: PChar): Integer;');
//  s.AddDelphiFunction('function FloatToTextFmtS(Buf: PChar; const Value; ValueType: TFloatValue; Format: PChar; const FormatSettings: TFormatSettings): Integer;');
//  s.AddDelphiFunction('function StrToFloat(const S: string): Extended;');
  s.AddDelphiFunction('function StrToFloatS(const S: string; const FormatSettings: TFormatSettings): Extended;');
  s.AddDelphiFunction('function StrToFloatDef(const S: string; const Default: Extended): Extended;');
  s.AddDelphiFunction('function StrToFloatDefS(const S: string; const Default: Extended; const FormatSettings: TFormatSettings): Extended;');
  s.AddDelphiFunction('function TryStrToFloat(const S: string; out Value: Extended): Boolean;');
  s.AddDelphiFunction('function TryStrToFloatS(const S: string; out Value: Extended; const FormatSettings: TFormatSettings): Boolean;');
  s.AddDelphiFunction('function TryStrToFloat(const S: string; out Value: Double): Boolean;');
  s.AddDelphiFunction('function TryStrToFloatS(const S: string; out Value: Double; const FormatSettings: TFormatSettings): Boolean;');
  s.AddDelphiFunction('function TryStrToFloat(const S: string; out Value: Single): Boolean;');
  s.AddDelphiFunction('function TryStrToFloatS(const S: string; out Value: Single; const FormatSettings: TFormatSettings): Boolean;');
  s.AddDelphiFunction('function StrToCurr(const S: string): Currency;');
  s.AddDelphiFunction('function StrToCurrS(const S: string; const FormatSettings: TFormatSettings): Currency;');
  s.AddDelphiFunction('function StrToCurrDef(const S: string; const Default: Currency): Currency;');
  s.AddDelphiFunction('function StrToCurrDefS(const S: string; const Default: Currency; const FormatSettings: TFormatSettings): Currency;');
  s.AddDelphiFunction('function TryStrToCurr(const S: string; out Value: Currency): Boolean;');
  s.AddDelphiFunction('function TryStrToCurrS(const S: string; out Value: Currency; const FormatSettings: TFormatSettings): Boolean;');
//  s.AddDelphiFunction('procedure FloatToDecimal(var Result: TFloatRec; const Value; ValueType: TFloatValue; Precision: Integer; Decimals: Integer);');
//  s.AddDelphiFunction('function TextToFloat(Buffer: PChar; var Value; ValueType: TFloatValue): Boolean;');
//  s.AddDelphiFunction('function TextToFloatS(Buffer: PChar; var Value; ValueType: TFloatValue; const FormatSettings: TFormatSettings): Boolean;');

  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function TextToExtended(const S: string; var Value: Extended): Boolean;');
  s.AddDelphiFunction('function TextToExtendedS(const S: string; var Value: Extended; const AFormatSettings: TFormatSettings): Boolean;');
  s.AddDelphiFunction('function TextToDouble(const S: string; var Value: Double): Boolean;');
  s.AddDelphiFunction('function TextToDoubleS(const S: string; var Value: Double; const AFormatSettings: TFormatSettings): Boolean;');
  s.AddDelphiFunction('function TextToCurrency(const S: string; var Value: Currency): Boolean;');
  s.AddDelphiFunction('function TextToCurrencyS(const S: string; var Value: Currency; const AFormatSettings: TFormatSettings): Boolean;');
//  s.AddDelphiFunction('function HashName(Name: MarshaledAString): Cardinal;');
  {$IFEND}

  s.AddDelphiFunction('function IntToHexD(Value: Integer; Digits: Integer): string;');
  s.AddDelphiFunction('function Int64ToHexD(Value: Int64; Digits: Integer): string;');
  s.AddDelphiFunction('function TryStrToInt(const S: string; out Value: Integer): Boolean;');
  s.AddDelphiFunction('function TryStrToInt64(const S: string; out Value: Int64): Boolean;');

  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function LoadStr(Ident: NativeUInt): string;');
  s.AddDelphiFunction('function FmtLoadStr(Ident: NativeUInt; const Args: array of const): string;');
  {$ELSE}
  s.AddDelphiFunction('function LoadStr(Ident: Integer): string;');
  s.AddDelphiFunction('function FmtLoadStr(Ident: Integer; const Args: array of const): string;');
  {$IFEND}
  s.AddDelphiFunction('function FileOpen(const FileName: string; Mode: LongWord): THandle;');
  s.AddDelphiFunction('function FileCreate(const FileName: string): THandle;');
  s.AddDelphiFunction('function FileCreateA(const FileName: string; Rights: Integer): THandle;');

//  s.AddDelphiFunction('function FileRead(Handle: THandle; var Buffer; Count: LongWord): Integer;');
//  s.AddDelphiFunction('function FileWrite(Handle: THandle; const Buffer; Count: LongWord): Integer;');
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function FileRead(Handle: THandle; var Buffer: TBytes; Offset, Count: LongWord): Integer;');
  s.AddDelphiFunction('function FileWrite(Handle: THandle; const Buffer:TBytes; Offset, Count: LongWord): Integer;');
  {$IFEND}
//  s.AddDelphiFunction('function FileSeek(Handle: THandle; Offset: Integer; Origin: Integer): Integer;');
  s.AddDelphiFunction('function FileSeek(Handle: THandle; const Offset: Int64; Origin: Integer): Int64;');
  s.AddDelphiFunction('procedure FileClose(Handle: THandle);');

  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function FileSetDate(const FileName: string; Age: LongInt): Integer;');
  s.AddDelphiFunction('function FileGetAttr(const FileName: string; FollowLink: Boolean{ = True}): Integer;');
  s.AddDelphiFunction('function FileSetAttr(const FileName: string; Attr: Integer; FollowLink: Boolean{ = True}): Integer;');
  {$ELSE}
  s.AddDelphiFunction('function FileSetDate(Handle: Integer; Age: Integer): Integer;');
  s.AddDelphiFunction('function FileGetAttr(const FileName: string): Integer;');
  s.AddDelphiFunction('function FileSetAttr(const FileName: string; Attr: Integer): Integer;');
  {$IFEND}

  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function ShortIntToHex(Value: ShortInt): string;');
  s.AddDelphiFunction('function ByteToHex(Value: Byte): string;');
  s.AddDelphiFunction('function SmallIntToHex(Value: SmallInt): string;');
  s.AddDelphiFunction('function WordToHex(Value: Word): string;');
  s.AddDelphiFunction('function IntToHex(Value: Integer): string;');
  s.AddDelphiFunction('function CardinalToHex(Value: Cardinal): string;');
  s.AddDelphiFunction('function Int64ToHex(Value: Int64): string;');
  s.AddDelphiFunction('function UInt64ToHex(Value: UInt64): string;');
  s.AddDelphiFunction('function UInt64ToHexD(Value: UInt64; Digits: Integer): string;');
  s.AddDelphiFunction('function StrToUInt(const S: string): Cardinal;');
  s.AddDelphiFunction('function StrToUIntDef(const S: string; Default: Cardinal): Cardinal;');
  s.AddDelphiFunction('function TryStrToUInt(const S: string; out Value: Cardinal): Boolean;');
  s.AddDelphiFunction('function StrToUInt64Def(const S: string; const Default: UInt64): UInt64;');
  s.AddDelphiFunction('function TryStrToUInt64(const S: string; out Value: UInt64): Boolean;');
  s.AddDelphiFunction('function IsRelativePath(const Path: string): Boolean;');
  s.AddDelphiFunction('function IsAssembly(const FileName: string): Boolean;');

  s.AddDelphiFunction('function FileCreate(const FileName: string; Mode: LongWord; Rights: Integer): THandle;');
  s.AddDelphiFunction('function FileCreateSymLink(const Link, Target: string): Boolean;');

  S.AddTypeS( 'TSymLinkRec', 'record TargetName: TFileName; Attr: Integer; Size: Int64; FindData: TWin32FindData; end;' );
  s.AddDelphiFunction('function FileGetSymLinkTarget(const FileName: string; var SymLinkRec: TSymLinkRec): Boolean;');
  s.AddDelphiFunction('function FileGetSymLinkTarget(const FileName: string; var TargetName: string): Boolean;');

  S.AddTypeS( 'TFileSystemAttribute', '(fsCaseSensitive, fsCasePreserving, fsLocal, fsNetwork, fsRemovable, fsSymLink)' );
  S.AddTypeS( 'TFileSystemAttributes', 'set of TFileSystemAttribute' );
  s.AddDelphiFunction('function FileSystemAttributes(const Path: string): TFileSystemAttributes;');
  s.AddDelphiFunction('function FileGetDateTimeInfo(const FileName: string; out DateTime: TWin32FindData{TDateTimeInfoRec}; FollowLink: Boolean{ = True}): Boolean;');
  {$IFEND}
end;

end.
