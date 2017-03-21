@echo off

rem Common options

  set UsePack=0
  set EurekaLog=0
  set DEBUG=0
  set MAPFILE=0
  set JDBG=0
  set CleanDcc32Log=1
  set DEBUG_BATCH=0
  set TRACE_STACK_SOURCE=0

  set UserLib=.

  rem . RemObjects Pascal Components path:
  set rps_lib=..\..
  rem .
  set UserLib=%UserLib%;%rps_lib%\Source;%rps_lib%\Source\ThirdParty

:L_LIB_DONE
  set UserLibI=%UserLib%
  set UserLibR=%UserLib%

  @rem dcc analyze result options:
  @rem @set IGNOREERRORLEVEL=1

  @rem MakeJclDbg
  @rem   J - Create .JDBG files
  @rem   E - Insert debug data into executable files
  @rem   M - Delete MAP file after conversion
  @if "%plfm%"=="w32" set MakeJclDbgO=-E

  @rem path to MakeJclDbg.exe
  @set MakeJclDbgP=%cd%\thirdparty\jcl\

:L_DCU
  if "%plfm%"=="" set plfm=w32

:L_EXE
  @rem @if "%plfm%"=="w64" set UserCOpt=%UserCOpt% -E.\..\bin\x64
  @rem @if "%plfm%"=="w32" @set UserCOpt=%UserCOpt% -E.\..\bin

:L_DCU_A
@goto L_DCU_L
  @rem "A:" - it is RAMDisk (ImDisk: http://www.ltr-data.se/opencode.html/#ImDisk)
  @if not exist "A:\" goto L_DCU_L
  @if not exist "A:\$dx\%plfm%__dcu\" md "A:\$dx\%plfm%__dcu"
  @if not exist "A:\$dx\%plfm%__dcu\" goto L_DCU_L
  @set UserCOpt=%UserCOpt% -N0A:\$dx\%plfm%__dcu
  @goto :eof

:L_DCU_L
  @if not exist ".\_dcu\" md ".\_dcu"
  @if not exist ".\_dcu\" goto :eof
  @set UserCOpt=%UserCOpt% -N0.\_dcu
  @goto :eof
