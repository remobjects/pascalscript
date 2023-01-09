
unit uPSR_dateutils;
{$I PascalScript.inc}
interface
uses
  SysUtils, uPSRuntime;



procedure RegisterDateTimeLibrary_R(S: TPSExec);

implementation

uses
  DateUtils;

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
  S.RegisterDelphiFunction(@FormatDateTime, 'FormatDateTime', cdRegister);
  S.RegisterDelphiFunction(@StrToDate, 'StrToDate', cdRegister);

  // DateUtils
  S.RegisterDelphiFunction(@DateOf, 'DateOf', cdRegister);
  S.RegisterDelphiFunction(@TimeOf, 'TimeOf', cdRegister);
  S.RegisterDelphiFunction(@IsInLeapYear, 'IsInLeapYear', cdRegister);
  S.RegisterDelphiFunction(@IsPM, 'IsPM', cdRegister);
  {$IF CompilerVersion >= 28}
  S.RegisterDelphiFunction(@IsAM, 'IsAM', cdRegister);
  {$IFEND}
  S.RegisterDelphiFunction(@IsValidDate, 'IsValidDate', cdRegister);
  S.RegisterDelphiFunction(@IsValidTime, 'IsValidTime', cdRegister);
  S.RegisterDelphiFunction(@IsValidDateTime, 'IsValidDateTime', cdRegister);
  S.RegisterDelphiFunction(@IsValidDateDay, 'IsValidDateDay', cdRegister);
  S.RegisterDelphiFunction(@IsValidDateWeek, 'IsValidDateWeek', cdRegister);
  S.RegisterDelphiFunction(@IsValidDateMonthWeek, 'IsValidDateMonthWeek', cdRegister);
  S.RegisterDelphiFunction(@WeeksInYear, 'WeeksInYear', cdRegister);
  S.RegisterDelphiFunction(@WeeksInAYear, 'WeeksInAYear', cdRegister);
  S.RegisterDelphiFunction(@DaysInYear, 'DaysInYear', cdRegister);
  S.RegisterDelphiFunction(@DaysInAYear, 'DaysInAYear', cdRegister);
  S.RegisterDelphiFunction(@DaysInMonth, 'DaysInMonth', cdRegister);
  S.RegisterDelphiFunction(@DaysInAMonth, 'DaysInAMonth', cdRegister);
  S.RegisterDelphiFunction(@Today, 'Today', cdRegister);
  S.RegisterDelphiFunction(@Yesterday, 'Yesterday', cdRegister);
  S.RegisterDelphiFunction(@Tomorrow, 'Tomorrow', cdRegister);
  S.RegisterDelphiFunction(@IsToday, 'IsToday', cdRegister);
  S.RegisterDelphiFunction(@IsSameDay, 'IsSameDay', cdRegister);
  S.RegisterDelphiFunction(@YearOf, 'YearOf', cdRegister);
  S.RegisterDelphiFunction(@MonthOf, 'MonthOf', cdRegister);
  S.RegisterDelphiFunction(@WeekOf, 'WeekOf', cdRegister);
  S.RegisterDelphiFunction(@DayOf, 'DayOf', cdRegister);
  S.RegisterDelphiFunction(@HourOf, 'HourOf', cdRegister);
  S.RegisterDelphiFunction(@MinuteOf, 'MinuteOf', cdRegister);
  S.RegisterDelphiFunction(@SecondOf, 'SecondOf', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOf, 'MilliSecondOf', cdRegister);
  S.RegisterDelphiFunction(@StartOfTheYear, 'StartOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@EndOfTheYear, 'EndOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@StartOfAYear, 'StartOfAYear', cdRegister);
  S.RegisterDelphiFunction(@EndOfAYear, 'EndOfAYear', cdRegister);
  S.RegisterDelphiFunction(@StartOfTheMonth, 'StartOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@EndOfTheMonth, 'EndOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@StartOfAMonth, 'StartOfAMonth', cdRegister);
  S.RegisterDelphiFunction(@EndOfAMonth, 'EndOfAMonth', cdRegister);
  S.RegisterDelphiFunction(@StartOfTheWeek, 'StartOfTheWeek', cdRegister);
  S.RegisterDelphiFunction(@EndOfTheWeek, 'EndOfTheWeek', cdRegister);
  S.RegisterDelphiFunction(@StartOfAWeek, 'StartOfAWeek', cdRegister);
  S.RegisterDelphiFunction(@EndOfAWeek, 'EndOfAWeek', cdRegister);
  S.RegisterDelphiFunction(@StartOfTheDay, 'StartOfTheDay', cdRegister);
  S.RegisterDelphiFunction(@EndOfTheDay, 'EndOfTheDay', cdRegister);
  S.RegisterDelphiFunction(@StartOfADay, 'StartOfADay', cdRegister);
  S.RegisterDelphiFunction(@EndOfADay, 'EndOfADay', cdRegister);
  S.RegisterDelphiFunction(@MonthOfTheYear, 'MonthOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@WeekOfTheYear, 'WeekOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@DayOfTheYear, 'DayOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@HourOfTheYear, 'HourOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@MinuteOfTheYear, 'MinuteOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@SecondOfTheYear, 'SecondOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOfTheYear, 'MilliSecondOfTheYear', cdRegister);
  S.RegisterDelphiFunction(@WeekOfTheMonth, 'WeekOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@DayOfTheMonth, 'DayOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@HourOfTheMonth, 'HourOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@MinuteOfTheMonth, 'MinuteOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@SecondOfTheMonth, 'SecondOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOfTheMonth, 'MilliSecondOfTheMonth', cdRegister);
  S.RegisterDelphiFunction(@DayOfTheWeek, 'DayOfTheWeek', cdRegister);
  S.RegisterDelphiFunction(@HourOfTheWeek, 'HourOfTheWeek', cdRegister);
  S.RegisterDelphiFunction(@MinuteOfTheWeek, 'MinuteOfTheWeek', cdRegister);
  S.RegisterDelphiFunction(@SecondOfTheWeek, 'SecondOfTheWeek', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOfTheWeek, 'MilliSecondOfTheWeek', cdRegister);
  S.RegisterDelphiFunction(@HourOfTheDay, 'HourOfTheDay', cdRegister);
  S.RegisterDelphiFunction(@MinuteOfTheDay, 'MinuteOfTheDay', cdRegister);
  S.RegisterDelphiFunction(@SecondOfTheDay, 'SecondOfTheDay', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOfTheDay, 'MilliSecondOfTheDay', cdRegister);
  S.RegisterDelphiFunction(@MinuteOfTheHour, 'MinuteOfTheHour', cdRegister);
  S.RegisterDelphiFunction(@SecondOfTheHour, 'SecondOfTheHour', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOfTheHour, 'MilliSecondOfTheHour', cdRegister);
  S.RegisterDelphiFunction(@SecondOfTheMinute, 'SecondOfTheMinute', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOfTheMinute, 'MilliSecondOfTheMinute', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondOfTheSecond, 'MilliSecondOfTheSecond', cdRegister);
  S.RegisterDelphiFunction(@WithinPastYears, 'WithinPastYears', cdRegister);
  S.RegisterDelphiFunction(@WithinPastMonths, 'WithinPastMonths', cdRegister);
  S.RegisterDelphiFunction(@WithinPastWeeks, 'WithinPastWeeks', cdRegister);
  S.RegisterDelphiFunction(@WithinPastDays, 'WithinPastDays', cdRegister);
  S.RegisterDelphiFunction(@WithinPastHours, 'WithinPastHours', cdRegister);
  S.RegisterDelphiFunction(@WithinPastMinutes, 'WithinPastMinutes', cdRegister);
  S.RegisterDelphiFunction(@WithinPastSeconds, 'WithinPastSeconds', cdRegister);
  S.RegisterDelphiFunction(@WithinPastMilliSeconds, 'WithinPastMilliSeconds', cdRegister);
  S.RegisterDelphiFunction(@YearsBetween, 'YearsBetween', cdRegister);
  S.RegisterDelphiFunction(@MonthsBetween, 'MonthsBetween', cdRegister);
  S.RegisterDelphiFunction(@WeeksBetween, 'WeeksBetween', cdRegister);
  S.RegisterDelphiFunction(@DaysBetween, 'DaysBetween', cdRegister);
  S.RegisterDelphiFunction(@HoursBetween, 'HoursBetween', cdRegister);
  S.RegisterDelphiFunction(@MinutesBetween, 'MinutesBetween', cdRegister);
  S.RegisterDelphiFunction(@SecondsBetween, 'SecondsBetween', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondsBetween, 'MilliSecondsBetween', cdRegister);
  {$IF CompilerVersion >= 28}
  S.RegisterDelphiFunction(@DateTimeInRange, 'DateTimeInRange', cdRegister);
  S.RegisterDelphiFunction(@DateInRange, 'DateInRange', cdRegister);
  S.RegisterDelphiFunction(@TimeInRange, 'TimeInRange', cdRegister);
  {$IFEND}
  S.RegisterDelphiFunction(@YearSpan, 'YearSpan', cdRegister);
  S.RegisterDelphiFunction(@MonthSpan, 'MonthSpan', cdRegister);
  S.RegisterDelphiFunction(@WeekSpan, 'WeekSpan', cdRegister);
  S.RegisterDelphiFunction(@DaySpan, 'DaySpan', cdRegister);
  S.RegisterDelphiFunction(@HourSpan, 'HourSpan', cdRegister);
  S.RegisterDelphiFunction(@MinuteSpan, 'MinuteSpan', cdRegister);
  S.RegisterDelphiFunction(@SecondSpan, 'SecondSpan', cdRegister);
  S.RegisterDelphiFunction(@MilliSecondSpan, 'MilliSecondSpan', cdRegister);
  S.RegisterDelphiFunction(@IncYear, 'IncYear', cdRegister);
  S.RegisterDelphiFunction(@IncWeek, 'IncWeek', cdRegister);
  S.RegisterDelphiFunction(@IncDay, 'IncDay', cdRegister);
  S.RegisterDelphiFunction(@IncHour, 'IncHour', cdRegister);
  S.RegisterDelphiFunction(@IncMinute, 'IncMinute', cdRegister);
  S.RegisterDelphiFunction(@IncSecond, 'IncSecond', cdRegister);
  S.RegisterDelphiFunction(@IncMilliSecond, 'IncMilliSecond', cdRegister);
  S.RegisterDelphiFunction(@EncodeDateTime, 'EncodeDateTime', cdRegister);
  S.RegisterDelphiFunction(@DecodeDateTime, 'DecodeDateTime', cdRegister);
  S.RegisterDelphiFunction(@EncodeDateWeek, 'EncodeDateWeek', cdRegister);
  S.RegisterDelphiFunction(@DecodeDateWeek, 'DecodeDateWeek', cdRegister);
  S.RegisterDelphiFunction(@EncodeDateDay, 'EncodeDateDay', cdRegister);
  S.RegisterDelphiFunction(@DecodeDateDay, 'DecodeDateDay', cdRegister);
  S.RegisterDelphiFunction(@EncodeDateMonthWeek, 'EncodeDateMonthWeek', cdRegister);
  S.RegisterDelphiFunction(@DecodeDateMonthWeek, 'DecodeDateMonthWeek', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeDateTime, 'TryEncodeDateTime', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeDateWeek, 'TryEncodeDateWeek', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeDateDay, 'TryEncodeDateDay', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeDateMonthWeek, 'TryEncodeDateMonthWeek', cdRegister);
  S.RegisterDelphiFunction(@RecodeYear, 'RecodeYear', cdRegister);
  S.RegisterDelphiFunction(@RecodeMonth, 'RecodeMonth', cdRegister);
  S.RegisterDelphiFunction(@RecodeDay, 'RecodeDay', cdRegister);
  S.RegisterDelphiFunction(@RecodeHour, 'RecodeHour', cdRegister);
  S.RegisterDelphiFunction(@RecodeMinute, 'RecodeMinute', cdRegister);
  S.RegisterDelphiFunction(@RecodeSecond, 'RecodeSecond', cdRegister);
  S.RegisterDelphiFunction(@RecodeMilliSecond, 'RecodeMilliSecond', cdRegister);
  S.RegisterDelphiFunction(@RecodeDate, 'RecodeDate', cdRegister);
  S.RegisterDelphiFunction(@RecodeTime, 'RecodeTime', cdRegister);
  S.RegisterDelphiFunction(@RecodeDateTime, 'RecodeDateTime', cdRegister);
  S.RegisterDelphiFunction(@TryRecodeDateTime, 'TryRecodeDateTime', cdRegister);
  S.RegisterDelphiFunction(@CompareDateTime, 'CompareDateTime', cdRegister);
  S.RegisterDelphiFunction(@SameDateTime, 'SameDateTime', cdRegister);
  S.RegisterDelphiFunction(@CompareDate, 'CompareDate', cdRegister);
  S.RegisterDelphiFunction(@SameDate, 'SameDate', cdRegister);
  S.RegisterDelphiFunction(@CompareTime, 'CompareTime', cdRegister);
  S.RegisterDelphiFunction(@SameTime, 'SameTime', cdRegister);
  S.RegisterDelphiFunction(@NthDayOfWeek, 'NthDayOfWeek', cdRegister);
  S.RegisterDelphiFunction(@DecodeDayOfWeekInMonth, 'DecodeDayOfWeekInMonth', cdRegister);
  S.RegisterDelphiFunction(@EncodeDayOfWeekInMonth, 'EncodeDayOfWeekInMonth', cdRegister);
  S.RegisterDelphiFunction(@TryEncodeDayOfWeekInMonth, 'TryEncodeDayOfWeekInMonth', cdRegister);
  S.RegisterDelphiFunction(@InvalidDateTimeError, 'InvalidDateTimeError', cdRegister);
  S.RegisterDelphiFunction(@InvalidDateWeekError, 'InvalidDateWeekError', cdRegister);
  S.RegisterDelphiFunction(@InvalidDateDayError, 'InvalidDateDayError', cdRegister);
  S.RegisterDelphiFunction(@InvalidDateMonthWeekError, 'InvalidDateMonthWeekError', cdRegister);
  S.RegisterDelphiFunction(@InvalidDayOfWeekInMonthError, 'InvalidDayOfWeekInMonthError', cdRegister);
  S.RegisterDelphiFunction(@DateTimeToJulianDate, 'DateTimeToJulianDate', cdRegister);
  S.RegisterDelphiFunction(@JulianDateToDateTime, 'JulianDateToDateTime', cdRegister);
  S.RegisterDelphiFunction(@TryJulianDateToDateTime, 'TryJulianDateToDateTime', cdRegister);
  S.RegisterDelphiFunction(@DateTimeToModifiedJulianDate, 'DateTimeToModifiedJulianDate', cdRegister);
  S.RegisterDelphiFunction(@ModifiedJulianDateToDateTime, 'ModifiedJulianDateToDateTime', cdRegister);
  S.RegisterDelphiFunction(@TryModifiedJulianDateToDateTime, 'TryModifiedJulianDateToDateTime', cdRegister);
  S.RegisterDelphiFunction(@DateTimeToUnix, 'DateTimeToUnix', cdRegister);
  S.RegisterDelphiFunction(@UnixToDateTime, 'UnixToDateTime', cdRegister);
  S.RegisterDelphiFunction(@DateTimeToMilliseconds, 'DateTimeToMilliseconds', cdRegister);
  S.RegisterDelphiFunction(@TimeToMilliseconds, 'TimeToMilliseconds', cdRegister);
  S.RegisterDelphiFunction(@ISO8601ToDate, 'ISO8601ToDate', cdRegister);
  S.RegisterDelphiFunction(@TryISO8601ToDate, 'TryISO8601ToDate', cdRegister);
  S.RegisterDelphiFunction(@DateToISO8601, 'DateToISO8601', cdRegister);
end;

end.
