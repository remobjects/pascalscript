unit uPSR_StrUtils;
{$I PascalScript.inc}
interface
uses
  uPSRuntime;

procedure RegisterStrUtilsLibrary_R(S: TPSExec);

implementation

uses
  StrUtils;

procedure RegisterStrUtilsLibrary_R(S: TPSExec);
begin
  S.RegisterDelphiFunction( @ResemblesText, 'ResemblesText', cdRegister );
  S.RegisterDelphiFunction( @AnsiResemblesText, 'AnsiResemblesText', cdRegister );
  S.RegisterDelphiFunction( @ContainsText, 'ContainsText', cdRegister );
  S.RegisterDelphiFunction( @AnsiContainsText, 'AnsiContainsText', cdRegister );
  S.RegisterDelphiFunction( @StartsText, 'StartsText', cdRegister );
  S.RegisterDelphiFunction( @AnsiStartsText, 'AnsiStartsText', cdRegister );
  S.RegisterDelphiFunction( @EndsText, 'EndsText', cdRegister );
  S.RegisterDelphiFunction( @AnsiEndsText, 'AnsiEndsText', cdRegister );
  S.RegisterDelphiFunction( @ReplaceText, 'ReplaceText', cdRegister );
  S.RegisterDelphiFunction( @AnsiReplaceText, 'AnsiReplaceText', cdRegister );
  S.RegisterDelphiFunction( @MatchText, 'MatchText', cdRegister );
  S.RegisterDelphiFunction( @AnsiMatchText, 'AnsiMatchText', cdRegister );
  S.RegisterDelphiFunction( @IndexText, 'IndexText', cdRegister );
  S.RegisterDelphiFunction( @AnsiIndexText, 'AnsiIndexText', cdRegister );
  S.RegisterDelphiFunction( @ContainsStr, 'ContainsStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiContainsStr, 'AnsiContainsStr', cdRegister );
  S.RegisterDelphiFunction( @StartsStr, 'StartsStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiStartsStr, 'AnsiStartsStr', cdRegister );
  S.RegisterDelphiFunction( @EndsStr, 'EndsStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiEndsStr, 'AnsiEndsStr', cdRegister );
  S.RegisterDelphiFunction( @ReplaceStr, 'ReplaceStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiReplaceStr, 'AnsiReplaceStr', cdRegister );
  S.RegisterDelphiFunction( @MatchStr, 'MatchStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiMatchStr, 'AnsiMatchStr', cdRegister );
  S.RegisterDelphiFunction( @IndexStr, 'IndexStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiIndexStr, 'AnsiIndexStr', cdRegister );
  S.RegisterDelphiFunction( @DupeString, 'DupeString', cdRegister );
  S.RegisterDelphiFunction( @ReverseString, 'ReverseString', cdRegister );
  S.RegisterDelphiFunction( @AnsiReverseString, 'AnsiReverseString', cdRegister );
  S.RegisterDelphiFunction( @StuffString, 'StuffString', cdRegister );
  S.RegisterDelphiFunction( @RandomFrom, 'RandomFrom', cdRegister );
  S.RegisterDelphiFunction( @IfThen, 'IfThen', cdRegister );
  S.RegisterDelphiFunction( @SplitString, 'SplitString', cdRegister );
  S.RegisterDelphiFunction( @LeftStr, 'LeftStr', cdRegister );
  S.RegisterDelphiFunction( @RightStr, 'RightStr', cdRegister );
  S.RegisterDelphiFunction( @MidStr, 'MidStr', cdRegister );
  S.RegisterDelphiFunction( @LeftBStr, 'LeftBStr', cdRegister );
  S.RegisterDelphiFunction( @RightBStr, 'RightBStr', cdRegister );
  S.RegisterDelphiFunction( @MidBStr, 'MidBStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiLeftStr, 'AnsiLeftStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiRightStr, 'AnsiRightStr', cdRegister );
  S.RegisterDelphiFunction( @AnsiMidStr, 'AnsiMidStr', cdRegister );
  S.RegisterDelphiFunction( @SearchBuf, 'SearchBuf', cdRegister );
  S.RegisterDelphiFunction( @PosEx, 'PosEx', cdRegister );
//  S.RegisterDelphiFunction( @Soundex, 'Soundex', cdRegister );
//  S.RegisterDelphiFunction( @SoundexInt, 'SoundexInt', cdRegister );
//  S.RegisterDelphiFunction( @DecodeSoundexInt, 'DecodeSoundexInt', cdRegister );
//  S.RegisterDelphiFunction( @SoundexWord, 'SoundexWord', cdRegister );
//  S.RegisterDelphiFunction( @DecodeSoundexWord, 'DecodeSoundexWord', cdRegister );
//  S.RegisterDelphiFunction( @SoundexSimilar, 'SoundexSimilar', cdRegister );
//  S.RegisterDelphiFunction( @SoundexCompare, 'SoundexCompare', cdRegister );
//  S.RegisterDelphiFunction( @SoundexProc, 'SoundexProc', cdRegister );
end;

end.
