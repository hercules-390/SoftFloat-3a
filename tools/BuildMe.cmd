@echo off

:: Configure SoftFloat and the compile it.
:: Your current working directory MUST be the one where this file resides

:: First parameter is the processor architecture being build for, as
:: determined by 1Stop.cmd.

:: %build_arch% must have been set to the build architecture by the caller
:: of this script

echo ************************************** %0: Configuring and Building SoftFloat 3a

set "todir=..\..\%build_arch%\s3fh.release"
echo Building for release in '%todir%'. >&2
if "%1" neq "" (
    echo ..with parameters %*
)

:: Set the CMake generator to the most modern version of Visual Studio
:: installed on this machine.  This script assumes that at least one
:: such is installed.  Lowest acceptable is VS2008; highest is VS2017
:: (As of this writing, VS2017 is supported by CMake but is only RC
:: status from Microsoft.

if "%VisualStudioVersion%" == "15.0" (
    set "cmake_generator=Visual Studio 15 2017"
) else if "%VisualStudioVersion%" == "14.0" (
    set "cmake_generator=Visual Studio 14 2015"
) else if "%VisualStudioVersion%" == "12.0" (
    set "cmake_generator=Visual Studio 12 2013"
) else if "%VisualStudioVersion%" == "11.0" (
    set "cmake_generator=Visual Studio 11 2012"
) else if "%VisualStudioVersion%" == "10.0" (
    set "cmake_generator=Visual Studio 10 2010"
) else if "%VisualStudioVersion%" == "9.0" (
    set "cmake_generator=Visual Studio 9 2008"
) else (
    set "retcode=12"
    echo Unable to determine Visual Studio version, found "%VisualStudioVersion%".  Terminating.
    goto :exitBuildMe
)

:: If building for 64-bit target, set the suffix for the CMake generator

if /I "%build_arch%" == "amd64" (
    set "cmake_generator=%cmake_generator% Win64"
)


pushd %todir%

if %errorlevel% GTR 0 (
    set "retcode=%errorlevel%"
    echo Unable to change directory to '%todir%'.  Terminating.
    goto :exitBuildMe
)


cmake ..\..\SoftFloat-3a -G "%cmake_generator%%"

if %errorlevel% GTR 0 (
    set "retcode=%errorlevel%"
    echo Unable to configure.  Terminating.
    goto :exitBuildMe
)


cmake --build . --target clean --config Release %*

if %errorlevel% GTR 0 (
    set "retcode=%errorlevel%"
    echo Unable to clean.  Terminating.
::    goto :exitBuildMe
    pause
)
cmake --build . --config Release %*

if %errorlevel% GTR 0 (
    set "retcode=%errorlevel%"
    echo Unable to compile.  Terminating.
    goto :exitBuildMe
)

:exitBuildMe
popd
exit /b %retcode%