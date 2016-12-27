@echo off

:: This script is the one-stop shopping for MakeDirs, BuildMe, and InstallMe
:: in the utils subdirectory.

:: Your current working directory MUST be the one where this file resides

:: Save current directory and go to where the individual scripts are

:: Parameters passed on the command line are passed as parameters to the
:: BuildMe script.

setlocal

set "retcode="
pushd tools

:: We check for PLATFORM because Windows is not very clear about whether
:: we are building for amd64 or just running on amd64.  If PLATFORM
:: exists, then this is a cross-platform build x86 on amd64.  Otherwise
:: we will use the PROCESSOR_ARCHITECTURE value.  (Need to check
:: what the variables look like for a cross-platform build amd64 on
:: x86).   The result is available to the remaining scripts.

if /I "%PLATFORM%"=="X86" (
  set "build_arch=x86"
) else (
  set "build_arch=%PROCESSOR_ARCHITECTURE%"
)

:: Unforturnately the PLATFORM variable will mess up --clean-first.  We
:: shall unset it for the duration of the script.  Setting the generator
:: (below) will determine whether a 32-bit or 64-bit library is built.

set "PLATFORM="

call MakeDirs.cmd  && ( call BuildMe.cmd %* && call InstallMe.cmd )

set "retcode=%errorlevel%"

popd

if %retcode% GTR 0 (
  echo *** Unsuccessful completion!
)

exit /b %retcode%