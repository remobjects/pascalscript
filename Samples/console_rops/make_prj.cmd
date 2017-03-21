@rem NB: FOR WINDOWS NT ONLY
@rem @setlocal ENABLEEXTENSIONS

@set xErrorTimeout=1

@set xLang=
@for /F "tokens=1,2,3,4*" %%i in ('chcp') do @if "%%l"=="866" set xLang=ru
@if "%xLang%"=="" for /F "tokens=1,2,3,4*" %%i in ('chcp') do @if "%%l"=="1251" set xLang=ru
@if "%xLang%"=="" set xLang=en

@set make_prj_ver=2017.0306.1527

@rem #
@rem # make_prj Version 2017.0306.1527
@rem # ================================
@rem # Description(EN):
@rem # ================================
@rem # Compilation: Delphi/C++Builder" projects/modules/packages for other platforms (win32,win64,android,osx,iox).
@rem # For show help run without parameters.
@rem #
@rem # Description(RU):
@rem # Описание
@rem # ================================
@rem # Компиляция: Delphi/C++Builder/Kylix" pas модулей/проектов для различных платформ (win32,win64,android,osx,iox).
@rem # Запустите без параметров для справки.
@rem #

@if "%IGNOREERRORLEVEL%"=="" @(
  @set IGNOREERRORLEVEL=0
) else @(
  @set IGNOREERRORLEVEL=1
)

@rem params parsing:

@if "%1"=="" goto L_HELP

@if "%1" == "/C"  goto L_CLEAN
@if "%1" == "/c"  goto L_CLEAN
@if "%1" == "/CA" goto L_CLEAN
@if "%1" == "/ca" goto L_CLEAN
@goto L_CLEAR_SKIP

:L_CLEAN
@del dcc*.log >nul 2>nul
@del /Q *.tds *.lsp *.ejf *.drc *.vsr *.~* >nul 2>nul
@del *.bpi >nul 2>nul
@del /Q *.map *.jdbg *.pdb *.rsm >nul 2>nul
@del /Q *.dcp *.dcpil *.dcu *.dpu *.dcuil *.lib *.bpi *.obj *.o *.a  >nul 2>nul
@rem @del /Q *.bpl *.dpl >nul 2>nul
@rem @del /Q *.dylib *.dll >nul 2>nul
@if "%1" NEQ "/CA" goto L_CLEAN_DONE
@if "%1" NEQ "/ca" goto L_CLEAN_DONE
@del /Q *.cfg *.dof *.dsk >nul 2>nul
:L_CLEAN_DONE
@goto L_EXIT

:L_CLEAR_SKIP
@set DVER=%1
@rem if exist "%1"
@if "%2" NEQ "" set project=%2
@if "%project%"=="" goto L_ERROR_PARAM
@set DBASE=%DVER%

@if not exist "%project%" @(
  @echo\ERROR: Not found project file "%project%"
  @set E=2
  @set errorlevel=%E%
  @echo press any key to exit>con
  @pause >nul
  @goto L_EXIT
)

@rem Calculate Project specified options file name (Extract File Name ...):

@set project_path=
@for /F "delims=" %%i in ("%project%") do @set project_path=%%~di%%~pi
@rem .l log
@rem @echo\path=%project_path%>con

@set project_name=
@for /F "delims=" %%i in ("%project%") do @set project_name=%%~ni
@rem .l log
@rem @echo\name=%project_name%>con

@set project_type=?
@set project_ext=
@if "%project_name%"=="" @if "%project%"=="?" goto L_PEXT

@rem .1 variant 1
@rem @for /F "delims=" %%i in ("%project%") do @set project_ext=%%~xi
@rem @for /F "delims=." %%i in ("%project_ext%") do @set project_ext=%%i
@rem .2 variant 2; limitations: exist $project and os supported shot path/names
@set T=
@for /F "delims=" %%i in ("%project%") do @set T=%%~si
@for /F "delims=" %%i in ("%T%") do @set project_ext=%%~xi
@for /F "delims=." %%i in ("%project_ext%") do @set project_ext=%%i
@rem .l
@rem @echo\ext=%project_ext%>con
@rem .e error
@if "%project_ext%"=="" (
  @echo\ERROR: Unsupported project file name "%project%"
  @set E=3
  @set errorlevel=%E%
  @echo press any key to exit>con
  @pause >nul
  @goto L_EXIT
)
@rem .l
@rem @echo\ext=%project_ext%>con
@rem .c check
  @rem .......................... lower
@if %project_ext%==pas @(
  set project_ext=pas
  set project_type=u_pas
) else @if %project_ext%==pp @(
  set project_ext=pp
  set project_type=u_pas
) else @if %project_ext%==dpr @(
  set project_ext=dpr
  set project_type=p_dpr
@rem ) else @if %project_ext%==dpk @(
@rem   set project_ext=dpk
@rem   set project_type=p_dpk
@rem ) else @if %project_ext%==lpr @(
@rem   set project_ext=lpr
@rem   set project_type=p_lpr
) else @if %project_ext%==rps @(
  set project_ext=rps
  set project_type=p_pas
  @rem .......................... upper
) else @if %project_ext%==PAS @(
  set project_ext=pas
  set project_type=u_pas
) else @if %project_ext%==PP @(
  set project_ext=pp
  set project_type=u_pas
) else @if %project_ext%==DPR @(
  set project_ext=dpr
  set project_type=p_dpr
) else @if %project_ext%==DPK @(
  set project_ext=dpk
  set project_type=p_dpk
@rem ) else @if %project_ext%==LPR @(
@rem   set project_ext=lpr
@rem   set project_type=p_lpr
@rem ) else @if %project_ext%==LPK @(
@rem   set project_ext=lpk
@rem   set project_type=p_lpk
) else @if %project_ext%==RPS @(
  set project_ext=rps
  set project_type=p_pas
  @rem ..........................
) else @(
  @echo\ERROR: Unsupported file type "%project_ext%"
  @set E=4
  @set errorlevel=%E%
  @echo press any key to exit>con
  @pause >nul
  @goto L_EXIT
)
@rem .l
@rem @echo\ext=%project_ext%>con
@rem @echo\type=%project_type%>con
:L_PEXT

@rem Clear user Envinronments
@set dccilOpt=
@set bccilOpt=

@set UserLib=.
@set UserLibI=.
@set UserLibO=.
@set UserLibR=.
@set UserPack=
@set UserCOpt=
@set DEBUG_BATCH=0
@set CleanDcc32Log=1
@set UsePack=0
@set DEBUG=0
@set MAPFILE=1
@set TRACE_STACK_SOURCE=1
@set JDBG=0
@set Fmx=0

@rem set platform variables:

@set COMMAND=
@set DELPHI_ROOTDIR=
@set KEY=HKCU
@set Platform=
@set DelphiName=
@set ide_name=
@set REGPATH=
@set DXVER=?
@set PLIB=
@set PREL=
@set xlinker=
@set ndklibpath=
@set XOS=win
@set plfm=w32
@set slib=\win32

@set pd=\
@set vd=;

@if "%DVER%"=="30w32"  set DVER=30
@if "%DVER%"=="D30"    set DVER=30

@if "%DVER%"=="29w32"  set DVER=29
@if "%DVER%"=="D29"    set DVER=29

@if "%DVER%"=="28w32"  set DVER=28
@if "%DVER%"=="D28"    set DVER=28

@if "%DVER%"=="27w32"  set DVER=27
@if "%DVER%"=="D27"    set DVER=27

@if "%DVER%"=="26w32"  set DVER=26
@if "%DVER%"=="D26"    set DVER=26

@if "%DVER%"=="25w32"  set DVER=25
@if "%DVER%"=="D25"    set DVER=25

@if "%DVER%"=="24w32"  set DVER=24
@if "%DVER%"=="D24"    set DVER=24

@if "%DVER%"=="23w32"  set DVER=23
@if "%DVER%"=="D23"    set DVER=23

@if "%DVER%"=="22w32"  set DVER=22
@if "%DVER%"=="D22"    set DVER=22

@if "%DVER%"=="21w32"  set DVER=21
@if "%DVER%"=="D21"    set DVER=21

@if "%DVER%"=="20w32"  set DVER=20
@if "%DVER%"=="D20"    set DVER=20

@if "%DVER%"=="19w32"  set DVER=19
@if "%DVER%"=="D19"    set DVER=19

@if "%DVER%"=="18w32"  set DVER=18
@if "%DVER%"=="D18"    set DVER=18

@if "%DVER%"=="17w32"  set DVER=17
@if "%DVER%"=="D17"    set DVER=17

@if "%DVER%"=="16w32"  set DVER=16
@if "%DVER%"=="D16"    set DVER=16

@if "%DVER%"=="D15"    set DVER=15
@if "%DVER%"=="D14"    set DVER=14
@if "%DVER%"=="D12"    set DVER=12
@if "%DVER%"=="D11"    set DVER=11
@if "%DVER%"=="D10"    set DVER=10
@if "%DVER%"=="D9"     set DVER=9
@if "%DVER%"=="D8"     set DVER=8
@if "%DVER%"=="D7"     set DVER=7
@if "%DVER%"=="K3"     set DVER=k3
@if "%DVER%"=="D6"     set DVER=6
@if "%DVER%"=="D5"     set DVER=5
@if "%DVER%"=="D4"     set DVER=4
@if "%DVER%"=="D3"     set DVER=3
@if "%DVER%"==""       set DVER=0

@if "%DVER%"=="30arm"  set DVER=30arm32
@if "%DVER%"=="29arm"  set DVER=29arm32
@if "%DVER%"=="28arm"  set DVER=28arm32
@if "%DVER%"=="27arm"  set DVER=27arm32
@if "%DVER%"=="26arm"  set DVER=26arm32
@if "%DVER%"=="25arm"  set DVER=25arm32
@if "%DVER%"=="24arm"  set DVER=24arm32
@if "%DVER%"=="23arm"  set DVER=23arm32
@if "%DVER%"=="22arm"  set DVER=22arm32
@if "%DVER%"=="21arm"  set DVER=21arm32
@if "%DVER%"=="20arm"  set DVER=20arm32
@if "%DVER%"=="19arm"  set DVER=19arm32
@if "%DVER%"=="18arm"  set DVER=18arm32

@if "%DVER%"=="30osx"  set DVER=30osx32
@if "%DVER%"=="29osx"  set DVER=29osx32
@if "%DVER%"=="28osx"  set DVER=28osx32
@if "%DVER%"=="27osx"  set DVER=27osx32
@if "%DVER%"=="26osx"  set DVER=26osx32
@if "%DVER%"=="25osx"  set DVER=25osx32
@if "%DVER%"=="24osx"  set DVER=24osx32
@if "%DVER%"=="23osx"  set DVER=23osx32
@if "%DVER%"=="22osx"  set DVER=22osx32
@if "%DVER%"=="21osx"  set DVER=21osx32
@if "%DVER%"=="20osx"  set DVER=20osx32
@if "%DVER%"=="19osx"  set DVER=19osx32
@if "%DVER%"=="18osx"  set DVER=18osx32
@if "%DVER%"=="17osx"  set DVER=17osx32
@if "%DVER%"=="16osx"  set DVER=16osx32

@if "%DVER%"=="15w"    set DVER="15"
@if "%DVER%"=="14w"    set DVER="14"
@if "%DVER%"=="14W"    set DVER="14"
@if "%DVER%"=="12w"    set DVER="12"
@if "%DVER%"=="12W"    set DVER="12"
@if "%DVER%"=="11w"    set DVER="11"
@if "%DVER%"=="11W"    set DVER="11"
@if "%DVER%"=="10w"    set DVER="10"
@if "%DVER%"=="10W"    set DVER="10"
@if "%DVER%"=="9w"     set DVER="9"
@if "%DVER%"=="9W"     set DVER="9"
@if "%DVER%"=="8"      set DVER=BDS
@if "%DVER%"=="bds"    set DVER=BDS

@if "%DVER%"=="11N"    goto L_SET_BDS
@if "%DVER%"=="11n"    goto L_SET_BDS
@if "%DVER%"=="10N"    goto L_SET_BDS
@if "%DVER%"=="10n"    goto L_SET_BDS
@if "%DVER%"=="9N"     goto L_SET_BDS
@if "%DVER%"=="9n"     goto L_SET_BDS
@if "%DVER%"=="D.Net1" goto L_SET_DNET1
@if "%DVER%"=="D.NET1" goto L_SET_DNET1
@if "%DVER%"=="d.net1" goto L_SET_DNET1
@if "%DVER%"=="BDS"    goto L_SET_BDS

@if "%DVER%"=="B3"     goto L_SET_BUILDER
@if "%DVER%"=="b3"     goto L_SET_BUILDER
@if "%DVER%"=="B4"     goto L_SET_BUILDER
@if "%DVER%"=="b4"     goto L_SET_BUILDER
@if "%DVER%"=="B5"     goto L_SET_BUILDER
@if "%DVER%"=="b5"     goto L_SET_BUILDER
@if "%DVER%"=="B6"     goto L_SET_BUILDER
@if "%DVER%"=="b6"     goto L_SET_BUILDER

@if "%DVER%" NEQ "30w64" goto L_30w64_Done
@set DVER=30
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_30w64_Done

@if "%DVER%" NEQ "30aarm32" goto L_30aarm32_Done
@set DVER=30
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_30aarm32_Done

@if "%DVER%" NEQ "30osx32" goto L_30osx32_Done
@set DVER=30
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_30osx32_Done

@if "%DVER%" NEQ "30iosarm32" goto L_30iosarm32_Done
@set DVER=30
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_30iosarm32_Done

@if "%DVER%" NEQ "30iosarm64" goto L_30iosarm64_Done
@set DVER=30
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_30iosarm64_Done

@if "%DVER%" NEQ "30ioss" goto L_30ioss32_Done
@set DVER=30
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_30ioss32_Done

@if "%DVER%" NEQ "29w64" goto L_29w64_Done
@set DVER=29
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_29w64_Done

@if "%DVER%" NEQ "29aarm32" goto L_29aarm32_Done
@set DVER=29
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_29aarm32_Done

@if "%DVER%" NEQ "29osx32" goto L_29osx32_Done
@set DVER=29
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_29osx32_Done

@if "%DVER%" NEQ "29iosarm32" goto L_29iosarm32_Done
@set DVER=29
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_29iosarm32_Done

@if "%DVER%" NEQ "29iosarm64" goto L_29iosarm64_Done
@set DVER=29
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_29iosarm64_Done

@if "%DVER%" NEQ "29ioss" goto L_29ioss32_Done
@set DVER=29
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_29ioss32_Done

@if "%DVER%" NEQ "28w64" goto L_28w64_Done
@set DVER=28
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_28w64_Done

@if "%DVER%" NEQ "28aarm32" goto L_28aarm32_Done
@set DVER=28
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_28aarm32_Done

@if "%DVER%" NEQ "28osx32" goto L_28osx32_Done
@set DVER=28
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_28osx32_Done

@if "%DVER%" NEQ "28iosarm32" goto L_28iosarm32_Done
@set DVER=28
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_28iosarm32_Done

@if "%DVER%" NEQ "28iosarm64" goto L_28iosarm64_Done
@set DVER=28
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_28iosarm64_Done

@if "%DVER%" NEQ "28ioss" goto L_28ioss32_Done
@set DVER=28
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_28ioss32_Done

@if "%DVER%" NEQ "27w64" goto L_27w64_Done
@set DVER=27
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_27w64_Done

@if "%DVER%" NEQ "27aarm32" goto L_27aarm32_Done
@set DVER=27
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_27aarm32_Done

@if "%DVER%" NEQ "27osx32" goto L_27osx32_Done
@set DVER=27
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_27osx32_Done

@if "%DVER%" NEQ "27iosarm32" goto L_27iosarm32_Done
@set DVER=27
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_27iosarm32_Done

@if "%DVER%" NEQ "27iosarm64" goto L_27iosarm64_Done
@set DVER=27
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_27iosarm64_Done

@if "%DVER%" NEQ "27ioss" goto L_27ioss32_Done
@set DVER=27
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_27ioss32_Done

@if "%DVER%" NEQ "26w64" goto L_26w64_Done
@set DVER=26
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_26w64_Done

@if "%DVER%" NEQ "26aarm32" goto L_26aarm32_Done
@set DVER=26
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_26aarm32_Done

@if "%DVER%" NEQ "26osx32" goto L_26osx32_Done
@set DVER=26
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_26osx32_Done

@if "%DVER%" NEQ "26iosarm32" goto L_26iosarm32_Done
@set DVER=26
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_26iosarm32_Done

@if "%DVER%" NEQ "26iosarm64" goto L_26iosarm64_Done
@set DVER=26
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_26iosarm64_Done

@if "%DVER%" NEQ "26ioss" goto L_26ioss32_Done
@set DVER=26
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_26ioss32_Done

@if "%DVER%" NEQ "25w64" goto L_25w64_Done
@set DVER=25
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_25w64_Done

@if "%DVER%" NEQ "25aarm32" goto L_25aarm32_Done
@set DVER=25
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_25aarm32_Done

@if "%DVER%" NEQ "25osx32" goto L_25osx32_Done
@set DVER=25
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_25osx32_Done

@if "%DVER%" NEQ "25iosarm32" goto L_25iosarm32_Done
@set DVER=25
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_25iosarm32_Done

@if "%DVER%" NEQ "25iosarm64" goto L_25iosarm64_Done
@set DVER=25
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_25iosarm64_Done

@if "%DVER%" NEQ "25ioss" goto L_25ioss32_Done
@set DVER=25
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_25ioss32_Done

@if "%DVER%" NEQ "24w64" goto L_24w64_Done
@set DVER=24
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_24w64_Done

@if "%DVER%" NEQ "24aarm32" goto L_24aarm32_Done
@set DVER=24
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_24aarm32_Done

@if "%DVER%" NEQ "24osx32" goto L_24osx32_Done
@set DVER=24
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_24osx32_Done

@if "%DVER%" NEQ "24iosarm32" goto L_24iosarm32_Done
@set DVER=24
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_24iosarm32_Done

@if "%DVER%" NEQ "24iosarm64" goto L_24iosarm64_Done
@set DVER=24
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_24iosarm64_Done

@if "%DVER%" NEQ "24ioss" goto L_24ioss32_Done
@set DVER=24
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_24ioss32_Done

@if "%DVER%" NEQ "23w64" goto L_23w64_Done
@set DVER=23
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_23w64_Done

@if "%DVER%" NEQ "23aarm32" goto L_23aarm32_Done
@set DVER=23
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_23aarm32_Done

@if "%DVER%" NEQ "23osx32" goto L_23osx32_Done
@set DVER=23
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_23osx32_Done

@if "%DVER%" NEQ "23iosarm32" goto L_23iosarm32_Done
@set DVER=23
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice32
@goto L_PLFM
:L_23iosarm32_Done

@if "%DVER%" NEQ "23iosarm64" goto L_23iosarm64_Done
@set DVER=23
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_23iosarm64_Done

@if "%DVER%" NEQ "23ioss" goto L_23ioss32_Done
@set DVER=23
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_23ioss32_Done

@rem XE8 Win64
@if "%DVER%" NEQ "22w64" goto L_22w64_Done
@set DVER=22
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_22w64_Done

@rem XE8 Android arm32
@if "%DVER%" NEQ "22aarm32" goto L_22aarm32_Done
@set DVER=22
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_22aarm32_Done

@rem XE8 OSX
@if "%DVER%" NEQ "22osx32" goto L_22osx32_Done
@set DVER=22
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_22osx32_Done

@if "%DVER%" NEQ "22iosarm32" goto L_22iosarm32_Done
@set DVER=22
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice
@goto L_PLFM
:L_22iosarm32_Done

@if "%DVER%" NEQ "22iosarm64" goto L_22iosarm64_Done
@set DVER=22
@set XOS=ios
@set plfm=iosarm64
@set slib=\iosDevice64
@goto L_PLFM
:L_22iosarm64_Done

@rem XE8 IOS Simulator
@if "%DVER%" NEQ "22ioss" goto L_22ioss32_Done
@set DVER=22
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_22ioss32_Done

@rem XE7 Win64
@if "%DVER%" NEQ "21w64" goto L_21w64_Done
@set DVER=21
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_21w64_Done

@rem XE7 Android arm32
@if "%DVER%" NEQ "21aarm32" goto L_21aarm32_Done
@set DVER=21
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_21aarm32_Done

@rem XE7 OSX
@if "%DVER%" NEQ "21osx32" goto L_21osx32_Done
@set DVER=21
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_21osx32_Done

@if "%DVER%" NEQ "21iosarm32" goto L_21iosarm32_Done
@set DVER=21
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice
@goto L_PLFM
:L_21iosarm32_Done

@if "%DVER%" NEQ "21iosarm64" goto L_21iosarm64_Done
@echo ERROR: platform not suppurted
@goto L_ERROR_SKIPCMD
:L_21iosarm64_Done

@rem XE7 IOS Simulator
@if "%DVER%" NEQ "21ioss" goto L_21ioss32_Done
@set DVER=21
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_21ioss32_Done

@rem XE6 Win64
@if "%DVER%" NEQ "20w64" goto L_20w64_Done
@set DVER=20
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_20w64_Done

@rem XE6 Android arm32
@if "%DVER%" NEQ "20aarm32" goto L_20aarm32_Done
@set DVER=20
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_20aarm32_Done

@rem XE6 OSX
@if "%DVER%" NEQ "20osx32" goto L_20osx32_Done
@set DVER=20
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_20osx32_Done

@if "%DVER%" NEQ "20iosarm32" goto L_20iosarm32_Done
@set DVER=20
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice
@goto L_PLFM
:L_20iosarm32_Done

@if "%DVER%" NEQ "20iosarm64" goto L_20iosarm64_Done
@echo ERROR: platform not suppurted
@goto L_ERROR_SKIPCMD
:L_20iosarm64_Done

@rem XE6 IOS Simulator
@if "%DVER%" NEQ "20ioss" goto L_20ioss32_Done
@set DVER=20
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_20ioss32_Done

@rem XE5 Win64
@if "%DVER%" NEQ "19w64" goto L_19w64_Done
@set DVER=19
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_19w64_Done

@rem XE5 Android arm32
@if "%DVER%" NEQ "19aarm32" goto L_19aarm32_Done
@set DVER=19
@set XOS=android
@set plfm=aarm32
@set slib=\android
@goto L_PLFM
:L_19aarm32_Done

@rem XE5 OSX
@if "%DVER%" NEQ "19osx32" goto L_19osx32_Done
@set DVER=19
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_19osx32_Done

@if "%DVER%" NEQ "19iosarm32" goto L_19iosarm32_Done
@set DVER=19
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice
@goto L_PLFM
:L_19iosarm32_Done

@if "%DVER%" NEQ "19iosarm64" goto L_19iosarm64_Done
@echo ERROR: platform not suppurted
@goto L_ERROR_SKIPCMD
:L_19iosarm64_Done

@rem XE5 IOS Simulator
@if "%DVER%" NEQ "19ioss" goto L_19ioss32_Done
@set DVER=19
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_19ioss32_Done

@rem XE4 Win64
@if "%DVER%" NEQ "18w64" goto L_18w64_Done
@set DVER=18
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_18w64_Done

@rem XE4 Android arm32
@if "%DVER%" NEQ "18aarm32" goto L_18aarm32_Done
@echo ERROR: platform not suppurted
@goto L_ERROR_SKIPCMD
:L_18aarm32_Done

@rem XE4 OSX
@if "%DVER%" NEQ "18osx32" goto L_18osx32_Done
@set DVER=18
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_18osx32_Done

@if "%DVER%" NEQ "18iosarm32" goto L_18iosarm32_Done
@set DVER=18
@set XOS=ios
@set plfm=iosarm32
@set slib=\iosDevice
@goto L_PLFM
:L_18iosarm32_Done

@if "%DVER%" NEQ "18iosarm64" goto L_18iosarm64_Done
@echo ERROR: platform not suppurted
@goto L_ERROR_SKIPCMD
:L_18iosarm64_Done

@rem XE4 IOS Simulator
@if "%DVER%" NEQ "18ioss" goto L_18ioss32_Done
@set DVER=18
@set XOS=ios
@set plfm=ioss32
@set slib=\iossimulator
@goto L_PLFM
:L_18ioss32_Done

@rem XE3 Win64
@if "%DVER%" NEQ "17w64" goto L_17w64_Done
@set DVER=17
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_17w64_Done

@rem XE3 OSX
@if "%DVER%" NEQ "17osx32" goto L_17osx32_Done
@set DVER=17
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@goto L_PLFM
:L_17osx32_Done

@rem XE2 Win64
@if "%DVER%" NEQ "16w64" goto L_16w64_Done
@set DVER=16
@set plfm=w64
@set slib=\win64
@goto L_PLFM
:L_16w64_Done

@rem XE2 OSX
@if "%DVER%" NEQ "16osx32" goto L_16osx32_Done
@set DVER=16
@set XOS=osx
@set plfm=osx32
@set slib=\osx32
@rem @goto L_PLFM
:L_16osx32_Done

:L_PLFM
@rem @echo DBG: %%XOS%%=%XOS%>con
@if "%XOS%" NEQ "win" set Fmx=1

@rem XE
@if %DVER% LEQ 15 set slib=

@if "%DVER%"=="k3" set plfm=linux
@if "%DVER%"=="k3" set slib=\linux

@set DXVER=%DVER%
@if "%DVER%"=="9"  set DXVER=09
@if "%DVER%"=="8"  set DXVER=08
@if "%DVER%"=="7"  set DXVER=07
@if "%DVER%"=="k3" set DXVER=06
@if "%DVER%"=="6"  set DXVER=06
@if "%DVER%"=="5"  set DXVER=05
@if "%DVER%"=="4"  set DXVER=04
@if "%DVER%"=="3"  set DXVER=03

@set Platform=DX
@if "%DVER%"=="k3" set Platform=kylix
@if "%Platform%"=="kylix" set pd=/
@if "%Platform%"=="kylix" set vd=:
@if "%Platform%"=="kylix" set DelphiName=CrossKylix
@if "%Platform%"=="kylix" goto L_PLATFORM_DONE

@set ide_name=RAD Studio
@set DelphiName=BDS
@set REGPATH=\Software\Embarcadero\BDS

@if %DVER% GEQ 12  if %DVER% LEQ 14 set REGPATH=\Software\CodeGear\BDS
@if %DVER% GEQ 8   if %DVER% LEQ 11 set REGPATH=\Software\Borland\BDS
@if %DVER% LEQ 7   set REGPATH=\Software\Borland\Delphi
@if %DVER% LEQ 7   set DelphiName=Delphi
@if %DVER% LEQ 7   set ide_name=Delphi %DVER%
@if %DVER% LEQ 5   set KEY=HKLM

@if %DVER% GEQ 16  goto L_IDE_NAME_XE
@if %DVER% GEQ 9   set /a ide_name=2005-9+%DVER%
@if %DVER% ==  12  set /a ide_name+=1
@if %DVER% GEQ 9   set ide_name=RAD Studio %ide_name%

:L_IDE_NAME_XE
@set xe=
@if %DVER% GEQ 16  set /a xe=%DVER%-14
@if %DVER% GEQ 15  set ide_name=RAD Studio XE%xe%

@if %DVER% GEQ 14 if %DVER% LEQ 19 set /a DVER-=1
@if %DVER% GEQ 9  set /a DVER-=6

@rem @echo ### "%ide_name%" REGPATH=($REG:%KEY%%REGPATH%\%DVER%.0\RootDir)

:L_PLATFORM_DONE
@goto L_SET_DONE

:L_SET_DNET1
@set Platform=D.Net1
@set DVER=1
@set KEY=HKLM
@set REGPATH=\Software\Borland\Delphi for .NET Preview
@set DelphiName=Delphi.Net
@goto L_SET_DONE

:L_SET_BDS
@set Platform=DELPHI_NET
@if "%DVER%"=="11N" set DVER=5
@if "%DVER%"=="11n" set DVER=5
@if "%DVER%"=="10N" set DVER=4
@if "%DVER%"=="10n" set DVER=4
@if "%DVER%"=="9N"  set DVER=3
@if "%DVER%"=="9n"  set DVER=3
@set KEY=HKCU
@set REGPATH=\Software\Borland\BDS
@set DelphiName=Delphi.Net
@goto L_SET_DONE

:L_SET_BUILDER
@set Platform=CB
@set REGPATH=\SOFTWARE\Borland\C++Builder
@if "%DVER%"=="B8"  set DVER=8
@if "%DVER%"=="B7"  set DVER=7
@if "%DVER%"=="B6"  set DVER=6
@if "%DVER%"=="B5"  set DVER=5
@if "%DVER%"=="B4"  set DVER=4
@if "%DVER%"=="B3"  set DVER=1
@set KEY=HKLM
@if %DVER% GEQ 6 set KEY=HKCU
@set DelphiName=C++Builder

:L_SET_DONE
@rem read compiler root directory from registry:

@if "%Platform%" NEQ "kylix" goto L_PATH_FROM_REG
:L_PATH_FOR_KYLIX
@if "%CROSSKYLIX_DIR%"=="" @set CROSSKYLIX_DIR=C:\delphi\tools\CrossKylix
@if "%CROSSKYLIX_LNX%"=="" @set CROSSKYLIX_LNX=/C/delphi/tools/CrossKylix
@set ide_name=CrossKylix
@rem @goto L_PATH_FROM_REG_DONE
@goto L_PATH_KYLIX

:L_PATH_FROM_REG
@rem 1
@rem @for /F "skip=2 tokens=1,2,3*" %%i in ('REG QUERY "%KEY%%REGPATH%\%DVER%.0" /v RootDir') do if "%%i"=="RootDir" @set DELPHI_ROOTDIR=%%~dpsk
@rem @call :RemoveRigthSplash DELPHI_ROOTDIR
@rem 2
@call :GetRegValuePath "%KEY%%REGPATH%\%DVER%.0" RootDir DELPHI_ROOTDIR
@rem .
@echo DELPHI_ROOTDIR="%DELPHI_ROOTDIR%">con
@if "%DELPHI_ROOTDIR%"=="" goto L_ERROR_DX_ROOTDIR
:L_PATH_FROM_REG_DONE

@rem define system envinronment path:

@if "%Platform%"=="DELPHI_NET" goto L_PATH_DELPHI_NET
@if "%Platform%"=="D.Net1" goto L_PATH_DNET1
@if "%Platform%"=="kylix" goto L_PATH_KYLIX

@rem TODO: read common bpl from registry
@if exist "%DELPHI_ROOTDIR%\projects\bpl\" set path=%DELPHI_ROOTDIR%\projects\bpl;%path%
@set path=%DELPHI_ROOTDIR%\bin;%path%
@rem OLD delphi ide replace system dll priority
@if exist "%DELPHI_ROOTDIR%\bin\system32\" set path=%DELPHI_ROOTDIR%\Bin\system32;%path%

@goto L_PATH_DONE
:L_PATH_DNET1
:L_PATH_DELPHI_NET
@rem TODO: .Net SDK Assemblies
@rem TODO: BDS Shared Assemblies
@set path=%DELPHI_ROOTDIR%\Bin;%DELPHI_ROOTDIR%\projects\assemblies;%path%
@goto L_PATH_DONE
:L_PATH_KYLIX
@set path=%CROSSKYLIX_DIR%;%path%
@rem @goto L_PATH_DONE
:L_PATH_DONE

@rem Set User Envinronments
@if "%3" neq "/c" goto l_cmd_dcc
@if not exist "%SystemRoot%\cfg_dcc.cmd" goto l_cmd_dcc
@call "%SystemRoot%\cfg_dcc.cmd"
@rem @goto l_cmd_done
:l_cmd_dcc
@if not exist "cfg_dcc.cmd" goto l_cmd_common
@call "cfg_dcc.cmd"
@rem @goto l_cmd_done
:l_cmd_common
@if not exist "common.cmd" goto l_cmd_fn
@call "common.cmd"
@rem @goto l_cmd_done
:l_cmd_fn
@if exist "%project_name%.cmd" call "%project_name%.cmd"
:l_cmd_done

@if "%UserLib%"==""    set UserLib=.
@if "%UserLibI%"==""   set UserLibI=.
@if "%UserLibO%"==""   set UserLibO=.
@if "%UserLibR%"==""   set UserLibR=.
@if "%UserCOpt%"=="."  set UserCOpt=

@set DBG=0
@if "%DEBUG%" == "1" set DBG=1
@if "%DEBUG%" NEQ "1" if "%TRACE_STACK_SOURCE%"=="1" set DBG=1

@rem define Library path:

@if "%Platform%"=="D.Net1" goto L_SRC_DNET
@if "%Platform%"=="DELPHI_NET" goto L_SRC_DELPHI_NET
@if "%Platform%"=="kylix" goto L_SRC_KYLIX
@set DLib=%UserLib%
@if "%DXVER%" NEQ "?" if %DXVER% GEQ 15 @(
  set PLIB=\win32
  if "%plfm%"=="w64" set PLIB=\win64
  if "%plfm%"=="osx32" set PLIB=\osx32
)
@if "%DXVER%" NEQ "?" if %DXVER% GEQ 18 @(
  if "%plfm%"=="aarm32" set PLIB=\android
  @rem if "%plfm%"=="aarm64" set PLIB=\android64

  if "%plfm%"=="ioss32" set PLIB=\iossimulator
  if "%plfm%"=="iosarm32" if %DXVER% GEQ 22 set PLIB=\iosDevice32
  if "%plfm%"=="iosarm32" if %DXVER% LEQ 21 set PLIB=\iosDevice
  if "%plfm%"=="iosarm64" set PLIB=\iosDevice64
)

@set PLIB=lib%PLIB%
@if "%DXVER%" NEQ "?" if %DXVER% GEQ 15 set PREL=\release
@if .%DBG%==.1 set DLib=%UserLib%;%DELPHI_ROOTDIR%\%PLIB%\debug

@set DLib=%DLib%;%DELPHI_ROOTDIR%\%PLIB%%PREL%
@if "%XOS%"=="win" set DLib=%DLib%;%DELPHI_ROOTDIR%\imports
  @rem @if "%XOS%"=="win" set DLib=%DLib%;%DELPHI_ROOTDIR%\ocx\servers
@if exist "%DELPHI_ROOTDIR%\projects\bpl\" set DLib=%DLib%;%DELPHI_ROOTDIR%\projects\bpl
@if "%XOS%"=="win" set DLib=%DLib%;%DELPHI_ROOTDIR%\source\toolsapi
  @rem set DLib=%DLib%;%DELPHI_ROOTDIR%\bin\system32
@if "%XOS%"=="win" if "%indy%" ==  "09" @set DLib=%DLib%;%DELPHI_ROOTDIR%\%PLIB%\indy9
@if "%XOS%"=="win" if "%indy%" NEQ "09" @set DLib=%DLib%;%DELPHI_ROOTDIR%\%PLIB%\indy10

@goto L_SRC_DONE

:L_SRC_DELPHI_NET
@set %UserLibI%=%UserLibI%;%DELPHI_ROOTDIR%\lib
@set %UserLibO%=%UserLibO%;%DELPHI_ROOTDIR%\lib
@set %UserLibR%=%UserLibR%;%DELPHI_ROOTDIR%\lib
@set DLib=%UserLib%
@if .%DBG%==.1 set DLib=%UserLib%;%DELPHI_ROOTDIR%\lib\debug
@set DLib=%DLib%;%DELPHI_ROOTDIR%\lib
@goto L_SRC_DONE
:L_SRC_DNET
@rem delphi .Net Preview:
@set %UserLibI%=%UserLibI%;%DELPHI_ROOTDIR%\units
@set %UserLibO%=%UserLibO%;%DELPHI_ROOTDIR%\units
@set %UserLibR%=%UserLibR%;%DELPHI_ROOTDIR%\units
@set DLib=%UserLib%;%DELPHI_ROOTDIR%\units
@goto L_SRC_DONE
:L_SRC_KYLIX
@set DLib=%UserLib%
@set DLib=%DLib%:%CROSSKYLIX_LNX%/libc
@if .%DBG%==.1 set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/lib/debug
@if .%DBG%==.1 if "%indy%"=="09" set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/lib/debug/indy9
@if .%DBG%==.1 if "%indy%" NEQ "09" set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/lib/debug/indy10
@set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/lib
@set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/imports
@set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/source/toolsapi
@if "%indy%"=="09" set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/lib/indy9
@if "%indy%" NEQ "09" set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/lib/indy10
@rem @set DLib=%DLib%:%CROSSKYLIX_LNX%/kylix/bin
@rem @goto L_SRC_DONE
:L_SRC_DONE

@rem Build:

@if "%Platform%"=="DELPHI_NET" goto L_BUILD_DNET
@if "%Platform%"=="D.Net1" goto L_BUILD_DNET
@if "%Platform%"=="CB" goto L_BUILD_BUILDER

@set t=
@if "%ide_name%" NEQ "" set t= ( %ide_name% )
@if "%project%" NEQ "?" @echo %project% - start make_prj, ver "%make_prj_ver%"; D%DXVER%%t%:

@set DCC_OPT=-$J+,R-,I-,Q-,Y-,B-,A+,W-,U-,T-,H+,X+,P+,V+,G+
@rem EQU, NEQ, LSS, LEQ, GTR, GEQ

@if "%Platform%"=="kylix" goto L_DCC_OPT_DONE

@if "%XOS%"=="android" set DCC_OPT=-TX.so %DCC_OPT%
@if "%DEBUG%"=="1" if "%XOS%"=="android" set DCC_OPT=-V -VN %DCC_OPT%

@set t=
@if "%XOS%"=="win" if %DXVER% LEQ 19 set t=;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE
@if "%XOS%"=="win" if %DXVER% GEQ 15 set t=WinTypes=Winapi.Windows;WinProcs=Winapi.Windows%t%;
@if "%XOS%"=="win" if %DXVER% LEQ 14 set t=WinTypes=Windows;WinProcs=Windows%t%;

@if %DXVER% LEQ 15 goto L_OPT_A_DONE
@rem XE2 UP
@set t=%t%Generics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults
:L_OPT_A_DONE
@if "%t%" NEQ "" set DCC_OPT=%DCC_OPT% -A%t%

@if %DXVER% GEQ 10 set DCC_OPT=--no-config %DCC_OPT%
@if %DXVER% GEQ 10 set DCC_OPT=%DCC_OPT% -W-SYMBOL_PLATFORM -W-UNIT_PLATFORM -W-GARBAGE
@rem @if %DXVER% GEQ 15 set DCC_OPT= %DCC_OPT% --legacy-ifend --inline:auto --zero-based-strings-

@if %DXVER% LEQ 15 goto L_NS_DONE
@set t=-NSSystem;Xml;Data;Datasnap;Web;Web.Win;Soap.Win
@if "%XOS%"=="win" set t=%t%;Winapi;System.Win;Data.Win
@if "%XOS%"=="win" if %DXVER% LEQ 19 set t=%t%;BDE
@if "%XOS%"=="win" set t=%t%;Xml.Win;Web.Win

@if %Fmx% NEQ 1 if "%XOS%"=="win" set t=%t%;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Shell;VCLTee
@if %Fmx% NEQ 0 set t=%t%;Fmx
@set DCC_OPT=%DCC_OPT% %t%
:L_NS_DONE

:L_DCC_OPT_DONE
@set dccPath=%DELPHI_ROOTDIR%\bin

@rem @echo DBG: %%xlinker%%=%xlinker%
@if "%xlinker%" NEQ "" goto L_XLINKERS_DONE
@if "%XOS%" NEQ "android" goto L_XLINKER_A_DONE
@set t=
@rem 1
@rem @for /F "skip=2 tokens=1,2,3*" %%i in ('REG QUERY "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs" /v Default_Android') do @if "%%i"=="Default_Android" for /F "skip=2 tokens=1,2,3*" %%l in ('REG QUERY "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs\%%k" /v NDKArmLinuxAndroidFile') do @if "%%l"=="NDKArmLinuxAndroidFile" set t=%%n
@rem 2
@call :GetRegValue "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs" Default_Android t
@if "%t%" NEQ "" call :GetRegValue "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs\%t%" NDKArmLinuxAndroidFile t
@set xlinker=%t%
@echo linker.android=%xlinker%>con
@rem @if "%xlinker%"=="" goto L_XLINKERS_DONE
@if "%xlinker%"=="" goto L_ERROR_DX_LINKER
@set xlinker=--linker:%xlinker%
:L_XLINKER_A_DONE
@rem :L_LINKER_OSX_DONE
@rem :L_LINKER_IOS_DONE
:L_XLINKERS_DONE
@rem @echo DBG: %%xlinker%%=%xlinker%
@if "%xlinker%" NEQ "" set DCC_OPT=%DCC_OPT% %xlinker%

@rem @echo DBG: %%ndklibpath%%=%ndklibpath%
@if "%ndklibpath%" NEQ "" goto L_NDKLIBPATHS_DONE
@if "%XOS%" NEQ "android" goto L_NDKLIBPATH_A_DONE
@set t=
@set s=DelphiNDKLibraryPath
@if %DXVER% LEQ 19 @set s=LibraryPath
@rem 1
@rem @for /F "skip=2 tokens=1,2,3*" %%i in ('REG QUERY "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs" /v Default_Android') do @if "%%i"=="Default_Android" for /F "skip=2 tokens=1,2,3*" %%l in ('REG QUERY "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs\%%k" /v %s%') do @if "%%l"=="%s%" set t=%%n
@rem 2
@call :GetRegValue "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs" Default_Android t
@if "%t%" NEQ "" call :GetRegValue "%KEY%%REGPATH%\%DVER%.0\PlatformSDKs\%t%" %s% t

@set ndklibpath=%t%
@echo ndklibpath.android=%ndklibpath%>con
@rem @if "%ndklibpath%"=="" goto L_NDKLIBPATHS_DONE
@if "%ndklibpath%"=="" goto L_ERROR_DX_LINKER
@set ndklibpath=--libpath:%ndklibpath%
:L_NDKLIBPATH_A_DONE
@rem :L_LINKER_OSX_DONE
@rem :L_LINKER_IOS_DONE
:L_NDKLIBPATHS_DONE
@rem @echo DBG: %%ndklibpath%%=%ndklibpath%
@if "%ndklibpath%" NEQ "" set DCC_OPT=%DCC_OPT% %ndklibpath%

@rem  Windows
@set dccName=dcc32
@if "%plfm%"=="w64" set dccName=dcc64

@rem Android
@if "%plfm%"=="aarm32" set dccName=dccaarm
@if "%plfm%"=="aarm64" set dccName=dccaarm64

@rem OSX
@if "%plfm%"=="osx32" set dccName=dccosx

@rem iOS
@if "%plfm%"=="ioss32" set dccName=dccios32
@if "%plfm%"=="iosarm32" set dccName=dcciosarm
@if "%plfm%"=="iosarm64" set dccName=dcciosarm64

@if "%Platform%"=="kylix" set dccName=ckdcc
@if "%Platform%"=="kylix" set dccPath=%CROSSKYLIX_DIR%

@set dccName=%dccName%.exe

@if "%DEBUG%"=="1"      set DCC_OPT=%DCC_OPT% -DDEBUG;_DEBUG_
@if "%DEBUG%"=="0"      set DCC_OPT=%DCC_OPT% -$D-
@rem ,$C-,O+
@if "%DEBUG%" NEQ "0"   set DCC_OPT=%DCC_OPT% -$D+,L+,Y+,C-,O-
@if "%MAPFILE%"=="1"    set DCC_OPT=%DCC_OPT% -GD
@if "%UserCOpt%" NEQ "" set DCC_OPT=%DCC_OPT% %UserCOpt%

@rem set DCC_OPT=-Q -M -B %DCC_OPT%
@set DCC_OPT=-M -B %DCC_OPT%
@rem System Unit Recompile:
@rem set DCC_OPT=-v %DCC_OPT%

@if "%UserLib%" NEQ "" set UserLib=%UserLib%%vd%

@if "%UserPack%" == "" goto L_USE_PACK_DX
@rem TODO: compile with runtime packages: calculate standard package names
@set DCC_OPT=%DCC_OPT% -LU%UserPack%
:L_USE_PACK_DX

@if "%project%"=="?" goto L_EXIT
@if "%UserLibO%"=="." @set UserLibO=
@if "%XOS%"=="android" @if "%UserLibO%"=="" set UserLibO=%DLib%
@if "%XOS%"=="android" @if "%UserLibO%" NEQ "" set UserLibO=%UserLibO%;%DLib%
@if "%UserLibO%" NEQ "" @set UserLibO= -O"%UserLibO%"
@set COMMAND=%dccName% %project% %DCC_OPT% -U"%DLib%" -I"%DLib%" -R"%DLib%"%UserLibO%
@rem @call date/t>>dcc32.log
@rem @call time/t>>dcc32.log
@echo GO MAKE: [ %date% %time% ]>>dcc32.log
@echo %COMMAND%>>dcc32.log
@echo\>con
@echo %COMMAND%>con
@echo\>con
@"%dccPath%\%dccName%" %project% %DCC_OPT% -U"%DLib%" -I"%DLib%" -R"%DLib%"%UserLibO%
@set E=%ERRORLEVEL%
@if "%IGNOREERRORLEVEL%"=="1" set E=0
@rem @echo ERRORLEVEL=%E%
@echo %project% - finish
@if "%E%" NEQ "0" goto L_ERROR

@rem @echo check exist "%project_name%.map">con
@if not exist "%project_name%.map" goto L_BUILD_DONE
@if "%MakeJclDbgP%" neq "" if not exist "%MakeJclDbgP%"MakeJclDbg.exe set MakeJclDbgP=
@if "%MakeJclDbgO%"=="" set MakeJclDbgO=-J
@echo MakeJclDbg.exe %MakeJclDbgO% %project%
@if "%JDBG%"=="1" call "%MakeJclDbgP%"MakeJclDbg.exe %MakeJclDbgO% %project%

@goto L_BUILD_DONE

:L_BUILD_DNET

@set dccilOpt=-m -nsBorland.Delphi.System -nsBorland.Delphi -nsBorland.Vcl -luSystem.Drawing -luSystem.Data -luSystem.Windows.Forms %dccilOpt%

@if "%project%"=="?" goto L_EXIT
@if "%UserLibO%"=="." @set UserLibO=
@if "%UserLibO%" NEQ "" @set UserLibO= -O%UserLibO%
@set COMMAND=dccil %dccilOpt% %UserCOpt% %project% -U"%DLib%" -I"%UserLibI%" -R"%UserLibR%"%UserLibO%
@echo ------------------------------------------------------------------------------------------>con
@echo COMMAND=%COMMAND%>con
@echo ------------------------------------------------------------------------------------------>con
@dccil %dccilOpt% %UserCOpt% %project% -U"%DLib%" -I"%UserLibI%" -R"%UserLibR%"%UserLibO%
@set E=%ERRORLEVEL%
@if "%IGNOREERRORLEVEL%"=="1" set E=0
@if "%E%" NEQ "0" goto L_ERROR

@goto L_BUILD_DONE

:L_BUILD_BUILDER
@if "%DVER%"=="1" set DVER=3
@set BDFIX=
@if "%DVER%"=="3" set BDFIX=;VER110
@if "%DVER%"=="4" set BDFIX=;VER125
@if "%DVER%"=="5" set BDFIX=;VER130;BCB
@if "%DVER%"=="6" set BDFIX=;VER140;BCB

@set DCC_OPT=-$J+,R-,I-,Q-,Y-,B-,A+,W-,U-,T-,H+,X+,P+,V+

@if .%DBG%==.0          set DCC_OPT=%DCC_OPT%,D-,$C-,O+
@if .%DBG%==.1          set DCC_OPT=%DCC_OPT%,D+,L+,C-,O-
@if "%MAPFILE%"=="1"    set DCC_OPT=%DCC_OPT% -GD
@if "%UserCOpt%" NEQ "" set DCC_OPT=%DCC_OPT% %UserCOpt%

@set DCC_OPT=-JPHN %DCC_OPT%
@rem @set DCC_OPT=-M %DCC_OPT%
@rem System Unit Recompile
@rem set DCC_OPT=-v %DCC_OPT%

@if "%UserLib%" NEQ "" set UserLib=%UserLib%%vd%

@set UnitDir=%DELPHI_ROOTDIR%\lib\release;%DELPHI_ROOTDIR%\lib\obj;%DELPHI_ROOTDIR%\bin\lib;%DELPHI_ROOTDIR%\release
@set IncludeDir=%DELPHI_ROOTDIR%\include;%DELPHI_ROOTDIR%\include\vcl
@set ResourceDir=%IncludeDir%;%UnitDir%
@set UnitDir=%UserLib%%UnitDir%
@set IncludeDir=%UserLib%%UnitDir%

@if "%project%"=="?" goto L_EXIT
@set COMMAND=dcc32.exe" -D_RTLDLL;USEPACKAGES%BDFIX% -U%UnitDir%  -I%IncludeDir% -R%ResourceDir% %project% %DCC_OPT%
@echo ------------------------------------------------------------------------------------------>con
@echo "%DELPHI_ROOTDIR%\bin\dcc32.exe"  -D_RTLDLL;USEPACKAGES%BDFIX% -U%UnitDir%  -I%IncludeDir% -R%ResourceDir% %project% %DCC_OPT% %bccOpt%>con
@echo ------------------------------------------------------------------------------------------>con
@"%DELPHI_ROOTDIR%\bin\dcc32.exe" -D_RTLDLL;USEPACKAGES%BDFIX% -U%UnitDir%  -I%IncludeDir% -R%ResourceDir% -M %project% %DCC_OPT%
@set E=%ERRORLEVEL%
@if "%IGNOREERRORLEVEL%"=="1" set E=0
@if "%E%" NEQ "0" goto L_ERROR

:L_BUILD_DONE
@if "%CleanDcc32Log%"=="1" del dcc32.log >nul 2>nul

@echo Done.

@goto L_EXIT

:L_ERROR_DX_ROOTDIR
@set KEYSTR=HKEY_CURRENT_USER
@if "%ide_name%"=="" set ide_name=%DelphiName% %DVER%
@if "%KEY%"=="HKLM" set KEYSTR=HKEY_LOCAL_MACHIME
@echo ERROR:>con
@echo  Cannot find "%ide_name%" (%%DVER%%=%DXVER%)>con
@echo  Details:>con
@echo    Cannot find registry path:>con
@echo       '%KEYSTR%%REGPATH%\%DVER%.0\RootDir'>con
@echo press any key to exit>con
@pause >nul
@goto L_EXIT

:L_ERROR_DX_LINKER
@if "%ide_name%"=="" set ide_name=%DelphiName% %DVER%
@echo ERROR:>con
@echo  Linker not found (%XOS%) "%ide_name%" (%%DVER%%=%DXVER%)>con
@echo press any key to exit>con
@pause >nul
@goto L_EXIT

:L_HELP
@rem cls
@goto L_HELP_INFO
:L_ERROR_PARAM
@if %xLang%A==ruA @(
  @echo ERROR: неверные параметры>con
) else @(
  @echo ERROR: unknown parameters>con
)
:L_HELP_INFO
@echo\make_prj Version %make_prj_ver%>con
@if "%xLang%"=="ru" @(
  @echo   "make_prj.cmd" - утилита сборки/компиляции проекта/модуля Delphi/C++Builder/Kylix>con
  @echo ---------------------------------------------------------------------------------------------->con
  @echo Использование:>con
  @echo   make_prj.cmd  "delphi-compiler"  "project_file|?" ["options"]>con
  @echo Где:>con
  @echo   [1] delphi-compiler:>con
  @echo        22       - Delphi XE8  for win32>con
  @echo        22w64    - Delphi XE8  for win64>con
  @echo        22arm32  - Delphi XE8  for arm32>con
  @echo        22osx32  - Delphi XE8  for osx32>con
  @echo        22ios32  - Delphi XE8  for iOS arm 32>con
  @echo        22ios64  - Delphi XE8  for iOS arm 64>con
  @echo        22ioss   - Delphi XE8  for iOS Simulator>con
  @echo        ... ... ... ... ........ ... ..>con
  @echo        18ios32  - Delphi XE4  for iOS arm 32>con
  @echo        18ios64  - Delphi XE4  for iOS arm 64>con
  @echo        18ioss   - Delphi XE4  for iOS Simulator>con
  @echo        17       - Delphi XE3  for win32>con
  @echo        ... ... ... ... ........ ... ..>con
  @echo        16       - Delphi XE2  for win32>con
  @echo        16w64    - Delphi XE2  for win64>con
  @echo        16osx    - Delphi XE2  for osx32>con
  @echo        15       - Delphi XE   for win32>con
  @echo        14       - Delphi 2010 for win32>con
  @echo        12       - Delphi 2009 for win32>con
  @echo        11       - Delphi 2007 for win32>con
  @echo        11N      - Delphi 2007 for .net2>con
  @echo        10       - Delphi 2006 for win32>con
  @echo        10N      - Delphi 2006 for .net2>con
  @echo        9        - Delphi 2005 for win32>con
  @echo        9N       - Delphi 2005 for .net1>con
  @echo        8        - Delphi 8    for .net1>con
  @echo        BDS      - Delphi 8    for .net1>con
  @echo        D.Net1   - Delphi      for .net1 preview>con
  @echo        7        - Delphi 7    for win32>con
  @echo        k3       - Kylix  3    for linux x86 [ CrossKylix: C:\delphi\tools\CrossKylix ]>con
  @echo        6        - Delphi 6    for win32>con
  @echo        5        - Delphi 5    for win32>con
  @echo        4        - Delphi 4    for win32>con
  @echo        3        - Delphi 3    for win32>con
  @echo\>con
  @echo        B6       - C++ Builder 6   for win32>con
  @echo        B5       - C++ Builder 5   for win32>con
  @echo        B4       - C++ Builder 4   for win32>con
  @echo        B3       - C++ Builder 3.5 for win32>con
  @echo\>con
  @echo        /C       - Clean - чистка текущей директории от: [dcu, obj, o, a, drc, vsr ...]>con
  @echo        /CA      - /C + remove  "cfg, dof, dsk" Files>con
  @echo\>con
  @echo   [2] "project_file|?"  -  Имя проекта/модуля или ? для установки переменных окружения.>con
  @echo\>con
  @echo   [3] "Options":>con
  @echo          /c  - искать общий "%%SystemRoot%%\cfg_dcc.cmd" описывающий общие настройки.>con
  @echo\>con
  @echo Примеры:>con
  @echo   make_prj.cmd 3 Project1.dpr>con
  @echo   make_prj.cmd 6 Unit1.pas>con
  @echo   make_prj.cmd B6 Unit1.pas>con
  @echo   make_prj.cmd 9N my.module.pas>con
  @echo   make_prj.cmd 16w64 Unit1.pas>con
  @echo   make_prj.cmd 16osx Unit1.pas>con
  @echo   make_prj.cmd k3 Unit1.pas>con
  @echo   make_prj.cmd /C>con
  @echo   make_prj.cmd D5 ?  - только установка переменных окружения>con
  @echo   make_prj.cmd 6 project1.dpr /c - все настройки указанны в cfg_dcc.cmd>con
) else @(
  @echo   "make_prj.cmd" - The utility of assembly/compilation of Delphi/C++ Builder/Kylix project/unit/package>con
  @echo ---------------------------------------------------------------------------------------------->con
  @echo Usage:>con
  @echo   make_prj.cmd  "delphi-compiler"  "project_file|?" ["options"]>con
  @echo Where:>con
  @echo   [1] delphi-compiler:>con
  @echo        22         - Delphi XE8  for win32>con
  @echo        22w64      - Delphi XE8  for win64>con
  @echo        22arm32    - Delphi XE8  for arm32>con
  @echo        22osx32    - Delphi XE8  for osx32>con
  @echo        22ios32    - Delphi XE8  for iOS arm 32>con
  @echo        22ios64    - Delphi XE8  for iOS arm 64>con
  @echo        22ioss     - Delphi XE8  for iOS Simulator>con
  @echo        ... ... ... ... ........ ... ..>con
  @echo        18iosarm32 - Delphi XE4  for iOS arm 32>con
  @echo        18iosarm64 - Delphi XE4  for iOS arm 64>con
  @echo        18ioss     - Delphi XE4  for iOS Simulator>con
  @echo        17         - Delphi XE3  for win32>con
  @echo        ... ... ... ... ........ ... ..>con
  @echo        16         - Delphi XE2  for win32>con
  @echo        16w64      - Delphi XE2  for win64>con
  @echo        16osx      - Delphi XE2  for osx32>con
  @echo        15         - Delphi XE   for win32>con
  @echo        14         - Delphi 2010 for win32>con
  @echo        12         - Delphi 2009 for win32>con
  @echo        11         - Delphi 2007 for win32>con
  @echo        11N        - Delphi 2007 for .net2>con
  @echo        10         - Delphi 2006 for win32>con
  @echo        10N        - Delphi 2006 for .net2>con
  @echo        9          - Delphi 2005 for win32>con
  @echo        9N         - Delphi 2005 for .net1>con
  @echo        8          - Delphi 8    for .net1>con
  @echo        BDS        - Delphi 8    for .net1>con
  @echo        D.Net1     - Delphi      for .net1 preview>con
  @echo        7          - Delphi 7    for win32>con
  @echo        k3         - Kylix  3    for linux x86 [ CrossKylix: C:\delphi\tools\CrossKylix ]>con
  @echo        6          - Delphi 6    for win32>con
  @echo        5          - Delphi 5    for win32>con
  @echo        4          - Delphi 4    for win32>con
  @echo        3          - Delphi 3    for win32>con
  @echo\>con
  @echo        B6         - C++ Builder 6   for win32>con
  @echo        B5         - C++ Builder 5   for win32>con
  @echo        B4         - C++ Builder 4   for win32>con
  @echo        B3         - C++ Builder 3.5 for win32>con
  @echo\>con
  @echo        /C         - Clean - Cleaning of the current directory from: [dcu, obj, o, a, drc, vsr ...]>con
  @echo        /CA        - /C + Cleaning of the current directory from: "cfg, dof, dsk" Files>con
  @echo\>con
  @echo   [2] "project_file|?"  -  Name of the project/unit or ? for installation of environment variables only.>con
  @echo\>con
  @echo   [3] "Options":>con
  @echo          /c  - To search common "%%SystemRoot%%\cfg_dcc.cmd" describing for common options.>con
  @echo\>con
  @echo Examples:>con
  @echo   make_prj.cmd 3 Project1.dpr>con
  @echo   make_prj.cmd 6 Unit1.pas>con
  @echo   make_prj.cmd B6 Unit1.pas>con
  @echo   make_prj.cmd 9N my.module.pas>con
  @echo   make_prj.cmd 16w64 Unit1.pas>con
  @echo   make_prj.cmd 16osx Unit1.pas>con
  @echo   make_prj.cmd k3 Unit1.pas>con
  @echo   make_prj.cmd /C>con
  @echo   make_prj.cmd D5 ?  - Only installation of environment variables>con
  @echo   make_prj.cmd 6 project1.dpr /c - Originally to take adjustments from cfg_dcc.cmd>con
)
@echo ------------------------------------------------------------------------------------------>con
@goto L_EXIT

:L_ERROR
@if "%E%"=="" set E=%ERRORLEVEL%

@if "%DEBUG_BATCH%"=="1" goto L_ERROR_LOG

@echo ------------------------------------------------------------------------------------------>con
@echo PATH=%path%>con
@echo ------------------------------------------------------------------------------------------>con
@echo Error (ERRORLEVEL="%E%").>con
@if "%UserLib%" NEQ "" if "%UserLib%" NEQ "." echo UserLib=%UserLib%>con
@if "%UserPack%" NEQ "" echo UserPack=%UserPack%>con
@echo ------------------------------------------------------------------------------------------>con
@echo command:>con
@echo %COMMAND%>con
@echo ------------------------------------------------------------------------------------------>con

:L_ERROR_LOG
@rem Clean Log File
@rem @if "%E%"=="0" if "%CleanDcc32Log%"=="1" del dcc32.log >nul 2>nul
@if "%CleanDcc32Log%"=="1" del dcc32.log >nul 2>nul

@echo ------------------------------------------------------------------------------------------>>dcc32.log
@set>>dcc32.log
@echo . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . >>dcc32.log
@echo Error (ERRORLEVEL="%E%").>>dcc32.log
@echo . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . >>dcc32.log
@echo CD=%cd%>>dcc32.log
@echo . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . >>dcc32.log
@echo PATH=%path%>>dcc32.log
@echo . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . >>dcc32.log
@echo Error (ERRORLEVEL="%E%").>>dcc32.log
@echo UserLib=%UserLib%>>dcc32.log
@echo UserPack=%UserPack%>>dcc32.log
@echo . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . >>dcc32.log
@echo command:>>dcc32.log
@echo %COMMAND%>>dcc32.log
@echo . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . >>dcc32.log

@if exist "error_handler.cmd" call error_handler.cmd
@if "%SKIP_ERROR%"=="1" goto L_EXIT

:L_ERROR_SKIPCMD
@if not %xErrorTimeout%A==1A goto L_WAIT_2
@if "%FARHOME%" NEQ "" goto L_WAIT_2
@echo Press Crtl+C to quit ... >con
@ping -a -n 10 1.1.1.1 -w 10000>nul
@rem @goto L_WAIT_END
:L_WAIT_2
@echo !!! ERROR !!! Press any key to exit . . .>con
@pause >nul
:L_WAIT_END
@set errorlevel=1
@exit 1

:L_EXIT
@goto :eof


::::::::::::::::::::::::::::::::::::::::::::::::::::::
:StrLen S L
::::::::::::::::::::::::::::::::::::::::::::::::::::::  TODO: not supported quoted S
@setlocal
  @call set S=%%%1%%
  @set L=0
  :Loop
  @if "%S%"=="" @(endlocal & set "%2=%L%" & goto :eof)
  @set /a L=%L%+1
  @set S=%S:~0,-1%
@goto Loop
::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::
:RemoveRigthSplash %S%
::::::::::::::::::::::::::::::::::::::::::::::::::::::  :: TODO: StrLen not work when S is quoted
@setlocal
  @call set S=%%%~1%%
  @call :StrLen S L
  @if %L%==0 @goto l_end
    @set /a L-=1
    @set C=%%S:~%L%,1%%
    @call set "C=%C%"
    @if "%C%" NEQ "\" @goto l_end
    @set C=%%S:~0,%L%%%
    @call set "S=%C%"
  :l_end
@endlocal & @set "%1=%S%" & @goto :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::
:xGetRegValue %P% %N% %V%
::::::::::::::::::::::::::::::::::::::::::::::::::::::  :: TODO: N - not work when quoted
@setlocal
  @set S=
  @call set N=%%%~2%%
  @for /F "skip=2 tokens=1,2,3*" %%i in ('REG QUERY "%%%1%%" /v %%%2%%') do @if "%%i"=="%N%" set S=%%k
@endlocal & @set "%3=%S%" & @goto :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GetRegValue P N %V%
::::::::::::::::::::::::::::::::::::::::::::::::::::::  :: TODO: N - not work when quoted
@setlocal
  @set P=%1
  @set N=%2
  @set V=
  @call :xGetRegValue P N V
@endlocal & @set "%3=%V%" & @goto :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::
:xGetRegValuePath %P% %N% %V%
::::::::::::::::::::::::::::::::::::::::::::::::::::::  :: TODO: N - not work when quoted
@setlocal
  @set S=
  @call set N=%%%~2%%
  @for /F "skip=2 tokens=1,2,3*" %%i in ('REG QUERY "%%%1%%" /v %%%2%%') do @if "%%i"=="%N%" if "%%k" NEQ "" (
   set S=%%k
   call :RemoveRigthSplash S
  )
@endlocal & @set "%3=%S%" & @goto :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GetRegValuePath P N %V%
::::::::::::::::::::::::::::::::::::::::::::::::::::::  :: TODO: N - not work when quoted
@setlocal
  @set P=%1
  @set N=%2
  @set V=
  @call :xGetRegValuePath P N V
@endlocal & @set "%3=%V%" & @goto :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::
