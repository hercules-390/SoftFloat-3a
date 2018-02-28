@echo off

:: Configure SoftFloat and the compile it.
:: Your current working directory MUST be the one where this file resides

:: First parameter is the processor architecture being build for, as
:: determined by 1Stop.cmd.

:: %build_arch% must have been set to the build architecture by the caller
:: of this script

:: %cmake_generator% must have been set to the CMake generator to be used,
:: as determined by the caller based on the Visual Studio version.

echo ************************************** %0: Configuring and Building SoftFloat 3a

set "todir=..\..\%build_arch%\s3fh.release"
echo Building for release in '%todir%'. >&2
if "%1" neq "" (
    echo ..with parameters %*
)


pushd %todir%

if %errorlevel% GTR 0 (
    set "retcode=%errorlevel%"
    echo Unable to change directory to '%todir%'.  Terminating.
    goto :exitBuildMe
)

echo cmake ..\..\SoftFloat-3a -G "%cmake_generator%%"

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