
unit uPSR_dateutils;
{$I PascalScript.inc}
interface
uses
  SysUtils, uPSRuntime, DateUtils;



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

function DateTimeToUnix(D: TDateTime): Int64;
begin
  Result := Round((D - 25569) * 86400);
end;

function UnixToDateTime(U: Int64): TDateTime;
begin
  Result := U / 86400 + 25569;
end;

procedure RegisterDateTimeLibrary_R(S: TPSExec);
type _T2 = function(const DateTime: TDateTime): string;
var _P2: _T2;
begin
  S.RegisterDelphiFunction(@EncodeDate, 'ENCODEDATE', cdRegister);
  S.RegisterDelphiFunction(@EncodeTime, 'ENCODETIME', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeDate, 'TRYENCODEDATE', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeTime, 'TRYENCODETIME', cdRegister);
  S.RegisterDelphiFunction(@DecodeDate, 'DECODEDATE', cdRegister);
  S.RegisterDelphiFunction(@DecodeTime, 'DECODETIME', cdRegister);
  S.RegisterDelphiFunction(@DayOfWeek, 'DAYOFWEEK', cdRegister);
  S.RegisterDelphiFunction(@Date, 'DATE', cdRegister);
  S.RegisterDelphiFunction(@Time, 'TIME', cdRegister);
  S.RegisterDelphiFunction(@Now, 'NOW', cdRegister);
  S.RegisterDelphiFunction(@DateTimeToUnix, 'DATETIMETOUNIX', cdRegister);
  S.RegisterDelphiFunction(@UnixToDateTime, 'UNIXTODATETIME', cdRegister);
  S.RegisterDelphiFunction(@IncYear, 'INCYEAR', cdRegister);
  S.RegisterDelphiFunction(@IncMonth, 'INCMONTH', cdRegister);
  S.RegisterDelphiFunction(@IncWeek, 'INCWEEK', cdRegister);
  S.RegisterDelphiFunction(@IncDay, 'INCDAY', cdRegister);
  S.RegisterDelphiFunction(@IncHour, 'INCHOUR', cdRegister);
  S.RegisterDelphiFunction(@IncMinute, 'INCMINUTE', cdRegister);
  S.RegisterDelphiFunction(@IncSecond, 'INCSECOND', cdRegister);
  S.RegisterDelphiFunction(@IncMilliSecond, 'INCMILLISECOND', cdRegister);
  _P2 := DateToStr;
  S.RegisterDelphiFunction(@_P2, 'DateToStr', cdRegister);
  _P2 := TimeToStr;
  S.RegisterDelphiFunction(@_P2, 'TimeToStr', cdRegister);
  _P2 := DateTimeToStr;
  S.RegisterDelphiFunction(@_P2, 'DateTimeToStr', cdRegister);
  S.RegisterDelphiFunction(@FormatDateTime, 'FORMATDATETIME', cdRegister);
end;

end.
