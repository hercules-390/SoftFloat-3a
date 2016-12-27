@echo off

:: Generate default build and install directories if the do not exist.
:: Your current working directory MUST be the one where this file resides

:: First parameter is the processor architecture being build for, as
:: determined by 1Stop.cmd.

echo ************************************** %0: Creating Directories
setlocal

set "root=..\..\%build_arch%"

pushd ..\..\
set  "abs_path=%cd%"
popd

echo Creating directories in %build_arch% under '%abs_path%'.>&2

call :dodir && (call :dodir s3fh && (call :dodir s3fh.release && call :dodir s3fh.debug))

set "retcode=%errorlevel%"

exit /b %retcode%



:dodir

set "dir=%root%\%1"

if NOT EXIST %dir% (
        mkdir %dir%
        if %errorlevel% gtr 0 (
                echo Cannot create directory '%build_arch%\%1'.  Terminating.
                exit /b 12
        )
        echo Created '%build_arch%\%1'. >&2
) else (
        echo '%build_arch%\%1' exists. >&2
)

exit /b 0