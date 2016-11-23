@if defined TRACEON (@echo on) else (@echo off)

  REM  If this batch file works, then it was written by Fish.
  REM  If it doesn't then I don't know who the heck wrote it.

  setlocal
  set "TRACE=if defined DEBUG echo"
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
  echo         1.0     (June 13, 2016)

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

  if not "%~1" == "32" (
    if not "%~1" == "64" (
      goto :HELP
    ) else (
      set "vstarget=amd64"
    )
  ) else (
    set "vstarget=x86"
  )

  set "VSVERSIONS=140 120 110 100 90 80"
  set "VSTOOLSDIR="

:VSTOOLSDIR_loop

  for /f "tokens=1*" %%a in ("%VSVERSIONS%") do (
    call :try_VSTOOLSDIR "%%a"
    if defined VSTOOLSDIR goto :got_VSTOOLSDIR
    if "%%b" == "" goto :VSTOOLSDIR_error
    set "VSVERSIONS=%%b"
    goto :VSTOOLSDIR_loop
  )

:try_VSTOOLSDIR

  set "nnn=%~1"
  setlocal enabledelayedexpansion
  if not "!VS%nnn%COMNTOOLS!" == "" (
    if exist "!VS%nnn%COMNTOOLS!..\..\VC\vcvarsall.bat"  (
      set "VSTOOLSDIR=!VS%nnn%COMNTOOLS!"
    )
  )
  endlocal && set "VSTOOLSDIR=%VSTOOLSDIR%"
  goto :EOF

:got_VSTOOLSDIR

  if /i "%PROCESSOR_ARCHITECTURE%" == "x86"   set "vshost=x86"
  if /i "%PROCESSOR_ARCHITECTURE%" == "AMD64" set "vshost=amd64"

  ::  Since Microsoft doesn't have an X64 build of their compiler,
  ::  if targeting x86 we must use their x86 compiler under WOW64.
  ::  This is called cross compiling.

  if /i "%vstarget%" == "x86" set "vshost=x86"
  if /i not "%vshost%" == "%vstarget%" goto :cross_compile

  ::  Host architecture matches target architecture

  set "vshost="

  if not exist "%VSTOOLSDIR%..\..\VC\bin\vcvars32.bat" (
    goto :targ_arch_error
  )

  goto :set_VSTOOLS

:cross_compile

  ::  Targeting x86 but running under x64! (WOW64)

  set "vshost=x86_" && REM (even though our ACTUAL host arch is x64!)

  if not exist "%VSTOOLSDIR%..\..\VC\bin\%vshost%%vstarget%\vcvars%vshost%%vstarget%.bat" (
    goto :targ_arch_error
  )

:set_VSTOOLS

  endlocal && set "VSTOOLSDIR=%VSTOOLSDIR%" && set "vshost=%vshost%" && set "vstarget=%vstarget%"
  call "%VSTOOLSDIR%..\..\VC\vcvarsall.bat"  %vshost%%vstarget%
  exit /b 0

:VSTOOLSDIR_error

  echo %~nx0: ERROR: No supported version of Visual Studio is installed
  endlocal
  exit /b 1

:targ_arch_error

  echo %~nx0: ERROR: Build support for target architecture %vstarget% is not installed
  endlocal
  exit /b 1

::-----------------------------------------------------------------------------
