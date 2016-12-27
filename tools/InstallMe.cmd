@echo off

:: Install Soft Float.
:: Your current working directory MUST be the one where this file resides

echo ************************************** %0: Installing SoftFloat-3a

set "todir=..\..\%build_arch%\s3fh.release"
echo Installing for release in '%todir%'. >&2

pushd %todir%

if %errorlevel% GTR 0 (
    set "retcode=%errorlevel%"
    echo Unable to change directory to '%todir%'.  Terminating.
    goto :exitInstallMe
)


cmake -P cmake_install.cmake
if %errorlevel% GTR 0 (
    set "retcode=%errorlevel%"
    echo Unable to install.  Terminating.
    goto :exitInstallMe
)

:exitInstallMe
popd
exit /b %retcode%