unit uPSC_SysUtils;

interface

uses
  uPSCompiler, uPSUtils;

procedure RegisterSysUtilsLibrary_C(S: TPSPascalCompiler);

implementation

uses
  SysUtils;

procedure RegisterSysUtilsLibrary_C(S: TPSPascalCompiler);
var
  Str : string;
begin
  {$IF CompilerVersion >= 28}
  S.AddConstant('INVALID_HANDLE_VALUE', INVALID_HANDLE_VALUE);
  {$IFEND}

  S.AddConstant('fmOpenRead', fmOpenRead);
  S.AddConstant('fmOpenWrite', fmOpenWrite);
  S.AddConstant('fmOpenReadWrite', fmOpenReadWrite);
  S.AddConstant('fmExclusive', fmExclusive);
  S.AddConstant('fmShareCompat', fmShareCompat);
  S.AddConstant('fmShareExclusive', fmShareExclusive);
  S.AddConstant('fmShareDenyWrite', fmShareDenyWrite);
  S.AddConstant('fmShareDenyRead', fmShareDenyRead);
  S.AddConstant('fmShareDenyNone', fmShareDenyNone);

  S.AddConstant('faInvalid', faInvalid);
  S.AddConstant('faReadOnly', faReadOnly);
  S.AddConstant('faHidden', faHidden);
  S.AddConstant('faSysFile', faSysFile);
  S.AddConstant('faVolumeID', faVolumeID);
  S.AddConstant('faDirectory', faDirectory);
  S.AddConstant('faArchive', faArchive);
  S.AddConstant('faNormal', faNormal);
  S.AddConstant('faTemporary', faTemporary);
  S.AddConstant('faSymLink', faSymLink);
  S.AddConstant('faCompressed', faCompressed);
  S.AddConstant('faEncrypted', faEncrypted);
  S.AddConstant('faVirtual', faVirtual);
  S.AddConstant('faAnyFile', faAnyFile);

  S.AddConstant('DefaultTrueBoolStr', DefaultTrueBoolStr);
  S.AddConstant('DefaultFalseBoolStr', DefaultFalseBoolStr);

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

  {$IF CompilerVersion >= 28}
  S.AddTypeS( 'TLocaleOptions', '(loInvariantLocale, loUserLocale)' );
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
  s.AddDelphiFunction('function SameTextS(const S1, S2: string; LocaleOptions: TLocaleOptions): Boolean;' );
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
  s.AddDelphiFunction('function Format(const Format: string; const Args: array of const): string; overload;' );
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
end;

end.
