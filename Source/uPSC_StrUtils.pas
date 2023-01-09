{ Compile time Date Time library }
unit uPSC_StrUtils;

interface

uses
  uPSCompiler, uPSUtils;

procedure RegisterStrUtilsLibrary_C(S: TPSPascalCompiler);

implementation

uses
  StrUtils;

procedure RegisterStrUtilsLibrary_C(S: TPSPascalCompiler);
begin
(*
type
  TSoundexLength = 1..MaxInt;
  TSoundexIntLength = 1..8;

const
  { Default word delimiters are any character except the core alphanumerics. }
  WordDelimiters: set of Byte = [0..255] -
    [Ord('a')..Ord('z'), Ord('A')..Ord('Z'), Ord('1')..Ord('9'), Ord('0')];
*)

  S.AddTypeS('TStringSeachOption', '(soDown, soMatchCase, soWholeWord)');
  S.AddTypeS('TStringSearchOptions', 'set of TStringSeachOption');
  S.AddTypeS('TCompareTextProc', 'function(const AText, AOther: string): Boolean;');

  S.AddTypeS('TStringDynArray', 'Array of String');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function ResemblesText(const AText, AOther: string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiResemblesText(const AText, AOther: string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function ContainsText(const AText, ASubText: string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiContainsText(const AText, ASubText: string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function StartsText(const ASubText, AText: string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiStartsText(const ASubText, AText: string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function EndsText(const ASubText, AText: string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiEndsText(const ASubText, AText: string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function ReplaceText(const AText, AFromText, AToText: string): string;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiReplaceText(const AText, AFromText, AToText: string): string;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function MatchText(const AText: string; const AValues: array of string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiMatchText(const AText: string; const AValues: array of string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function IndexText(const AText: string; const AValues: array of string): Integer;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiIndexText(const AText: string; const AValues: array of string): Integer;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function ContainsStr(const AText, ASubText: string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiContainsStr(const AText, ASubText: string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function StartsStr(const ASubText, AText: string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiStartsStr(const ASubText, AText: string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function EndsStr(const ASubText, AText: string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiEndsStr(const ASubText, AText: string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function ReplaceStr(const AText, AFromText, AToText: string): string;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiReplaceStr(const AText, AFromText, AToText: string): string;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function MatchStr(const AText: string; const AValues: array of string): Boolean;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiMatchStr(const AText: string; const AValues: array of string): Boolean;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function IndexStr(const AText: string; const AValues: array of string): Integer;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiIndexStr(const AText: string; const AValues: array of string): Integer;');

  s.AddDelphiFunction('function DupeString(const AText: string; ACount: Integer): string;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function ReverseString(const AText: string): string;');
  {$ENDIF UNICODE}
  s.AddDelphiFunction('function AnsiReverseString(const AText: string): string;');

  s.AddDelphiFunction('function StuffString(const AText: string; AStart, ALength: Cardinal; const ASubText: string): string;');
  s.AddDelphiFunction('function RandomFrom(const AValues: array of string): string;');
  s.AddDelphiFunction('function IfThen(AValue: Boolean; const ATrue: string; AFalse: string{ = ''}): string;');
  s.AddDelphiFunction('function SplitString(const S, Delimiters: string): TStringDynArray;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function LeftStr(const AText: string; const ACount: Integer): string;');
  s.AddDelphiFunction('function RightStr(const AText: string; const ACount: Integer): string;');
  s.AddDelphiFunction('function MidStr(const AText: string; const AStart, ACount: Integer): string;');
  {$ELSE}
  s.AddDelphiFunction('function LeftStr(const AText: AnsiString; const ACount: Integer): AnsiString;');
  s.AddDelphiFunction('function RightStr(const AText: AnsiString; const ACount: Integer): AnsiString;');
  s.AddDelphiFunction('function MidStr(const AText: AnsiString; const AStart, ACount: Integer): AnsiString;');
  {$ENDIF UNICODE}

  s.AddDelphiFunction('function LeftBStr(const AText: AnsiString; const AByteCount: Integer): AnsiString;');
  s.AddDelphiFunction('function RightBStr(const AText: AnsiString; const AByteCount: Integer): AnsiString;');
  s.AddDelphiFunction('function MidBStr(const AText: AnsiString; const AByteStart, AByteCount: Integer): AnsiString;');
  s.AddDelphiFunction('function AnsiLeftStr(const AText: string; const ACount: Integer): string;');
  s.AddDelphiFunction('function AnsiRightStr(const AText: string; const ACount: Integer): string;');
  s.AddDelphiFunction('function AnsiMidStr(const AText: string; const AStart, ACount: Integer): string;');

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function SearchBuf(Buf: PChar; BufLen: Integer; SelStart, SelLength: Integer; SearchString: String; Options: TStringSearchOptions{ = [soDown]}): PChar;');
  {$ELSE}
  s.AddDelphiFunction('function SearchBuf(Buf: PAnsiChar; BufLen: Integer; SelStart, SelLength: Integer; SearchString: AnsiString; Options: TStringSearchOptions{ = [soDown]}): PAnsiChar;');
  {$ENDIF}

  {$IFDEF UNICODE}
  s.AddDelphiFunction('function PosEx(const SubStr, S: string; Offset: Integer{ = 1}): Integer;');
  {$ELSE}
  s.AddDelphiFunction('function PosEx(const SubStr, S: string; Offset: Cardinal{ = 1}): Integer;');
  {$ENDIF UNICODE}

(*
  s.AddDelphiFunction('function Soundex(const AText: string; ALength: TSoundexLength{ = 4}): string;');
  s.AddDelphiFunction('function SoundexInt(const AText: string; ALength: TSoundexIntLength{ = 4}): Integer;');
  s.AddDelphiFunction('function DecodeSoundexInt(AValue: Integer): string;');
  s.AddDelphiFunction('function SoundexWord(const AText: string): Word;');
  s.AddDelphiFunction('function DecodeSoundexWord(AValue: Word): string;');
  s.AddDelphiFunction('function SoundexSimilar(const AText, AOther: string; ALength: TSoundexLength{ = 4}): Boolean;');
  s.AddDelphiFunction('function SoundexCompare(const AText, AOther: string; ALength: TSoundexLength{ = 4}): Integer;');
  s.AddDelphiFunction('function SoundexProc(const AText, AOther: string): Boolean;');
*)
end;

end.
