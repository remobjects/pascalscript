{ Compile time Date Time library }
unit uPSC_Math;

interface

uses
  uPSCompiler, uPSUtils;

procedure RegisterMathLibrary_C(S: TPSPascalCompiler);

implementation

uses
  Math;

procedure RegisterMathLibrary_C(S: TPSPascalCompiler);
begin
  S.AddConstant( 'MinSingle', MinSingle );
  S.AddConstant( 'MaxSingle', MaxSingle );
  S.AddConstant( 'MinDouble', MinDouble );
  S.AddConstant( 'MaxDouble', MaxDouble );
  S.AddConstant( 'MinExtended', MinExtended );
  S.AddConstant( 'MaxExtended', MaxExtended );
  S.AddConstant( 'MinComp', MinComp );
  S.AddConstant( 'MaxComp', MaxComp );
  S.AddConstant( 'NaN', NaN );
  S.AddConstant( 'Infinity', Infinity );
  S.AddConstant( 'NegInfinity', NegInfinity );
  S.AddConstant( 'NegativeValue', NegativeValue );
  S.AddConstant( 'ZeroValue', ZeroValue );
  S.AddConstant( 'PositiveValue', PositiveValue );

  S.AddConstant( 'seSSE', seSSE );
  S.AddConstant( 'seSSE2', seSSE2 );
  S.AddConstant( 'seSSE3', seSSE3 );
  S.AddConstant( 'seSSSE3', seSSSE3 );
  S.AddConstant( 'seSSE41', seSSE41 );
  S.AddConstant( 'seSSE42', seSSE42 );
  S.AddConstant( 'sePOPCNT', sePOPCNT );
  S.AddConstant( 'seAESNI', seAESNI );
  S.AddConstant( 'sePCLMULQDQ', sePCLMULQDQ );

  S.AddTypeS( 'TPaymentTime', '(ptEndOfPeriod, ptStartOfPeriod)' );

  s.AddDelphiFunction('function ArcCos(const X : Extended) : Extended;');
  s.AddDelphiFunction('function ArcSin(const X : Extended) : Extended;');
  s.AddDelphiFunction('function ArcTan2(const Y, X: Extended): Extended;');
  s.AddDelphiFunction('procedure SinCos(const Theta: Extended; var Sin, Cos: Extended);');
  s.AddDelphiFunction('function Tan(const X: Extended): Extended;');
  s.AddDelphiFunction('function Cotan(const X: Extended): Extended;');
  s.AddDelphiFunction('function Secant(const X: Extended): Extended;');
  s.AddDelphiFunction('function Cosecant(const X: Extended): Extended;');
  s.AddDelphiFunction('function Hypot(const X, Y: Extended): Extended;');
  s.AddDelphiFunction('function Hypot_(const X, Y, Z: Extended): Extended;');
  s.AddDelphiFunction('function RadToDeg(const Radians: Extended): Extended;');
  s.AddDelphiFunction('function RadToGrad(const Radians: Extended): Extended;');
  s.AddDelphiFunction('function RadToCycle(const Radians: Extended): Extended;');
  s.AddDelphiFunction('function DegToRad(const Degrees: Extended): Extended;');
  s.AddDelphiFunction('function DegToGrad(const Degrees: Extended): Extended;');
  s.AddDelphiFunction('function DegToCycle(const Degrees: Extended): Extended;');
  s.AddDelphiFunction('function DegNormalize(const Degrees: Extended): Extended;');
  s.AddDelphiFunction('function GradToRad(const Grads: Extended): Extended;');
  s.AddDelphiFunction('function GradToDeg(const Grads: Extended): Extended;');
  s.AddDelphiFunction('function GradToCycle(const Grads: Extended): Extended;');
  s.AddDelphiFunction('function CycleToRad(const Cycles: Extended): Extended;');
  s.AddDelphiFunction('function CycleToDeg(const Cycles: Extended): Extended;');
  s.AddDelphiFunction('function CycleToGrad(const Cycles: Extended): Extended;');
  s.AddDelphiFunction('function Cot(const X: Extended): Extended;');
  s.AddDelphiFunction('function Sec(const X: Extended): Extended;');
  s.AddDelphiFunction('function Csc(const X: Extended): Extended;');
  s.AddDelphiFunction('function Cosh(const X: Extended): Extended;');
  s.AddDelphiFunction('function Sinh(const X: Extended): Extended;');
  s.AddDelphiFunction('function Tanh(const X: Extended): Extended;');
  s.AddDelphiFunction('function CotH(const X: Extended): Extended;');
  s.AddDelphiFunction('function SecH(const X: Extended): Extended;');
  s.AddDelphiFunction('function CscH(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcCot(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcSec(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcCsc(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcCosh(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcSinh(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcTanh(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcCotH(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcSecH(const X: Extended): Extended;');
  s.AddDelphiFunction('function ArcCscH(const X: Extended): Extended;');
  s.AddDelphiFunction('function LnXP1(const X: Extended): Extended;');
  s.AddDelphiFunction('function Log10(const X: Extended): Extended;');
  s.AddDelphiFunction('function Log2(const X: Extended): Extended;');
  s.AddDelphiFunction('function LogN(const Base, X: Extended): Extended;');
  s.AddDelphiFunction('function IntPower(const Base: Extended; const Exponent: Integer): Extended;');
  s.AddDelphiFunction('function Power(const Base, Exponent: Extended): Extended;');
  s.AddDelphiFunction('procedure Frexp(const X: Extended; var Mantissa: Extended; var Exponent: Integer);');
  s.AddDelphiFunction('function Ldexp(const X: Extended; const P: Integer): Extended;');
  s.AddDelphiFunction('function Ceil(const X: Extended): Integer;');
  s.AddDelphiFunction('function Floor(const X: Extended): Integer;');
  s.AddDelphiFunction('function Poly(const X: Extended; const Coefficients: array of Extended): Extended;');
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function Mean(const Data: array of Double): Extended;');
  s.AddDelphiFunction('function Sum(const Data: array of Double): Extended;');
  {$ELSE}
  s.AddDelphiFunction('function Mean(const Data: array of Extended): Extended;');
  s.AddDelphiFunction('function Sum(const Data: array of Extended): Extended;');
  {$IFEND}
  s.AddDelphiFunction('function SumInt(const Data: array of Integer): Integer;');
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function SumOfSquares(const Data: array of Double): Extended;');
  s.AddDelphiFunction('procedure SumsAndSquares(const Data: array of Double; var Sum, SumOfSquares: Extended);');
  {$ELSE}
  s.AddDelphiFunction('function SumOfSquares(const Data: array of Extended): Extended;');
  s.AddDelphiFunction('procedure SumsAndSquares(const Data: array of Extended; var Sum, SumOfSquares: Extended);');
  {$IFEND}
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function MinValue(const Data: array of Double): Double;');
  {$ELSE}
  s.AddDelphiFunction('function MinValue(const Data: array of Extended): Extended;');
  {$IFEND}
  s.AddDelphiFunction('function MinIntValue(const Data: array of Integer): Integer;');
  s.AddDelphiFunction('function Min(const A, B: Int64): Int64;');
  s.AddDelphiFunction('function MinF(const A, B: Extended): Extended;');
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function MaxValue(const Data: array of Double): Double;');
  {$ELSE}
  s.AddDelphiFunction('function MaxValue(const Data: array of Extended): Extended;');
  {$IFEND}
  s.AddDelphiFunction('function MaxIntValue(const Data: array of Integer): Integer;');
  s.AddDelphiFunction('function Max(const A, B: Int64): Int64;');
  s.AddDelphiFunction('function MaxF(const A, B: Extended): Extended;');
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function StdDev(const Data: array of Double): Extended;');
  s.AddDelphiFunction('procedure MeanAndStdDev(const Data: array of Double; var Mean, StdDev: Extended);');
  s.AddDelphiFunction('function PopnStdDev(const Data: array of Double): Extended;');
  s.AddDelphiFunction('function Variance(const Data: array of Double): Extended;');
  s.AddDelphiFunction('function PopnVariance(const Data: array of Double): Extended;');
  s.AddDelphiFunction('function TotalVariance(const Data: array of Double): Extended;');
  s.AddDelphiFunction('function Norm(const Data: array of Double): Extended;');
  {$ELSE}
  s.AddDelphiFunction('function StdDev(const Data: array of Extended): Extended;');
  s.AddDelphiFunction('procedure MeanAndStdDev(const Data: array of Extended; var Mean, StdDev: Extended);');
  s.AddDelphiFunction('function PopnStdDev(const Data: array of Extended): Extended;');
  s.AddDelphiFunction('function Variance(const Data: array of Extended): Extended;');
  s.AddDelphiFunction('function PopnVariance(const Data: array of Extended): Extended;');
  s.AddDelphiFunction('function TotalVariance(const Data: array of Extended): Extended;');
  s.AddDelphiFunction('function Norm(const Data: array of Extended): Extended;');
  {$IFEND}
  s.AddDelphiFunction('procedure MomentSkewKurtosis(const Data: array of Double; var M1, M2, M3, M4, Skew, Kurtosis: Extended);');
  s.AddDelphiFunction('function RandG(Mean, StdDev: Extended): Extended;');
  s.AddDelphiFunction('function IsNan(const AValue: Extended): Boolean;');
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function IsInfinite(const AValue: Double): Boolean;');
  {$ELSE}
  s.AddDelphiFunction('function IsInfinite(const AValue: Extended): Boolean;');
  {$IFEND}
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function Sign(const AValue: Double): ShortInt{TValueSign};');
  {$ELSE}
  s.AddDelphiFunction('function Sign(const AValue: Extended): ShortInt{TValueSign};');
  {$IFEND}
  s.AddDelphiFunction('function CompareValueF(const A : Extended; B: Extended; Epsilon: Extended{ = 0}): ShortInt{TValueRelationship};');
  s.AddDelphiFunction('function CompareValue(const A : Int64; B: Int64): ShortInt{TValueRelationship};');
  s.AddDelphiFunction('function SameValueF(const A : Extended; B: Extended; Epsilon: Extended{ = 0}): Boolean;');
  s.AddDelphiFunction('function SameValue(const A : Int64; B: Int64): Boolean;');
  s.AddDelphiFunction('function IsZero(const A: Extended; Epsilon: Extended{ = 0}): Boolean;');
  s.AddDelphiFunction('function IfThen(AValue: Boolean; const ATrue: Extended; const AFalse: Extended{ = 0.0}): Extended;');
  {$IF CompilerVersion > 22}
  s.AddDelphiFunction('function FMod(const ANumerator, ADenominator: Extended): Extended;');
  {$IFEND}
  s.AddDelphiFunction('function RandomRange(const AFrom, ATo: Integer): Integer;');
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function RandomFrom(const AValues: array of Double): Double;');
  s.AddDelphiFunction('function InRange(const AValue, AMin, AMax: Double): Boolean;');
  s.AddDelphiFunction('function EnsureRange(const AValue, AMin, AMax: Double): Double;');
  s.AddDelphiFunction('procedure DivMod(Dividend: Integer; Divisor: Word; var Result, Remainder: Word);');
  {$ELSE}
  s.AddDelphiFunction('function RandomFrom(const AValues: array of Extended): Extended;');
  s.AddDelphiFunction('function InRange(const AValue, AMin, AMax: Extended): Boolean;');
  s.AddDelphiFunction('function EnsureRange(const AValue, AMin, AMax: Extended): Extended;');
  s.AddDelphiFunction('procedure DivMod(Dividend: Cardinal; Divisor: Word; var Result, Remainder: Word);');
  {$IFEND}
  s.AddDelphiFunction('function RoundTo(const AValue: Extended; const ADigit: ShortInt{TRoundToEXRangeExtended}): Extended;');
  {$IF CompilerVersion < 22}
  s.AddDelphiFunction('function SimpleRoundTo(const AValue: Double; const ADigit: ShortInt{TRoundToRange = -2}): Double;');
  {$ELSE}
  s.AddDelphiFunction('function SimpleRoundTo(const AValue: Extended; const ADigit: ShortInt{TRoundToRange = -2}): Extended;');
  {$IFEND}
  s.AddDelphiFunction('function DoubleDecliningBalance(const Cost, Salvage: Extended; Life, Period: Integer): Extended;');
  s.AddDelphiFunction('function FutureValue(const Rate: Extended; NPeriods: Integer; const Payment, PresentValue: Extended; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function InterestPayment(const Rate: Extended; Period, NPeriods: Integer; const PresentValue, FutureValue: Extended; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function InterestRate(NPeriods: Integer; const Payment, PresentValue, FutureValue: Extended; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function InternalRateOfReturn(const Guess: Extended; const CashFlows: array of Double): Extended;');
  s.AddDelphiFunction('function NumberOfPeriods(const Rate: Extended; Payment: Extended; const PresentValue, FutureValue: Extended; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function NetPresentValue(const Rate: Extended; const CashFlows: array of Double; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function Payment(Rate: Extended; NPeriods: Integer; const PresentValue, FutureValue: Extended; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function PeriodPayment(const Rate: Extended; Period, NPeriods: Integer; const PresentValue, FutureValue: Extended; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function PresentValue(const Rate: Extended; NPeriods: Integer; const Payment, FutureValue: Extended; PaymentTime: TPaymentTime): Extended;');
  s.AddDelphiFunction('function SLNDepreciation(const Cost, Salvage: Extended; Life: Integer): Extended;');
  s.AddDelphiFunction('function SYDDepreciation(const Cost, Salvage: Extended; Life, Period: Integer): Extended;');
end;

end.
