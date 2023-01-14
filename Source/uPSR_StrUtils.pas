unit uPSR_StrUtils;
{$I PascalScript.inc}
interface

{$WARN UNSAFE_CODE OFF}

uses
  uPSRuntime;

procedure RegisterStrUtilsLibrary_R(S: TPSExec);

implementation

uses
  StrUtils;

procedure RegisterStrUtilsLibrary_R(S: TPSExec);
begin
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @ResemblesText, 'ResemblesText', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiResemblesText, 'AnsiResemblesText', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @ContainsText, 'ContainsText', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiContainsText, 'AnsiContainsText', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @StartsText, 'StartsText', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiStartsText, 'AnsiStartsText', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @EndsText, 'EndsText', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiEndsText, 'AnsiEndsText', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @ReplaceText, 'ReplaceText', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiReplaceText, 'AnsiReplaceText', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @MatchText, 'MatchText', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiMatchText, 'AnsiMatchText', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @IndexText, 'IndexText', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiIndexText, 'AnsiIndexText', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @ContainsStr, 'ContainsStr', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiContainsStr, 'AnsiContainsStr', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @StartsStr, 'StartsStr', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiStartsStr, 'AnsiStartsStr', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @EndsStr, 'EndsStr', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiEndsStr, 'AnsiEndsStr', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @ReplaceStr, 'ReplaceStr', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiReplaceStr, 'AnsiReplaceStr', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @MatchStr, 'MatchStr', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiMatchStr, 'AnsiMatchStr', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @IndexStr, 'IndexStr', cdRegister );
  {$ENDIF UNICODE}
  S.RegisterDelphiFunction( @AnsiIndexStr, 'AnsiIndexStr', cdRegister );
  S.RegisterDelphiFunction( @DupeString, 'DupeString', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @ReverseString, 'ReverseString', cdRegister );
  {$ENDIF UNICODE}  
  S.RegisterDelphiFunction( @AnsiReverseString, 'AnsiReverseString', cdRegister );
  S.RegisterDelphiFunction( @StuffString, 'StuffString', cdRegister );
  S.RegisterDelphiFunction( @RandomFrom, 'RandomFrom', cdRegister );
  S.RegisterDelphiFunction( @IfThen, 'IfThen', cdRegister );
  {$IFDEF UNICODE}
  S.RegisterDelphiFunction( @SplitString, 'SplitString', cdRegister );
  {$ENDIF UNICODE}
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
