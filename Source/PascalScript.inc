{----------------------------------------------------------------------------}
{ RemObjects Pascal Script                                                   }
{                                                                            }
{ compiler: Delphi 2 and up, Kylix 3 and up                                  }
{ platform: Win32, Linux                                                     }
{                                                                            }
{ (c)opyright RemObjects Software. all rights reserved.                      }
{                                                                            }
{----------------------------------------------------------------------------}


{$INCLUDE eDefines.inc}

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

{$IFDEF VER125}{C4}{$B-}{$X+}{$T-}{$H+}{$ENDIF}
{$IFDEF VER110}{C3}{$B-}{$X+}{$T-}{$H+}{$ENDIF}
{$IFDEF VER93}{C1}{$B-}{$X+}{$T-}{$H+}{$ENDIF}

{$IFDEF DELPHI4UP}
  {$DEFINE PS_HAVEVARIANT}
  {$DEFINE PS_DYNARRAY}
{$ENDIF}

{$IFNDEF FPC}
  {$B-}{$X+}{$T-}{$H+}
{$ELSE}
  {$R-}{$Q-}
{$ENDIF}

{$IFNDEF FPC}
{$IFNDEF DELPHI4UP}
{$IFNDEF LINUX}
  {$DEFINE PS_NOINT64}
{$ENDIF}
{$ENDIF}

{$IFDEF DELPHI2}
  {$DEFINE PS_NOINT64}
  {$DEFINE PS_NOWIDESTRING}
  {$B-}{$X+}{$T-}{$H+}
{$ENDIF}

{$IFDEF LINUX}{KYLIX}{$DEFINE CLX}{$DEFINE DELPHI3UP}{$DEFINE DELPHI6UP}{$ENDIF}
{$ENDIF}
{$R-}{$Q-}


{
Defines:
  IFPS3_NOSMARTLIST    - Don't use the smart list option
}

{$UNDEF DEBUG}

{$IFDEF CLX}
{$DEFINE PS_NOIDISPATCH} // not implemented
{$ENDIF}

{$IFDEF FPC}
  {$DEFINE PS_HAVEVARIANT}
  {$DEFINE PS_DYNARRAY}
  {$DEFINE PS_NOIDISPATCH}
  {$if defined(fpc_version) and defined(fpc_patch) and defined(fpc_release) and (fpc_version=2) and (fpc_release>=3) and (fpc_patch>=1)}
    {$UNDEF FPC_OLD_FIX}
    {$UNDEF PS_FPCSTRINGWORKAROUND}
  {FreePascal 2.3.1 and above has much Delphi compatibility bugs fixed}
  {$else}
    {$DEFINE FPC_OLD_FIX}
    {$DEFINE PS_FPCSTRINGWORKAROUND}
  {$ifend}
  {$DEFINE DELPHI3UP}
  {$DEFINE DELPHI6UP}
{$ENDIF}
