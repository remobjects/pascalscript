{ Compile time Date Time library }
unit uPSC_dateutils;

interface

uses
  SysUtils, uPSCompiler, uPSUtils;

procedure RegisterDateTimeLibrary_C(S: TPSPascalCompiler);

implementation

uses
  DateUtils;

procedure RegisterDatetimeLibrary_C(S: TPSPascalCompiler);
begin
  s.AddType('TDateTime', btDouble).ExportName := True;
  {$IF CompilerVersion >= 28}
  s.AddType('TDate', btDouble).ExportName := True;
  s.AddType('TTime', btDouble).ExportName := True;
  {$IFEND}

  s.AddDelphiFunction('function EncodeDate(Year, Month, Day: Word): TDateTime;');
  s.AddDelphiFunction('function EncodeTime(Hour, Min, Sec, MSec: Word): TDateTime;');
  s.AddDelphiFunction('function TryEncodeDate(Year, Month, Day: Word; var Date: TDateTime): Boolean;');
  s.AddDelphiFunction('function TryEncodeTime(Hour, Min, Sec, MSec: Word; var Time: TDateTime): Boolean;');
  s.AddDelphiFunction('procedure DecodeDate(const DateTime: TDateTime; var Year, Month, Day: Word);');
  s.AddDelphiFunction('procedure DecodeTime(const DateTime: TDateTime; var Hour, Min, Sec, MSec: Word);');
  s.AddDelphiFunction('function DayOfWeek(const DateTime: TDateTime): Word;');
  s.AddDelphiFunction('function Date: TDateTime;');
  s.AddDelphiFunction('function Time: TDateTime;');
  s.AddDelphiFunction('function Now: TDateTime;');
  s.AddDelphiFunction('function DateTimeToUnix(D: TDateTime): Int64;');
  s.AddDelphiFunction('function UnixToDateTime(U: Int64): TDateTime;');

  s.AddDelphiFunction('function DateToStr(D: TDateTime): string;');
  s.AddDelphiFunction('function StrToDate(const S: string): TDateTime;');
  s.AddDelphiFunction('function FormatDateTime(const fmt: string; D: TDateTime): string;');

  s.AddDelphiFunction('function DateOf(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function TimeOf(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function IsInLeapYear(const AValue: TDateTime): Boolean;');
  s.AddDelphiFunction('function IsPM(const AValue: TDateTime): Boolean;');
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function IsAM(const AValue: TDateTime): Boolean;');
  {$IFEND}
  s.AddDelphiFunction('function IsValidDate(const AYear, AMonth, ADay: Word): Boolean;');
  s.AddDelphiFunction('function IsValidTime(const AHour, AMinute, ASecond, AMilliSecond: Word): Boolean;');
  s.AddDelphiFunction('function IsValidDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word): Boolean;');
  s.AddDelphiFunction('function IsValidDateDay(const AYear, ADayOfYear: Word): Boolean;');
  s.AddDelphiFunction('function IsValidDateWeek(const AYear, AWeekOfYear, ADayOfWeek: Word): Boolean;');
  s.AddDelphiFunction('function IsValidDateMonthWeek(const AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word): Boolean;');
  s.AddDelphiFunction('function WeeksInYear(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function WeeksInAYear(const AYear: Word): Word;');
  s.AddDelphiFunction('function DaysInYear(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function DaysInAYear(const AYear: Word): Word;');
  s.AddDelphiFunction('function DaysInMonth(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function DaysInAMonth(const AYear, AMonth: Word): Word;');
  s.AddDelphiFunction('function Today: TDateTime;');
  s.AddDelphiFunction('function Yesterday: TDateTime;');
  s.AddDelphiFunction('function Tomorrow: TDateTime;');
  s.AddDelphiFunction('function IsToday(const AValue: TDateTime): Boolean;');
  s.AddDelphiFunction('function IsSameDay(const AValue, ABasis: TDateTime): Boolean;');
  s.AddDelphiFunction('function YearOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MonthOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function WeekOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function DayOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function HourOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MinuteOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function SecondOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MilliSecondOf(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function StartOfTheYear(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function EndOfTheYear(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function StartOfAYear(const AYear: Word): TDateTime;');
  s.AddDelphiFunction('function EndOfAYear(const AYear: Word): TDateTime;');
  s.AddDelphiFunction('function StartOfTheMonth(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function EndOfTheMonth(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function StartOfAMonth(const AYear, AMonth: Word): TDateTime;');
  s.AddDelphiFunction('function EndOfAMonth(const AYear, AMonth: Word): TDateTime;');
  s.AddDelphiFunction('function StartOfTheWeek(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function EndOfTheWeek(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function StartOfAWeek(const AYear, AWeekOfYear: Word; const ADayOfWeek: Word{ = 1}): TDateTime;');
  s.AddDelphiFunction('function EndOfAWeek(const AYear, AWeekOfYear: Word; const ADayOfWeek: Word{ = 7}): TDateTime;');
  s.AddDelphiFunction('function StartOfTheDay(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function EndOfTheDay(const AValue: TDateTime): TDateTime;');
  s.AddDelphiFunction('function StartOfADay(const AYear, AMonth, ADay: Word): TDateTime;');
  s.AddDelphiFunction('function EndOfADay(const AYear, AMonth, ADay: Word): TDateTime;');
  s.AddDelphiFunction('function MonthOfTheYear(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function WeekOfTheYear(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function DayOfTheYear(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function HourOfTheYear(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MinuteOfTheYear(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function SecondOfTheYear(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function MilliSecondOfTheYear(const AValue: TDateTime): Int64;');
  s.AddDelphiFunction('function WeekOfTheMonth(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function DayOfTheMonth(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function HourOfTheMonth(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MinuteOfTheMonth(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function SecondOfTheMonth(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function MilliSecondOfTheMonth(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function DayOfTheWeek(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function HourOfTheWeek(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MinuteOfTheWeek(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function SecondOfTheWeek(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function MilliSecondOfTheWeek(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function HourOfTheDay(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MinuteOfTheDay(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function SecondOfTheDay(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function MilliSecondOfTheDay(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function MinuteOfTheHour(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function SecondOfTheHour(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MilliSecondOfTheHour(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function SecondOfTheMinute(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function MilliSecondOfTheMinute(const AValue: TDateTime): Cardinal;');
  s.AddDelphiFunction('function MilliSecondOfTheSecond(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('function WithinPastYears(const ANow, AThen: TDateTime; const AYears: Integer): Boolean;');
  s.AddDelphiFunction('function WithinPastMonths(const ANow, AThen: TDateTime; const AMonths: Integer): Boolean;');
  s.AddDelphiFunction('function WithinPastWeeks(const ANow, AThen: TDateTime; const AWeeks: Integer): Boolean;');
  s.AddDelphiFunction('function WithinPastDays(const ANow, AThen: TDateTime; const ADays: Integer): Boolean;');
  s.AddDelphiFunction('function WithinPastHours(const ANow, AThen: TDateTime; const AHours: Int64): Boolean;');
  s.AddDelphiFunction('function WithinPastMinutes(const ANow, AThen: TDateTime; const AMinutes: Int64): Boolean;');
  s.AddDelphiFunction('function WithinPastSeconds(const ANow, AThen: TDateTime; const ASeconds: Int64): Boolean;');
  s.AddDelphiFunction('function WithinPastMilliSeconds(const ANow, AThen: TDateTime; const AMilliSeconds: Int64): Boolean;');
  s.AddDelphiFunction('function YearsBetween(const ANow, AThen: TDateTime): Integer;');
  s.AddDelphiFunction('function MonthsBetween(const ANow, AThen: TDateTime): Integer;');
  s.AddDelphiFunction('function WeeksBetween(const ANow, AThen: TDateTime): Integer;');
  s.AddDelphiFunction('function DaysBetween(const ANow, AThen: TDateTime): Integer;');
  s.AddDelphiFunction('function HoursBetween(const ANow, AThen: TDateTime): Int64;');
  s.AddDelphiFunction('function MinutesBetween(const ANow, AThen: TDateTime): Int64;');
  s.AddDelphiFunction('function SecondsBetween(const ANow, AThen: TDateTime): Int64;');
  s.AddDelphiFunction('function MilliSecondsBetween(const ANow, AThen: TDateTime): Int64;');
  {$IF CompilerVersion >= 28}
  s.AddDelphiFunction('function DateTimeInRange(ADateTime: TDateTime; AStartDateTime, AEndDateTime: TDateTime; aInclusive: Boolean{ = True}): Boolean;');
  s.AddDelphiFunction('function DateInRange(ADate: TDate; AStartDate, AEndDate: TDate; AInclusive: Boolean{ = True}): Boolean;');
  s.AddDelphiFunction('function TimeInRange(ATime: TTime; AStartTime, AEndTime: TTime; AInclusive: Boolean{ = True}): Boolean;');
  {$IFEND}
  s.AddDelphiFunction('function YearSpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function MonthSpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function WeekSpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function DaySpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function HourSpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function MinuteSpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function SecondSpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function MilliSecondSpan(const ANow, AThen: TDateTime): Double;');
  s.AddDelphiFunction('function IncYear(const AValue: TDateTime; const ANumberOfYears: Integer{ = 1}): TDateTime;');
  s.AddDelphiFunction('function IncWeek(const AValue: TDateTime; const ANumberOfWeeks: Integer{ = 1}): TDateTime;');
  s.AddDelphiFunction('function IncDay(const AValue: TDateTime; const ANumberOfDays: Integer{ = 1}): TDateTime;');
  s.AddDelphiFunction('function IncHour(const AValue: TDateTime; const ANumberOfHours: Int64{ = 1}): TDateTime;');
  s.AddDelphiFunction('function IncMinute(const AValue: TDateTime; const ANumberOfMinutes: Int64{ = 1}): TDateTime;');
  s.AddDelphiFunction('function IncSecond(const AValue: TDateTime; const ANumberOfSeconds: Int64{ = 1}): TDateTime;');
  s.AddDelphiFunction('function IncMilliSecond(const AValue: TDateTime; const ANumberOfMilliSeconds: Int64{ = 1}): TDateTime;');
  s.AddDelphiFunction('function EncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word): TDateTime;');
  s.AddDelphiFunction('procedure DecodeDateTime(const AValue: TDateTime; out AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word);');
  s.AddDelphiFunction('function EncodeDateWeek(const AYear, AWeekOfYear: Word; const ADayOfWeek: Word{ = 1}): TDateTime;');
  s.AddDelphiFunction('procedure DecodeDateWeek(const AValue: TDateTime; out AYear, AWeekOfYear, ADayOfWeek: Word);');
  s.AddDelphiFunction('function EncodeDateDay(const AYear, ADayOfYear: Word): TDateTime;');
  s.AddDelphiFunction('procedure DecodeDateDay(const AValue: TDateTime; out AYear, ADayOfYear: Word);');
  s.AddDelphiFunction('function EncodeDateMonthWeek(const AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word): TDateTime;');
  s.AddDelphiFunction('procedure DecodeDateMonthWeek(const AValue: TDateTime; out AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word);');
  s.AddDelphiFunction('function TryEncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word; out AValue: TDateTime): Boolean;');
  s.AddDelphiFunction('function TryEncodeDateWeek(const AYear, AWeekOfYear: Word; out AValue: TDateTime; const ADayOfWeek: Word{ = 1}): Boolean;');
  s.AddDelphiFunction('function TryEncodeDateDay(const AYear, ADayOfYear: Word; out AValue: TDateTime): Boolean;');
  s.AddDelphiFunction('function TryEncodeDateMonthWeek(const AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word; var AValue: TDateTime): Boolean;');
  s.AddDelphiFunction('function RecodeYear(const AValue: TDateTime; const AYear: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeMonth(const AValue: TDateTime; const AMonth: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeDay(const AValue: TDateTime; const ADay: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeHour(const AValue: TDateTime; const AHour: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeMinute(const AValue: TDateTime; const AMinute: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeSecond(const AValue: TDateTime; const ASecond: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeMilliSecond(const AValue: TDateTime; const AMilliSecond: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeDate(const AValue: TDateTime; const AYear, AMonth, ADay: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeTime(const AValue: TDateTime; const AHour, AMinute, ASecond, AMilliSecond: Word): TDateTime;');
  s.AddDelphiFunction('function RecodeDateTime(const AValue: TDateTime; const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word): TDateTime;');
  s.AddDelphiFunction('function TryRecodeDateTime(const AValue: TDateTime; const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word; out AResult: TDateTime): Boolean;');
  s.AddDelphiFunction('function CompareDateTime(const A, B: TDateTime): ShortInt{TValueRelationship};');
  s.AddDelphiFunction('function SameDateTime(const A, B: TDateTime): Boolean;');
  s.AddDelphiFunction('function CompareDate(const A, B: TDateTime): ShortInt{TValueRelationship};');
  s.AddDelphiFunction('function SameDate(const A, B: TDateTime): Boolean;');
  s.AddDelphiFunction('function CompareTime(const A, B: TDateTime): ShortInt{TValueRelationship};');
  s.AddDelphiFunction('function SameTime(const A, B: TDateTime): Boolean;');
  s.AddDelphiFunction('function NthDayOfWeek(const AValue: TDateTime): Word;');
  s.AddDelphiFunction('procedure DecodeDayOfWeekInMonth(const AValue: TDateTime; out AYear, AMonth, ANthDayOfWeek, ADayOfWeek: Word);');
  s.AddDelphiFunction('function EncodeDayOfWeekInMonth(const AYear, AMonth, ANthDayOfWeek, ADayOfWeek: Word): TDateTime;');
  s.AddDelphiFunction('function TryEncodeDayOfWeekInMonth(const AYear, AMonth, ANthDayOfWeek, ADayOfWeek: Word; out AValue: TDateTime): Boolean;');
  s.AddDelphiFunction('procedure InvalidDateTimeError(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word; const ABaseDate: TDateTime{ = 0});');
  s.AddDelphiFunction('procedure InvalidDateWeekError(const AYear, AWeekOfYear, ADayOfWeek: Word);');
  s.AddDelphiFunction('procedure InvalidDateDayError(const AYear, ADayOfYear: Word);');
  s.AddDelphiFunction('procedure InvalidDateMonthWeekError(const AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word);');
  s.AddDelphiFunction('procedure InvalidDayOfWeekInMonthError(const AYear, AMonth, ANthDayOfWeek, ADayOfWeek: Word);');
  s.AddDelphiFunction('function DateTimeToJulianDate(const AValue: TDateTime): Double;');
  s.AddDelphiFunction('function JulianDateToDateTime(const AValue: Double): TDateTime;');
  s.AddDelphiFunction('function TryJulianDateToDateTime(const AValue: Double; out ADateTime: TDateTime): Boolean;');
  s.AddDelphiFunction('function DateTimeToModifiedJulianDate(const AValue: TDateTime): Double;');
  s.AddDelphiFunction('function ModifiedJulianDateToDateTime(const AValue: Double): TDateTime;');
  s.AddDelphiFunction('function TryModifiedJulianDateToDateTime(const AValue: Double; out ADateTime: TDateTime): Boolean;');
  s.AddDelphiFunction('function DateTimeToUnix(const AValue: TDateTime; AInputIsUTC: Boolean{ = True}): Int64;');
  s.AddDelphiFunction('function UnixToDateTime(const AValue: Int64; AReturnUTC: Boolean{ = True}): TDateTime;');
  s.AddDelphiFunction('function DateTimeToMilliseconds(const ADateTime: TDateTime): Int64;');
  s.AddDelphiFunction('function TimeToMilliseconds(const ATime: TTime): Integer;');
  s.AddDelphiFunction('function ISO8601ToDate(const AISODate: string; AReturnUTC: Boolean{ = True}): TDateTime;');
  s.AddDelphiFunction('function TryISO8601ToDate(const AISODate: string; out Value: TDateTime; AReturnUTC: Boolean{ = True}): Boolean;');
  s.AddDelphiFunction('function DateToISO8601(const ADate: TDateTime; AInputIsUTC: Boolean{ = True}): string;');

  {$IF CompilerVersion >= 28}
  S.AddTypeS('TLocalTimeType', '(lttStandard, lttDaylight, lttAmbiguous, lttInvalid)');
  {$IFEND}
  s.AddConstant('DaysPerWeek',DaysPerWeek);
  s.AddConstant('WeeksPerFortnight',WeeksPerFortnight);
  S.AddConstant('MonthsPerYear',MonthsPerYear);
  S.AddConstant('YearsPerDecade',YearsPerDecade);
  S.AddConstant('YearsPerCentury',YearsPerCentury);
  S.AddConstant('YearsPerMillennium',YearsPerMillennium);
  S.AddConstant('DayMonday',DayMonday);
  S.AddConstant('DayTuesday',DayTuesday);
  S.AddConstant('DayWednesday',DayWednesday);
  S.AddConstant('DayThursday',DayThursday);
  S.AddConstant('DayFriday',DayFriday);
  S.AddConstant('DaySaturday',DaySaturday);
  S.AddConstant('DaySunday',DaySunday);
  {$IF CompilerVersion >= 28}
  S.AddConstant('MonthJanuary',MonthJanuary);
  S.AddConstant('MonthFebruary',MonthFebruary);
  S.AddConstant('MonthMarch',MonthMarch);
  S.AddConstant('MonthApril',MonthApril);
  S.AddConstant('MonthMay',MonthMay);
  S.AddConstant('MonthJune',MonthJune);
  S.AddConstant('MonthJuly',MonthJuly);
  S.AddConstant('MonthAugust',MonthAugust);
  S.AddConstant('MonthSeptember',MonthSeptember);
  S.AddConstant('MonthOctober',MonthOctober);
  S.AddConstant('MonthNovember',MonthNovember);
  S.AddConstant('MonthDecember',MonthDecember);
  {$IFEND}
  S.AddConstant('OneHour',OneHour);
  S.AddConstant('OneMinute',OneMinute);
  S.AddConstant('OneSecond',OneSecond);
  S.AddConstant('OneMillisecond',OneMillisecond);
  {$IF CompilerVersion >= 28}
  S.AddConstant('EpochAsJulianDate',EpochAsJulianDate);
  S.AddConstant('EpochAsUnixDate',EpochAsUnixDate);
  {$IFEND}
  S.AddConstant('RecodeLeaveFieldAsIs',RecodeLeaveFieldAsIs);

  S.AddConstant('ApproxDaysPerMonth',ApproxDaysPerMonth);
  S.AddConstant('ApproxDaysPerYear',ApproxDaysPerYear);
end;

end.
