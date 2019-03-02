{ x64.inc }

{.$O-,D+,L+} // for debug

{$IFDEF DELPHI}
  {$DEFINE PS_RESBEFOREPARAMETERS}
  {$DEFINE x64_string_result_as_varparameter}
{$ENDIF}

{ implementation of x64 abi }
//procedure DebugBreak; external 'Kernel32.dll';
const
  EmptyPChar: array[0..0] of Char = (Char(#0));

type
  EInvocationError = class(Exception);

//
// Calculate/Declare defines
//
{$UNDEF X64CALL_ASM} { not change }
{$UNDEF REG_STACK_PTR_OFFSET0} { not change }
{$IFDEF MSWINDOWS}{$DEFINE WINDOWS}{$ENDIF}

{$IFDEF MSWINDOWS}
  {$IFDEF CPUX64}

    {$IFDEF DELPHI}
      {$DEFINE X64CALL_ASM} { optional } // ! Successfully on exceptions !
    {$ENDIF}

    {$IFDEF FPC}
      {.$DEFINE X64CALL_ASM} { optional } // ! Not recomended : GPF on exception !
    {$ENDIF}

  {$ELSE}

  {$ENDIF}
{$ELSE !MSWINDOWS}

  {$DEFINE X64CALL_ASM} { optional } // TODO: Check pas version (disable "X64CALL_ASM").

{$ENDIF !MSWINDOWS}

{$IFNDEF X64CALL_ASM} // PURE PASCAL version. ! DELPHI/FPC: Successfully on exceptions !
type
  {$IFDEF CPUX64}
  t_pstask = array[0..61] of IPointer;
  p_pstask = ^t_pstask;
  TRegisters = packed record
    _RCX,                  // 0
    _RDX,                  // 8
    _R8,                   // 16
    _R9: IPointer;         // 24
    _XMM1,                 // 32
    _XMM2,                 // 40
    _XMM3: Double;         // 48
    case byte of
    0:(
      Stack: Pointer;      // 56
      Items: {$IFDEF FPC}PtrUInt{$ELSE}IntPtr{$ENDIF}; // 64
      SingleBits: Integer; // 72
      );
    1:(S: p_pstask);
  end;
  {$ENDIF CPUX64}
  {$DEFINE REG_STACK_PTR_OFFSET0} { not change }
type
  t_pcall_04 = procedure(_rcx,_rdx,_r8,_r9: IPointer);
  t_pcall_05 = procedure(_rcx,_rdx,_r8,_r9,p5: IPointer);
  t_pcall_06 = procedure(_rcx,_rdx,_r8,_r9,p5,p6: IPointer);
  t_pcall_07 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7: IPointer);
  t_pcall_08 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8: IPointer);
  t_pcall_09 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9: IPointer);
  t_pcall_10 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10: IPointer);
  t_pcall_11 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11: IPointer);
  t_pcall_12 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12: IPointer);
  t_pcall_13 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13: IPointer);
  t_pcall_14 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14: IPointer);
  t_pcall_15 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15: IPointer);
  t_pcall_16 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16: IPointer);
  t_pcall_17 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17: IPointer);
  t_pcall_18 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18: IPointer);
  t_pcall_19 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19: IPointer);
  t_pcall_20 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20: IPointer);
  t_pcall_21 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21: IPointer);
  t_pcall_22 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22: IPointer);
  t_pcall_23 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23: IPointer);
  t_pcall_24 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24: IPointer);
  t_pcall_25 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25: IPointer);
  t_pcall_26 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26: IPointer);
  t_pcall_27 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27: IPointer);
  t_pcall_28 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28: IPointer);
  t_pcall_29 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29: IPointer);
  t_pcall_30 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30: IPointer);
  t_pcall_31 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31: IPointer);
  t_pcall_32 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32: IPointer);
  t_pcall_33 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33: IPointer);
  t_pcall_34 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34: IPointer);
  t_pcall_35 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35: IPointer);
  t_pcall_36 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36: IPointer);
  t_pcall_37 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37: IPointer);
  t_pcall_38 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38: IPointer);
  t_pcall_39 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39: IPointer);
  t_pcall_40 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40: IPointer);
  t_pcall_41 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41: IPointer);
  t_pcall_42 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42: IPointer);
  t_pcall_43 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43: IPointer);
  t_pcall_44 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44: IPointer);
  t_pcall_45 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45: IPointer);
  t_pcall_46 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46: IPointer);
  t_pcall_47 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47: IPointer);
  t_pcall_48 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48: IPointer);
  t_pcall_49 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49: IPointer);
  t_pcall_50 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50: IPointer);
  t_pcall_51 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51: IPointer);
  t_pcall_52 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52: IPointer);
  t_pcall_53 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53: IPointer);
  t_pcall_54 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54: IPointer);
  t_pcall_55 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55: IPointer);
  t_pcall_56 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56: IPointer);
  t_pcall_57 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57: IPointer);
  t_pcall_58 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58: IPointer);
  t_pcall_59 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59: IPointer);
  t_pcall_60 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59,p60: IPointer);
  t_pcall_61 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59,p60,p61: IPointer);
  t_pcall_62 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59,p60,p61,p62: IPointer);
  t_pcall_63 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59,p60,p61,p62,p63: IPointer);
  t_pcall_64 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59,p60,p61,p62,p63,p64: IPointer);
  t_pcall_65 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59,p60,p61,p62,p63,p64,p65: IPointer);
  t_pcall_66 = procedure(_rcx,_rdx,_r8,_r9,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,
    p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,
    p41,p42,p43,p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57,p58,p59,p60,p61,p62,p63,p64,p65,p66: IPointer);
procedure x64call({RCX}Address: Pointer;out {RDX}_RAX: IPointer;var {R8}_XMM0: Double; var {R9}R: TRegisters);
begin
  case R.Items of // stack items count
    00: t_pcall_04(Address)(R._RCX,R._RDX,R._R8,R._R9);
    01: t_pcall_05(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00]);
    02: t_pcall_06(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01]);
    03: t_pcall_07(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02]);
    04: t_pcall_08(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03]);
    05: t_pcall_09(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04]);
    06: t_pcall_10(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05]);
    07: t_pcall_11(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
          R.S[06]);
    08: t_pcall_12(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07]);
    09: t_pcall_13(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08]);
    10: t_pcall_14(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09]);
    11: t_pcall_15(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10]);
    12: t_pcall_16(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11]);
    13: t_pcall_17(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12]);
    14: t_pcall_18(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13]);
    15: t_pcall_19(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14]);
    16: t_pcall_20(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15]);
    17: t_pcall_21(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16]);
    18: t_pcall_22(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17]);
    19: t_pcall_23(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18]);
    20: t_pcall_24(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19]);
    21: t_pcall_25(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20]);
    22: t_pcall_26(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21]);
    23: t_pcall_27(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22]);
    24: t_pcall_28(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23]);
    25: t_pcall_29(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24]);
    26: t_pcall_30(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25]);
    27: t_pcall_31(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26]);
    28: t_pcall_32(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27]);
    29: t_pcall_33(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28]);
    30: t_pcall_34(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29]);
    31: t_pcall_35(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30]);
    32: t_pcall_36(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31]);
    33: t_pcall_37(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32]);
    34: t_pcall_38(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33]);
    35: t_pcall_39(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34]);
    36: t_pcall_40(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35]);
    37: t_pcall_41(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36]);
    38: t_pcall_42(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37]);
    39: t_pcall_43(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38]);
    40: t_pcall_44(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39]);
    41: t_pcall_45(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40]);
    42: t_pcall_46(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41]);
    43: t_pcall_47(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42]);
    44: t_pcall_48(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43]);
    45: t_pcall_49(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44]);
    46: t_pcall_50(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45]);
    47: t_pcall_51(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46]);
    48: t_pcall_52(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47]);
    49: t_pcall_53(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48]);
    50: t_pcall_54(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49]);
    51: t_pcall_55(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50]);
    52: t_pcall_56(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51]);
    53: t_pcall_57(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52]);
    54: t_pcall_58(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53]);
    55: t_pcall_59(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54]);
    56: t_pcall_60(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54],R.S[55]);
    57: t_pcall_61(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54],R.S[55],
      R.S[56]);
    58: t_pcall_62(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54],R.S[55],
      R.S[56],R.S[57]);
    59: t_pcall_63(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54],R.S[55],
      R.S[56],R.S[57],R.S[58]);
    60: t_pcall_64(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54],R.S[55],
      R.S[56],R.S[57],R.S[58],R.S[59]);
    61: t_pcall_65(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54],R.S[55],
      R.S[56],R.S[57],R.S[58],R.S[59],R.S[60]);
    62: t_pcall_66(Address)(R._RCX,R._RDX,R._R8,R._R9,R.S[00],R.S[01],R.S[02],R.S[03],R.S[04],R.S[05],
      R.S[06],R.S[07],R.S[08],R.S[09],R.S[10],R.S[11],R.S[12],R.S[13],R.S[14],R.S[15],
      R.S[16],R.S[17],R.S[18],R.S[19],R.S[20],R.S[21],R.S[22],R.S[23],R.S[24],R.S[25],
      R.S[26],R.S[27],R.S[28],R.S[29],R.S[30],R.S[31],R.S[32],R.S[33],R.S[34],R.S[35],
      R.S[36],R.S[37],R.S[38],R.S[39],R.S[40],R.S[41],R.S[42],R.S[43],R.S[44],R.S[45],
      R.S[46],R.S[47],R.S[48],R.S[49],R.S[50],R.S[51],R.S[52],R.S[53],R.S[54],R.S[55],
      R.S[56],R.S[57],R.S[58],R.S[59],R.S[60],R.S[61]);
    //}
    else
      raise EInvocationError.Create('Internal: Parameter count exceeded 64');
  end;
end;
{$ENDIF}

{$IFDEF X64CALL_ASM}

{$IFDEF WINDOWS}
type
  //{$IFDEF UNICODE_OR_FPC}{$ALIGN 16}{$ENDIF} // For packed record mode
  //{$ifdef FPC}
  //{$PACKRECORDS 16}
  //{$endif}
  t_pstask = array[0..61] of IPointer;
  p_pstask = ^t_pstask;
  TRegisters = packed record
    _RCX,                  // 0
    _RDX,                  // 8
    _R8,                   // 16
    _R9: IPointer;         // 24
    _XMM1,                 // 32
    _XMM2,                 // 40
    _XMM3: Double;         // 48
    case byte of
    0:(
      Stack: Pointer;      // 56
      Items: {$IFDEF FPC}PtrUInt{$ELSE}IntPtr{$ENDIF}; // 64
      SingleBits: Integer; // 72
      );
    1:(S: p_pstask);
  end;
  PRegisters=^TRegisters;

{$IFDEF CPUX64}

  {$IFDEF DELPHI}
    {$DEFINE REG_STACK_PTR_OFFSET0} { optional } // ! Successfully on exceptions !
  {$ENDIF}

  {$IFDEF FPC}
    {$mode delphi}
    {$ASMMODE INTEL}
    {.$DEFINE REG_STACK_PTR_OFFSET0} { optional } // ! GPF on exceptions for both asm variants!
  {$ENDIF}

{$ENDIF CPUX64}

{$IFDEF REG_STACK_PTR_OFFSET0} // ! NEW asm-win-x64 version for delphi and/or fpc !

procedure x64call({RCX}Address: Pointer;out {RDX}_RAX: IPointer;var {R8}_XMM0: Double; var {R9}RegInfo: TRegisters);
assembler; {$ifdef FPC}nostackframe;{$endif}
  //
  // !!! DELPHI: Successfully on exceptions !
  // !!! TODO: FPC: ! GPF on exception !
  //
  procedure InvokeErrorParamCount; // The number of parameters exceeded 64 (c_par_max_count)
  begin
    raise EInvocationError.Create('Internal: Parameter count exceeded 64');
  end;
  //
const
  c_par_max_count    = 64;                                   // == $40

  c_sz_ptr           = SizeOf(Pointer);                      // == 8
  c_arg_count        = 4;                                    // == 4
  c_arg_size         = c_arg_count * c_sz_ptr;               // == 32
  c_loc_count        = c_par_max_count + 4;                  // == 68
  c_params           = c_loc_count - c_arg_count + 1;        // == 65

  c_loc_offs_adress  = c_loc_count * c_sz_ptr + c_arg_size;  // == 576
  c_loc_offs__rax    = c_loc_offs_adress + 1*c_sz_ptr;       // == 584
  c_loc_offs__xmm0   = c_loc_offs_adress + 2*c_sz_ptr;       // == 592
  c_loc_offs_reginfo = c_loc_offs_adress + 4*c_sz_ptr;       // == 608

  //c_reg_packed = ((SizeOf(TRegisters) mod c_sz_ptr) + c_sz_ptr - 1) div c_sz_ptr; // 1 - packed records; 0 - aligned
asm
{$ifdef DELPHI}
  .params c_params // There's actually room for c_loc_count, assembler is saving locals for "Address,_RAX,_XMM0,RegInfo"
{$else} // TODO: FPC: GPF on exception
  push    rbp
  sub     rsp, $210
  mov     rbp, rsp
{$endif}

  mov     [rbp+c_loc_offs_adress], Address   // save: rcx (@Address)
  mov     [rbp+c_loc_offs__rax], _RAX        // save: rdx (@_RDX)
  mov     [rbp+c_loc_offs__xmm0], _XMM0      // save: r8  (@_XMM0)
  mov     [rbp+c_loc_offs_reginfo], RegInfo  // save: r9  (@RegInfo)    dbg: TRegisters(pointer(R9)^),r

  //
  // check Registers.Items (param count limitation)
  //
  mov     rcx, [RegInfo].TRegisters.Items
  test    rcx, rcx
  jz      @@skip_items

  cmp     rcx, c_par_max_count-2
  jbe     @@frame_is_try

  call    InvokeErrorParamCount

@@frame_is_try:
  //
  // copy registers:
  //   source  :  [RegInfo].TRegisters.Stack
  //   dest    :  [rbp + c_arg_count*c_sz_ptr]
  //   count   :  rcx
  //   note    :  All items on stack should be 16 byte aligned. Caller should have handled that, just copy data here.
  //
  mov     r8, [RegInfo].TRegisters.Stack    // source
  lea     rdx, [rbp + c_arg_count*c_sz_ptr] // dest
@copy_loop:
  // copy pointer:
  mov     rax, [r8]
  mov     [rdx], rax
  // next:
  add     r8, c_sz_ptr
  add     rdx, c_sz_ptr
  dec     rcx
  or      rcx, rcx
  jnz     @copy_loop
  // next.
  //
  // copy registers.

@@skip_items:

  // mov *, [r9].*    ;    [r9] == [RegInfo]
  mov     rcx, [RegInfo].TRegisters._RCX
  mov     rdx, [RegInfo].TRegisters._RDX
  mov     r8,  [RegInfo].TRegisters._R8

  movsd   xmm0,[RegInfo].TRegisters._RCX
  movsd   xmm1,[RegInfo].TRegisters._RDX
  movsd   xmm2,[RegInfo].TRegisters._R8
  movsd   xmm3,[RegInfo].TRegisters._R9

  mov     r9,  [RegInfo].TRegisters._R9  // !!! Overwritten RegInfo (r9)

  call    [rbp+c_loc_offs_adress]

  // make result
  mov     rdx, [rbp+c_loc_offs__rax] // restore: rdx (@_RDX)
  mov     [rdx], RAX            // fill: _RAX

  //movsd   [rdx+c_sz_ptr], XMM0  // fill: _XMM0
  mov     rdx, [rbp+c_loc_offs__xmm0] // restore: r8 (@_RMM0)
  mov     [rdx], RAX            // fill: _RAX

{$ifdef DELPHI}
{$else}
  lea     rsp, [rbp+$210]
  pop     rbp

  ret
{$endif}
end;

{$ELSE !IFDEF REG_STACK_PTR_OFFSET0} // ! asm-win-x64 version for delphi and/or fpc !

  {$undef _demo_x64call_gpf_}
  {.$IFDEF DEBUG}
    {.$define _demo_x64call_gpf_} { optional }
  {.$ENDIF}

{$ifdef _demo_x64call_gpf_}
procedure demo_x64call_gpf();
begin
  raise Exception.Create('Demo x64 GPF!');
end;
{$endif}

procedure x64call( // TODO: ! GPF on exception !
  Address: Pointer;
  out _RAX: IPointer;
  var _XMM0: Double;
  var Registers: TRegisters); assembler; {$IFDEF FPC}nostackframe;{$ENDIF}
asm
(* Registers:
    RCX: Address
    RDX: *_RAX
    R8:  * _XMM0
    R9: _REGISTERS
    fpc inserts an 20h empty space
*)
//{$IFDEF FPC}
  push rbp
  mov rbp,rsp
//{$ENDIF}
  push rcx  // address         ;rbp -8
  push rdx  // @_rax           ;rbp -16
  push r8   // @_xmm0          ;rbp -24
  push r9   // _registers      ;rbp -32

  mov rax, [rbp-32] //registers

  mov rcx, [rax+64] // items/count
  mov rdx, [rax+56] // stack
  jmp @compareitems
@work:
{$IFDEF FPC}
  push qword ptr [rdx]
{$ELSE}
  push [rdx]
{$ENDIF}
  dec rcx
  sub rdx,8
@compareitems:
  or rcx, rcx
  jnz @work

  // copy registers
  mov rcx, [rax+72] // single bits

  bt rcx, 1
  jnc @g1
  cvtsd2ss xmm1, [rax+32]
  jmp @g1e
  @g1:
  movsd xmm1, [rax+32]
  @g1e:

  bt rcx, 2
  jnc @g2
  cvtsd2ss xmm2, [rax+40]
  jmp @g2e
  @g2:
  movsd xmm2, [rax+40]
  @g2e:

  bt rcx, 3
  jnc @g3
  cvtsd2ss xmm3, [rax+48]
  jmp @g3e
  @g3:
  movsd xmm3, [rax+48]
  @g3e:

  // rbp-16: address of xmm0

  bt rcx, 0
  jnc @g0
  mov rdx, [rbp -24]
  cvtsd2ss xmm0, [rdx]
  jmp @g0e
  @g0:
  mov rdx, [rbp -24]
  movsd xmm0, [rdx]
  @g0e:

  // other registers
  mov rcx, [rax]
  mov rdx, [rax+8]
  mov r8, [rax+16]
  mov r9, [rax+24]

  mov RAX, [rbp-8]

  // weird thing on windows, it needs 32 bytes in the CALLEE side to do whatever in
  sub RSP, 32

{$ifdef _demo_x64call_gpf_}
  // Demonstration GPF:
  call demo_x64call_gpf
{$endif}

  call RAX

  add RSP, 32 // undo the damage done earlier

  // copy result back
  mov RDX, [rbp-16]
  mov [RDX], RAX

  mov rax, [rbp-32] //registers

  bt [rax+72], 8                 // if atype.basetype  <> btSingle
  jnc @g5                        //
  cvtss2sd xmm1,xmm0             // convert single to double  into xmm1
  mov rdx,[rbp-24]               // @_xmm0  ;rbp -24
  movsd qword ptr [rdx], xmm1    // save  xmm1 to param _xmm0
  jmp @g5e                       // exit if atype.basetype  = btSingle

  @g5:                           //else "if atype.basetype  = btSingle"
    mov rdx,[rbp-24]             // @_xmm0  ;rbp -24
    movsd qword ptr [rdx], xmm0  // save  xmm1 to param _xmm0

  @g5e:

  leave
  ret
end;
{$ENDIF !IFDEF REG_STACK_PTR_OFFSET0}

{$ELSE !WINDOWS} // ! Not windows version !
type
  //{$IFDEF UNICODE_OR_FPC}{$ALIGN 16}{$ENDIF} // For packed record mode
  //{$ifdef FPC}
  //{$PACKRECORDS 16}
  //{$endif}
  TRegisters = packed record
    _RDI,               //  0
    _RSI,               //  8
    _RDX,               // 16
    _RCX,               // 24
    _R8,                // 32
    _R9: IPointer;      // 40
    _XMM1,              // 48
    _XMM2,              // 56
    _XMM3,              // 64
    _XMM4,              // 72
    _XMM5,              // 80
    _XMM6,              // 88
    _XMM7: Double;      // 96
    SingleBits: Integer; //104
  end;

procedure x64call(  // TODO: Need check GPF on exception !
  Address: Pointer;
  out _RAX: IPointer;
  var Registers: TRegisters;
  aStack: Pointer; aItems: Integer; var _XMM0: Double); assembler; nostackframe;
asm
(* Registers:
    RDI: Address
    RSI: _RAX
    RDX: Registers
    RCX: aStack
    R8:  aItems
    R9:  XMM0

    rbp-8    addr
    rbp-16   _rax
    rbp-24   _xmm0
    rbp-32   regs
*)
  push rbp
  mov rbp,rsp
  push rdi  // address
  push rsi  // _rax
  push r9   // xmm0
  push rdx
{$IFDEF PS_STACKALIGN}
  bt r8, 0
  jnc @skipjump
  sub rsp, 8
@skipjump:
{$ENDIF}
  mov rax, rdx
  jmp @compareitems
@work:
{$IFDEF FPC}
  push qword ptr [rcx]
{$ELSE}
  push [rcx]
{$ENDIF}
  dec r8
  sub rcx,8
@compareitems:
  or r8, r8
  jnz @work

  // copy registers
  // xmm0
  mov rdx,[rbp-24]
  bt [rax+104], 0
  jnc @skipxmm0
  cvtsd2ss xmm0,[rdx]
  jmp @skipxmm0re
  @skipxmm0:
  movq xmm0,[rdx]            // move quadword to xmm0 from _XMM0
  @skipxmm0re:

  // xmm1
  bt [rax+104], 1
  jnc @skipxmm1
  cvtsd2ss xmm1,[rax+48]
  jmp @skipxmm1re
  @skipxmm1:
  movq xmm1,[rax+48]         // move quadword to xmm1 from Registers._XMM1
  @skipxmm1re:

  // xmm2
  bt [rax+104], 2
  jnc @skipxmm2
  cvtsd2ss xmm2,[rax+56]
  jmp @skipxmm2re
  @skipxmm2:
  movq xmm2,[rax+56]         // move quadword to xmm2 from Registers._XMM2
  @skipxmm2re:

  // xmm3
  bt [rax+104], 3
  jnc @skipxmm3
  cvtsd2ss xmm3,[rax+64]
  jmp @skipxmm3re
  @skipxmm3:
  movq xmm3,[rax+64]         // move quadword to xmm3 from Registers._XMM3
  @skipxmm3re:

  // xmm4
  bt [rax+104], 4
  jnc @skipxmm4
  cvtsd2ss xmm4,[rax+72]
  jmp @skipxmm4re
  @skipxmm4:
  movq xmm4,[rax+72]         // move quadword to xmm4 from Registers._XMM4
  @skipxmm4re:

  // xmm5
  bt [rax+104], 5
  jnc @skipxmm5
  cvtsd2ss xmm5,[rax+80]
  jmp @skipxmm5re
  @skipxmm5:
  movq xmm5,[rax+80]         // move quadword to xmm5 from Registers._XMM5
  @skipxmm5re:

  // xmm6
  bt [rax+104], 6
  jnc @skipxmm6
  cvtsd2ss xmm6,[rax+88]
  jmp @skipxmm6re
  @skipxmm6:
  movq xmm6,[rax+88]         // move quadword to xmm6 from Registers._XMM6
  @skipxmm6re:

  // xmm7
  bt [rax+104], 7
  jnc @skipxmm7
  cvtsd2ss xmm7,[rax+96]
  jmp @skipxmm7re
  @skipxmm7:
  movq xmm7,[rax+96]         // move quadword to xmm7 from Registers._XMM7
  @skipxmm7re:

  mov RDI, [rax]
  mov RSI, [rax+ 8]
  mov RDX, [rax+16]
  mov RCX, [rax+24]
  mov R8,  [rax+32]
  mov R9,  [rax+40]

  // weird thing on windows, it needs 32 bytes in the CALLEE side to do whatever in; not sure about linux
  //sub RSP, 32

  mov rax, [rbp-8]
  call RAX

  // add rsp, 8

  // add rsp, 32 // undo the damage done earlier

  // copy result back
  mov rsi, [rbp-16]          // _RAX parameter
  mov [rsi], RAX
  mov rsi, [rbp-24]          // _XMM0 parameter

  // xmm0 res
  mov rax, [rbp-32]          // Registers parameter
  bt [rax+104], 8            // if atype.basetype  <> btSingle
  jnc @skipres               // then goto skipres else begin
  cvtss2sd xmm1,xmm0         // convert single to double  into xmm1
  movq [rsi],xmm1            // move quadword to _XMM0
  jmp @skipresre             // end
  @skipres:
  movq [rsi],xmm0            // move quadword to _XMM0
  @skipresre:

  pop rdx
  pop r9   // xmm0
  pop rsi  // _rax
  pop rdi  // address
  leave
  ret
end;
{$ENDIF !WINDOWS}

{$ENDIF X64CALL_ASM}

function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
var
  Stack: array of Byte;
  _RAX: IPointer;
  _XMM0: Double;
  Registers: TRegisters;
  {$IFNDEF WINDOWS}
  RegUsageFloat: Byte;
  {$ENDIF}
{$IFDEF FPC}
  IsConstructor,IsVirtualCons: Boolean;
{$ENDIF}
  RegUsage: Byte;
  CallData: TPSList;
  I: Integer;
  pp: ^Byte;

  function rp(p: PPSVariantIFC): PPSVariantIFC;
  begin
    if (p = nil) or (p.aType = nil) then begin
      result := nil;
      exit;
    end;
    if p.aType.BaseType = btPointer then begin
      p^.aType := Pointer(Pointer(IPointer(p^.dta) + PointerSize)^);
      p^.Dta := Pointer(p^.dta^);
    end;
    Result := p;
  end;

  {$IFDEF WINDOWS}
  procedure StoreReg(data: IPointer);   overload;
  var p: Pointer;
  begin
    case RegUsage of
      0: begin inc(RegUsage); Registers._RCX:=Data; end;
      1: begin inc(RegUsage); Registers._RDX:=Data; end;
      2: begin inc(RegUsage); Registers._R8:=Data; end;
      3: begin inc(RegUsage); Registers._R9:=Data; end;
    else begin
      SetLength(Stack, Length(Stack)+8);
      p := @Stack[Length(Stack)-8];
      IPointer(p^) := data;
    end;
    end;
  end;
  {$ELSE !WINDOWS}
  procedure StoreReg(data: IPointer);   overload;
  var p: Pointer;
  begin
    case RegUsage of
      0: begin inc(RegUsage); Registers._RDI:=Data; end;
      1: begin inc(RegUsage); Registers._RSI:=Data; end;
      2: begin inc(RegUsage); Registers._RDX:=Data; end;
      3: begin inc(RegUsage); Registers._RCX:=Data; end;
      4: begin inc(RegUsage); Registers._R8:=Data; end;
      5: begin inc(RegUsage); Registers._R9:=Data; end;
      else begin
        SetLength(Stack, Length(Stack)+8);
        p := @Stack[Length(Stack)-8];
        IPointer(p^) := data;
      end;
    end;
  end;
  {$ENDIF !WINDOWS}

  procedure StoreStack(const aData; Len: Integer);
  var
    p: Pointer;
  begin
    if Len > 8 then
      if Length(Stack) mod 16 <> 0 then begin
        SetLength(Stack, Length(Stack)+ (16-(Length(Stack) mod 16)));
      end;
    SetLength(Stack, Length(Stack)+Len);
    p := @Stack[Length(Stack)-Len];
    Move(aData, p^, Len);
  end;

  {$IFDEF WINDOWS}
  procedure StoreReg(data: Double); overload;
  var p: Pointer;
  begin
    case RegUsage of
      0: begin inc(RegUsage); _XMM0:=Data; end;
      1: begin inc(RegUsage); Registers._XMM1:=Data; end;
      2: begin inc(RegUsage); Registers._XMM2:=Data; end;
      3: begin inc(RegUsage); Registers._XMM3:=Data; end;
      else begin
        SetLength(Stack, Length(Stack)+8);
        p := @Stack[Length(Stack)-8];
        Double(p^) := data;
      end;
    end;
  end;
  procedure StoreReg(data: Single); overload;
  var p: Pointer;
  begin
    case RegUsage of
      0: begin inc(RegUsage); Registers.SingleBits := Registers.SingleBits or 1;_XMM0:=Data; end;
      1: begin inc(RegUsage); Registers.SingleBits := Registers.SingleBits or 2; Registers._XMM1:=Data; end;
      2: begin inc(RegUsage); Registers.SingleBits := Registers.SingleBits or 4;Registers._XMM2:=Data; end;
      3: begin inc(RegUsage); Registers.SingleBits := Registers.SingleBits or 8; Registers._XMM3:=Data; end;
      else begin
        SetLength(Stack, Length(Stack)+8);
        p := @Stack[Length(Stack)-8];
        Double(p^) := data;
      end;
    end;
  end;
  {$ELSE !WINDOWS}
  procedure StoreReg(data: Double); overload;
  var p: Pointer;
  begin
    case RegUsageFloat of
      0: begin inc(RegUsageFloat); _XMM0:=Data; end;
      1: begin inc(RegUsageFloat); Registers._XMM1:=Data; end;
      2: begin inc(RegUsageFloat); Registers._XMM2:=Data; end;
      3: begin inc(RegUsageFloat); Registers._XMM3:=Data; end;
      4: begin inc(RegUsageFloat); Registers._XMM4:=Data; end;
      5: begin inc(RegUsageFloat); Registers._XMM5:=Data; end;
      6: begin inc(RegUsageFloat); Registers._XMM6:=Data; end;
      7: begin inc(RegUsageFloat); Registers._XMM7:=Data; end;
      else begin
        SetLength(Stack, Length(Stack)+8);
        p := @Stack[Length(Stack)-8];
        Double(p^) := data;
      end;
    end;
  end;
  procedure StoreReg(data: Single); overload;
  var p: Pointer;
  begin
    case RegUsageFloat of
      0: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 1; _XMM0:=Data; end;
      1: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 2; Registers._XMM1:=Data; end;
      2: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 4; Registers._XMM2:=Data; end;
      3: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 8; Registers._XMM3:=Data; end;
      4: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 16; Registers._XMM4:=Data; end;
      5: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 32; Registers._XMM5:=Data; end;
      6: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 64; Registers._XMM6:=Data; end;
      7: begin inc(RegUsageFloat); Registers.SingleBits := Registers.SingleBits or 128; Registers._XMM7:=Data; end;
      else begin
        SetLength(Stack, Length(Stack)+8);
        p := @Stack[Length(Stack)-8];
        Double(p^) := data;
      end;
    end;
  end;
  {$ENDIF !WINDOWS}

  type
    TMethodCallData = record
      AType: Byte;
      Data: TMethod;
    end;
    PMethodCallData=^TMethodCallData;
  function GetPtr(fVar: PPSVariantIFC): Boolean;
  var
    varPtr: Pointer;
    p: Pointer;
  begin
    Result := False;
    if fVar = nil then exit;
    if fVar.VarParam then
    begin
      case fVar.aType.BaseType of
        btArray: begin
            if Copy(fVar.aType.ExportName, 1, 10) = '!OPENARRAY' then begin
              p := CreateOpenArray(True, Self, fVar);
              if p = nil then exit;
              if CallData = nil then
                CallData := TPSList.Create;
              CallData.Add(p);
              StoreReg(IPointer(POpenArray(p)^.Data));
              StoreReg(IPointer(POpenArray(p)^.ItemCount -1));
              Result := True;
              Exit;
            end else begin
              varptr := fVar.Dta;
              //Exit;
            end;
          end;
        btVariant,
        btSet,
        btStaticArray,
        btRecord,
        btInterface,
        btClass,
        {$IFNDEF PS_NOWIDESTRING} btUnicodeString, btWideString, btWideChar,{$ENDIF} btU8, btS8, btU16,
        btS16, btU32, btS32, btSingle, btDouble, btExtended, btString, btPChar, btChar, btCurrency
        {$IFNDEF PS_NOINT64}, bts64{$ENDIF}: begin
            Varptr := fVar.Dta;
          end;
        else begin
          Exit; // invalid type
        end;
      end; {case}
      StoreReg(IPointer(VarPtr));
    end else begin { #else : (not fVar.VarParam) }
      case fVar.aType.BaseType of
        btSet: begin
            case TPSTypeRec_Set(fVar.aType).aByteSize of
              1: StoreReg(IPointer(byte(fVar.dta^)));
              2: StoreReg(IPointer(word(fVar.dta^)));
              3, 4: StoreReg(IPointer(cardinal(fVar.dta^)));
              5,6,7,8: StoreReg(IPointer(fVar.Dta^));
              else
                StoreReg(IPointer(fVar.Dta));
            end;
          end;
        btArray: begin
            if Copy(fVar.aType.ExportName, 1, 10) = '!OPENARRAY' then begin
              p := CreateOpenArray(False, Self, fVar);
              if p =nil then exit;
              if CallData = nil then
                CallData := TPSList.Create;
              CallData.Add(p);
              StoreReg(IPointer(POpenArray(p)^.Data));
              StoreReg(IPointer(POpenArray(p)^.ItemCount -1));
              Result := True;
              exit;
            end else begin
              StoreReg(IPointer(fVar.Dta{$IFNDEF FPC}^{$ENDIF}));
            end;
          end;
        btRecord: begin
            if fVar.aType.RealSize <= sizeof(IPointer) then
              StoreReg(IPointer(fVar.dta^))
            else
              StoreReg(IPointer(fVar.Dta));
          end;
        btVariant, btStaticArray: begin
            StoreReg(IPointer(fVar.Dta));
          end;
        btExtended, btDouble: {8 bytes} begin
            StoreReg(double(fVar.dta^));
          end;
        btCurrency: {8 bytes} begin
            StoreReg(IPointer(fVar.dta^));
          end;
        btSingle: {4 bytes} begin
            StoreReg(single(fVar.dta^));
          end;

        btChar, btU8, btS8: begin
            StoreReg(IPointer(byte(fVar.dta^)));
          end;
        btWideChar,
        btU16, btS16: begin
            StoreReg(IPointer(word(fVar.dta^)));
          end;
        btU32, btS32: begin
            StoreReg(IPointer(cardinal(fVar.dta^)));
          end;
        btPChar: begin
            if Pointer(fVar.dta^) = nil then
              StoreReg(IPointer(@EmptyPChar))
            else
              StoreReg(IPointer(fVar.dta^));
          end;
        btClass, btInterface, btString: begin
            StoreReg(IPointer(fVar.dta^));
          end;
        btWideString: begin
            StoreReg(IPointer(fVar.dta^));
          end;
        btUnicodeString: begin
            StoreReg(IPointer(fVar.dta^));
          end;
        btProcPtr: begin
            p := New(PMethodCallData);
            TMethodCallData(p^).AType:=255;
            if CallData = nil then
              CallData := TPSList.Create;
            CallData.Add(p);
            TMethodCallData(p^).Data := MKMethod(Self, Longint(fVar.Dta^)); // It requires the implementation of "Handled"
            StoreReg(IPointer(@TMethodCallData(p^).Data));
          end;
        btS64: begin
            StoreReg(IPointer(int64(fVar.dta^)));
          end;
      end; {case}
    end;  { #if else : (not fVar.VarParam) }
    Result := True;
  end; // function GetPtr

begin // function TPSExec.InnerfuseCall
  {$IFDEF FPC}
  if (Integer(CallingConv) and 128) <> 0 then begin
    IsVirtualCons := true;
    CAllingConv := TPSCallingConvention(Integer(CallingConv) and not 128);
  end else
    IsVirtualCons:= false;
  if (Integer(CallingConv) and 64) <> 0 then begin
    IsConstructor := true;
    CAllingConv := TPSCallingConvention(Integer(CallingConv) and not 64);
  end else
    IsConstructor := false;
  {$ENDIF}
  InnerfuseCall := False;
  if Address = nil then
    exit; // need address
  SetLength(Stack, 0);
  CallData := nil;
  res := rp(res);
  if res <> nil then
    res.VarParam := true;
  try
{$IFNDEF WINDOWS}
    (*_RSI := 0;
    _RDI := 0;
    _XMM4 := 0;
    _XMM5 := 0;
    _XMM6 := 0;
    _XMM7 := 0;*)
    RegUsageFloat := 0;
{$ENDIF}
   _XMM0 := 0;
    FillChar(Registers, Sizeof(Registers), 0);
    _RAX := 0;
    RegUsage := 0;
    {$warnings off}
    {$IF DEFINED (fpc) and (fpc_version >= 3)} // FIX FOR FPC constructor calls
    {$warnings on}
    if IsConstructor then begin
      if not GetPtr(rp(Params[0])) then exit; // this goes first
      DisposePPSVariantIFC(Params[0]);
      Params.Delete(0);
    end;
    {$ENDIF}
    if assigned(_Self) then begin
      StoreReg(IPointer(_Self));
    end;
    if assigned(res) and (res^.atype.basetype = btSingle) then begin
      Registers.Singlebits  := Registers.Singlebits or 256;
    end;
    {$IFDEF PS_RESBEFOREPARAMETERS}
    if assigned(res) then begin
      case res^.aType.BaseType of
        {$IFDEF x64_string_result_as_varparameter}
        {$IFNDEF PS_NOWIDESTRING}
        btWideString, btUnicodeString,
        {$ENDIF}
        {.$IFNDEF PS_FPCSTRINGWORKAROUND}
        btString,
        {.$ENDIF}
        {$ENDIF x64_string_result_as_varparameter}
        btInterface, btArray, btVariant, btStaticArray:
          GetPtr(res);
        btRecord,
        btSet:
          begin
            if res.aType.RealSize > PointerSize then
              GetPtr(res);
          end;
      end;
    end;
    {$ENDIF PS_RESBEFOREPARAMETERS}
    for I := 0 to Params.Count - 1 do begin
      if not GetPtr(rp(Params[I])) then
        Exit;
    end;
    if assigned(res) then begin
      {$IFNDEF PS_RESBEFOREPARAMETERS}
      case res^.aType.BaseType of
        {$IFDEF x64_string_result_as_varparameter}
        btstring, btWideString, btUnicodeString,
        {$ENDIF}
        btInterface, btArray, btVariant, btStaticArray:
          GetPtr(res);
        btRecord,
        btSet:
          begin
            if res.aType.RealSize > PointerSize then
              GetPtr(res);
          end;
      end;
      {$ENDIF !PS_RESBEFOREPARAMETERS}
      {$IFDEF WINDOWS}
      if (length(Stack) mod 16) <> 0 then begin
        SetLength(Stack, Length(Stack)+16 - (Length(Stack) mod 16));
      end;
      {$ENDIF}
      if Stack = nil
      then pp := nil
      else pp := @Stack[{$IFDEF REG_STACK_PTR_OFFSET0}0{$ELSE}Length(Stack)-8{$ENDIF}];

      {$IFDEF WINDOWS}
      Registers.Stack := pp;
      Registers.Items := Length(Stack) div 8;
      x64call(Address, _RAX, _XMM0, Registers);
      {$ELSE}
      x64call(Address, _RAX, Registers, pp, Length(Stack) div 8, _XMM0);
      {$ENDIF !WINDOWS}

      case res^.aType.BaseType of
        btRecord, btSet:
          begin
            case res.aType.RealSize of
              1: byte(res.Dta^) := _RAX;
              2: word(res.Dta^) := _RAX;
              3,
              4: Longint(res.Dta^) := _RAX;
              5,6,7,8: IPointer(res.dta^) := _RAX;
            end;
          end;
        btSingle:
          tbtsingle(res.Dta^) := _XMM0;
        btDouble:
          tbtdouble(res.Dta^) := _XMM0;
        btExtended:
          tbtextended(res.Dta^) := _XMM0;
        btChar, btU8, btS8:
          tbtu8(res.dta^) := _RAX;

        {$IFNDEF PS_NOWIDESTRING}
        btWideChar,
        {$ENDIF}
        btu16, bts16:  tbtu16(res.dta^) := _RAX;

        btClass :
          IPointer(res.dta^) := _RAX;
        btu32, bts32:
          tbtu32(res.dta^) := _RAX;
        btPChar:
          pansichar(res.dta^) := Pansichar(_RAX);
        bts64:
          tbts64(res.dta^) := Int64(_RAX);
        btCurrency:
          tbtCurrency(res.Dta^) := Int64(_RAX);

        btInterface,
        btVariant,
        {$IFDEF x64_string_result_as_varparameter}
        btWidestring, btUnicodestring, btString,
        {$ENDIF}
        btStaticArray, btArray:;

        {$IFNDEF x64_string_result_as_varparameter}
        btUnicodeString, btWideString, btstring:
          Int64(res.dta^) := _RAX;
        {$ENDIF}
      else
        exit;
      end; // case
    end else begin // when res==nil
      {$IFDEF WINDOWS}
      if (length(Stack) mod 16) <> 0 then begin
        SetLength(Stack, Length(Stack)+16 - (Length(Stack) mod 16));
      end;
      {$ENDIF}
      if Stack = nil
      then pp := nil
      else pp := @Stack[{$IFDEF REG_STACK_PTR_OFFSET0}0{$ELSE}Length(Stack)-8{$ENDIF}];

      {$IFDEF WINDOWS}
      Registers.Stack := pp;
      Registers.Items := Length(Stack) div 8;
      x64call(Address, _RAX, _XMM0, Registers);
      {$ELSE}
      x64call(Address, _RAX, Registers, pp, Length(Stack) div 8, _XMM0);
      {$ENDIF !WINDOWS}
    end; // if else
    Result := True;
  finally
    if Assigned(CallData) then begin
      for i := CallData.Count-1 downto 0 do
      begin
        pp := CallData[i];
        case pp^ of
          0: begin
            DestroyOpenArray(Self, Pointer(pp));
          end;
          255: begin
            Dispose(PMethodCallData(pp)); // release TMethodCallData
          end;
        end;
      end;
      CallData.Free;
    end;
  end;
end;
