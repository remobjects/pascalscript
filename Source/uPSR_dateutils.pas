
unit uPSR_dateutils;
{$I PascalScript.inc}
interface
uses
  SysUtils, uPSRuntime;



procedure RegisterDateTimeLibrary_R(S: TPSExec);

implementation

function TryEncodeDate(Year, Month, Day: Word; var Date: TDateTime): Boolean;
begin
  try
    Date := EncodeDate(Year, Month, Day);
    Result := true;
  except
    Result := false;
  end;
end;

function TryEncodeTime(Hour, Min, Sec, MSec: Word; var Time: TDateTime): Boolean;
begin
  try
    Time := EncodeTime(hour, Min, Sec, MSec);
    Result := true;
  except
    Result := false;
  end;
end;

{ A TDateTime before 30 December 1899 is negative, and its time of day is still
  added to the day, not subtracted: noon of 29 December 1899 is -1.5.  These
  convert through a count of days on which time runs forward. }
function DateTimeToUnix(D: TDateTime): Int64;
var
  lDays: Double;
begin
  if D < 0 then
    lDays := Int(D) - Frac(D)
  else
    lDays := D;
  Result := Round((lDays - 25569) * 86400);
end;

function UnixToDateTime(U: Int64): TDateTime;
var
  lDays, lDay: Double;
begin
  lDays := U / 86400 + 25569;
  if lDays < 0 then begin
    lDay := Int(lDays);
    if lDay <> lDays then
      lDay := lDay - 1;
    Result := lDay - (lDays - lDay);
  end else
    Result := lDays;
end;

{$IFDEF FPC}
{ Free Pascal declares StrToDate's ShortString form first, and FormatDateTime with a
  third, defaulted parameter, so a binding by address would take neither as the
  script declares it: these routines do. }
function StrToDate_P(const S: AnsiString): TDateTime;
begin
  Result := StrToDate(S);
end;

function FormatDateTime_P(const fmt: AnsiString; D: TDateTime): AnsiString;
begin
  Result := FormatDateTime(fmt, D);
end;
{$ENDIF}

procedure RegisterDateTimeLibrary_R(S: TPSExec);
begin
  S.RegisterDelphiFunction(@EncodeDate, 'EncodeDate', cdRegister);
  S.RegisterDelphiFunction(@EncodeTime, 'EncodeTime', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeDate, 'TryEncodeDate', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeTime, 'TryEncodeTime', cdRegister);
  S.RegisterDelphiFunction(@DecodeDate, 'DecodeDate', cdRegister);
  S.RegisterDelphiFunction(@DecodeTime, 'DecodeTime', cdRegister);
  S.RegisterDelphiFunction(@DayOfWeek, 'DayOfWeek', cdRegister);
  S.RegisterDelphiFunction(@Date, 'Date', cdRegister);
  S.RegisterDelphiFunction(@Time, 'Time', cdRegister);
  S.RegisterDelphiFunction(@Now, 'Now', cdRegister);
  S.RegisterDelphiFunction(@DateTimeToUnix, 'DateTimeToUnix', cdRegister);
  S.RegisterDelphiFunction(@UnixToDateTime, 'UnixToDateTime', cdRegister);
  S.RegisterDelphiFunction(@DateToStr, 'DateToStr', cdRegister);
  S.RegisterDelphiFunction({$IFDEF FPC}@FormatDateTime_P{$ELSE}@FormatDateTime{$ENDIF}, 'FormatDateTime', cdRegister);
  S.RegisterDelphiFunction({$IFDEF FPC}@StrToDate_P{$ELSE}@StrToDate{$ENDIF}, 'StrToDate', cdRegister);
end;

end.
