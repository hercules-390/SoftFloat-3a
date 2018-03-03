@if defined TRACEON (@echo on) else (@echo off)

  REM  If this batch file works, then it was written by Fish.
  REM  If it doesn't then I don't know who the heck wrote it.

  setlocal
  set "TRACE=if defined DEBUG echo"
  set "return=goto :EOF"
  goto :BEGIN

::-----------------------------------------------------------------------------
::                            VSTOOLS.CMD
::-----------------------------------------------------------------------------
:HELP

  echo.
  echo     NAME
  echo.
  echo         %~n0   --   Initialize Visual Studio build environment
  echo.
  echo     SYNOPSIS
  echo.
  echo         %~nx0    { 32 ^| 64 }
  echo.
  echo     ARGUMENTS
  echo.
  echo         32 ^| 64     Defines the desired target architecture.
  echo.
  echo     OPTIONS
  echo.
  echo         (NONE)
  echo.
  echo     NOTES
  echo.
  echo         Some flavor of Visual Studio must obviously be installed.
  echo         Supported versions are Visual Studio 2005 through 2015.
  echo.
  echo     EXIT STATUS
  echo.
  echo         0          Success
  echo         1          Error
  echo.
  echo     AUTHOR
  echo.
  echo         "Fish"  (David B. Trout)
  echo.
  echo     VERSION
  echo.
  echo         2.0     (March 2, 2018)

  endlocal && exit /b 1

::-----------------------------------------------------------------------------
::                               BEGIN
::-----------------------------------------------------------------------------
:BEGIN

  if /i "%~1" == ""        goto :HELP
  if /i "%~1" == "?"       goto :HELP
  if /i "%~1" == "/?"      goto :HELP
  if /i "%~1" == "-?"      goto :HELP
  if /i "%~1" == "--help"  goto :HELP

  ::-------------------------------
  :: Determine target environment
  ::-------------------------------

  if not "%~1" == "32" (
    if not "%~1" == "64" (
      goto :HELP
    ) else (
      set "vstarget=amd64"
    )
  ) else (
    set "vstarget=x86"
  )

  echo Target architecture is %vstarget%

  ::-------------------------------
  :: Determine host environment
  ::-------------------------------

  if   /i "%PROCESSOR_ARCHITEW6432%" == "x86"   set "vshost=x86"
  if   /i "%PROCESSOR_ARCHITEW6432%" == "AMD64" set "vshost=amd64"

  if not defined vshost (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86"   set "vshost=x86"
    if /i "%PROCESSOR_ARCHITECTURE%" == "AMD64" set "vshost=amd64"
  )

  echo Host architecture is %vshost%

  ::-------------------------------
  :: Determine which Visual Studio
  ::-------------------------------

  call :which_vstudio
  if %rc% NEQ 0 goto :vstools_error

  ::--------------------------------------------------------
  ::           Set the build environment....
  ::
  :: Note that we must set the build enviroment outside
  :: the scope of our setlocal/endlocal to ensure that
  :: whatever build environment gets set ends up being
  :: passed back to the caller. Our goal is after all
  :: is to set environment variables for the caller!
  ::--------------------------------------------------------

  endlocal                          ^
    && set "vstarget=%vstarget%"    ^
    && set "vshost=%vshost%"        ^
    && set "VCVARSDIR=%VCVARSDIR%"  ^
    && set "vsver=%vsver%"          ^
    && set "vs2017=%vs2017%"

  ::--------------------------------------------------------
  ::           IMPORTANT PROGRAMMING NOTE!
  ::
  :: ALL variables the below ":set_build_env" call needs
  :: MUST be re-"set" on the above "endlocal" statement!
  ::--------------------------------------------------------

  call :set_build_env

  exit /b 0

:vstools_error

  echo %~nx0: ERROR: No supported version of Visual Studio is installed
  endlocal
  exit /b 1


::-----------------------------------------------------------------------------
::                         set_build_env
::-----------------------------------------------------------------------------
:set_build_env

  if %vsver% LSS %vs2017% (
    goto :vs2015_or_earlier
  )

  ::-----------------------------------
  ::   Visual Studio 2017 or LATER
  ::-----------------------------------

  pushd .
  echo.

  if /i not "%vshost%" == "%vstarget%" (

    @REM  Cross compiling...

    call "%VCVARSDIR%\vcvars%vshost%_%vstarget%.bat"
    @if defined TRACEON (@echo on) else (@echo off)

  ) else (

    if /i "%vstarget%" == "x86"   call "%VCVARSDIR%\vcvars32.bat"
    @if defined TRACEON (@echo on) else (@echo off)

    if /i "%vstarget%" == "amd64" call "%VCVARSDIR%\vcvars64.bat"
    @if defined TRACEON (@echo on) else (@echo off)
  )

  echo.
  popd

  %return%

:vs2015_or_earlier

  ::-----------------------------------
  ::   Visual Studio 2015 or EARLIER
  ::-----------------------------------

  if /i "%vshost%" == "%vstarget%" (

    set "vcvarsall_argument=%vstarget%"

  ) else (

    @REM Cross compile: use 32-bit compiler to build 64-bit application
    set "vcvarsall_argument=x86_amd64"
  )

  call "%VCVARSDIR%\vcvarsall.bat"  %vcvarsall_argument%
  @if defined TRACEON (@echo on) else (@echo off)

  %return%


::-----------------------------------------------------------------------------
::                            which_vstudio
::-----------------------------------------------------------------------------
:which_vstudio

  set "rc=0"
  set "VCVARSDIR="

  set "vs2017=150"
  set "vs2015=140"
  set "vs2013=120"
  set "vs2012=110"
  set "vs2010=100"
  set "vs2008=90"
  set "vs2005=80"

  set "VSVERSIONS=%vs2017% %vs2015% %vs2013% %vs2012% %vs2010% %vs2008% %vs2005%"

:vstudio_try_loop

  for /f "tokens=1*" %%a in ("%VSVERSIONS%") do (
    call :try_vstudio_sub "%%a"
    if defined VCVARSDIR %return%
    if "%%b" == "" goto :vstudio_error
    set "VSVERSIONS=%%b"
    goto :vstudio_try_loop
  )

:vstudio_error

  echo %~nx0: ERROR: No supported version of Visual Studio is installed
  set "rc=1"
  %return%

:try_vstudio_sub

  set "vsver=%~1"

  setlocal enabledelayedexpansion

  if not "!VS%vsver%COMNTOOLS!" == "" (
    if %vsver% GEQ %vs2017% (
      set "VCVARSDIR=!VS%vsver%COMNTOOLS!..\..\VC\Auxiliary\Build"
    ) else (
      set "VCVARSDIR=!VS%vsver%COMNTOOLS!..\..\VC"
    )
  )

  endlocal && set "VCVARSDIR=%VCVARSDIR%"
  %return%

::-----------------------------------------------------------------------------
