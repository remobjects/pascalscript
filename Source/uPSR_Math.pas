unit uPSR_Math;
{$I PascalScript.inc}
interface

{$WARN UNSAFE_CODE OFF}

uses
  uPSRuntime;

procedure RegisterMathLibrary_R(S: TPSExec);

implementation

uses
  Math;

procedure RegisterMathLibrary_R(S: TPSExec);
begin
  S.RegisterDelphiFunction( @ArcCos, 'ArcCos', cdRegister );
  S.RegisterDelphiFunction( @ArcSin, 'ArcSin', cdRegister );
  S.RegisterDelphiFunction( @ArcTan2, 'ArcTan2', cdRegister );
  S.RegisterDelphiFunction( @SinCos, 'SinCos', cdRegister );
  S.RegisterDelphiFunction( @Tan, 'Tan', cdRegister );
  S.RegisterDelphiFunction( @Cotan, 'Cotan', cdRegister );
  S.RegisterDelphiFunction( @Secant, 'Secant', cdRegister );
  S.RegisterDelphiFunction( @Cosecant, 'Cosecant', cdRegister );
  S.RegisterDelphiFunction( @Hypot, 'Hypot', cdRegister );
  S.RegisterDelphiFunction( @Hypot, 'Hypot_', cdRegister );
  S.RegisterDelphiFunction( @RadToDeg, 'RadToDeg', cdRegister );
  S.RegisterDelphiFunction( @RadToGrad, 'RadToGrad', cdRegister );
  S.RegisterDelphiFunction( @RadToCycle, 'RadToCycle', cdRegister );
  S.RegisterDelphiFunction( @DegToRad, 'DegToRad', cdRegister );
  S.RegisterDelphiFunction( @DegToGrad, 'DegToGrad', cdRegister );
  S.RegisterDelphiFunction( @DegToCycle, 'DegToCycle', cdRegister );
  {$IF CompilerVersion >= 23}
  S.RegisterDelphiFunction( @DegNormalize, 'DegNormalize', cdRegister );
  {$IFEND}
  S.RegisterDelphiFunction( @GradToRad, 'GradToRad', cdRegister );
  S.RegisterDelphiFunction( @GradToDeg, 'GradToDeg', cdRegister );
  S.RegisterDelphiFunction( @GradToCycle, 'GradToCycle', cdRegister );
  S.RegisterDelphiFunction( @CycleToRad, 'CycleToRad', cdRegister );
  S.RegisterDelphiFunction( @CycleToDeg, 'CycleToDeg', cdRegister );
  S.RegisterDelphiFunction( @CycleToGrad, 'CycleToGrad', cdRegister );
  S.RegisterDelphiFunction( @Cot, 'Cot', cdRegister );
  S.RegisterDelphiFunction( @Sec, 'Sec', cdRegister );
  S.RegisterDelphiFunction( @Csc, 'Csc', cdRegister );
  S.RegisterDelphiFunction( @Cosh, 'Cosh', cdRegister );
  S.RegisterDelphiFunction( @Sinh, 'Sinh', cdRegister );
  S.RegisterDelphiFunction( @Tanh, 'Tanh', cdRegister );
  S.RegisterDelphiFunction( @CotH, 'CotH', cdRegister );
  S.RegisterDelphiFunction( @SecH, 'SecH', cdRegister );
  S.RegisterDelphiFunction( @CscH, 'CscH', cdRegister );
  S.RegisterDelphiFunction( @ArcCot, 'ArcCot', cdRegister );
  S.RegisterDelphiFunction( @ArcSec, 'ArcSec', cdRegister );
  S.RegisterDelphiFunction( @ArcCsc, 'ArcCsc', cdRegister );
  S.RegisterDelphiFunction( @ArcCosh, 'ArcCosh', cdRegister );
  S.RegisterDelphiFunction( @ArcSinh, 'ArcSinh', cdRegister );
  S.RegisterDelphiFunction( @ArcTanh, 'ArcTanh', cdRegister );
  S.RegisterDelphiFunction( @ArcCotH, 'ArcCotH', cdRegister );
  S.RegisterDelphiFunction( @ArcSecH, 'ArcSecH', cdRegister );
  S.RegisterDelphiFunction( @ArcCscH, 'ArcCscH', cdRegister );
  S.RegisterDelphiFunction( @LnXP1, 'LnXP1', cdRegister );
  S.RegisterDelphiFunction( @Log10, 'Log10', cdRegister );
  S.RegisterDelphiFunction( @Log2, 'Log2', cdRegister );
  S.RegisterDelphiFunction( @LogN, 'LogN', cdRegister );
  S.RegisterDelphiFunction( @IntPower, 'IntPower', cdRegister );
  S.RegisterDelphiFunction( @Power, 'Power', cdRegister );
  S.RegisterDelphiFunction( @Frexp, 'Frexp', cdRegister );
  S.RegisterDelphiFunction( @Ldexp, 'Ldexp', cdRegister );
  S.RegisterDelphiFunction( @Ceil, 'Ceil', cdRegister );
  S.RegisterDelphiFunction( @Floor, 'Floor', cdRegister );
  S.RegisterDelphiFunction( @Poly, 'Poly', cdRegister );
  S.RegisterDelphiFunction( @Mean, 'Mean', cdRegister );
  S.RegisterDelphiFunction( @Sum, 'Sum', cdRegister );
  S.RegisterDelphiFunction( @SumInt, 'SumInt', cdRegister );
  S.RegisterDelphiFunction( @SumOfSquares, 'SumOfSquares', cdRegister );
  S.RegisterDelphiFunction( @SumsAndSquares, 'SumsAndSquares', cdRegister );
  S.RegisterDelphiFunction( @MinValue, 'MinValue', cdRegister );
  S.RegisterDelphiFunction( @MinIntValue, 'MinIntValue', cdRegister );
  S.RegisterDelphiFunction( @Min, 'Min', cdRegister );
  S.RegisterDelphiFunction( @Min, 'MinF', cdRegister );
  S.RegisterDelphiFunction( @MaxValue, 'MaxValue', cdRegister );
  S.RegisterDelphiFunction( @MaxIntValue, 'MaxIntValue', cdRegister );
  S.RegisterDelphiFunction( @Max, 'Max', cdRegister );
  S.RegisterDelphiFunction( @Max, 'MaxF', cdRegister );
  S.RegisterDelphiFunction( @StdDev, 'StdDev', cdRegister );
  S.RegisterDelphiFunction( @MeanAndStdDev, 'MeanAndStdDev', cdRegister );
  S.RegisterDelphiFunction( @PopnStdDev, 'PopnStdDev', cdRegister );
  S.RegisterDelphiFunction( @Variance, 'Variance', cdRegister );
  S.RegisterDelphiFunction( @PopnVariance, 'PopnVariance', cdRegister );
  S.RegisterDelphiFunction( @TotalVariance, 'TotalVariance', cdRegister );
  S.RegisterDelphiFunction( @Norm, 'Norm', cdRegister );
  S.RegisterDelphiFunction( @MomentSkewKurtosis, 'MomentSkewKurtosis', cdRegister );
  S.RegisterDelphiFunction( @RandG, 'RandG', cdRegister );
  S.RegisterDelphiFunction( @IsNan, 'IsNan', cdRegister );
  S.RegisterDelphiFunction( @IsInfinite, 'IsInfinite', cdRegister );
  S.RegisterDelphiFunction( @Sign, 'Sign', cdRegister );
  S.RegisterDelphiFunction( @CompareValue, 'CompareValueF', cdRegister );
  S.RegisterDelphiFunction( @CompareValue, 'CompareValue', cdRegister );
  S.RegisterDelphiFunction( @SameValue, 'SameValueF', cdRegister );
  S.RegisterDelphiFunction( @SameValue, 'SameValue', cdRegister );
  S.RegisterDelphiFunction( @IsZero, 'IsZero', cdRegister );
  S.RegisterDelphiFunction( @IfThen, 'IfThen', cdRegister );
  {$IF CompilerVersion > 22}
  S.RegisterDelphiFunction( @FMod, 'FMod', cdRegister );
  {$IFEND}
  S.RegisterDelphiFunction( @RandomRange, 'RandomRange', cdRegister );
  S.RegisterDelphiFunction( @RandomFrom, 'RandomFrom', cdRegister );
  S.RegisterDelphiFunction( @InRange, 'InRange', cdRegister );
  S.RegisterDelphiFunction( @EnsureRange, 'EnsureRange', cdRegister );
  S.RegisterDelphiFunction( @DivMod, 'DivMod', cdRegister );
  S.RegisterDelphiFunction( @RoundTo, 'RoundTo', cdRegister );
  S.RegisterDelphiFunction( @SimpleRoundTo, 'SimpleRoundTo', cdRegister );
  S.RegisterDelphiFunction( @DoubleDecliningBalance, 'DoubleDecliningBalance', cdRegister );
  S.RegisterDelphiFunction( @FutureValue, 'FutureValue', cdRegister );
  S.RegisterDelphiFunction( @InterestPayment, 'InterestPayment', cdRegister );
  S.RegisterDelphiFunction( @InterestRate, 'InterestRate', cdRegister );
  S.RegisterDelphiFunction( @InternalRateOfReturn, 'InternalRateOfReturn', cdRegister );
  S.RegisterDelphiFunction( @NumberOfPeriods, 'NumberOfPeriods', cdRegister );
  S.RegisterDelphiFunction( @NetPresentValue, 'NetPresentValue', cdRegister );
  S.RegisterDelphiFunction( @Payment, 'Payment', cdRegister );
  S.RegisterDelphiFunction( @PeriodPayment, 'PeriodPayment', cdRegister );
  S.RegisterDelphiFunction( @PresentValue, 'PresentValue', cdRegister );
  S.RegisterDelphiFunction( @SLNDepreciation, 'SLNDepreciation', cdRegister );
  S.RegisterDelphiFunction( @SYDDepreciation, 'SYDDepreciation', cdRegister );
end;

end.
